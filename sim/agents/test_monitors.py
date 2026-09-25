#!/usr/bin/env python3
"""The monitors and the metrics, against logs written by hand.

Every case here is a log small enough to read: a handover that works, one that
leaves a sector uncovered, a recall that is obeyed and one that is not. A
monitor is only worth having if it fails on the log that breaks its rule, so
every rule is tested both ways round.

    python3 -m unittest discover -s sim/agents -p 'test_*.py'
"""
from __future__ import annotations

import unittest

from log import Event
from metrics import Coverage, coverage_over_time, loss_on_member_loss, against_target
from monitors import can_always_return, check_rules, wins_until, worth_reporting


def state(t: float, member: int, to: str, sector: int | None = None) -> Event:
    detail = {"to": to}
    if sector is not None:
        detail["sector"] = sector
    return Event(t_sim=t, t_wall=t, kind="state", member=member, element=None, detail=detail)


def fault(t: float, member: int, what: str = "member lost") -> Event:
    return Event(t_sim=t, t_wall=t, kind="fault", member=member, element=None,
                 detail={"fault": what})


class RecallWins(unittest.TestCase):
    """Once recalled, a member does not watch again until it has landed."""

    def test_holds_when_the_recall_is_obeyed(self):
        events = [
            state(0, 0, "Landed"), state(1, 0, "Watching", 1),
            state(10, 0, "Recalled"), state(20, 0, "Landing"),
            state(25, 0, "Landed"), state(30, 0, "Watching", 1),
        ]
        verdict = wins_until(events, "RecallWins", trigger="Recalled",
                             forbidden="Watching", until="Landed")
        self.assertTrue(verdict.held, verdict.detail)
        self.assertEqual(verdict.checked, 1)
        self.assertFalse(verdict.vacuous)

    def test_fails_when_a_recalled_member_watches_again(self):
        events = [
            state(0, 0, "Landed"), state(1, 0, "Watching", 1),
            state(10, 0, "Recalled"),
            state(15, 0, "Watching", 1),   # the breach: never landed
        ]
        verdict = wins_until(events, "RecallWins", trigger="Recalled",
                             forbidden="Watching", until="Landed")
        self.assertFalse(verdict.held)
        self.assertEqual(len(verdict.breaches), 1)
        self.assertIn("member 0", verdict.breaches[0])

    def test_one_member_recall_does_not_indict_another(self):
        events = [
            state(10, 0, "Recalled"),
            state(15, 1, "Watching", 2),   # a different member, free to watch
            state(20, 0, "Landed"),
        ]
        verdict = wins_until(events, "RecallWins", trigger="Recalled",
                             forbidden="Watching", until="Landed")
        self.assertTrue(verdict.held, verdict.detail)

    def test_a_rule_nothing_exercised_is_reported_as_vacuous(self):
        events = [state(0, 0, "Landed"), state(1, 0, "Watching", 1)]
        verdict = wins_until(events, "RecallWins", trigger="Recalled",
                             forbidden="Watching", until="Landed")
        self.assertTrue(verdict.held)
        self.assertTrue(verdict.vacuous, "a rule never put to the test is not evidence")


class ReturnsWhenIsolated(unittest.TestCase):
    def test_holds_when_everyone_comes_home(self):
        events = [
            state(0, 0, "Landed"), state(1, 0, "Watching", 1),
            state(5, 0, "Isolated"), state(9, 0, "Landing"), state(10, 0, "Landed"),
        ]
        verdict = can_always_return(events, "ReturnsWhenIsolated", home="Landed")
        self.assertTrue(verdict.held, verdict.detail)
        self.assertEqual(verdict.checked, 1)

    def test_a_member_still_flying_when_the_run_ended_is_not_a_breach(self):
        # A live run cut short at 150 s reported both of its members as
        # breaches of this rule while they were watching their sectors exactly
        # as asked. A run that ends first has not been given a chance to
        # conclude, and saying BROKEN accuses the architecture of it.
        events = [state(0, 0, "Landed"), state(1, 0, "Watching", 1)]
        verdict = can_always_return(events, "ReturnsWhenIsolated", home="Landed", ended_at=150)
        self.assertTrue(verdict.held)
        self.assertEqual(verdict.checked, 0, "nothing finished a sortie, so nothing is judged")
        self.assertTrue(verdict.vacuous)
        self.assertIn("still away when the run ended", verdict.detail)

    def test_one_member_home_and_one_still_out_judges_only_the_first(self):
        events = [
            state(0, 0, "Landed"), state(1, 0, "Watching", 1), state(9, 0, "Landed"),
            state(0, 1, "Landed"), state(1, 1, "Watching", 2),
        ]
        verdict = can_always_return(events, "ReturnsWhenIsolated", home="Landed", ended_at=150)
        self.assertTrue(verdict.held)
        self.assertEqual(verdict.checked, 1)

    def test_fails_when_a_member_never_returns(self):
        # `ended_at` before the member's last state: it had time and did not.
        events = [
            state(0, 0, "Landed"), state(1, 0, "Watching", 1), state(5, 0, "Isolated"),
        ]
        verdict = can_always_return(events, "ReturnsWhenIsolated", home="Landed", ended_at=4)
        self.assertFalse(verdict.held)
        self.assertIn("never returned", verdict.breaches[0])


class UnknownRules(unittest.TestCase):
    def test_a_rule_kind_with_no_monitor_is_not_passed(self):
        verdicts = check_rules(
            [state(0, 0, "Landed")],
            [{"rule": "SomethingNew", "kind": "eventually"}],
            recalled="Recalled", watching="Watching", landed="Landed",
        )
        self.assertFalse(verdicts[0].held)
        self.assertIn("not checked, not passed", verdicts[0].detail)

    def test_a_rule_whose_trigger_is_unknown_is_not_passed(self):
        # This one shipped once: every winsUntil rule was armed on Recalled, so
        # QuarantinedStaysOut came back "held" on the strength of a recall it
        # has nothing to do with. A pass for a rule nobody checked.
        verdicts = check_rules(
            [state(0, 0, "Recalled"), state(1, 0, "Landed")],
            [{"rule": "QuarantinedStaysOut", "kind": "winsUntil"}],
            recalled="Recalled", watching="Watching", landed="Landed",
        )
        self.assertFalse(verdicts[0].held)
        self.assertIn("not checked, and not passed", verdicts[0].detail)

    def test_the_geofence_rule_arms_on_the_clearance_state(self):
        events = [
            state(0, 0, "Watching", 1), state(5, 0, "OutsideClearance"),
            state(8, 0, "Watching", 1),          # breach of the geofence rule
            state(9, 0, "Landed"),
        ]
        verdicts = check_rules(
            events,
            [{"rule": "GeofenceBreachEndsWatch", "kind": "winsUntil"},
             {"rule": "RecallWins", "kind": "winsUntil"}],
            recalled="Recalled", watching="Watching", landed="Landed",
            outside="OutsideClearance",
        )
        geofence = next(v for v in verdicts if v.rule == "GeofenceBreachEndsWatch")
        recall = next(v for v in verdicts if v.rule == "RecallWins")
        self.assertFalse(geofence.held, "watching after a breach is a breach")
        self.assertTrue(recall.held, "nothing was recalled, so that rule is untouched")


class WhatMayBeReported(unittest.TestCase):
    def test_a_fleet_that_never_armed_produces_no_report(self):
        ok, why = worth_reporting(0, 12)
        self.assertFalse(ok)
        self.assertIn("nothing flew", why)
        # And it points at the evidence rather than at the host. The first
        # version blamed the machine, and the next time this fired the
        # autopilots were reporting "EKF3 origin set" and "using GPS" — they
        # were ready, and the runtime had asked them to arm exactly once,
        # before they could say yes, and never asked again.
        self.assertIn("before blaming", why)

    def test_a_partial_fleet_is_reported_and_labelled(self):
        ok, why = worth_reporting(7, 12)
        self.assertTrue(ok)
        self.assertIn("7 of 12", why)

    def test_a_whole_fleet_needs_no_caveat(self):
        ok, why = worth_reporting(12, 12)
        self.assertTrue(ok)
        self.assertIn("all 12", why)


class CoverageMetric(unittest.TestCase):
    def test_a_fully_watched_run_averages_one(self):
        events = [state(0, m, "Watching", m + 1) for m in range(4)]
        events.append(state(100, 0, "Landed"))
        coverage = coverage_over_time(events, sectors=4, watching="Watching", until=100)
        # Four sectors held from t=0 to t=100, then one drops at the very end.
        self.assertEqual(coverage.samples[-1][1], 0.75)
        self.assertGreater(coverage.mean, 0.99)

    def test_the_mean_is_time_weighted_not_event_weighted(self):
        events = [
            state(0, 0, "Watching", 1),    # one of two sectors, for 90 s
            state(90, 1, "Watching", 2),   # both, for the last 10 s
        ]
        coverage = coverage_over_time(events, sectors=2, watching="Watching", until=100)
        # 0.5 for 90 s then 1.0 for 10 s = 0.55, not the 0.75 an event-weighted
        # average would give.
        self.assertAlmostEqual(coverage.mean, 0.55, places=3)

    def test_two_members_over_one_sector_do_not_count_twice(self):
        events = [state(0, 0, "Watching", 1), state(1, 1, "Watching", 1)]
        coverage = coverage_over_time(events, sectors=4, watching="Watching", until=10)
        self.assertEqual(coverage.samples[-1][1], 0.25)

    def test_the_handover_gap_shows_as_a_dip(self):
        events = [
            state(0, 0, "Watching", 1),
            state(50, 0, "Recalled"),       # leaves sector 1 uncovered
            state(60, 1, "Watching", 1),    # the relief arrives ten seconds later
        ]
        coverage = coverage_over_time(events, sectors=1, watching="Watching", until=100)
        self.assertEqual(coverage.lowest, 0.0, "the uncovered gap must be visible")
        self.assertAlmostEqual(coverage.mean, 0.9, places=3)


class LossMetric(unittest.TestCase):
    def test_the_drop_and_the_recovery_are_both_reported(self):
        # Four sectors, four members watching and a fifth on a pad. Recovery
        # needs the spare: moving a watching member onto the orphaned sector
        # only moves the hole, which is the arithmetic the forerunner exposes.
        events = [state(0, m, "Watching", m + 1) for m in range(4)]
        events.append(state(0, 4, "Landed"))
        events += [
            fault(100, 3),
            state(100, 3, "Lost"),          # its sector goes dark
            state(140, 4, "Watching", 4),   # the spare launches and takes it
        ]
        coverage = coverage_over_time(events, sectors=4, watching="Watching", until=200)
        impact = loss_on_member_loss(events, coverage, settle=10)
        self.assertIsNotNone(impact)
        self.assertAlmostEqual(impact.before, 1.0, places=3)
        self.assertAlmostEqual(impact.lowest_after, 0.75, places=3)
        self.assertAlmostEqual(impact.loss, 0.25, places=3)
        self.assertIsNotNone(impact.recovery_seconds)

    def test_moving_a_watcher_onto_the_gap_only_moves_the_gap(self):
        # The finding this whole demonstration exists to show, in miniature:
        # with no spare, re-spreading cannot restore coverage. It is reported
        # as an unrecovered loss, not smoothed away.
        events = [state(0, m, "Watching", m + 1) for m in range(4)]
        events += [
            fault(100, 3), state(100, 3, "Lost"),
            state(140, 0, "Watching", 4),   # member 0 abandons sector 1 for 4
        ]
        coverage = coverage_over_time(events, sectors=4, watching="Watching", until=200)
        impact = loss_on_member_loss(events, coverage, settle=10)
        self.assertAlmostEqual(impact.loss, 0.25, places=3)
        self.assertAlmostEqual(impact.recovered_to, 0.75, places=3)
        self.assertIsNone(impact.recovery_seconds,
                          "three members cannot hold four sectors, and the metric must say so")

    def test_only_what_happens_inside_the_window_is_charged_to_the_loss(self):
        # Without a window this reported a loss of 1.0 for a fleet that merely
        # rotated into its recharge an hour later: true about the curve, false
        # about the loss.
        events = [state(0, m, "Watching", m + 1) for m in range(4)]
        events += [fault(100, 3), state(100, 3, "Lost")]
        # Long after the loss, everyone rotates home — nothing to do with it.
        events += [state(600, m, "Recalled") for m in range(3)]
        coverage = coverage_over_time(events, sectors=4, watching="Watching", until=900)
        impact = loss_on_member_loss(events, coverage, window=120)
        self.assertAlmostEqual(impact.loss, 0.25, places=3,
                               msg="one of four sectors, not the whole rotation")
        self.assertEqual(impact.window, 120)

    def test_a_run_with_no_loss_reports_nothing_rather_than_zero(self):
        events = [state(0, 0, "Watching", 1)]
        coverage = coverage_over_time(events, sectors=1, watching="Watching", until=10)
        self.assertIsNone(loss_on_member_loss(events, coverage))

    def test_a_fleet_that_never_recovers_says_so(self):
        events = [state(0, m, "Watching", m + 1) for m in range(2)]
        events += [fault(50, 1), state(50, 1, "Lost")]
        coverage = coverage_over_time(events, sectors=2, watching="Watching", until=200)
        impact = loss_on_member_loss(events, coverage, settle=10)
        self.assertAlmostEqual(impact.loss, 0.5, places=3)
        self.assertIsNone(impact.recovery_seconds, "no recovery is not a recovery at the end")


class Targets(unittest.TestCase):
    def test_the_sense_decides_which_way_round_a_target_is_met(self):
        self.assertTrue(against_target(0.92, 0.9, "max"))
        self.assertFalse(against_target(0.40, 0.9, "max"))
        self.assertTrue(against_target(0.08, 0.25, "min"))
        self.assertFalse(against_target(0.30, 0.25, "min"))


if __name__ == "__main__":
    unittest.main()


class ReplayFrames(unittest.TestCase):
    """WP4's frames: what the replay draws must be what the log recorded."""

    def setUp(self):
        import sys, pathlib
        sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent.parent / "runtime"))

    def test_a_frame_says_who_holds_each_sector(self):
        from overlay import frames_from
        events = [state(0, 0, "Watching", 1), state(10, 1, "Watching", 2)]
        frames = frames_from(events, [{"id": 1}, {"id": 2}], until=20, watching="Watching", step=5)
        self.assertEqual(frames[0]["held"], {"1": 0, "2": None})
        self.assertEqual(frames[-1]["held"], {"1": 0, "2": 1})
        self.assertAlmostEqual(frames[-1]["share"], 1.0)

    def test_a_member_leaving_frees_its_sector(self):
        from overlay import frames_from
        events = [state(0, 0, "Watching", 1), state(10, 0, "Recalled")]
        frames = frames_from(events, [{"id": 1}], until=20, watching="Watching", step=5)
        self.assertEqual(frames[0]["held"]["1"], 0)
        self.assertIsNone(frames[-1]["held"]["1"], "a recalled member must not still hold a sector")

    def test_a_lost_member_is_shown_as_lost(self):
        from overlay import frames_from
        events = [state(0, 0, "Watching", 1), fault(10, 0), state(10, 0, "Lost")]
        frames = frames_from(events, [{"id": 1}], until=20, watching="Watching", step=5)
        self.assertEqual(frames[0]["lost"], [])
        self.assertEqual(frames[-1]["lost"], [0])
        self.assertIsNone(frames[-1]["held"]["1"])

    def test_the_replay_cannot_show_what_the_run_did_not_do(self):
        # An empty log draws an empty grid, not a plausible one.
        from overlay import frames_from
        frames = frames_from([], [{"id": 1}, {"id": 2}], until=10, watching="Watching", step=5)
        self.assertTrue(all(f["watched"] == 0 for f in frames))
        self.assertTrue(all(f["share"] == 0.0 for f in frames))


class GroundLinkLoss(unittest.TestCase):
    """Stage 2's measure: what the watch does once the ground goes quiet."""

    def setUp(self):
        import sys, pathlib
        sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))

    def test_nothing_to_report_without_a_cut(self):
        from metrics import coverage_after_ground_loss
        events = [state(0, 0, "Watching", 1)]
        cov = coverage_over_time(events, sectors=1, watching="Watching", until=100)
        self.assertIsNone(coverage_after_ground_loss(events, cov, until=100))

    def test_it_measures_only_after_the_cut(self):
        from log import Event
        from metrics import coverage_after_ground_loss
        cut = Event(t_sim=50, t_wall=50, kind="fault", member=None, element=None,
                    detail={"fault": "ground link lost"})
        # Both sectors held before the cut; one drops straight after it.
        events = [state(0, 0, "Watching", 1), state(0, 1, "Watching", 2), cut,
                  state(50, 1, "Recalled")]
        cov = coverage_over_time(events, sectors=2, watching="Watching", until=100)
        after = coverage_after_ground_loss(events, cov, until=100)
        self.assertAlmostEqual(after["before"], 1.0, places=3)
        self.assertAlmostEqual(after["mean_after"], 0.5, places=3,
                               msg="the window starts at the cut, not at the run")
        self.assertEqual(after["cut_at"], 50)

    def test_an_architecture_that_keeps_flying_scores_the_same_after_as_before(self):
        from log import Event
        from metrics import coverage_after_ground_loss
        cut = Event(t_sim=50, t_wall=50, kind="fault", member=None, element=None,
                    detail={"fault": "ground link lost"})
        events = [state(0, 0, "Watching", 1), state(0, 1, "Watching", 2), cut]
        cov = coverage_over_time(events, sectors=2, watching="Watching", until=100)
        after = coverage_after_ground_loss(events, cov, until=100)
        self.assertAlmostEqual(after["mean_after"], 1.0, places=3)
