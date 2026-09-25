#!/usr/bin/env python3
"""What the members say to each other.

The architecture's whole trade-off is *where coordination is decided*, so the
thing that carries coordination traffic has to be a named, replaceable part
rather than a function call between objects. This is the interface; the
forerunner's implementation delivers in memory.

Deliberately not a real bus yet. The plan's stage 2 cuts the mesh to animate
the trade-off, and that is when a UDP implementation earns its place — a run
with twenty-five processes in it does not need a twenty-sixth before anything
has flown. Everything above this speaks `Mesh`, so stage 2 swaps the class and
nothing else changes.
"""
from __future__ import annotations

from collections import defaultdict, deque
from dataclasses import dataclass
from typing import Any


@dataclass(frozen=True)
class Message:
    """One thing a member told the others."""

    sender: int
    kind: str
    """The coordination function that sent it, by the model's name."""
    body: dict[str, Any]


class Mesh:
    """The bearer, as far as the agents are concerned."""

    def __init__(self, members: list[int]) -> None:
        self._inboxes: dict[int, deque[Message]] = {m: deque() for m in members}
        self._reachable: set[int] = set(members)
        self.sent: list[Message] = []
        # Two bearers, not one. Members talk to each other over the mesh; the
        # ground talks to them over the ground link. The architecture's whole
        # trade-off is which of those a decision depends on, so cutting one
        # must not cut the other — a simulation that conflated them could not
        # tell the two alternatives apart at all.
        self.ground_up = True

    GROUND = -1
    """The ground station speaks over the ground link, not over the mesh."""

    def broadcast(self, sender: int, kind: str, **body: Any) -> Message:
        message = Message(sender=sender, kind=kind, body=body)
        self.sent.append(message)
        # A member that has been cut off talks to nobody. The ground is not a
        # member and is not subject to that: its traffic is the ground link,
        # which stage 2 cuts separately. Treating it as an unreachable member
        # silently dropped every tasking the ground ever sent, and the only
        # symptom was a fleet that launched once and never flew again.
        if sender != self.GROUND and sender not in self._reachable:
            return message
        for member, inbox in self._inboxes.items():
            if member != sender and member in self._reachable:
                inbox.append(message)
        return message

    def broadcast_from_ground(self, kind: str, **body: Any) -> Message:
        """Tasking, which reaches every member the ground link still has."""
        message = Message(sender=self.GROUND, kind=kind, body=body)
        self.sent.append(message)
        if not self.ground_up:
            # Recorded as sent and delivered nowhere. The operator does not
            # know the link is down either.
            return message
        for member, inbox in self._inboxes.items():
            inbox.append(message)
        return message

    def cut_ground_link(self) -> None:
        """The ground station stops reaching anybody. Stage 2's instrument."""
        self.ground_up = False

    def restore_ground_link(self) -> None:
        self.ground_up = True

    def receive(self, member: int) -> list[Message]:
        inbox = self._inboxes[member]
        out = list(inbox)
        inbox.clear()
        return out

    # -- what stage 2 will use ---------------------------------------------

    def isolate(self, member: int) -> None:
        """Cut one member off. Its `Isolated` mode is what the model calls this."""
        self._reachable.discard(member)

    def rejoin(self, member: int) -> None:
        self._reachable.add(member)

    def is_reachable(self, member: int) -> bool:
        return member in self._reachable
