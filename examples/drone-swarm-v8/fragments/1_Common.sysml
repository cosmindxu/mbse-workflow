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
        // ── shared definitions asked for by LA ──
        item def CoordinationDirective {
        doc /* a ground-decided instruction to one or more members: a sector assignment, a recharge-rotation slot, a coverage redistribution, a deconfliction constraint, or an admission decision */
        attribute memberId : String {
        doc /* which member the directive addresses, or the fleet as a whole */
        }
        attribute directiveKind : String {
        doc /* which coordination function issued it: handOverSector, rotateRecharge, redistributeCoverage, deconflictFlight or admitMember */
        }
        attribute sector : String {
        doc /* the sector the directive assigns or reassigns, when applicable */
        }
        attribute effectiveTime : String {
        doc /* when the directive takes effect */
        }
        }
        item def MemberStatusReport {
        doc /* a member's periodic status feed to the ground: where it is, what it is doing, and what is degraded -- the raw material the ground assembles into the status picture and uses to decide coordination */
        attribute memberId : String {
        doc /* which member this status is from */
        }
        attribute position : String {
        doc /* the member's last known position */
        }
        attribute mode : String {
        doc /* the member's current mode, e.g. Watching, Recalled, Grounded */
        }
        attribute batteryLevel : Real {
        doc /* remaining flight endurance, used to plan recharge rotation */
        }
        attribute sector : String {
        doc /* the sector currently assigned to this member */
        }
        }
        // ── shared definitions asked for by PA ──
        port def GroundLinkPort { doc /* the port through which a part exchanges traffic over the ground-station link (tasking, command, recall, acknowledgement, reports) */ }
        connection def GroundStationLinkDef { doc /* the physical ground-to-fleet radio link medium: GroundStationLink, not always available, carried by each side's GroundLinkRadioUnitNode */ }
        // ── shared definitions asked for by PA ──
        item def BatteryPack {
        doc /* The physical battery pack swapped at the recharge bay rather than charged in place, giving the fixed 20-minute ground turnaround. */
        attribute mass : ISQ::MassValue {
        doc /* Mass of one battery pack. */
        }
        }
    }
