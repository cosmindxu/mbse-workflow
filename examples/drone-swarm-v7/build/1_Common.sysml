package SurveillanceDroneSwarm {
    doc /* SurveillanceDroneSwarm — layered model.
           Mission: Take in the operations centre's tasking, supervisory command and recall, and the moving objects in a tasked area of interest, and send back triaged, merged detection reports, tracks, a status picture and a decision record for each report. Stay inside the airspace clearance and work through radio interference, loss of satellite positioning, bad weather and decoys, using a mesh radio, a ground link, recharge points, stored maps and the ground crew.
           Function: SurveillanceDroneSwarm moves the tasked area of interest from unwatched to continuously watched and reported.
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
        metadata def Budget;
    }
    package Common {
        doc /* Shared definitions for every layer of SurveillanceDroneSwarm: what flows, the ports and interfaces it flows through, and the measures of effectiveness with their targets. No behaviour lives here. */

        attribute def Position {
            doc /* A geographic position estimate, in WGS84 with an error bound. */
            attribute latitudeDeg : ScalarValues::Real { doc /* Latitude in degrees */ }
            attribute longitudeDeg : ScalarValues::Real { doc /* Longitude in degrees */ }
            attribute errorMeters : ScalarValues::Real { doc /* Estimated horizontal position error in metres */ }
        }

        attribute def ObjectClass {
            doc /* A classification label: one of the known classes, or Unknown when confidence is below the reporting threshold. */
            attribute label : ScalarValues::String { doc /* The class name, or "Unknown" */ }
        }

        item def DetectionReport {
            doc /* A report of one detected moving object, sent from a drone toward the operations centre. */
            attribute position : Position { doc /* Where the detected object is */ }
            attribute time : ScalarValues::Real { doc /* When the object was detected, in seconds since epoch */ }
            attribute objectClass : ObjectClass { doc /* One of the known classes, or Unknown */ }
            attribute confidence : ScalarValues::Real { doc /* Classifier confidence in objectClass, from 0 to 1 */ }
            attribute sensorId : ScalarValues::String { doc /* The sensor that made the detection */ }
            attribute memberId : ScalarValues::String { doc /* The drone that made the detection */ }
            attribute classifierVersion : ScalarValues::String { doc /* The classifier version that produced the class */ }
            attribute ageSeconds : ScalarValues::Real { doc /* How old the report is, in seconds */ }
        }

        item def Track {
            doc /* A tracked object built from correlated detections, to be merged with the fixed camera network's tracks at the operations centre. */
            attribute trackId : ScalarValues::String { doc /* Identity of the tracked object */ }
            attribute lastSeenTime : ScalarValues::Real { doc /* When the object was last seen, in seconds since epoch */ }
            attribute stale : ScalarValues::Boolean { doc /* Set once nothing has seen the object for 120 seconds */ }
        }

        item def DecisionRecord {
            doc /* The audit record kept for every report. */
            attribute frames : ScalarValues::String { doc /* References to the frames the report came from */ }
            attribute classifierVersion : ScalarValues::String { doc /* The classifier version that classified it */ }
            attribute reportingThreshold : ScalarValues::Real { doc /* The reporting threshold in force when the report was made */ }
            attribute acknowledgedBy : ScalarValues::String { doc /* Who at the operations centre acknowledged the report */ }
        }

        item def CoordinationUpdate {
            doc /* Drone-to-drone coordination traffic on the mesh: handover, rotation, redistribution, deconfliction, relay, track correlation and admission messages. */
            attribute senderId : ScalarValues::String { doc /* The drone sending the update */ }
            attribute topic : ScalarValues::String { doc /* Which coordination matter the update is about */ }
            attribute payloadClassifierVersion : ScalarValues::String { doc /* The sender's classifier version, so version mismatches can be seen */ }
        }

        item def MemberStatus {
            doc /* One drone's status: where it is, what it is doing, its mode and its charge. */
            attribute memberId : ScalarValues::String { doc /* The drone reporting */ }
            attribute memberPosition : Position { doc /* Where the drone is */ }
            attribute activity : ScalarValues::String { doc /* What the drone is doing, for example watching, transiting or recharging */ }
            attribute degradedModes : ScalarValues::String { doc /* Which degraded modes the drone is in */ }
            attribute chargeShare : ScalarValues::Real { doc /* Remaining battery, from 0 to 1 */ }
            attribute classifierVersion : ScalarValues::String { doc /* The classifier version the drone runs */ }
        }

        item def StatusPicture {
            doc /* The operator's picture of the whole swarm. */
            attribute coverageShare : ScalarValues::Real { doc /* Share of the area currently under watch */ }
            attribute airborneCount : ScalarValues::Integer { doc /* Number of drones airborne */ }
            attribute degradedSummary : ScalarValues::String { doc /* What is degraded, across drones and the mesh */ }
        }

        item def MissionTasking {
            doc /* The operations centre's tasking: the area, its sectors and the mission window. */
            attribute areaId : ScalarValues::String { doc /* The area of interest */ }
            attribute sectorCount : ScalarValues::Integer { doc /* How many sectors the area is divided into */ }
            attribute windowStart : ScalarValues::Real { doc /* When the mission starts */ }
            attribute windowEnd : ScalarValues::Real { doc /* When the mission ends */ }
        }

        item def SupervisoryCommand {
            doc /* The operator's supervisory command: priorities, a sector to look at more closely, and the reporting threshold. */
            attribute prioritySector : ScalarValues::String { doc /* A sector to look at more closely */ }
            attribute priorities : ScalarValues::String { doc /* What the operator wants attended to first */ }
            attribute reportingThreshold : ScalarValues::Real { doc /* The least confidence a classification needs before it becomes a report */ }
        }

        item def RecallCommand {
            doc /* An order to recall and land the whole swarm or one drone. */
            attribute targetMemberId : ScalarValues::String { doc /* The drone to recall, or "all" for the whole swarm */ }
        }

        item def ReportAcknowledgement {
            doc /* The operations centre's confirmation that it received a detection report. */
            attribute reportRef : ScalarValues::String { doc /* The report being acknowledged */ }
            attribute acknowledger : ScalarValues::String { doc /* Who acknowledged it */ }
        }

        item def AirspaceClearance {
            doc /* The airspace authority's clearance: where and when the drones may fly. */
            attribute volumeRef : ScalarValues::String { doc /* The cleared airspace volume */ }
            attribute validUntil : ScalarValues::Real { doc /* When the clearance expires */ }
        }

        port def MeshPort {
            doc /* The port a drone uses to exchange coordination traffic with a peer over the mesh radio. */
            out item update : CoordinationUpdate;
        }

        interface def MeshLink {
            doc /* The mesh radio link between two drones, independent of the ground link. */
            end sender : MeshPort;
            end receiver : ~MeshPort;
        }

        port def GroundLinkPort {
            doc /* The drone side of the radio link to the ground station: reports and status go out; commands and acknowledgements come in. */
            out item report : DetectionReport;
            out item status : MemberStatus;
            in item command : SupervisoryCommand;
            in item recall : RecallCommand;
            in item acknowledgement : ReportAcknowledgement;
        }

        interface def GroundLink {
            doc /* The radio link between a drone and the ground station; it is not always available. */
            end drone : GroundLinkPort;
            end station : ~GroundLinkPort;
        }

        port def OperationsPort {
            doc /* The swarm side of the exchange with the operations centre. */
            out item report : DetectionReport;
            out item track : Track;
            out item picture : StatusPicture;
            out item record : DecisionRecord;
            in item tasking : MissionTasking;
            in item command : SupervisoryCommand;
            in item recall : RecallCommand;
            in item acknowledgement : ReportAcknowledgement;
        }

        interface def OperationsLink {
            doc /* The link between the ground station and the operations centre. */
            end swarmSide : OperationsPort;
            end centreSide : ~OperationsPort;
        }

        port def CameraTrackPort {
            doc /* Where the fixed camera network provides its tracks for merging at the operations centre. */
            out item cameraTrack : Track;
        }

        interface def CameraTrackFeed {
            doc /* The feed of camera network tracks into the operations centre's merge. */
            end provider : CameraTrackPort;
            end consumer : ~CameraTrackPort;
        }

        port def AirspacePort {
            doc /* Where the airspace authority provides clearance. */
            out item clearance : AirspaceClearance;
        }

        interface def AirspaceClearanceFeed {
            doc /* The flow of airspace clearance from the authority to the swarm. */
            end authority : AirspacePort;
            end swarmSide : ~AirspacePort;
        }

        #MoE attribute areaUnderWatchShare : ScalarValues::Real {
            doc /* Share of the area under watch at any moment; at least 0.9. */
            require constraint { areaUnderWatchShare >= 0.9 }
        }
        #MoE attribute coverageLossOnMemberLoss : ScalarValues::Real {
            doc /* Share of coverage lost when one drone is lost, before re-spreading; at most 0.25. */
            require constraint { coverageLossOnMemberLoss <= 0.25 }
        }
        #MoE attribute jammedMeshAreaUnderWatchShare : ScalarValues::Real {
            doc /* Share of the area under watch with half the mesh links jammed; at least 0.75. */
            require constraint { jammedMeshAreaUnderWatchShare >= 0.75 }
        }
        #MoE attribute groundLinkLossAreaUnderWatchShare : ScalarValues::Real {
            doc /* Share of the area under watch with the ground link or ground station down. The brief gives no number; the target is set here to its continuous-watch figure of 0.9. */
            require constraint { groundLinkLossAreaUnderWatchShare >= 0.9 }
        }
        #MoE attribute watchEnduranceHours : ScalarValues::Real {
            doc /* Hours the swarm holds the watch before it needs people. The brief gives no number; 24 h is a target set here. */
            require constraint { watchEnduranceHours >= 24 }
        }
        #MoE attribute reportLatencySeconds : ScalarValues::Real {
            doc /* Age of a report when it reaches the operations centre with the link up; at most 60 s. */
            require constraint { reportLatencySeconds <= 60 }
        }
        #MoE attribute positionErrorWithoutGnssMeters : ScalarValues::Real {
            doc /* Position error after 10 minutes without satellite positioning; at most 50 m. */
            require constraint { positionErrorWithoutGnssMeters <= 50 }
        }
        #MoE attribute reportHoldMinutes : ScalarValues::Real {
            doc /* How long a cut-off drone holds its reports; at least 30 minutes. */
            require constraint { reportHoldMinutes >= 30 }
        }
        #MoE attribute reportsLostInLinkGap : ScalarValues::Integer {
            doc /* Reports lost across a link gap; none. */
            require constraint { reportsLostInLinkGap <= 0 }
        }
        #MoE attribute missedDetectionShare : ScalarValues::Real {
            doc /* Share of real objects that go undetected; at most 0.10. */
            require constraint { missedDetectionShare <= 0.1 }
        }
        #MoE attribute falseAlarmsPerHour : ScalarValues::Real {
            doc /* False alarms reaching the operator per hour; at most 2. */
            require constraint { falseAlarmsPerHour <= 2 }
        }
        #MoE attribute operatorAlertsPerHour : ScalarValues::Real {
            doc /* Alerts reaching the operator per hour after triage; at most 20. */
            require constraint { operatorAlertsPerHour <= 20 }
        }
        #MoE attribute acknowledgedReportsThatMatterShare : ScalarValues::Real {
            doc /* Share of acknowledged reports that turn out to matter; at least 0.8. */
            require constraint { acknowledgedReportsThatMatterShare >= 0.8 }
        }
        #MoE attribute onboardClassificationCostUsd : ScalarValues::Real {
            doc /* On-board classification computing cost per drone; at most 300 USD. */
            require constraint { onboardClassificationCostUsd <= 300 }
        }

        #Budget attribute fleetSize : ScalarValues::Integer {
            doc /* Fixed by the brief: 12 drones can be fielded. Held as a requirement, not scored. */
            require constraint { fleetSize <= 12 }
        }
        #Budget attribute operatorSecondsPerAlert : ScalarValues::Real {
            doc /* Fixed by the brief: the operator needs at least 30 s per alert. Held as a requirement, not scored. */
            require constraint { operatorSecondsPerAlert >= 30 }
        }
        #Budget attribute memberFlightEnduranceMinutes : ScalarValues::Real {
            doc /* Fixed by the brief: a drone flies about 40 minutes. Held as a requirement, not scored. */
            require constraint { memberFlightEnduranceMinutes <= 40 }
        }
        #Budget attribute memberRechargeMinutes : ScalarValues::Real {
            doc /* Fixed by the brief: a drone takes about 60 minutes to recharge. Held as a requirement, not scored. */
            require constraint { memberRechargeMinutes >= 60 }
        }
        #Budget attribute areaOfInterestKm2 : ScalarValues::Real {
            doc /* Fixed by the brief: the area of interest is up to 25 km². Held as a requirement, not scored. */
            require constraint { areaOfInterestKm2 <= 25 }
        }
    }
}
