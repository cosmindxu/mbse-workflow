package SurveillanceDroneSwarm {
    doc /* SurveillanceDroneSwarm — layered model.
           Mission: The SurveillanceDroneSwarm holds continuous watch over a tasked area of up to 25 km² for an operations centre: it takes tasking, supervisory command, recall and report acknowledgement from the centre and what its sensors see of the area, and returns triaged detection reports, correlated tracks, decision records and a status picture, while constrained by airspace clearance, radio interference, satellite-positioning outages, weather and a fleet of twelve drones, and supplied by a mesh radio, a ground-station link, a battery-swap ground crew and stored maps.
           Function: SurveillanceDroneSwarm carries the tasked area from unwatched and unreported to continuously watched with acknowledged detection reports at the operations centre.
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
    }
    package Common {
        doc /* Definitions every layer of the surveillance drone swarm model shares: what flows between
             * drones, ground station and operations centre; the ports and interfaces they flow through;
             * and one #MoE attribute per measure of effectiveness, each held to its target by a named
             * require constraint. Nothing happens here — behaviour belongs to a layer. */

        attribute def GeoPosition {
            doc /* A place in the world: what a detection report says about where an object was and what a
                 * status message says about where a drone is. */
            attribute latitudeDegrees : ScalarValues::Real {
                doc /* Latitude of the point, in degrees. */
            }
            attribute longitudeDegrees : ScalarValues::Real {
                doc /* Longitude of the point, in degrees. */
            }
            attribute altitudeMetres : ScalarValues::Real {
                doc /* Height above the reference surface, in metres. */
            }
            attribute estimatedErrorMetres : ScalarValues::Real {
                doc /* How far the estimate may be wrong; it grows while satellite positioning is unavailable. */
            }
        }

        item def DetectionReport {
            doc /* What one drone says about one detected object. The brief fixes these eight fields and no
                 * others; everything the operator sees is built from them. */
            attribute position : GeoPosition {
                doc /* Where the detected object was, as the reporting drone estimated it. */
            }
            attribute time : ScalarValues::Real {
                doc /* When the detection was made, in seconds on the mission clock. */
            }
            attribute objectClass : ScalarValues::String {
                doc /* One of the known classes, or Unknown when nothing can be said with enough confidence —
                     * the swarm says Unknown rather than forcing a class. */
            }
            attribute confidence : ScalarValues::Real {
                doc /* How sure the classifier is of objectClass, compared against the reporting threshold in force. */
            }
            attribute sensorId : ScalarValues::String {
                doc /* Which sensor the detection came from, so the reports of a degraded sensor can be found again. */
            }
            attribute memberId : ScalarValues::String {
                doc /* Which drone reported it. */
            }
            attribute classifierVersion : ScalarValues::String {
                doc /* The classifier version that produced the class, so drones running different versions can be told apart. */
            }
            attribute ageSeconds : ScalarValues::Real {
                doc /* How long ago the detection was made, so a report held through a link gap is not read as current. */
            }
        }

        item def Track {
            doc /* One object followed over time. The brief fixes these three fields: after correlation there is
                 * one track per object, not one per observing drone. */
            attribute trackId : ScalarValues::String {
                doc /* The identity of the tracked object, kept across sector handover. */
            }
            attribute lastSeenTime : ScalarValues::Real {
                doc /* When anything last saw the object, in seconds on the mission clock. */
            }
            attribute stale : ScalarValues::Boolean {
                doc /* Set once nothing has been seen for the stale threshold, so a track is never shown as current
                     * when it is not. */
            }
        }

        item def TaskingOrder {
            doc /* What the operations centre gives the swarm to start a mission: the area, its sectors and the window. */
            attribute areaIdentifier : ScalarValues::String {
                doc /* Which area of interest is tasked. */
            }
            attribute sectorList : ScalarValues::String {
                doc /* The sectors the area is divided into, each of which must have a drone watching it. */
            }
            attribute windowStartTime : ScalarValues::Real {
                doc /* When the mission window opens. */
            }
            attribute windowEndTime : ScalarValues::Real {
                doc /* When the mission window closes. */
            }
        }

        item def SupervisoryCommand {
            doc /* What the operator changes while the mission runs, without flying any drone. */
            attribute priorityOrder : ScalarValues::String {
                doc /* Which sectors or object classes matter most at the moment. */
            }
            attribute focusSector : ScalarValues::String {
                doc /* A sector the operator wants looked at more closely. */
            }
            attribute reportingThreshold : ScalarValues::Real {
                doc /* The least confidence a classification needs before it becomes a report. */
            }
        }

        item def RecallOrder {
            doc /* An order to recall and land, for the whole swarm or one drone, arriving at any time. */
            attribute targetMemberId : ScalarValues::String {
                doc /* Which drone is recalled; empty when the whole swarm is. */
            }
            attribute wholeFleet : ScalarValues::Boolean {
                doc /* True when every drone is recalled. */
            }
            attribute issuedTime : ScalarValues::Real {
                doc /* When the order was issued, so a recall is never overtaken by an older command. */
            }
        }

        item def ReportAcknowledgement {
            doc /* The operations centre confirming a detection report, so nothing is lost in a link gap. */
            attribute acknowledgedReportId : ScalarValues::String {
                doc /* Which report is confirmed. */
            }
            attribute acknowledgedBy : ScalarValues::String {
                doc /* Which analyst or operator confirmed it; it goes into the decision record. */
            }
            attribute acknowledgementTime : ScalarValues::Real {
                doc /* When the confirmation was made. */
            }
        }

        item def MemberStatus {
            doc /* What one drone says about itself: the raw material of the status picture. */
            attribute memberId : ScalarValues::String {
                doc /* Which drone this is about. */
            }
            attribute position : GeoPosition {
                doc /* Where the drone is. */
            }
            attribute activitySummary : ScalarValues::String {
                doc /* What it is doing: watching a sector, transiting, recharging, recalled, landed. */
            }
            attribute assignedSector : ScalarValues::String {
                doc /* The sector it is responsible for, if any. */
            }
            attribute flightMinutesRemaining : ScalarValues::Real {
                doc /* How much of its endurance is left, including the transit home. */
            }
            attribute degradationSummary : ScalarValues::String {
                doc /* Which of NavigationDegraded, SensingDegraded, Isolated or Quarantined hold. */
            }
            attribute classifierVersion : ScalarValues::String {
                doc /* The classifier version this drone is running, so mixed versions are visible. */
            }
        }

        item def StatusPicture {
            doc /* What the operator sees of the whole swarm: where every drone is, what it is doing, how much
                 * coverage there is and what is degraded. */
            attribute pictureTime : ScalarValues::Real {
                doc /* When the picture was made, so the operator knows how current it is. */
            }
            attribute memberSummaries : ScalarValues::String {
                doc /* One line per drone, drawn from MemberStatus. */
            }
            attribute coverageFraction : ScalarValues::Real {
                doc /* The share of the tasked area under watch at this moment. */
            }
            attribute degradationSummary : ScalarValues::String {
                doc /* What is degraded across the swarm, including MeshDegraded. */
            }
        }

        item def TriagedAlert {
            doc /* What actually reaches the operator after triage: what is most likely to matter first, with
                 * duplicates merged. */
            attribute alertId : ScalarValues::String {
                doc /* The identity of the alert, carried into the acknowledgement and the decision record. */
            }
            attribute priorityRank : ScalarValues::Integer {
                doc /* Where the alert sits in the order presented to the operator. */
            }
            attribute mergedReportCount : ScalarValues::Integer {
                doc /* How many detection reports were merged into this one alert. */
            }
            attribute summaryText : ScalarValues::String {
                doc /* What the operator reads to judge it inside the time they have. */
            }
        }

        item def DecisionRecord {
            doc /* The record kept for every report: what it was built from and who accepted it, so a decision can
                 * be reconstructed afterwards. */
            attribute reportId : ScalarValues::String {
                doc /* Which report the record is about. */
            }
            attribute frameReferences : ScalarValues::String {
                doc /* The frames the detection came from. */
            }
            attribute classifierVersion : ScalarValues::String {
                doc /* The classifier version that produced the class. */
            }
            attribute thresholdInForce : ScalarValues::Real {
                doc /* The reporting threshold that was in force when the report was made. */
            }
            attribute acknowledgedBy : ScalarValues::String {
                doc /* Who acknowledged it at the operations centre. */
            }
        }

        item def CoordinationUpdate {
            doc /* The unit of member-to-member traffic over the mesh: every coordination matter the drones settle
                 * between themselves travels as one of these. */
            attribute originMemberId : ScalarValues::String {
                doc /* Which drone the update came from. */
            }
            attribute updateKind : ScalarValues::String {
                doc /* Which coordination matter it concerns: handover, rotation, redistribution, deconfliction,
                     * relay, correlation, track handover or admission. */
            }
            attribute sequenceNumber : ScalarValues::Integer {
                doc /* The order of updates from that drone, so a late update never undoes a newer one. */
            }
            attribute hopCount : ScalarValues::Integer {
                doc /* How many drones have relayed it, so relay does not loop. */
            }
            attribute payloadSummary : ScalarValues::String {
                doc /* What the update says, in the terms of its kind. */
            }
        }

        item def SectorAssignment {
            doc /* Which drone is responsible for which sector, and from when. */
            attribute memberId : ScalarValues::String {
                doc /* The drone taking the sector. */
            }
            attribute sectorId : ScalarValues::String {
                doc /* The sector assigned. */
            }
            attribute takesEffectTime : ScalarValues::Real {
                doc /* When the assignment starts, so two drones are never responsible for the same sector at once. */
            }
        }

        item def SectorHandover {
            doc /* A drone leaving to recharge handing its sector to one arriving, without a gap in the watch. */
            attribute sectorId : ScalarValues::String {
                doc /* The sector being handed over. */
            }
            attribute fromMemberId : ScalarValues::String {
                doc /* The drone leaving. */
            }
            attribute toMemberId : ScalarValues::String {
                doc /* The drone arriving. */
            }
            attribute handoverTime : ScalarValues::Real {
                doc /* When responsibility passes; the arriving drone is on station before it. */
            }
        }

        item def RotationPlan {
            doc /* Who goes to recharge next, so the airborne share never falls below what the sectors need. */
            attribute nextToRechargeMemberId : ScalarValues::String {
                doc /* The drone due to leave for the recharge point. */
            }
            attribute airborneShare : ScalarValues::Real {
                doc /* The share of the fleet that stays airborne under this plan. */
            }
            attribute planTime : ScalarValues::Real {
                doc /* When the plan was settled. */
            }
        }

        item def CoverageRedistribution {
            doc /* How the remaining drones re-spread over the sectors when one is lost. */
            attribute lostMemberId : ScalarValues::String {
                doc /* The drone that was lost. */
            }
            attribute reassignments : ScalarValues::String {
                doc /* The new sector assignments for the drones that remain. */
            }
            attribute expectedCoverageFraction : ScalarValues::Real {
                doc /* The coverage the swarm expects to hold once the re-spread is done. */
            }
        }

        item def DeconflictionAdvisory {
            doc /* What keeps two drones apart in the air and at the recharge point. */
            attribute memberId : ScalarValues::String {
                doc /* The drone the advisory is for. */
            }
            attribute conflictWithMemberId : ScalarValues::String {
                doc /* The other drone in the conflict. */
            }
            attribute avoidanceAction : ScalarValues::String {
                doc /* What the drone is to do to keep separation. */
            }
        }

        item def RelayedMessage {
            doc /* A report or status from a drone out of range of the ground station, carried through a neighbour. */
            attribute originMemberId : ScalarValues::String {
                doc /* The drone whose traffic this is. */
            }
            attribute relayMemberId : ScalarValues::String {
                doc /* The neighbour carrying it. */
            }
            attribute hopCount : ScalarValues::Integer {
                doc /* How many relays it has been through. */
            }
            attribute payloadSummary : ScalarValues::String {
                doc /* What is being relayed: a detection report or a status. */
            }
        }

        item def TrackCorrelation {
            doc /* Two drones seeing the same object resolved into one track. */
            attribute primaryTrackId : ScalarValues::String {
                doc /* The track that survives the merge. */
            }
            attribute mergedTrackId : ScalarValues::String {
                doc /* The track folded into it. */
            }
            attribute correlationConfidence : ScalarValues::Real {
                doc /* How sure the swarm is that the two are the same object. */
            }
        }

        item def TrackHandover {
            doc /* An object moving from one sector to the next, with the drone watching the next sector taking
                 * over the track without losing it. */
            attribute trackId : ScalarValues::String {
                doc /* The track being handed over. */
            }
            attribute fromMemberId : ScalarValues::String {
                doc /* The drone giving it up. */
            }
            attribute toMemberId : ScalarValues::String {
                doc /* The drone taking it on. */
            }
            attribute lastSeenTime : ScalarValues::Real {
                doc /* When the object was last seen, so the receiving drone knows how stale the track is. */
            }
        }

        item def AdmissionRequest {
            doc /* A drone asking to join the coordination, with what the others check it by. */
            attribute candidateMemberId : ScalarValues::String {
                doc /* The drone asking to join. */
            }
            attribute credential : ScalarValues::String {
                doc /* What the others authenticate it against. */
            }
            attribute classifierVersion : ScalarValues::String {
                doc /* The classifier version the candidate runs, checked against the fleet's. */
            }
        }

        item def AdmissionVerdict {
            doc /* What the others decide about a candidate: admitted, or quarantined until readmitted. */
            attribute candidateMemberId : ScalarValues::String {
                doc /* The drone the verdict is about. */
            }
            attribute admitted : ScalarValues::Boolean {
                doc /* True when it may take part in coordination. */
            }
            attribute reason : ScalarValues::String {
                doc /* Why it was refused, when it was. */
            }
        }

        item def ClassifierVersionManifest {
            doc /* Which classifier version the fleet is to run and which version each drone is running. */
            attribute fleetClassifierVersion : ScalarValues::String {
                doc /* The one version that is to be held across the fleet. */
            }
            attribute memberId : ScalarValues::String {
                doc /* The drone whose running version is being declared. */
            }
            attribute memberClassifierVersion : ScalarValues::String {
                doc /* The version that drone is actually running. */
            }
        }

        item def SceneObservation {
            doc /* What a sensor gives the classifier: the frames a detection and its decision record are built from. */
            attribute frameId : ScalarValues::String {
                doc /* The identity of the frame, referenced by the decision record. */
            }
            attribute captureTime : ScalarValues::Real {
                doc /* When the frame was taken. */
            }
            attribute sensorId : ScalarValues::String {
                doc /* Which sensor took it. */
            }
            attribute qualityIndicator : ScalarValues::Real {
                doc /* How good the frame is under the lighting and weather of the moment; it is what makes a
                     * degrading sensor visible rather than silent. */
            }
        }

        item def NavigationFix {
            doc /* Where a drone believes it is and how it came to believe it. */
            attribute position : GeoPosition {
                doc /* The fix itself, with its estimated error. */
            }
            attribute fixSource : ScalarValues::String {
                doc /* Satellite positioning, or camera against stored maps when satellite positioning is unavailable. */
            }
            attribute fixTime : ScalarValues::Real {
                doc /* When the fix was taken. */
            }
        }

        item def AirspaceClearance {
            doc /* What the airspace authority allows: when and where anything may fly. */
            attribute clearanceId : ScalarValues::String {
                doc /* The identity of the clearance. */
            }
            attribute geofenceDescription : ScalarValues::String {
                doc /* The volume outside which a drone does not watch. */
            }
            attribute validFromTime : ScalarValues::Real {
                doc /* When the clearance begins. */
            }
            attribute validUntilTime : ScalarValues::Real {
                doc /* When it ends. */
            }
        }

        item def FlightIntent {
            doc /* What the swarm tells the airspace authority it means to do, so the clearance can be held against it. */
            attribute memberId : ScalarValues::String {
                doc /* The drone whose intent this is. */
            }
            attribute sectorId : ScalarValues::String {
                doc /* Where it means to fly. */
            }
            attribute altitudeBand : ScalarValues::String {
                doc /* The height band it means to use. */
            }
            attribute intentWindow : ScalarValues::String {
                doc /* When it means to be there. */
            }
        }

        item def ServiceRequest {
            doc /* A drone asking the ground crew for a battery swap or other servicing. */
            attribute memberId : ScalarValues::String {
                doc /* The drone asking. */
            }
            attribute requestTime : ScalarValues::Real {
                doc /* When it asked, so the turnaround can be measured from it. */
            }
            attribute serviceKind : ScalarValues::String {
                doc /* Battery swap, or other servicing between sorties. */
            }
        }

        item def ServiceCompletion {
            doc /* The ground crew saying a drone is ready to fly again. */
            attribute memberId : ScalarValues::String {
                doc /* The drone that was serviced. */
            }
            attribute completionTime : ScalarValues::Real {
                doc /* When the servicing finished. */
            }
            attribute flightMinutesAvailable : ScalarValues::Real {
                doc /* How much flight the fresh battery gives, out of which transit and watch are both paid. */
            }
        }

        port def MeshPeerPort {
            doc /* How one drone exchanges coordination traffic with a peer over the mesh radio, independently of
                 * the link to the operations centre. Every member is wired through this from LA down. */
            out item update : CoordinationUpdate {
                doc /* The coordination update this drone offers its peer. */
            }
        }

        interface def MeshLink {
            doc /* The mesh between two drones: the bearer of everything the members settle between themselves,
                 * and the thing MeshDegraded is about. */
            end sender : MeshPeerPort {
                doc /* The drone offering the update. */
            }
            end receiver : ~MeshPeerPort {
                doc /* The peer taking it. */
            }
        }

        port def MemberGroundLinkPort {
            doc /* The air side of the radio link between one drone and the ground station: reports and status out,
                 * command in. It is not always available, and the swarm works through a gap. */
            out item report : DetectionReport {
                doc /* Detection reports, held while cut off and delivered when the link returns. */
            }
            out item track : Track {
                doc /* The tracks the drone holds, for correlation and merging further up. */
            }
            out item status : MemberStatus {
                doc /* What the drone says about itself, for the status picture. */
            }
            out item relayed : RelayedMessage {
                doc /* Traffic carried for a neighbour that is out of range of the ground station. */
            }
            in item tasking : TaskingOrder {
                doc /* The area, its sectors and the mission window. */
            }
            in item supervisory : SupervisoryCommand {
                doc /* Priorities, focus sector and the reporting threshold. */
            }
            in item recall : RecallOrder {
                doc /* The order to recall and land. */
            }
            in item acknowledgement : ReportAcknowledgement {
                doc /* Confirmation that a report arrived, so it need not be held any longer. */
            }
            in item manifest : ClassifierVersionManifest {
                doc /* The classifier version the fleet is to run. */
            }
        }

        interface def GroundLink {
            doc /* The radio link between a drone and the ground station; the one whose loss the swarm has to
                 * survive without dropping the watch. */
            end airSide : MemberGroundLinkPort {
                doc /* The drone's end of the link. */
            }
            end groundSide : ~MemberGroundLinkPort {
                doc /* The ground station's end of the link. */
            }
        }

        port def OperationsLinkPort {
            doc /* The ground station's side of what passes to and from the operations centre. */
            out item alert : TriagedAlert {
                doc /* What reaches the operator, ranked and with duplicates merged. */
            }
            out item track : Track {
                doc /* Correlated tracks, to be merged at the centre with the fixed camera network's tracks. */
            }
            out item picture : StatusPicture {
                doc /* Where every drone is, what it is doing, how much coverage there is, what is degraded. */
            }
            out item record : DecisionRecord {
                doc /* The record kept for every report. */
            }
            in item tasking : TaskingOrder {
                doc /* The mission the centre tasks. */
            }
            in item supervisory : SupervisoryCommand {
                doc /* The operator's priorities, focus and reporting threshold. */
            }
            in item recall : RecallOrder {
                doc /* Recall and land, for the swarm or one drone. */
            }
            in item acknowledgement : ReportAcknowledgement {
                doc /* The centre confirming each detection report. */
            }
        }

        interface def OperationsLink {
            doc /* What joins the swarm's ground station to the operations centre where analysts watch and
                 * acknowledge. */
            end systemSide : OperationsLinkPort {
                doc /* The ground station's end. */
            }
            end centreSide : ~OperationsLinkPort {
                doc /* The operations centre's end. */
            }
        }

        port def AirspaceAuthorityPort {
            doc /* How the system takes its clearance and declares what it means to fly. */
            in item clearance : AirspaceClearance {
                doc /* When and where anything may fly. */
            }
            out item intent : FlightIntent {
                doc /* What the swarm means to do, declared against the clearance. */
            }
        }

        interface def AirspaceCoordinationLink {
            doc /* What joins the system to the airspace authority that constrains every sortie. */
            end systemSide : AirspaceAuthorityPort {
                doc /* The system's end. */
            }
            end authoritySide : ~AirspaceAuthorityPort {
                doc /* The authority's end. */
            }
        }

        port def GroundServicePort {
            doc /* How a drone and the ground crew settle a turnaround at the recharge point. */
            out item request : ServiceRequest {
                doc /* The drone asking for a battery swap. */
            }
            in item completion : ServiceCompletion {
                doc /* The crew saying it is ready to fly again. */
            }
        }

        interface def GroundServiceLink {
            doc /* What joins a drone at the recharge point to the crew that swaps its battery in about twenty minutes. */
            end droneSide : GroundServicePort {
                doc /* The drone's end. */
            }
            end crewSide : ~GroundServicePort {
                doc /* The ground crew's end. */
            }
        }

        port def SensorFeedPort {
            doc /* How the frames a sensor takes reach whatever classifies them. */
            out item observation : SceneObservation {
                doc /* A frame with the time, the sensor and how good it is under the lighting and weather. */
            }
        }

        interface def SensorFeed {
            doc /* What joins a sensor to the classification that reads its frames; the path along which a
                 * degrading sensor has to become visible. */
            end sensorSide : SensorFeedPort {
                doc /* The sensor's end. */
            }
            end processingSide : ~SensorFeedPort {
                doc /* The classifier's end. */
            }
        }

        port def NavigationFeedPort {
            doc /* How a position estimate reaches whatever stamps a report with it. */
            out item fix : NavigationFix {
                doc /* Where the drone believes it is, from satellite positioning or from camera against stored maps. */
            }
        }

        interface def NavigationFeed {
            doc /* What joins navigation to the functions that depend on knowing where the drone is: reporting,
                 * geofence keeping and deconfliction. */
            end navigationSide : NavigationFeedPort {
                doc /* The navigation end. */
            }
            end consumerSide : ~NavigationFeedPort {
                doc /* The end that uses the fix. */
            }
        }

        #MoE attribute areaUnderWatchFraction : ScalarValues::Real {
            doc /* The share of the tasked area under watch at any moment. The brief requires at least 0.9 and it
                 * follows arithmetically from how many drones are airborne and how much each of them sees. */
            require constraint areaUnderWatchMeetsTarget {
                doc /* At any moment at least 0.9 of the area is under watch. */
                areaUnderWatchFraction >= 0.9
            }
        }

        #MoE attribute watchEnduranceHoursWithoutPeople : ScalarValues::Real {
            doc /* How long the swarm holds the watch before it needs people to intervene. The brief names this as
                 * a thing that matters but states no number: 12 hours is the architect's working target and is not
                 * the customer's. */
            require constraint watchEnduranceMeetsTarget {
                doc /* The swarm holds the watch for at least 12 hours unaided. */
                watchEnduranceHoursWithoutPeople >= 12
            }
        }

        #MoE attribute reportDeliveryLatencySeconds : ScalarValues::Real {
            doc /* How old a report is when it reaches the operations centre with the link up. Placeholder: the
                 * customer has not yet stated this number. */
            require constraint reportLatencyMeetsTarget {
                doc /* With the link up, a report is no older than 60 seconds on arrival — a placeholder. */
                reportDeliveryLatencySeconds <= 60
            }
        }

        #MoE attribute positionErrorAfterGnssLossMetres : ScalarValues::Real {
            doc /* How far a drone's position estimate may be wrong after ten minutes without satellite positioning.
                 * Placeholder: not yet the customer's number. */
            require constraint positionErrorMeetsTarget {
                doc /* After ten minutes without satellite positioning the position error stays within 50 m — a placeholder. */
                positionErrorAfterGnssLossMetres <= 50
            }
        }

        #MoE attribute coverageUnderMeshJammingFraction : ScalarValues::Real {
            doc /* The share of the area still under watch with half the links between drones jammed. Placeholder:
                 * not yet the customer's number. It is the sharpest discriminator between ground-held and
                 * drone-held coordination. */
            require constraint jammedCoverageMeetsTarget {
                doc /* With half the links jammed, at least 0.75 of the area stays under watch — a placeholder. */
                coverageUnderMeshJammingFraction >= 0.75
            }
        }

        #MoE attribute reportHoldDurationMinutes : ScalarValues::Real {
            doc /* How long a cut-off drone holds its reports and loses none. Placeholder: not yet the customer's number. */
            require constraint reportHoldMeetsTarget {
                doc /* While cut off, a drone holds its reports for at least 30 minutes — a placeholder. */
                reportHoldDurationMinutes >= 30
            }
        }

        #MoE attribute missedDetectionFraction : ScalarValues::Real {
            doc /* The share of real objects that go undetected. Placeholder: not yet the customer's number. */
            require constraint missedDetectionMeetsTarget {
                doc /* No more than 0.10 of real objects go undetected — a placeholder. */
                missedDetectionFraction <= 0.10
            }
        }

        #MoE attribute falseAlarmsPerHour : ScalarValues::Real {
            doc /* False alarms reaching the operator each hour; traded against missed detections by the reporting
                 * threshold. Placeholder: not yet the customer's number. */
            require constraint falseAlarmsMeetTarget {
                doc /* No more than 2 false alarms an hour reach the operator — a placeholder. */
                falseAlarmsPerHour <= 2
            }
        }

        #MoE attribute alertsReachingOperatorPerHour : ScalarValues::Real {
            doc /* How many alerts actually reach the operator after triage and duplicate merging. Placeholder: it
                 * is set against the operator capacity the brief marks as a placeholder. */
            require constraint alertRateMeetsTarget {
                doc /* No more than 20 alerts an hour reach the operator — a placeholder. */
                alertsReachingOperatorPerHour <= 20
            }
        }

        #MoE attribute acknowledgedReportsThatMatterFraction : ScalarValues::Real {
            doc /* The share of the reports the operator acknowledges that turn out to matter. Placeholder: not yet
                 * the customer's number. */
            require constraint acknowledgedPrecisionMeetsTarget {
                doc /* At least 0.8 of acknowledged reports turn out to matter — a placeholder. */
                acknowledgedReportsThatMatterFraction >= 0.8
            }
        }

        #MoE attribute coverageDropAfterMemberLossFraction : ScalarValues::Real {
            doc /* How much coverage is lost when one drone is lost, before the remaining drones re-spread. */
            require constraint coverageDropMeetsTarget {
                doc /* No more than 0.25 of the coverage drops before the swarm re-spreads. */
                coverageDropAfterMemberLossFraction <= 0.25
            }
        }

        #MoE attribute onboardClassifierCostUsdPerDrone : ScalarValues::Real {
            doc /* What the on-board computing for classification costs per drone. Placeholder: not yet the
                 * customer's number. Multiplied by twelve it decides whether classification can live on the drones. */
            require constraint classifierCostMeetsTarget {
                doc /* The on-board computing for classification costs no more than 300 USD per drone — a placeholder. */
                onboardClassifierCostUsdPerDrone <= 300
            }
        }

        #MoE attribute fleetSizeDrones : ScalarValues::Integer {
            doc /* Budget: twelve drones is the fleet the design has to work with. Fixed by the brief, held as a
                 * requirement and never scored between architectures. */
            require constraint fleetSizeWithinBudget {
                doc /* The design works with no more than 12 drones. */
                fleetSizeDrones <= 12
            }
        }

        #MoE attribute memberFlightEnduranceMinutes : ScalarValues::Real {
            doc /* Budget: about 40 minutes of flight per drone, fixed by the brief. Transit out and back is spent
                 * from this same budget, so it is read with cruiseSpeedMetresPerSecond, which the brief does give. */
            require constraint flightEnduranceWithinBudget {
                doc /* A drone flies for at least 40 minutes on one battery. */
                memberFlightEnduranceMinutes >= 40
            }
        }

        #MoE attribute groundTurnaroundMinutes : ScalarValues::Real {
            doc /* Budget: about 20 minutes on the ground, because batteries are swapped rather than charged in
                 * place. With endurance it fixes the airborne share the fleet can hold. */
            require constraint turnaroundWithinBudget {
                doc /* Turnaround on the ground is no more than 20 minutes. */
                groundTurnaroundMinutes <= 20
            }
        }

        #MoE attribute cruiseSpeedMetresPerSecond : ScalarValues::Real {
            doc /* Budget: about 18 m/s between recharge point and sector, fixed by the brief. Without it nothing
                 * can say a drone reaches its station and returns inside its 40 minutes over an area several
                 * kilometres across. */
            require constraint cruiseSpeedWithinBudget {
                doc /* A drone cruises at no less than 18 m/s between recharge point and sector. */
                cruiseSpeedMetresPerSecond >= 18
            }
        }

        #MoE attribute sensorFootprintSquareKilometres : ScalarValues::Real {
            doc /* Budget: about 3.0 km² under watch from a drone's watch altitude. This is what makes the coverage
                 * figure arithmetic rather than a hope. */
            require constraint sensorFootprintWithinBudget {
                doc /* A drone keeps at least 3.0 km² under watch at once. */
                sensorFootprintSquareKilometres >= 3.0
            }
        }

        #MoE attribute areaOfInterestSquareKilometres : ScalarValues::Real {
            doc /* Budget: the area of interest is up to 25 km², divided into sectors. Fixed by the brief. */
            require constraint areaWithinBudget {
                doc /* The tasked area is no more than 25 km². */
                areaOfInterestSquareKilometres <= 25
            }
        }

        #MoE attribute operatorAlertCapacityPerHour : ScalarValues::Real {
            doc /* Budget: the most alerts one operator can judge in an hour. A property of the operator, not
                 * something an architecture improves. Placeholder: not yet the customer's number. */
            require constraint operatorCapacityWithinBudget {
                doc /* The operator judges at most 20 alerts an hour — a placeholder. */
                operatorAlertCapacityPerHour <= 20
            }
        }

        #MoE attribute operatorSecondsPerAlert : ScalarValues::Real {
            doc /* Budget: the least time the operator needs for each alert. Placeholder: not yet the customer's number. */
            require constraint operatorTimeWithinBudget {
                doc /* The operator has at least 30 seconds for each alert — a placeholder. */
                operatorSecondsPerAlert >= 30
            }
        }

        #MoE attribute trackStaleThresholdSeconds : ScalarValues::Real {
            doc /* Budget: a track is stale once nothing has been seen for this long. It is the value the stale field
                 * of a Track is set from. Placeholder: not yet the customer's number. */
            require constraint staleThresholdWithinBudget {
                doc /* A track is marked stale after no more than 120 seconds without a sighting — a placeholder. */
                trackStaleThresholdSeconds <= 120
            }
        }

        #MoE attribute gnssOutageToleratedMinutes : ScalarValues::Real {
            doc /* Budget: the satellite-positioning outage the position-error measure is stated against.
                 * Placeholder: not yet the customer's number. */
            require constraint gnssOutageWithinBudget {
                doc /* The drone tolerates at least 10 minutes without satellite positioning — a placeholder. */
                gnssOutageToleratedMinutes >= 10
            }
        }

        #MoE attribute jammedLinkShareFraction : ScalarValues::Real {
            doc /* Budget: the share of links between drones assumed jammed when degraded coverage is measured.
                 * Placeholder: not yet the customer's number. */
            require constraint jammedShareWithinBudget {
                doc /* Degraded coverage is measured with at least half the links between drones jammed — a placeholder. */
                jammedLinkShareFraction >= 0.5
            }
        }
        // ── shared definitions asked for by OA ──
        item def MissionTasking {
        doc /* The area of interest, its sectors and the mission window, issued by the operations centre. */
        attribute areaOfInterestId : String;
        attribute sectors : String;
        attribute missionWindow : String;
        }
        item def RechargeRotationPlan {
        doc /* A plan settling which member withdraws to swap batteries and which replaces it on station. */
        attribute memberId : String;
        attribute recallTime : String;
        attribute replacementMemberId : String;
        }
        item def CoverageRedistributionPlan {
        doc /* A re-spread of sector assignments across members as one leaves, rejoins or is lost. */
        attribute sectorId : String;
        attribute assignedMemberIds : String;
        }
        item def MembershipRequest {
        doc /* A candidate's request to join the mesh and take part in coordination. */
        attribute candidateId : String;
        attribute credential : String;
        }
        item def MembershipDecision {
        doc /* The existing members' decision on a candidate's admission request. */
        attribute candidateId : String;
        attribute accepted : Boolean;
        attribute reason : String;
        }}
    package OA {
    	doc /* Operational Analysis: the entities of the surveillance operation as it stands today, what each does, what they exchange, and their operational modes -- without naming or presupposing the system that will later take the watch asset over. */

    	/* ===================== Resources (environment, not the system) ===================== */

    	part def GroundStation {
    		doc /* Fixed ground infrastructure that hosts tasking, the watch picture and, in a ground-centred architecture, sector and rotation coordination. Not the drone population itself. */
    	}
    	part groundStation : GroundStation {
    		doc /* The fixed ground station used by this operation. */
    	}

    	part def MeshRadio {
    		doc /* Bearer of member-to-member coordination traffic, independent of the link to the operations centre; what lets the watch survive a ground-link drop. */
    	}
    	part meshRadio : MeshRadio {
    		doc /* The mesh radio resource shared by the watch-asset population. */
    	}

    	part def GroundStationLink {
    		doc /* Radio link between the watch asset and the ground station; not always available, worked through and reconciled afterwards. */
    	}
    	part groundStationLink : GroundStationLink {
    		doc /* The ground-station link resource of this operation. */
    	}

    	part def RechargePointAndBatterySwap {
    		doc /* Ground point and crew where batteries are swapped rather than charged in place, giving a roughly twenty-minute turnaround. */
    	}
    	part rechargePointAndBatterySwap : RechargePointAndBatterySwap {
    		doc /* The recharge point and battery-swap crew serving the population. */
    	}

    	part def RecoveryPoint {
    		doc /* The point a member that has lost contact with the swarm returns to on its own rather than becoming a hazard. */
    	}
    	part recoveryPoint : RecoveryPoint {
    		doc /* The recovery point this operation designates. */
    	}

    	part def StoredMaps {
    		doc /* Reference imagery a member navigates against when satellite positioning is unavailable. */
    	}
    	part storedMaps : StoredMaps {
    		doc /* The stored-map reference imagery this operation maintains. */
    	}

    	part def ClassifierRelease {
    		doc /* One classifier version held across the fleet, with each member's running version known. */
    	}
    	part classifierRelease : ClassifierRelease {
    		doc /* The classifier version currently released to the population. */
    	}

    	/* ===================== Coordination and command-and-control activities ===================== */
    	/* Each is the OA action def that every member's activity is typed by, per the brief's population rule. */

    	#Coordination action def HandOverSector {
    		doc /* Settles sector handover: one member formally passes watch responsibility for a sector to another. */
    		out port reqOut : Common::SectorAssignment {
    			doc /* The sector-assignment offer this member sends toward the peer it is handing responsibility to. */
    		}
    		in port reqIn : Common::SectorAssignment {
    			doc /* The sector-assignment offer this member receives from a peer handing it responsibility. */
    		}
    	}

    	#Coordination action def RotateRecharge {
    		doc /* Settles recharge rotation: schedules a member's withdrawal to swap batteries and its replacement on station. */
    		out port reqOut : Common::RechargeRotationPlan {
    			doc /* The rotation plan this member proposes for its own withdrawal and replacement. */
    		}
    		in port reqIn : Common::RechargeRotationPlan {
    			doc /* The rotation plan this member receives, agreeing to relieve or be relieved. */
    		}
    	}

    	#Coordination action def RedistributeCoverage {
    		doc /* Settles coverage redistribution: re-spreads members across sectors as one leaves, rejoins or is lost. */
    		out port reqOut : Common::CoverageRedistributionPlan {
    			doc /* The re-spread plan this member proposes to peers. */
    		}
    		in port reqIn : Common::CoverageRedistributionPlan {
    			doc /* The re-spread plan this member receives and adopts. */
    		}
    	}

    	#Coordination action def DeconflictFlight {
    		doc /* Settles deconfliction: keeps members apart in the air. */
    		out port reqOut : Common::DeconflictionAdvisory {
    			doc /* The avoidance advisory this member issues to a peer it may otherwise converge with. */
    		}
    		in port reqIn : Common::DeconflictionAdvisory {
    			doc /* The avoidance advisory this member receives from a peer. */
    		}
    	}

    	#Coordination action def RelayThroughNeighbour {
    		doc /* Settles relay: one member forwards another member's traffic when a direct path is unavailable. */
    		out port reqOut : Common::RelayedMessage {
    			doc /* Traffic this member forwards on behalf of another member. */
    		}
    		in port reqIn : Common::RelayedMessage {
    			doc /* Traffic this member receives to forward, or receives as the intended destination via relay. */
    		}
    	}

    	#Coordination action def CorrelateTracks {
    		doc /* Settles track correlation: merges observations of the same object from different members into one track rather than one per observer. */
    		out port reqOut : Common::Track {
    			doc /* An observation-derived track this member offers for correlation with peers' sightings of the same object. */
    		}
    		in port reqIn : Common::Track {
    			doc /* A peer's track offered for correlation against this member's own observations. */
    		}
    	}

    	#Coordination action def HandOverTrack {
    		doc /* Settles track handover: passes custody of a track from the member that has been carrying it to the member now best placed to. */
    		out port reqOut : Common::Track {
    			doc /* The track this member hands off to a peer now better placed to carry it. */
    		}
    		in port reqIn : Common::Track {
    			doc /* The track this member takes custody of from a peer. */
    		}
    	}

    	#Coordination action def AdmitMember {
    		doc /* Settles member admission: a candidate requests to join the mesh and existing members decide whether to admit it. */
    		out port admitReqOut : Common::MembershipRequest {
    			doc /* The admission request this member sends when seeking to join, or forwards on a candidate's behalf. */
    		}
    		in port admitReqIn : Common::MembershipRequest {
    			doc /* The admission request this member receives from a candidate. */
    		}
    		out port admitDecOut : Common::MembershipDecision {
    			doc /* The admission decision this member returns to a candidate. */
    		}
    		in port admitDecIn : Common::MembershipDecision {
    			doc /* The admission decision this member receives about its own candidacy. */
    		}
    	}

    	#C2 action def TaskSurveillanceMission {
    		doc /* Lets the supervisor set the area of interest, its sectors and the mission window for the watch asset. */
    		out port cmdOut : Common::MissionTasking {
    			doc /* The mission tasking issued by the supervisor. */
    		}
    		in port cmdIn : Common::MissionTasking {
    			doc /* The mission tasking received by a member of the watch asset. */
    		}
    	}

    	#C2 action def IssueSupervisoryCommand {
    		doc /* Lets the supervisor set priorities, a sector to look at more closely, and the reporting threshold. */
    		out port cmdOut : Common::SupervisoryCommand {
    			doc /* The supervisory command issued by the supervisor. */
    		}
    		in port cmdIn : Common::SupervisoryCommand {
    			doc /* The supervisory command received by a member of the watch asset. */
    		}
    	}

    	#C2 action def RecallToLand {
    		doc /* Lets the supervisor recall and land the whole watch asset or one member, arriving at any time. */
    		out port cmdOut : Common::RecallOrder {
    			doc /* The recall order issued by the supervisor. */
    		}
    		in port cmdIn : Common::RecallOrder {
    			doc /* The recall order received by a member of the watch asset. */
    		}
    	}

    	#C2 action def PresentStatusPicture {
    		doc /* Presents where every member is, what it is doing, how much coverage there is and what is degraded. */
    		out port cmdOut : Common::StatusPicture {
    			doc /* The status picture assembled and sent toward the supervisor. */
    		}
    		in port cmdIn : Common::StatusPicture {
    			doc /* The status picture received by the supervisor. */
    		}
    	}

    	#C2 action def AcknowledgeDetectionReport {
    		doc /* Confirms each detection report at the operations centre, so nothing is lost across a link gap. */
    		out port ackOut : Common::ReportAcknowledgement {
    			doc /* The acknowledgement issued by the analyst for a received detection report. */
    		}
    		in port ackIn : Common::ReportAcknowledgement {
    			doc /* The acknowledgement received by the member whose report it confirms. */
    		}
    	}

    	/* ===================== Other member activities (not coordination/C2, but part of "what each does") ===================== */

    	action def WatchSector {
    		doc /* Holds continuous watch over an assigned sector from altitude. */
    	}

    	action def DetectAndClassify {
    		doc /* Detects moving objects in the watched sector and classifies them well enough to say whether they matter, saying Unknown rather than forcing a class. */
    	}

    	action def ReportDetection {
    		doc /* Carries one detection report from the member that made it to the operations centre. */
    		out port reportOut : Common::DetectionReport {
    			doc /* The detection report sent by the member that made it. */
    		}
    		in port reportIn : Common::DetectionReport {
    			doc /* The detection report received at the operations centre. */
    		}
    	}

    	/* ===================== Operational modes of the watch asset ===================== */

    	#Mode state def WatchAssetOperatingMode {
    		doc /* The operating mode of a watch-asset member across its duty cycle. */
    		initial start;
    		transition start -> Watching;
    		state Watching {
    			doc /* Actively watching an assigned sector. */
    		}
    		state Transiting {
    			doc /* Repositioning between sector and recharge point. */
    		}
    		state Recharging {
    			doc /* On the ground swapping batteries with the ground crew. */
    		}
    		state Grounded {
    			doc /* Not flying: recalled, faulted, or awaiting airspace clearance. */
    		}
    		transition Watching -> Transiting;
    		transition Transiting -> Recharging;
    		transition Recharging -> Transiting;
    		transition Transiting -> Watching;
    		transition Watching -> Grounded;
    		transition Transiting -> Grounded;
    		transition Grounded -> Transiting;
    	}

    	#State state def WatchAssetAvailabilityState {
    		doc /* Whether a watch-asset member can currently be tasked and can take part in coordination. */
    		initial start;
    		transition start -> Available;
    		state Available {
    			doc /* Able to accept tasking and take part in coordination. */
    		}
    		state Committed {
    			doc /* Currently executing an assigned activity. */
    		}
    		state Unavailable {
    			doc /* Cannot currently be tasked: servicing, recalled, or off-station. */
    		}
    		transition Available -> Committed;
    		transition Committed -> Available;
    		transition Available -> Unavailable;
    		transition Unavailable -> Available;
    	}

    	/* ===================== The operational entity the system takes over: a population ===================== */
    	/* The member definition carries only what every member is, not what it does: activities are declared beside the parts below and allocated to the representative that performs them, so allocation -- not ownership -- is what the next layer inherits. */

    	part def WatchAssetMember {
    		doc /* The kind of member the watch-asset population is made of: each able to watch a sector, coordinate with its peers over the mesh, and take command from the supervisor. Declared once here; the population is never collapsed into a single instance. */
    		state mode : WatchAssetOperatingMode {
    			doc /* This kind of member's operating-mode state machine. */
    		}
    		state availability : WatchAssetAvailabilityState {
    			doc /* This kind of member's availability state machine. */
    		}
    	}

    	part watchAsset : WatchAssetMember {
    		doc /* The watch asset: the single named operational entity, under the exact name the brief gives, that the system takes over. Untagged. It names the population as a whole; the population that realises it in the field is assetAlpha, assetBravo and their ten peers, whose own activities are declared beside them below and allocated to them, not to this part. */
    	}

    	part assetAlpha : WatchAssetMember {
    		doc /* One representative member of the watch-asset population. Its own activities are declared beside it below, as usages of the OA action defs every member's activity is typed by, and allocated to it -- not nested inside this part. */
    	}

    	part assetBravo : WatchAssetMember {
    		doc /* A second representative member of the watch-asset population, standing for the other ten. Its own activities are declared beside it below, as usages of the same OA action defs, and allocated to it -- not nested inside this part; together with assetAlpha's, they are the two ends the flows below connect. */
    	}

    	/* ----- assetAlpha's own activities: usages beside the part, allocated to it, not nested in it ----- */

    	action alphaWatchSector : WatchSector {
    		doc /* assetAlpha's own performance of holding watch over its assigned sector. */
    	}
    	action alphaDetectAndClassify : DetectAndClassify {
    		doc /* assetAlpha's own performance of detecting and classifying objects in its sector. */
    	}
    	action alphaReportDetection : ReportDetection {
    		doc /* assetAlpha's own performance of carrying a detection report to the operations centre. */
    	}
    	action alphaHandOverSector : HandOverSector {
    		doc /* assetAlpha's own performance of sector handover. */
    	}
    	action alphaRotateRecharge : RotateRecharge {
    		doc /* assetAlpha's own performance of recharge rotation. */
    	}
    	action alphaRedistributeCoverage : RedistributeCoverage {
    		doc /* assetAlpha's own performance of coverage redistribution. */
    	}
    	action alphaDeconflictFlight : DeconflictFlight {
    		doc /* assetAlpha's own performance of flight deconfliction. */
    	}
    	action alphaRelayThroughNeighbour : RelayThroughNeighbour {
    		doc /* assetAlpha's own performance of relay through a neighbour. */
    	}
    	action alphaCorrelateTracks : CorrelateTracks {
    		doc /* assetAlpha's own performance of track correlation. */
    	}
    	action alphaHandOverTrack : HandOverTrack {
    		doc /* assetAlpha's own performance of track handover. */
    	}
    	action alphaAdmitMember : AdmitMember {
    		doc /* assetAlpha's own performance of member admission. */
    	}
    	action alphaTaskSurveillanceMission : TaskSurveillanceMission {
    		doc /* assetAlpha's own acceptance of mission tasking. */
    	}
    	action alphaIssueSupervisoryCommand : IssueSupervisoryCommand {
    		doc /* assetAlpha's own acceptance of a supervisory command. */
    	}
    	action alphaRecallToLand : RecallToLand {
    		doc /* assetAlpha's own acceptance of a recall order. */
    	}
    	action alphaPresentStatusPicture : PresentStatusPicture {
    		doc /* assetAlpha's own contribution to the status picture. */
    	}
    	action alphaAcknowledgeDetectionReport : AcknowledgeDetectionReport {
    		doc /* assetAlpha's own receipt of a detection-report acknowledgement. */
    	}

    	/* ----- assetBravo's own activities: usages beside the part, allocated to it, not nested in it ----- */

    	action bravoWatchSector : WatchSector {
    		doc /* assetBravo's own performance of holding watch over its assigned sector. */
    	}
    	action bravoDetectAndClassify : DetectAndClassify {
    		doc /* assetBravo's own performance of detecting and classifying objects in its sector. */
    	}
    	action bravoReportDetection : ReportDetection {
    		doc /* assetBravo's own performance of carrying a detection report to the operations centre. */
    	}
    	action bravoHandOverSector : HandOverSector {
    		doc /* assetBravo's own performance of sector handover. */
    	}
    	action bravoRotateRecharge : RotateRecharge {
    		doc /* assetBravo's own performance of recharge rotation. */
    	}
    	action bravoRedistributeCoverage : RedistributeCoverage {
    		doc /* assetBravo's own performance of coverage redistribution. */
    	}
    	action bravoDeconflictFlight : DeconflictFlight {
    		doc /* assetBravo's own performance of flight deconfliction. */
    	}
    	action bravoRelayThroughNeighbour : RelayThroughNeighbour {
    		doc /* assetBravo's own performance of relay through a neighbour. */
    	}
    	action bravoCorrelateTracks : CorrelateTracks {
    		doc /* assetBravo's own performance of track correlation. */
    	}
    	action bravoHandOverTrack : HandOverTrack {
    		doc /* assetBravo's own performance of track handover. */
    	}
    	action bravoAdmitMember : AdmitMember {
    		doc /* assetBravo's own performance of member admission. */
    	}
    	action bravoTaskSurveillanceMission : TaskSurveillanceMission {
    		doc /* assetBravo's own acceptance of mission tasking. */
    	}
    	action bravoIssueSupervisoryCommand : IssueSupervisoryCommand {
    		doc /* assetBravo's own acceptance of a supervisory command. */
    	}
    	action bravoRecallToLand : RecallToLand {
    		doc /* assetBravo's own acceptance of a recall order. */
    	}
    	action bravoPresentStatusPicture : PresentStatusPicture {
    		doc /* assetBravo's own contribution to the status picture. */
    	}
    	action bravoAcknowledgeDetectionReport : AcknowledgeDetectionReport {
    		doc /* assetBravo's own receipt of a detection-report acknowledgement. */
    	}

    	/* ===================== Human and institutional actors ===================== */
    	/* Every actor's own activity is a usage declared beside its part, at this package's top level, and allocated to it below -- never nested inside the #Actor part def, which would make a three-segment flow end that resolves to nothing once this layer is carried down. */

    	#Actor part def SwarmSupervisor {
    		doc /* The single operator who tasks, commands, recalls and watches the whole watch asset rather than flying each member. */
    	}
    	part swarmSupervisor : SwarmSupervisor {
    		doc /* The supervisor on duty for this operation. */
    	}

    	action supervisorTaskSurveillanceMission : TaskSurveillanceMission {
    		doc /* The supervisor's own issuing of mission tasking. */
    	}
    	action supervisorIssueSupervisoryCommand : IssueSupervisoryCommand {
    		doc /* The supervisor's own issuing of a supervisory command. */
    	}
    	action supervisorRecallToLand : RecallToLand {
    		doc /* The supervisor's own issuing of a recall order. */
    	}
    	action supervisorPresentStatusPicture : PresentStatusPicture {
    		doc /* The supervisor's own receipt of the status picture. */
    	}

    	#Actor part def OperationsCentreAnalyst {
    		doc /* Watches the feeds and reports, judges what matters, and acknowledges each detection report; the one whose attention triage has to protect. */
    	}
    	part opsCentreAnalyst : OperationsCentreAnalyst {
    		doc /* The analyst on duty at the operations centre. */
    	}

    	action analystReportDetection : ReportDetection {
    		doc /* The analyst's own receipt of a detection report. */
    	}
    	action analystAcknowledgeDetectionReport : AcknowledgeDetectionReport {
    		doc /* The analyst's own issuing of a detection-report acknowledgement. */
    	}

    	#Actor part def DutyController {
    		doc /* Today assigns sectors, hands sectors over, re-spreads assets, keeps them apart and relays reports by hand; the role the watch asset's own coordination activities (HandOverSector, RotateRecharge, RedistributeCoverage, DeconflictFlight) take over. */
    	}
    	part dutyController : DutyController {
    		doc /* The duty controller currently performing manual coordination for this operation. */
    	}

    	#Actor part def AirspaceAuthority {
    		doc /* Clears when and where anything may fly; its geofence and window constrain every sortie. */
    	}
    	part airspaceAuthority : AirspaceAuthority {
    		doc /* The airspace authority governing this operation's area of interest. */
    	}

    	#Actor part def GroundCrew {
    		doc /* Services members between sorties and swaps batteries at the recharge point in about twenty minutes. */
    	}
    	part groundCrew : GroundCrew {
    		doc /* The ground crew servicing this operation's population. */
    	}

    	#Actor part def FixedCameraNetworkOperator {
    		doc /* Keeps the existing fixed camera network and its own tracks, merged at the operations centre with what the watch asset reports. */
    	}
    	part fixedCameraNetworkOperator : FixedCameraNetworkOperator {
    		doc /* The operator of the fixed camera network this operation merges tracks with. */
    	}

    	#Actor part def SafetyAuthority {
    		doc /* Holds the watch asset to the rules it never breaks -- recall, geofence, return when isolated, quarantine -- enforced independently of the detection software. */
    	}
    	part safetyAuthority : SafetyAuthority {
    		doc /* The safety authority overseeing this operation. */
    	}

    	#Actor part def ProcuringCustomer {
    		doc /* Fields the population, states the numbers still marked placeholder, and chooses between candidate architectures. */
    	}
    	part procuringCustomer : ProcuringCustomer {
    		doc /* The customer procuring this operation's population. */
    	}

    	/* ===================== Mission ===================== */

    	#Mission use case def SurveillanceWatchMission {
    		doc /* Carries the tasked area of interest from unwatched and unreported to continuously watched, with acknowledged detection reports delivered to the operations centre. */
    		subject asset : WatchAssetMember;
    	}

    	/* ===================== Capabilities ===================== */

    	#Capability use case def ContinuousAreaWatch {
    		doc /* Holds continuous surveillance of the tasked area: at any moment at least one member watches each sector, through recharge rotations. */
    		subject asset : WatchAssetMember;
    	}

    	#Capability use case def DetectionClassificationAndReporting {
    		doc /* Detects moving objects, classifies them well enough to say whether they matter -- saying Unknown rather than forcing a class -- and reports them with a position and a time. */
    		subject asset : WatchAssetMember;
    	}

    	#Capability use case def SwarmSelfCoordination {
    		doc /* Settles sector handover, recharge rotation, coverage redistribution, deconfliction, relay, track correlation, track handover and member admission between members over the mesh. */
    		subject asset : WatchAssetMember;
    	}

    	#Capability use case def SupervisedCommandAndControl {
    		doc /* Lets one operator task, command, recall, watch and acknowledge for the whole watch asset rather than fly each member. */
    		subject supervisor : SwarmSupervisor;
    	}

    	#Capability use case def DisconnectedOperationAndReconciliation {
    		doc /* Keeps detecting while cut off from the operations centre, holds the reports, and delivers them once the link is back -- none lost. */
    		subject asset : WatchAssetMember;
    	}

    	#Capability use case def ReportTriageAndDecisionRecord {
    		doc /* Triages reports before they reach the operator, merges duplicates, and keeps a decision record for every report. */
    		subject asset : WatchAssetMember;
    	}

    	#Capability use case def GracefulDegradation {
    		doc /* Keeps flying and watching as members leave, rejoin or are lost, with the loss of coverage bounded rather than the watch stopping. */
    		subject asset : WatchAssetMember;
    	}

    	#Capability use case def AirspaceComplianceAndSafeRecovery {
    		doc /* Stays inside cleared airspace, lands safely when it is not available, and returns to a recovery point when contact with the swarm is lost. */
    		subject asset : WatchAssetMember;
    	}

    	/* ===================== Exchanges between members of the population ===================== */
    	/* Between the two representatives' own activities declared above; the same pattern applies across every pair in the fleet. */

    	flow sectorHandoverFlow of Common::SectorAssignment from alphaHandOverSector.reqOut to bravoHandOverSector.reqIn {
    		doc /* A sector handover offered by one member and accepted by its neighbour. */
    	}

    	flow rechargeRotationFlow of Common::RechargeRotationPlan from bravoRotateRecharge.reqOut to alphaRotateRecharge.reqIn {
    		doc /* A recharge rotation plan agreed between a member due to withdraw and the member replacing it on station. */
    	}

    	flow coverageRedistributionFlow of Common::CoverageRedistributionPlan from alphaRedistributeCoverage.reqOut to bravoRedistributeCoverage.reqIn {
    		doc /* A re-spread of sector assignments agreed as a member leaves, rejoins or is lost. */
    	}

    	flow deconflictionFlow of Common::DeconflictionAdvisory from bravoDeconflictFlight.reqOut to alphaDeconflictFlight.reqIn {
    		doc /* An avoidance advisory exchanged to keep two members apart in the air. */
    	}

    	flow relayFlow of Common::RelayedMessage from alphaRelayThroughNeighbour.reqOut to bravoRelayThroughNeighbour.reqIn {
    		doc /* Traffic one member forwards on behalf of another when a direct path is unavailable. */
    	}

    	flow trackCorrelationFlow of Common::Track from alphaCorrelateTracks.reqOut to bravoCorrelateTracks.reqIn {
    		doc /* An observation offered so two members' sightings of the same object are merged into one track. */
    	}

    	flow trackHandoverFlow of Common::Track from bravoHandOverTrack.reqOut to alphaHandOverTrack.reqIn {
    		doc /* Custody of a track passed from the member that has been carrying it to the member now best placed to. */
    	}

    	flow admissionRequestFlow of Common::MembershipRequest from alphaAdmitMember.admitReqOut to bravoAdmitMember.admitReqIn {
    		doc /* A request to join the mesh, offered by the requesting member and received by an existing member for a decision. */
    	}

    	flow admissionDecisionFlow of Common::MembershipDecision from bravoAdmitMember.admitDecOut to alphaAdmitMember.admitDecIn {
    		doc /* The admission decision returned to the requesting member. */
    	}

    	/* ===================== Exchanges with human actors ===================== */
    	/* Every end here is a two-segment usage.port, never a part.action.port, so the flow survives being carried into the next layer. */

    	flow missionTaskingFlow of Common::MissionTasking from supervisorTaskSurveillanceMission.cmdOut to alphaTaskSurveillanceMission.cmdIn {
    		doc /* The tasked area, its sectors and the mission window, issued by the supervisor. */
    	}

    	flow supervisoryCommandFlow of Common::SupervisoryCommand from supervisorIssueSupervisoryCommand.cmdOut to alphaIssueSupervisoryCommand.cmdIn {
    		doc /* Priorities, a sector to look at more closely, and the reporting threshold, set by the supervisor. */
    	}

    	flow recallFlow of Common::RecallOrder from supervisorRecallToLand.cmdOut to alphaRecallToLand.cmdIn {
    		doc /* An order to recall and land the whole watch asset or one member. */
    	}

    	flow statusPictureFlow of Common::StatusPicture from alphaPresentStatusPicture.cmdOut to supervisorPresentStatusPicture.cmdIn {
    		doc /* Where every member is, what it is doing, how much coverage there is and what is degraded. */
    	}

    	flow detectionReportFlow of Common::DetectionReport from alphaReportDetection.reportOut to analystReportDetection.reportIn {
    		doc /* A detection report carried from the member that made it to the analyst at the operations centre. */
    	}

    	flow ackFlow of Common::ReportAcknowledgement from analystAcknowledgeDetectionReport.ackOut to alphaAcknowledgeDetectionReport.ackIn {
    		doc /* The analyst's acknowledgement of a detection report, returned so nothing is lost across a link gap. */
    	}

    	/* ===================== Allocation of operational activities to entities ===================== */
    	/* Type-level: the definition every member's activity is typed by, and who in general carries it. */

    	allocate HandOverSector to watchAsset;
    	allocate RotateRecharge to watchAsset;
    	allocate RedistributeCoverage to watchAsset;
    	allocate DeconflictFlight to watchAsset;
    	allocate RelayThroughNeighbour to watchAsset;
    	allocate CorrelateTracks to watchAsset;
    	allocate HandOverTrack to watchAsset;
    	allocate AdmitMember to watchAsset;
    	allocate WatchSector to watchAsset;
    	allocate DetectAndClassify to watchAsset;
    	allocate ReportDetection to watchAsset;
    	allocate ReportDetection to opsCentreAnalyst;
    	allocate TaskSurveillanceMission to watchAsset;
    	allocate TaskSurveillanceMission to swarmSupervisor;
    	allocate IssueSupervisoryCommand to watchAsset;
    	allocate IssueSupervisoryCommand to swarmSupervisor;
    	allocate RecallToLand to watchAsset;
    	allocate RecallToLand to swarmSupervisor;
    	allocate PresentStatusPicture to watchAsset;
    	allocate PresentStatusPicture to swarmSupervisor;
    	allocate AcknowledgeDetectionReport to watchAsset;
    	allocate AcknowledgeDetectionReport to opsCentreAnalyst;

    	/* Usage-level: each representative's own performance, allocated to the representative that performs it. */

    	allocate alphaWatchSector to assetAlpha;
    	allocate alphaDetectAndClassify to assetAlpha;
    	allocate alphaReportDetection to assetAlpha;
    	allocate alphaHandOverSector to assetAlpha;
    	allocate alphaRotateRecharge to assetAlpha;
    	allocate alphaRedistributeCoverage to assetAlpha;
    	allocate alphaDeconflictFlight to assetAlpha;
    	allocate alphaRelayThroughNeighbour to assetAlpha;
    	allocate alphaCorrelateTracks to assetAlpha;
    	allocate alphaHandOverTrack to assetAlpha;
    	allocate alphaAdmitMember to assetAlpha;
    	allocate alphaTaskSurveillanceMission to assetAlpha;
    	allocate alphaIssueSupervisoryCommand to assetAlpha;
    	allocate alphaRecallToLand to assetAlpha;
    	allocate alphaPresentStatusPicture to assetAlpha;
    	allocate alphaAcknowledgeDetectionReport to assetAlpha;

    	allocate bravoWatchSector to assetBravo;
    	allocate bravoDetectAndClassify to assetBravo;
    	allocate bravoReportDetection to assetBravo;
    	allocate bravoHandOverSector to assetBravo;
    	allocate bravoRotateRecharge to assetBravo;
    	allocate bravoRedistributeCoverage to assetBravo;
    	allocate bravoDeconflictFlight to assetBravo;
    	allocate bravoRelayThroughNeighbour to assetBravo;
    	allocate bravoCorrelateTracks to assetBravo;
    	allocate bravoHandOverTrack to assetBravo;
    	allocate bravoAdmitMember to assetBravo;
    	allocate bravoTaskSurveillanceMission to assetBravo;
    	allocate bravoIssueSupervisoryCommand to assetBravo;
    	allocate bravoRecallToLand to assetBravo;
    	allocate bravoPresentStatusPicture to assetBravo;
    	allocate bravoAcknowledgeDetectionReport to assetBravo;

    	/* Usage-level: each actor's own performance, allocated to the actor that performs it -- declared beside the actor's part above, never nested inside it. */

    	allocate supervisorTaskSurveillanceMission to swarmSupervisor;
    	allocate supervisorIssueSupervisoryCommand to swarmSupervisor;
    	allocate supervisorRecallToLand to swarmSupervisor;
    	allocate supervisorPresentStatusPicture to swarmSupervisor;
    	allocate analystReportDetection to opsCentreAnalyst;
    	allocate analystAcknowledgeDetectionReport to opsCentreAnalyst;

    	/* ===================== Hazards this layer adds ===================== */

    	package Hazards {
    		doc /* Operational-analysis hazards, stated before any system design exists. */

    		#Hazard requirement CoverageGapDuringHandoverHazard {
    			doc /* If sector handover between two members is not make-before-break, the sector can go briefly unwatched while responsibility transfers between them. */
    			subject asset : WatchAssetMember;
    		}
    	}

    	satisfy Hazards::CoverageGapDuringHandoverHazard by HandOverSector;
    }
}
