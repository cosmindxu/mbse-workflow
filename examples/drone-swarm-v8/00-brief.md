# SurveillanceDroneSwarm

**Mission**: The SurveillanceDroneSwarm holds continuous watch over a tasked area of up to 25 km² for an operations centre: it takes tasking, supervisory command, recall and report acknowledgement from the centre and what its sensors see of the area, and returns triaged detection reports, correlated tracks, decision records and a status picture, while constrained by airspace clearance, radio interference, satellite-positioning outages, weather and a fleet of twelve drones, and supplied by a mesh radio, a ground-station link, a battery-swap ground crew and stored maps.

**Function**: SurveillanceDroneSwarm carries the tasked area from unwatched and unreported to continuously watched with acknowledged detection reports at the operations centre.

**Operational entity the system takes over**: `watchAsset`

## Environment

| Quadrant | Element | What it is |
|---|---|---|
| input | `MissionTasking` | The area of interest, its sectors and the mission window, issued by the operations centre. |
| input | `SupervisoryCommand` | Priorities, a sector to look at more closely, and the reporting threshold — the least confidence a classification needs before it becomes a report. |
| input | `RecallOrder` | An order to recall and land the whole swarm or one drone, arriving at any time. |
| input | `ReportAcknowledgement` | The operations centre confirming each detection report, so nothing is lost in a link gap. |
| input | `MovingObjectsInArea` | The objects in the watched area that have to be detected, classified and reported — the thing the mission is about. |
| input | `SceneConditions` | Lighting, weather and deliberately misleading paint or shapes, which degrade what the sensors can tell apart. |
| output | `DetectionReports` | Position, time, class, confidence and provenance for each detected object, delivered to the operations centre. |
| output | `CorrelatedTracks` | One track per object rather than one per observing drone, for merging with the fixed camera network's tracks at the operations centre. |
| output | `TriagedAlertStream` | What is most likely to matter, first, with duplicates merged, sized to what one operator can judge. |
| output | `StatusPicture` | Where every drone is, what it is doing, how much coverage there is and what is degraded. |
| output | `DecisionRecord` | For every report: the frames it came from, the classifier version, the reporting threshold in force and who acknowledged it. |
| constraining | `AirspaceClearance` | Airspace authorities constrain when and where anything may fly; outside the cleared volume a drone does not watch. |
| constraining | `RadioInterference` | A source of interference may degrade the mesh between drones as well as the link to the operations centre. |
| constraining | `SatellitePositioningOutage` | Satellite positioning may be unavailable for minutes at a time; a drone then navigates by camera against stored maps. |
| constraining | `WeatherLimit` | The swarm operates in weather up to moderate wind; above that it lands. |
| constraining | `FleetAndEnduranceBudget` | Twelve drones, about 40 minutes of flight each, about 20 minutes of turnaround, 18 m/s cruise and about 3.0 km² under watch from altitude — the arithmetic coverage has to come out of. |
| constraining | `OperatorAttention` | One operator can judge at most 20 alerts an hour and needs at least 30 seconds for each. |
| constraining | `ScopeExclusion` | Weapons, interception and anything done to what is detected are out of scope: this system watches and reports. |
| resource | `MeshRadio` | The bearer of member-to-member coordination traffic, independent of the link to the operations centre — what lets the watch survive a ground-link drop. |
| resource | `GroundStationLink` | The radio link between the swarm and the ground station, not always available; the swarm works through a gap and reconciles afterwards. |
| resource | `GroundStation` | The fixed part of the system: tasking, watching, and in one architecture the coordinator that assigns sectors and rotations. |
| resource | `RechargePointAndBatterySwap` | The ground point and crew where batteries are swapped rather than charged in place, giving a 20-minute turnaround. |
| resource | `RecoveryPoint` | The point a drone that has lost contact with the swarm returns to on its own rather than becoming a hazard. |
| resource | `StoredMaps` | The reference imagery a drone navigates against when satellite positioning is unavailable. |
| resource | `ClassifierRelease` | One classifier version held across the fleet, with each drone's running version known. |

## Stakeholders

- **OperationsCentreAnalyst** — Watches the feeds and reports, judges what matters, acknowledges each detection report; the one whose attention the triage has to protect.
- **DutyController** — Today assigns sectors, hands sectors over, re-spreads assets, keeps them apart and relays reports by hand; the operational entity's supervisor, and the role the swarm's coordination takes over.
- **SwarmSupervisor** — The single operator who tasks, commands, recalls and watches the whole swarm rather than flying each drone.
- **AirspaceAuthority** — Clears when and where anything may fly; its geofence and window constrain every sortie.
- **GroundCrew** — Services drones between sorties and swaps batteries at the recharge point in about twenty minutes.
- **FixedCameraNetworkOperator** — Keeps the existing camera network and its own tracks; what the swarm reports is merged with those tracks at the operations centre.
- **ProcuringCustomer** — Fields the twelve drones, states the numbers still marked placeholder, and chooses between the ground-centred and drone-centred architectures.
- **SafetyAuthority** — Holds the swarm to the rules it never breaks — recall, geofence, return when isolated, quarantine — enforced by something independent of the detection software.

## Capabilities

- `ContinuousAreaWatch` — Hold continuous surveillance of the tasked area: at any moment at least one drone is watching each sector of it, through recharge rotations.
- `DetectionClassificationAndReporting` — Detect moving objects, classify them well enough to say whether they matter — saying Unknown rather than forcing a class — and report them with a position and a time.
- `SwarmSelfCoordination` — Settle sector handover, recharge rotation, coverage redistribution, deconfliction, relay, track correlation, track handover and member admission between the drones over the mesh.
- `SupervisedCommandAndControl` — Let one operator task, command, recall, watch and acknowledge for the whole swarm rather than fly each drone.
- `DisconnectedOperationAndReconciliation` — Keep detecting while cut off from the operations centre, hold the reports, and deliver them once the link is back — none lost.
- `ReportTriageAndDecisionRecord` — Triage reports before they reach the operator, merge duplicates, and keep a decision record for every report.
- `GracefulDegradation` — Keep flying and watching as drones leave, rejoin or are lost, with the loss of coverage bounded rather than the watch stopping.
- `AirspaceComplianceAndSafeRecovery` — Stay inside the cleared airspace, land safely when it is not available, and return to a recovery point when contact with the swarm is lost.

## Population

12 members of `SurveillanceDrone`, carried by `fleet`. Twelve identical small drones, each able to watch a sector for about forty minutes, which must settle sector handover, recharge rotation, coverage redistribution, deconfliction, relay, track correlation, track handover and admission with each other over a mesh radio that does not depend on the ground link.

- peer port: `Common::MeshPeerPort`; peer interface: `Common::MeshLink`
- coordination capability: `SwarmSelfCoordination`
- carried by: `MeshRadio`

## Coordination between members (#Coordination)

- `handOverSector` — A drone leaving to recharge hands its sector to one arriving, without a gap in the watch.
- `rotateRecharge` — The drones settle who goes to recharge next, so the airborne share never falls below what the sectors need.
- `redistributeCoverage` — When a drone is lost, the remaining ones re-spread over the sectors and the loss of coverage stays within its bound.
- `deconflictFlight` — The drones keep apart from each other in the air and at the recharge point.
- `relayThroughNeighbour` — A drone out of range of the ground station passes its reports and status through a neighbour.
- `correlateTracks` — When two drones see the same object the swarm reports one track, not two.
- `handOverTrack` — When an object moves from one sector to the next, the drone watching the next sector takes over the track without losing it.
- `admitMember` — A drone joins the coordination only after the others have authenticated it; one that fails is quarantined until readmitted.

## Command and control (#C2)

- `taskSurveillanceMission` — The operator gives the swarm the area, its sectors and the mission window.
- `issueSupervisoryCommand` — The operator sets priorities, points the swarm at a sector to look at more closely, and sets the reporting threshold — the least confidence a classification needs before it becomes a report.
- `recallToLand` — The operator recalls and lands the whole swarm or one drone, at any time.
- `presentStatusPicture` — The swarm shows where every drone is, what it is doing, how much coverage there is and what is degraded.
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
| `SensingDegraded` | member | The drone's sensors cannot be trusted as they are. |
| `Isolated` | member | The drone is cut off from the other drones. |
| `Quarantined` | member | The drone has failed admission and takes no part in coordination until readmitted. |
| `MeshDegraded` | fleet | A share of the links between drones is jammed and the swarm coordinates over what is left. |

## What the items carry

- `DetectionReport`: `position`, `time`, `objectClass`, `confidence`, `sensorId`, `memberId`, `classifierVersion`, `ageSeconds`
- `Track`: `trackId`, `lastSeenTime`, `stale`

## Measures of effectiveness

| Measure | Sense | Target | Target from | Unit | What it decides |
|---|---|---|---|---|---|
| `areaUnderWatchFraction` | max | 0.9 | brief | — | The share of the area of interest under watch at any moment; the brief requires at least 0.9 and it is the first thing an architecture is judged on. |
| `watchEnduranceHoursWithoutPeople` | max | 12 | brief | hours | How long the swarm holds the watch before it needs people to intervene. The brief names this as a thing that matters but states no number; 12 hours is set here by the architect as a working target and must be confirmed with the customer. |
| `reportDeliveryLatencySeconds` | min | 60 | placeholder in the brief | seconds | How old a report is when it reaches the operations centre with the link up; distinguishes architectures by where triage and correlation sit. |
| `positionErrorAfterGnssLossMetres` | min | 50 | placeholder in the brief | metres | How accurately a drone knows where it is after ten minutes without satellite positioning; it sets where its reports place objects. |
| `coverageUnderMeshJammingFraction` | max | 0.75 | placeholder in the brief | — | The share of the area still under watch with half the links between drones jammed; the sharpest discriminator between ground-held and drone-held coordination. |
| `reportHoldDurationMinutes` | max | 30 | placeholder in the brief | minutes | How long a cut-off drone holds its reports without losing any before the link returns. |
| `missedDetectionFraction` | min | 0.1 | placeholder in the brief | — | The share of real objects that go undetected; with the false-alarm rate it fixes how much the reporting threshold can be tightened. |
| `falseAlarmsPerHour` | min | 2 | placeholder in the brief | alerts per hour | False alarms reaching the operator each hour; traded against missed detections by the reporting threshold. |
| `alertsReachingOperatorPerHour` | min | 20 | placeholder in the brief | alerts per hour | How many alerts actually reach the operator after triage and duplicate merging; an architecture that floods the operator fails whatever else it does. |
| `acknowledgedReportsThatMatterFraction` | max | 0.8 | placeholder in the brief | — | The share of the reports the operator acknowledges that turn out to matter; measures whether triage ranks the right things first. |
| `coverageDropAfterMemberLossFraction` | min | 0.25 | brief | — | How much coverage is lost when one drone is lost, before the remaining drones re-spread; the brief bounds it at 0.25. |
| `onboardClassifierCostUsdPerDrone` | min | 300 | placeholder in the brief | USD | What the on-board computing for classification costs per drone; multiplied by twelve it decides whether classification can live on the drones at all. |
| `fleetSizeDrones` | min | 12 | brief | — | Twelve drones is the fleet the design has to work with — fixed by the brief, held as a requirement and never scored. |
| `memberFlightEnduranceMinutes` | max | 40 | brief | minutes | About 40 minutes of flight per drone, fixed by the brief. Transit out and back is spent from this same budget, so it is read together with the cruise-speed budget below, which the brief does give as 18 m/s. |
| `groundTurnaroundMinutes` | min | 20 | brief | minutes | About 20 minutes on the ground because batteries are swapped, not charged in place; with endurance it fixes the airborne share the fleet can hold. |
| `cruiseSpeedMetresPerSecond` | max | 18 | brief | m/s | About 18 m/s between recharge point and sector, fixed by the brief; without it nothing can say a drone reaches its station and returns inside its 40 minutes over an area several kilometres across. |
| `sensorFootprintSquareKilometres` | max | 3 | brief | km2 | About 3.0 km² under watch from a drone's watch altitude; this makes the coverage figure arithmetic rather than a hope. |
| `areaOfInterestSquareKilometres` | min | 25 | brief | km2 | The area of interest is up to 25 km², divided into sectors — fixed by the brief. |
| `operatorAlertCapacityPerHour` | min | 20 | placeholder in the brief | alerts per hour | The most alerts one operator can judge in an hour; fixed by the brief as a property of the operator, not something an architecture improves. |
| `operatorSecondsPerAlert` | max | 30 | placeholder in the brief | seconds | The least time the operator needs for each alert; fixed by the brief and never scored. |
| `trackStaleThresholdSeconds` | min | 120 | placeholder in the brief | seconds | A track is stale once nothing has been seen for 120 seconds; the value the stale field of a Track is set from. |
| `gnssOutageToleratedMinutes` | max | 10 | placeholder in the brief | minutes | The satellite-positioning outage the position-error measure is stated against: ten minutes. |
| `jammedLinkShareFraction` | max | 0.5 | placeholder in the brief | — | The share of links between drones assumed jammed when the degraded-coverage measure is taken: half. |

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

The brief describes a population, not a single system: twelve identical drones that settle eight named matters with each other over a mesh that is deliberately independent of the ground link. That independence is the whole point of the architecture decision, so the mesh peer port and its interface are declared in Common in the mandated shape and every member is wired through them from LA down; collapsing the swarm into one instance would make the decision unaskable. The operational entity the system takes over is one representative watch asset — today a crewed sortie flown to a sector under a duty controller's hand-made plan — which is why the controller's eight coordination activities become the coordination functions and the operations centre's five become the C2 functions.

Hazards, rules, modes and items are exactly those the brief names and no more: the eight known hazards go to SA::Hazards once and are satisfied by path below; the four rules are all carried by one member's state machine, since each is about what a single drone does after recall, geofence breach, isolation or quarantine; MeshDegraded is the only fleet-level mode. DetectionReport and Track carry exactly the fields the brief lists and nothing else, so a layer cannot quietly add an identifier to make its own life easier — acknowledgement therefore carries its own reference field and is documented as doing so.

On the measures: every target that the brief states is taken from the brief, and every number it marks as awaiting the customer is flagged as a placeholder so no report can claim a design has met a customer requirement. Three numbers the brief fixes rather than asks for — the fleet of twelve, the operator's 20 alerts an hour and 30 seconds each — are budgets, declared and never scored. The cruise speed is declared as a budget because the brief gives it (18 m/s) and because endurance and area alone cannot say whether a drone reaches its sector and returns: transit out and back is paid from the same forty minutes as the watching, and a model without the speed would let an architecture spend its whole flight budget on the return leg. Only watchEnduranceHoursWithoutPeople has a target nobody asked for; its doc says so.

Common holds definitions only, so it declares no state machines and no hazards of its own: modes, states and layer hazards belong where there are parts to carry and mitigate them. The ports declared here are the ones the layers will actually wire — mesh, ground link, operations link, airspace, ground service, sensor feed and navigation feed — so that the interfaces check does not report a port that connects to nothing.

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
