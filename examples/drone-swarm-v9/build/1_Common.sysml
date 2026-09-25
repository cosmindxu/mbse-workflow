package SurveillanceDroneSwarm {
    doc /* SurveillanceDroneSwarm — layered model.
           Mission: The SurveillanceDroneSwarm holds continuous watch over a tasked area of up to 25 km² and turns what happens there into acknowledged, triaged detection reports at the operations centre, inside the airspace clearance, weather, radio interference and satellite-positioning outages the environment imposes, using twelve battery-swapped drones, a mesh radio between them, a ground station and an intermittent link to the operations centre.
           Function: SurveillanceDroneSwarm moves the tasked area from unwatched and unreported to continuously watched and reported to the operations centre.
           One package per perspective; references point upward only. */
    package Kinds {
        doc /* User-defined keywords (CV-02): layer, structural role, mode and lifecycle tags.
               Every `#Tag` used anywhere in this model is declared here. */
        metadata def OA; metadata def SA; metadata def LA; metadata def PA; metadata def EPBS;
        metadata def Mission; metadata def Capability; metadata def Chain; metadata def Actor;
        metadata def Logical; metadata def Behaviour; metadata def Node;
        metadata def Mode; metadata def State;
        metadata def Hazard; metadata def Accepted; metadata def Rule; metadata def MoE; metadata def Estimate; metadata def Variant;
        metadata def Member; metadata def Coordination; metadata def C2; metadata def Configuration;
        metadata def Imposed; metadata def Standard; metadata def Customer;
        metadata def CI_CSCI; metadata def CI_HWCI; metadata def CI_COTS; metadata def CI_TBD;
        // asked for by the brief
        metadata def Budget; metadata def Placeholder;
    }
    package Common {
        doc /* Definitions every layer of SurveillanceDroneSwarm shares: the items that flow between a drone, its peers, the ground station, the operations centre and the environment; the ports and interfaces those flows cross; and one #MoE attribute per measure of effectiveness, each held to its target by a require constraint. Nothing happens here — no parts, no behaviour, no state machines: those belong to a layer. */

        // ---------------------------------------------------------------
        // Value-level attribute definitions
        // ---------------------------------------------------------------

        attribute def TimeStamp {
            doc /* A point in time, used wherever a report, a track or a coordination message has to be placed in time. */
            attribute secondsSinceEpoch : ScalarValues::Real {
                doc /* Seconds since the mission epoch the whole swarm shares. */
            }
        }

        attribute def GeoPosition {
            doc /* Where something is: the position a report places an object at, and the position a drone believes it holds. */
            attribute latitudeDegrees : ScalarValues::Real {
                doc /* Latitude in degrees. */
            }
            attribute longitudeDegrees : ScalarValues::Real {
                doc /* Longitude in degrees. */
            }
            attribute altitudeMetres : ScalarValues::Real {
                doc /* Height above the reference surface in metres. */
            }
            attribute estimatedErrorMetres : ScalarValues::Real {
                doc /* How far out the position may be — the figure that grows while satellite positioning is unavailable. */
            }
        }

        attribute def Identifier {
            doc /* A name something in the model is known by across drones, the ground station and the operations centre. */
            attribute label : ScalarValues::String {
                doc /* The identifying text itself. */
            }
        }

        attribute def MemberId :> Identifier {
            doc /* Which drone of the twelve is meant. */
        }

        attribute def SensorId :> Identifier {
            doc /* Which sensor on a drone is meant, so a degraded sensor's reports can be found again. */
        }

        attribute def TrackId :> Identifier {
            doc /* The one identity the swarm reports for an object it is watching. */
        }

        attribute def SectorId :> Identifier {
            doc /* Which sector of the tasked area is meant. */
        }

        attribute def ReportKey :> Identifier {
            doc /* The key a detection report is acknowledged and recorded under; it is carried beside a report rather than inside it, because the brief fixes the report's fields exactly. */
        }

        attribute def ConfidenceLevel :> ScalarValues::Real {
            doc /* How sure a classification is, between 0 and 1, compared against the reporting threshold in force. */
        }

        attribute def ReportingThreshold :> ConfidenceLevel {
            doc /* The least confidence a classification needs before it becomes a report; below it the answer is Unknown. */
        }

        attribute def ClassifierVersion {
            doc /* Which build of the classifier produced a class, so mixed versions across the fleet are visible. */
            attribute versionTag : ScalarValues::String {
                doc /* The released version name. */
            }
            attribute buildHash : ScalarValues::String {
                doc /* The exact build the drone runs, so two drones claiming one version can still be told apart. */
            }
        }

        attribute def MissionWindow {
            doc /* The span of time a tasking is valid over. */
            attribute startTime : TimeStamp {
                doc /* When the watch is to begin. */
            }
            attribute endTime : TimeStamp {
                doc /* When the watch may end. */
            }
        }

        attribute def SectorDefinition {
            doc /* One sector of the tasked area: what a drone is assigned to watch. */
            attribute sectorId : SectorId {
                doc /* Which sector this is. */
            }
            attribute areaSquareKilometres : ScalarValues::Real {
                doc /* How much area the sector holds, against the 3.0 km² a drone keeps under watch at once. */
            }
            attribute centre : GeoPosition {
                doc /* The point a drone transits to in order to watch this sector. */
            }
        }

        attribute def GeofenceBoundary {
            doc /* The edge of the cleared airspace, as a drone carries it. */
            attribute boundaryVertices : ScalarValues::String {
                doc /* The vertices of the cleared volume in the form the drone holds them. */
            }
            attribute ceilingMetres : ScalarValues::Real {
                doc /* The upper limit of the cleared volume. */
            }
        }

        enum def ObjectClass {
            doc /* The classes a detection may be reported as. Unknown is a first-class answer, not a failure: a detection that cannot be classified with enough confidence is reported Unknown rather than forced into a class. */
            enum Unknown;
            enum Person;
            enum GroundVehicle;
            enum Vessel;
            enum Aircraft;
            enum Animal;
        }

        // ---------------------------------------------------------------
        // Items the brief fixes the fields of
        // ---------------------------------------------------------------

        item def DetectionReport {
            doc /* What a drone reports when it detects and classifies a moving object. The brief lists these fields, and these are exactly the fields it carries. */
            attribute position : GeoPosition {
                doc /* Where the detected object was, as the reporting drone knew its own position at the time. */
            }
            attribute time : TimeStamp {
                doc /* When the detection was made. */
            }
            attribute objectClass : ObjectClass {
                doc /* One of the known classes, or Unknown when the classification did not reach the reporting threshold. */
            }
            attribute confidence : ConfidenceLevel {
                doc /* How sure the classification is, compared against the reporting threshold in force. */
            }
            attribute sensorId : SensorId {
                doc /* Which sensor the detection came from, so a degraded sensor's reports can be found. */
            }
            attribute memberId : MemberId {
                doc /* Which drone reported it. */
            }
            attribute classifierVersion : ClassifierVersion {
                doc /* The classifier version that produced the class, so mixed versions across the fleet are visible. */
            }
            attribute ageSeconds : ScalarValues::Real {
                doc /* How long ago the detection was made, at the moment the report is read — the figure the 60-second placeholder is measured against. */
            }
        }

        item def Track {
            doc /* One object the swarm is watching, held as a single identity across correlation between drones and handover between sectors. The brief lists these fields, and these are exactly the fields it carries. */
            attribute trackId : TrackId {
                doc /* The one identity the swarm reports for an object. */
            }
            attribute lastSeenTime : TimeStamp {
                doc /* When anything last saw the object on this track. */
            }
            attribute stale : ScalarValues::Boolean {
                doc /* Set once nothing has been seen for the stale threshold — 120 seconds, a placeholder awaiting the customer's number. */
            }
        }

        // ---------------------------------------------------------------
        // Items that cross the link to the operations centre
        // ---------------------------------------------------------------

        item def SurveillanceTasking {
            doc /* What the operations centre tasks the swarm with: the area, its sectors and the mission window. */
            attribute taskingId : Identifier {
                doc /* Which tasking this is, so a later one supersedes an earlier one unambiguously. */
            }
            attribute areaSquareKilometres : ScalarValues::Real {
                doc /* How large the tasked area is, up to 25 km². */
            }
            attribute sectors : SectorDefinition[1..*] {
                doc /* The sectors the area is divided into; at any moment at least one drone watches each. */
            }
            attribute window : MissionWindow {
                doc /* The mission window the watch is to be held over. */
            }
            attribute issuedAt : TimeStamp {
                doc /* When the operations centre issued the tasking. */
            }
        }

        item def SupervisoryCommand {
            doc /* What the operator commands without flying a drone: priorities, a sector to look at more closely, and the rule for what to report. */
            attribute priorityOrder : ScalarValues::String {
                doc /* What the operator wants attended to first. */
            }
            attribute focusSector : SectorId {
                doc /* A sector to look at more closely than the rest. */
            }
            attribute reportingThreshold : ReportingThreshold {
                doc /* The least confidence a classification needs before it becomes a report. */
            }
            attribute issuedAt : TimeStamp {
                doc /* When the command was issued, so the threshold in force at any report is known. */
            }
        }

        item def RecallOrder {
            doc /* An order to recall and land, for the whole swarm or one drone, issuable at any time; once it is received the drone does not watch again until it has landed. */
            attribute wholeSwarm : ScalarValues::Boolean {
                doc /* True when the whole swarm is recalled, false when one drone is. */
            }
            attribute targetMember : MemberId {
                doc /* Which drone is recalled when the order is not for the whole swarm. */
            }
            attribute recoveryPoint : GeoPosition {
                doc /* Where the recalled drone is to land. */
            }
            attribute issuedAt : TimeStamp {
                doc /* When the recall was issued. */
            }
        }

        item def ReportAcknowledgement {
            doc /* The operations centre's confirmation of a detection report, so nothing is lost in a link gap and an unacknowledged report is held and re-sent. */
            attribute reportKey : ReportKey {
                doc /* Which report is being acknowledged. */
            }
            attribute acknowledgedBy : ScalarValues::String {
                doc /* Who at the operations centre acknowledged it — the name the decision record keeps. */
            }
            attribute acknowledgedAt : TimeStamp {
                doc /* When it was acknowledged. */
            }
        }

        item def TriagedAlert {
            doc /* A report as it reaches the operator after triage: ranked by how likely it is to matter, with duplicates merged, so the alert rate stays inside what one operator can judge. */
            attribute reportKey : ReportKey {
                doc /* Which report this alert stands for. */
            }
            attribute priorityRank : ScalarValues::Integer {
                doc /* Where this alert sits in the order presented to the operator; 1 is first. */
            }
            attribute mergedReportCount : ScalarValues::Integer {
                doc /* How many duplicate reports were merged into this one alert. */
            }
            attribute raisedAt : TimeStamp {
                doc /* When the alert was put in front of the operator. */
            }
            item summarisedReport : DetectionReport {
                doc /* The report the alert presents, carried whole so the operator judges what the drone actually said. */
            }
        }

        item def DecisionRecord {
            doc /* What is kept for every report so that a classification can be accounted for afterwards: the frames it came from, the classifier version, the reporting threshold in force, and who acknowledged it. */
            attribute reportKey : ReportKey {
                doc /* Which report this record is about. */
            }
            attribute frameReferences : ScalarValues::String[1..*] {
                doc /* The frames the detection came from, identified so they can be retrieved. */
            }
            attribute classifierVersion : ClassifierVersion {
                doc /* The classifier version that produced the class. */
            }
            attribute thresholdInForce : ReportingThreshold {
                doc /* The reporting threshold that was in force when the report was raised. */
            }
            attribute acknowledgedBy : ScalarValues::String {
                doc /* Who acknowledged the report at the operations centre. */
            }
            attribute recordedAt : TimeStamp {
                doc /* When the record was written. */
            }
        }

        item def MemberStatus {
            doc /* What one drone says about itself: where it is, what it is doing, how long it can stay up, and what about it is degraded. */
            attribute memberId : MemberId {
                doc /* Which drone this is about. */
            }
            attribute position : GeoPosition {
                doc /* Where the drone believes it is, with the error it believes that position carries. */
            }
            attribute assignedSector : SectorId {
                doc /* Which sector it is watching, or is transiting to. */
            }
            attribute activity : ScalarValues::String {
                doc /* What it is doing: watching, transiting, recharging, landed, returning. */
            }
            attribute enduranceRemainingMinutes : ScalarValues::Real {
                doc /* How much of the 40 minutes is left, including the transit home. */
            }
            attribute classifierVersion : ClassifierVersion {
                doc /* Which classifier version this drone runs, so mixed versions across the fleet are visible. */
            }
            attribute navigationDegraded : ScalarValues::Boolean {
                doc /* True while the drone has no satellite positioning. */
            }
            attribute sensingDegraded : ScalarValues::Boolean {
                doc /* True while the drone's sensors cannot be trusted as they are. */
            }
            attribute isolated : ScalarValues::Boolean {
                doc /* True while the drone is cut off from the other drones. */
            }
            attribute quarantined : ScalarValues::Boolean {
                doc /* True while the drone has failed admission and takes no part in coordination. */
            }
            attribute heldReportCount : ScalarValues::Integer {
                doc /* How many reports the drone is holding because the link is down. */
            }
            attribute reportedAt : TimeStamp {
                doc /* When the drone said this. */
            }
        }

        item def SwarmStatusPicture {
            doc /* The picture one operator supervises the whole swarm from: where every drone is, what it is doing, how much coverage there is and what is degraded. */
            attribute coverageFraction : ScalarValues::Real {
                doc /* The share of the tasked area under watch at the moment the picture was compiled. */
            }
            attribute airborneCount : ScalarValues::Integer {
                doc /* How many of the twelve are in the air. */
            }
            attribute degradedCount : ScalarValues::Integer {
                doc /* How many are degraded in navigation, sensing, isolation or quarantine. */
            }
            attribute meshDegraded : ScalarValues::Boolean {
                doc /* True while a share of the links between drones is jammed. */
            }
            attribute compiledAt : TimeStamp {
                doc /* When the picture was compiled, so the operator knows how old it is. */
            }
            item memberStates : MemberStatus[0..*] {
                doc /* What each drone last said about itself. */
            }
        }

        // ---------------------------------------------------------------
        // Items the drones exchange with each other over the mesh
        // ---------------------------------------------------------------

        item def CoordinationMessage {
            doc /* Anything one drone sends another over the mesh. Everything the members settle between themselves specialises this, so one mesh port carries all of it. */
            attribute senderId : MemberId {
                doc /* Which drone sent it. */
            }
            attribute sentAt : TimeStamp {
                doc /* When it was sent. */
            }
            attribute sequenceNumber : ScalarValues::Integer {
                doc /* Where it sits in the sender's stream, so loss over a jammed mesh is visible. */
            }
        }

        item def SectorHandover :> CoordinationMessage {
            doc /* A drone leaving to recharge hands its sector to one arriving, without a gap in coverage. */
            attribute sector : SectorId {
                doc /* Which sector changes hands. */
            }
            attribute relinquishingMember : MemberId {
                doc /* The drone giving the sector up. */
            }
            attribute assumingMember : MemberId {
                doc /* The drone taking the sector on. */
            }
            attribute effectiveAt : TimeStamp {
                doc /* When the handover takes effect, so neither drone leaves before the other arrives. */
            }
        }

        item def RechargeRotationProposal :> CoordinationMessage {
            doc /* Who goes to recharge next, so that the airborne share never falls below what the sectors need. */
            attribute proposedMember : MemberId {
                doc /* The drone proposed to go next. */
            }
            attribute proposedDepartureTime : TimeStamp {
                doc /* When it would leave its sector. */
            }
            attribute airborneShareAfter : ScalarValues::Real {
                doc /* The share of the fleet still airborne if this rotation is taken. */
            }
        }

        item def CoverageRedistributionPlan :> CoordinationMessage {
            doc /* When a drone is lost, how the remaining ones re-spread over the sectors so that the loss of coverage is bounded. */
            attribute lostMember : MemberId {
                doc /* The drone that has been lost. */
            }
            attribute sectorAssignments : ScalarValues::String {
                doc /* Which drone takes which sector under the new spread. */
            }
            attribute expectedCoverageFraction : ScalarValues::Real {
                doc /* The coverage the plan expects to hold, against the bound on how much may drop. */
            }
        }

        item def DeconflictionAdvisory :> CoordinationMessage {
            doc /* How two drones keep apart in the air and at the recharge point. */
            attribute conflictingMember : MemberId {
                doc /* The other drone in the conflict. */
            }
            attribute separationMetres : ScalarValues::Real {
                doc /* How far apart they are now. */
            }
            attribute avoidanceManoeuvre : ScalarValues::String {
                doc /* What the receiving drone is asked to do to keep the separation. */
            }
        }

        item def RelayedTraffic :> CoordinationMessage {
            doc /* A drone out of range of the ground station passes its reports and status through a neighbour. */
            attribute originMember : MemberId {
                doc /* The drone whose traffic this is. */
            }
            attribute hopCount : ScalarValues::Integer {
                doc /* How many drones the traffic has already passed through — what the report age at the operations centre grows with. */
            }
            item relayedReports : DetectionReport[0..*] {
                doc /* The reports being passed on. */
            }
            item relayedStatus : MemberStatus[0..1] {
                doc /* The status being passed on. */
            }
        }

        item def TrackCorrelationHint :> CoordinationMessage {
            doc /* What one drone tells another so that two drones seeing the same object report one track, not two. */
            attribute candidateTrackId : TrackId {
                doc /* The track the sender believes the other drone's object is the same as. */
            }
            attribute matchConfidence : ConfidenceLevel {
                doc /* How sure the sender is that the two are the same object. */
            }
            item observedTrack : Track {
                doc /* The track as the sender holds it. */
            }
        }

        item def TrackHandover :> CoordinationMessage {
            doc /* When an object moves from one sector to the next, the drone watching the next sector takes over the track without losing it. */
            attribute fromSector : SectorId {
                doc /* The sector the object is leaving. */
            }
            attribute toSector : SectorId {
                doc /* The sector the object is entering. */
            }
            attribute assumingMember : MemberId {
                doc /* The drone taking the track on. */
            }
            item handedTrack : Track {
                doc /* The track being handed over, so its identity survives the crossing. */
            }
        }

        item def AdmissionExchange :> CoordinationMessage {
            doc /* A drone joins the coordination only after the others have authenticated it; one that fails is quarantined and takes no part until it has been readmitted. */
            attribute candidateMember : MemberId {
                doc /* The drone asking to join. */
            }
            attribute challengeNonce : ScalarValues::String {
                doc /* The challenge the others put to it. */
            }
            attribute credentialToken : ScalarValues::String {
                doc /* The answer the candidate gives, which the others check. */
            }
            attribute admitted : ScalarValues::Boolean {
                doc /* True when the candidate is admitted, false when it is quarantined. */
            }
        }

        // ---------------------------------------------------------------
        // Items that cross the boundary to the rest of the environment
        // ---------------------------------------------------------------

        item def AirspaceClearance {
            doc /* What the airspace authority grants and withdraws: when and where anything may fly. */
            attribute clearanceId : Identifier {
                doc /* Which clearance this is. */
            }
            attribute boundary : GeofenceBoundary {
                doc /* The volume that is cleared. */
            }
            attribute validFrom : TimeStamp {
                doc /* When the clearance begins. */
            }
            attribute validUntil : TimeStamp {
                doc /* When the clearance ends, after which nothing watches until it has landed. */
            }
            attribute issuedBy : ScalarValues::String {
                doc /* Which authority issued it. */
            }
        }

        item def SensorObservation {
            doc /* What a drone's sensors give it of the scene: the frames detection and classification are made from, and that the decision record refers back to. */
            attribute frameId : Identifier {
                doc /* Which frame this is, so a decision record can name it. */
            }
            attribute capturedAt : TimeStamp {
                doc /* When the frame was captured. */
            }
            attribute sensorId : SensorId {
                doc /* Which sensor captured it. */
            }
            attribute sceneQuality : ScalarValues::Real {
                doc /* How well the scene can be told apart in this frame, as lighting, weather and misleading paint or shapes degrade it. */
            }
        }

        item def GroundServicingRequest {
            doc /* A drone asking the ground crew for the turnaround that puts it back in the air: batteries swapped, not charged in place. */
            attribute memberId : MemberId {
                doc /* Which drone is asking. */
            }
            attribute requestedAt : TimeStamp {
                doc /* When it asked. */
            }
            attribute recoveryPoint : GeoPosition {
                doc /* Where it is landing to be serviced. */
            }
            attribute batterySwapRequired : ScalarValues::Boolean {
                doc /* True for the ordinary 20-minute swap; false when the drone is landing for another reason. */
            }
        }

        item def GroundServicingConfirmation {
            doc /* The ground crew's answer: the drone is serviced and how much flying it has. */
            attribute memberId : MemberId {
                doc /* Which drone was serviced. */
            }
            attribute servicedAt : TimeStamp {
                doc /* When the turnaround finished. */
            }
            attribute enduranceAvailableMinutes : ScalarValues::Real {
                doc /* How many minutes of flight the fitted battery gives. */
            }
        }

        // ---------------------------------------------------------------
        // Port definitions
        // ---------------------------------------------------------------

        port def MeshPort {
            doc /* What one drone exchanges with a peer over the mesh radio. It carries everything the members settle between themselves and does not depend on the link to the operations centre. */
            out item update : CoordinationMessage {
                doc /* A coordination message to a peer; the peer receives it through the conjugate of this port. */
            }
        }

        port def MemberGroundPort {
            doc /* What one drone exchanges with the ground station over the intermittent radio link. */
            out item report : DetectionReport {
                doc /* A detection report on its way to the operations centre. */
            }
            out item memberStatus : MemberStatus {
                doc /* Where the drone is, what it is doing and what about it is degraded. */
            }
            in item tasking : SurveillanceTasking {
                doc /* The area, its sectors and the mission window. */
            }
            in item supervisoryCommand : SupervisoryCommand {
                doc /* Priorities, a focus sector and the reporting threshold. */
            }
            in item recall : RecallOrder {
                doc /* The order to recall and land. */
            }
            in item acknowledgement : ReportAcknowledgement {
                doc /* Confirmation that a report arrived, so a held report can be released. */
            }
        }

        port def OperationsCentrePort {
            doc /* What the ground station exchanges with the operations centre: everything the operator gives the swarm and everything the swarm puts in front of the operator. */
            out item alert : TriagedAlert {
                doc /* A triaged alert, ranked and with duplicates merged. */
            }
            out item picture : SwarmStatusPicture {
                doc /* The status picture one operator supervises the whole swarm from. */
            }
            out item record : DecisionRecord {
                doc /* The decision record kept for a report. */
            }
            out item reportedTrack : Track {
                doc /* One track per object, for merging with the fixed camera network's tracks at the operations centre. */
            }
            in item tasking : SurveillanceTasking {
                doc /* The tasking the operations centre gives. */
            }
            in item supervisoryCommand : SupervisoryCommand {
                doc /* The supervisory command the operator gives. */
            }
            in item recall : RecallOrder {
                doc /* The recall the operator may issue at any time. */
            }
            in item acknowledgement : ReportAcknowledgement {
                doc /* The operations centre's acknowledgement of a report. */
            }
        }

        port def AirspaceClearancePort {
            doc /* Where the cleared airspace enters the system: what the airspace authority grants and withdraws. */
            in item clearance : AirspaceClearance {
                doc /* The clearance in force, which bounds when and where anything may fly. */
            }
        }

        port def SceneObservationPort {
            doc /* Where the watched scene enters a drone: the frames its sensors give it. */
            in item observation : SensorObservation {
                doc /* A frame of the scene, with how well it can be told apart. */
            }
        }

        port def GroundServicingPort {
            doc /* Where a drone meets the ground crew for the battery swap that puts it back in the air. */
            out item servicingRequest : GroundServicingRequest {
                doc /* The drone asking for a turnaround. */
            }
            in item servicingConfirmation : GroundServicingConfirmation {
                doc /* The crew's answer, with the endurance the fitted battery gives. */
            }
        }

        // ---------------------------------------------------------------
        // Interface definitions
        // ---------------------------------------------------------------

        interface def MeshInterface {
            doc /* Joins two drones over the mesh radio. This is the bearer coordination survives on when the ground link drops. */
            end sender : MeshPort {
                doc /* The drone sending the coordination message. */
            }
            end receiver : ~MeshPort {
                doc /* The peer drone receiving it. */
            }
        }

        interface def GroundLinkInterface {
            doc /* Joins a drone to the ground station over the radio link that is not always available; the swarm has to keep working through a gap and reconcile afterwards. */
            end airborneEnd : MemberGroundPort {
                doc /* The drone's end of the link. */
            }
            end groundEnd : ~MemberGroundPort {
                doc /* The ground station's end of the link. */
            }
        }

        interface def OperationsCentreInterface {
            doc /* Joins the ground station to the operations centre, where the operator tasks, commands, recalls, watches and acknowledges. */
            end stationEnd : OperationsCentrePort {
                doc /* The ground station's end. */
            }
            end centreEnd : ~OperationsCentrePort {
                doc /* The operations centre's end. */
            }
        }

        interface def AirspaceAuthorityInterface {
            doc /* Joins the system to the airspace authority whose clearance constrains when and where anything may fly. */
            end systemEnd : AirspaceClearancePort {
                doc /* The system's end, which receives the clearance. */
            }
            end authorityEnd : ~AirspaceClearancePort {
                doc /* The authority's end, which issues and withdraws it. */
            }
        }

        interface def SceneObservationInterface {
            doc /* Joins a drone's sensing to the watched scene, whatever lighting, weather and misleading paint or shapes do to it. */
            end sensingEnd : SceneObservationPort {
                doc /* The drone's end, which takes the frames. */
            }
            end sceneEnd : ~SceneObservationPort {
                doc /* The scene's end, which yields them. */
            }
        }

        interface def GroundServicingInterface {
            doc /* Joins a landed drone to the ground crew for the roughly 20-minute battery swap. */
            end memberEnd : GroundServicingPort {
                doc /* The drone's end. */
            }
            end crewEnd : ~GroundServicingPort {
                doc /* The ground crew's end. */
            }
        }

        // ---------------------------------------------------------------
        // Measures of effectiveness — scored between the two architectures
        // ---------------------------------------------------------------

        #MoE attribute areaUnderWatchFraction : ScalarValues::Real {
            doc /* The share of the tasked area under watch at any moment. The brief states at least 0.9. It follows arithmetically from how many drones are airborne and the 3.0 km² each keeps under watch, so it separates the two architectures by how well each keeps sectors filled while members rotate to recharge. */
        }
        require constraint areaUnderWatchTarget {
            doc /* At any moment at least 0.9 of the area must be under watch. */
            areaUnderWatchFraction >= 0.9
        }

        #MoE attribute coverageLossAfterMemberLossFraction : ScalarValues::Real {
            doc /* The share of coverage lost when one drone is lost, before the swarm re-spreads. The brief states no more than 0.25; how quickly redistribution is agreed is where ground-held and member-held coordination differ most. */
        }
        require constraint coverageLossAfterMemberLossTarget {
            doc /* When one drone is lost, no more than 0.25 of the coverage may drop before the swarm re-spreads. */
            coverageLossAfterMemberLossFraction <= 0.25
        }

        #MoE #Placeholder attribute coverageUnderMeshJammingFraction : ScalarValues::Real {
            doc /* The share of the area still under watch with half the links between drones jammed. 0.75 is a placeholder awaiting the customer's number: a design meeting it has met a placeholder, nothing more. */
        }
        require constraint coverageUnderMeshJammingTarget {
            doc /* With half the links between drones jammed, at least 0.75 of the area must stay under watch — placeholder. */
            coverageUnderMeshJammingFraction >= 0.75
        }

        #MoE #Placeholder attribute reportAgeAtOperationsCentreSeconds : ScalarValues::Real {
            doc /* How old a report is when it reaches the operations centre with the link up. 60 seconds is a placeholder awaiting the customer's number; relay hop count and where triage runs drive it. */
        }
        require constraint reportAgeAtOperationsCentreTarget {
            doc /* With the link up, a report is no older than 60 seconds when it reaches the operations centre — placeholder. */
            reportAgeAtOperationsCentreSeconds <= 60.0
        }

        #MoE #Placeholder attribute positionErrorWithoutSatelliteMetres : ScalarValues::Real {
            doc /* A drone's position error after ten minutes without satellite positioning, navigating by camera against stored maps. 50 m is a placeholder awaiting the customer's number; it decides whether reports place objects where they are. */
        }
        require constraint positionErrorWithoutSatelliteTarget {
            doc /* After 10 minutes without satellite positioning, a drone's position error must stay within 50 m — placeholder. */
            positionErrorWithoutSatelliteMetres <= 50.0
        }

        #MoE #Placeholder attribute reportHoldWhileCutOffMinutes : ScalarValues::Real {
            doc /* How long a drone holds its reports while cut off from the operations centre without losing any. 30 minutes is a placeholder awaiting the customer's number. */
        }
        require constraint reportHoldWhileCutOffTarget {
            doc /* While cut off, a drone holds its reports for at least 30 minutes and loses none — placeholder. */
            reportHoldWhileCutOffMinutes >= 30.0
        }

        #MoE #Placeholder attribute missedDetectionFraction : ScalarValues::Real {
            doc /* The share of real objects that go undetected. 0.10 is a placeholder awaiting the customer's number, and it trades against the reporting threshold and the false-alarm rate. */
        }
        require constraint missedDetectionTarget {
            doc /* No more than 0.10 of real objects may go undetected — placeholder. */
            missedDetectionFraction <= 0.10
        }

        #MoE #Placeholder attribute falseAlarmsPerHour : ScalarValues::Real {
            doc /* False alarms reaching the operator each hour. 2 per hour is a placeholder awaiting the customer's number, and it is the other side of the missed-detection trade. */
        }
        require constraint falseAlarmsPerHourTarget {
            doc /* No more than 2 false alarms per hour may reach the operator — placeholder. */
            falseAlarmsPerHour <= 2.0
        }

        #MoE #Placeholder attribute alertsReachingOperatorPerHour : ScalarValues::Real {
            doc /* How many alerts reach the operator each hour after triage. 20 per hour is a placeholder awaiting the customer's number, and it is what triage is scored on against operator overload. */
        }
        require constraint alertsReachingOperatorTarget {
            doc /* No more alerts may reach the operator than the 20 per hour they can judge — placeholder. */
            alertsReachingOperatorPerHour <= 20.0
        }

        #MoE #Placeholder attribute acknowledgedReportsThatMatterFraction : ScalarValues::Real {
            doc /* The share of reports the operator acknowledges that turn out to matter. 0.8 is a placeholder awaiting the customer's number; it measures whether triage ranks the right things first. */
        }
        require constraint acknowledgedReportsThatMatterTarget {
            doc /* At least 0.8 of the reports the operator acknowledges must turn out to matter — placeholder. */
            acknowledgedReportsThatMatterFraction >= 0.8
        }

        #MoE #Placeholder attribute onboardClassificationCostUsdPerMember : ScalarValues::Real {
            doc /* What the on-board computing for classification costs per drone. 300 USD is a placeholder awaiting the customer's number; it decides how much classification can sit on the member rather than the ground. */
        }
        require constraint onboardClassificationCostTarget {
            doc /* The on-board computing for classification may cost no more than 300 USD per drone — placeholder. */
            onboardClassificationCostUsdPerMember <= 300.0
        }

        #MoE attribute unattendedWatchDurationHours : ScalarValues::Real {
            doc /* How long the swarm holds the watch before it needs people. The brief asks for this but states no number, so 12 hours is a target set in this model and NOT asked for by the customer; it should be replaced by the customer's figure before any architecture is failed on it. */
        }
        require constraint unattendedWatchDurationTarget {
            doc /* The swarm holds the watch for at least 12 hours before it needs people — a target set in this model, not the customer's. */
            unattendedWatchDurationHours >= 12.0
        }

        // ---------------------------------------------------------------
        // Budgets — what the brief fixes. Declared, never scored.
        // ---------------------------------------------------------------

        #Budget attribute fleetSizeMembers : ScalarValues::Integer {
            doc /* Twelve drones is the fleet the design has to work with; the brief fixes it. */
        }
        require constraint fleetSizeBudget {
            doc /* We can field 12 drones. */
            fleetSizeMembers <= 12
        }

        #Budget attribute memberEnduranceMinutes : ScalarValues::Real {
            doc /* Each drone flies about 40 minutes, and the transit out and back is spent from the same 40 minutes as the watching. Read together with the 18 m/s cruise speed below, this says whether a member reaches its sector and returns inside its endurance. */
        }
        require constraint memberEnduranceBudget {
            doc /* No design may assume more than the 40 minutes of flight a drone has. */
            memberEnduranceMinutes <= 40.0
        }

        #Budget attribute groundTurnaroundMinutes : ScalarValues::Real {
            doc /* About 20 minutes on the ground, because the batteries are swapped, not charged in place; the airborne share follows from this and the endurance. */
        }
        require constraint groundTurnaroundBudget {
            doc /* No design may assume a turnaround shorter than the 20 minutes the battery swap takes. */
            groundTurnaroundMinutes >= 20.0
        }

        #Budget attribute cruiseSpeedMetresPerSecond : ScalarValues::Real {
            doc /* A drone cruises at about 18 m/s between its recharge point and its sector. The brief fixes it; without it nothing can say whether a member reaches its station and returns inside the 40-minute endurance over an area several kilometres across. */
        }
        require constraint cruiseSpeedBudget {
            doc /* No design may assume a cruise faster than 18 m/s. */
            cruiseSpeedMetresPerSecond <= 18.0
        }

        #Budget attribute instantaneousFootprintSquareKilometres : ScalarValues::Real {
            doc /* About 3.0 km² under watch at once from watch altitude; this is what makes the coverage figure arithmetic rather than a hope. */
        }
        require constraint instantaneousFootprintBudget {
            doc /* No design may assume more than 3.0 km² under watch from one drone at once. */
            instantaneousFootprintSquareKilometres <= 3.0
        }

        #Budget attribute areaOfInterestSquareKilometres : ScalarValues::Real {
            doc /* The area of interest is up to 25 km², divided into sectors; the brief fixes it as the size the design must cover. */
        }
        require constraint areaOfInterestBudget {
            doc /* The tasked area is up to 25 km². */
            areaOfInterestSquareKilometres <= 25.0
        }

        #Budget #Placeholder attribute operatorSecondsPerAlert : ScalarValues::Real {
            doc /* The operator needs at least 30 seconds for each alert. The brief fixes this as the time an operator has — a placeholder awaiting the customer's number — so it is declared and never scored. */
        }
        require constraint operatorSecondsPerAlertBudget {
            doc /* The operator needs at least 30 seconds to judge each alert — placeholder. */
            operatorSecondsPerAlert >= 30.0
        }

        #Budget #Placeholder attribute trackStaleAfterSeconds : ScalarValues::Real {
            doc /* A track is marked stale once nothing has been seen for 120 seconds. The brief fixes this threshold and marks it a placeholder awaiting the customer's number. */
        }
        require constraint trackStaleAfterBudget {
            doc /* A track's stale flag is set no later than 120 seconds after anything last saw the object — placeholder. */
            trackStaleAfterSeconds <= 120.0
        }

        #Budget #Placeholder attribute satellitePositioningOutageMinutes : ScalarValues::Real {
            doc /* The ten minutes without satellite positioning the position-error measure is taken over. It is a test condition from the same placeholder statement as the 50 m figure, not something to be better at. */
        }
        require constraint satellitePositioningOutageBudget {
            doc /* The position-error measure is taken after at least 10 minutes without satellite positioning — placeholder. */
            satellitePositioningOutageMinutes >= 10.0
        }

        #Budget #Placeholder attribute meshLinksJammedFraction : ScalarValues::Real {
            doc /* The half of the links between drones jammed that the jammed-coverage measure is taken under. It is a test condition from the same placeholder statement as the 0.75 figure. */
        }
        require constraint meshLinksJammedBudget {
            doc /* The jammed-coverage measure is taken with at least half the links between drones jammed — placeholder. */
            meshLinksJammedFraction >= 0.5
        }
    }
}
