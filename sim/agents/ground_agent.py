#!/usr/bin/env python3
"""The operator's side, and the board of who is watching what.

Two `#C2` functions the brief names — `taskMission` and `recallAndLand` — plus
the bookkeeping that turns one member's `handOverSector` into another member's
launch. In the chosen architecture (alternative 2) the deciding coordination
lives on the drones; what stays on the ground is command, and the sector board
is what an operator would have in front of them.

The board is also where the forerunner's central arithmetic becomes visible.
Twelve members on a 40/60 duty cycle put 4.8 of them in the air at a time, so
twelve sectors cannot all be held: some requests for a relief will find nobody
charged to send. That is not handled as an error — it is recorded as an
unfilled handover, and it is the finding the run exists to produce.
"""
from __future__ import annotations

from dataclasses import dataclass, field

from log import EventLog
from member_agent import MemberAgent
from mesh import Mesh


@dataclass
class GroundAgent:
    """Command, and the board of who holds which sector."""

    members: dict[int, MemberAgent]
    mesh: Mesh
    log: EventLog
    sectors: list[int]
    root: str
    unfilled: list[tuple[float, int]] = field(default_factory=list)
    """(time, sector) once per episode a sector went unfilled — not per tick."""
    _dark: set = field(default_factory=set)
    """Sectors currently uncovered with nobody to send."""

    def _element(self, name: str) -> str:
        return f"{self.root}::PA::{name}"

    # -- the two C2 functions ----------------------------------------------

    def taskMission(self, t: float) -> None:
        """Put the fleet to work: one member to each sector it can fill."""
        self.log.record(t, "command", element=self._element("taskMission"),
                        sectors=len(self.sectors), members=len(self.members))
        for sector, member in zip(self.sectors, sorted(self.members)):
            self.members[member].launch(t, sector)

    def recallAndLand(self, t: float) -> None:
        """Bring everyone home. The operator's stop button."""
        self.log.record(t, "command", element=self._element("recallAndLand"),
                        members=len(self.members))
        for member in self.members.values():
            if member.state not in (member.states.landed, member.states.lost):
                member.rotateRecharge(t)

    # -- the board ----------------------------------------------------------

    def watched_sectors(self) -> set[int]:
        return {
            m.sector for m in self.members.values()
            if m.state == m.states.watching
        }

    def uncovered(self) -> list[int]:
        return [s for s in self.sectors if s not in self.watched_sectors()]

    def available(self, t: float) -> list[int]:
        """Members on a pad with charge in them, soonest-ready first."""
        ready = [
            m for m in self.members.values()
            if m.state == m.states.landed and m.recharged(t)
        ]
        return [m.index for m in sorted(ready, key=lambda m: m.charged_at)]

    def step(self, t: float) -> None:
        """Observe what is dark, then fill it — if this architecture can."""
        # In the ground-decided architecture the rotation is the ground's call:
        # a member at its reserve waits to be told. Sending it is the ground's
        # whole job here, and being unable to send it is what the trade-off is
        # about — when the link is down this still runs, and reaches nobody.
        for member in self.members.values():
            if member.decides_locally or not member.handover_requested:
                continue
            if member.state != member.states.watching:
                continue
            self.mesh.broadcast_from_ground("rotateNow", member=member.index)
            self.log.record(t, "behaviour", member=member.index,
                            element=self._element("rotateRecharge"),
                            ordered_to_rotate=True, reached=self.mesh.ground_up)

        # Observing a dark sector is not deciding anything, so it happens under
        # either architecture. An earlier version buried it in the ground's
        # decision path and the on-board fleet silently stopped recording the
        # brief's own arithmetic.
        uncovered = set(self.uncovered())
        for sector in self._dark - uncovered:
            self._dark.discard(sector)
        free_now = self.available(t)
        for sector in sorted(uncovered):
            if free_now or sector in self._dark:
                continue
            self._dark.add(sector)
            self.unfilled.append((round(t), sector))
            self.log.record(
                t, "note", element=self._element("rotateRecharge"),
                unfilled_sector=sector,
                why="no member has charge: 12 members on a 40/60 duty cycle "
                    "put 4.8 in the air at once, and there are 12 sectors",
            )

        peer_decided = [m for m in self.members.values() if m.decides_locally]
        if peer_decided:
            # The members settle it over the mesh. The ground doing it as well
            # would hide exactly the difference this study exists to measure.
            held = self.watched_sectors() | {
                m.sector for m in self.members.values()
                if m.state == m.states.launching
            }
            for member in sorted(peer_decided, key=lambda m: m.index):
                if member.state != member.states.landed or not member.recharged(t):
                    continue
                if member.claimSector(t, held, self.sectors):
                    held.add(member.sector)
            return

        # Ground-decided: the order has to travel down the link. Calling the
        # member directly was the bug that made this whole study meaningless —
        # the ground kept tasking a fleet it could no longer reach, and the two
        # architectures measured the same because neither was ever cut off.
        if not self.mesh.ground_up:
            for sector in sorted(uncovered):
                if sector in self._dark:
                    continue
                self._dark.add(sector)
                self.log.record(
                    t, "note", element=self._element("taskMission"),
                    unreachable_sector=sector,
                    why="the ground decides rotation in this architecture and the "
                        "ground link is down, so nothing can be tasked to this sector",
                )
            return

        for sector in self.uncovered():
            free = self.available(t)
            if not free:
                continue
            self.mesh.broadcast_from_ground("takeSector", member=free[0], sector=sector)
            self.log.record(t, "behaviour", member=free[0],
                            element=self._element("rotateRecharge"),
                            takes_sector=sector)
            self.members[free[0]].launch(t, sector)
