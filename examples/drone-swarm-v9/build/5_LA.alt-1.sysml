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
        // ── shared definitions asked for by OA ──
        item def SectorHandoverProposal { doc /* A drone's proposal to hand a sector, with the watch it carries, to a neighbour. */ }
        item def RechargeRotationSlot { doc /* A drone's place in the recharge rotation: when it leaves and who takes over. */ }
        item def CoverageAssignment { doc /* A share of the tasked area assigned to a drone when coverage is re-spread. */ }
        item def FlightIntent { doc /* A drone's announced flight path and altitude, exchanged to deconflict flight. */ }
        item def TaskingOrder { doc /* Tasking given by the duty controller: the area of interest, its sectors and the mission window. */ }
        item def PriorityDirective { doc /* Supervisory command: priorities, a sector to look at more closely, and the reporting threshold. */ }
        item def RecallDirective { doc /* An order to recall and land the whole swarm or one drone. */ }
        item def ReportReceipt { doc /* The operations centre's acknowledgement of one detection report. */ }
        item def ConditionNotice { doc /* A notice that a condition has changed: positioning, sensing, contact, or mesh jamming. */ }
        // ── shared definitions asked for by SA ──
        item def MovingObjectsInArea { doc /* The objects moving through the tasked area that the swarm must detect, classify and place in time and space. */ }
        item def TriagedAlerts { doc /* Detection reports ranked so that what is most likely to matter reaches the operator first, with duplicates merged. */ }
        item def DecisionRecords { doc /* For every report: the frames it came from, the classifier version, the reporting threshold in force and who acknowledged it. */ }
        item def DroneArrival { doc /* A drone arriving on the ground at the recharge point or the recovery point, to be serviced or recovered by ground crew. */ }
        item def DroneServiced { doc /* A drone handed back to the swarm by ground crew after a battery swap or a recovery. */ }
        item def PositioningStatus { doc /* Whether satellite positioning is available to a drone, so it can tell when it must navigate by camera against stored maps. */ }
        item def SensorHealthStatus { doc /* Whether a drone's sensors can be trusted, so reports from a degraded sensor can be marked as such. */ }
        item def MeshLinkStatus { doc /* The state of a drone's links to the other drones over the mesh: contact lost or regained, and the share of links jammed. */ }
        item def WeatherCondition { doc /* Wind, lighting and weather as sensed on board; above moderate wind the swarm lands. */ }
        // ── shared definitions asked for by LA ──
        item def CoordinationDirective { doc /* A directive from the coordinator to a drone: sector assignment, handover, rotation, redistribution, deconfliction, launch, release, or an admission verdict. */ attribute directiveKind { doc /* Which kind of directive this is. */ } attribute memberId { doc /* The drone the directive is for. */ } attribute sectorId { doc /* The sector the directive concerns, where it has one. */ } attribute effectiveTime { doc /* When the directive takes effect. */ } }
        item def DirectiveAck { doc /* A drone's acknowledgement of one coordination directive. */ attribute memberId { doc /* The drone acknowledging. */ } attribute directiveKind { doc /* The kind of directive acknowledged. */ } attribute ackTime { doc /* When the drone acknowledged. */ } }
        item def AdmissionRequest { doc /* What a drone offers to be admitted to coordination. */ attribute memberId { doc /* Identity the drone claims. */ } attribute classifierVersion { doc /* The classifier version the drone runs. */ } attribute credential { doc /* Proof that the drone is one of the twelve. */ } }
        item def MemberSituationNotice { doc /* A notice of a change in a drone's or the mesh's situation that triggers a transition: positioning lost or back, sensing degraded or restored, contact lost or back, jamming, wind above moderate. */ attribute memberId { doc /* The drone concerned, or empty for the mesh as a whole. */ } attribute situation { doc /* What changed. */ } }
    }
    package OA {
        doc /* Operational analysis: how the tasked area is watched and reported today, without any system named. The entities, what each does, what they exchange, and the operational modes. */

        // ---------- Entities ----------

        #Actor part def DutyController {
            doc /* Operations-centre operator who tasks the swarm, issues supervisory command and recall, and today does sector assignment, handover, re-spread, deconfliction and relay by hand. */
        }
        part dutyController : DutyController {
            doc /* The one operator who supervises the whole swarm. */
        }

        #Actor part def OperationsCentreAnalyst {
            doc /* Judges the alerts that arrive, acknowledges each detection report and merges swarm tracks with the fixed camera network's tracks. */
        }
        part operationsCentreAnalyst : OperationsCentreAnalyst {
            doc /* The analyst at the operations centre. */
        }

        #Actor part def AirspaceAuthority {
            doc /* Grants and withdraws the clearance that says when and where anything may fly. */
        }
        part airspaceAuthority : AirspaceAuthority {
            doc /* The authority whose clearance bounds every flight. */
        }

        #Actor part def GroundCrew {
            doc /* Services drones between sorties, swapping batteries at the recharge point in about 20 minutes, and recovers drones that return on their own. */
        }
        part groundCrew : GroundCrew {
            doc /* The crew at the recharge point and the recovery point. */
        }

        #Actor part def FixedCameraNetworkOperator {
            doc /* Keeps the existing fixed camera network and its own tracks in service. */
        }
        part fixedCameraNetworkOperator : FixedCameraNetworkOperator {
            doc /* The operator of the fixed camera network. */
        }

        #Member part def SwarmMember {
            doc /* One of the twelve identical small drones: about 40 minutes of flight, about 18 m/s cruise, about 3.0 km2 under watch at a time, battery swapped on the ground. Declared once; every member is a usage of it. */
        }

        part watchAsset : SwarmMember [12] {
            doc /* The operational entity that holds the watch over the tasked area: the population of twelve identical drones. */
        }
        part memberA : SwarmMember {
            doc /* First representative of the twelve-drone population watchAsset; not an extra drone. */
        }
        part memberB : SwarmMember {
            doc /* Second representative of the twelve-drone population watchAsset; not an extra drone. */
        }

        #Node part def GroundStationNode {
            doc /* The station that tasks and watches the swarm and shows its status picture. */
        }
        part groundStation : GroundStationNode {
            doc /* The ground station used today. */
        }

        #Node part def MeshRadio {
            doc /* The radio mesh carrying coordination traffic between drones; it does not depend on the link to the operations centre. */
        }
        part meshRadioBetweenDrones : MeshRadio {
            doc /* The mesh radio that carries the traffic between drones. */
        }

        #Node part def GroundLinkRadio {
            doc /* The intermittently available radio link carrying tasking, command, reports, status and acknowledgements to and from the operations centre. */
        }
        part groundLinkToOperationsCentre : GroundLinkRadio {
            doc /* The intermittent link to the operations centre. */
        }

        #Node part def RechargePoint {
            doc /* Where batteries are swapped, not charged in place; about 20 minutes of turnaround. */
        }
        part batterySwapAtRechargePoint : RechargePoint {
            doc /* The recharge point where ground crew swap batteries. */
        }

        #Node part def RecoveryPoint {
            doc /* The point a drone that has lost contact with the swarm returns to on its own rather than becoming a hazard. */
        }
        part recoveryPoint : RecoveryPoint {
            doc /* The recovery point for drones that return on their own. */
        }

        #Node part def FixedCameraNetwork {
            doc /* The existing camera network; it stays and keeps its own tracks, which swarm reports must be mergeable with. */
        }
        part fixedCameraNetwork : FixedCameraNetwork {
            doc /* The existing fixed camera network. */
        }

        // ---------- Coordination between members ----------

        #Coordination action def HandOverSector {
            doc /* A drone hands its sector to a neighbour when it leaves to recharge, so the sector stays watched. */
            out port handoverOut;
            in port handoverIn;
        }
        #Coordination action def RotateRecharge {
            doc /* Members agree who leaves to recharge and who takes the place, so the rotation never empties a sector. */
            out port rotationOut;
            in port rotationIn;
        }
        #Coordination action def RedistributeCoverage {
            doc /* Members re-spread over the area when one is lost or leaves, so the share of area under watch stays high. */
            out port coverageOut;
            in port coverageIn;
        }
        #Coordination action def DeconflictFlight {
            doc /* Members announce flight intent to each other so that two drones do not occupy the same airspace. */
            out port intentOut;
            in port intentIn;
        }
        #Coordination action def RelayReportsThroughNeighbour {
            doc /* A member that cannot reach the operations centre sends its reports through a neighbour that can. */
            out port relayOut;
            in port relayIn;
        }
        #Coordination action def CorrelateTracks {
            doc /* Members agree that tracks seen by different drones are the same object, giving one track per object. */
            out port correlationOut;
            in port correlationIn;
        }
        #Coordination action def HandOverTrack {
            doc /* A track is handed to the drone that watches the sector the object moves into. */
            out port trackHandoverOut;
            in port trackHandoverIn;
        }
        #Coordination action def AdmitMember {
            doc /* A drone is checked before it takes part in coordination; one that fails takes no part until readmitted. */
            out port admissionOut;
            in port admissionIn;
        }

        // ---------- Command and control ----------

        #C2 action def TaskSurveillanceArea {
            doc /* The duty controller tasks the swarm with the area of interest, its sectors and the mission window. */
            out port taskingOut;
        }
        #C2 action def CommandSupervisoryPriorities {
            doc /* The duty controller gives priorities, a sector to look at more closely and the reporting threshold. */
            out port priorityOut;
        }
        #C2 action def RecallAndLand {
            doc /* An order to recall and land the whole swarm or one drone, issuable at any time. */
            out port recallOut;
        }
        #C2 action def PresentStatusPicture {
            doc /* Shows where every drone is, what it is doing, how much of the area is under watch and what is degraded. */
            in port statusIn;
        }
        #C2 action def AcknowledgeDetectionReport {
            doc /* The operations centre confirms each detection report, so nothing is lost in a link gap. */
            in port reportIn;
            out port receiptOut;
        }

        // ---------- Other operational activities ----------

        action def DetectAndClassifyObject {
            doc /* A drone detects a moving object in its sector and classifies it, saying Unknown when confidence is short of the reporting threshold. */
            out port detectionOut;
        }
        action def DeliverDetectionReport {
            doc /* A drone delivers a report with position and time to the operations centre, holds it while cut off, and clears it on acknowledgement. */
            in port detectionIn;
            out port reportOut;
            in port receiptIn;
        }
        action def ApplySupervisoryDirectives {
            doc /* A drone takes up the tasking, priorities and recall given by the duty controller, and lands on recall. */
            in port taskingIn;
            in port priorityIn;
            in port recallIn;
        }
        action def ReportMemberStatus {
            doc /* A drone reports its position, activity and degradations for the status picture. */
            out port statusOut;
        }
        action def ReportTrackPicture {
            doc /* A drone reports the tracks it holds so the analyst can merge them with the camera network's tracks. */
            out port trackPictureOut;
        }
        action def ReturnToRecoveryPoint {
            doc /* A drone that has lost contact with the swarm returns to the recovery point on its own. */
        }
        action def SwapBattery {
            doc /* Ground crew swap a landed drone's battery at the recharge point, about 20 minutes. */
        }
        action def RecoverReturnedDrone {
            doc /* Ground crew recover a drone that returned to the recovery point on its own. */
        }
        action def GrantAirspaceClearance {
            doc /* The airspace authority grants or withdraws the clearance that bounds when and where anything may fly. */
        }
        action def ProvideCameraTracks {
            doc /* The fixed camera network provides its own tracks. */
            out port cameraTrackOut;
        }
        action def MergeSwarmTracks {
            doc /* The analyst merges swarm tracks with the camera network's tracks, one track per object. */
            in port swarmTrackIn;
            in port cameraTrackIn;
        }

        // ---------- Activity usages, written here and allocated to the entity that performs them ----------

        action issueTasking : TaskSurveillanceArea { doc /* Duty controller's tasking activity. */ }
        action issuePriorities : CommandSupervisoryPriorities { doc /* Duty controller's supervisory-command activity. */ }
        action issueRecall : RecallAndLand { doc /* Duty controller's recall activity. */ }
        action presentStatus : PresentStatusPicture { doc /* Ground station's status presentation. */ }
        action acknowledgeReports : AcknowledgeDetectionReport { doc /* Analyst's acknowledgement activity. */ }
        action mergeTracks : MergeSwarmTracks { doc /* Analyst's track merge. */ }
        action provideCameraTracks : ProvideCameraTracks { doc /* Camera network's own track output. */ }
        action swapBatteryAct : SwapBattery { doc /* Ground crew battery swap. */ }
        action recoverDroneAct : RecoverReturnedDrone { doc /* Ground crew recovery of a returned drone. */ }
        action grantClearanceAct : GrantAirspaceClearance { doc /* Airspace authority clearance. */ }

        allocate issueTasking to dutyController;
        allocate issuePriorities to dutyController;
        allocate issueRecall to dutyController;
        allocate presentStatus to groundStation;
        allocate acknowledgeReports to operationsCentreAnalyst;
        allocate mergeTracks to operationsCentreAnalyst;
        allocate provideCameraTracks to fixedCameraNetwork;
        allocate swapBatteryAct to groundCrew;
        allocate recoverDroneAct to groundCrew;
        allocate grantClearanceAct to airspaceAuthority;

        // memberA
        action alphaHandOverSector : HandOverSector { doc /* memberA hands over its sector. */ }
        action alphaRotateRecharge : RotateRecharge { doc /* memberA takes part in the recharge rotation. */ }
        action alphaRedistributeCoverage : RedistributeCoverage { doc /* memberA re-spreads coverage. */ }
        action alphaDeconflictFlight : DeconflictFlight { doc /* memberA deconflicts its flight. */ }
        action alphaRelayReports : RelayReportsThroughNeighbour { doc /* memberA relays reports through a neighbour. */ }
        action alphaCorrelateTracks : CorrelateTracks { doc /* memberA correlates tracks with neighbours. */ }
        action alphaHandOverTrack : HandOverTrack { doc /* memberA hands a track over. */ }
        action alphaAdmitMember : AdmitMember { doc /* memberA takes part in member admission. */ }
        action alphaDetect : DetectAndClassifyObject { doc /* memberA detects and classifies. */ }
        action alphaDeliver : DeliverDetectionReport { doc /* memberA delivers and holds reports. */ }
        action alphaDirectives : ApplySupervisoryDirectives { doc /* memberA takes up directives. */ }
        action alphaStatus : ReportMemberStatus { doc /* memberA reports its status. */ }
        action alphaTrackPicture : ReportTrackPicture { doc /* memberA reports its tracks. */ }
        action alphaReturn : ReturnToRecoveryPoint { doc /* memberA returns to the recovery point when cut off. */ }

        allocate alphaHandOverSector to memberA;
        allocate alphaRotateRecharge to memberA;
        allocate alphaRedistributeCoverage to memberA;
        allocate alphaDeconflictFlight to memberA;
        allocate alphaRelayReports to memberA;
        allocate alphaCorrelateTracks to memberA;
        allocate alphaHandOverTrack to memberA;
        allocate alphaAdmitMember to memberA;
        allocate alphaDetect to memberA;
        allocate alphaDeliver to memberA;
        allocate alphaDirectives to memberA;
        allocate alphaStatus to memberA;
        allocate alphaTrackPicture to memberA;
        allocate alphaReturn to memberA;

        // memberB
        action bravoHandOverSector : HandOverSector { doc /* memberB hands over its sector. */ }
        action bravoRotateRecharge : RotateRecharge { doc /* memberB takes part in the recharge rotation. */ }
        action bravoRedistributeCoverage : RedistributeCoverage { doc /* memberB re-spreads coverage. */ }
        action bravoDeconflictFlight : DeconflictFlight { doc /* memberB deconflicts its flight. */ }
        action bravoRelayReports : RelayReportsThroughNeighbour { doc /* memberB relays reports through a neighbour. */ }
        action bravoCorrelateTracks : CorrelateTracks { doc /* memberB correlates tracks with neighbours. */ }
        action bravoHandOverTrack : HandOverTrack { doc /* memberB hands a track over. */ }
        action bravoAdmitMember : AdmitMember { doc /* memberB takes part in member admission. */ }
        action bravoDetect : DetectAndClassifyObject { doc /* memberB detects and classifies. */ }
        action bravoDeliver : DeliverDetectionReport { doc /* memberB delivers and holds reports. */ }
        action bravoDirectives : ApplySupervisoryDirectives { doc /* memberB takes up directives. */ }
        action bravoStatus : ReportMemberStatus { doc /* memberB reports its status. */ }
        action bravoTrackPicture : ReportTrackPicture { doc /* memberB reports its tracks. */ }
        action bravoReturn : ReturnToRecoveryPoint { doc /* memberB returns to the recovery point when cut off. */ }

        allocate bravoHandOverSector to memberB;
        allocate bravoRotateRecharge to memberB;
        allocate bravoRedistributeCoverage to memberB;
        allocate bravoDeconflictFlight to memberB;
        allocate bravoRelayReports to memberB;
        allocate bravoCorrelateTracks to memberB;
        allocate bravoHandOverTrack to memberB;
        allocate bravoAdmitMember to memberB;
        allocate bravoDetect to memberB;
        allocate bravoDeliver to memberB;
        allocate bravoDirectives to memberB;
        allocate bravoStatus to memberB;
        allocate bravoTrackPicture to memberB;
        allocate bravoReturn to memberB;

        // ---------- What members exchange with each other (over the mesh) ----------

        flow handOverSectorAtoB of Common::SectorHandoverProposal from alphaHandOverSector.handoverOut to bravoHandOverSector.handoverIn { doc /* memberA proposes a sector handover to memberB. */ }
        flow handOverSectorBtoA of Common::SectorHandoverProposal from bravoHandOverSector.handoverOut to alphaHandOverSector.handoverIn { doc /* memberB proposes a sector handover to memberA. */ }
        flow rotateRechargeAtoB of Common::RechargeRotationSlot from alphaRotateRecharge.rotationOut to bravoRotateRecharge.rotationIn { doc /* memberA tells memberB its place in the recharge rotation. */ }
        flow rotateRechargeBtoA of Common::RechargeRotationSlot from bravoRotateRecharge.rotationOut to alphaRotateRecharge.rotationIn { doc /* memberB tells memberA its place in the recharge rotation. */ }
        flow redistributeCoverageAtoB of Common::CoverageAssignment from alphaRedistributeCoverage.coverageOut to bravoRedistributeCoverage.coverageIn { doc /* memberA sends its share of coverage to memberB. */ }
        flow redistributeCoverageBtoA of Common::CoverageAssignment from bravoRedistributeCoverage.coverageOut to alphaRedistributeCoverage.coverageIn { doc /* memberB sends its share of coverage to memberA. */ }
        flow deconflictFlightAtoB of Common::FlightIntent from alphaDeconflictFlight.intentOut to bravoDeconflictFlight.intentIn { doc /* memberA announces flight intent to memberB. */ }
        flow deconflictFlightBtoA of Common::FlightIntent from bravoDeconflictFlight.intentOut to alphaDeconflictFlight.intentIn { doc /* memberB announces flight intent to memberA. */ }
        flow relayReportsAtoB of Common::DetectionReport from alphaRelayReports.relayOut to bravoRelayReports.relayIn { doc /* memberA passes a report to memberB to carry onward. */ }
        flow relayReportsBtoA of Common::DetectionReport from bravoRelayReports.relayOut to alphaRelayReports.relayIn { doc /* memberB passes a report to memberA to carry onward. */ }
        flow correlateTracksAtoB of Common::Track from alphaCorrelateTracks.correlationOut to bravoCorrelateTracks.correlationIn { doc /* memberA shares a track for correlation. */ }
        flow correlateTracksBtoA of Common::Track from bravoCorrelateTracks.correlationOut to alphaCorrelateTracks.correlationIn { doc /* memberB shares a track for correlation. */ }
        flow handOverTrackAtoB of Common::Track from alphaHandOverTrack.trackHandoverOut to bravoHandOverTrack.trackHandoverIn { doc /* memberA hands a track to memberB. */ }
        flow handOverTrackBtoA of Common::Track from bravoHandOverTrack.trackHandoverOut to alphaHandOverTrack.trackHandoverIn { doc /* memberB hands a track to memberA. */ }
        flow admitMemberAtoB of Common::AdmissionExchange from alphaAdmitMember.admissionOut to bravoAdmitMember.admissionIn { doc /* memberA exchanges admission evidence with memberB. */ }
        flow admitMemberBtoA of Common::AdmissionExchange from bravoAdmitMember.admissionOut to alphaAdmitMember.admissionIn { doc /* memberB exchanges admission evidence with memberA. */ }

        // ---------- Detection, reporting and acknowledgement ----------

        flow detectionAlpha of Common::DetectionReport from alphaDetect.detectionOut to alphaDeliver.detectionIn { doc /* memberA passes a classified detection to its delivery. */ }
        flow detectionBravo of Common::DetectionReport from bravoDetect.detectionOut to bravoDeliver.detectionIn { doc /* memberB passes a classified detection to its delivery. */ }
        flow reportFromAlpha of Common::DetectionReport from alphaDeliver.reportOut to acknowledgeReports.reportIn { doc /* memberA's report reaches the operations centre over the ground link. */ }
        flow reportFromBravo of Common::DetectionReport from bravoDeliver.reportOut to acknowledgeReports.reportIn { doc /* memberB's report reaches the operations centre over the ground link. */ }
        flow receiptToAlpha of Common::ReportReceipt from acknowledgeReports.receiptOut to alphaDeliver.receiptIn { doc /* The acknowledgement returns to memberA. */ }
        flow receiptToBravo of Common::ReportReceipt from acknowledgeReports.receiptOut to bravoDeliver.receiptIn { doc /* The acknowledgement returns to memberB. */ }

        // ---------- Status and tracks ----------

        flow statusFromAlpha of Common::MemberStatus from alphaStatus.statusOut to presentStatus.statusIn { doc /* memberA's status feeds the status picture. */ }
        flow statusFromBravo of Common::MemberStatus from bravoStatus.statusOut to presentStatus.statusIn { doc /* memberB's status feeds the status picture. */ }
        flow trackPictureFromAlpha of Common::Track from alphaTrackPicture.trackPictureOut to mergeTracks.swarmTrackIn { doc /* memberA's tracks go to the analyst for merging. */ }
        flow trackPictureFromBravo of Common::Track from bravoTrackPicture.trackPictureOut to mergeTracks.swarmTrackIn { doc /* memberB's tracks go to the analyst for merging. */ }
        flow cameraTracksToMerge of Common::Track from provideCameraTracks.cameraTrackOut to mergeTracks.cameraTrackIn { doc /* The camera network's own tracks go to the analyst for merging. */ }

        // ---------- Command from the duty controller ----------

        flow taskingToAlpha of Common::TaskingOrder from issueTasking.taskingOut to alphaDirectives.taskingIn { doc /* Tasking reaches memberA. */ }
        flow taskingToBravo of Common::TaskingOrder from issueTasking.taskingOut to bravoDirectives.taskingIn { doc /* Tasking reaches memberB. */ }
        flow prioritiesToAlpha of Common::PriorityDirective from issuePriorities.priorityOut to alphaDirectives.priorityIn { doc /* Priorities and the reporting threshold reach memberA. */ }
        flow prioritiesToBravo of Common::PriorityDirective from issuePriorities.priorityOut to bravoDirectives.priorityIn { doc /* Priorities and the reporting threshold reach memberB. */ }
        flow recallToAlpha of Common::RecallDirective from issueRecall.recallOut to alphaDirectives.recallIn { doc /* A recall order reaches memberA. */ }
        flow recallToBravo of Common::RecallDirective from issueRecall.recallOut to bravoDirectives.recallIn { doc /* A recall order reaches memberB. */ }

        // ---------- Capabilities and mission ----------

        #Mission use case def WatchTheTaskedArea {
            doc /* Hold continuous watch over a tasked area of up to 25 km2 and turn what happens there into acknowledged, triaged detection reports at the operations centre, inside airspace clearance, weather, radio interference and satellite-positioning outages. */
            subject holder : SwarmMember;
        }

        #Capability use case def ContinuousSectorWatch {
            doc /* Hold continuous surveillance: at any moment at least one drone watches each sector, as members leave to recharge and rejoin. */
            subject holder : SwarmMember;
        }
        #Capability use case def MovingObjectDetectionAndClassification {
            doc /* Detect moving objects, classify them well enough to say whether they matter, and say Unknown rather than force a class below the reporting threshold. */
            subject holder : SwarmMember;
        }
        #Capability use case def ReportDeliveryAndReconciliation {
            doc /* Deliver each report with position and time, keep detecting and holding reports while cut off, and reconcile with none lost once the link is back. */
            subject holder : SwarmMember;
        }
        #Capability use case def SwarmSelfCoordination {
            doc /* Settle sector handover, recharge rotation, coverage redistribution, deconfliction, link relay, track correlation, track handover and member admission between the drones over the mesh. */
            subject holder : SwarmMember;
        }
        #Capability use case def OperatorSupervisionOfTheSwarm {
            doc /* Let one operator task, command, recall and watch the whole swarm rather than fly each drone, and acknowledge each report. */
            subject holder : DutyController;
        }
        #Capability use case def AlertTriage {
            doc /* Triage reports before they reach the operator, most likely to matter first and duplicates merged, so the alert rate stays inside what one operator can judge. */
            subject holder : OperationsCentreAnalyst;
        }
        #Capability use case def DecisionRecordKeeping {
            doc /* Keep, for every report, the frames it came from, the classifier version, the reporting threshold in force and who acknowledged it. */
            subject holder : OperationsCentreAnalyst;
        }
        #Capability use case def GracefulDegradationUnderLoss {
            doc /* Keep flying and watching when a drone is lost, the mesh is jammed or the ground link or ground station drops, with the loss of coverage bounded. */
            subject holder : SwarmMember;
        }
        #Capability use case def AirspaceComplianceAndSafeRecovery {
            doc /* Stay inside cleared airspace, land when it is not cleared or wind exceeds moderate, and return to a recovery point when contact with the swarm is lost. */
            subject holder : SwarmMember;
        }
        #Capability use case def ClassifierVersionConsistency {
            doc /* Keep one classifier version across the fleet and know which version each drone runs, so one object is not classified differently by different drones. */
            subject holder : SwarmMember;
        }

        // ---------- Operational modes and states ----------

        #Mode state def SwarmMemberModes {
            doc /* Operating conditions of one drone: nominal, without satellite positioning, sensors not trustworthy, cut off from the other drones, or failed admission. */
            initial start;
            transition start -> Nominal;
            state Nominal { doc /* The drone has positioning, trusted sensors, contact with the swarm and admission. */ }
            state NavigationDegraded { doc /* The drone has no satellite positioning and navigates by what its camera sees against stored maps. */ }
            state SensingDegraded { doc /* The drone's sensors cannot be trusted as they are, and what it reports from them is marked accordingly. */ }
            state Isolated { doc /* The drone is cut off from the other drones and coordinates with none of them. */ }
            state Quarantined { doc /* The drone has failed admission and takes no part in coordination until it has been readmitted. */ }
            transition losePositioning first Nominal accept positioningLostNotice : Common::ConditionNotice do action navigateByCamera then NavigationDegraded;
            transition regainPositioning first NavigationDegraded accept positioningBackNotice : Common::ConditionNotice do action resumeSatelliteNavigation then Nominal;
            transition degradeSensing first Nominal accept sensingDegradedNotice : Common::ConditionNotice do action markReportsUnreliable then SensingDegraded;
            transition restoreSensing first SensingDegraded accept sensingRestoredNotice : Common::ConditionNotice do action clearReportMarking then Nominal;
            transition loseContact first Nominal accept contactLostNotice : Common::ConditionNotice do action coordinateWithNone then Isolated;
            transition regainContact first Isolated accept contactBackNotice : Common::ConditionNotice do action rejoinCoordination then Nominal;
            transition failAdmission first Nominal accept admissionFailed : Common::AdmissionExchange do action withdrawFromCoordination then Quarantined;
            transition readmit first Quarantined accept readmission : Common::AdmissionExchange do action resumeCoordination then Nominal;
        }

        #State state def SwarmMemberStates {
            doc /* Where one drone is in its sortie: on the ground, flying out, watching, flying back, recalled, or returning to the recovery point on its own. */
            initial start;
            transition start -> Landed;
            state Landed { doc /* On the ground, battery being swapped or waiting for tasking. */ }
            state Transiting { doc /* Flying from the recharge point to its sector. */ }
            state Watching { doc /* Holding watch over its sector. */ }
            state Returning { doc /* Flying back to the recharge point to swap the battery. */ }
            state Recalled { doc /* Recalled by order and on its way down; it does not watch until landed. */ }
            state Recovering { doc /* Cut off from the swarm and returning to the recovery point on its own. */ }
            transition launch first Landed accept taskingReceived : Common::TaskingOrder do action beginTransit then Transiting;
            transition Transiting -> Watching;
            transition Watching -> Returning;
            transition Returning -> Landed;
            transition recallWhileTransiting first Transiting accept recallReceivedEarly : Common::RecallDirective do action abortTransit then Recalled;
            transition recallWhileWatching first Watching accept recallReceived : Common::RecallDirective do action abortWatch then Recalled;
            transition Recalled -> Landed;
            transition loseSwarmContact first Watching accept swarmContactLost : Common::ConditionNotice do action headForRecoveryPoint then Recovering;
            transition Recovering -> Landed;
        }

        #Mode state def FleetModes {
            doc /* Condition of the mesh between drones, taken over the whole population watchAsset. */
            initial start;
            transition start -> MeshIntact;
            state MeshIntact { doc /* The links between drones are all usable. */ }
            state MeshDegraded { doc /* A share of the links between drones is jammed and the swarm coordinates over what is left. */ }
            transition meshJammed first MeshIntact accept jammingNotice : Common::ConditionNotice do action coordinateOverRemainingLinks then MeshDegraded;
            transition meshRestored first MeshDegraded accept jammingClearedNotice : Common::ConditionNotice do action restoreFullCoordination then MeshIntact;
        }

        #State state def FleetStates {
            doc /* Where the whole population watchAsset is in the mission: on the ground, on watch, or recalled. */
            initial start;
            transition start -> Grounded;
            state Grounded { doc /* No drone is flying. */ }
            state OnWatch { doc /* The population holds the watch, rotating members through recharge. */ }
            state Recalled { doc /* The whole population has been recalled and lands. */ }
            transition fleetLaunch first Grounded accept fleetTasking : Common::TaskingOrder do action launchRotation then OnWatch;
            transition fleetRecall first OnWatch accept fleetRecallOrder : Common::RecallDirective do action landPopulation then Recalled;
            transition Recalled -> Grounded;
        }

        // ---------- Hazards this layer adds ----------

        package Hazards {
            doc /* Hazards of the operation as it is, without the system. */

            #Hazard requirement ManualCoordinationLagHazard {
                doc /* Sector assignment, handover, re-spread and deconfliction done by hand lag behind events, and a sector goes unwatched. */
                subject holder : DutyController;
            }
            #Hazard requirement UnrecoveredDroneHazard {
                doc /* A drone that has lost contact with the swarm keeps flying with nowhere to go and becomes a hazard. */
                subject holder : SwarmMember;
            }
            #Hazard requirement ReportLostInLinkGapHazard {
                doc /* A detection report is sent into a link gap and nobody knows it never arrived. */
                subject holder : OperationsCentreAnalyst;
            }
            #Hazard requirement WatchBeyondClearanceHazard {
                doc /* A drone keeps flying its watch after the airspace clearance has been withdrawn. */
                subject holder : SwarmMember;
            }
        }

        satisfy Hazards::ManualCoordinationLagHazard by alphaRedistributeCoverage;
        satisfy Hazards::UnrecoveredDroneHazard by alphaReturn;
        satisfy Hazards::ReportLostInLinkGapHazard by acknowledgeReports;
        satisfy Hazards::WatchBeyondClearanceHazard by alphaDirectives;
    }
    package SA {
        #prompt part saGuidance {
            doc /* SA: the system is one black-box part with ports. Every function is allocated to the system or to an actor, and traces to at least one operational activity. No design choices here. */
        }

        // the system, black box
        part def SurveillanceDroneSwarmSystem {
            doc /* The whole surveillance drone swarm seen as one black box: the twelve-drone population, its mesh, its on-board sensing and its tasking, reporting and status functions, with no internal structure. It takes tasking, supervisory command, recall, acknowledgements, airspace clearance, serviced drones and the moving objects in the area, and gives detection reports, triaged alerts, the track picture, the status picture, decision records and arriving drones. */
            in port taskingIn : Common::TaskingOrder;
            in port supervisoryIn : Common::PriorityDirective;
            in port recallIn : Common::RecallDirective;
            in port acknowledgementIn : Common::ReportReceipt;
            in port objectsIn : Common::MovingObjectsInArea;
            in port clearanceIn : Common::AirspaceClearance;
            in port servicedDroneIn : Common::DroneServiced;
            out port reportsOut : Common::DetectionReport;
            out port alertsOut : Common::TriagedAlerts;
            out port trackPictureOut : Common::Track;
            out port statusOut : Common::MemberStatus;
            out port decisionRecordsOut : Common::DecisionRecords;
            out port rechargeArrivalOut : Common::DroneArrival;
            out port recoveryArrivalOut : Common::DroneArrival;
        }
        part system : SurveillanceDroneSwarmSystem {
            doc /* The system under design: the twelve-drone swarm as one black box. */
        }
        trace system to SurveillanceDroneSwarm::OA::watchAsset;

        #prose part environmentConstraints {
            doc /* Constraining inputs carried as constraints on the system, not as ports, because no actor sends them: RadioInterference (degrades the mesh and the ground link), SatellitePositioningOutage (minutes at a time), WeatherLightingAndDeception (sensing degrades; the swarm lands above moderate wind), FixedCameraNetwork tracks that swarm tracks must be mergeable with, OperatorAttentionLimit (a bounded number of alerts per hour), and WatchAndReportOnlyScope (weapons, interception and anything done to what is detected are out of scope). The clearance from the airspace authority does arrive through a port, clearanceIn. */
        }

        // the population: 12 identical members (CV-16)
        #Member part def SwarmMember {
            doc /* One member of the twelve-drone population: a small drone that flies about 40 minutes at about 18 m/s and keeps about 3.0 km2 under watch. At SA the system is still one black box: this definition is carried, not instantiated, and holds the two state machines every member follows. */
            out port meshOut : Common::MeshPort;
            in port meshIn : ~Common::MeshPort;

            #Mode state def SwarmMemberModes {
                doc /* Operating condition of one drone: nominal, without satellite positioning, sensors not trustworthy, cut off from the other drones, or failed admission and readmitted. Carries the rule QuarantinedStaysOut. */
                @SysproseVerification::PropertyPattern {
                    doc /* QuarantinedStaysOut: once a drone is quarantined, it takes no part in coordination until it has been readmitted. */
                    attribute pattern = "absence";
                    attribute scope = "between";
                    attribute q = "state Quarantined";
                    attribute r = "state Readmitted";
                    attribute p = "state Nominal";
                }
                initial start;
                transition start -> Nominal;
                state Nominal {
                    doc /* The drone has positioning, trusted sensors, contact with the swarm and admission, and takes part in coordination. */
                }
                state NavigationDegraded {
                    doc /* The drone has no satellite positioning and navigates by what its camera sees against stored maps. */
                }
                state SensingDegraded {
                    doc /* The drone's sensors cannot be trusted as they are, and what it reports from them is marked accordingly. */
                }
                state Isolated {
                    doc /* The drone is cut off from the other drones and coordinates with none of them. */
                }
                state Quarantined {
                    doc /* The drone has failed admission and takes no part in coordination until it has been readmitted. */
                }
                state Readmitted {
                    doc /* The drone has passed the readmission check and is about to take part in coordination again. */
                }
                transition losePositioning first Nominal accept positioningLost : Common::PositioningStatus do action navigateByCamera then NavigationDegraded;
                transition regainPositioning first NavigationDegraded accept positioningRegained : Common::PositioningStatus do action resumeSatelliteNavigation then Nominal;
                transition degradeSensing first Nominal accept sensorHealthLost : Common::SensorHealthStatus do action markReportsUnreliable then SensingDegraded;
                transition restoreSensing first SensingDegraded accept sensorHealthRestored : Common::SensorHealthStatus do action clearReportMarking then Nominal;
                transition loseContact first Nominal accept meshContactLost : Common::MeshLinkStatus do action coordinateWithNone then Isolated;
                transition regainContact first Isolated accept meshContactRegained : Common::MeshLinkStatus do action resumeCoordination then Nominal;
                transition failAdmission first Nominal accept admissionFailed : Common::AdmissionExchange do action stopCoordinating then Quarantined;
                transition readmit first Quarantined accept readmissionPassed : Common::AdmissionExchange do action rejoinAfterCheck then Readmitted;
                transition Readmitted -> Nominal;
            }

            #State state def SwarmMemberStates {
                doc /* Where one drone is in its sortie: on the ground, flying out, watching, flying back, recalled, outside its cleared airspace, or returning to the recovery point on its own. Carries the rules RecallWins, GeofenceBreachEndsWatch and ReturnsWhenIsolated. */
                @SysproseVerification::PropertyPattern {
                    doc /* RecallWins: once a drone is recalled, it does not watch again until it has landed. */
                    attribute pattern = "absence";
                    attribute scope = "between";
                    attribute q = "state Recalled";
                    attribute r = "state Landed";
                    attribute p = "state Watching";
                }
                @SysproseVerification::PropertyPattern {
                    doc /* GeofenceBreachEndsWatch: once a drone is outside its cleared airspace, it does not watch until it has landed. */
                    attribute pattern = "absence";
                    attribute scope = "between";
                    attribute q = "state OutsideClearance";
                    attribute r = "state Landed";
                    attribute p = "state Watching";
                }
                @SysproseVerification::PropertyPattern {
                    doc /* ReturnsWhenIsolated: from any situation a drone can be in, it can always get back to landed; an isolated drone included. */
                    attribute pattern = "recovery";
                    attribute scope = "globally";
                    attribute p = "state Landed";
                }
                initial start;
                transition start -> Landed;
                state Landed {
                    doc /* On the ground, battery being swapped or waiting for tasking. */
                }
                state Transiting {
                    doc /* Flying from the recharge point to its sector. */
                }
                state Watching {
                    doc /* Holding watch over its sector. */
                }
                state Returning {
                    doc /* Flying back to the recharge point to swap the battery, or to land when the wind is above moderate. */
                }
                state Recalled {
                    doc /* Recalled by order and on its way down; it does not watch until landed. */
                }
                state Recovering {
                    doc /* Cut off from the swarm and returning to the recovery point on its own. */
                }
                state OutsideClearance {
                    doc /* Outside the cleared airspace or the clearance withdrawn: on its way down, and it does not watch until landed. */
                }
                transition launch first Landed accept assignment : Common::TaskingOrder do action startSortie then Transiting;
                transition Transiting -> Watching;
                transition endWatch first Watching accept rotationSlot : Common::RechargeRotationSlot do action handSectorAndReturn then Returning;
                transition Returning -> Landed;
                transition recallWhileTransiting first Transiting accept recallDirective : Common::RecallDirective do action abortTransitAndLand then Recalled;
                transition recallWhileWatching first Watching accept recallDirective : Common::RecallDirective do action abortWatchAndLand then Recalled;
                transition Recalled -> Landed;
                transition loseSwarmContact first Watching accept contactLost : Common::MeshLinkStatus do action headForRecoveryPoint then Recovering;
                transition loseContactInTransit first Transiting accept contactLostEnRoute : Common::MeshLinkStatus do action headForRecoveryPointFromTransit then Recovering;
                transition Recovering -> Landed;
                transition leaveClearanceWhileWatching first Watching accept clearanceUpdate : Common::AirspaceClearance do action stopWatchOutsideClearance then OutsideClearance;
                transition leaveClearanceInTransit first Transiting accept clearanceUpdateEnRoute : Common::AirspaceClearance do action stopTransitOutsideClearance then OutsideClearance;
                transition OutsideClearance -> Landed;
                transition windLimit first Watching accept weatherNow : Common::WeatherCondition do action landInWind then Returning;
            }
        }
        #prose part fleetFact {
            doc /* Population: 12 members of SwarmMember, carried by fleet, exchanging through Common::MeshInterface. Carried from the brief; instantiated from LA down. */
        }

        // fleet-level configuration: the condition of the mesh over the whole population
        #Configuration state def FleetConfiguration {
            doc /* Condition of the mesh between drones, taken over the whole twelve-drone population. */
            initial start;
            transition start -> MeshIntact;
            state MeshIntact {
                doc /* The links between drones are all usable. */
            }
            state MeshDegraded {
                doc /* A share of the links between drones is jammed and the swarm coordinates over what is left. */
            }
            transition meshJammed first MeshIntact accept jamming : Common::MeshLinkStatus do action coordinateOverRemainingLinks then MeshDegraded;
            transition meshRestored first MeshDegraded accept linksRestored : Common::MeshLinkStatus do action resumeFullCoordination then MeshIntact;
        }

        // actors: every operational entity the system is not
        #Actor part def DutyController {
            doc /* Operations-centre operator who tasks the swarm, issues supervisory command and recall. Exchanges through three outgoing ports. */
            out port taskingOut : Common::TaskingOrder;
            out port priorityOut : Common::PriorityDirective;
            out port recallOut : Common::RecallDirective;
        }
        part dutyController : DutyController {
            doc /* The one operator who supervises the whole swarm. */
        }
        trace dutyController to SurveillanceDroneSwarm::OA::dutyController;
        #Actor part def OperationsCentreAnalyst {
            doc /* Judges the alerts, acknowledges each detection report and merges swarm tracks with the fixed camera network's tracks. Receives reports, alerts, the swarm track picture, decision records and the camera tracks; returns the acknowledgement. */
            in port reportsIn : Common::DetectionReport;
            in port alertsIn : Common::TriagedAlerts;
            in port trackPictureIn : Common::Track;
            in port recordsIn : Common::DecisionRecords;
            in port cameraTrackIn : Common::Track;
            out port receiptOut : Common::ReportReceipt;
        }
        part operationsCentreAnalyst : OperationsCentreAnalyst {
            doc /* The analyst at the operations centre. */
        }
        trace operationsCentreAnalyst to SurveillanceDroneSwarm::OA::operationsCentreAnalyst;
        #Actor part def AirspaceAuthority {
            doc /* Grants and withdraws the clearance that says when and where anything may fly. Exchanges through one outgoing port. */
            out port clearanceOut : Common::AirspaceClearance;
        }
        part airspaceAuthority : AirspaceAuthority {
            doc /* The authority whose clearance bounds every flight. */
        }
        trace airspaceAuthority to SurveillanceDroneSwarm::OA::airspaceAuthority;
        #Actor part def GroundCrew {
            doc /* Services drones between sorties and recovers drones that return on their own; hands serviced drones back to the swarm. */
            out port servicedDroneOut : Common::DroneServiced;
        }
        part groundCrew : GroundCrew {
            doc /* The crew at the recharge point and the recovery point. */
        }
        trace groundCrew to SurveillanceDroneSwarm::OA::groundCrew;
        #Actor part def FixedCameraNetworkOperator {
            doc /* Keeps the existing fixed camera network and its own tracks in service. It has no exchange with the system at SA; its tracks reach the analyst through the camera network. */
        }
        part fixedCameraNetworkOperator : FixedCameraNetworkOperator {
            doc /* The operator of the fixed camera network. */
        }
        trace fixedCameraNetworkOperator to SurveillanceDroneSwarm::OA::fixedCameraNetworkOperator;
        #Actor part def GroundStationNode {
            doc /* The station that tasks and watches the swarm and shows its status picture. At SA it receives the status picture; whether it also coordinates the swarm is the command-and-control architecture decision taken later. */
            in port statusIn : Common::MemberStatus;
        }
        part groundStation : GroundStationNode {
            doc /* The ground station used today. */
        }
        trace groundStation to SurveillanceDroneSwarm::OA::groundStation;
        #Actor part def MeshRadio {
            doc /* The radio mesh carrying coordination traffic between drones; it does not depend on the link to the operations centre. It is a medium inside the swarm, so it has no port on the system at SA; PA types the member-to-member links by it. */
        }
        part meshRadioBetweenDrones : MeshRadio {
            doc /* The mesh radio that carries the traffic between drones. */
        }
        trace meshRadioBetweenDrones to SurveillanceDroneSwarm::OA::meshRadioBetweenDrones;
        #Actor part def GroundLinkRadio {
            doc /* The intermittently available radio link carrying tasking, command, reports, status and acknowledgements to and from the operations centre. It is the medium under the ports to the operations-centre actors; its intermittency is carried as a constraint and allocated at PA. */
        }
        part groundLinkToOperationsCentre : GroundLinkRadio {
            doc /* The intermittent link to the operations centre. */
        }
        trace groundLinkToOperationsCentre to SurveillanceDroneSwarm::OA::groundLinkToOperationsCentre;
        #Actor part def RechargePoint {
            doc /* Where batteries are swapped, not charged in place; about 20 minutes of turnaround. Receives drones that come down to be serviced. */
            in port arrivalIn : Common::DroneArrival;
        }
        part batterySwapAtRechargePoint : RechargePoint {
            doc /* The recharge point where ground crew swap batteries. */
        }
        trace batterySwapAtRechargePoint to SurveillanceDroneSwarm::OA::batterySwapAtRechargePoint;
        #Actor part def RecoveryPoint {
            doc /* The point a drone that has lost contact with the swarm returns to on its own rather than becoming a hazard. Receives such drones. */
            in port arrivalIn : Common::DroneArrival;
        }
        part recoveryPoint : RecoveryPoint {
            doc /* The recovery point for drones that return on their own. */
        }
        trace recoveryPoint to SurveillanceDroneSwarm::OA::recoveryPoint;
        #Actor part def FixedCameraNetwork {
            doc /* The existing camera network; it stays and keeps its own tracks, which swarm reports must be mergeable with. */
            out port cameraTrackOut : Common::Track;
        }
        part fixedCameraNetwork : FixedCameraNetwork {
            doc /* The existing fixed camera network. */
        }
        trace fixedCameraNetwork to SurveillanceDroneSwarm::OA::fixedCameraNetwork;
        #Actor part def MovingObjectsSource {
            doc /* The moving objects in the tasked area that the swarm must detect, classify and place in time and space. An environment source, not an operational entity of OA, so it carries no trace. */
            out port objectsOut : Common::MovingObjectsInArea;
        }
        part movingObjectsInArea : MovingObjectsSource {
            doc /* Whatever moves through the tasked area. */
        }

        // the system ports wired to the actors
        connection taskingLink connect dutyController.taskingOut to system.taskingIn;
        connection supervisoryLink connect dutyController.priorityOut to system.supervisoryIn;
        connection recallLink connect dutyController.recallOut to system.recallIn;
        connection acknowledgementLink connect operationsCentreAnalyst.receiptOut to system.acknowledgementIn;
        connection objectsLink connect movingObjectsInArea.objectsOut to system.objectsIn;
        connection clearanceLink connect airspaceAuthority.clearanceOut to system.clearanceIn;
        connection servicedDroneLink connect groundCrew.servicedDroneOut to system.servicedDroneIn;
        connection reportsLink connect system.reportsOut to operationsCentreAnalyst.reportsIn;
        connection alertsLink connect system.alertsOut to operationsCentreAnalyst.alertsIn;
        connection trackPictureLink connect system.trackPictureOut to operationsCentreAnalyst.trackPictureIn;
        connection statusLink connect system.statusOut to groundStation.statusIn;
        connection decisionRecordsLink connect system.decisionRecordsOut to operationsCentreAnalyst.recordsIn;
        connection rechargeArrivalLink connect system.rechargeArrivalOut to batterySwapAtRechargePoint.arrivalIn;
        connection recoveryArrivalLink connect system.recoveryArrivalOut to recoveryPoint.arrivalIn;
        connection cameraTracksLink connect fixedCameraNetwork.cameraTrackOut to operationsCentreAnalyst.cameraTrackIn;

        // capabilities, carried over with the system as subject
        #Capability use case def WatchTheTaskedArea {
            doc /* Hold continuous watch over a tasked area of up to 25 km2 and turn what happens there into acknowledged, triaged detection reports at the operations centre. */
            subject s : SurveillanceDroneSwarmSystem;
        }
        trace WatchTheTaskedArea to SurveillanceDroneSwarm::OA::WatchTheTaskedArea;
        #Capability use case def ContinuousSectorWatch {
            doc /* At any moment at least one drone watches each sector, as members leave to recharge and rejoin. */
            subject s : SurveillanceDroneSwarmSystem;
        }
        trace ContinuousSectorWatch to SurveillanceDroneSwarm::OA::ContinuousSectorWatch;
        #Capability use case def MovingObjectDetectionAndClassification {
            doc /* Detect moving objects, classify them well enough to say whether they matter, and say Unknown rather than force a class below the reporting threshold. */
            subject s : SurveillanceDroneSwarmSystem;
        }
        trace MovingObjectDetectionAndClassification to SurveillanceDroneSwarm::OA::MovingObjectDetectionAndClassification;
        #Capability use case def ReportDeliveryAndReconciliation {
            doc /* Deliver each report with position and time, keep detecting and holding reports while cut off, and reconcile with none lost once the link is back. */
            subject s : SurveillanceDroneSwarmSystem;
        }
        trace ReportDeliveryAndReconciliation to SurveillanceDroneSwarm::OA::ReportDeliveryAndReconciliation;
        #Capability use case def SwarmSelfCoordination {
            doc /* Settle sector handover, recharge rotation, coverage redistribution, deconfliction, link relay, track correlation, track handover and member admission between the drones over the mesh. */
            subject s : SurveillanceDroneSwarmSystem;
        }
        trace SwarmSelfCoordination to SurveillanceDroneSwarm::OA::SwarmSelfCoordination;
        #Capability use case def OperatorSupervisionOfTheSwarm {
            doc /* Let one operator task, command, recall and watch the whole swarm rather than fly each drone, and acknowledge each report. */
            subject s : SurveillanceDroneSwarmSystem;
        }
        trace OperatorSupervisionOfTheSwarm to SurveillanceDroneSwarm::OA::OperatorSupervisionOfTheSwarm;
        #Capability use case def AlertTriage {
            doc /* Triage reports before they reach the operator, most likely to matter first and duplicates merged, so the alert rate stays inside what one operator can judge. */
            subject s : SurveillanceDroneSwarmSystem;
        }
        trace AlertTriage to SurveillanceDroneSwarm::OA::AlertTriage;
        #Capability use case def DecisionRecordKeeping {
            doc /* Keep, for every report, the frames it came from, the classifier version, the reporting threshold in force and who acknowledged it. */
            subject s : SurveillanceDroneSwarmSystem;
        }
        trace DecisionRecordKeeping to SurveillanceDroneSwarm::OA::DecisionRecordKeeping;
        #Capability use case def GracefulDegradationUnderLoss {
            doc /* Keep flying and watching when a drone is lost, the mesh is jammed or the ground link or ground station drops, with the loss of coverage bounded. */
            subject s : SurveillanceDroneSwarmSystem;
        }
        trace GracefulDegradationUnderLoss to SurveillanceDroneSwarm::OA::GracefulDegradationUnderLoss;
        #Capability use case def AirspaceComplianceAndSafeRecovery {
            doc /* Stay inside cleared airspace, land when it is not cleared or wind exceeds moderate, and return to a recovery point when contact with the swarm is lost. */
            subject s : SurveillanceDroneSwarmSystem;
        }
        trace AirspaceComplianceAndSafeRecovery to SurveillanceDroneSwarm::OA::AirspaceComplianceAndSafeRecovery;
        #Capability use case def ClassifierVersionConsistency {
            doc /* Keep one classifier version across the fleet and know which version each drone runs, so one object is not classified differently by different drones. */
            subject s : SurveillanceDroneSwarmSystem;
        }
        trace ClassifierVersionConsistency to SurveillanceDroneSwarm::OA::ClassifierVersionConsistency;

        // function definitions
        action def TaskSurveillanceArea {
            doc /* The duty controller tasks the swarm with the area of interest, its sectors and the mission window. */
            out taskingOut;
        }
        action def CommandSupervisoryPriorities {
            doc /* The duty controller gives priorities, a sector to look at more closely and the reporting threshold. */
            out priorityOut;
        }
        action def RecallAndLand {
            doc /* An order to recall and land the whole swarm or one drone, issuable at any time. */
            out recallOut;
        }
        action def PresentStatusPicture {
            doc /* Shows where every drone is, what it is doing, how much of the area is under watch and what is degraded. */
            in statusIn;
        }
        action def AcknowledgeDetectionReport {
            doc /* The operations centre confirms each detection report so nothing is lost in a link gap, judging the triaged alerts it is given. */
            in reportIn;
            in alertsIn;
            out receiptOut;
        }
        action def MergeSwarmTracks {
            doc /* The analyst merges swarm tracks with the camera network's tracks, one track per object. */
            in swarmTrackIn;
            in cameraTrackIn;
        }
        action def ProvideCameraTracks {
            doc /* The fixed camera network provides its own tracks. */
            out cameraTrackOut;
        }
        action def SwapBattery {
            doc /* Ground crew swap a landed drone's battery at the recharge point, about 20 minutes. */
        }
        action def RecoverReturnedDrone {
            doc /* Ground crew recover a drone that returned to the recovery point on its own. */
        }
        action def GrantAirspaceClearance {
            doc /* The airspace authority grants or withdraws the clearance that bounds when and where anything may fly. */
        }
        action def HandOverSector {
            doc /* A drone hands its sector to a neighbour when it leaves to recharge, so the sector stays watched. */
            out handoverOut;
            in handoverIn;
        }
        action def RotateRecharge {
            doc /* Members agree who leaves to recharge and who takes the place, so the rotation never empties a sector. */
            out rotationOut;
            in rotationIn;
        }
        action def RedistributeCoverage {
            doc /* Members re-spread over the area when one is lost or leaves, so the share of area under watch stays high. */
            out coverageOut;
            in coverageIn;
        }
        action def DeconflictFlight {
            doc /* Members announce flight intent to each other so that two drones do not occupy the same airspace. */
            out intentOut;
            in intentIn;
        }
        action def RelayReportsThroughNeighbour {
            doc /* A member that cannot reach the operations centre sends its reports through a neighbour that can. */
            out relayOut;
            in relayIn;
        }
        action def CorrelateTracks {
            doc /* Members agree that tracks seen by different drones are the same object, giving one track per object. */
            out correlationOut;
            in correlationIn;
        }
        action def HandOverTrack {
            doc /* A track is handed to the drone that watches the sector the object moves into. */
            out trackHandoverOut;
            in trackHandoverIn;
        }
        action def AdmitMember {
            doc /* A drone is checked before it takes part in coordination, including the classifier version it runs; one that fails takes no part until readmitted. */
            out admissionOut;
            in admissionIn;
        }
        action def DetectAndClassifyObject {
            doc /* A drone detects a moving object in its sector and classifies it, saying Unknown when confidence is short of the reporting threshold. */
            out detectionOut;
        }
        action def DeliverDetectionReport {
            doc /* A drone delivers a report with position and time to the operations centre, holds it while cut off, and clears it on acknowledgement. */
            in detectionIn;
            out reportOut;
            in receiptIn;
        }
        action def ApplySupervisoryDirectives {
            doc /* A drone takes up the tasking, priorities and recall given by the duty controller, and lands on recall. */
            in taskingIn;
            in priorityIn;
            in recallIn;
        }
        action def ReportMemberStatus {
            doc /* A drone reports its position, activity and degradations, sensing degradation included, for the status picture. */
            out statusOut;
        }
        action def ReportTrackPicture {
            doc /* A drone reports the tracks it holds, marking a track stale once nothing has seen the object, so the analyst can merge them with the camera network's tracks. */
            out trackPictureOut;
        }
        action def ReturnToRecoveryPoint {
            doc /* A drone that has lost contact with the swarm returns to the recovery point on its own. */
        }
        action def TriageAlerts {
            doc /* Ranks the reports so that what is most likely to matter reaches the operator first, with duplicates merged, keeping the alert rate inside what one operator can judge. */
            in reportsIn;
            out alertsOut;
        }
        action def KeepDecisionRecords {
            doc /* Keeps, for every report, the frames it came from, the classifier version, the reporting threshold in force and who acknowledged it. */
            in reportIn;
            in receiptIn;
        }

        // functions: command and control
        #C2 action taskSurveillanceArea : TaskSurveillanceArea {
            doc /* Command and control: the duty controller tasks the swarm with the area, sectors and mission window. */
        }
        allocate taskSurveillanceArea to dutyController;
        trace taskSurveillanceArea to SurveillanceDroneSwarm::OA::issueTasking;
        #C2 action commandSupervisoryPriorities : CommandSupervisoryPriorities {
            doc /* Command and control: the duty controller gives priorities, a sector to look at more closely and the reporting threshold. */
        }
        allocate commandSupervisoryPriorities to dutyController;
        trace commandSupervisoryPriorities to SurveillanceDroneSwarm::OA::issuePriorities;
        #C2 action recallAndLand : RecallAndLand {
            doc /* Command and control: the duty controller recalls and lands the whole swarm or one drone at any time. */
        }
        allocate recallAndLand to dutyController;
        trace recallAndLand to SurveillanceDroneSwarm::OA::issueRecall;
        #C2 action presentStatusPicture : PresentStatusPicture {
            doc /* Command and control: the ground station shows the status picture of the swarm. */
        }
        allocate presentStatusPicture to groundStation;
        trace presentStatusPicture to SurveillanceDroneSwarm::OA::presentStatus;
        #C2 action acknowledgeDetectionReport : AcknowledgeDetectionReport {
            doc /* Command and control: the analyst acknowledges each detection report and judges the triaged alerts. */
        }
        allocate acknowledgeDetectionReport to operationsCentreAnalyst;
        trace acknowledgeDetectionReport to SurveillanceDroneSwarm::OA::acknowledgeReports;

        // functions performed by actors
        action mergeTracks : MergeSwarmTracks {
            doc /* The analyst merges swarm tracks with the fixed camera network's tracks. */
        }
        allocate mergeTracks to operationsCentreAnalyst;
        trace mergeTracks to SurveillanceDroneSwarm::OA::mergeTracks;
        action provideCameraTracks : ProvideCameraTracks {
            doc /* The fixed camera network keeps and provides its own tracks. */
        }
        allocate provideCameraTracks to fixedCameraNetwork;
        trace provideCameraTracks to SurveillanceDroneSwarm::OA::provideCameraTracks;
        action swapBatteryAct : SwapBattery {
            doc /* Ground crew swap a landed drone's battery. */
        }
        allocate swapBatteryAct to groundCrew;
        trace swapBatteryAct to SurveillanceDroneSwarm::OA::swapBatteryAct;
        action recoverDroneAct : RecoverReturnedDrone {
            doc /* Ground crew recover a drone that returned on its own. */
        }
        allocate recoverDroneAct to groundCrew;
        trace recoverDroneAct to SurveillanceDroneSwarm::OA::recoverDroneAct;
        action grantClearanceAct : GrantAirspaceClearance {
            doc /* The airspace authority grants or withdraws the clearance. */
        }
        allocate grantClearanceAct to airspaceAuthority;
        trace grantClearanceAct to SurveillanceDroneSwarm::OA::grantClearanceAct;

        // functions: coordination between members, one function for the members performing one activity
        #Coordination action handOverSector : HandOverSector {
            doc /* Members hand a sector to a neighbour when one leaves to recharge. */
        }
        allocate handOverSector to system;
        trace handOverSector to SurveillanceDroneSwarm::OA::alphaHandOverSector;
        trace handOverSector to SurveillanceDroneSwarm::OA::bravoHandOverSector;
        #Coordination action rotateRecharge : RotateRecharge {
            doc /* Members agree the recharge rotation so no sector is emptied. */
        }
        allocate rotateRecharge to system;
        trace rotateRecharge to SurveillanceDroneSwarm::OA::alphaRotateRecharge;
        trace rotateRecharge to SurveillanceDroneSwarm::OA::bravoRotateRecharge;
        #Coordination action redistributeCoverage : RedistributeCoverage {
            doc /* Members re-spread over the area when one is lost or leaves. */
        }
        allocate redistributeCoverage to system;
        trace redistributeCoverage to SurveillanceDroneSwarm::OA::alphaRedistributeCoverage;
        trace redistributeCoverage to SurveillanceDroneSwarm::OA::bravoRedistributeCoverage;
        #Coordination action deconflictFlight : DeconflictFlight {
            doc /* Members announce flight intent so two drones do not share airspace. */
        }
        allocate deconflictFlight to system;
        trace deconflictFlight to SurveillanceDroneSwarm::OA::alphaDeconflictFlight;
        trace deconflictFlight to SurveillanceDroneSwarm::OA::bravoDeconflictFlight;
        #Coordination action relayReportsThroughNeighbour : RelayReportsThroughNeighbour {
            doc /* A member without a link to the operations centre relays reports through a neighbour. */
        }
        allocate relayReportsThroughNeighbour to system;
        trace relayReportsThroughNeighbour to SurveillanceDroneSwarm::OA::alphaRelayReports;
        trace relayReportsThroughNeighbour to SurveillanceDroneSwarm::OA::bravoRelayReports;
        #Coordination action correlateTracks : CorrelateTracks {
            doc /* Members agree tracks seen by different drones are one object. */
        }
        allocate correlateTracks to system;
        trace correlateTracks to SurveillanceDroneSwarm::OA::alphaCorrelateTracks;
        trace correlateTracks to SurveillanceDroneSwarm::OA::bravoCorrelateTracks;
        #Coordination action handOverTrack : HandOverTrack {
            doc /* A track is handed to the drone watching the sector the object moves into. */
        }
        allocate handOverTrack to system;
        trace handOverTrack to SurveillanceDroneSwarm::OA::alphaHandOverTrack;
        trace handOverTrack to SurveillanceDroneSwarm::OA::bravoHandOverTrack;
        #Coordination action admitMember : AdmitMember {
            doc /* A drone is checked, its classifier version included, before it takes part in coordination. */
        }
        allocate admitMember to system;
        trace admitMember to SurveillanceDroneSwarm::OA::alphaAdmitMember;
        trace admitMember to SurveillanceDroneSwarm::OA::bravoAdmitMember;

        // functions the members perform for the mission
        action detectAndClassifyObject : DetectAndClassifyObject {
            doc /* Detects moving objects in the sector and classifies them, or says Unknown. */
        }
        allocate detectAndClassifyObject to system;
        trace detectAndClassifyObject to SurveillanceDroneSwarm::OA::alphaDetect;
        trace detectAndClassifyObject to SurveillanceDroneSwarm::OA::bravoDetect;
        action deliverDetectionReport : DeliverDetectionReport {
            doc /* Delivers, holds while cut off, and clears on acknowledgement, each detection report. */
        }
        allocate deliverDetectionReport to system;
        trace deliverDetectionReport to SurveillanceDroneSwarm::OA::alphaDeliver;
        trace deliverDetectionReport to SurveillanceDroneSwarm::OA::bravoDeliver;
        action applySupervisoryDirectives : ApplySupervisoryDirectives {
            doc /* Takes up tasking, priorities and recall, and lands on recall. */
        }
        allocate applySupervisoryDirectives to system;
        trace applySupervisoryDirectives to SurveillanceDroneSwarm::OA::alphaDirectives;
        trace applySupervisoryDirectives to SurveillanceDroneSwarm::OA::bravoDirectives;
        action reportMemberStatus : ReportMemberStatus {
            doc /* Reports position, activity and degradations for the status picture. */
        }
        allocate reportMemberStatus to system;
        trace reportMemberStatus to SurveillanceDroneSwarm::OA::alphaStatus;
        trace reportMemberStatus to SurveillanceDroneSwarm::OA::bravoStatus;
        action reportTrackPicture : ReportTrackPicture {
            doc /* Reports the tracks held, one per object, stale ones marked. */
        }
        allocate reportTrackPicture to system;
        trace reportTrackPicture to SurveillanceDroneSwarm::OA::alphaTrackPicture;
        trace reportTrackPicture to SurveillanceDroneSwarm::OA::bravoTrackPicture;
        action returnToRecoveryPoint : ReturnToRecoveryPoint {
            doc /* Returns a cut-off drone to the recovery point on its own. */
        }
        allocate returnToRecoveryPoint to system;
        trace returnToRecoveryPoint to SurveillanceDroneSwarm::OA::alphaReturn;
        trace returnToRecoveryPoint to SurveillanceDroneSwarm::OA::bravoReturn;

        // functions the capabilities AlertTriage and DecisionRecordKeeping introduce; OA has no activity for them, so they trace to the capability and to the acknowledgement they serve
        action triageAlerts : TriageAlerts {
            doc /* Ranks reports most-likely-to-matter first and merges duplicates before they reach the operator. */
        }
        allocate triageAlerts to system;
        trace triageAlerts to SurveillanceDroneSwarm::OA::AlertTriage;
        trace triageAlerts to SurveillanceDroneSwarm::OA::acknowledgeReports;
        action keepDecisionRecords : KeepDecisionRecords {
            doc /* Keeps the decision record of every report: frames, classifier version, threshold in force and who acknowledged it. */
        }
        allocate keepDecisionRecords to system;
        trace keepDecisionRecords to SurveillanceDroneSwarm::OA::DecisionRecordKeeping;
        trace keepDecisionRecords to SurveillanceDroneSwarm::OA::acknowledgeReports;

        // interactions, carried over as functional exchanges
        flow handOverSectorAtoB of Common::SectorHandoverProposal from handOverSector.handoverOut to handOverSector.handoverIn;
        flow rotateRechargeAtoB of Common::RechargeRotationSlot from rotateRecharge.rotationOut to rotateRecharge.rotationIn;
        flow redistributeCoverageAtoB of Common::CoverageAssignment from redistributeCoverage.coverageOut to redistributeCoverage.coverageIn;
        flow deconflictFlightAtoB of Common::FlightIntent from deconflictFlight.intentOut to deconflictFlight.intentIn;
        flow relayReportsAtoB of Common::DetectionReport from relayReportsThroughNeighbour.relayOut to relayReportsThroughNeighbour.relayIn;
        flow correlateTracksAtoB of Common::Track from correlateTracks.correlationOut to correlateTracks.correlationIn;
        flow handOverTrackAtoB of Common::Track from handOverTrack.trackHandoverOut to handOverTrack.trackHandoverIn;
        flow admitMemberAtoB of Common::AdmissionExchange from admitMember.admissionOut to admitMember.admissionIn;
        flow detectionAlpha of Common::DetectionReport from detectAndClassifyObject.detectionOut to deliverDetectionReport.detectionIn;
        flow reportFromAlpha of Common::DetectionReport from deliverDetectionReport.reportOut to acknowledgeDetectionReport.reportIn;
        flow receiptToAlpha of Common::ReportReceipt from acknowledgeDetectionReport.receiptOut to deliverDetectionReport.receiptIn;
        flow statusFromAlpha of Common::MemberStatus from reportMemberStatus.statusOut to presentStatusPicture.statusIn;
        flow trackPictureFromAlpha of Common::Track from reportTrackPicture.trackPictureOut to mergeTracks.swarmTrackIn;
        flow cameraTracksToMerge of Common::Track from provideCameraTracks.cameraTrackOut to mergeTracks.cameraTrackIn;
        flow taskingToAlpha of Common::TaskingOrder from taskSurveillanceArea.taskingOut to applySupervisoryDirectives.taskingIn;
        flow prioritiesToAlpha of Common::PriorityDirective from commandSupervisoryPriorities.priorityOut to applySupervisoryDirectives.priorityIn;
        flow recallToAlpha of Common::RecallDirective from recallAndLand.recallOut to applySupervisoryDirectives.recallIn;
        flow reportsToTriage of Common::DetectionReport from deliverDetectionReport.reportOut to triageAlerts.reportsIn;
        flow alertsToJudgement of Common::TriagedAlerts from triageAlerts.alertsOut to acknowledgeDetectionReport.alertsIn;
        flow reportsToRecords of Common::DetectionReport from deliverDetectionReport.reportOut to keepDecisionRecords.reportIn;
        flow receiptsToRecords of Common::ReportReceipt from acknowledgeDetectionReport.receiptOut to keepDecisionRecords.receiptIn;

        // rules the system never breaks (CV-18), stated once and satisfied by the member whose machines carry them
        #Rule requirement RecallWins {
            doc /* Once a drone is recalled, it does not watch again until it has landed. */
            subject m : SwarmMember;
        }
        satisfy RecallWins by SwarmMember;
        #Rule requirement ReturnsWhenIsolated {
            doc /* From any situation a drone can be in, it can always get back to landed; an isolated drone included. */
            subject m : SwarmMember;
        }
        satisfy ReturnsWhenIsolated by SwarmMember;
        #Rule requirement GeofenceBreachEndsWatch {
            doc /* Once a drone is outside its cleared airspace, it does not watch until it has landed. */
            subject m : SwarmMember;
        }
        satisfy GeofenceBreachEndsWatch by SwarmMember;
        #Rule requirement QuarantinedStaysOut {
            doc /* Once a drone is quarantined, it takes no part in coordination until it has been readmitted. */
            subject m : SwarmMember;
        }
        satisfy QuarantinedStaysOut by SwarmMember;

        // hazards at the system boundary
        package Hazards {
            doc /* Hazards the system as a whole adds at its boundary, each stated once here and satisfied below by the function or component that mitigates it. */
            #Hazard requirement PositionDriftHazard {
                doc /* Without satellite positioning, a drone's position estimate drifts and its reports place objects in the wrong place. */
                subject m : SwarmMember;
            }
            #Hazard requirement MeshJammingHazard {
                doc /* Interference cuts the links between drones, and coordination stalls. */
                subject s : SurveillanceDroneSwarmSystem;
            }
            #Hazard requirement MisclassificationHazard {
                doc /* A detection is reported as the wrong class, or a forced class where Unknown was the truth. */
                subject s : SurveillanceDroneSwarmSystem;
            }
            #Hazard requirement SensingDegradedUnnoticedHazard {
                doc /* A sensor degrades and nobody knows the reports from it are unreliable. */
                subject m : SwarmMember;
            }
            #Hazard requirement StaleTrackHazard {
                doc /* A track is shown as current after nothing has seen the object for a while. */
                subject s : SurveillanceDroneSwarmSystem;
            }
            #Hazard requirement SpoofedMemberHazard {
                doc /* Something that is not one of the drones joins the mesh and takes part in coordination. */
                subject s : SurveillanceDroneSwarmSystem;
            }
            #Hazard requirement MixedClassifierVersionsHazard {
                doc /* Drones run different classifier versions and classify the same object differently. */
                subject s : SurveillanceDroneSwarmSystem;
            }
            #Hazard requirement OperatorOverloadHazard {
                doc /* More alerts reach the operator than they can judge, and they accept what is in front of them. */
                subject s : SurveillanceDroneSwarmSystem;
            }
        }
        satisfy SurveillanceDroneSwarm::SA::Hazards::PositionDriftHazard by SwarmMember;
        satisfy SurveillanceDroneSwarm::SA::Hazards::MeshJammingHazard by redistributeCoverage;
        satisfy SurveillanceDroneSwarm::SA::Hazards::MisclassificationHazard by detectAndClassifyObject;
        satisfy SurveillanceDroneSwarm::SA::Hazards::SensingDegradedUnnoticedHazard by reportMemberStatus;
        satisfy SurveillanceDroneSwarm::SA::Hazards::StaleTrackHazard by reportTrackPicture;
        satisfy SurveillanceDroneSwarm::SA::Hazards::SpoofedMemberHazard by admitMember;
        satisfy SurveillanceDroneSwarm::SA::Hazards::MixedClassifierVersionsHazard by admitMember;
        satisfy SurveillanceDroneSwarm::SA::Hazards::OperatorOverloadHazard by triageAlerts;

        // hazards stated at OA, satisfied here by path
        satisfy SurveillanceDroneSwarm::OA::Hazards::ManualCoordinationLagHazard by handOverSector;
        satisfy SurveillanceDroneSwarm::OA::Hazards::UnrecoveredDroneHazard by returnToRecoveryPoint;
        satisfy SurveillanceDroneSwarm::OA::Hazards::ReportLostInLinkGapHazard by deliverDetectionReport;
        satisfy SurveillanceDroneSwarm::OA::Hazards::WatchBeyondClearanceHazard by SwarmMember;
    }
    package LA {
        doc /* Logical architecture of the SurveillanceDroneSwarm. The system is decomposed into logical functions, the member definition of the twelve-drone population and the state machines every member and the fleet follow. Every logical function realises an SA function. Nothing physical is chosen: every function stays allocated to one placeholder component, mainComponent, and whether the coordination and command-and-control functions end up on the ground or on the members is the decision of the next step, which also places the counted fleet and its peer representatives. */

        // ---------------------------------------------------------------
        // Placeholder component
        // ---------------------------------------------------------------

        part def SurveillanceDroneSwarmLogical {
            doc /* Placeholder logical component that holds every logical function until the next step decomposes it into logical components in more than one way and compares the ways. It is not a design choice. */
        }


        // ---------------------------------------------------------------
        // Coordination functions between members (realise SA functions)
        // ---------------------------------------------------------------

        #Coordination action def HandOverSector :> SurveillanceDroneSwarm::SA::HandOverSector {
            doc /* Logical function: a member that leaves to recharge hands its sector to a neighbour and stays until the neighbour confirms, so the sector stays watched. Realises SA::HandOverSector. */
        }

        #Coordination action def RotateRecharge :> SurveillanceDroneSwarm::SA::RotateRecharge {
            doc /* Logical function: members agree who leaves to recharge and who takes the place, so the rotation never empties a sector. Realises SA::RotateRecharge. */
        }

        #Coordination action def RedistributeCoverage :> SurveillanceDroneSwarm::SA::RedistributeCoverage {
            doc /* Logical function: members re-spread over the area when one is lost or leaves. It works from the last agreed assignment when links are jammed and can be performed by any member, so no single holder is needed. Realises SA::RedistributeCoverage. */
        }

        #Coordination action def DeconflictFlight :> SurveillanceDroneSwarm::SA::DeconflictFlight {
            doc /* Logical function: members announce flight intent so that two drones do not occupy the same airspace. Realises SA::DeconflictFlight. */
        }

        #Coordination action def RelayReportsThroughNeighbour :> SurveillanceDroneSwarm::SA::RelayReportsThroughNeighbour {
            doc /* Logical function: a member that cannot reach the operations centre sends its reports through a neighbour that can, and keeps each report until it is handed over. Realises SA::RelayReportsThroughNeighbour. */
        }

        #Coordination action def CorrelateTracks :> SurveillanceDroneSwarm::SA::CorrelateTracks {
            doc /* Logical function: members agree that tracks seen by different drones are the same object, giving one track per object. Realises SA::CorrelateTracks. */
        }

        #Coordination action def HandOverTrack :> SurveillanceDroneSwarm::SA::HandOverTrack {
            doc /* Logical function: a track is handed to the drone that watches the sector the object moves into. Realises SA::HandOverTrack. */
        }

        #Coordination action def AdmitMember :> SurveillanceDroneSwarm::SA::AdmitMember {
            doc /* Logical function: a drone is checked before it takes part in coordination, including the classifier version it runs; one that fails is quarantined until readmitted. Realises SA::AdmitMember. */
        }

        // ---------------------------------------------------------------
        // Command and control functions (realise SA functions)
        // ---------------------------------------------------------------

        #C2 action def TaskSurveillanceArea :> SurveillanceDroneSwarm::SA::TaskSurveillanceArea {
            doc /* Logical function: the swarm is tasked with the area of interest, its sectors and the mission window. Realises SA::TaskSurveillanceArea. */
        }

        #C2 action def CommandSupervisoryPriorities :> SurveillanceDroneSwarm::SA::CommandSupervisoryPriorities {
            doc /* Logical function: priorities, a sector to look at more closely and the reporting threshold are given to the swarm. Realises SA::CommandSupervisoryPriorities. */
        }

        #C2 action def RecallAndLand :> SurveillanceDroneSwarm::SA::RecallAndLand {
            doc /* Logical function: an order to recall and land the whole swarm or one drone, issuable at any time. Realises SA::RecallAndLand. */
        }

        #C2 action def PresentStatusPicture :> SurveillanceDroneSwarm::SA::PresentStatusPicture {
            doc /* Logical function: shows where every drone is, what it is doing, how much of the area is under watch and what is degraded. Realises SA::PresentStatusPicture. */
        }

        #C2 action def AcknowledgeDetectionReport :> SurveillanceDroneSwarm::SA::AcknowledgeDetectionReport {
            doc /* Logical function: each detection report is confirmed at the operations centre so nothing is lost in a link gap. Realises SA::AcknowledgeDetectionReport. */
        }

        // ---------------------------------------------------------------
        // Sensing, reporting and record functions (realise SA functions)
        // ---------------------------------------------------------------

        action def DetectAndClassifyObject :> SurveillanceDroneSwarm::SA::DetectAndClassifyObject {
            doc /* Logical function: detects a moving object in the member's sector and classifies it, saying Unknown when confidence is short of the reporting threshold. Realises SA::DetectAndClassifyObject. */
        }

        action def DeliverDetectionReport :> SurveillanceDroneSwarm::SA::DeliverDetectionReport {
            doc /* Logical function: delivers a report with position and time to the operations centre, holds it while cut off and clears it only on acknowledgement. Realises SA::DeliverDetectionReport. */
        }

        action def ApplySupervisoryDirectives :> SurveillanceDroneSwarm::SA::ApplySupervisoryDirectives {
            doc /* Logical function: a drone takes up the tasking, priorities and recall given by the duty controller and lands on recall. Realises SA::ApplySupervisoryDirectives. */
        }

        action def ReportMemberStatus :> SurveillanceDroneSwarm::SA::ReportMemberStatus {
            doc /* Logical function: a drone reports its position, activity and degradations, sensing degradation included, for the status picture. Realises SA::ReportMemberStatus. */
        }

        action def ReportTrackPicture :> SurveillanceDroneSwarm::SA::ReportTrackPicture {
            doc /* Logical function: reports the tracks held, one per object, marking a track stale once nothing has seen the object for 120 seconds. Realises SA::ReportTrackPicture. */
        }

        action def ReturnToRecoveryPoint :> SurveillanceDroneSwarm::SA::ReturnToRecoveryPoint {
            doc /* Logical function: a drone that has lost contact with the swarm returns to the recovery point on its own. Realises SA::ReturnToRecoveryPoint. */
        }

        action def TriageAlerts :> SurveillanceDroneSwarm::SA::TriageAlerts {
            doc /* Logical function: ranks reports so that what is most likely to matter reaches the operator first, merges duplicates and keeps the alert rate inside what one operator can judge. Realises SA::TriageAlerts. */
        }

        action def KeepDecisionRecords :> SurveillanceDroneSwarm::SA::KeepDecisionRecords {
            doc /* Logical function: keeps for every report the frames it came from, the classifier version, the reporting threshold in force and who acknowledged it. Realises SA::KeepDecisionRecords. */
        }

        // ---------------------------------------------------------------
        // Function usages, all allocated to the placeholder
        // ---------------------------------------------------------------

        action handOverSector : HandOverSector {
            doc /* Usage of the sector hand-over function; allocated to the placeholder until the next step places it. */
        }
        action rotateRecharge : RotateRecharge {
            doc /* Usage of the recharge rotation function; allocated to the placeholder until the next step places it. */
        }
        action redistributeCoverage : RedistributeCoverage {
            doc /* Usage of the coverage redistribution function; allocated to the placeholder until the next step places it. */
        }
        action deconflictFlight : DeconflictFlight {
            doc /* Usage of the flight deconfliction function; allocated to the placeholder until the next step places it. */
        }
        action relayReportsThroughNeighbour : RelayReportsThroughNeighbour {
            doc /* Usage of the report relay function; allocated to the placeholder until the next step places it. */
        }
        action correlateTracks : CorrelateTracks {
            doc /* Usage of the track correlation function; allocated to the placeholder until the next step places it. */
        }
        action handOverTrack : HandOverTrack {
            doc /* Usage of the track hand-over function; allocated to the placeholder until the next step places it. */
        }
        action admitMember : AdmitMember {
            doc /* Usage of the member admission function; allocated to the placeholder until the next step places it. */
        }
        action taskSurveillanceArea : TaskSurveillanceArea {
            doc /* Usage of the tasking function; allocated to the placeholder until the next step places it. */
        }
        action commandSupervisoryPriorities : CommandSupervisoryPriorities {
            doc /* Usage of the supervisory command function; allocated to the placeholder until the next step places it. */
        }
        action recallAndLand : RecallAndLand {
            doc /* Usage of the recall function; allocated to the placeholder until the next step places it. */
        }
        action presentStatusPicture : PresentStatusPicture {
            doc /* Usage of the status presentation function; allocated to the placeholder until the next step places it. */
        }
        action acknowledgeDetectionReport : AcknowledgeDetectionReport {
            doc /* Usage of the report acknowledgement function; allocated to the placeholder until the next step places it. */
        }
        action detectAndClassifyObject : DetectAndClassifyObject {
            doc /* Usage of the detection and classification function; allocated to the placeholder until the next step places it. */
        }
        action deliverDetectionReport : DeliverDetectionReport {
            doc /* Usage of the report delivery function; allocated to the placeholder until the next step places it. */
        }
        action applySupervisoryDirectives : ApplySupervisoryDirectives {
            doc /* Usage of the directive uptake function; allocated to the placeholder until the next step places it. */
        }
        action reportMemberStatus : ReportMemberStatus {
            doc /* Usage of the status reporting function; allocated to the placeholder until the next step places it. */
        }
        action reportTrackPicture : ReportTrackPicture {
            doc /* Usage of the track reporting function; allocated to the placeholder until the next step places it. */
        }
        action returnToRecoveryPoint : ReturnToRecoveryPoint {
            doc /* Usage of the return-to-recovery function; allocated to the placeholder until the next step places it. */
        }
        action triageAlerts : TriageAlerts {
            doc /* Usage of the alert triage function; allocated to the placeholder until the next step places it. */
        }
        action keepDecisionRecords : KeepDecisionRecords {
            doc /* Usage of the decision record function; allocated to the placeholder until the next step places it. */
        }

        // ---------------------------------------------------------------
        // Member definition: the replicable element of the population
        // ---------------------------------------------------------------


        #Configuration state def FleetConfiguration {
            doc /* Condition of the mesh between drones, taken over the whole twelve-drone population. */

            initial start;
            transition start -> MeshIntact;

            state MeshIntact {
                doc /* The links between drones are all usable. */
            }
            state MeshDegraded {
                doc /* A share of the links between drones is jammed and the swarm coordinates over what is left. */
            }

            transition MeshIntact -> MeshDegraded;
            transition MeshDegraded -> MeshIntact;
        }

        // ---------------------------------------------------------------
        // Worst-case estimates of the measures of effectiveness (CV-17)
        // These are the worst of the ground-centred and member-centred
        // allocations, because that choice is not taken at this layer.
        // ---------------------------------------------------------------

        #Estimate attribute areaUnderWatchFraction :> Common::areaUnderWatchFraction = 0.78 {
            doc /* Worst case 0.78. Basis: twelve drones, 40 min endurance, 20 min battery swap gives at most 40/60 airborne. Transit of up to 4 km each way at 18 m/s is about 7.4 min of the 40, leaving about 32.6 min of watching per 60 min cycle, so about 6.5 drones watch at a time. 6.5 x 3.0 km2 is about 19.6 km2 of 25 km2. Target 0.9 is not met by this arithmetic. */
        }

        #Estimate attribute coverageLossAfterMemberLossFraction :> Common::coverageLossAfterMemberLossFraction = 0.16 {
            doc /* Worst case 0.16. Basis: one watching drone holds about 3.0 km2 of the roughly 19.6 km2 under watch, about 0.15, before any re-spread; the same for either allocation because the loss precedes the redistribution. */
        }

        #Estimate attribute coverageUnderMeshJammingFraction :> Common::coverageUnderMeshJammingFraction = 0.58 {
            doc /* Worst case 0.58. Basis: with half the links jammed, at worst half of the hand-overs between neighbours fail and leave a sector empty for part of a swap turnaround, so the 0.78 baseline is cut by about a quarter. The member-centred allocation is the worse case. Placeholder target 0.75 is not met. */
        }

        #Estimate attribute reportAgeAtOperationsCentreSeconds :> Common::reportAgeAtOperationsCentreSeconds = 40 {
            doc /* Worst case 40 s with the link up. Basis: about 5 s to classify, up to three relay hops of about 2 s each through neighbours, about 5 s on the ground link and about 20 s for triage queuing. Relay hop count is the driver; units are seconds. */
        }

        #Estimate attribute positionErrorWithoutSatelliteMetres :> Common::positionErrorWithoutSatelliteMetres = 80 {
            doc /* Worst case 80 m after ten minutes without satellite positioning. Basis: about 10.8 km flown in ten minutes at 18 m/s; camera matching against stored maps bounds the drift, but over featureless ground the bound is loose. Placeholder target 50 m is not met. Units are metres. */
        }

        #Estimate attribute reportHoldWhileCutOffMinutes :> Common::reportHoldWhileCutOffMinutes = 40 {
            doc /* Worst case 40 min. Basis: the hold is bounded by one 40 min sortie, after which the drone lands and its held reports survive the battery swap on board. Units are minutes. */
        }

        #Estimate attribute missedDetectionFraction :> Common::missedDetectionFraction = 0.12 {
            doc /* Worst case 0.12. Basis: poor lighting, weather and deliberately misleading paint or shapes reduce what the sensors can tell apart. Placeholder target 0.10 is not met. */
        }

        #Estimate attribute falseAlarmsPerHour :> Common::falseAlarmsPerHour = 3 {
            doc /* Worst case 3 per hour reaching the operator. Basis: the reporting threshold is held at the level that gives the missed-detection figure above; a higher threshold trades false alarms for missed detections. Units are 1/h. */
        }

        #Estimate attribute alertsReachingOperatorPerHour :> Common::alertsReachingOperatorPerHour = 24 {
            doc /* Worst case 24 per hour after triage. Basis: duplicates from several drones are merged, but with all twelve drones flying and busy sectors the remaining alerts still exceed 20. At 30 s per alert the operator could judge up to 120 per hour. Units are 1/h. */
        }

        #Estimate attribute acknowledgedReportsThatMatterFraction :> Common::acknowledgedReportsThatMatterFraction = 0.7 {
            doc /* Worst case 0.7. Basis: triage ranks by classification confidence only at this layer, without operator feedback on what mattered. */
        }

        #Estimate attribute onboardClassificationCostUsdPerMember :> Common::onboardClassificationCostUsdPerMember = 350 {
            doc /* Worst case 350 USD per member. Basis: the case in which the whole classification runs on the drone, as in the member-centred allocation. Placeholder target 300 USD is not met. Units are USD. */
        }

        #Estimate attribute unattendedWatchDurationHours :> Common::unattendedWatchDurationHours = 0.7 {
            doc /* Worst case 0.7 h. Basis: batteries are swapped by ground crew, so without people the watch ends when the first 40 min sortie is spent. The 12 h figure is a target set here, not the customer's. Units are hours. */
        }

        // ---------------------------------------------------------------
        // Hazards this layer adds (a split of responsibilities)
        // ---------------------------------------------------------------

        package Hazards {
            doc /* Hazards the logical split of responsibilities adds, each stated once here and satisfied below by the function that mitigates it. */

            #Hazard requirement CoordinationConcentrationHazard {
                subject s : SurveillanceDroneSwarmLogical;
                doc /* About the coordination and command-and-control functions of the logical system: if they end up on one component, a ground station or a single member, the loss of that component stalls sector hand-over, rotation and redistribution for the whole swarm. */
            }

            #Hazard requirement SectorHandOffLostHazard {
                subject m : SwarmMember;
                doc /* About handOverSector between members: a member leaves to recharge before the neighbour has taken the sector, because the hand-over message was jammed or the neighbour was lost, and the sector is unwatched. */
            }

            #Hazard requirement RelayedReportDroppedHazard {
                subject m : SwarmMember;
                doc /* About relayReportsThroughNeighbour: a report handed to a neighbour for relay is dropped on the way, and the originating member believes it has been delivered. */
            }

            #Hazard requirement TrackHandOverGapHazard {
                subject m : SwarmMember;
                doc /* About handOverTrack and correlateTracks: a track is handed to a drone that does not take it up, or two drones both keep it, so the object is lost or shown twice. */
            }
    doc /* Hazards this split of responsibilities adds: what a ground-centred decision point and its hand-offs to the drones introduce. */
    #Hazard requirement GroundCoordinatorSinglePointHazard {
        subject c : GroundSwarmCoordinator;
        doc /* All handover, rotation and redistribution decisions are taken in one ground component; if it or its path to the drones is lost, no sector is handed over and no rotation is planned, and coverage decays as drones reach their endurance. */
    }
    #Hazard requirement DirectiveHandOffLostHazard {
        subject c : GroundSwarmCoordinator;
        doc /* A directive from the ground to a drone is lost or arrives late, so a sector is left with nobody assigned while the drone it was taken from has already left. */
    }
    #Hazard requirement ReportRelayLossHazard {
        subject m : SwarmMember;
        doc /* A report relayed through a neighbour is lost when the neighbour is lost, jammed or quarantined before the report reaches the ground. */
    }
        }
        satisfy SurveillanceDroneSwarm::SA::Hazards::MeshJammingHazard by relayReportsThroughNeighbour;
        satisfy SurveillanceDroneSwarm::SA::Hazards::MisclassificationHazard by detectAndClassifyObject;
        satisfy SurveillanceDroneSwarm::SA::Hazards::SensingDegradedUnnoticedHazard by reportMemberStatus;
        satisfy SurveillanceDroneSwarm::SA::Hazards::StaleTrackHazard by reportTrackPicture;
        satisfy SurveillanceDroneSwarm::SA::Hazards::SpoofedMemberHazard by admitMember;
        satisfy SurveillanceDroneSwarm::SA::Hazards::MixedClassifierVersionsHazard by admitMember;
        satisfy SurveillanceDroneSwarm::SA::Hazards::OperatorOverloadHazard by triageAlerts;

        satisfy Hazards::CoordinationConcentrationHazard by redistributeCoverage;
        satisfy Hazards::SectorHandOffLostHazard by rotateRecharge;
        satisfy Hazards::RelayedReportDroppedHazard by deliverDetectionReport;
        satisfy Hazards::TrackHandOverGapHazard by correlateTracks;
            // carried from the layer above; restored by the orchestrator
            allocate taskSurveillanceArea to dutyController;
            trace taskSurveillanceArea to SurveillanceDroneSwarm::SA::taskSurveillanceArea;
            allocate commandSupervisoryPriorities to dutyController;
            trace commandSupervisoryPriorities to SurveillanceDroneSwarm::SA::commandSupervisoryPriorities;
            allocate recallAndLand to dutyController;
            trace recallAndLand to SurveillanceDroneSwarm::SA::recallAndLand;
            allocate presentStatusPicture to groundStation;
            trace presentStatusPicture to SurveillanceDroneSwarm::SA::presentStatusPicture;
            allocate acknowledgeDetectionReport to operationsCentreAnalyst;
            trace acknowledgeDetectionReport to SurveillanceDroneSwarm::SA::acknowledgeDetectionReport;
            trace handOverSector to SurveillanceDroneSwarm::SA::handOverSector;
            trace rotateRecharge to SurveillanceDroneSwarm::SA::rotateRecharge;
            trace redistributeCoverage to SurveillanceDroneSwarm::SA::redistributeCoverage;
            trace deconflictFlight to SurveillanceDroneSwarm::SA::deconflictFlight;
            trace relayReportsThroughNeighbour to SurveillanceDroneSwarm::SA::relayReportsThroughNeighbour;
            trace correlateTracks to SurveillanceDroneSwarm::SA::correlateTracks;
            trace handOverTrack to SurveillanceDroneSwarm::SA::handOverTrack;
            trace admitMember to SurveillanceDroneSwarm::SA::admitMember;
            trace detectAndClassifyObject to SurveillanceDroneSwarm::SA::detectAndClassifyObject;
            trace deliverDetectionReport to SurveillanceDroneSwarm::SA::deliverDetectionReport;
            trace applySupervisoryDirectives to SurveillanceDroneSwarm::SA::applySupervisoryDirectives;
            trace reportMemberStatus to SurveillanceDroneSwarm::SA::reportMemberStatus;
            trace reportTrackPicture to SurveillanceDroneSwarm::SA::reportTrackPicture;
            trace returnToRecoveryPoint to SurveillanceDroneSwarm::SA::returnToRecoveryPoint;
            trace triageAlerts to SurveillanceDroneSwarm::SA::triageAlerts;
            trace keepDecisionRecords to SurveillanceDroneSwarm::SA::keepDecisionRecords;

        // ── architecture, alternative 1 ──
        doc /* LA, architecture alternative 1: ground-centred command and control. The ground station decides every coordination that needs the whole picture: sector handover, recharge rotation, coverage redistribution, deconfliction, track correlation and admission. The twelve identical drones execute those directives, relay reports through neighbours over the mesh, and fall back to a stand-alone safe behaviour when the ground path is lost. Nothing physical is chosen here: how the ground path is carried is left to PA. */

        attribute fleetCount = 12.0 { doc /* The twelve drones the brief fixes, restated here because a constraint body cannot reach Common. */ }
        attribute sortieMinutes = 40.0 { doc /* Flight endurance of one drone, transit included, as the brief fixes it. */ }
        attribute turnaroundMinutes = 20.0 { doc /* Battery-swap turnaround on the ground, as the brief fixes it. */ }
        attribute transitMinutesEachWay = 3.0 { doc /* Design assumption, not fixed by the brief: the recharge point sits near the middle of the roughly 5 km by 5 km area, so a leg is about 2.7 km, which is 3 minutes at 18 m/s. It is spent from the 40 minutes of endurance. */ }
        attribute footprintSquareKm = 3.0 { doc /* Area one drone keeps under watch at watch altitude, as the brief fixes it. */ }
        attribute taskedAreaSquareKm = 25.0 { doc /* Largest tasked area, as the brief fixes it. */ }
        attribute jammedLinkFraction = 0.5 { doc /* Share of links between drones jammed in the jamming test condition, as the brief fixes it. */ }
        attribute watchingMembers = fleetCount * (sortieMinutes - 2.0 * transitMinutesEachWay) / (sortieMinutes + turnaroundMinutes) { doc /* Average number of drones on station at any moment: each drone watches for its endurance minus the two transit legs out of every sortie plus turnaround cycle of 60 minutes. Each drone covers 3.0 km2 against a fair share of 25/12 km2, so the watched share below is derived from the per-member footprint and is not bounded by the airborne share of the fleet. */ }
        part def GroundSwarmCoordinator {
            doc /* Ground component that takes every decision needing the whole picture: it decides sector handover, recharge rotation, coverage redistribution and flight deconfliction, correlates the tracks of all drones into one track per object, and admits or refuses members by identity and classifier version. It is the deciding point of this architecture and therefore its single point of failure. */
            in port taskingIn : Common::TaskingOrder { doc /* The tasked area, sectors and mission window from the console. */ }
            in port priorityIn : Common::PriorityDirective { doc /* Priorities and the sector to look at more closely, used when redistributing coverage. */ }
            in port statusIn : Common::MemberStatus { doc /* Position, activity, battery and degradations of every drone. */ }
            in port trackIn : Common::Track { doc /* Tracks held by each drone, to be correlated. */ }
            in port admissionIn : Common::AdmissionRequest { doc /* Identity and classifier version offered by a drone asking to take part. */ }
            in port directiveAckIn : Common::DirectiveAck { doc /* Acknowledgement of each directive by the drone it went to. */ }
            out port directiveOut : Common::CoordinationDirective { doc /* Sector assignment, handover, rotation, redistribution, deconfliction and admission verdict for the drones. */ }
            out port correlatedTrackOut : Common::Track { doc /* One correlated track per object, with stale ones marked, for triage. */ }

            #Mode state def SwarmCoordinatorModes {
                doc /* How far the coordinator can reach the drones: all of them, part of them because of jamming, or none. */
                initial start;
                transition start -> FleetReachable;
                state FleetReachable { doc /* Every drone answers; directives reach all of them. */ }
                state FleetPartiallyReachable { doc /* A share of the paths to drones is jammed; directives go over the surviving paths and through relaying neighbours. */ }
                state FleetUnreachable { doc /* No drone answers; each drone acts on its last assignment and its stand-alone rules. */ }
                transition jamPaths first FleetReachable accept jamNotice : Common::MemberSituationNotice then FleetPartiallyReachable;
                transition restorePaths first FleetPartiallyReachable accept restoreNotice : Common::MemberSituationNotice then FleetReachable;
                transition losePaths first FleetPartiallyReachable accept lossNotice : Common::MemberSituationNotice then FleetUnreachable;
                transition regainPaths first FleetUnreachable accept regainNotice : Common::MemberSituationNotice then FleetPartiallyReachable;
            }

            #State state def SwarmCoordinatorStates {
                doc /* What the coordinator is doing about the tasking: waiting for it, planning sectors, or supervising the plan. */
                initial start;
                transition start -> AwaitingTasking;
                state AwaitingTasking { doc /* No tasking yet; nothing to coordinate. */ }
                state Planning { doc /* Dividing the tasked area into sectors and assigning drones to them. */ }
                state Supervising { doc /* Directing handovers, rotation, redistribution and deconfliction against the plan. */ }
                transition receiveTasking first AwaitingTasking accept tasking : Common::TaskingOrder then Planning;
                transition planReady first Planning accept planned : Common::CoordinationDirective then Supervising;
                transition retask first Supervising accept retasking : Common::TaskingOrder then Planning;
            }
        }
        part def GroundOperatorConsole {
            doc /* Ground component through which the one operator tasks, commands, recalls and watches the swarm, and through which each detection report is acknowledged. It carries every command-and-control function. */
            out port taskingOut : Common::TaskingOrder { doc /* Tasking issued to the coordinator and the drones. */ }
            out port priorityOut : Common::PriorityDirective { doc /* Priorities and the reporting threshold issued to the coordinator, the drones and the record store. */ }
            out port recallOut : Common::RecallDirective { doc /* Recall of the whole swarm or of one drone, issuable at any time. */ }
            in port statusIn : Common::MemberStatus { doc /* Status of every drone, for the status picture. */ }
            in port alertsIn : Common::TriagedAlerts { doc /* Triaged alerts the operator judges. */ }
            in port recordsIn : Common::DecisionRecords { doc /* Decision records shown alongside the alerts. */ }
            out port receiptOut : Common::ReportReceipt { doc /* Acknowledgement of a detection report; the drones clear it and the record store notes who acknowledged. */ }
        }
        part def GroundAlertTriage {
            doc /* Ground component that ranks reports so the ones most likely to matter reach the operator first and merges duplicates using the correlated tracks, keeping the alert rate inside what one operator can judge. */
            in port reportsIn : Common::DetectionReport { doc /* Detection reports from all drones. */ }
            in port trackIn : Common::Track { doc /* Correlated tracks, used to recognise duplicates of one object. */ }
            out port alertsOut : Common::TriagedAlerts { doc /* Ranked, de-duplicated alerts for the console. */ }
        }
        part def GroundDecisionRecordStore {
            doc /* Ground component that keeps, for every report, the frames it came from, the classifier version, the reporting threshold in force and who acknowledged it. */
            in port reportIn : Common::DetectionReport { doc /* Each detection report with its provenance. */ }
            in port thresholdIn : Common::PriorityDirective { doc /* The reporting threshold in force when the report was made. */ }
            in port receiptIn : Common::ReportReceipt { doc /* Who acknowledged the report. */ }
            out port recordsOut : Common::DecisionRecords { doc /* The decision records, shown at the console. */ }
        }
        #Member part def SwarmMember {
            doc /* One of the twelve identical drones. It detects and classifies in its sector, holds and delivers its reports, relays neighbours' reports and hands tracks over across the mesh, and carries out the directives the ground coordinator sends. Its own state machines carry the safety rules, so it lands, recovers or stays out of coordination without waiting for the ground. */
            out port meshOut : Common::MeshPort { doc /* Traffic to a neighbour over the mesh: relayed reports and track handover. */ }
            in port meshIn : ~Common::MeshPort { doc /* Traffic from a neighbour over the mesh. */ }
            in port directiveIn : Common::CoordinationDirective { doc /* Directive from the ground coordinator. */ }
            out port directiveAckOut : Common::DirectiveAck { doc /* Acknowledgement of each directive, so a lost hand-off is noticed. */ }
            out port admissionOut : Common::AdmissionRequest { doc /* Identity and classifier version offered for admission. */ }
            out port statusOut : Common::MemberStatus { doc /* Position, activity and degradations, sensing degradation included. */ }
            out port trackOut : Common::Track { doc /* Tracks held by this drone, stale ones marked. */ }
            out port reportOut : Common::DetectionReport { doc /* Detection reports, held while cut off. */ }
            in port receiptIn : Common::ReportReceipt { doc /* Acknowledgement that lets the drone clear a held report. */ }
            in port taskingIn : Common::TaskingOrder { doc /* Tasking and mission window. */ }
            in port priorityIn : Common::PriorityDirective { doc /* Priorities and the reporting threshold in force. */ }
            in port recallIn : Common::RecallDirective { doc /* Recall order, issuable at any time. */ }

            #Mode state def SwarmMemberModes {
                doc /* Operating condition of one drone: nominal, without satellite positioning, sensors not trustworthy, cut off from the other drones, or failed admission and readmitted. Carries the rule QuarantinedStaysOut. */
                @SysproseVerification::PropertyPattern {
                    doc /* QuarantinedStaysOut: once a drone is quarantined, it takes no part in coordination until it has been readmitted. */
                    attribute pattern = "absence";
                    attribute scope = "between";
                    attribute q = "state Quarantined";
                    attribute r = "state Readmitted";
                    attribute p = "state Nominal";
                }
                initial start;
                transition start -> Nominal;
                state Nominal { doc /* The drone has positioning, trusted sensors, contact with the swarm and admission, and takes part in coordination. */ }
                state NavigationDegraded { doc /* The drone has no satellite positioning and navigates by what its camera sees against stored maps. */ }
                state SensingDegraded { doc /* The drone's sensors cannot be trusted as they are, and what it reports from them is marked accordingly. */ }
                state Isolated { doc /* The drone is cut off from the other drones and from the ground coordinator; it coordinates with none of them and acts on its last assignment. */ }
                state Quarantined { doc /* The drone has failed admission at the ground coordinator and takes no part in coordination until it has been readmitted. */ }
                state Readmitted { doc /* The drone has passed the readmission check and is about to take part in coordination again. */ }
                transition losePositioning first Nominal accept positioningLost : Common::MemberSituationNotice then NavigationDegraded;
                transition regainPositioning first NavigationDegraded accept positioningBack : Common::MemberSituationNotice then Nominal;
                transition degradeSensing first Nominal accept sensingBad : Common::MemberSituationNotice then SensingDegraded;
                transition restoreSensing first SensingDegraded accept sensingGood : Common::MemberSituationNotice then Nominal;
                transition loseContact first Nominal accept contactLost : Common::MemberSituationNotice then Isolated;
                transition regainContact first Isolated accept contactBack : Common::MemberSituationNotice then Nominal;
                transition failAdmission first Nominal accept refusal : Common::CoordinationDirective then Quarantined;
                transition readmit first Quarantined accept readmission : Common::CoordinationDirective then Readmitted;
                transition Readmitted -> Nominal;
            }

            #State state def SwarmMemberStates {
                doc /* Where one drone is in its sortie: on the ground, flying out, watching, flying back, recalled, outside its cleared airspace, or returning to the recovery point on its own. Carries the rules RecallWins, GeofenceBreachEndsWatch and ReturnsWhenIsolated. */
                @SysproseVerification::PropertyPattern {
                    doc /* RecallWins: once a drone is recalled, it does not watch again until it has landed. */
                    attribute pattern = "absence";
                    attribute scope = "between";
                    attribute q = "state Recalled";
                    attribute r = "state Landed";
                    attribute p = "state Watching";
                }
                @SysproseVerification::PropertyPattern {
                    doc /* GeofenceBreachEndsWatch: once a drone is outside its cleared airspace, it does not watch until it has landed. */
                    attribute pattern = "absence";
                    attribute scope = "between";
                    attribute q = "state OutsideClearance";
                    attribute r = "state Landed";
                    attribute p = "state Watching";
                }
                @SysproseVerification::PropertyPattern {
                    doc /* ReturnsWhenIsolated: from any situation a drone can be in, it can always get back to landed; an isolated drone included. */
                    attribute pattern = "recovery";
                    attribute scope = "globally";
                    attribute p = "state Landed";
                }
                initial start;
                transition start -> Landed;
                state Landed { doc /* On the ground, battery being swapped or waiting for a launch directive. */ }
                state Transiting { doc /* Flying from the recharge point to the sector the coordinator assigned. */ }
                state Watching { doc /* Holding watch over its sector. */ }
                state Returning { doc /* Flying back to the recharge point to swap the battery, or to land when the wind is above moderate. */ }
                state Recalled { doc /* Recalled by order and on its way down; it does not watch until landed. */ }
                state Recovering { doc /* Cut off from the swarm and the ground coordinator, returning to the recovery point on its own. */ }
                state OutsideClearance { doc /* Outside the cleared airspace or the clearance withdrawn: on its way down, and it does not watch until landed. */ }
                transition launch first Landed accept launchDirective : Common::CoordinationDirective then Transiting;
                transition Transiting -> Watching;
                transition endWatch first Watching accept releaseDirective : Common::CoordinationDirective then Returning;
                transition Returning -> Landed;
                transition recallWhileTransiting first Transiting accept recallOrderA : Common::RecallDirective then Recalled;
                transition recallWhileWatching first Watching accept recallOrderB : Common::RecallDirective then Recalled;
                transition Recalled -> Landed;
                transition loseSwarmContact first Watching accept contactNoticeA : Common::MemberSituationNotice then Recovering;
                transition loseContactInTransit first Transiting accept contactNoticeB : Common::MemberSituationNotice then Recovering;
                transition Recovering -> Landed;
                transition leaveClearanceWhileWatching first Watching accept clearanceNoticeA : Common::AirspaceClearance then OutsideClearance;
                transition leaveClearanceInTransit first Transiting accept clearanceNoticeB : Common::AirspaceClearance then OutsideClearance;
                transition OutsideClearance -> Landed;
                transition windLimit first Watching accept windNotice : Common::MemberSituationNotice then Returning;
            }
        }
        part groundCoordinator : GroundSwarmCoordinator { doc /* The ground coordinator: the one place where sector, rotation, redistribution, deconfliction, correlation and admission are decided. */ }
        part operatorConsole : GroundOperatorConsole { doc /* The console of the one operator; command and control sit here. */ }
        part groundTriage : GroundAlertTriage { doc /* Alert triage in front of the operator. */ }
        part groundRecordStore : GroundDecisionRecordStore { doc /* Decision records of every report. */ }
        part fleet : SwarmMember [12] { doc /* The twelve identical drones. */ }
        part memberA : SwarmMember { doc /* First representative of the population, one end of the peer exchange over the mesh. */ }
        part memberB : SwarmMember { doc /* Second representative of the population, the other end of the peer exchange over the mesh. */ }
        interface peerLink : Common::MeshInterface connect memberA.meshOut to memberB.meshIn { doc /* Peer exchange from one drone to a neighbour over the mesh: relayed reports and track handover. */ }
        interface peerLinkBack : Common::MeshInterface connect memberB.meshOut to memberA.meshIn { doc /* The same exchange in the other direction. */ }
        connection taskingToFleet connect operatorConsole.taskingOut to fleet.taskingIn { doc /* Tasking reaches every drone. */ }
        connection taskingToCoordinator connect operatorConsole.taskingOut to groundCoordinator.taskingIn { doc /* Tasking reaches the coordinator, which plans sectors from it. */ }
        connection priorityToFleet connect operatorConsole.priorityOut to fleet.priorityIn { doc /* Priorities and the reporting threshold reach every drone. */ }
        connection priorityToCoordinator connect operatorConsole.priorityOut to groundCoordinator.priorityIn { doc /* Priorities reach the coordinator for redistribution. */ }
        connection priorityToRecordStore connect operatorConsole.priorityOut to groundRecordStore.thresholdIn { doc /* The reporting threshold in force is kept for the decision records. */ }
        connection recallToFleet connect operatorConsole.recallOut to fleet.recallIn { doc /* Recall goes straight to the drones, not through the coordinator, so it stays effective when the coordinator is lost. */ }
        connection directivesToFleet connect groundCoordinator.directiveOut to fleet.directiveIn { doc /* Coordination directives from the ground to the drones. */ }
        connection directiveAcks connect fleet.directiveAckOut to groundCoordinator.directiveAckIn { doc /* Drones acknowledge each directive. */ }
        connection admissionRequests connect fleet.admissionOut to groundCoordinator.admissionIn { doc /* Drones offer identity and classifier version for admission. */ }
        connection statusToCoordinator connect fleet.statusOut to groundCoordinator.statusIn { doc /* Drone status feeds the coordinator's decisions. */ }
        connection statusToConsole connect fleet.statusOut to operatorConsole.statusIn { doc /* Drone status feeds the status picture. */ }
        connection tracksToCoordinator connect fleet.trackOut to groundCoordinator.trackIn { doc /* Tracks from all drones go to the coordinator for correlation. */ }
        connection correlatedTracksToTriage connect groundCoordinator.correlatedTrackOut to groundTriage.trackIn { doc /* Correlated tracks let triage merge duplicates. */ }
        connection reportsToTriage connect fleet.reportOut to groundTriage.reportsIn { doc /* Detection reports go to triage. */ }
        connection reportsToRecords connect fleet.reportOut to groundRecordStore.reportIn { doc /* Detection reports go to the record store. */ }
        connection alertsToConsole connect groundTriage.alertsOut to operatorConsole.alertsIn { doc /* Triaged alerts go to the operator. */ }
        connection receiptsToFleet connect operatorConsole.receiptOut to fleet.receiptIn { doc /* Acknowledgement lets drones clear held reports. */ }
        connection receiptsToRecords connect operatorConsole.receiptOut to groundRecordStore.receiptIn { doc /* Acknowledgement records who acknowledged the report. */ }
        connection recordsToConsole connect groundRecordStore.recordsOut to operatorConsole.recordsIn { doc /* Decision records are available at the console. */ }
        allocate handOverSector to groundCoordinator;
        allocate rotateRecharge to groundCoordinator;
        allocate redistributeCoverage to groundCoordinator;
        allocate deconflictFlight to groundCoordinator;
        allocate correlateTracks to groundCoordinator;
        allocate admitMember to groundCoordinator;
        allocate relayReportsThroughNeighbour to fleet;
        allocate handOverTrack to fleet;
        allocate detectAndClassifyObject to fleet;
        allocate deliverDetectionReport to fleet;
        allocate applySupervisoryDirectives to fleet;
        allocate reportMemberStatus to fleet;
        allocate reportTrackPicture to fleet;
        allocate returnToRecoveryPoint to fleet;
        allocate taskSurveillanceArea to operatorConsole;
        allocate commandSupervisoryPriorities to operatorConsole;
        allocate recallAndLand to operatorConsole;
        allocate presentStatusPicture to operatorConsole;
        allocate acknowledgeDetectionReport to operatorConsole;
        allocate triageAlerts to groundTriage;
        allocate keepDecisionRecords to groundRecordStore;
        satisfy SurveillanceDroneSwarm::SA::Hazards::PositionDriftHazard by fleet;
        satisfy SurveillanceDroneSwarm::SA::Hazards::MeshJammingHazard by fleet;
        satisfy SurveillanceDroneSwarm::SA::Hazards::MisclassificationHazard by fleet;
        satisfy SurveillanceDroneSwarm::SA::Hazards::SensingDegradedUnnoticedHazard by fleet;
        satisfy SurveillanceDroneSwarm::SA::Hazards::StaleTrackHazard by groundCoordinator;
        satisfy SurveillanceDroneSwarm::SA::Hazards::SpoofedMemberHazard by groundCoordinator;
        satisfy SurveillanceDroneSwarm::SA::Hazards::MixedClassifierVersionsHazard by groundCoordinator;
        satisfy SurveillanceDroneSwarm::SA::Hazards::OperatorOverloadHazard by groundTriage;
        satisfy Hazards::GroundCoordinatorSinglePointHazard by fleet;
        satisfy Hazards::DirectiveHandOffLostHazard by groundCoordinator;
        satisfy Hazards::ReportRelayLossHazard by fleet;
        satisfy LA::Hazards::CoordinationConcentrationHazard by fleet;
        satisfy LA::Hazards::SectorHandOffLostHazard by groundCoordinator;
        satisfy LA::Hazards::RelayedReportDroppedHazard by fleet;
        satisfy LA::Hazards::TrackHandOverGapHazard by groundCoordinator;
        satisfy SurveillanceDroneSwarm::SA::RecallWins by fleet;
        satisfy SurveillanceDroneSwarm::SA::ReturnsWhenIsolated by fleet;
        satisfy SurveillanceDroneSwarm::SA::GeofenceBreachEndsWatch by fleet;
        satisfy SurveillanceDroneSwarm::SA::QuarantinedStaysOut by fleet;
        assert constraint { areaUnderWatchFraction == watchingMembers * footprintSquareKm / taskedAreaSquareKm }
        assert constraint { coverageLossAfterMemberLossFraction == 1.0 / watchingMembers }
        assert constraint { coverageUnderMeshJammingFraction == watchingMembers * footprintSquareKm / taskedAreaSquareKm * (1.0 - jammedLinkFraction * turnaroundMinutes / (sortieMinutes + turnaroundMinutes)) }
    }
}
