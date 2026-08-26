#!/usr/bin/env python3
"""Check that every env key a Deployment references actually exists.

A pod whose ``secretKeyRef``/``configMapKeyRef`` names a key that is not in the
ConfigMap or the Secret does not fail at apply time — it fails later, at
runtime, as ``CreateContainerConfigError``, which is a slow and confusing way to
learn about a typo. This catches it in CI instead.

The Secret is read from ``secret.example.yaml`` (placeholders), because the real
``secret.yaml`` is git-ignored and never exists on a runner. Only key *names*
matter here, so the placeholders are exactly as good as the real values.
"""

from __future__ import annotations

import sys
from pathlib import Path

import yaml

K8S_DIR = Path(__file__).resolve().parent.parent


def _documents() -> list[dict]:
    docs: list[dict] = []
    for path in sorted(K8S_DIR.glob("*.yaml")):
        with path.open(encoding="utf-8") as handle:
            docs += [
                doc | {"__file__": path.name}
                for doc in yaml.safe_load_all(handle)
                if isinstance(doc, dict)
            ]
    return docs


def _keys_of(docs: list[dict], kind: str, name: str) -> set[str]:
    for doc in docs:
        if doc.get("kind") == kind and doc.get("metadata", {}).get("name") == name:
            return set(doc.get("data", {})) | set(doc.get("stringData", {}))
    return set()


def main() -> int:
    docs = _documents()
    available = {
        "configMapKeyRef": {
            name: _keys_of(docs, "ConfigMap", name)
            for name in {
                doc["metadata"]["name"] for doc in docs if doc.get("kind") == "ConfigMap"
            }
        },
        "secretKeyRef": {
            name: _keys_of(docs, "Secret", name)
            for name in {
                doc["metadata"]["name"] for doc in docs if doc.get("kind") == "Secret"
            }
        },
    }

    problems: list[str] = []
    checked = 0

    def walk(node: object, origin: str) -> None:
        nonlocal checked
        if isinstance(node, dict):
            for ref_kind in ("configMapKeyRef", "secretKeyRef"):
                ref = node.get("valueFrom", {}).get(ref_kind) if "valueFrom" in node else None
                if isinstance(ref, dict):
                    checked += 1
                    source, key = ref.get("name"), ref.get("key")
                    known = available[ref_kind].get(source)
                    if known is None:
                        problems.append(f"{origin}: no {ref_kind} source named {source!r}")
                    elif key not in known:
                        problems.append(
                            f"{origin}: {source!r} has no key {key!r} "
                            f"(available: {', '.join(sorted(known))})"
                        )
            for value in node.values():
                walk(value, origin)
        elif isinstance(node, list):
            for item in node:
                walk(item, origin)

    for doc in docs:
        walk(doc, f"{doc['__file__']}/{doc.get('kind')}")

    # envFrom pulls a whole ConfigMap/Secret in; verify the source exists.
    for doc in docs:
        for container in _containers(doc):
            for source in container.get("envFrom", []) or []:
                for ref_kind, kind in (
                    ("configMapRef", "configMapKeyRef"),
                    ("secretRef", "secretKeyRef"),
                ):
                    ref = source.get(ref_kind)
                    if ref and ref.get("name") not in available[kind]:
                        problems.append(
                            f"{doc['__file__']}: envFrom names a missing "
                            f"{ref_kind} {ref.get('name')!r}"
                        )

    for problem in problems:
        print(f"error: {problem}", file=sys.stderr)
    print(f"checked {checked} key references across {len(docs)} manifests")
    return 1 if problems else 0


def _containers(doc: dict) -> list[dict]:
    spec = doc.get("spec", {})
    template = spec.get("template", {}) if isinstance(spec, dict) else {}
    pod_spec = template.get("spec", {}) if isinstance(template, dict) else {}
    return pod_spec.get("containers", []) or []


if __name__ == "__main__":
    raise SystemExit(main())
