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
