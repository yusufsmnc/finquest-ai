#!/usr/bin/env python3
"""Offline structural checks on the k8s manifests.

Three classes of mistake that schema validation does not catch, and that a
cluster-less CI job can still find:

1. **A dangling env reference.** A ``secretKeyRef``/``configMapKeyRef`` naming a
   key that does not exist does not fail at apply time — it fails much later,
   in the pod, as ``CreateContainerConfigError``.
2. **A Service that selects nothing.** A typo in ``spec.selector`` produces a
   Service with no endpoints. Everything reports healthy; the traffic just goes
   nowhere.
3. **A malformed document** — missing ``apiVersion``/``kind``/``metadata.name``,
   or two objects of the same kind sharing a name.

The Secret is read from ``secret.example.yaml`` (placeholders), because the real
``secret.yaml`` is git-ignored and never exists on a runner. Only key *names*
matter here, so the placeholders are exactly as good as the real values.
"""

from __future__ import annotations

import sys
from pathlib import Path

import yaml

K8S_DIR = Path(__file__).resolve().parent.parent


#: The filled-in Secret is git-ignored and absent on a runner, but it does sit
#: next to the template on a developer's machine. Skipping it keeps the two
#: environments identical — and means this never reads a real credential.
IGNORED = {"secret.yaml"}


def _documents() -> list[dict]:
    docs: list[dict] = []
    for path in sorted(K8S_DIR.glob("*.yaml")):
        if path.name in IGNORED:
            continue
        with path.open(encoding="utf-8") as handle:
            docs += [
                doc | {"__file__": path.name}
                for doc in yaml.safe_load_all(handle)
                if isinstance(doc, dict)
            ]
    return docs


def _name(doc: dict) -> str:
    return doc.get("metadata", {}).get("name", "<unnamed>")


def _containers(doc: dict) -> list[dict]:
    spec = doc.get("spec", {})
    template = spec.get("template", {}) if isinstance(spec, dict) else {}
    pod_spec = template.get("spec", {}) if isinstance(template, dict) else {}
    return pod_spec.get("containers", []) or []


def _check_structure(docs: list[dict], problems: list[str]) -> None:
    seen: set[tuple[str, str]] = set()
    for doc in docs:
        origin = doc["__file__"]
        for field in ("apiVersion", "kind"):
            if not doc.get(field):
                problems.append(f"{origin}: a document is missing {field}")
        if not doc.get("metadata", {}).get("name"):
            problems.append(f"{origin}: {doc.get('kind')} has no metadata.name")
            continue
        identity = (doc.get("kind", ""), _name(doc))
        if identity in seen:
            problems.append(f"{origin}: duplicate {identity[0]}/{identity[1]}")
        seen.add(identity)


def _check_env_references(docs: list[dict], problems: list[str]) -> int:
    available = {
        "configMapKeyRef": {
            _name(doc): set(doc.get("data", {})) | set(doc.get("stringData", {}))
            for doc in docs
            if doc.get("kind") == "ConfigMap"
        },
        "secretKeyRef": {
            _name(doc): set(doc.get("data", {})) | set(doc.get("stringData", {}))
            for doc in docs
            if doc.get("kind") == "Secret"
        },
    }
    checked = 0

    def walk(node: object, origin: str) -> None:
        nonlocal checked
        if isinstance(node, dict):
            source_of = node.get("valueFrom") if isinstance(node.get("valueFrom"), dict) else {}
            for ref_kind in ("configMapKeyRef", "secretKeyRef"):
                ref = source_of.get(ref_kind)
                if isinstance(ref, dict):
                    checked += 1
                    source, key = ref.get("name"), ref.get("key")
                    known = available[ref_kind].get(source)
                    if known is None:
                        problems.append(
                            f"{origin}: no {ref_kind} source named {source!r}"
                        )
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
                for field, ref_kind in (
                    ("configMapRef", "configMapKeyRef"),
                    ("secretRef", "secretKeyRef"),
                ):
                    ref = source.get(field)
                    if ref and ref.get("name") not in available[ref_kind]:
                        problems.append(
                            f"{doc['__file__']}: envFrom names a missing "
                            f"{field} {ref.get('name')!r}"
                        )
    return checked


def _check_service_selectors(docs: list[dict], problems: list[str]) -> int:
    pod_labels = [
        doc.get("spec", {}).get("template", {}).get("metadata", {}).get("labels", {})
        for doc in docs
        if doc.get("kind") in {"Deployment", "StatefulSet", "DaemonSet"}
    ]
    checked = 0
    for doc in docs:
        if doc.get("kind") != "Service":
            continue
        selector = doc.get("spec", {}).get("selector") or {}
        if not selector:
            problems.append(f"{doc['__file__']}: Service {_name(doc)} has no selector")
            continue
        checked += 1
        if not any(
            labels and selector.items() <= labels.items() for labels in pod_labels
        ):
            problems.append(
                f"{doc['__file__']}: Service {_name(doc)} selects {selector}, "
                "which matches no pod template in k8s/"
            )
    return checked


def main() -> int:
    docs = _documents()
    problems: list[str] = []

    _check_structure(docs, problems)
    env_refs = _check_env_references(docs, problems)
    selectors = _check_service_selectors(docs, problems)

    for problem in problems:
        print(f"error: {problem}", file=sys.stderr)

    print(
        f"checked {len(docs)} manifests: "
        f"{env_refs} env key references, {selectors} service selectors"
    )
    return 1 if problems else 0


if __name__ == "__main__":
    raise SystemExit(main())
