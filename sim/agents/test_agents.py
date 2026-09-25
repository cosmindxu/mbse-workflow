#!/usr/bin/env python3
"""The agents, flown against a fake autopilot.

Nothing here starts Gazebo. A `FakeLink` stands in for one SITL instance and
reports whatever altitude the test puts in it, so the member's machine — launch,
watch, reach the reserve, hand over, recharge — is exercised in milliseconds and
deterministically. What this cannot test is whether the autopilot obeys; that is
what the live run is for.
"""
from __future__ import annotations

import unittest

from ground_agent import GroundAgent
from log import EventLog
from member_agent import Duty, MemberAgent, States
from mesh import Mesh
from metrics import coverage_over_time
from monitors import wins_until


class FakeLink:
    """One autopilot, as far as an agent can tell."""

    def __init__(self, index: int) -> None:
        self.index = index
        self.altitude = 0.0
        self.commands: list[tuple] = []
        self._at = (0.0, 0.0)

    def position(self) -> tuple[float, float]:
        return self._at

    def pump(self) -> None:
        pass

    def takeoff(self, altitude: float) -> None:
        self.commands.append(("takeoff", altitude))
        self.altitude = altitude          # a cooperative autopilot

    def goto(self, north: float, east: float, altitude: float) -> None:
        self.commands.append(("goto", north, east, altitude))
        self._at = (north, east)          # this fake arrives at once, on purpose

    def return_to_launch(self) -> None:
        self.commands.append(("rtl",))
        self._at = (0.0, 0.0)
        self.altitude = 0.0               # and it lands promptly

    def land(self) -> None:
        self.commands.append(("land",))
        self.altitude = 0.0


def make_fleet(members: int, sectors: int, *, flight=240.0, recharge=360.0):
    log = EventLog()
    mesh = Mesh(list(range(members)))
    duty = Duty(flight_seconds=flight, recharge_seconds=recharge, time_scale=10)
    geometry = {s + 1: (s * 100.0, s * 100.0) for s in range(sectors)}
    agents = {
        i: MemberAgent(
            index=i, sector=i + 1, link=FakeLink(i), mesh=mesh, log=log, duty=duty,
            sectors=geometry, watch_altitude=60.0, root="Swarm",
        )
        for i in range(members)
    }
    ground = GroundAgent(members=agents, mesh=mesh, log=log,
                         sectors=list(range(1, sectors + 1)), root="Swarm")
    return log, mesh, agents, ground


class MemberMachine(unittest.TestCase):
    def test_a_tasked_member_launches_then_watches(self):
        log, _, agents, ground = make_fleet(1, 1)
        member = agents[0]
        ground.taskMission(0)
        self.assertEqual(member.state, States().launching)
        member.step(1)
        self.assertEqual(member.state, States().watching)
        self.assertIn(("takeoff", 60.0), member.link.commands)
        # It flew to its sector, at its deconflicted height.
        self.assertTrue(any(c[0] == "goto" for c in member.link.commands))

    def test_it_asks_for_a_relief_at_the_reserve_and_waits_for_one(self):
        log, mesh, agents, ground = make_fleet(1, 1, flight=100.0)
        member = agents[0]
        ground.taskMission(0)
        member.step(1)
        self.assertEqual(member.state, States().watching)
        # 80% of a 100 s budget is the reserve: it asks, and keeps watching.
        member.step(85)
        self.assertTrue(member.handover_requested)
        self.assertTrue(any(m.kind == "handOverSector" for m in mesh.sent))
        self.assertEqual(member.state, States().watching,
                         "leaving before a relief arrives is not a handover")

    def test_it_goes_when_relieved(self):
        _, mesh, agents, ground = make_fleet(1, 1, flight=100.0)
        member = agents[0]
        ground.taskMission(0)
        member.step(1)
        member.step(85)
        member.relieved = True
        member.step(86)
        self.assertEqual(member.state, States().recalled)
        member.step(87)
        self.assertEqual(member.state, States().landed)

    def test_it_goes_anyway_when_the_flight_budget_is_spent(self):
        # The reserve is a margin, not a promise. A member nobody relieves must
        # still come home rather than fly on a budget it does not have.
        _, _, agents, ground = make_fleet(1, 1, flight=100.0)
        member = agents[0]
        ground.taskMission(0)
        member.step(1)
        member.step(85)
        self.assertEqual(member.state, States().watching)
        member.step(101)
        self.assertEqual(member.state, States().recalled)

    def test_charge_is_the_agents_and_traces_to_the_budget(self):
        _, _, agents, _ = make_fleet(1, 1, flight=240.0)
        member = agents[0]
        member.flying_since = 0.0
        self.assertFalse(member.at_reserve(191))
        self.assertTrue(member.at_reserve(192))   # 0.8 x 240
        self.assertAlmostEqual(member.duty.usable_seconds, 192.0)

    def test_a_recharging_member_is_not_available_until_it_is_charged(self):
        _, _, agents, ground = make_fleet(1, 1, recharge=360.0)
        member = agents[0]
        member.state = States().landed
        member.charged_at = 100.0
        self.assertFalse(member.recharged(300))
        self.assertTrue(member.recharged(460))
        self.assertEqual(ground.available(300), [])
        self.assertEqual(ground.available(460), [0])

    def test_deconfliction_is_computed_alone_and_agrees_across_members(self):
        _, _, agents, _ = make_fleet(4, 4)
        heights = {i: agents[i].deconflictMembers(0) for i in agents}
        self.assertEqual(len(set(heights.values())), 4, "members must not share a height")


class GroundBoard(unittest.TestCase):
    def test_it_tasks_one_member_per_sector(self):
        _, _, agents, ground = make_fleet(4, 4)
        ground.taskMission(0)
        for member in agents.values():
            member.step(1)
        self.assertEqual(ground.watched_sectors(), {1, 2, 3, 4})
        self.assertEqual(ground.uncovered(), [])

    def test_an_uncovered_sector_with_nobody_charged_is_recorded_not_hidden(self):
        # Two members, four sectors: the arithmetic the demonstration exists
        # to show. Nobody is charged, so two sectors simply cannot be filled.
        log, _, agents, ground = make_fleet(2, 4)
        for member in agents.values():
            member.decides_locally = False      # the ground-decided architecture
        ground.taskMission(0)
        for member in agents.values():
            member.step(1)
        ground.step(2)
        self.assertTrue(ground.unfilled, "an unfillable sector must be recorded")
        notes = [e for e in log.events if e.kind == "note" and "unfilled_sector" in e.detail]
        self.assertTrue(notes)
        self.assertIn("4.8 in the air", notes[0].detail["why"])

    def test_recall_brings_everyone_home(self):
        _, _, agents, ground = make_fleet(3, 3)
        ground.taskMission(0)
        for member in agents.values():
            member.step(1)
        ground.recallAndLand(50)
        for member in agents.values():
            self.assertEqual(member.state, States().recalled)


class WhatTheLogProves(unittest.TestCase):
    """The agents and the monitors, end to end, with no autopilot at all."""

    def test_a_full_rotation_obeys_RecallWins_and_shows_the_gap(self):
        log, _, agents, ground = make_fleet(2, 2, flight=100.0, recharge=50.0)
        ground.taskMission(0)
        t = 1.0
        while t < 200:
            for member in agents.values():
                member.step(t)
            ground.step(t)
            t += 1.0

        verdict = wins_until(log.events, "RecallWins", trigger="Recalled",
                             forbidden="Watching", until="Landed")
        self.assertTrue(verdict.held, verdict.detail)
        self.assertGreater(verdict.checked, 0, "the run must actually exercise the rule")

        coverage = coverage_over_time(log.events, sectors=2, watching="Watching", until=200)
        # Both sectors held at first, and the rotation leaves a gap: with two
        # members and two sectors there is no spare, so coverage cannot stay at 1.
        self.assertLess(coverage.mean, 1.0)
        self.assertGreater(coverage.mean, 0.0)

    def test_the_log_names_model_elements_not_this_code(self):
        log, _, agents, ground = make_fleet(1, 1, flight=50.0)
        ground.taskMission(0)
        agents[0].step(1)
        agents[0].step(45)    # at the reserve: asks for a relief
        agents[0].step(55)    # budget spent: goes anyway
        elements = {e.element for e in log.events if e.element}
        self.assertIn("Swarm::PA::taskMission", elements)
        self.assertIn("Swarm::PA::handOverSector", elements)
        self.assertIn("Swarm::PA::rotateRecharge", elements)
        for element in elements:
            self.assertTrue(element.startswith("Swarm::"), element)


if __name__ == "__main__":
    unittest.main()


class TheTradeOff(unittest.TestCase):
    """Stage 2: the two architectures must be distinguishable once cut off."""

    def test_a_ground_decided_fleet_cannot_rotate_without_its_link(self):
        _, mesh, agents, ground = make_fleet(2, 2, flight=100.0, recharge=10.0)
        for member in agents.values():
            member.decides_locally = False
        ground.taskMission(0)
        for m in agents.values():
            m.step(1)
        mesh.cut_ground_link()
        # Past the reserve: each asks, and the order can no longer reach it.
        for t in range(85, 95):
            for m in agents.values():
                m.step(t)
            ground.step(t)
        for m in agents.values():
            self.assertTrue(m.handover_requested, "it asked")
            self.assertFalse(m.told_to_rotate, "and nobody could answer")
            self.assertEqual(m.state, States().watching, "so it holds station")

    def test_an_onboard_fleet_relaunches_with_no_ground_at_all(self):
        _, mesh, agents, ground = make_fleet(2, 2, flight=100.0, recharge=5.0)
        ground.taskMission(0)
        mesh.cut_ground_link()          # cut before anything else happens
        t = 1.0
        while t < 400:
            for m in agents.values():
                m.step(t)
            ground.step(t)
            t += 1.0
        # With no ground at all, members still rotated and took sectors again.
        relaunched = [e for e in ground.log.events
                      if e.kind == "behaviour" and "claimed_sector" in e.detail]
        self.assertTrue(relaunched, "peers must be able to fill a dark sector unaided")
        self.assertEqual(relaunched[0].detail["decided"], "between members, over the mesh")


class TheWayHome(unittest.TestCase):
    """A reserve that ignores distance is not a reserve."""

    def test_a_distant_member_turns_for_home_earlier_than_a_near_one(self):
        _, _, agents, _ = make_fleet(2, 2, flight=240.0)
        near, far = agents[0], agents[1]
        for m in (near, far):
            m.cruise_speed = 15.0
            m.flying_since = 0.0
        near.link._at = (150.0, 0.0)     # ten seconds from home
        far.link._at = (2250.0, 0.0)     # two and a half minutes from home
        # Usable budget is 192 s. The near one may stay almost to it; the far
        # one has to leave with its whole return leg still to fly.
        self.assertFalse(near.at_reserve(150))
        self.assertTrue(far.at_reserve(150), "a member 2.25 km out must already be going home")

    def test_a_member_with_no_position_falls_back_to_the_flat_reserve(self):
        _, _, agents, _ = make_fleet(1, 1, flight=100.0)
        m = agents[0]
        m.link = None
        m.flying_since = 0.0
        self.assertFalse(m.at_reserve(79))
        self.assertTrue(m.at_reserve(80))


class TheOtherCoordinationFunctions(unittest.TestCase):
    def test_a_quarantined_member_does_not_admit_anybody(self):
        _, _, agents, _ = make_fleet(2, 2)
        gatekeeper = agents[0]
        self.assertTrue(gatekeeper.admitMember(1, joining=1))
        gatekeeper.quarantine(2)
        self.assertFalse(gatekeeper.admitMember(3, joining=1),
                         "a member that is out cannot vouch for anyone")

    def test_only_an_airborne_reachable_member_can_relay(self):
        _, mesh, agents, ground = make_fleet(2, 2)
        ground.taskMission(0)
        for m in agents.values():
            m.step(1)
        self.assertTrue(agents[0].relayLink(2, for_member=1))
        mesh.isolate(0)
        self.assertFalse(agents[0].relayLink(3, for_member=1),
                         "a member the mesh has cut off cannot be somebody else's relay")

    def test_both_appear_in_the_log_under_their_model_names(self):
        log, _, agents, _ = make_fleet(2, 2)
        agents[0].admitMember(1, joining=1)
        agents[0].relayLink(2, for_member=1)
        elements = {e.element for e in log.events if e.element}
        self.assertIn("Swarm::PA::admitMember", elements)
        self.assertIn("Swarm::PA::relayLink", elements)
