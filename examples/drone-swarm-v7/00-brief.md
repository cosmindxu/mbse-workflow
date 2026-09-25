# SurveillanceDroneSwarm

**Mission**: Take in the operations centre's tasking, supervisory command and recall, and the moving objects in a tasked area of interest, and send back triaged, merged detection reports, tracks, a status picture and a decision record for each report. Stay inside the airspace clearance and work through radio interference, loss of satellite positioning, bad weather and decoys, using a mesh radio, a ground link, recharge points, stored maps and the ground crew.

**Function**: SurveillanceDroneSwarm moves the tasked area of interest from unwatched to continuously watched and reported.

**Operational entity the system takes over**: `watchAsset`

## Environment

| Quadrant | Element | What it is |
|---|---|---|
| input | `MissionTasking` | The area of interest, its sectors and the mission window, set by the operations centre |
| input | `SupervisoryAndRecallCommands` | Priorities, a sector to look at more closely, the reporting threshold, and recall-and-land for the whole swarm or one drone |
| input | `MovingObjectsInArea` | The real objects in the area that have to be detected and classified |
| input | `CameraNetworkTracks` | Tracks from the fixed camera network that the swarm's tracks are merged with at the operations centre |
| input | `ReportAcknowledgements` | The operations centre's confirmation of each detection report |
| output | `DetectionReportsAndTracks` | Triaged, de-duplicated detection reports and tracks with position and time, sent to the operations centre |
| output | `StatusPicture` | Where every drone is, what it is doing, how much coverage there is and what is degraded |
| output | `DecisionRecords` | For each report: the frames it came from, the classifier version, the reporting threshold in force and who acknowledged it |
| constraining | `AirspaceClearance` | The airspace authority's limits on when and where the drones may fly |
| constraining | `RadioInterference` | Interference that can degrade the mesh between drones and the link to the operations centre |
| constraining | `SatellitePositioningOutage` | Satellite positioning can be unavailable for minutes at a time |
| constraining | `WeatherLightingAndDecoys` | Wind above moderate forces a landing; lighting, weather and misleading paint or shapes degrade sensing |
| constraining | `OperatorWorkloadLimit` | At most 20 alerts per hour, with at least 30 seconds for each |
| constraining | `ComputingCostCap` | On-board classification computing costs no more than 300 USD per drone |
| resource | `MeshRadio` | Drone-to-drone radio that does not depend on the ground link and carries the coordination traffic |
| resource | `GroundLinkRadio` | Radio link between the swarm and the operations centre, which is not always available |
| resource | `RechargePointAndGroundCrew` | Where the drones land, recharge (about 60 minutes) and are serviced |
| resource | `StoredMaps` | Reference imagery a drone navigates against when satellite positioning is unavailable |
| resource | `FleetOfTwelveDrones` | The 12 identical drones that can be fielded, each flying about 40 minutes |

## Stakeholders

- **DutyController** — The single operator at the operations centre who tasks, supervises and recalls the swarm and acknowledges reports
- **Analysts** — Operations centre staff who judge triaged alerts and decide which ones matter
- **OperationsCentre** — Commissions surveillance missions and merges swarm reports with the fixed camera network's tracks
- **AirspaceAuthority** — Says when and where the drones may fly
- **GroundCrew** — Services and recharges the drones between sorties
- **FixedCameraNetworkOwner** — Runs the existing camera network, whose tracks the swarm's tracks must merge with
- **ProgrammeSponsor** — Pays for the fleet and holds the per-drone computing cost cap

## Capabilities

- `HoldContinuousWatch` — Keep at least one drone watching every sector of the tasked area at all times, rotating drones through recharge
- `DetectClassifyAndReport` — Detect moving objects, classify them or say Unknown, and report them with position and time
- `CoordinateSwarm` — Let the drones settle among themselves, over the mesh, the handovers, rotation, redistribution, deconfliction, relay, track correlation and admission
- `SuperviseSwarm` — Let one operator task, supervise, recall and see the status of the whole swarm and acknowledge its reports
- `OperateThroughLinkGap` — Keep detecting while cut off from the operations centre, hold the reports and deliver them once the link is back, with none lost
- `StayWithinClearedAirspace` — Fly only inside the cleared airspace and weather limits, and land safely when that is not possible
- `NavigateWithoutSatellitePositioning` — Keep knowing where each drone is by matching camera views against stored maps
- `TriageReports` — Rank reports by how likely they are to matter and merge duplicates before they reach the operator
- `KeepDecisionRecord` — Record, for every report, its source frames, classifier version, reporting threshold and acknowledger
- `ManageClassifierVersion` — Keep one classifier version across the fleet and know which version each drone runs

## Population

12 members of `SurveillanceDrone`, carried by `fleet`. Twelve identical surveillance drones. They have to settle handovers, recharge rotation, redistribution, deconfliction, relay, track correlation and admission among themselves over the mesh radio, so the watch survives when the ground link drops.

- peer port: `Common::MeshPort`; peer interface: `Common::MeshLink`
- coordination capability: `CoordinateSwarm`
- carried by: `MeshRadio`

## Coordination between members (#Coordination)

- `handOverSector` — A drone leaving to recharge hands its sector to one arriving, without a gap.
- `rotateRecharge` — Decide who goes to recharge next, so the airborne share never falls below what the sectors need.
- `redistributeCoverage` — When a drone is lost, the remaining drones re-spread over the sectors so the loss of coverage stays bounded.
- `deconflictMembers` — Keep drones apart in the air and at the recharge point.
- `relayLink` — A drone out of range of the ground station passes its reports and status through a neighbour.
- `correlateTracks` — When two drones see the same object, the swarm reports one track, not two.
- `handOverTrack` — When an object moves into the next sector, the drone watching that sector takes over the track without losing it.
- `admitMember` — A drone joins coordination only after the others have authenticated it; one that fails is quarantined until readmitted.

## Command and control (#C2)

- `taskMission` — Set the area, its sectors and the mission window.
- `commandSupervision` — Set priorities, a sector to look at more closely, and the reporting threshold.
- `recallAndLand` — Recall and land the whole swarm or one drone, at any time.
- `presentStatusPicture` — Show where every drone is, what it is doing, how much coverage there is and what is degraded.
- `acknowledgeReport` — The operations centre confirms each detection report, so nothing is lost in a link gap.

## Hazards the brief names

- `PositionDriftHazard` — Without satellite positioning, a drone's position estimate drifts and its reports place objects in the wrong place.
- `MeshJammingHazard` — Interference cuts the links between drones, and coordination stalls.
- `MisclassificationHazard` — A detection is reported as the wrong class, or given a forced class where Unknown was the truth.
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
| `NavigationDegraded` | member | The drone has no satellite positioning and navigates by camera against stored maps. |
| `SensingDegraded` | member | The drone's sensors cannot be trusted as they are. |
| `Isolated` | member | The drone is cut off from the other drones. |
| `Quarantined` | member | The drone failed admission and takes no part in coordination until readmitted. |
| `MeshDegraded` | fleet | A share of the links between drones is jammed. |

## What the items carry

- `DetectionReport`: `position`, `time`, `objectClass`, `confidence`, `sensorId`, `memberId`, `classifierVersion`, `ageSeconds`
- `Track`: `trackId`, `lastSeenTime`, `stale`
- `DecisionRecord`: `frames`, `classifierVersion`, `reportingThreshold`, `acknowledgedBy`

## Measures of effectiveness

| Measure | Sense | Target | Target from | Unit | What it decides |
|---|---|---|---|---|---|
| `areaUnderWatchShare` | max | 0.9 | brief | — | Share of the area under watch at any moment; the brief requires at least 0.9. |
| `coverageLossOnMemberLoss` | min | 0.25 | brief | — | Share of coverage lost when one drone is lost, before the swarm re-spreads; the brief allows at most 0.25. |
| `jammedMeshAreaUnderWatchShare` | max | 0.75 | brief | — | Share of the area under watch with half the links between drones jammed; the brief requires at least 0.75. |
| `groundLinkLossAreaUnderWatchShare` | max | 0.9 | brief | — | Share of the area under watch while the ground link or the ground station is down. This is where coordination placement makes the biggest difference. The brief gives no number; the target is set here to the brief's continuous-watch figure of 0.9. |
| `watchEnduranceHours` | max | 24 | set by SEED | h | How long the swarm holds the watch before it needs people. The brief gives no number; 24 h is a target set here. |
| `reportLatencySeconds` | min | 60 | brief | s | Age of a report when it reaches the operations centre with the link up; the brief allows at most 60 s. |
| `positionErrorWithoutGnssMeters` | min | 50 | brief | m | A drone's position error after 10 minutes without satellite positioning; the brief allows at most 50 m. |
| `reportHoldMinutes` | max | 30 | brief | min | How long a cut-off drone holds its reports; the brief requires at least 30 minutes. |
| `reportsLostInLinkGap` | min | 0 | set by SEED | — | Number of reports lost across a link gap; the brief says none. |
| `missedDetectionShare` | min | 0.1 | brief | — | Share of real objects that go undetected; the brief allows at most 0.10. |
| `falseAlarmsPerHour` | min | 2 | brief | 1/h | False alarms reaching the operator each hour; the brief allows at most 2. |
| `operatorAlertsPerHour` | min | 20 | brief | 1/h | Alerts reaching the operator each hour after triage; the operator can judge at most 20. |
| `acknowledgedReportsThatMatterShare` | max | 0.8 | brief | — | Share of acknowledged reports that turn out to matter; the brief requires at least 0.8. |
| `onboardClassificationCostUsd` | min | 300 | brief | USD | Cost of on-board classification computing per drone; the brief allows at most 300 USD. |
| `fleetSize` | min | 12 | brief | — | The number of drones that can be fielded; fixed by the brief at 12. |
| `operatorSecondsPerAlert` | max | 30 | brief | s | Time the operator needs to judge each alert; fixed by the brief at least 30 s. |
| `memberFlightEnduranceMinutes` | max | 40 | brief | min | How long one drone flies; fixed by the brief at about 40 minutes. |
| `memberRechargeMinutes` | min | 60 | brief | min | How long one drone takes to recharge; fixed by the brief at about 60 minutes. |
| `areaOfInterestKm2` | max | 25 | brief | km2 | Size of the area the design must cover; fixed by the brief at up to 25 km². |

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

The swarm takes over the job that the duty controller's watch assets do today: holding a sector, handing it over, recharging and relaying. So the operational entity is one representative watchAsset, typed by the SurveillanceDrone member definition. The brief sizes the population at 12 drones, which coordinate over a mesh radio that does not depend on the ground link. The mesh port and interface in Common follow the peer shape the layers below wire through.

Coordination between drones (8 functions) is kept apart from the operator's command and control (5 functions). That way both architectures the brief asks for (coordination at the ground station, or on the drones) can put the same functions in different places.

Hazards, rules, modes and the three items with listed fields (DetectionReport, Track, DecisionRecord) use the brief's names and nothing more.

Every number the brief asks the design to achieve is a scored #MoE with the brief's target. Two targets are set here because the brief gives none, and their docs say so: endurance at 24 h, and coverage with the ground link down at 0.9. Coverage with the link down is the measure where the two architectures differ most. Numbers the brief fixes are #Budget attributes and are not scored: fleet size, operator time per alert, flight and recharge times, and area size. This needs the extra kind Budget.

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
  been seen for 120 seconds.

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

- Each drone flies for about 40 minutes and takes about 60 minutes to recharge,
  so the fleet has to be sized for that ratio.
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
- After **10 minutes without satellite positioning**, a drone's position error
  must stay within **50 m**.
- With **half the links between drones jammed**, at least **0.75 of the area**
  must stay under watch.
- While cut off, a drone holds its reports for at least **30 minutes** and loses
  none.
- No more than **0.10** of real objects may go undetected, and no more than **2
  false alarms per hour** may reach the operator.
- With the link up, a report is no older than **60 seconds** when it reaches the
  operations centre.
- The operator can judge at most **20 alerts per hour** and needs at least **30
  seconds** for each.
- At least **0.8** of the reports the operator acknowledges must turn out to
  matter.
- The on-board computing for classification may cost no more than **300 USD per
  drone**.

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
