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
        }
        // ── shared definitions asked for by SA ──
        item def MovingObjectsInArea {
        doc /* The objects moving in the watched area that must be detected, classified and reported; the environment input the mission exists to observe. */
        }
        item def SceneConditions {
        doc /* Lighting, weather and deliberately misleading paint or shapes present in the scene, degrading what the sensors can tell apart. */
        }
        item def TriagedAlertStream {
        doc /* The ranked, duplicate-merged stream of what is most likely to matter, sized to what one operator can judge in an hour. */
        }
        // ── shared definitions asked for by SA ──
        item def RadioInterference {
        doc /* a source of interference that may degrade the mesh between drones as well as the link to the operations centre */
        }
        item def SatellitePositioningOutage {
        doc /* an interval during which satellite positioning is unavailable to a drone */
        }
        item def WeatherLimit {
        doc /* the weather condition the swarm is operating in, checked against the wind limit above which it lands */
        }
    }
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
    package SA {
    doc /* System-level architecture of SurveillanceDroneSwarm as a single black box: its boundary ports on the environment, the actors it faces across that boundary, and the functions it performs, each traced to the operational activity it realises. The watchAsset population declared at OA is taken over here as one box; its member definition (SurveillanceDrone) is carried down to LA and is never instantiated at this layer -- no fleet, no representatives, no internal structure. */

    // ===== Actors the system faces across its boundary =====

    #Actor part def SwarmSupervisor {
        doc /* the single operator who tasks, commands, recalls and watches the whole swarm; source of mission tasking, supervisory command and recall, recipient of the status picture */
        out port missionTaskingOut : Common::MissionTasking {
            doc /* mission tasking issued toward the system */
        }
        out port supervisoryCommandOut : Common::SupervisoryCommand {
            doc /* supervisory command issued toward the system */
        }
        out port recallOrderOut : Common::RecallOrder {
            doc /* recall order issued toward the system, at any time */
        }
        in port statusPictureIn : Common::StatusPicture {
            doc /* status picture received from the system */
        }
    }

    #Actor part def OperationsCentreAnalyst {
        doc /* watches feeds and reports, judges what matters, acknowledges each detection report; the one whose attention triage protects */
        out port reportAcknowledgementOut : Common::ReportAcknowledgement {
            doc /* acknowledgement issued for a received detection report */
        }
        in port detectionReportsIn : Common::DetectionReport {
            doc /* detection reports received from the system */
        }
        in port correlatedTracksIn : Common::Track {
            doc /* correlated tracks received from the system, merged here with the fixed camera network's tracks */
        }
        in port triagedAlertStreamIn : Common::TriagedAlert {
            doc /* the triaged, duplicate-merged alert stream received from the system */
        }
        in port decisionRecordIn : Common::DecisionRecord {
            doc /* the decision record received for each report */
        }
    }

    #Actor part def AirspaceAuthority {
        doc /* clears when and where anything may fly; its geofence and window gate every sortie */
        out port airspaceClearanceOut : Common::AirspaceClearance {
            doc /* the cleared volume and window issued to the system */
        }
    }

    #Actor part def OperatingEnvironment {
        doc /* the physical world the swarm watches and flies in: the objects to be detected, the conditions that degrade sensing, radio interference, satellite-positioning outages and the weather it must operate within */
        out port movingObjectsInAreaOut : Common::MovingObjectsInArea {
            doc /* the moving objects present in the watched area */
        }
        out port sceneConditionsOut : Common::SceneConditions {
            doc /* lighting, weather and deliberately misleading paint or shapes */
        }
        out port radioInterferenceOut : Common::RadioInterference {
            doc /* a source of interference degrading the mesh or the ground-station link */
        }
        out port satellitePositioningOutageOut : Common::SatellitePositioningOutage {
            doc /* an interval during which satellite positioning is unavailable */
        }
        out port weatherLimitOut : Common::WeatherLimit {
            doc /* the weather condition the swarm is currently operating in */
        }
    }

    // ===== Carried population member definition (CV-16): the replicable element, never instantiated at SA =====

    #Member part def SurveillanceDrone {
        doc /* the one replicable member of the watchAsset population, the twelve identical drones the system is realised by. Carried at SA as a definition only -- no usage, no fleet, no representatives at this layer, because the system is still one box here. LA instantiates it as the fleet and as coordination/C2 representatives; PA realises it physically. */
        out port meshOut : Common::MeshPeerPort {
            doc /* this member's outgoing mesh link to a peer member */
        }
        in port meshIn : ~Common::MeshPeerPort {
            doc /* this member's incoming mesh link from a peer member, the conjugate of meshOut */
        }
    }

    // ===== The system as one black box =====

    part def SurveillanceDroneSwarmSystem {
        doc /* the SurveillanceDroneSwarm: one black-box system that takes over the watchAsset operational entity (SurveillanceDroneSwarm::OA::watchAsset). It carries the tasked area from unwatched and unreported to continuously watched with acknowledged detection reports at the operations centre. The population that realises it -- twelve identical SurveillanceDrone members -- is carried down to LA as one member definition and is never instantiated here: this box has no internal parts. */

        in port missionTaskingIn : Common::MissionTasking {
            doc /* the area of interest, its sectors and the mission window */
        }
        in port supervisoryCommandIn : Common::SupervisoryCommand {
            doc /* priorities, a sector to look at more closely, and the reporting threshold */
        }
        in port recallOrderIn : Common::RecallOrder {
            doc /* an order to recall and land the whole swarm or one drone */
        }
        in port reportAcknowledgementIn : Common::ReportAcknowledgement {
            doc /* the operations centre confirming each detection report */
        }
        in port movingObjectsInAreaIn : Common::MovingObjectsInArea {
            doc /* the objects the mission is about */
        }
        in port sceneConditionsIn : Common::SceneConditions {
            doc /* conditions that degrade what the sensors can tell apart */
        }
        in port airspaceClearanceIn : Common::AirspaceClearance {
            doc /* the cleared volume and window the system may fly in */
        }
        in port radioInterferenceIn : Common::RadioInterference {
            doc /* interference affecting the mesh or the ground-station link */
        }
        in port satellitePositioningOutageIn : Common::SatellitePositioningOutage {
            doc /* a satellite-positioning outage in effect */
        }
        in port weatherLimitIn : Common::WeatherLimit {
            doc /* the weather the system must operate within */
        }
        out port detectionReportsOut : Common::DetectionReport {
            doc /* position, time, class, confidence and provenance for each detected object */
        }
        out port correlatedTracksOut : Common::Track {
            doc /* one track per object, for merging with the fixed camera network's tracks */
        }
        out port triagedAlertStreamOut : Common::TriagedAlert {
            doc /* what is most likely to matter, first, duplicates merged, sized to one operator */
        }
        out port statusPictureOut : Common::StatusPicture {
            doc /* where every drone is, what it is doing, coverage and what is degraded */
        }
        out port decisionRecordOut : Common::DecisionRecord {
            doc /* for every report: frames, classifier version, threshold in force and who acknowledged it */
        }

        mode : SwarmOperatingMode {
            doc /* the system's operating mode as a whole */
        }
        availability : SwarmAvailabilityState {
            doc /* whether the system as a whole can currently be tasked and is delivering the watch */
        }
    }

    part swarmSupervisor : SwarmSupervisor {
        doc /* the supervisor on duty for this operation, facing the system at its boundary */
    }
    part opsCentreAnalyst : OperationsCentreAnalyst {
        doc /* the analyst on duty at the operations centre, facing the system at its boundary */
    }
    part airspaceAuthority : AirspaceAuthority {
        doc /* the airspace authority governing this operation's area of interest */
    }
    part operatingEnvironment : OperatingEnvironment {
        doc /* the physical environment this operation watches and flies in */
    }
    part surveillanceDroneSwarm : SurveillanceDroneSwarmSystem {
        doc /* the system under design, as one instance for this operation */
    }

    // ===== System ports wired to the actors =====

    connection missionTaskingLink connect surveillanceDroneSwarm.missionTaskingIn to swarmSupervisor.missionTaskingOut {
        doc /* carries mission tasking from the supervisor to the system */
    }
    connection supervisoryCommandLink connect surveillanceDroneSwarm.supervisoryCommandIn to swarmSupervisor.supervisoryCommandOut {
        doc /* carries supervisory command from the supervisor to the system */
    }
    connection recallOrderLink connect surveillanceDroneSwarm.recallOrderIn to swarmSupervisor.recallOrderOut {
        doc /* carries a recall order from the supervisor to the system at any time */
    }
    connection statusPictureLink connect surveillanceDroneSwarm.statusPictureOut to swarmSupervisor.statusPictureIn {
        doc /* carries the status picture from the system to the supervisor */
    }
    connection reportAckLink connect surveillanceDroneSwarm.reportAcknowledgementIn to opsCentreAnalyst.reportAcknowledgementOut {
        doc /* carries the analyst's acknowledgement of each detection report to the system */
    }
    connection detectionReportsLink connect surveillanceDroneSwarm.detectionReportsOut to opsCentreAnalyst.detectionReportsIn {
        doc /* carries detection reports from the system to the analyst */
    }
    connection correlatedTracksLink connect surveillanceDroneSwarm.correlatedTracksOut to opsCentreAnalyst.correlatedTracksIn {
        doc /* carries correlated tracks from the system to the analyst */
    }
    connection triagedAlertLink connect surveillanceDroneSwarm.triagedAlertStreamOut to opsCentreAnalyst.triagedAlertStreamIn {
        doc /* carries the triaged alert stream from the system to the analyst */
    }
    connection decisionRecordLink connect surveillanceDroneSwarm.decisionRecordOut to opsCentreAnalyst.decisionRecordIn {
        doc /* carries the decision record from the system to the analyst */
    }
    connection airspaceClearanceLink connect surveillanceDroneSwarm.airspaceClearanceIn to airspaceAuthority.airspaceClearanceOut {
        doc /* carries airspace clearance from the airspace authority to the system */
    }
    connection movingObjectsLink connect surveillanceDroneSwarm.movingObjectsInAreaIn to operatingEnvironment.movingObjectsInAreaOut {
        doc /* carries the objects present in the area to the system's sensors */
    }
    connection sceneConditionsLink connect surveillanceDroneSwarm.sceneConditionsIn to operatingEnvironment.sceneConditionsOut {
        doc /* carries scene conditions to the system's sensors */
    }
    connection radioInterferenceLink connect surveillanceDroneSwarm.radioInterferenceIn to operatingEnvironment.radioInterferenceOut {
        doc /* carries radio interference exposure to the system */
    }
    connection satOutageLink connect surveillanceDroneSwarm.satellitePositioningOutageIn to operatingEnvironment.satellitePositioningOutageOut {
        doc /* carries satellite-positioning outage exposure to the system */
    }
    connection weatherLimitLink connect surveillanceDroneSwarm.weatherLimitIn to operatingEnvironment.weatherLimitOut {
        doc /* carries the current weather to the system */
    }

    // ===== System modes and states (CV-07) =====
    // SwarmOperatingMode also carries, at this layer, the brief's member modes (NavigationDegraded,
    // SensingDegraded, Isolated, Quarantined) and the fleet mode (MeshDegraded), because the member
    // and the fleet are not instantiated here -- the system is still one box. It also carries the
    // four rules the system never breaks (CV-18): RecallWins, GeofenceBreachEndsWatch,
    // QuarantinedStaysOut and ReturnsWhenIsolated.

    #Mode state def SwarmOperatingMode {
        doc /* the system's operating mode as a whole, abstracted from individual members' duty cycles, which are carried at LA */
        initial start;
        transition start -> Watching;
        state Watching {
            doc /* holding continuous watch over the tasked area */
        }
        state Degraded {
            doc /* operating with reduced coverage or reliability: interference, GNSS outage, weather or member loss */
        }
        state NavigationDegraded {
            doc /* the brief's member mode: navigation is degraded (e.g. a GNSS outage in effect) and position estimates are less trustworthy */
        }
        state SensingDegraded {
            doc /* the brief's member mode: a sensor has degraded and reports drawn from it are marked less reliable */
        }
        state Isolated {
            doc /* the brief's member mode: cut off from the mesh, unable to coordinate with the rest of the swarm */
        }
        state MeshDegraded {
            doc /* the brief's fleet mode: the mesh as a whole is degraded, e.g. by radio interference, and coordination is impaired */
        }
        state AirspaceBreach {
            doc /* outside the cleared volume or window issued by the airspace authority; watch does not resume until landed */
        }
        state Quarantined {
            doc /* the brief's member mode: excluded from coordination on suspicion of not being a genuine member, pending readmission */
        }
        state Recalled {
            doc /* returning to land following a recall order */
        }
        state Grounded {
            doc /* not flying: fully landed, whether recalled, faulted, quarantined, in airspace breach, or awaiting airspace clearance */
        }
        transition Watching -> Degraded;
        transition Degraded -> Watching;
        transition Watching -> NavigationDegraded;
        transition NavigationDegraded -> Watching;
        transition Watching -> SensingDegraded;
        transition SensingDegraded -> Watching;
        transition Watching -> Isolated;
        transition Isolated -> Watching;
        transition Watching -> MeshDegraded;
        transition MeshDegraded -> Watching;
        transition Watching -> AirspaceBreach;
        transition AirspaceBreach -> Grounded;
        transition Watching -> Quarantined;
        transition Quarantined -> Grounded;
        transition Watching -> Recalled;
        transition Degraded -> Recalled;
        transition Recalled -> Grounded;
        transition Grounded -> Watching;

        @SysproseVerification::PropertyPattern {
            doc /* RecallWins: once the swarm is recalled, it does not watch again until it has landed */
            attribute pattern = "absence";
            attribute scope = "between";
            attribute q = "state Recalled";
            attribute r = "state Grounded";
            attribute p = "state Watching";
        }
        @SysproseVerification::PropertyPattern {
            doc /* GeofenceBreachEndsWatch: once the swarm is outside its cleared airspace, it does not watch until it has landed */
            attribute pattern = "absence";
            attribute scope = "between";
            attribute q = "state AirspaceBreach";
            attribute r = "state Grounded";
            attribute p = "state Watching";
        }
        @SysproseVerification::PropertyPattern {
            doc /* QuarantinedStaysOut: once quarantined, the swarm takes no part in watch until it has landed and can be readmitted */
            attribute pattern = "absence";
            attribute scope = "between";
            attribute q = "state Quarantined";
            attribute r = "state Grounded";
            attribute p = "state Watching";
        }
        @SysproseVerification::PropertyPattern {
            doc /* ReturnsWhenIsolated: from any situation the swarm can be in, it can always get back to landed, an isolated member's situation included */
            attribute pattern = "recovery";
            attribute scope = "globally";
            attribute p = "state Grounded";
        }
    }

    #State state def SwarmAvailabilityState {
        doc /* whether the system as a whole can currently be tasked and is delivering the watch */
        initial start;
        transition start -> Nominal;
        state Nominal {
            doc /* available: accepting tasking and commands, delivering reports at target coverage */
        }
        state Constrained {
            doc /* available but operating under an active constraint: interference, GNSS outage, weather or airspace limits */
        }
        state Unavailable {
            doc /* not available: grounded or recalled, not delivering the watch */
        }
        transition Nominal -> Constrained;
        transition Constrained -> Nominal;
        transition Nominal -> Unavailable;
        transition Constrained -> Unavailable;
        transition Unavailable -> Nominal;
    }

    // ===== Coordination functions of the system (#Coordination), each traced to its OA activity, each with a flow =====

    #Coordination action handOverSector : SurveillanceDroneSwarm::OA::HandOverSector {
        doc /* the system's function that settles sector handover between members, entirely within the swarm's boundary; traces to OA::HandOverSector */
        flow sectorHandoverFlow of Common::SectorAssignment from reqOut to reqIn;
    }
    #Coordination action rotateRecharge : SurveillanceDroneSwarm::OA::RotateRecharge {
        doc /* the system's function that settles recharge rotation between members; traces to OA::RotateRecharge */
        flow rechargeRotationFlow of Common::RechargeRotationPlan from reqOut to reqIn;
    }
    #Coordination action redistributeCoverage : SurveillanceDroneSwarm::OA::RedistributeCoverage {
        doc /* the system's function that re-spreads members across sectors as one leaves, rejoins or is lost; traces to OA::RedistributeCoverage */
        flow coverageRedistributionFlow of Common::CoverageRedistributionPlan from reqOut to reqIn;
    }
    #Coordination action deconflictFlight : SurveillanceDroneSwarm::OA::DeconflictFlight {
        doc /* the system's function that keeps members apart in the air; traces to OA::DeconflictFlight */
        flow deconflictionFlow of Common::DeconflictionAdvisory from reqOut to reqIn;
    }
    #Coordination action relayThroughNeighbour : SurveillanceDroneSwarm::OA::RelayThroughNeighbour {
        doc /* the system's function that forwards one member's traffic through another when a direct path is unavailable; traces to OA::RelayThroughNeighbour */
        flow relayFlow of Common::RelayedMessage from reqOut to reqIn;
    }
    #Coordination action correlateTracks : SurveillanceDroneSwarm::OA::CorrelateTracks {
        doc /* the system's function that merges observations of the same object from different members into one track; traces to OA::CorrelateTracks */
        flow trackCorrelationFlow of Common::Track from reqOut to reqIn;
    }
    #Coordination action handOverTrack : SurveillanceDroneSwarm::OA::HandOverTrack {
        doc /* the system's function that passes custody of a track between members; traces to OA::HandOverTrack */
        flow trackHandoverFlow of Common::Track from reqOut to reqIn;
    }
    #Coordination action admitMember : SurveillanceDroneSwarm::OA::AdmitMember {
        doc /* the system's function that decides whether a candidate joins the mesh; traces to OA::AdmitMember */
        flow admissionRequestFlow of Common::MembershipRequest from admitReqOut to admitReqIn;
        flow admissionDecisionFlow of Common::MembershipDecision from admitDecOut to admitDecIn;
    }

    // ===== Command-and-control functions of the system (#C2), each traced to its OA activity, each with a flow =====

    #C2 action taskSurveillanceMission : SurveillanceDroneSwarm::OA::TaskSurveillanceMission {
        doc /* the system's function that takes mission tasking from the supervisor; traces to OA::TaskSurveillanceMission */
        flow missionTaskingFlow of Common::MissionTasking from cmdOut to cmdIn;
    }
    #C2 action issueSupervisoryCommand : SurveillanceDroneSwarm::OA::IssueSupervisoryCommand {
        doc /* the system's function that takes a supervisory command from the supervisor; traces to OA::IssueSupervisoryCommand */
        flow supervisoryCommandFlow of Common::SupervisoryCommand from cmdOut to cmdIn;
    }
    #C2 action recallToLand : SurveillanceDroneSwarm::OA::RecallToLand {
        doc /* the system's function that takes a recall order from the supervisor at any time; traces to OA::RecallToLand */
        flow recallFlow of Common::RecallOrder from cmdOut to cmdIn;
    }
    #C2 action presentStatusPicture : SurveillanceDroneSwarm::OA::PresentStatusPicture {
        doc /* the system's function that assembles and presents the status picture; traces to OA::PresentStatusPicture */
        flow statusPictureFlow of Common::StatusPicture from cmdOut to cmdIn;
    }
    #C2 action acknowledgeDetectionReport : SurveillanceDroneSwarm::OA::AcknowledgeDetectionReport {
        doc /* the system's function that takes the analyst's acknowledgement of a detection report; traces to OA::AcknowledgeDetectionReport */
        flow acknowledgementFlow of Common::ReportAcknowledgement from ackOut to ackIn;
    }

    // ===== Core watch, detect and report functions, each traced to its OA activity =====

    action watchSector : SurveillanceDroneSwarm::OA::WatchSector {
        doc /* the system's function that holds continuous watch over an assigned sector from altitude; traces to OA::WatchSector */
    }
    action detectAndClassify : SurveillanceDroneSwarm::OA::DetectAndClassify {
        doc /* the system's function that detects moving objects and classifies them well enough to say whether they matter, saying Unknown rather than forcing a class; traces to OA::DetectAndClassify */
    }
    action reportDetection : SurveillanceDroneSwarm::OA::ReportDetection {
        doc /* the system's function that carries one detection report to the operations centre; traces to OA::ReportDetection */
        flow detectionReportFlow of Common::DetectionReport from reportOut to reportIn;
    }
    action triageReports {
        doc /* the system's function that ranks and merges detection reports into a bounded alert stream for the operator and keeps a decision record for every report; traces to the OA capability ReportTriageAndDecisionRecord, which has no dedicated OA activity of its own */
        out port triagedAlertOut : Common::TriagedAlert {
            doc /* the triaged alert this function produces */
        }
        out port decisionRecordOut : Common::DecisionRecord {
            doc /* the decision record this function keeps for a report */
        }
    }

    // ===== Explicit traces from every SA function to the OA activity it realises (CV-03) =====
    // The ": OA::X" type ascription above shows specialisation but is not read as a trace by the
    // checker; every function is also traced explicitly here.

    trace watchSector to SurveillanceDroneSwarm::OA::WatchSector;
    trace detectAndClassify to SurveillanceDroneSwarm::OA::DetectAndClassify;
    trace reportDetection to SurveillanceDroneSwarm::OA::ReportDetection;
    trace triageReports to SurveillanceDroneSwarm::OA::ReportTriageAndDecisionRecord;
    trace handOverSector to SurveillanceDroneSwarm::OA::HandOverSector;
    trace rotateRecharge to SurveillanceDroneSwarm::OA::RotateRecharge;
    trace redistributeCoverage to SurveillanceDroneSwarm::OA::RedistributeCoverage;
    trace deconflictFlight to SurveillanceDroneSwarm::OA::DeconflictFlight;
    trace relayThroughNeighbour to SurveillanceDroneSwarm::OA::RelayThroughNeighbour;
    trace correlateTracks to SurveillanceDroneSwarm::OA::CorrelateTracks;
    trace handOverTrack to SurveillanceDroneSwarm::OA::HandOverTrack;
    trace admitMember to SurveillanceDroneSwarm::OA::AdmitMember;
    trace taskSurveillanceMission to SurveillanceDroneSwarm::OA::TaskSurveillanceMission;
    trace issueSupervisoryCommand to SurveillanceDroneSwarm::OA::IssueSupervisoryCommand;
    trace recallToLand to SurveillanceDroneSwarm::OA::RecallToLand;
    trace presentStatusPicture to SurveillanceDroneSwarm::OA::PresentStatusPicture;
    trace acknowledgeDetectionReport to SurveillanceDroneSwarm::OA::AcknowledgeDetectionReport;

    // ===== Allocation: every SA function is allocated to the system =====

    allocate handOverSector to surveillanceDroneSwarm;
    allocate rotateRecharge to surveillanceDroneSwarm;
    allocate redistributeCoverage to surveillanceDroneSwarm;
    allocate deconflictFlight to surveillanceDroneSwarm;
    allocate relayThroughNeighbour to surveillanceDroneSwarm;
    allocate correlateTracks to surveillanceDroneSwarm;
    allocate handOverTrack to surveillanceDroneSwarm;
    allocate admitMember to surveillanceDroneSwarm;
    allocate taskSurveillanceMission to surveillanceDroneSwarm;
    allocate issueSupervisoryCommand to surveillanceDroneSwarm;
    allocate recallToLand to surveillanceDroneSwarm;
    allocate presentStatusPicture to surveillanceDroneSwarm;
    allocate acknowledgeDetectionReport to surveillanceDroneSwarm;
    allocate watchSector to surveillanceDroneSwarm;
    allocate detectAndClassify to surveillanceDroneSwarm;
    allocate reportDetection to surveillanceDroneSwarm;
    allocate triageReports to surveillanceDroneSwarm;

    // ===== Capability traces: every SA capability traces to OA =====

    use case continuousAreaWatch : SurveillanceDroneSwarm::OA::ContinuousAreaWatch {
        doc /* traces to OA::ContinuousAreaWatch; realised by watchSector held across the fleet through rotateRecharge and redistributeCoverage */
    }
    use case detectionClassificationAndReporting : SurveillanceDroneSwarm::OA::DetectionClassificationAndReporting {
        doc /* traces to OA::DetectionClassificationAndReporting; realised by detectAndClassify and reportDetection */
    }
    use case swarmSelfCoordination : SurveillanceDroneSwarm::OA::SwarmSelfCoordination {
        doc /* traces to OA::SwarmSelfCoordination; realised by the eight #Coordination functions */
    }
    use case supervisedCommandAndControl : SurveillanceDroneSwarm::OA::SupervisedCommandAndControl {
        doc /* traces to OA::SupervisedCommandAndControl; realised by the five #C2 functions */
    }
    use case disconnectedOperationAndReconciliation : SurveillanceDroneSwarm::OA::DisconnectedOperationAndReconciliation {
        doc /* traces to OA::DisconnectedOperationAndReconciliation; realised by reportDetection holding reports across a ground-link gap and delivering them once restored */
    }
    use case reportTriageAndDecisionRecord : SurveillanceDroneSwarm::OA::ReportTriageAndDecisionRecord {
        doc /* traces to OA::ReportTriageAndDecisionRecord; realised by triageReports */
    }
    use case gracefulDegradation : SurveillanceDroneSwarm::OA::GracefulDegradation {
        doc /* traces to OA::GracefulDegradation; realised by redistributeCoverage and admitMember bounding coverage loss as members leave, rejoin or are lost */
    }
    use case airspaceComplianceAndSafeRecovery : SurveillanceDroneSwarm::OA::AirspaceComplianceAndSafeRecovery {
        doc /* traces to OA::AirspaceComplianceAndSafeRecovery; realised at this layer by the system's airspaceClearanceIn boundary and its recall/grounded modes, carried in detail by the member's rules at LA */
    }

    // ===== Hazards this layer adds: what the system as a whole can do wrong at its boundary =====

    package Hazards {
        doc /* boundary-level hazards named by the brief, stated once here at SA and satisfied by path below; never restated at LA or PA */

        #Hazard requirement PositionDriftHazard {
            subject sys : SurveillanceDroneSwarmSystem;
            doc /* without satellite positioning, a member's position estimate drifts and its reports place objects in the wrong place */
        }
        #Hazard requirement MeshJammingHazard {
            subject sys : SurveillanceDroneSwarmSystem;
            doc /* interference cuts the links between members, and coordination stalls */
        }
        #Hazard requirement MisclassificationHazard {
            subject sys : SurveillanceDroneSwarmSystem;
            doc /* a detection is reported as the wrong class, or a forced class where Unknown was the truth */
        }
        #Hazard requirement SensingDegradedUnnoticedHazard {
            subject sys : SurveillanceDroneSwarmSystem;
            doc /* a sensor degrades and nobody knows the reports from it are unreliable */
        }
        #Hazard requirement StaleTrackHazard {
            subject sys : SurveillanceDroneSwarmSystem;
            doc /* a track is shown as current after nothing has seen the object for a while */
        }
        #Hazard requirement SpoofedMemberHazard {
            subject sys : SurveillanceDroneSwarmSystem;
            doc /* something that is not one of the members joins the mesh and takes part in coordination */
        }
        #Hazard requirement MixedClassifierVersionsHazard {
            subject sys : SurveillanceDroneSwarmSystem;
            doc /* members run different classifier versions and classify the same object differently */
        }
        #Hazard requirement OperatorOverloadHazard {
            subject sys : SurveillanceDroneSwarmSystem;
            doc /* more alerts reach the operator than they can judge, and they accept what is in front of them */
        }
    }

    satisfy Hazards::PositionDriftHazard by surveillanceDroneSwarm;
    satisfy Hazards::MeshJammingHazard by relayThroughNeighbour;
    satisfy Hazards::MisclassificationHazard by detectAndClassify;
    satisfy Hazards::SensingDegradedUnnoticedHazard by presentStatusPicture;
    satisfy Hazards::StaleTrackHazard by correlateTracks;
    satisfy Hazards::SpoofedMemberHazard by admitMember;
    satisfy Hazards::MixedClassifierVersionsHazard by SurveillanceDroneSwarm::OA::classifierRelease;
    satisfy Hazards::OperatorOverloadHazard by triageReports;

    // ===== Rules the system never breaks (CV-18): stated once here, carried by SwarmOperatingMode above =====

    #Rule requirement RecallWins {
        subject sys : SurveillanceDroneSwarmSystem;
        doc /* RecallWins: once a drone is recalled, it does not watch again until it has landed */
    }
    #Rule requirement ReturnsWhenIsolated {
        subject sys : SurveillanceDroneSwarmSystem;
        doc /* ReturnsWhenIsolated: from any situation a drone can be in, it can always get back to landed, an isolated drone included */
    }
    #Rule requirement GeofenceBreachEndsWatch {
        subject sys : SurveillanceDroneSwarmSystem;
        doc /* GeofenceBreachEndsWatch: once a drone is outside its cleared airspace, it does not watch until it has landed */
    }
    #Rule requirement QuarantinedStaysOut {
        subject sys : SurveillanceDroneSwarmSystem;
        doc /* QuarantinedStaysOut: once a drone is quarantined, it takes no part in coordination until it has been readmitted */
    }

    // ===== Numeric budgets worth stating at the boundary (CV verification knob; non-blocking) =====

    require constraint operatorAlertBudget {
        doc /* the triaged alert stream reaching the operator must not exceed the operator's judged capacity of 20 alerts per hour, per OperatorAttention */
    }
    require constraint areaUnderWatchBudget {
        doc /* the share of the area of interest under watch at any moment must reach at least 0.9, the first measure an architecture is judged on */
    }
        // carried from the layer above; restored by the orchestrator
        allocate taskSurveillanceMission to watchAsset;
        allocate issueSupervisoryCommand to watchAsset;
        allocate recallToLand to watchAsset;
        allocate presentStatusPicture to watchAsset;
        allocate acknowledgeDetectionReport to watchAsset;
        allocate handOverSector to watchAsset;
        allocate rotateRecharge to watchAsset;
        allocate redistributeCoverage to watchAsset;
        allocate deconflictFlight to watchAsset;
        allocate relayThroughNeighbour to watchAsset;
        allocate correlateTracks to watchAsset;
        allocate handOverTrack to watchAsset;
        allocate admitMember to watchAsset;
        allocate handOverSector to system;
        trace handOverSector to SurveillanceDroneSwarm::OA::alphaHandOverSector;
        trace handOverSector to SurveillanceDroneSwarm::OA::bravoHandOverSector;
        allocate rotateRecharge to system;
        trace rotateRecharge to SurveillanceDroneSwarm::OA::alphaRotateRecharge;
        trace rotateRecharge to SurveillanceDroneSwarm::OA::bravoRotateRecharge;
        allocate redistributeCoverage to system;
        trace redistributeCoverage to SurveillanceDroneSwarm::OA::alphaRedistributeCoverage;
        trace redistributeCoverage to SurveillanceDroneSwarm::OA::bravoRedistributeCoverage;
        allocate deconflictFlight to system;
        trace deconflictFlight to SurveillanceDroneSwarm::OA::alphaDeconflictFlight;
        trace deconflictFlight to SurveillanceDroneSwarm::OA::bravoDeconflictFlight;
        allocate relayThroughNeighbour to system;
        trace relayThroughNeighbour to SurveillanceDroneSwarm::OA::alphaRelayThroughNeighbour;
        trace relayThroughNeighbour to SurveillanceDroneSwarm::OA::bravoRelayThroughNeighbour;
        allocate correlateTracks to system;
        trace correlateTracks to SurveillanceDroneSwarm::OA::alphaCorrelateTracks;
        trace correlateTracks to SurveillanceDroneSwarm::OA::bravoCorrelateTracks;
        allocate handOverTrack to system;
        trace handOverTrack to SurveillanceDroneSwarm::OA::alphaHandOverTrack;
        trace handOverTrack to SurveillanceDroneSwarm::OA::bravoHandOverTrack;
        allocate admitMember to system;
        trace admitMember to SurveillanceDroneSwarm::OA::alphaAdmitMember;
        trace admitMember to SurveillanceDroneSwarm::OA::bravoAdmitMember;
        allocate taskSurveillanceMission to system;
        trace taskSurveillanceMission to SurveillanceDroneSwarm::OA::alphaTaskSurveillanceMission;
        trace taskSurveillanceMission to SurveillanceDroneSwarm::OA::bravoTaskSurveillanceMission;
        allocate issueSupervisoryCommand to system;
        trace issueSupervisoryCommand to SurveillanceDroneSwarm::OA::alphaIssueSupervisoryCommand;
        trace issueSupervisoryCommand to SurveillanceDroneSwarm::OA::bravoIssueSupervisoryCommand;
        allocate recallToLand to system;
        trace recallToLand to SurveillanceDroneSwarm::OA::alphaRecallToLand;
        trace recallToLand to SurveillanceDroneSwarm::OA::bravoRecallToLand;
        allocate presentStatusPicture to system;
        trace presentStatusPicture to SurveillanceDroneSwarm::OA::alphaPresentStatusPicture;
        trace presentStatusPicture to SurveillanceDroneSwarm::OA::bravoPresentStatusPicture;
        allocate acknowledgeDetectionReport to system;
        trace acknowledgeDetectionReport to SurveillanceDroneSwarm::OA::alphaAcknowledgeDetectionReport;
        trace acknowledgeDetectionReport to SurveillanceDroneSwarm::OA::bravoAcknowledgeDetectionReport;
    }
}
