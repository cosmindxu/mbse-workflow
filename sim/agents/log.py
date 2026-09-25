#!/usr/bin/env python3
"""What happened, in the model's own words.

Every event carries the qualified name of the model element it belongs to, so
the run can be read back against the architecture rather than against this
code. `handOverSector` in the log is `SurveillanceDroneSwarm::PA::handOverSector`
in the model, and the report's traceability section is a join on that column.

One line of JSON per event, because the monitors and the metrics are pure
functions over the log and nothing else: they can be tested against a log
written by hand, and they can be re-run over a recorded flight without flying
it again.
"""
from __future__ import annotations

import json
import pathlib
import threading
import time
from dataclasses import asdict, dataclass, field
from typing import Any


@dataclass(frozen=True)
class Event:
    """One thing that happened, and who it happened to."""

    t_sim: float
    """Seconds of simulated time since the scenario began."""
    t_wall: float
    """Seconds of wall clock, so a stall in the runtime is visible in the log."""
    kind: str
    """`state`, `behaviour`, `command`, `fault`, `note`."""
    member: int | None
    """The instance it concerns, or None for the fleet as a whole."""
    element: str | None
    """The qualified name of the model element, where there is one."""
    detail: dict[str, Any] = field(default_factory=dict)


class EventLog:
    """An append-only JSONL log, safe to write from several agents at once."""

    def __init__(self, path: pathlib.Path | None = None) -> None:
        self.path = path
        self.events: list[Event] = []
        self._lock = threading.Lock()
        self._started_wall = time.time()
        self._file = None
        if path is not None:
            path.parent.mkdir(parents=True, exist_ok=True)
            self._file = path.open("w", encoding="utf-8")

    def record(
        self,
        t_sim: float,
        kind: str,
        *,
        member: int | None = None,
        element: str | None = None,
        **detail: Any,
    ) -> Event:
        event = Event(
            t_sim=round(t_sim, 3),
            t_wall=round(time.time() - self._started_wall, 3),
            kind=kind,
            member=member,
            element=element,
            detail=detail,
        )
        with self._lock:
            self.events.append(event)
            if self._file is not None:
                self._file.write(json.dumps(asdict(event)) + "\n")
                self._file.flush()
        return event

    def close(self) -> None:
        if self._file is not None:
            self._file.close()
            self._file = None

    # -- reading back -------------------------------------------------------

    @staticmethod
    def read(path: pathlib.Path) -> list[Event]:
        """A log written earlier, as events again. This is what the report reads."""
        events: list[Event] = []
        for line in path.read_text(encoding="utf-8").splitlines():
            if not line.strip():
                continue
            raw = json.loads(line)
            events.append(Event(**raw))
        return events

    def of_kind(self, kind: str) -> list[Event]:
        return [e for e in self.events if e.kind == kind]


def state_changes(events: list[Event]) -> list[Event]:
    """Just the state transitions, in order. The monitors walk these."""
    return [e for e in events if e.kind == "state"]
