# SurveillanceDroneSwarm

**Mission**: The SurveillanceDroneSwarm holds continuous watch over a tasked area of up to 25 km² and turns what happens there into acknowledged, triaged detection reports at the operations centre, inside the airspace clearance, weather, radio interference and satellite-positioning outages the environment imposes, using twelve battery-swapped drones, a mesh radio between them, a ground station and an intermittent link to the operations centre.

**Function**: SurveillanceDroneSwarm moves the tasked area from unwatched and unreported to continuously watched and reported to the operations centre.

**Operational entity the system takes over**: `watchAsset`

## Environment

| Quadrant | Element | What it is |
|---|---|---|
| input | `SurveillanceTasking` | The area of interest, its sectors and the mission window, given by the operations centre. |
| input | `SupervisoryCommand` | Priorities, a sector to look at more closely, and the reporting threshold — the least confidence a classification needs before it becomes a report. |
| input | `RecallOrder` | An order to recall and land the whole swarm or one drone, issuable at any time. |
| input | `ReportAcknowledgement` | The operations centre's confirmation of each detection report, so nothing is lost in a link gap. |
| input | `MovingObjectsInArea` | The objects moving through the tasked area that the swarm must detect, classify and place in time and space. |
| output | `DetectionReports` | Reports of detected objects with position, time, class or Unknown, confidence and provenance, delivered to the operations centre. |
| output | `TriagedAlerts` | Reports ranked so that what is most likely to matter reaches the operator first, with duplicates merged. |
| output | `SwarmTrackPicture` | One track per object — correlated across drones and handed over between sectors — to be merged with the fixed camera network's tracks at the operations centre. |
| output | `SwarmStatusPicture` | Where every drone is, what it is doing, how much of the area is under watch and what is degraded. |
| output | `DecisionRecords` | For every report: the frames it came from, the classifier version, the reporting threshold in force and who acknowledged it. |
| constraining | `AirspaceClearance` | The airspace authority's clearance bounds when and where anything may fly; outside it a drone does not watch until it has landed. |
| constraining | `RadioInterference` | A source of interference may degrade the mesh between drones as well as the link to the operations centre. |
| constraining | `SatellitePositioningOutage` | Satellite positioning may be unavailable for minutes at a time; a drone then navigates by what its camera sees against stored maps. |
| constraining | `WeatherLightingAndDeception` | Lighting, weather and deliberately misleading paint or shapes degrade what the sensors can tell apart; above moderate wind the swarm lands. |
| constraining | `FixedCameraNetwork` | The existing camera network stays and keeps its own tracks; what the swarm reports must be mergeable with those tracks, not merely shown beside them. |
| constraining | `OperatorAttentionLimit` | One operator supervises the whole swarm and can judge only a bounded number of alerts per hour, each needing time to judge. |
| constraining | `WatchAndReportOnlyScope` | Weapons, interception and anything done to what is detected are out of scope: this system watches and reports. |
| resource | `MeshRadioBetweenDrones` | A radio mesh that carries coordination traffic between drones and does not depend on the link to the operations centre. |
| resource | `GroundLinkToOperationsCentre` | An intermittently available radio link carrying tasking, command, reports, status and acknowledgements. |
| resource | `GroundStation` | The station that tasks and watches the swarm and, in one of the two architectures, coordinates it. |
| resource | `TwelveDroneFleet` | Twelve identical small drones, each flying about 40 minutes, cruising at about 18 m/s and keeping about 3.0 km² under watch. |
| resource | `BatterySwapAtRechargePoint` | Ground crew and a recharge point where batteries are swapped, not charged in place — about 20 minutes of turnaround. |
| resource | `RecoveryPoint` | A point a drone that has lost contact with the swarm returns to on its own rather than becoming a hazard. |

## Stakeholders

- **DutyController** — Operations-centre operator who tasks the swarm, issues supervisory command and recall, and today does the sector assignment, handover, re-spread, deconfliction and relay by hand
- **OperationsCentreAnalyst** — Judges the alerts the swarm raises, acknowledges each detection report and merges swarm tracks with the fixed camera network's tracks
- **AirspaceAuthority** — Grants and withdraws the clearance that says when and where anything may fly; the swarm stays inside it and lands when it does not
- **GroundCrew** — Services drones between sorties — swaps batteries at the recharge point in about 20 minutes — and recovers drones that return on their own
- **FixedCameraNetworkOperator** — Keeps the existing fixed camera network and its own tracks, which stay in service and must be merged with what the swarm reports
- **ProgrammeAcquirer** — Fields the twelve drones, chooses between the ground-centred and member-centred command-and-control architectures, and owns the placeholder numbers until the customer states them

## Capabilities

- `ContinuousSectorWatch` — Hold continuous surveillance of the tasked area: at any moment at least one drone is watching each sector of it, as members leave to recharge and rejoin.
- `MovingObjectDetectionAndClassification` — Detect moving objects in the area, classify them well enough to say whether they matter, and say Unknown rather than forcing a class when confidence is short of the reporting threshold.
- `ReportDeliveryAndReconciliation` — Deliver each detection report to the operations centre with position and time, keep detecting and holding reports while cut off, and reconcile once the link is back with none lost.
- `SwarmSelfCoordination` — Settle sector handover, recharge rotation, coverage redistribution, deconfliction, link relay, track correlation, track handover and member admission between the drones themselves over the mesh.
- `OperatorSupervisionOfTheSwarm` — Let one operator task, command, recall and watch the whole swarm rather than fly each drone, and acknowledge each report.
- `AlertTriage` — Triage reports before they reach the operator: what is most likely to matter first, duplicates merged, so the alert rate stays inside what one operator can judge.
- `DecisionRecordKeeping` — Keep, for every report, the frames it came from, the classifier version, the reporting threshold in force and who acknowledged it.
- `GracefulDegradationUnderLoss` — Keep flying and watching when a drone is lost, when the mesh is jammed and when the ground link or the ground station drops, with the loss of coverage bounded.
- `AirspaceComplianceAndSafeRecovery` — Stay inside the cleared airspace, land safely when it is not cleared or the weather exceeds moderate wind, and return to a recovery point when contact with the swarm is lost.
- `ClassifierVersionConsistency` — Keep one classifier version across the fleet and know which version each drone runs, so the same object is not classified differently by different drones.

## Population

12 members of `SwarmMember`, carried by `fleet`. The swarm is twelve identical drones that must settle sector handover, recharge rotation, coverage redistribution, deconfliction, link relay, track correlation, track handover and member admission with each other over a mesh radio that does not depend on the link to the operations centre — that is what lets the watch survive when the ground link drops.

- peer port: `Common::MeshPort`; peer interface: `Common::MeshInterface`
- coordination capability: `SwarmSelfCoordination`
- carried by: `MeshRadioBetweenDrones`

## Coordination between members (#Coordination)

- `handOverSector` — A drone leaving to recharge hands its sector to one arriving, without a gap in coverage.
- `rotateRecharge` — The drones settle who goes to recharge next, so that the airborne share never falls below what the sectors need.
- `redistributeCoverage` — When a drone is lost, the remaining ones re-spread over the sectors and the loss of coverage is bounded.
- `deconflictFlight` — The drones keep apart from each other in the air and at the recharge point.
- `relayReportsThroughNeighbour` — A drone out of range of the ground station passes its reports and status through a neighbour.
- `correlateTracks` — When two drones see the same object, the swarm reports one track, not two.
- `handOverTrack` — When an object moves from one sector to the next, the drone watching the next sector takes over the track without losing it.
- `admitMember` — A drone joins the coordination only after the others have authenticated it; one that fails is quarantined and takes no part until it has been readmitted.

## Command and control (#C2)

- `taskSurveillanceArea` — The operator gives the area, its sectors and the mission window.
- `commandSupervisoryPriorities` — The operator sets priorities, names a sector to look at more closely, and sets the reporting threshold — the least confidence a classification needs before it becomes a report.
- `recallAndLand` — The operator recalls the whole swarm or one drone, at any time, and it lands.
- `presentStatusPicture` — The system shows where every drone is, what it is doing, how much coverage there is and what is degraded.
- `acknowledgeDetectionReport` — The operations centre confirms each detection report, so nothing is lost in a link gap.

## Hazards the brief names

- `PositionDriftHazard` — Without satellite positioning, a drone's position estimate drifts and its reports place objects in the wrong place.
- `MeshJammingHazard` — Interference cuts the links between drones, and coordination stalls.
- `MisclassificationHazard` — A detection is reported as the wrong class, or a forced class where Unknown was the truth.
- `SensingDegradedUnnoticedHazard` — A sensor degrades and nobody knows the reports from it are unreliable.
- `StaleTrackHazard` — A track is shown as current after nothing has seen the object for a while.
- `SpoofedMemberHazard` — Something that is not one of the drones joins the mesh and takes part in coordination.
- `MixedClassifierVersionsHazard` — Drones run different classifier versions and classify the same object differently.
- `OperatorOverloadHazard` — More alerts reach the operator than they can judge, and they accept what is in front of them.

## Rules the system never breaks

| Rule | Kind | Carried by | In the brief's words |
|---|---|---|---|
| `RecallWins` | winsUntil | member | Once a drone is recalled, it does not watch again until it has landed. |
| `ReturnsWhenIsolated` | canAlwaysReturn | member | From any situation a drone can be in, it can always get back to landed; an isolated drone included. |
| `GeofenceBreachEndsWatch` | winsUntil | member | Once a drone is outside its cleared airspace, it does not watch until it has landed. |
| `QuarantinedStaysOut` | winsUntil | member | Once a drone is quarantined, it takes no part in coordination until it has been readmitted. |

## Modes

| Mode | Of | What it is |
|---|---|---|
| `NavigationDegraded` | member | The drone has no satellite positioning and navigates by what its camera sees against stored maps. |
| `SensingDegraded` | member | The drone's sensors cannot be trusted as they are, and what it reports from them is marked accordingly. |
| `Isolated` | member | The drone is cut off from the other drones and coordinates with none of them. |
| `Quarantined` | member | The drone has failed admission and takes no part in coordination until it has been readmitted. |
| `MeshDegraded` | fleet | A share of the links between drones is jammed and the swarm coordinates over what is left. |

## What the items carry

- `DetectionReport`: `position`, `time`, `objectClass`, `confidence`, `sensorId`, `memberId`, `classifierVersion`, `ageSeconds`
- `Track`: `trackId`, `lastSeenTime`, `stale`

## Measures of effectiveness

| Measure | Sense | Target | Target from | Unit | What it decides |
|---|---|---|---|---|---|
| `areaUnderWatchFraction` | max | 0.9 | brief | — | The share of the tasked area under watch at any moment; the brief states at least 0.9, and it separates architectures by how well they keep sectors filled while members rotate to recharge. |
| `coverageLossAfterMemberLossFraction` | min | 0.25 | brief | — | The share of coverage lost when one drone is lost, before the swarm re-spreads; the brief states no more than 0.25, and it is where a ground-coordinated and a member-coordinated redistribution differ most. |
| `coverageUnderMeshJammingFraction` | max | 0.75 | placeholder in the brief | — | The share of the area still under watch with half the links between drones jammed; the brief marks 0.75 as a placeholder awaiting the customer's number, so meeting it means only that a placeholder has been met. |
| `reportAgeAtOperationsCentreSeconds` | min | 60 | placeholder in the brief | s | How old a report is when it reaches the operations centre with the link up; the brief marks 60 s as a placeholder awaiting the customer's number, and relay hop count drives it. |
| `positionErrorWithoutSatelliteMetres` | min | 50 | placeholder in the brief | m | A drone's position error after ten minutes without satellite positioning; the brief marks 50 m as a placeholder awaiting the customer's number, and it decides whether reports place objects where they are. |
| `reportHoldWhileCutOffMinutes` | max | 30 | placeholder in the brief | min | How long a drone holds its reports while cut off without losing any; the brief marks 30 minutes as a placeholder awaiting the customer's number, and it sizes on-board storage against the link-gap risk. |
| `missedDetectionFraction` | min | 0.1 | placeholder in the brief | — | The share of real objects that go undetected; the brief marks 0.10 as a placeholder awaiting the customer's number, and it trades against the reporting threshold and the false-alarm rate. |
| `falseAlarmsPerHour` | min | 2 | placeholder in the brief | 1/h | False alarms reaching the operator each hour; the brief marks 2 per hour as a placeholder awaiting the customer's number, and it is the other side of the missed-detection trade. |
| `alertsReachingOperatorPerHour` | min | 20 | placeholder in the brief | 1/h | How many alerts reach the operator each hour after triage; the brief marks 20 per hour as a placeholder awaiting the customer's number, and it is what triage is scored on against operator overload. |
| `acknowledgedReportsThatMatterFraction` | max | 0.8 | placeholder in the brief | — | The share of reports the operator acknowledges that turn out to matter; the brief marks 0.8 as a placeholder awaiting the customer's number, and it measures whether triage ranks the right things first. |
| `onboardClassificationCostUsdPerMember` | min | 300 | placeholder in the brief | USD | What the on-board computing for classification costs per drone; the brief marks 300 USD as a placeholder awaiting the customer's number, and it decides how much classification can sit on the member rather than the ground. |
| `unattendedWatchDurationHours` | max | 12 | brief | h | How long the swarm holds the watch before it needs people — the brief asks for this but states no number, so 12 hours is a target set here and not asked for by the customer; it should be replaced by the customer's figure before any architecture is failed on it. |
| `fleetSizeMembers` | min | 12 | brief | — | Twelve drones is the fleet the design has to work with; the brief fixes it, so it is declared and never scored. |
| `memberEnduranceMinutes` | max | 40 | brief | min | Each drone flies about 40 minutes, and the transit out and back is spent from the same 40 minutes as the watching; the brief fixes it together with the 18 m/s cruise speed declared below, so the reach of a sector from the recharge point can be checked rather than assumed. |
| `groundTurnaroundMinutes` | min | 20 | brief | min | About 20 minutes on the ground because batteries are swapped, not charged in place; the brief fixes it and the airborne share follows from it with the endurance. |
| `cruiseSpeedMetresPerSecond` | max | 18 | brief | m/s | A drone cruises at about 18 m/s between its recharge point and its sector; the brief fixes it, and without it nothing can say whether a member reaches its station and returns inside the 40-minute endurance. |
| `instantaneousFootprintSquareKilometres` | max | 3 | brief | km2 | About 3.0 km² under watch at once from watch altitude; the brief fixes it, and it makes the coverage figure arithmetic from the number of drones airborne. |
| `areaOfInterestSquareKilometres` | min | 25 | brief | km2 | The area of interest is up to 25 km², divided into sectors; the brief fixes it as the size the design must cover. |
| `operatorSecondsPerAlert` | max | 30 | placeholder in the brief | s | The operator needs at least 30 seconds for each alert; the brief fixes this as the time an operator has, marked a placeholder awaiting the customer's number, and it is declared, never scored. |
| `trackStaleAfterSeconds` | min | 120 | placeholder in the brief | s | A track is marked stale once nothing has been seen for 120 seconds; the brief fixes this threshold and marks it a placeholder awaiting the customer's number. |
| `satellitePositioningOutageMinutes` | max | 10 | placeholder in the brief | min | The ten minutes without satellite positioning the position-error measure is taken over; it comes from the same placeholder statement as the 50 m figure and is a test condition, not a thing to be better at. |
| `meshLinksJammedFraction` | max | 0.5 | placeholder in the brief | — | The half of the links between drones jammed that the jammed-coverage measure is taken under; it comes from the same placeholder statement as the 0.75 figure and is a test condition. |

## Options

| Knob | State |
|---|---|
| modes_states | on |
| interfaces | on |
| variability | on |
| safety | on |
| views | off |
| verification | on |
| requirements_intake | off |
| infrastructure_intake | off |

## Why this framing

The environment reads cleanly into the four quadrants: tasking, supervisory command, recall and acknowledgement come in from the operations centre along with the objects moving through the area; reports, triaged alerts, one track per object, the status picture and the decision record go out; airspace clearance, interference, satellite outage, weather and deception, the fixed camera network that stays, and one operator's attention constrain it; twelve drones, the mesh, the intermittent ground link, the ground station and the 20-minute battery swap supply it. The mission sentence is those four read together, and the function sentence names the state change the whole model exists to make: a tasked area goes from unwatched and unreported to continuously watched and reported.

The system is a population, so the operational entity it takes over is one representative watch asset — the thing the duty controller assigns a sector to, hands a sector over from, re-spreads, deconflicts and relays through today. That is deliberate: those five hand-done activities become the coordination functions the members settle between themselves, and the controller's tasking, command, recall, status picture and acknowledgement become the C2 functions. Splitting them this way is what lets the two candidate architectures — coordination at the ground station, coordination on the drones — be compared on the same functions rather than on different ones.

The measures are the brief's numbers and nothing else. Every figure the brief marks a placeholder is carried as a placeholder so no report can claim the customer asked for it, and every figure the brief FIXES rather than asks the design to achieve — the fleet of twelve, the 40-minute endurance, the 20-minute turnaround, the 18 m/s cruise, the 3.0 km² footprint, the 25 km² area, the operator's 30 seconds, the 120-second stale threshold, and the two test conditions — is a budget: declared, constrained, never scored. The cruise speed matters most of these: with a 25 km² area and 40 minutes of flight, an architecture that puts its recharge point wrong can spend the whole budget on transit, and only a declared speed makes that visible. Only one target is invented — how long the watch holds before it needs people — and its doc says so, because a target nobody asked for can fail every architecture.

Common declares the flows, ports and interfaces in one place so the layers wire rather than invent: one MeshPort in the shape given, carrying a CoordinationMessage that every coordination item specialises, so one peer connection serves handover, rotation, redistribution, deconfliction, relay, correlation, track handover and admission; a member-to-ground port and an operations-centre port that keep the intermittent link and the operator boundary distinct, because one candidate architecture loads the first far more than the other; and clearance, scene and servicing ports so the constraining and supplying environment has somewhere to attach at OA and SA. DetectionReport and Track carry exactly the fields the brief lists, which is why the acknowledgement key sits beside a report rather than inside it.

## The brief as it was given

```
# Surveillance drone swarm

We need an architecture for a **surveillance drone swarm** that watches a fixed
area of interest — a stretch of coastline, a border section, or the perimeter of
an industrial site — and reports what it sees to an operations centre.

## What it is for

A single drone cannot watch an area of that size continuously: it has to land to
recharge, and a gap in coverage is exactly when something happens. A swarm of
small drones, coordinated so that some are always airborne while others recharge,
can hold continuous watch over the area for as long as the mission lasts.

## The operation today

An operations centre tasks a surveillance mission over an area. Today that means
a few crewed aircraft sorties or a fixed camera network: the aircraft are
expensive and intermittent, the cameras cannot move to look at something.
Analysts at the operations centre watch the feeds and raise an alert when
something matters. The fixed camera network stays: it keeps its own tracks, and
what the swarm reports has to be merged with those tracks at the operations
centre, not shown beside them. Airspace authorities constrain when and where anything may
fly, and a ground crew services the aircraft between sorties.

Keeping watch continuous is already a coordination job, done by hand. A duty
controller at the operations centre assigns each watch asset a sector, hands a
sector over from an asset that has to leave to one arriving, re-spreads the
remaining assets when one is lost, keeps them apart in the air, and relays a
report when an asset cannot reach the centre directly. When the controller or
the link to the assets is unavailable, the watch falls apart.

## The swarm is a population

The swarm is **twelve identical drones** — the design number to size and test
against — and a ground station. The drones exchange coordination traffic **with
each other** over a mesh radio that does not depend on the link to the operations
centre: that is what lets the watch survive when the ground link drops.

## What the members must settle between themselves

- **Sector handover** — a drone leaving to recharge hands its sector to one
  arriving, without a gap.
- **Recharge rotation** — who goes to recharge next, so that the airborne share
  never falls below what the sectors need.
- **Coverage redistribution** — when a drone is lost, the remaining ones re-spread
  over the sectors and the loss of coverage is bounded.
- **Deconfliction** — drones keep apart in the air and at the recharge point.
- **Link relay** — a drone out of range of the ground station passes its reports
  and status through a neighbour.
- **Track correlation** — when two drones see the same object, the swarm reports
  one track, not two.
- **Track handover** — when an object moves from one sector to the next, the
  drone watching the next sector takes over the track without losing it.
- **Member admission** — a drone joins the coordination only after the others
  have authenticated it; one that fails is quarantined and takes no part until it
  has been readmitted.

## Command and control the operator exercises over the swarm

- **Tasking** — the area, its sectors and the mission window.
- **Supervisory command** — priorities, a sector to look at more closely, and
  the rule for what to report: the **reporting threshold**, the least confidence
  a classification needs before it becomes a report.
- **Recall and land** — for the whole swarm or one drone, at any time.
- **Status picture** — where every drone is, what it is doing, how much coverage
  there is, what is degraded.
- **Report acknowledgement** — the operations centre confirms each detection
  report, so nothing is lost in a link gap.

## What the swarm has to do

- Hold continuous surveillance of the tasked area: at any moment at least one
  drone is watching each sector of it.
- Detect moving objects in the area, classify them well enough to say whether
  they matter, and report them to the operations centre with a position and a
  time.
- Keep flying as individual drones leave to recharge and rejoin — the swarm
  degrades gracefully rather than stopping.
- Stay inside the airspace it is cleared for, and land safely when it is not.
- Let one operator supervise the whole swarm rather than fly each drone.
- Keep detecting while cut off from the operations centre, hold the reports,
  and deliver them once the link is back — none lost.
- **Triage** reports before they reach the operator: what is most likely to
  matter first, duplicates merged.
- Keep a **decision record** for every report: the frames it came from, the
  classifier version, the reporting threshold in force, and who acknowledged it.
- Say **Unknown** when a detection cannot be classified with enough confidence,
  rather than forcing it into a class.
- Keep one classifier version across the fleet, and know which version each
  drone runs.

## The environment it works in

- A source of **radio interference** may degrade the mesh between drones as well
  as the link to the operations centre.
- **Satellite positioning may be unavailable** for minutes at a time; a drone
  then navigates by what its camera sees against stored maps.
- Lighting, weather and deliberately misleading paint or shapes degrade what the
  sensors can tell apart.

## What every report and track carries

- A **detection report** carries: position, time, objectClass (one of the known
  classes, or Unknown), confidence, sensorId, memberId, classifierVersion and
  ageSeconds.
- A **track** carries: trackId, lastSeenTime, and stale — set once nothing has
  been seen for 120 seconds *(placeholder)*.

## Modes we already know

- A drone can be in **NavigationDegraded** (no satellite positioning),
  **SensingDegraded** (its sensors cannot be trusted as they are), **Isolated**
  (cut off from the other drones) or **Quarantined** (failed admission).
- The swarm as a whole can be in **MeshDegraded** (a share of the links between
  drones is jammed).

## Rules the swarm never breaks

These are checked against each design's state machines, and are enforced by
something that does not depend on the detection software being right.

- **RecallWins** — once a drone is recalled, it does not watch again until it has
  landed.
- **ReturnsWhenIsolated** — from any situation a drone can be in, it can always
  get back to landed; an isolated drone included.
- **GeofenceBreachEndsWatch** — once a drone is outside its cleared airspace, it
  does not watch until it has landed.
- **QuarantinedStaysOut** — once a drone is quarantined, it takes no part in
  coordination until it has been readmitted.

## Hazards we already know

- **PositionDriftHazard** — without satellite positioning, a drone's position
  estimate drifts and its reports place objects in the wrong place.
- **MeshJammingHazard** — interference cuts the links between drones, and
  coordination stalls.
- **MisclassificationHazard** — a detection is reported as the wrong class, or a
  forced class where Unknown was the truth.
- **SensingDegradedUnnoticedHazard** — a sensor degrades and nobody knows the
  reports from it are unreliable.
- **StaleTrackHazard** — a track is shown as current after nothing has seen the
  object for a while.
- **SpoofedMemberHazard** — something that is not one of the drones joins the
  mesh and takes part in coordination.
- **MixedClassifierVersionsHazard** — drones run different classifier versions
  and classify the same object differently.
- **OperatorOverloadHazard** — more alerts reach the operator than they can
  judge, and they accept what is in front of them.

## Constraints we already know

- Each drone flies for about 40 minutes. Turnaround on the ground is about
  **20 minutes**: the batteries are swapped, not charged in place, so a drone is
  back in the air far sooner than a charge would allow. The fleet has to be
  sized for that ratio.
- A drone **cruises at about 18 m/s** between its recharge point and its sector.
  This matters more than it looks: the area is several kilometres across, and
  the transit out and back is spent from the same 40 minutes as the watching.
- From its watch altitude a drone keeps **about 3.0 km² under watch** at once.
  This is what makes the coverage figure below arithmetic rather than a hope:
  the share of the area under watch follows from how many drones are airborne
  and how much each of them sees.
- The area of interest is up to 25 km², divided into sectors.
- We can field **12 drones**. That is the fleet the design has to work with.
- At any moment at least **0.9 of the area** must be under watch.
- When one drone is lost, no more than **0.25 of the coverage** may drop before
  the swarm re-spreads.
- Communication with the operations centre is over a radio link that is not
  always available; the swarm has to keep working through a gap and reconcile
  afterwards.
- A drone that loses contact with the swarm must not become a hazard: it returns
  to a recovery point on its own.
- The swarm operates in weather up to moderate wind; above that it lands.

The numbers marked *(placeholder)* below are not yet the customer's: they stand
in until the customer states them, and a design meeting one has met a
placeholder, nothing more.

- After **10 minutes without satellite positioning**, a drone's position error
  must stay within **50 m** *(placeholder)*.
- With **half the links between drones jammed**, at least **0.75 of the area**
  must stay under watch *(placeholder)*.
- While cut off, a drone holds its reports for at least **30 minutes** and loses
  none *(placeholder)*.
- No more than **0.10** of real objects may go undetected, and no more than **2
  false alarms per hour** may reach the operator *(placeholder)*.
- With the link up, a report is no older than **60 seconds** when it reaches the
  operations centre *(placeholder)*.
- The operator can judge at most **20 alerts per hour** and needs at least **30
  seconds** for each *(placeholder)*.
- At least **0.8** of the reports the operator acknowledges must turn out to
  matter *(placeholder)*.
- The on-board computing for classification may cost no more than **300 USD per
  drone** *(placeholder)*.

## What matters when we choose between designs

- How much of the area is under watch at any moment.
- How long the swarm can hold the watch before it needs people.
- How quickly a detected object reaches the operations centre.
- How accurately a drone knows where it is without satellite positioning.
- How much of the area stays under watch when the mesh is jammed.
- How long reports survive a cut-off, and how old they are when they arrive.
- How many alerts reach the operator, and how many of those matter.
- What the on-board computing costs per drone.
- What happens when one drone fails, and what happens when the radio link drops.

## The architecture decision this model has to make

Where command and control and coordination live is the main decision, and we do
not want it taken by default. One design keeps them at the ground station: a
ground coordinator assigns sectors and rotations, and the drones execute and
relay. The other puts them on the drones themselves: an elected or rotating
coordinator, or peer negotiation over the mesh, with the ground station tasking
and watching. **Model both and compare them**, including what each one keeps
doing when the ground link drops and when the ground station itself fails. Say in
each design where triage, track correlation and the decision record live, and
which component enforces the rules the swarm never breaks.

## Out of scope for this model

Weapons, interception, anything the swarm does to what it detects. This system
watches and reports.
```
