"""Application logging setup.

``LOG_LEVEL`` has been in the ConfigMap since Faz 5 and in ``Settings`` since
Faz 1, but nothing ever read it: no handler was installed, so the root logger
kept its default WARNING and every ``logger.info`` in the app went nowhere.
The startup diagnostic in ``main.py`` — the one line that says which
environment, which database and whether the mentor has a key — was invisible in
``kubectl logs`` for the whole of Faz 5. This is what makes it real.

uvicorn installs its own logging config before it imports the app, so calling
``configure_logging()`` at import time in ``app.main`` deliberately runs second
and wins.
"""

from __future__ import annotations

import logging
import logging.config

from app.core.config import settings

#: Everything the app writes goes here. Containers collect stdout, so a
#: separate log file or stderr split would only hide records from `kubectl
#: logs`.
_STREAM = "ext://sys.stdout"

_FORMAT = "%(asctime)s %(levelname)-8s %(name)s | %(message)s"
_DATEFMT = "%Y-%m-%dT%H:%M:%S%z"

DEFAULT_LEVEL = "INFO"

#: Libraries whose DEBUG output is a privacy problem, not a debugging aid.
#: The OpenAI SDK logs every outbound request at DEBUG, and that request body
#: is the mentor prompt — it carries the learner's context (xp, level, streak,
#: recent decisions). The key itself is not in there (the SDK records only
#: `bearer_auth: True`), but the user data is, and `LOG_LEVEL: debug` is a
#: one-word ConfigMap edit away. Turning up the application's own verbosity
#: must not turn these on with it.
#:
#: Both spellings are pinned deliberately: the OpenAI SDK ships against the
#: vendored `httpx2`/`httpcore2` distributions, which are the names that
#: actually appeared in the pod logs, while a direct `httpx` dependency would
#: log under the plain names.
THIRD_PARTY_LOGGERS = (
    "openai",
    "httpx",
    "httpcore",
    "httpx2",
    "httpcore2",
)

#: Floor for the loggers above. They are never quieter than the application —
#: a stricter LOG_LEVEL still applies — but never noisier either.
THIRD_PARTY_FLOOR = "WARNING"


def resolve_level(value: str | None) -> str:
    """Normalise a configured level, falling back rather than crashing.

    ``LOG_LEVEL`` arrives from a ConfigMap, which is a plain string a human
    edits. A typo there should degrade to INFO, not take the pod down on
    startup with a dictConfig ValueError.
    """
    candidate = (value or "").strip().upper()
    return candidate if candidate in logging.getLevelNamesMapping() else DEFAULT_LEVEL


def configure_logging(level: str | None = None) -> str:
    """Install the app's logging configuration. Returns the level applied."""
    resolved = resolve_level(level if level is not None else settings.log_level)
    # max(), not a fixed WARNING: LOG_LEVEL=error should quiet these too.
    third_party = (
        resolved
        if logging.getLevelNamesMapping()[resolved]
        > logging.getLevelNamesMapping()[THIRD_PARTY_FLOOR]
        else THIRD_PARTY_FLOOR
    )

    logging.config.dictConfig(
        {
            "version": 1,
            # Never True: uvicorn's loggers already exist by the time this
            # runs, and disabling them would silence the server itself.
            "disable_existing_loggers": False,
            "formatters": {"default": {"format": _FORMAT, "datefmt": _DATEFMT}},
            "handlers": {
                "stdout": {
                    "class": "logging.StreamHandler",
                    "stream": _STREAM,
                    "formatter": "default",
                }
            },
            # One handler, on the root. Everything else just sets a level and
            # propagates, so a record is formatted once and printed once.
            "root": {"handlers": ["stdout"], "level": resolved},
            "loggers": {
                # The app's own namespace, plus the module-level loggers that
                # use __name__ (app.services.mentor and friends).
                "finquest": {"level": resolved, "handlers": [], "propagate": True},
                "app": {"level": resolved, "handlers": [], "propagate": True},
                # Hand uvicorn's records to the same handler so server and
                # application lines share one format. Clearing `handlers`
                # replaces uvicorn's own, which is what stops double printing.
                "uvicorn": {"level": resolved, "handlers": [], "propagate": True},
                "uvicorn.error": {"level": resolved, "handlers": [], "propagate": True},
                "uvicorn.access": {
                    "level": resolved,
                    "handlers": [],
                    "propagate": True,
                },
                **{
                    name: {
                        "level": third_party,
                        "handlers": [],
                        "propagate": True,
                    }
                    for name in THIRD_PARTY_LOGGERS
                },
            },
        }
    )
    return resolved
