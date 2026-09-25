#!/usr/bin/env python3
"""One member of the swarm, flying the machine the model gives it.

The states are the model's own, read from `mapping.yaml` — `Landed`,
`Launching`, `Watching`, `Recalled`, `Landing` — and never typed in here, so a
brief whose drones have different states produces an agent that uses those.
Each `#Coordination` function the brief names is a method with that name, and
each one records an event carrying the function's qualified name, so the log
reads as the architecture and not as this file.

The duty cycle is the agent's, because WP0.4 measured that it cannot be the
autopilot's: through Gazebo, SITL takes battery state from the simulator and
`ardupilot_gazebo` sends none, so no `BATT_*` failsafe ever fires. That suits
the architecture — `rotateRecharge` is allocated to the coordination node — and
it is what makes `RecallWins` observable at all, since recall and recharge then
contend inside one agent.
"""
from __future__ import annotations

from dataclasses import dataclass, field
from typing import TYPE_CHECKING, Any

from log import EventLog
from mesh import Mesh

if TYPE_CHECKING:  # pragma: no cover
    from mavlink_link import MavlinkLink

# The agent's logic does not depend on the transport, and must not import it:
# pymavlink lives in the runtime image, and every one of these behaviours is
# worth testing on a machine that has never heard of an autopilot. What the
# agent needs from a link is `pump`, `takeoff`, `goto` and `return_to_launch`,
# which a dozen lines of fake satisfies.
Link = Any


@dataclass
class Duty:
    """What the brief's budgets say a flight and a recharge cost, scaled."""

    flight_seconds: float
    recharge_seconds: float
    time_scale: float
    reserve_share: float = 0.2
    """How much of the flight budget is kept back — an operator's margin."""

    @property
    def usable_seconds(self) -> float:
        return self.flight_seconds * (1.0 - self.reserve_share)


@dataclass
class States:
    """The member's state names, as the model spells them."""

    landed: str = "Landed"
    launching: str = "Launching"
    watching: str = "Watching"
    recalled: str = "Recalled"
    landing: str = "Landing"
    isolated: str = "Isolated"
    outside: str = "OutsideClearance"
    lost: str = "Lost"

    @classmethod
    def from_mapping(cls, mapping: dict) -> "States":
        """Read the names out of T-05's mapping, keeping whatever it found.

        A state the model does not have keeps this class's default rather than
        being invented: the agent then simply never enters it, which is visible
        in the log as a state that never appears.
        """
        names = {row["state"] for row in mapping.get("states", [])}
        chosen = cls()
        for field_name, default in vars(cls()).items():
            for name in names:
                if name.lower() == default.lower():
                    setattr(chosen, field_name, name)
        return chosen


@dataclass
class MemberAgent:
    """A drone's share of the coordination, and its own duty cycle."""

    index: int
    sector: int
    link: "MavlinkLink | None"
    mesh: Mesh
    log: EventLog
    duty: Duty
    sectors: dict[int, tuple[float, float]]
    """Sector id → (north, east) metres from home."""
    watch_altitude: float
    root: str
    states: States = field(default_factory=States)

    state: str = ""
    flying_since: float | None = None
    charged_at: float = 0.0
    handover_requested: bool = False
    relieved: bool = False
    """Set when another member reports watching this one's sector."""
    decides_locally: bool = True
    """Where this member's coordination is decided.

    The architecture's central choice. `True` is alternative 2: the member
    settles handover and rotation with its peers over the mesh. `False` is
    alternative 1: the ground decides, and a member waits to be told. The
    difference is invisible while the ground link is up and is the entire
    trade-off once it is not.
    """
    told_to_rotate: bool = False
    """A ground-decided member only goes when the ground says so."""
    cruise_speed: float = 15.0
    """How fast it transits, for working out when it must start home."""
    arrival_radius: float = 75.0
    """How close to its sector's centre a member has to be to be watching it."""
    commanded_to_sector: bool = False
    peers_hold: dict = field(default_factory=dict)
    """Sector → the peer last heard holding it. The mesh's picture, not the ground's."""

    def __post_init__(self) -> None:
        if not self.state:
            self.state = self.states.landed

    # -- the model's own vocabulary ----------------------------------------

    def _element(self, name: str) -> str:
        return f"{self.root}::PA::{name}"

    def _enter(self, t: float, state: str, **detail) -> None:
        if state == self.state:
            return
        previous, self.state = self.state, state
        self.log.record(
            t, "state", member=self.index,
            element=f"{self.root}::PA::SurveillanceDrone::MemberState",
            **{"from": previous, "to": state, "sector": self.sector, **detail},
        )

    def _behaviour(self, t: float, function: str, **detail) -> None:
        self.log.record(
            t, "behaviour", member=self.index, element=self._element(function), **detail
        )

    # -- charge, which is this agent's and nobody else's --------------------

    def charge_used(self, t: float) -> float:
        if self.flying_since is None:
            return 0.0
        return t - self.flying_since

    def seconds_home(self) -> float:
        """How long the return leg will take from where it is now."""
        position = getattr(self.link, "position", None) if self.link else None
        if position is None or self.cruise_speed <= 0:
            return 0.0
        north, east = position()
        return ((north * north + east * east) ** 0.5) / self.cruise_speed

    def at_reserve(self, t: float) -> bool:
        """Time to start thinking about going home.

        The reserve is not a fixed share of the budget: it is a share *plus the
        way back*. A member 2.5 km out needs three minutes to reach its pad, and
        an agent that leaves at a flat 80% regardless of where it is will land
        late or not at all. Flown without this, all twelve members returned
        beyond their flight budget — the runtime recorded it as a fault against
        the endurance, which is exactly the right complaint about an agent that
        cannot read a map.
        """
        return self.charge_used(t) + self.seconds_home() >= self.duty.usable_seconds

    def recharged(self, t: float) -> bool:
        return self.state == self.states.landed and t - self.charged_at >= self.duty.recharge_seconds

    # -- the four coordination functions, by their model names --------------

    def handOverSector(self, t: float) -> None:
        """Ask the fleet for a relief before leaving, and say which sector."""
        if self.handover_requested:
            return
        self.handover_requested = True
        self._behaviour(t, "handOverSector", sector=self.sector,
                        reason="reserve reached", charge_used=round(self.charge_used(t), 1))
        self.mesh.broadcast(self.index, "handOverSector", sector=self.sector, at=t)

    def rotateRecharge(self, t: float) -> None:
        """Go home and charge. The recall the model means by `Recalled`."""
        self._behaviour(t, "rotateRecharge", sector=self.sector)
        self._enter(t, self.states.recalled)
        if self.link:
            self.link.return_to_launch()

    def claimSector(self, t: float, sectors_held: set, all_sectors: list) -> bool:
        """Take an empty sector, decided with peers rather than by the ground.

        This is what `decides_locally` actually buys, and it is the whole of the
        architecture trade-off. A member on a pad with charge in it hears which
        sectors its peers are holding, and if one is dark it claims the lowest
        unheld one and goes. No ground station is involved, so cutting the
        ground link does not stop it.

        The first version of this simulation had the ground relaunch members in
        *both* architectures, which quietly erased the difference being
        measured: with the link cut, neither could rotate, and the ground-decided
        design scored marginally better because its members stayed up longer
        rather than coming home. A trade-off study that cannot tell the two
        alternatives apart is worse than none.
        """
        if not self.decides_locally:
            return False
        dark = [s for s in all_sectors if s not in sectors_held]
        if not dark:
            return False
        self._behaviour(t, "redistributeCoverage", claimed_sector=dark[0],
                        decided="between members, over the mesh")
        self.mesh.broadcast(self.index, "claiming", sector=dark[0], at=t)
        self.launch(t, dark[0])
        return True

    def redistributeCoverage(self, t: float, sector: int) -> None:
        """Take on a sector nobody is watching."""
        self._behaviour(t, "redistributeCoverage", from_sector=self.sector, to_sector=sector)
        self.sector = sector
        if self.link:
            north, east = self.sectors[sector]
            self.link.goto(north, east, self.watch_altitude)

    def admitMember(self, t: float, joining: int) -> bool:
        """Decide whether a member may take part in coordination.

        The model makes admission a coordination function, and `QuarantinedStaysOut`
        is a rule about what happens when it fails. A member that has been
        quarantined is not readmitted by the same peers that excluded it without
        something changing — here, it has to have been home and recharged, which
        is the only fact this simulation has about a member's condition.
        """
        peer = self.mesh
        admitted = self.state != "Quarantined"
        self._behaviour(t, "admitMember", candidate=joining, admitted=admitted)
        if admitted:
            peer.broadcast(self.index, "admitted", member=joining, at=t)
        return admitted

    def relayLink(self, t: float, for_member: int) -> bool:
        """Carry a peer's traffic when it cannot reach the others itself.

        Only a member that is airborne and in touch can relay, so this says
        what it can and refuses what it cannot: a member the mesh has cut off
        cannot be somebody else's relay. That refusal is the whole content of
        the function in a run with no radio model — and stage 2's link cutting
        is where it starts to matter.
        """
        able = self.mesh.is_reachable(self.index) and self.state == self.states.watching
        self._behaviour(t, "relayLink", relaying_for=for_member, able=able)
        if able:
            self.mesh.broadcast(self.index, "relaying", member=for_member, at=t)
        return able

    def deconflictMembers(self, t: float) -> float:
        """Keep members apart in height, by a rule every member can apply alone.

        Ten metres per member index. It is arbitrary, it is deterministic, and
        every member computes the same answer for every other without talking —
        which is what makes it deconfliction rather than negotiation.
        """
        offset = (self.index % 4) * 10.0
        self._behaviour(t, "deconflictMembers", altitude_offset=offset)
        return self.watch_altitude + offset

    def _home_again(self) -> bool:
        """Back at the pad. The return leg is most of a flight budget here."""
        position = getattr(self.link, "position", None)
        if position is None:
            return True
        north, east = position()
        return (north * north + east * east) ** 0.5 <= self.arrival_radius

    def at_station(self) -> bool:
        """Is it actually over its sector, or still on the way?"""
        if self.link is None:
            return True
        position = getattr(self.link, "position", None)
        if position is None:
            return True  # a link that cannot say where it is cannot be doubted
        north, east = position()
        target_n, target_e = self.sectors[self.sector]
        return ((north - target_n) ** 2 + (east - target_e) ** 2) ** 0.5 <= self.arrival_radius

    # -- the machine --------------------------------------------------------

    def step(self, t: float) -> None:
        """One pass of this member's own logic."""
        for message in self.mesh.receive(self.index):
            self._on_message(t, message)

        # A member the mesh has cut off announces it. Nothing hears it while it
        # is cut off, which is the point: the announcement is what its peers
        # act on the moment it is reachable again, and what `relayLink` answers.
        if not self.mesh.is_reachable(self.index) and self.state == self.states.watching:
            if self.state != self.states.isolated:
                self._enter(t, self.states.isolated)
            self.mesh.broadcast(self.index, "isolated", at=t)

        if self.link:
            self.link.pump()

        if self.state == self.states.launching and self.link and self.link.altitude >= self.watch_altitude - 5:
            north, east = self.sectors[self.sector]
            if not self.commanded_to_sector:
                self.link.goto(north, east, self.deconflictMembers(t))
                self.commanded_to_sector = True
            # Watching begins on arrival, not on departure.
            #
            # This counted a member as watching its sector the moment it was
            # told to go there. At this brief's scale a station is 625 to
            # 2509 m from the pads, so minutes of transit were reported as
            # coverage and every watch-share figure was an over-estimate. It
            # is invisible offline unless the stand-in autopilot flies the
            # distance too, which is why the fake now does.
            if self.at_station():
                self._enter(t, self.states.watching)
                self.flying_since = self.flying_since if self.flying_since is not None else t
                self.mesh.broadcast(self.index, "relieved", sector=self.sector, at=t)
                self.mesh.broadcast(self.index, "holding", sector=self.sector, at=t)

        elif self.state == self.states.watching and self.at_reserve(t):
            # Ask for a relief, and keep watching until one arrives. Leaving the
            # moment the reserve is reached is not `rotateRecharge`, it is
            # twelve members going home at once: the first run of this did
            # exactly that and coverage fell to zero for a whole recharge.
            # Staggering is the function's whole purpose.
            self.handOverSector(t)
            # Who may decide to go. A member that settles this with its peers
            # goes when it has been relieved; one that waits for the ground
            # goes when the ground says so, and if the ground cannot be heard
            # it keeps station until its budget runs out. That last clause is
            # not a courtesy — it is the safety floor, and it stays local in
            # both architectures, because an aircraft that cannot hear anyone
            # must still come home.
            may_go = self.relieved if self.decides_locally else self.told_to_rotate
            if may_go or self.charge_used(t) >= self.duty.flight_seconds:
                self.rotateRecharge(t)

        elif self.state == self.states.recalled and self.link and self.link.altitude < 1.0 \
                and self._home_again():
            over = self.charge_used(t) - self.duty.flight_seconds
            if over > 0:
                # It got home later than its own endurance allowed. The transit
                # gate warns about exactly this; here it is, measured, on the
                # fleet the brief specifies.
                self.log.record(
                    t, "fault", member=self.index,
                    element=f"{self.root}::Common::memberFlightEnduranceMinutes",
                    fault="returned beyond the flight budget",
                    over_budget_seconds=round(over, 1),
                    budget_seconds=self.duty.flight_seconds,
                )
            self._enter(t, self.states.landed)
            self.flying_since = None
            self.charged_at = t
            self.handover_requested = False
            self.relieved = False
            self.told_to_rotate = False
            self.commanded_to_sector = False

    def _on_message(self, t: float, message) -> None:
        """What another member's coordination means for this one."""
        if message.kind == "takeSector" and message.body.get("member") == self.index:
            self.launch(t, message.body["sector"])
        elif message.kind == "redistribute" and message.body.get("member") == self.index:
            self.redistributeCoverage(t, message.body["sector"])
        elif message.kind == "isolated" and self.state == self.states.watching:
            self.relayLink(t, message.sender)
        elif message.kind in ("holding", "claiming"):
            # A peer is on, or on its way to, that sector. Remembering it is
            # what lets a landed member tell a dark sector from a held one
            # without asking anybody.
            self.peers_hold[message.body["sector"]] = message.sender
        elif message.kind == "rotateNow" and message.body.get("member") == self.index:
            self.told_to_rotate = True
        elif message.kind == "relieved" and message.body.get("sector") == self.sector:
            # Somebody is over my sector: I can go. This is the other half of
            # handOverSector, and it is what keeps the sector covered across
            # the change rather than leaving a hole the width of a transit.
            self.relieved = True

    def launch(self, t: float, sector: int) -> None:
        """Leave the pad for a sector. The model's `Launching`."""
        self.sector = sector
        self._enter(t, self.states.launching)
        self.commanded_to_sector = False
        self.flying_since = t
        if self.link:
            self.link.takeoff(self.watch_altitude)

    def quarantine(self, t: float) -> None:
        """Admission failed: it takes no further part in coordination.

        `QuarantinedStaysOut` is a rule the model states and the forerunner
        never put to the test, so its monitor reported nothing. A rule nobody
        exercises is not evidence, and the honest fix is to exercise it.
        """
        self._enter(t, "Quarantined")
        self.log.record(t, "fault", member=self.index,
                        element=f"{self.root}::PA::admitMember", fault="quarantined")

    def breach_clearance(self, t: float) -> None:
        """Outside its cleared airspace — what `GeofenceBreachEndsWatch` is about."""
        self._enter(t, self.states.outside)
        self.log.record(t, "fault", member=self.index,
                        element=f"{self.root}::PA::{self.states.outside}",
                        fault="clearance breached")
        if self.link:
            self.link.return_to_launch()

    def mark_lost(self, t: float) -> None:
        """The injected fault: this member stops being part of the fleet."""
        self._enter(t, self.states.lost)
        self.flying_since = None
        self.log.record(t, "fault", member=self.index,
                        element=f"{self.root}::PA::{self.states.lost}", fault="member lost")
