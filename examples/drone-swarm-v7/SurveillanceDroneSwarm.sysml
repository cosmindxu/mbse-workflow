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
        // ── shared definitions asked for by OA ──
        item def CoordinationMessage {
        doc /* a generic peer-to-peer coordination payload exchanged today between watch assets settling handovers, rotation, redistribution, deconfliction, relay and admission among themselves; carried later over the mesh radio */
        }
        // ── shared definitions asked for by OA ──
        item def DetectionReportsAndTracks { doc /* triaged, de-duplicated detection reports and the tracks they belong to, each with classification or Unknown, position and time */ }
        item def ReportAcknowledgements { doc /* the duty controller's confirmation of receipt of a detection report, naming the acknowledger */ }
        item def DecisionRecords { doc /* the decision record kept for every report sent: source frames, classifier version, reporting threshold and acknowledger */ }
        item def SupervisoryAndRecallCommands { doc /* priorities, a sector to look at more closely, the reporting threshold, and recall-and-land orders for the population or for one member */ }
        item def CameraNetworkTracks { doc /* tracks supplied by the fixed camera network for merging with the watch asset population's reports */ }
        // ── shared definitions asked for by PA ──
        interface def GroundLinkInterface {
        doc /* Physical ground link between a drone and the ground station, carried by GroundLinkRadio hardware at each end; not always available, per resource GroundLinkRadio and constraint RadioInterference. */
        end droneEnd : GroundLinkPort;
        end stationEnd : ~GroundLinkPort;
        }
        // ── shared definitions asked for by PA ──
        doc /* the ground-link radio channel between a drone and the ground station, carried by the GroundLinkRadio resource; can be interrupted by RadioInterference or by a ground-station outage (see groundLinkLossAreaUnderWatchShare) */
        connection def GroundLinkChannel;
    }
    package OA {
    	doc /* Operational Analysis: the entities that carry out area surveillance today, what each does, what they exchange, and the modes the watch asset population can be in — all without naming the system that later takes over the watchAsset role. */

    	/* ---------- core operational action definitions ---------- */

    	action def HoldSectorWatch { doc /* holds continuous watch over an assigned sector of the tasked area of interest */ }
    	action def DetectAndClassifyObjects { doc /* detects moving objects in view and classifies them, or reports Unknown, with position and time */ }
    	action def NavigateAgainstStoredMaps { doc /* keeps a position estimate by matching camera views against stored reference imagery */ }
    	action def ReportDetections { doc /* sends triaged, de-duplicated detection reports and tracks toward the operations centre, and takes in acknowledgement of them */ }
    	action def RecordDecision { doc /* keeps the decision record for every report sent: source frames, classifier version, reporting threshold and acknowledger */ }
    	action def MergeWithCameraNetworkTracks { doc /* merges the watch asset population's reports, tracks and decision records with the fixed camera network's tracks */ }
    	action def ServiceAndRecharge { doc /* recharges and services a watch asset that has come in to land, about 60 minutes */ }
    	action def ProvideCameraTracks { doc /* supplies tracks from the fixed camera network to the operations centre for merging */ }
    	action def JudgeAlerts { doc /* judges the merged, triaged reports and tracks to decide which alerts matter */ }
    	action def ViewStatusPicture { doc /* takes in the status picture contributed by each watch asset: where it is, what it is doing, coverage and degradation */ }

    	/* ---------- coordination between population members (CV-16 defs, reused by every member's activity) ---------- */

    	#Coordination action def HandOverSector { doc /* hands a sector's watch from one member to a peer before the first must leave station */ }
    	#Coordination action def RotateRecharge { doc /* negotiates recharge rotation between members, and with the ground crew, so watch continuity is kept */ }
    	#Coordination action def RedistributeCoverage { doc /* redistributes coverage across the population when a member is lost or added */ }
    	#Coordination action def DeconflictMembers { doc /* deconflicts flight paths between members sharing the same airspace */ }
    	#Coordination action def RelayLink { doc /* relays mesh traffic for a member that is otherwise out of reach */ }
    	#Coordination action def CorrelateTracks { doc /* correlates one member's tracks against a peer's before reporting, to avoid duplicates */ }
    	#Coordination action def HandOverTrack { doc /* hands a track from a member that can no longer see the object to a peer that can */ }
    	#Coordination action def AdmitMember { doc /* admits, or refuses, a member's request to join the mesh and take part in coordination */ }

    	/* ---------- command and control (CV-16 defs, reused by every member's activity) ---------- */

    	#C2 action def TaskMission { doc /* sets the area of interest, its sectors and the mission window for the population */ }
    	#C2 action def CommandSupervision { doc /* issues priorities, a sector to look at more closely, and the reporting threshold */ }
    	#C2 action def RecallAndLand { doc /* orders recall-and-land for the whole population or for one member */ }
    	#C2 action def PresentStatusPicture { doc /* contributes a member's position, activity, coverage and degradation to the fleet status picture */ }
    	#C2 action def AcknowledgeReport { doc /* confirms receipt of a detection report */ }

    	/* ---------- operational modes and states of a watch asset ---------- */

    	#Mode state def WatchAssetMode {
    		doc /* the operating mode of a watch asset: nominal watching, the degraded and constrained conditions the brief names, and landed */
    		initial start;
    		transition start -> Watching;
    		state Watching { doc /* actively holding assigned sector watch under normal conditions */ }
    		state NavigationDegraded { doc /* no satellite positioning; navigating by matching camera views against stored maps */ }
    		state SensingDegraded { doc /* this watch asset's sensors cannot be trusted as they are */ }
    		state Isolated { doc /* cut off from the other watch assets */ }
    		state Quarantined { doc /* failed admission; takes no part in coordination until readmitted */ }
    		state MeshDegraded { doc /* a share of this watch asset's links to its peers is jammed */ }
    		state Landed { doc /* grounded, not watching: recalled, out of cleared airspace, or recharging */ }
    		transition Watching -> NavigationDegraded;
    		transition NavigationDegraded -> Watching;
    		transition Watching -> SensingDegraded;
    		transition SensingDegraded -> Watching;
    		transition Watching -> Isolated;
    		transition Isolated -> Watching;
    		transition Watching -> Quarantined;
    		transition Quarantined -> Watching;
    		transition Watching -> MeshDegraded;
    		transition MeshDegraded -> Watching;
    		transition Watching -> Landed;
    		transition Landed -> Watching;
    	}

    	#State state def WatchAssetStatus {
    		doc /* the coarse platform status of a watch asset, independent of its watch mode */
    		initial start;
    		transition start -> Idle;
    		state Idle { doc /* on the ground, available but not tasked */ }
    		state Active { doc /* airborne and performing tasked activity */ }
    		state Recharging { doc /* at a recharge point being serviced by the ground crew */ }
    		transition Idle -> Active;
    		transition Active -> Idle;
    		transition Active -> Recharging;
    		transition Recharging -> Idle;
    	}

    	/* ---------- entities: stakeholders as operational actors ---------- */

    	#Actor part def DutyController { doc /* the single operator at the operations centre who tasks, supervises and recalls the watch asset population and acknowledges its reports */ }
    	#Actor part def Analysts { doc /* operations centre staff who judge triaged alerts and decide which ones matter */ }
    	#Actor part def OperationsCentre { doc /* commissions surveillance missions and merges the watch asset population's reports with the fixed camera network's tracks */ }
    	#Actor part def AirspaceAuthority { doc /* says when and where the watch assets may fly */ }
    	#Actor part def GroundCrew { doc /* services and recharges the watch assets between sorties */ }
    	#Actor part def FixedCameraNetworkOwner { doc /* runs the existing fixed camera network whose tracks the watch asset population's tracks must merge with */ }
    	#Actor part def ProgrammeSponsor { doc /* pays for the population and holds the per-watch-asset computing cost cap */ }

    	part dutyController : DutyController { doc /* the duty controller on duty for this mission */ }
    	part analysts : Analysts { doc /* the analysts on duty for this mission */ }
    	part operationsCentre : OperationsCentre { doc /* the operations centre for this mission */ }
    	part airspaceAuthority : AirspaceAuthority { doc /* the airspace authority governing this mission's cleared airspace */ }
    	part groundCrew : GroundCrew { doc /* the ground crew servicing this mission's watch assets */ }
    	part fixedCameraNetworkOwner : FixedCameraNetworkOwner { doc /* the fixed camera network owner for this area */ }
    	part programmeSponsor : ProgrammeSponsor { doc /* the programme sponsor for this mission */ }

    	/* ---------- the operational entity the system takes over: a population of identical watch assets ---------- */

    	part def WatchAssetPopulation {
    		doc /* the operational role the system later takes over: a population of identical watch assets that together hold the tasked area under continuous watch, and that settle handovers, rotation, redistribution, deconfliction, relay, track correlation and admission among themselves */
    		state mode : WatchAssetMode;
    		state status : WatchAssetStatus;
    	}

    	part watchAsset : WatchAssetPopulation { doc /* the first representative watch asset: stands for how any one member carries its own share of sector watch, sensing, reporting, command reception and peer coordination */ }
    	part watchAssetPeer : WatchAssetPopulation { doc /* the second representative watch asset: a peer member of the same population, identical to watchAsset, coordinating with it */ }

    	/* ---------- watchAsset's own activities ---------- */

    	action holdWatchA : HoldSectorWatch { doc /* watchAsset holding its assigned sector */ }
    	action detectClassifyA : DetectAndClassifyObjects { doc /* watchAsset detecting and classifying objects in its sector */ }
    	action navigateA : NavigateAgainstStoredMaps { doc /* watchAsset navigating against stored maps */ }
    	action reportA : ReportDetections {
    		doc /* watchAsset reporting its detections and taking in acknowledgement */
    		out port reportsOut : Common::DetectionReportsAndTracks;
    		in port ackIn : Common::ReportAcknowledgements;
    	}
    	action decisionA : RecordDecision {
    		doc /* watchAsset keeping decision records for its own reports */
    		out port decisionsOut : Common::DecisionRecords;
    	}
    	action statusA : PresentStatusPicture {
    		doc /* watchAsset contributing its own status to the fleet status picture */
    		out port statusOut : Common::StatusPicture;
    	}
    	action taskingRecvA : TaskMission {
    		doc /* watchAsset taking in mission tasking */
    		in port taskingIn : Common::MissionTasking;
    	}
    	action supervisionRecvA : CommandSupervision {
    		doc /* watchAsset taking in supervisory direction */
    		in port supervisionIn : Common::SupervisoryAndRecallCommands;
    	}
    	action recallRecvA : RecallAndLand {
    		doc /* watchAsset taking in a recall-and-land order and stopping watch once landed */
    		in port recallIn : Common::SupervisoryAndRecallCommands;
    	}
    	action handOverSectorA : HandOverSector {
    		doc /* watchAsset handing its sector to watchAssetPeer before leaving station */
    		out port msgOut : Common::CoordinationMessage;
    	}
    	action rotateRechargeA : RotateRecharge {
    		doc /* watchAsset negotiating recharge rotation with watchAssetPeer */
    		out port msgOut : Common::CoordinationMessage;
    	}
    	action rechargeGroundA : RotateRecharge {
    		doc /* watchAsset requesting a recharge slot from the ground crew */
    		out port msgOut : Common::CoordinationMessage;
    	}
    	action redistributeCoverageA : RedistributeCoverage {
    		doc /* watchAsset redistributing coverage when the population's membership changes */
    		out port msgOut : Common::CoordinationMessage;
    	}
    	action deconflictMembersA : DeconflictMembers {
    		doc /* watchAsset deconflicting its flight path with watchAssetPeer */
    		out port msgOut : Common::CoordinationMessage;
    	}
    	action relayLinkA : RelayLink {
    		doc /* watchAsset taking in mesh traffic relayed by watchAssetPeer */
    		in port msgIn : Common::CoordinationMessage;
    	}
    	action correlateTracksA : CorrelateTracks {
    		doc /* watchAsset taking in watchAssetPeer's tracks to correlate before reporting */
    		in port trackIn : Common::Track;
    	}
    	action handOverTrackA : HandOverTrack {
    		doc /* watchAsset taking in a track handed over by watchAssetPeer */
    		in port trackIn : Common::Track;
    	}
    	action admitMemberA : AdmitMember {
    		doc /* watchAsset taking in an admission request relayed by watchAssetPeer */
    		in port msgIn : Common::CoordinationMessage;
    	}

    	/* ---------- watchAssetPeer's own activities ---------- */

    	action holdWatchB : HoldSectorWatch { doc /* watchAssetPeer holding its assigned sector */ }
    	action detectClassifyB : DetectAndClassifyObjects { doc /* watchAssetPeer detecting and classifying objects in its sector */ }
    	action navigateB : NavigateAgainstStoredMaps { doc /* watchAssetPeer navigating against stored maps */ }
    	action reportB : ReportDetections {
    		doc /* watchAssetPeer reporting its detections */
    		out port reportsOut : Common::DetectionReportsAndTracks;
    	}
    	action decisionB : RecordDecision {
    		doc /* watchAssetPeer keeping decision records for its own reports */
    		out port decisionsOut : Common::DecisionRecords;
    	}
    	action statusB : PresentStatusPicture {
    		doc /* watchAssetPeer contributing its own status to the fleet status picture */
    		out port statusOut : Common::StatusPicture;
    	}
    	action taskingRecvB : TaskMission {
    		doc /* watchAssetPeer taking in mission tasking */
    		in port taskingIn : Common::MissionTasking;
    	}
    	action supervisionRecvB : CommandSupervision {
    		doc /* watchAssetPeer taking in supervisory direction */
    		in port supervisionIn : Common::SupervisoryAndRecallCommands;
    	}
    	action recallRecvB : RecallAndLand {
    		doc /* watchAssetPeer taking in a recall-and-land order and stopping watch once landed */
    		in port recallIn : Common::SupervisoryAndRecallCommands;
    	}
    	action handOverSectorB : HandOverSector {
    		doc /* watchAssetPeer taking in a sector handover from watchAsset */
    		in port msgIn : Common::CoordinationMessage;
    	}
    	action rotateRechargeB : RotateRecharge {
    		doc /* watchAssetPeer taking in a recharge rotation negotiation from watchAsset */
    		in port msgIn : Common::CoordinationMessage;
    	}
    	action redistributeCoverageB : RedistributeCoverage {
    		doc /* watchAssetPeer taking in a coverage redistribution from watchAsset */
    		in port msgIn : Common::CoordinationMessage;
    	}
    	action deconflictMembersB : DeconflictMembers {
    		doc /* watchAssetPeer taking in deconfliction from watchAsset */
    		in port msgIn : Common::CoordinationMessage;
    	}
    	action relayLinkB : RelayLink {
    		doc /* watchAssetPeer relaying mesh traffic for watchAsset */
    		out port msgOut : Common::CoordinationMessage;
    	}
    	action correlateTracksB : CorrelateTracks {
    		doc /* watchAssetPeer sending its tracks to watchAsset for correlation */
    		out port trackOut : Common::Track;
    	}
    	action handOverTrackB : HandOverTrack {
    		doc /* watchAssetPeer handing a track over to watchAsset */
    		out port trackOut : Common::Track;
    	}
    	action admitMemberB : AdmitMember {
    		doc /* watchAssetPeer relaying an admission request to watchAsset */
    		out port msgOut : Common::CoordinationMessage;
    	}

    	/* ---------- other entities' activities ---------- */

    	action taskMissionAct : TaskMission {
    		doc /* operationsCentre setting the area of interest, its sectors and the mission window */
    		out port taskingOutA : Common::MissionTasking;
    		out port taskingOutB : Common::MissionTasking;
    	}
    	action mergeAct : MergeWithCameraNetworkTracks {
    		doc /* operationsCentre merging the population's reports, tracks and decision records with the fixed camera network's tracks */
    		in port swarmReportsInA : Common::DetectionReportsAndTracks;
    		in port swarmReportsInB : Common::DetectionReportsAndTracks;
    		in port decisionRecordsInA : Common::DecisionRecords;
    		in port decisionRecordsInB : Common::DecisionRecords;
    		in port cameraTracksIn : Common::CameraNetworkTracks;
    		out port mergedOut : Common::DetectionReportsAndTracks;
    	}
    	action commandSupervisionAct : CommandSupervision {
    		doc /* dutyController issuing priorities, a sector to look at more closely, and the reporting threshold */
    		out port supervisionOutA : Common::SupervisoryAndRecallCommands;
    		out port supervisionOutB : Common::SupervisoryAndRecallCommands;
    	}
    	action recallAndLandAct : RecallAndLand {
    		doc /* dutyController ordering recall-and-land */
    		out port recallOutA : Common::SupervisoryAndRecallCommands;
    		out port recallOutB : Common::SupervisoryAndRecallCommands;
    	}
    	action acknowledgeReportAct : AcknowledgeReport {
    		doc /* dutyController confirming receipt of a detection report */
    		out port ackOut : Common::ReportAcknowledgements;
    	}
    	action viewStatusAct : ViewStatusPicture {
    		doc /* dutyController taking in the status picture contributed by each watch asset */
    		in port statusInA : Common::StatusPicture;
    		in port statusInB : Common::StatusPicture;
    	}
    	action serviceAndRechargeAct : ServiceAndRecharge {
    		doc /* groundCrew recharging and servicing a watch asset that has come in to land */
    		in port rechargeIn : Common::CoordinationMessage;
    	}
    	action provideCameraTracksAct : ProvideCameraTracks {
    		doc /* fixedCameraNetworkOwner supplying camera network tracks for merging */
    		out port cameraTracksOut : Common::CameraNetworkTracks;
    	}
    	action judgeAlertsAct : JudgeAlerts {
    		doc /* analysts judging the merged, triaged reports and tracks */
    		in port mergedIn : Common::DetectionReportsAndTracks;
    	}

    	/* ---------- overall operational mission ---------- */

    	#Mission use case def HoldAndReportAreaWatch {
    		subject asset : WatchAssetPopulation;
    		doc /* take in the operations centre's tasking, supervisory command and recall, and the moving objects in the tasked area of interest, and send back triaged, merged detection reports, tracks, a status picture and a decision record for each report */
    	}

    	/* ---------- capabilities the brief names ---------- */

    	#Capability use case def HoldContinuousWatch {
    		subject asset : WatchAssetPopulation;
    		doc /* keep at least one watch asset watching every sector of the tasked area at all times, rotating members through recharge */
    	}
    	#Capability use case def DetectClassifyAndReport {
    		subject asset : WatchAssetPopulation;
    		doc /* detect moving objects, classify them or say Unknown, and report them with position and time */
    	}
    	#Capability use case def CoordinateSwarm {
    		subject asset : WatchAssetPopulation;
    		doc /* let the watch assets settle among themselves, over the mesh, the handovers, rotation, redistribution, deconfliction, relay, track correlation and admission */
    	}
    	#Capability use case def SuperviseSwarm {
    		subject operator : DutyController;
    		doc /* let one operator task, supervise, recall and see the status of the whole population and acknowledge its reports */
    	}
    	#Capability use case def OperateThroughLinkGap {
    		subject asset : WatchAssetPopulation;
    		doc /* keep detecting while cut off from the operations centre, hold the reports and deliver them once the link is back, with none lost */
    	}
    	#Capability use case def StayWithinClearedAirspace {
    		subject asset : WatchAssetPopulation;
    		doc /* fly only inside the cleared airspace and weather limits, and land safely when that is not possible */
    	}
    	#Capability use case def NavigateWithoutSatellitePositioning {
    		subject asset : WatchAssetPopulation;
    		doc /* keep knowing where each watch asset is by matching camera views against stored maps */
    	}
    	#Capability use case def TriageReports {
    		subject asset : WatchAssetPopulation;
    		doc /* rank reports by how likely they are to matter and merge duplicates before they reach the operator */
    	}
    	#Capability use case def KeepDecisionRecord {
    		subject asset : WatchAssetPopulation;
    		doc /* record, for every report, its source frames, classifier version, reporting threshold and acknowledger */
    	}
    	#Capability use case def ManageClassifierVersion {
    		subject asset : WatchAssetPopulation;
    		doc /* keep one classifier version across the population and know which version each watch asset runs */
    	}

    	/* ---------- functional exchanges: command and control ---------- */

    	flow taskingToAFlow of Common::MissionTasking from taskMissionAct.taskingOutA to taskingRecvA.taskingIn;
    	flow taskingToBFlow of Common::MissionTasking from taskMissionAct.taskingOutB to taskingRecvB.taskingIn;
    	flow supervisionToAFlow of Common::SupervisoryAndRecallCommands from commandSupervisionAct.supervisionOutA to supervisionRecvA.supervisionIn;
    	flow supervisionToBFlow of Common::SupervisoryAndRecallCommands from commandSupervisionAct.supervisionOutB to supervisionRecvB.supervisionIn;
    	flow recallToAFlow of Common::SupervisoryAndRecallCommands from recallAndLandAct.recallOutA to recallRecvA.recallIn;
    	flow recallToBFlow of Common::SupervisoryAndRecallCommands from recallAndLandAct.recallOutB to recallRecvB.recallIn;
    	flow ackToAFlow of Common::ReportAcknowledgements from acknowledgeReportAct.ackOut to reportA.ackIn;
    	flow statusAFlow of Common::StatusPicture from statusA.statusOut to viewStatusAct.statusInA;
    	flow statusBFlow of Common::StatusPicture from statusB.statusOut to viewStatusAct.statusInB;

    	/* ---------- functional exchanges: reporting and merging ---------- */

    	flow reportsAFlow of Common::DetectionReportsAndTracks from reportA.reportsOut to mergeAct.swarmReportsInA;
    	flow reportsBFlow of Common::DetectionReportsAndTracks from reportB.reportsOut to mergeAct.swarmReportsInB;
    	flow decisionsAFlow of Common::DecisionRecords from decisionA.decisionsOut to mergeAct.decisionRecordsInA;
    	flow decisionsBFlow of Common::DecisionRecords from decisionB.decisionsOut to mergeAct.decisionRecordsInB;
    	flow cameraTracksFlow of Common::CameraNetworkTracks from provideCameraTracksAct.cameraTracksOut to mergeAct.cameraTracksIn;
    	flow mergedToAnalystsFlow of Common::DetectionReportsAndTracks from mergeAct.mergedOut to judgeAlertsAct.mergedIn;

    	/* ---------- functional exchanges: coordination between the two representative members ---------- */

    	flow handOverSectorFlow of Common::CoordinationMessage from handOverSectorA.msgOut to handOverSectorB.msgIn;
    	flow rotateRechargeFlow of Common::CoordinationMessage from rotateRechargeA.msgOut to rotateRechargeB.msgIn;
    	flow rechargeRequestFlow of Common::CoordinationMessage from rechargeGroundA.msgOut to serviceAndRechargeAct.rechargeIn;
    	flow redistributeCoverageFlow of Common::CoordinationMessage from redistributeCoverageA.msgOut to redistributeCoverageB.msgIn;
    	flow deconflictMembersFlow of Common::CoordinationMessage from deconflictMembersA.msgOut to deconflictMembersB.msgIn;
    	flow relayLinkFlow of Common::CoordinationMessage from relayLinkB.msgOut to relayLinkA.msgIn;
    	flow correlateTracksFlow of Common::Track from correlateTracksB.trackOut to correlateTracksA.trackIn;
    	flow handOverTrackFlow of Common::Track from handOverTrackB.trackOut to handOverTrackA.trackIn;
    	flow admitMemberFlow of Common::CoordinationMessage from admitMemberB.msgOut to admitMemberA.msgIn;

    	/* ---------- allocation of every operational activity to the entity that performs it ---------- */

    	allocate holdWatchA to watchAsset;
    	allocate detectClassifyA to watchAsset;
    	allocate navigateA to watchAsset;
    	allocate reportA to watchAsset;
    	allocate decisionA to watchAsset;
    	allocate statusA to watchAsset;
    	allocate taskingRecvA to watchAsset;
    	allocate supervisionRecvA to watchAsset;
    	allocate recallRecvA to watchAsset;
    	allocate handOverSectorA to watchAsset;
    	allocate rotateRechargeA to watchAsset;
    	allocate rechargeGroundA to watchAsset;
    	allocate redistributeCoverageA to watchAsset;
    	allocate deconflictMembersA to watchAsset;
    	allocate relayLinkA to watchAsset;
    	allocate correlateTracksA to watchAsset;
    	allocate handOverTrackA to watchAsset;
    	allocate admitMemberA to watchAsset;

    	allocate holdWatchB to watchAssetPeer;
    	allocate detectClassifyB to watchAssetPeer;
    	allocate navigateB to watchAssetPeer;
    	allocate reportB to watchAssetPeer;
    	allocate decisionB to watchAssetPeer;
    	allocate statusB to watchAssetPeer;
    	allocate taskingRecvB to watchAssetPeer;
    	allocate supervisionRecvB to watchAssetPeer;
    	allocate recallRecvB to watchAssetPeer;
    	allocate handOverSectorB to watchAssetPeer;
    	allocate rotateRechargeB to watchAssetPeer;
    	allocate redistributeCoverageB to watchAssetPeer;
    	allocate deconflictMembersB to watchAssetPeer;
    	allocate relayLinkB to watchAssetPeer;
    	allocate correlateTracksB to watchAssetPeer;
    	allocate handOverTrackB to watchAssetPeer;
    	allocate admitMemberB to watchAssetPeer;

    	allocate taskMissionAct to operationsCentre;
    	allocate mergeAct to operationsCentre;
    	allocate commandSupervisionAct to dutyController;
    	allocate recallAndLandAct to dutyController;
    	allocate acknowledgeReportAct to dutyController;
    	allocate viewStatusAct to dutyController;
    	allocate serviceAndRechargeAct to groundCrew;
    	allocate provideCameraTracksAct to fixedCameraNetworkOwner;
    	allocate judgeAlertsAct to analysts;
    }
    package SA {
        #prompt part saGuidance {
            doc /* SA: the system is one black-box part with ports. Every function is allocated to the system or to an actor, and traces to at least one operational activity. No design choices here. */
        }

        // fleet-level mode and status of the system (the population, seen as one black box)
        #Mode state def SurveillanceDroneSwarmMode {
            doc /* the fleet-level watch mode of the system: normal coverage, or a share of the mesh links between members jammed. */
            initial start;
            transition start -> Covering;
            state Covering {
                doc /* the fleet is holding continuous watch over the tasked area under normal mesh conditions. */
            }
            state MeshDegraded {
                doc /* a share of the links between drones is jammed; the brief's named fleet mode. */
            }
            transition Covering -> MeshDegraded;
            transition MeshDegraded -> Covering;
        }
        #State state def SurveillanceDroneSwarmStatus {
            doc /* the coarse operating status of the system as a whole, independent of its watch mode. */
            initial start;
            transition start -> Idle;
            state Idle {
                doc /* the system has no active mission tasking. */
            }
            state Tasked {
                doc /* the system has received mission tasking and is conducting the watch. */
            }
            transition Idle -> Tasked;
            transition Tasked -> Idle;
        }

        // the system, black box
        part def SurveillanceDroneSwarmSystem {
            in port taskingIn : Common::MissionTasking;
            in port supervisionIn : Common::SupervisoryAndRecallCommands;
            in port recallIn : Common::SupervisoryAndRecallCommands;
            in port ackIn : Common::ReportAcknowledgements;
            out port reportsOut : Common::DetectionReportsAndTracks;
            out port decisionsOut : Common::DecisionRecords;
            out port statusOut : Common::StatusPicture;
            out port rechargeRequestOut : Common::CoordinationMessage;
            state mode : SurveillanceDroneSwarmMode;
            state status : SurveillanceDroneSwarmStatus;
            doc /* the surveillance drone swarm, one black box: it takes in tasking, supervision, recall and acknowledgement from the operations centre and duty controller, and sends back reports, decision records, status and recharge requests. Movement of objects in the area, camera-network tracks and the merge with them are exchanged between actors and are not modelled as system ports here, since OA allocates the merge to the operations centre. */
        }
        part system : SurveillanceDroneSwarmSystem;
        trace system to SurveillanceDroneSwarm::OA::watchAsset;

        // the population: 12 identical members (CV-16)
        #Mode state def SurveillanceDroneMode {
            doc /* the operating mode of one member drone: nominal watching, the degraded and constrained conditions the brief names, and landed. */
            initial start;
            transition start -> Landed;
            state Landed {
                doc /* grounded, not watching: recalled, out of cleared airspace, quarantined, or recharging. */
            }
            state Watching {
                doc /* actively holding assigned sector watch under normal conditions. */
            }
            state NavigationDegraded {
                doc /* no satellite positioning; navigating by matching camera views against stored maps. */
            }
            state SensingDegraded {
                doc /* this drone's sensors cannot be trusted as they are. */
            }
            state Isolated {
                doc /* cut off from the other drones. */
            }
            state Quarantined {
                doc /* failed admission; takes no part in coordination until readmitted. */
            }
            state Recalled {
                doc /* under a recall-and-land order; no longer watching, heading to land. */
            }
            state OutsideClearedAirspace {
                doc /* outside the airspace authority's cleared limits; no longer watching, heading to land. */
            }
            transition Landed -> Watching;
            transition Watching -> NavigationDegraded;
            transition NavigationDegraded -> Watching;
            transition Watching -> SensingDegraded;
            transition SensingDegraded -> Watching;
            transition Watching -> Isolated;
            transition Isolated -> Landed;
            transition Isolated -> Watching;
            transition Watching -> Quarantined;
            transition Quarantined -> Landed;
            transition Watching -> Recalled;
            transition Recalled -> Landed;
            transition Watching -> OutsideClearedAirspace;
            transition OutsideClearedAirspace -> Landed;

            @SysproseVerification::PropertyPattern {
                doc /* RecallWins: once a drone is recalled, it does not watch again until it has landed. */
                attribute pattern = "absence";
                attribute scope = "between";
                attribute q = "state Recalled";
                attribute r = "state Landed";
                attribute p = "state Watching";
            }
            @SysproseVerification::PropertyPattern {
                doc /* ReturnsWhenIsolated: from any situation a drone can be in, it can always get back to landed; an isolated drone included. */
                attribute pattern = "recovery";
                attribute scope = "globally";
                attribute p = "state Landed";
            }
            @SysproseVerification::PropertyPattern {
                doc /* GeofenceBreachEndsWatch: once a drone is outside its cleared airspace, it does not watch until it has landed. */
                attribute pattern = "absence";
                attribute scope = "between";
                attribute q = "state OutsideClearedAirspace";
                attribute r = "state Landed";
                attribute p = "state Watching";
            }
            @SysproseVerification::PropertyPattern {
                doc /* QuarantinedStaysOut: once a drone is quarantined, it takes no part in coordination until it has been readmitted. */
                attribute pattern = "absence";
                attribute scope = "between";
                attribute q = "state Quarantined";
                attribute r = "state Landed";
                attribute p = "state Watching";
            }
        }
        #State state def SurveillanceDroneStatus {
            doc /* the coarse platform status of one member drone, independent of its watch mode. */
            initial start;
            transition start -> Idle;
            state Idle {
                doc /* on the ground, available but not tasked. */
            }
            state Active {
                doc /* airborne and performing tasked activity. */
            }
            state Recharging {
                doc /* at a recharge point being serviced by the ground crew. */
            }
            transition Idle -> Active;
            transition Active -> Idle;
            transition Active -> Recharging;
            transition Recharging -> Idle;
        }
        #Member part def SurveillanceDrone {
            out port meshOut : Common::MeshPort;
            in port meshIn : ~Common::MeshPort;
            state mode : SurveillanceDroneMode;
            state status : SurveillanceDroneStatus;
            doc /* one member of the system: a single surveillance drone, carrying its own mode and status. At SA the system is still one black box: this definition is carried, not instantiated. */
        }
        #prose part fleetFact {
            doc /* Population: 12 members of SurveillanceDrone, carried by fleet, exchanging through Common::MeshLink. Carried from the brief; instantiated from LA down. */
        }

        // rules the system never breaks (CV-18), stated once at SA, carried by the member's mode machine above
        #Rule requirement RecallWins {
            subject s : SurveillanceDrone;
            doc /* Once a drone is recalled, it does not watch again until it has landed. */
        }
        #Rule requirement ReturnsWhenIsolated {
            subject s : SurveillanceDrone;
            doc /* From any situation a drone can be in, it can always get back to landed; an isolated drone included. */
        }
        #Rule requirement GeofenceBreachEndsWatch {
            subject s : SurveillanceDrone;
            doc /* Once a drone is outside its cleared airspace, it does not watch until it has landed. */
        }
        #Rule requirement QuarantinedStaysOut {
            subject s : SurveillanceDrone;
            doc /* Once a drone is quarantined, it takes no part in coordination until it has been readmitted. */
        }

        // actors: every operational entity the system is not
        #Actor part def DutyController {
            out port supervisionOut : Common::SupervisoryAndRecallCommands;
            out port recallOut : Common::SupervisoryAndRecallCommands;
            out port ackOut : Common::ReportAcknowledgements;
            in port statusIn : Common::StatusPicture;
            doc /* the single operator at the operations centre who tasks, supervises and recalls the swarm and acknowledges its reports, exchanging supervision, recall, acknowledgement and status with the system. */
        }
        part dutyController : DutyController;
        trace dutyController to SurveillanceDroneSwarm::OA::dutyController;
        #Actor part def Analysts {
            doc /* operations centre staff who judge the merged, triaged reports and tracks the operations centre produces; downstream of the operations centre, not an exchange partner of the system itself. */
        }
        part analysts : Analysts;
        trace analysts to SurveillanceDroneSwarm::OA::analysts;
        #Actor part def OperationsCentre {
            out port taskingOut : Common::MissionTasking;
            in port reportsIn : Common::DetectionReportsAndTracks;
            in port decisionsIn : Common::DecisionRecords;
            doc /* commissions surveillance missions, tasks the system with the area of interest and mission window, and takes in the system's triaged reports and decision records for merging with the fixed camera network's tracks. */
        }
        part operationsCentre : OperationsCentre;
        trace operationsCentre to SurveillanceDroneSwarm::OA::operationsCentre;
        #Actor part def AirspaceAuthority {
            doc /* says when and where the drones may fly; constrains the system's cleared airspace as a limit the system's rules must never breach, without a direct data exchange with the system at this layer. */
        }
        part airspaceAuthority : AirspaceAuthority;
        trace airspaceAuthority to SurveillanceDroneSwarm::OA::airspaceAuthority;
        #Actor part def GroundCrew {
            in port rechargeIn : Common::CoordinationMessage;
            doc /* services and recharges the drones between sorties, taking in recharge-slot requests from the system. */
        }
        part groundCrew : GroundCrew;
        trace groundCrew to SurveillanceDroneSwarm::OA::groundCrew;
        #Actor part def FixedCameraNetworkOwner {
            doc /* runs the existing camera network and supplies its tracks to the operations centre for merging with the system's tracks; exchanges with the operations centre, not with the system directly. */
        }
        part fixedCameraNetworkOwner : FixedCameraNetworkOwner;
        trace fixedCameraNetworkOwner to SurveillanceDroneSwarm::OA::fixedCameraNetworkOwner;
        #Actor part def ProgrammeSponsor {
            doc /* pays for the fleet and holds the per-drone computing cost cap; a budget stakeholder with no operational data exchange with the system. */
        }
        part programmeSponsor : ProgrammeSponsor;
        trace programmeSponsor to SurveillanceDroneSwarm::OA::programmeSponsor;

        // capabilities, carried over with the system as subject
        #Capability use case def HoldAndReportAreaWatch {
            subject s : SurveillanceDroneSwarmSystem;
            doc /* take in the operations centre's tasking, supervisory command and recall, and the moving objects in the tasked area of interest, and send back triaged, merged detection reports, tracks, a status picture and a decision record for each report. */
        }
        trace HoldAndReportAreaWatch to SurveillanceDroneSwarm::OA::HoldAndReportAreaWatch;
        #Capability use case def HoldContinuousWatch {
            subject s : SurveillanceDroneSwarmSystem;
            doc /* keep at least one drone watching every sector of the tasked area at all times, rotating drones through recharge. */
        }
        trace HoldContinuousWatch to SurveillanceDroneSwarm::OA::HoldContinuousWatch;
        #Capability use case def DetectClassifyAndReport {
            subject s : SurveillanceDroneSwarmSystem;
            doc /* detect moving objects, classify them or say Unknown, and report them with position and time. */
        }
        trace DetectClassifyAndReport to SurveillanceDroneSwarm::OA::DetectClassifyAndReport;
        #Capability use case def CoordinateSwarm {
            subject s : SurveillanceDroneSwarmSystem;
            doc /* let the drones settle among themselves, over the mesh, the handovers, rotation, redistribution, deconfliction, relay, track correlation and admission. */
        }
        trace CoordinateSwarm to SurveillanceDroneSwarm::OA::CoordinateSwarm;
        #Capability use case def SuperviseSwarm {
            subject s : SurveillanceDroneSwarmSystem;
            doc /* let one operator task, supervise, recall and see the status of the whole swarm and acknowledge its reports. */
        }
        trace SuperviseSwarm to SurveillanceDroneSwarm::OA::SuperviseSwarm;
        #Capability use case def OperateThroughLinkGap {
            subject s : SurveillanceDroneSwarmSystem;
            doc /* keep detecting while cut off from the operations centre, hold the reports and deliver them once the link is back, with none lost. */
        }
        trace OperateThroughLinkGap to SurveillanceDroneSwarm::OA::OperateThroughLinkGap;
        #Capability use case def StayWithinClearedAirspace {
            subject s : SurveillanceDroneSwarmSystem;
            doc /* fly only inside the cleared airspace and weather limits, and land safely when that is not possible. */
        }
        trace StayWithinClearedAirspace to SurveillanceDroneSwarm::OA::StayWithinClearedAirspace;
        #Capability use case def NavigateWithoutSatellitePositioning {
            subject s : SurveillanceDroneSwarmSystem;
            doc /* keep knowing where each drone is by matching camera views against stored maps. */
        }
        trace NavigateWithoutSatellitePositioning to SurveillanceDroneSwarm::OA::NavigateWithoutSatellitePositioning;
        #Capability use case def TriageReports {
            subject s : SurveillanceDroneSwarmSystem;
            doc /* rank reports by how likely they are to matter and merge duplicates before they reach the operator. */
        }
        trace TriageReports to SurveillanceDroneSwarm::OA::TriageReports;
        #Capability use case def KeepDecisionRecord {
            subject s : SurveillanceDroneSwarmSystem;
            doc /* record, for every report, its source frames, classifier version, reporting threshold and acknowledger. */
        }
        trace KeepDecisionRecord to SurveillanceDroneSwarm::OA::KeepDecisionRecord;
        #Capability use case def ManageClassifierVersion {
            subject s : SurveillanceDroneSwarmSystem;
            doc /* keep one classifier version across the fleet and know which version each drone runs. */
        }
        trace ManageClassifierVersion to SurveillanceDroneSwarm::OA::ManageClassifierVersion;

        // functions: one per operational activity, to be split or merged by the author
        action def HoldSectorWatch {
            doc /* holds continuous watch over an assigned sector of the tasked area of interest. */
        }
        action def DetectAndClassifyObjects {
            doc /* detects moving objects in view and classifies them, or reports Unknown, with position and time. */
        }
        action def NavigateAgainstStoredMaps {
            doc /* keeps a position estimate by matching camera views against stored reference imagery. */
        }
        action def ReportDetections {
            doc /* sends triaged, de-duplicated detection reports and tracks toward the operations centre, and takes in acknowledgement of them. */
        }
        action def RecordDecision {
            doc /* keeps the decision record for every report sent: source frames, classifier version, reporting threshold and acknowledger. */
        }
        action def PresentStatusPicture {
            doc /* contributes a drone's position, activity, coverage and degradation to the fleet status picture. */
        }
        action def TaskMission {
            doc /* sets, or takes in, the area of interest, its sectors and the mission window for the fleet. */
        }
        action def CommandSupervision {
            doc /* issues, or takes in, priorities, a sector to look at more closely, and the reporting threshold. */
        }
        action def RecallAndLand {
            doc /* orders, or takes in, recall-and-land for the whole fleet or for one member. */
        }
        action def HandOverSector {
            doc /* hands a sector's watch from one member to a peer before the first must leave station. */
        }
        action def RotateRecharge {
            doc /* negotiates recharge rotation between members, and with the ground crew, so watch continuity is kept. */
        }
        action def RedistributeCoverage {
            doc /* redistributes coverage across the fleet when a member is lost or added. */
        }
        action def DeconflictMembers {
            doc /* deconflicts flight paths between members sharing the same airspace. */
        }
        action def RelayLink {
            doc /* relays mesh traffic for a member that is otherwise out of reach. */
        }
        action def CorrelateTracks {
            doc /* correlates one member's tracks against a peer's before reporting, to avoid duplicates. */
        }
        action def HandOverTrack {
            doc /* hands a track from a member that can no longer see the object to a peer that can. */
        }
        action def AdmitMember {
            doc /* admits, or refuses, a member's request to join the mesh and take part in coordination. */
        }
        action def ManageClassifierVersionFunction {
            doc /* keeps one classifier version across the fleet and knows which version each drone runs; a new SA function tracing to the OA capability of the same name, since OA carries no separate activity for it. Named distinctly from the ManageClassifierVersion capability use case def, which shares SA's scope. */
        }
        action def MergeWithCameraNetworkTracks {
            doc /* merges the fleet's reports, tracks and decision records with the fixed camera network's tracks; performed by the operations centre, not the system. */
        }
        action def AcknowledgeReport {
            doc /* confirms receipt of a detection report; the duty controller sends the confirmation, the system takes it in. */
        }
        action def ViewStatusPicture {
            doc /* takes in the status picture contributed by each member; performed by the duty controller. */
        }
        action def ServiceAndRecharge {
            doc /* recharges and services a drone that has come in to land, about 60 minutes; performed by the ground crew. */
        }
        action def ProvideCameraTracks {
            doc /* supplies tracks from the fixed camera network to the operations centre for merging; performed by the fixed camera network owner. */
        }
        action def JudgeAlerts {
            doc /* judges the merged, triaged reports and tracks to decide which alerts matter; performed by the analysts. */
        }

        // one function for `holdWatchA`, `holdWatchB`: members performing one activity
        action holdSectorWatch : HoldSectorWatch {
            doc /* the system holding continuous watch over its assigned sector; every fleet member is a usage of this one function. */
        }
        allocate holdSectorWatch to system;
        trace holdSectorWatch to SurveillanceDroneSwarm::OA::holdWatchA;
        trace holdSectorWatch to SurveillanceDroneSwarm::OA::holdWatchB;
        // one function for `detectClassifyA`, `detectClassifyB`: members performing one activity
        action detectAndClassifyObjects : DetectAndClassifyObjects {
            doc /* the system detecting and classifying moving objects in its sector, or reporting Unknown. */
        }
        allocate detectAndClassifyObjects to system;
        trace detectAndClassifyObjects to SurveillanceDroneSwarm::OA::detectClassifyA;
        trace detectAndClassifyObjects to SurveillanceDroneSwarm::OA::detectClassifyB;
        satisfy SA::Hazards::MisclassificationHazard by detectAndClassifyObjects;
        // one function for `navigateA`, `navigateB`: members performing one activity
        action navigateAgainstStoredMaps : NavigateAgainstStoredMaps {
            doc /* the system keeping a position estimate against stored maps when satellite positioning is unavailable. */
        }
        allocate navigateAgainstStoredMaps to system;
        trace navigateAgainstStoredMaps to SurveillanceDroneSwarm::OA::navigateA;
        trace navigateAgainstStoredMaps to SurveillanceDroneSwarm::OA::navigateB;
        satisfy SA::Hazards::PositionDriftHazard by navigateAgainstStoredMaps;
        // one function for `reportA`, `reportB`: members performing one activity
        action reportDetections : ReportDetections {
            out reportsOut : Common::DetectionReportsAndTracks;
            in ackIn : Common::ReportAcknowledgements;
            doc /* the system sending triaged, de-duplicated reports and tracks, and taking in acknowledgement of them. */
        }
        allocate reportDetections to system;
        trace reportDetections to SurveillanceDroneSwarm::OA::reportA;
        trace reportDetections to SurveillanceDroneSwarm::OA::reportB;
        satisfy SA::Hazards::OperatorOverloadHazard by reportDetections;
        // one function for `decisionA`, `decisionB`: members performing one activity
        action recordDecision : RecordDecision {
            out decisionsOut : Common::DecisionRecords;
            doc /* the system keeping the decision record for every report it sends. */
        }
        allocate recordDecision to system;
        trace recordDecision to SurveillanceDroneSwarm::OA::decisionA;
        trace recordDecision to SurveillanceDroneSwarm::OA::decisionB;
        // one function for `statusA`, `statusB`: members performing one activity (#C2, named in the brief)
        #C2 action presentStatusPicture : PresentStatusPicture {
            out statusOut : Common::StatusPicture;
            doc /* the system contributing its position, activity, coverage and degradation to the fleet status picture; a command-and-control function of the system. */
        }
        allocate presentStatusPicture to system;
        trace presentStatusPicture to SurveillanceDroneSwarm::OA::statusA;
        trace presentStatusPicture to SurveillanceDroneSwarm::OA::statusB;
        satisfy SA::Hazards::SensingDegradedUnnoticedHazard by presentStatusPicture;
        // one function for `taskingRecvA`, `taskingRecvB`: members performing one activity (#C2, named in the brief)
        #C2 action taskMission : TaskMission {
            in taskingIn : Common::MissionTasking;
            doc /* the system taking in mission tasking from the operations centre; a command-and-control function of the system. */
        }
        allocate taskMission to system;
        trace taskMission to SurveillanceDroneSwarm::OA::taskingRecvA;
        trace taskMission to SurveillanceDroneSwarm::OA::taskingRecvB;
        // one function for `supervisionRecvA`, `supervisionRecvB`: members performing one activity (#C2, named in the brief)
        #C2 action commandSupervision : CommandSupervision {
            in supervisionIn : Common::SupervisoryAndRecallCommands;
            doc /* the system taking in supervisory direction from the duty controller; a command-and-control function of the system. */
        }
        allocate commandSupervision to system;
        trace commandSupervision to SurveillanceDroneSwarm::OA::supervisionRecvA;
        trace commandSupervision to SurveillanceDroneSwarm::OA::supervisionRecvB;
        // one function for `recallRecvA`, `recallRecvB`: members performing one activity (#C2, named in the brief)
        #C2 action recallAndLand : RecallAndLand {
            in recallIn : Common::SupervisoryAndRecallCommands;
            doc /* the system taking in a recall-and-land order and stopping watch once landed; a command-and-control function of the system. */
        }
        allocate recallAndLand to system;
        trace recallAndLand to SurveillanceDroneSwarm::OA::recallRecvA;
        trace recallAndLand to SurveillanceDroneSwarm::OA::recallRecvB;
        // #C2, named in the brief: the system's side of acknowledging a report, distinct from the duty controller's own AcknowledgeReport action
        #C2 action acknowledgeReport : AcknowledgeReport {
            in ackIn : Common::ReportAcknowledgements;
            doc /* the system taking in the duty controller's acknowledgement of a detection report; a command-and-control function of the system, named as the brief names it. */
        }
        allocate acknowledgeReport to system;
        trace acknowledgeReport to SurveillanceDroneSwarm::OA::reportA;
        trace acknowledgeReport to SurveillanceDroneSwarm::OA::acknowledgeReportAct;
        // one function for `handOverSectorA`, `handOverSectorB`: members performing one activity (#Coordination, named in the brief)
        #Coordination action handOverSector : HandOverSector {
            out msgOut : Common::CoordinationMessage;
            in msgIn : Common::CoordinationMessage;
            doc /* the system handing a sector's watch from one member to a peer before the first must leave station; a coordination function of the system. */
        }
        allocate handOverSector to system;
        trace handOverSector to SurveillanceDroneSwarm::OA::handOverSectorA;
        trace handOverSector to SurveillanceDroneSwarm::OA::handOverSectorB;
        // one function for `rotateRechargeA`, `rechargeGroundA`, `rotateRechargeB`: members performing one activity (#Coordination, named in the brief)
        #Coordination action rotateRecharge : RotateRecharge {
            out msgOut : Common::CoordinationMessage;
            in msgIn : Common::CoordinationMessage;
            doc /* the system negotiating recharge rotation between members and with the ground crew; a coordination function of the system. */
        }
        allocate rotateRecharge to system;
        trace rotateRecharge to SurveillanceDroneSwarm::OA::rotateRechargeA;
        trace rotateRecharge to SurveillanceDroneSwarm::OA::rechargeGroundA;
        trace rotateRecharge to SurveillanceDroneSwarm::OA::rotateRechargeB;
        // one function for `redistributeCoverageA`, `redistributeCoverageB`: members performing one activity (#Coordination, named in the brief)
        #Coordination action redistributeCoverage : RedistributeCoverage {
            out msgOut : Common::CoordinationMessage;
            in msgIn : Common::CoordinationMessage;
            doc /* the system redistributing coverage across the fleet when membership changes; a coordination function of the system. */
        }
        allocate redistributeCoverage to system;
        trace redistributeCoverage to SurveillanceDroneSwarm::OA::redistributeCoverageA;
        trace redistributeCoverage to SurveillanceDroneSwarm::OA::redistributeCoverageB;
        // one function for `deconflictMembersA`, `deconflictMembersB`: members performing one activity (#Coordination, named in the brief)
        #Coordination action deconflictMembers : DeconflictMembers {
            out msgOut : Common::CoordinationMessage;
            in msgIn : Common::CoordinationMessage;
            doc /* the system deconflicting flight paths between members sharing the same airspace; a coordination function of the system. */
        }
        allocate deconflictMembers to system;
        trace deconflictMembers to SurveillanceDroneSwarm::OA::deconflictMembersA;
        trace deconflictMembers to SurveillanceDroneSwarm::OA::deconflictMembersB;
        // one function for `relayLinkA`, `relayLinkB`: members performing one activity (#Coordination, named in the brief)
        #Coordination action relayLink : RelayLink {
            in msgIn : Common::CoordinationMessage;
            out msgOut : Common::CoordinationMessage;
            doc /* the system relaying mesh traffic for a member that is otherwise out of reach; a coordination function of the system, mitigating mesh jamming. */
        }
        allocate relayLink to system;
        trace relayLink to SurveillanceDroneSwarm::OA::relayLinkA;
        trace relayLink to SurveillanceDroneSwarm::OA::relayLinkB;
        satisfy SA::Hazards::MeshJammingHazard by relayLink;
        // one function for `correlateTracksA`, `correlateTracksB`: members performing one activity (#Coordination, named in the brief)
        #Coordination action correlateTracks : CorrelateTracks {
            in trackIn : Common::Track;
            out trackOut : Common::Track;
            doc /* the system correlating one member's tracks against a peer's before reporting, to avoid duplicates and stale tracks; a coordination function of the system. */
        }
        allocate correlateTracks to system;
        trace correlateTracks to SurveillanceDroneSwarm::OA::correlateTracksA;
        trace correlateTracks to SurveillanceDroneSwarm::OA::correlateTracksB;
        satisfy SA::Hazards::StaleTrackHazard by correlateTracks;
        // one function for `handOverTrackA`, `handOverTrackB`: members performing one activity (#Coordination, named in the brief)
        #Coordination action handOverTrack : HandOverTrack {
            in trackIn : Common::Track;
            out trackOut : Common::Track;
            doc /* the system handing a track from a member that can no longer see the object to a peer that can; a coordination function of the system. */
        }
        allocate handOverTrack to system;
        trace handOverTrack to SurveillanceDroneSwarm::OA::handOverTrackA;
        trace handOverTrack to SurveillanceDroneSwarm::OA::handOverTrackB;
        // one function for `admitMemberA`, `admitMemberB`: members performing one activity (#Coordination, named in the brief)
        #Coordination action admitMember : AdmitMember {
            in msgIn : Common::CoordinationMessage;
            out msgOut : Common::CoordinationMessage;
            doc /* the system admitting, or refusing, a member's request to join the mesh and take part in coordination; a coordination function of the system, mitigating spoofed members. */
        }
        allocate admitMember to system;
        trace admitMember to SurveillanceDroneSwarm::OA::admitMemberA;
        trace admitMember to SurveillanceDroneSwarm::OA::admitMemberB;
        satisfy SA::Hazards::SpoofedMemberHazard by admitMember;

        // a new system function, not carried from an OA action def: mitigates mixed classifier versions
        action manageClassifierVersion : ManageClassifierVersionFunction {
            doc /* the system keeping one classifier version across the fleet and knowing which version each member runs. */
        }
        allocate manageClassifierVersion to system;
        trace manageClassifierVersion to SurveillanceDroneSwarm::OA::ManageClassifierVersion;
        satisfy SA::Hazards::MixedClassifierVersionsHazard by manageClassifierVersion;

        #C2 action taskMissionAct : TaskMission {
            out taskingOutA : Common::MissionTasking;
            out taskingOutB : Common::MissionTasking;
            doc /* the operations centre setting the area of interest, its sectors and the mission window for the fleet. */
        }
        allocate taskMissionAct to operationsCentre;
        trace taskMissionAct to SurveillanceDroneSwarm::OA::taskMissionAct;
        action mergeAct : MergeWithCameraNetworkTracks {
            in swarmReportsInA : Common::DetectionReportsAndTracks;
            in swarmReportsInB : Common::DetectionReportsAndTracks;
            in decisionRecordsInA : Common::DecisionRecords;
            in decisionRecordsInB : Common::DecisionRecords;
            in cameraTracksIn : Common::CameraNetworkTracks;
            out mergedOut : Common::DetectionReportsAndTracks;
            doc /* the operations centre merging the system's reports, tracks and decision records with the fixed camera network's tracks. */
        }
        allocate mergeAct to operationsCentre;
        trace mergeAct to SurveillanceDroneSwarm::OA::mergeAct;
        #C2 action commandSupervisionAct : CommandSupervision {
            out supervisionOutA : Common::SupervisoryAndRecallCommands;
            out supervisionOutB : Common::SupervisoryAndRecallCommands;
            doc /* the duty controller issuing priorities, a sector to look at more closely, and the reporting threshold. */
        }
        allocate commandSupervisionAct to dutyController;
        trace commandSupervisionAct to SurveillanceDroneSwarm::OA::commandSupervisionAct;
        #C2 action recallAndLandAct : RecallAndLand {
            out recallOutA : Common::SupervisoryAndRecallCommands;
            out recallOutB : Common::SupervisoryAndRecallCommands;
            doc /* the duty controller ordering recall-and-land for the whole fleet or one member. */
        }
        allocate recallAndLandAct to dutyController;
        trace recallAndLandAct to SurveillanceDroneSwarm::OA::recallAndLandAct;
        #C2 action acknowledgeReportAct : AcknowledgeReport {
            out ackOut : Common::ReportAcknowledgements;
            doc /* the duty controller confirming receipt of a detection report. */
        }
        allocate acknowledgeReportAct to dutyController;
        trace acknowledgeReportAct to SurveillanceDroneSwarm::OA::acknowledgeReportAct;
        action viewStatusAct : ViewStatusPicture {
            in statusInA : Common::StatusPicture;
            in statusInB : Common::StatusPicture;
            doc /* the duty controller taking in the status picture contributed by each member. */
        }
        allocate viewStatusAct to dutyController;
        trace viewStatusAct to SurveillanceDroneSwarm::OA::viewStatusAct;
        action serviceAndRechargeAct : ServiceAndRecharge {
            in rechargeIn : Common::CoordinationMessage;
            doc /* the ground crew recharging and servicing a member that has come in to land. */
        }
        allocate serviceAndRechargeAct to groundCrew;
        trace serviceAndRechargeAct to SurveillanceDroneSwarm::OA::serviceAndRechargeAct;
        action provideCameraTracksAct : ProvideCameraTracks {
            out cameraTracksOut : Common::CameraNetworkTracks;
            doc /* the fixed camera network owner supplying camera tracks for merging by the operations centre. */
        }
        allocate provideCameraTracksAct to fixedCameraNetworkOwner;
        trace provideCameraTracksAct to SurveillanceDroneSwarm::OA::provideCameraTracksAct;
        action judgeAlertsAct : JudgeAlerts {
            in mergedIn : Common::DetectionReportsAndTracks;
            doc /* the analysts judging the merged, triaged reports and tracks. */
        }
        allocate judgeAlertsAct to analysts;
        trace judgeAlertsAct to SurveillanceDroneSwarm::OA::judgeAlertsAct;

        // interactions, carried over as functional exchanges
        flow taskingToAFlow of Common::MissionTasking from taskMissionAct::taskingOutA to taskMission::taskingIn;
        flow taskingToBFlow of Common::MissionTasking from taskMissionAct::taskingOutB to taskMission::taskingIn;
        flow supervisionToAFlow of Common::SupervisoryAndRecallCommands from commandSupervisionAct::supervisionOutA to commandSupervision::supervisionIn;
        flow supervisionToBFlow of Common::SupervisoryAndRecallCommands from commandSupervisionAct::supervisionOutB to commandSupervision::supervisionIn;
        flow recallToAFlow of Common::SupervisoryAndRecallCommands from recallAndLandAct::recallOutA to recallAndLand::recallIn;
        flow recallToBFlow of Common::SupervisoryAndRecallCommands from recallAndLandAct::recallOutB to recallAndLand::recallIn;
        flow ackToAFlow of Common::ReportAcknowledgements from acknowledgeReportAct::ackOut to reportDetections::ackIn;
        flow ackToSystemFlow of Common::ReportAcknowledgements from acknowledgeReportAct::ackOut to acknowledgeReport::ackIn;
        flow statusAFlow of Common::StatusPicture from presentStatusPicture::statusOut to viewStatusAct::statusInA;
        flow statusBFlow of Common::StatusPicture from presentStatusPicture::statusOut to viewStatusAct::statusInB;
        flow reportsAFlow of Common::DetectionReportsAndTracks from reportDetections::reportsOut to mergeAct::swarmReportsInA;
        flow reportsBFlow of Common::DetectionReportsAndTracks from reportDetections::reportsOut to mergeAct::swarmReportsInB;
        flow decisionsAFlow of Common::DecisionRecords from recordDecision::decisionsOut to mergeAct::decisionRecordsInA;
        flow decisionsBFlow of Common::DecisionRecords from recordDecision::decisionsOut to mergeAct::decisionRecordsInB;
        flow cameraTracksFlow of Common::CameraNetworkTracks from provideCameraTracksAct::cameraTracksOut to mergeAct::cameraTracksIn;
        flow mergedToAnalystsFlow of Common::DetectionReportsAndTracks from mergeAct::mergedOut to judgeAlertsAct::mergedIn;
        // between members at OA: handOverSectorA::msgOut to handOverSectorB::msgIn
        flow handOverSectorFlow of Common::CoordinationMessage from handOverSector::msgOut to handOverSector::msgIn;
        // between members at OA: rotateRechargeA::msgOut to rotateRechargeB::msgIn
        flow rotateRechargeFlow of Common::CoordinationMessage from rotateRecharge::msgOut to rotateRecharge::msgIn;
        flow rechargeRequestFlow of Common::CoordinationMessage from rotateRecharge::msgOut to serviceAndRechargeAct::rechargeIn;
        // between members at OA: redistributeCoverageA::msgOut to redistributeCoverageB::msgIn
        flow redistributeCoverageFlow of Common::CoordinationMessage from redistributeCoverage::msgOut to redistributeCoverage::msgIn;
        // between members at OA: deconflictMembersA::msgOut to deconflictMembersB::msgIn
        flow deconflictMembersFlow of Common::CoordinationMessage from deconflictMembers::msgOut to deconflictMembers::msgIn;
        // between members at OA: relayLinkB::msgOut to relayLinkA::msgIn
        flow relayLinkFlow of Common::CoordinationMessage from relayLink::msgOut to relayLink::msgIn;
        // between members at OA: correlateTracksB::trackOut to correlateTracksA::trackIn
        flow correlateTracksFlow of Common::Track from correlateTracks::trackOut to correlateTracks::trackIn;
        // between members at OA: handOverTrackB::trackOut to handOverTrackA::trackIn
        flow handOverTrackFlow of Common::Track from handOverTrack::trackOut to handOverTrack::trackIn;
        // between members at OA: admitMemberB::msgOut to admitMemberA::msgIn
        flow admitMemberFlow of Common::CoordinationMessage from admitMember::msgOut to admitMember::msgIn;

        // component exchanges: the system's ports wired to the actors' ports
        connection taskingLink connect system.taskingIn to operationsCentre.taskingOut {
            doc /* carries mission tasking from the operations centre to the system. */
        }
        connection reportsLink connect system.reportsOut to operationsCentre.reportsIn {
            doc /* carries triaged detection reports and tracks from the system to the operations centre. */
        }
        connection decisionsLink connect system.decisionsOut to operationsCentre.decisionsIn {
            doc /* carries decision records from the system to the operations centre. */
        }
        connection supervisionLink connect system.supervisionIn to dutyController.supervisionOut {
            doc /* carries supervisory commands from the duty controller to the system. */
        }
        connection recallLink connect system.recallIn to dutyController.recallOut {
            doc /* carries recall-and-land orders from the duty controller to the system. */
        }
        connection ackLink connect system.ackIn to dutyController.ackOut {
            doc /* carries report acknowledgements from the duty controller to the system. */
        }
        connection statusLink connect system.statusOut to dutyController.statusIn {
            doc /* carries the status picture from the system to the duty controller. */
        }
        connection rechargeLink connect system.rechargeRequestOut to groundCrew.rechargeIn {
            doc /* carries recharge-slot requests from the system to the ground crew. */
        }

        package Hazards {
            doc /* hazards added at SA: risks visible once functions are allocated to the system and actors and their ports are wired. Each is satisfied above by path, by the function that mitigates it. */

            #Hazard requirement PositionDriftHazard {
                subject s : SurveillanceDroneSwarmSystem;
                doc /* Without satellite positioning, a drone's position estimate drifts and its reports place objects in the wrong place. */
            }
            #Hazard requirement MeshJammingHazard {
                subject s : SurveillanceDroneSwarmSystem;
                doc /* Interference cuts the links between drones, and coordination stalls. */
            }
            #Hazard requirement MisclassificationHazard {
                subject s : SurveillanceDroneSwarmSystem;
                doc /* A detection is reported as the wrong class, or given a forced class where Unknown was the truth. */
            }
            #Hazard requirement SensingDegradedUnnoticedHazard {
                subject s : SurveillanceDroneSwarmSystem;
                doc /* A sensor degrades and nobody knows the reports from it are unreliable. */
            }
            #Hazard requirement StaleTrackHazard {
                subject s : SurveillanceDroneSwarmSystem;
                doc /* A track is shown as current after nothing has seen the object for a while. */
            }
            #Hazard requirement SpoofedMemberHazard {
                subject s : SurveillanceDroneSwarmSystem;
                doc /* Something that is not one of the drones joins the mesh and takes part in coordination. */
            }
            #Hazard requirement MixedClassifierVersionsHazard {
                subject s : SurveillanceDroneSwarmSystem;
                doc /* Drones run different classifier versions and classify the same object differently. */
            }
            #Hazard requirement OperatorOverloadHazard {
                subject s : SurveillanceDroneSwarmSystem;
                doc /* More alerts reach the operator than they can judge, and they accept what is in front of them. */
            }
        }
    }
    package LA {
        #prompt part laGuidance {
            doc /* LA: decompose the system into logical components. Every logical function traces to a system function; components exchange through ports; nothing physical is decided yet. */
        }

        // ---- mainComponent's mode/status/configuration state definitions ----
        #Mode state def SwarmMode {
            doc /* the fleet-level watch mode of the system: normal coverage, or a share of the mesh links between members jammed. Restates SA::SurveillanceDroneSwarmMode at LA, tagged #Mode per this run's modes-and-states option. */
            initial start;
            state Covering {
                doc /* the fleet is holding continuous watch over the tasked area under normal mesh conditions. */
            }
            state MeshDegraded {
                doc /* a share of the links between drones is jammed; the brief's named fleet mode. */
            }
            transition start -> Covering;
            transition Covering -> MeshDegraded;
            transition MeshDegraded -> Covering;
        }
        #Configuration state def FleetConfiguration {
            doc /* the same fleet-level watch condition as SwarmMode, restated as a #Configuration state def per CV-16's rule that fleet-level states belong to that kind rather than #Mode; deliberately redundant with SwarmMode so both this run's option and CV-16 are satisfied. */
            initial start;
            state Covering {
                doc /* the fleet is holding continuous watch over the tasked area under normal mesh conditions. */
            }
            state MeshDegraded {
                doc /* a share of the links between drones is jammed; the brief's named fleet mode. */
            }
            transition start -> Covering;
            transition Covering -> MeshDegraded;
            transition MeshDegraded -> Covering;
        }
        #State state def SwarmStatus {
            doc /* the coarse operating status of the system as a whole, independent of its watch mode. Restates SA::SurveillanceDroneSwarmStatus at LA. */
            initial start;
            state Idle {
                doc /* the system has no active mission tasking. */
            }
            state Tasked {
                doc /* the system has received mission tasking and is conducting the watch. */
            }
            transition start -> Idle;
            transition Idle -> Tasked;
            transition Tasked -> Idle;
        }

        // the system, to be decomposed into logical components (next step)
        part def SurveillanceDroneSwarmLogical {
            in port taskingIn : SA::SurveillanceDroneSwarmSystem::taskingIn;
            out port reportsOut : SA::SurveillanceDroneSwarmSystem::reportsOut;
            out port decisionsOut : SA::SurveillanceDroneSwarmSystem::decisionsOut;
            in port supervisionIn : SA::SurveillanceDroneSwarmSystem::supervisionIn;
            in port recallIn : SA::SurveillanceDroneSwarmSystem::recallIn;
            in port ackIn : SA::SurveillanceDroneSwarmSystem::ackIn;
            out port statusOut : SA::SurveillanceDroneSwarmSystem::statusOut;
            out port rechargeRequestOut : SA::SurveillanceDroneSwarmSystem::rechargeRequestOut;

            state mode : SwarmMode;
            state configuration : FleetConfiguration;
            state status : SwarmStatus;

            #Estimate attribute areaUnderWatchShare :> Common::areaUnderWatchShare = 0.92 {
                doc /* worst-case estimate; basis: FleetOfTwelveDrones rotating through sectors and recharge under redistributeCoverage/rotateRecharge keeps a standing majority of sectors watched; target >= 0.9. */
            }
            #Estimate attribute coverageLossOnMemberLoss :> Common::coverageLossOnMemberLoss = 0.2 {
                doc /* worst-case estimate; basis: losing 1 of 12 members costs roughly 1/12 of coverage before redistributeCoverage re-spreads the remaining fleet, plus handover lag; target <= 0.25. */
            }
            #Estimate attribute jammedMeshAreaUnderWatchShare :> Common::jammedMeshAreaUnderWatchShare = 0.78 {
                doc /* worst-case estimate; basis: relayLink lets members reach isolated peers through surviving links when half the mesh is jammed, at some coverage cost; target >= 0.75. */
            }
            #Estimate attribute groundLinkLossAreaUnderWatchShare :> Common::groundLinkLossAreaUnderWatchShare = 0.9 {
                doc /* worst-case estimate; basis: the eight #Coordination functions (handOverSector, rotateRecharge, redistributeCoverage, deconflictMembers, relayLink, correlateTracks, handOverTrack, admitMember) run over MeshRadio, independent of GroundLinkRadio, so coverage should hold when the ground link is down; where they end up allocated is next step's decision and would revise this figure. Target >= 0.9. */
            }
            #Estimate attribute watchEnduranceHours :> Common::watchEnduranceHours = 30 {
                doc /* worst-case estimate; basis: 40-minute sorties against a 60-minute recharge, rotated across 12 members via rotateRecharge, sustains the watch well past a duty shift before ground-crew fatigue becomes the limit; target >= 24 h. */
            }
            #Estimate attribute reportLatencySeconds :> Common::reportLatencySeconds = 45 {
                doc /* worst-case estimate; basis: onboard detection, correlateTracks de-duplication and reportDetections triage add delay before GroundLinkRadio delivery; target <= 60 s. */
            }
            #Estimate attribute positionErrorWithoutGnssMeters :> Common::positionErrorWithoutGnssMeters = 40 {
                doc /* worst-case estimate; basis: navigateAgainstStoredMaps bounds drift by matching camera views to StoredMaps over a 10-minute GNSS outage; target <= 50 m. */
            }
            #Estimate attribute reportHoldMinutes :> Common::reportHoldMinutes = 35 {
                doc /* worst-case estimate; basis: reportDetections buffers reports on a cut-off member with margin above the brief's floor; target >= 30 min. */
            }
            #Estimate attribute reportsLostInLinkGap :> Common::reportsLostInLinkGap = 0 {
                doc /* worst-case estimate; basis: reportDetections holds reports rather than dropping them across a ground-link gap and delivers them once the link returns; target <= 0. */
            }
            #Estimate attribute missedDetectionShare :> Common::missedDetectionShare = 0.08 {
                doc /* worst-case estimate; basis: detectAndClassifyObjects under nominal sensing and continuous watch; target <= 0.1. */
            }
            #Estimate attribute falseAlarmsPerHour :> Common::falseAlarmsPerHour = 1.5 {
                doc /* worst-case estimate; basis: reportDetections triage and manageClassifierVersion consistency hold false alarms under the brief's cap; target <= 2 / h. */
            }
            #Estimate attribute operatorAlertsPerHour :> Common::operatorAlertsPerHour = 18 {
                doc /* worst-case estimate; basis: reportDetections triage and de-duplication keep the alert rate under the operator's 20/h judging limit, with margin; target <= 20 / h. */
            }
            #Estimate attribute acknowledgedReportsThatMatterShare :> Common::acknowledgedReportsThatMatterShare = 0.82 {
                doc /* worst-case estimate; basis: commandSupervision's reporting threshold plus reportDetections triage push relevance above the brief's floor; target >= 0.8. */
            }
            #Estimate attribute onboardClassificationCostUsd :> Common::onboardClassificationCostUsd = 280 {
                doc /* worst-case estimate; basis: manageClassifierVersion keeps one classifier version so no per-member duplicate compute spend is needed, staying under ComputingCostCap; target <= 300 USD. */
            }

            doc /* the system's logical placeholder: one component carrying every LA function this step, its ports mirrored from SA. The decomposition of this component into distinct logical components (sensing, navigation, coordination, reporting) is the next step's job, done several ways and compared; this step fixes the population's structure, its modes and states, the hazards it makes visible and the architecture's worst-case measures of effectiveness. */
        }

        // ---- member mode/status state definitions (CV-18/CV-19, carried from SA) ----
        #Mode state def SurveillanceDroneMode {
            doc /* the operating mode of one member drone: nominal watching, the degraded and constrained conditions the brief names, and landed. Restates SA::SurveillanceDroneMode at LA and carries its four rule properties. */
            initial start;
            state Landed {
                doc /* grounded, not watching: recalled, out of cleared airspace, quarantined, or recharging. */
            }
            state Watching {
                doc /* actively holding assigned sector watch under normal conditions. */
            }
            state NavigationDegraded {
                doc /* no satellite positioning; navigating by matching camera views against stored maps. */
            }
            state SensingDegraded {
                doc /* this drone's sensors cannot be trusted as they are. */
            }
            state Isolated {
                doc /* cut off from the other drones. */
            }
            state Quarantined {
                doc /* failed admission; takes no part in coordination until readmitted. */
            }
            state Recalled {
                doc /* under a recall-and-land order; no longer watching, heading to land. */
            }
            state OutsideClearedAirspace {
                doc /* outside the airspace authority's cleared limits; no longer watching, heading to land. */
            }
            transition start -> Landed;
            transition Landed -> Watching;
            transition Watching -> NavigationDegraded;
            transition NavigationDegraded -> Watching;
            transition Watching -> SensingDegraded;
            transition SensingDegraded -> Watching;
            transition Watching -> Isolated;
            transition Isolated -> Watching;
            transition Isolated -> Landed;
            transition Landed -> Quarantined;
            transition Quarantined -> Landed;
            transition Watching -> Recalled;
            transition Recalled -> Landed;
            transition Watching -> OutsideClearedAirspace;
            transition OutsideClearedAirspace -> Landed;

            @SysproseVerification::PropertyPattern {
                doc /* RecallWins: once a drone is recalled, it does not watch again until it has landed. */
                attribute pattern = "absence";
                attribute scope = "between";
                attribute q = "state Recalled";
                attribute r = "state Landed";
                attribute p = "state Watching";
            }
            @SysproseVerification::PropertyPattern {
                doc /* ReturnsWhenIsolated: from any situation a drone can be in, it can always get back to landed; an isolated drone included. */
                attribute pattern = "recovery";
                attribute scope = "globally";
                attribute p = "state Landed";
            }
            @SysproseVerification::PropertyPattern {
                doc /* GeofenceBreachEndsWatch: once a drone is outside its cleared airspace, it does not watch until it has landed. */
                attribute pattern = "absence";
                attribute scope = "between";
                attribute q = "state OutsideClearedAirspace";
                attribute r = "state Landed";
                attribute p = "state Watching";
            }
            @SysproseVerification::PropertyPattern {
                doc /* QuarantinedStaysOut: once a drone is quarantined, it takes no part in coordination until it has been readmitted. */
                attribute pattern = "absence";
                attribute scope = "between";
                attribute q = "state Quarantined";
                attribute r = "state Landed";
                attribute p = "state Watching";
            }
        }
        #State state def SurveillanceDroneStatus {
            doc /* the coarse platform status of one member drone, independent of its watch mode. Restates SA::SurveillanceDroneStatus at LA. */
            initial start;
            state Idle {
                doc /* on the ground, available but not tasked. */
            }
            state Active {
                doc /* airborne and performing tasked activity. */
            }
            state Recharging {
                doc /* at a recharge point being serviced by the ground crew. */
            }
            transition start -> Idle;
            transition Idle -> Active;
            transition Active -> Recharging;
            transition Recharging -> Idle;
            transition Active -> Idle;
        }

        // the population's replicable member definition (CV-16). Functions-only at this step (layer.functionsOnly): the fleet usage, its representative peers and the peer interface between them are instantiated in the next step's component decomposition, several ways, and compared -- this step keeps every function allocated to the placeholder mainComponent, so no #Coordination/#C2 function is lost in the meantime.
        #prose part fleetFact {
            doc /* Population: 12 members of SurveillanceDrone. Carried from the brief; the #Member part def SurveillanceDrone above declares the replicable element and its peer mesh ports. Per this step's functions-only rule, the fleet usage, its representative pair and the Common::MeshLink peer interface between them are instantiated in the next step's component decomposition rather than here; every function stays allocated to mainComponent in this fragment. */
        }

        // actors, carried over unchanged
        #Actor part def DutyController {
            out port supervisionOut : SA::DutyController::supervisionOut;
            out port recallOut : SA::DutyController::recallOut;
            out port ackOut : SA::DutyController::ackOut;
            in port statusIn : SA::DutyController::statusIn;
            doc /* the single operator at the operations centre who tasks, supervises and recalls the swarm and acknowledges its reports; ports carried unchanged from SA. */
        }
        part dutyController : DutyController;
        trace dutyController to SurveillanceDroneSwarm::SA::dutyController;
        #Actor part def Analysts {
            doc /* operations centre staff who judge the merged, triaged reports and tracks the operations centre produces; no direct port exchange with the system, carried unchanged from SA. */
        }
        part analysts : Analysts;
        trace analysts to SurveillanceDroneSwarm::SA::analysts;
        #Actor part def OperationsCentre {
            out port taskingOut : SA::OperationsCentre::taskingOut;
            in port reportsIn : SA::OperationsCentre::reportsIn;
            in port decisionsIn : SA::OperationsCentre::decisionsIn;
            doc /* commissions surveillance missions, tasks the system with the area of interest and mission window, and takes in its triaged reports and decision records; ports carried unchanged from SA. */
        }
        part operationsCentre : OperationsCentre;
        trace operationsCentre to SurveillanceDroneSwarm::SA::operationsCentre;
        #Actor part def AirspaceAuthority {
            doc /* says when and where the drones may fly; constrains cleared airspace as a limit the members' rules never breach, with no direct port exchange with the system, carried unchanged from SA. */
        }
        part airspaceAuthority : AirspaceAuthority;
        trace airspaceAuthority to SurveillanceDroneSwarm::SA::airspaceAuthority;
        #Actor part def GroundCrew {
            in port rechargeIn : SA::GroundCrew::rechargeIn;
            doc /* services and recharges the drones between sorties, taking in recharge-slot requests; ports carried unchanged from SA. */
        }
        part groundCrew : GroundCrew;
        trace groundCrew to SurveillanceDroneSwarm::SA::groundCrew;
        #Actor part def FixedCameraNetworkOwner {
            doc /* runs the existing camera network and supplies its tracks to the operations centre for merging with the system's tracks; exchanges with the operations centre, not with the system directly, carried unchanged from SA. */
        }
        part fixedCameraNetworkOwner : FixedCameraNetworkOwner;
        trace fixedCameraNetworkOwner to SurveillanceDroneSwarm::SA::fixedCameraNetworkOwner;
        #Actor part def ProgrammeSponsor {
            doc /* pays for the fleet and holds the per-drone computing cost cap; a budget stakeholder with no operational data exchange with the system, carried unchanged from SA. */
        }
        part programmeSponsor : ProgrammeSponsor;
        trace programmeSponsor to SurveillanceDroneSwarm::SA::programmeSponsor;

        // functions, carried over from SA: every one of them has to be realised here
        action def HoldSectorWatch {
            doc /* holding sector watch is the fleet's baseline activity: a member watches its assigned sector, coordinated with peers via handOverSector; realised here as a system-level function on mainComponent pending allocation to a sensing/flight-control logical component next step. */
        }
        action def DetectAndClassifyObjects {
            doc /* detecting and classifying moving objects is performed onboard against the single classifier version manageClassifierVersion keeps current; realised here as a system-level function pending allocation to a perception logical component next step. */
        }
        action def NavigateAgainstStoredMaps {
            doc /* navigation without satellite positioning matches a member's camera view against StoredMaps reference imagery; realised here as a system-level function pending allocation to a navigation logical component next step. */
        }
        action def ReportDetections {
            doc /* triages and de-duplicates member detections into DetectionReportsAndTracks for the operations centre, holding them across a link gap and taking in acknowledgement; realised here as a system-level function pending allocation to a reporting logical component next step. */
        }
        action def RecordDecision {
            doc /* keeps the decision record for every report sent -- its frames, classifier version, reporting threshold and acknowledger; realised here as a system-level function pending allocation to a reporting logical component next step. */
        }
        action def PresentStatusPicture {
            doc /* aggregates each member's position, activity, coverage and degradation into StatusPicture for the duty controller; a command-and-control function realised at system level here, kept ground-facing this step. */
        }
        action def TaskMission {
            doc /* takes in the area of interest, its sectors and the mission window from the operations centre; a command-and-control function realised at system level here, kept ground-facing this step. */
        }
        action def CommandSupervision {
            doc /* takes in priorities, a sector to look at more closely, and the reporting threshold from the duty controller; a command-and-control function realised at system level here, kept ground-facing this step. */
        }
        action def RecallAndLand {
            doc /* takes in recall-and-land for the whole fleet or one member and ends that member's watch until it has landed; a command-and-control function realised at system level here, kept ground-facing this step. */
        }
        action def AcknowledgeReport {
            doc /* takes in the duty controller's acknowledgement of a detection report; a command-and-control function realised at system level here, kept ground-facing this step. */
        }
        action def HandOverSector {
            doc /* hands a sector's watch from one member to a peer, over the mesh, before the first must leave station; a coordination function realised at system level here, mitigating a gap on recall or recharge departure. */
        }
        action def RotateRecharge {
            doc /* negotiates recharge rotation between members and with the ground crew so watch continuity is kept; a coordination function realised at system level here. */
        }
        action def RedistributeCoverage {
            doc /* redistributes coverage across the fleet when a member is lost or added; a coordination function realised at system level here, the main lever for holding coverage despite membership change. */
        }
        action def DeconflictMembers {
            doc /* deconflicts flight paths between members sharing the same airspace, over the mesh; a coordination function realised at system level here. */
        }
        action def RelayLink {
            doc /* relays mesh traffic for a member that is otherwise out of reach; a coordination function realised at system level here, and the main lever for coordination continuity when the ground link is down or the mesh is jammed. */
        }
        action def CorrelateTracks {
            doc /* correlates one member's tracks against a peer's before reporting, to avoid duplicate and stale tracks; a coordination function realised at system level here. */
        }
        action def HandOverTrack {
            doc /* hands a track from a member that can no longer see the object to a peer that can, over the mesh; a coordination function realised at system level here. */
        }
        action def AdmitMember {
            doc /* admits, or refuses, a member's request to join the mesh and take part in coordination, guarding against a device that is not one of the fleet; a coordination function realised at system level here. */
        }
        action def ManageClassifierVersionFunction {
            doc /* keeps one classifier version across the fleet and knows which version each member runs, so members do not classify the same object differently; realised at system level here. */
        }
        action def MergeWithCameraNetworkTracks {
            doc /* merges the fleet's reports, tracks and decision records with the fixed camera network's tracks; performed by the operations centre actor, unchanged from SA. */
        }
        action def ViewStatusPicture {
            doc /* takes in the status picture contributed by each member; performed by the duty controller actor, unchanged from SA. */
        }
        action def ServiceAndRecharge {
            doc /* recharges and services a drone that has come in to land, about 60 minutes; performed by the ground crew actor, unchanged from SA. */
        }
        action def ProvideCameraTracks {
            doc /* supplies tracks from the fixed camera network to the operations centre for merging; performed by the fixed camera network owner actor, unchanged from SA. */
        }
        action def JudgeAlerts {
            doc /* judges the merged, triaged reports and tracks to decide which alerts matter; performed by the analysts actor, unchanged from SA. */
        }
        action holdSectorWatch : HoldSectorWatch;
        trace holdSectorWatch to SurveillanceDroneSwarm::SA::holdSectorWatch;
        action detectAndClassifyObjects : DetectAndClassifyObjects;
        trace detectAndClassifyObjects to SurveillanceDroneSwarm::SA::detectAndClassifyObjects;
        action navigateAgainstStoredMaps : NavigateAgainstStoredMaps;
        trace navigateAgainstStoredMaps to SurveillanceDroneSwarm::SA::navigateAgainstStoredMaps;
        action reportDetections : ReportDetections {
            out reportsOut : Common::DetectionReportsAndTracks;
            in ackIn : Common::ReportAcknowledgements;
        }
        trace reportDetections to SurveillanceDroneSwarm::SA::reportDetections;
        action recordDecision : RecordDecision {
            out decisionsOut : Common::DecisionRecords;
        }
        trace recordDecision to SurveillanceDroneSwarm::SA::recordDecision;
        #C2 action presentStatusPicture : PresentStatusPicture {
            out statusOut : Common::StatusPicture;
        }
        trace presentStatusPicture to SurveillanceDroneSwarm::SA::presentStatusPicture;
        #C2 action taskMission : TaskMission {
            in taskingIn : Common::MissionTasking;
        }
        trace taskMission to SurveillanceDroneSwarm::SA::taskMission;
        #C2 action commandSupervision : CommandSupervision {
            in supervisionIn : Common::SupervisoryAndRecallCommands;
        }
        trace commandSupervision to SurveillanceDroneSwarm::SA::commandSupervision;
        #C2 action recallAndLand : RecallAndLand {
            in recallIn : Common::SupervisoryAndRecallCommands;
        }
        trace recallAndLand to SurveillanceDroneSwarm::SA::recallAndLand;
        #C2 action acknowledgeReport : AcknowledgeReport {
            in ackIn : Common::ReportAcknowledgements;
        }
        trace acknowledgeReport to SurveillanceDroneSwarm::SA::acknowledgeReport;
        #Coordination action handOverSector : HandOverSector {
            out msgOut : Common::CoordinationMessage;
            in msgIn : Common::CoordinationMessage;
        }
        trace handOverSector to SurveillanceDroneSwarm::SA::handOverSector;
        #Coordination action rotateRecharge : RotateRecharge {
            out msgOut : Common::CoordinationMessage;
            in msgIn : Common::CoordinationMessage;
        }
        trace rotateRecharge to SurveillanceDroneSwarm::SA::rotateRecharge;
        #Coordination action redistributeCoverage : RedistributeCoverage {
            out msgOut : Common::CoordinationMessage;
            in msgIn : Common::CoordinationMessage;
        }
        trace redistributeCoverage to SurveillanceDroneSwarm::SA::redistributeCoverage;
        #Coordination action deconflictMembers : DeconflictMembers {
            out msgOut : Common::CoordinationMessage;
            in msgIn : Common::CoordinationMessage;
        }
        trace deconflictMembers to SurveillanceDroneSwarm::SA::deconflictMembers;
        #Coordination action relayLink : RelayLink {
            in msgIn : Common::CoordinationMessage;
            out msgOut : Common::CoordinationMessage;
        }
        trace relayLink to SurveillanceDroneSwarm::SA::relayLink;
        #Coordination action correlateTracks : CorrelateTracks {
            in trackIn : Common::Track;
            out trackOut : Common::Track;
        }
        trace correlateTracks to SurveillanceDroneSwarm::SA::correlateTracks;
        #Coordination action handOverTrack : HandOverTrack {
            in trackIn : Common::Track;
            out trackOut : Common::Track;
        }
        trace handOverTrack to SurveillanceDroneSwarm::SA::handOverTrack;
        #Coordination action admitMember : AdmitMember {
            in msgIn : Common::CoordinationMessage;
            out msgOut : Common::CoordinationMessage;
        }
        trace admitMember to SurveillanceDroneSwarm::SA::admitMember;
        action manageClassifierVersion : ManageClassifierVersionFunction;
        trace manageClassifierVersion to SurveillanceDroneSwarm::SA::manageClassifierVersion;
        #C2 action taskMissionAct : TaskMission {
            out taskingOutA : Common::MissionTasking;
            out taskingOutB : Common::MissionTasking;
        }
        allocate taskMissionAct to operationsCentre;
        trace taskMissionAct to SurveillanceDroneSwarm::SA::taskMissionAct;
        action mergeAct : MergeWithCameraNetworkTracks {
            in swarmReportsInA : Common::DetectionReportsAndTracks;
            in swarmReportsInB : Common::DetectionReportsAndTracks;
            in decisionRecordsInA : Common::DecisionRecords;
            in decisionRecordsInB : Common::DecisionRecords;
            in cameraTracksIn : Common::CameraNetworkTracks;
            out mergedOut : Common::DetectionReportsAndTracks;
        }
        allocate mergeAct to operationsCentre;
        trace mergeAct to SurveillanceDroneSwarm::SA::mergeAct;
        #C2 action commandSupervisionAct : CommandSupervision {
            out supervisionOutA : Common::SupervisoryAndRecallCommands;
            out supervisionOutB : Common::SupervisoryAndRecallCommands;
        }
        allocate commandSupervisionAct to dutyController;
        trace commandSupervisionAct to SurveillanceDroneSwarm::SA::commandSupervisionAct;
        #C2 action recallAndLandAct : RecallAndLand {
            out recallOutA : Common::SupervisoryAndRecallCommands;
            out recallOutB : Common::SupervisoryAndRecallCommands;
        }
        allocate recallAndLandAct to dutyController;
        trace recallAndLandAct to SurveillanceDroneSwarm::SA::recallAndLandAct;
        #C2 action acknowledgeReportAct : AcknowledgeReport {
            out ackOut : Common::ReportAcknowledgements;
        }
        allocate acknowledgeReportAct to dutyController;
        trace acknowledgeReportAct to SurveillanceDroneSwarm::SA::acknowledgeReportAct;
        action viewStatusAct : ViewStatusPicture {
            in statusInA : Common::StatusPicture;
            in statusInB : Common::StatusPicture;
        }
        allocate viewStatusAct to dutyController;
        trace viewStatusAct to SurveillanceDroneSwarm::SA::viewStatusAct;
        action serviceAndRechargeAct : ServiceAndRecharge {
            in rechargeIn : Common::CoordinationMessage;
        }
        allocate serviceAndRechargeAct to groundCrew;
        trace serviceAndRechargeAct to SurveillanceDroneSwarm::SA::serviceAndRechargeAct;
        action provideCameraTracksAct : ProvideCameraTracks {
            out cameraTracksOut : Common::CameraNetworkTracks;
        }
        allocate provideCameraTracksAct to fixedCameraNetworkOwner;
        trace provideCameraTracksAct to SurveillanceDroneSwarm::SA::provideCameraTracksAct;
        action judgeAlertsAct : JudgeAlerts {
            in mergedIn : Common::DetectionReportsAndTracks;
        }
        allocate judgeAlertsAct to analysts;
        trace judgeAlertsAct to SurveillanceDroneSwarm::SA::judgeAlertsAct;

        // interactions, carried over as functional exchanges
        flow taskingToAFlow of Common::MissionTasking from taskMissionAct::taskingOutA to taskMission::taskingIn;
        flow taskingToBFlow of Common::MissionTasking from taskMissionAct::taskingOutB to taskMission::taskingIn;
        flow supervisionToAFlow of Common::SupervisoryAndRecallCommands from commandSupervisionAct::supervisionOutA to commandSupervision::supervisionIn;
        flow supervisionToBFlow of Common::SupervisoryAndRecallCommands from commandSupervisionAct::supervisionOutB to commandSupervision::supervisionIn;
        flow recallToAFlow of Common::SupervisoryAndRecallCommands from recallAndLandAct::recallOutA to recallAndLand::recallIn;
        flow recallToBFlow of Common::SupervisoryAndRecallCommands from recallAndLandAct::recallOutB to recallAndLand::recallIn;
        flow ackToAFlow of Common::ReportAcknowledgements from acknowledgeReportAct::ackOut to reportDetections::ackIn;
        flow ackToSystemFlow of Common::ReportAcknowledgements from acknowledgeReportAct::ackOut to acknowledgeReport::ackIn;
        flow statusAFlow of Common::StatusPicture from presentStatusPicture::statusOut to viewStatusAct::statusInA;
        flow statusBFlow of Common::StatusPicture from presentStatusPicture::statusOut to viewStatusAct::statusInB;
        flow reportsAFlow of Common::DetectionReportsAndTracks from reportDetections::reportsOut to mergeAct::swarmReportsInA;
        flow reportsBFlow of Common::DetectionReportsAndTracks from reportDetections::reportsOut to mergeAct::swarmReportsInB;
        flow decisionsAFlow of Common::DecisionRecords from recordDecision::decisionsOut to mergeAct::decisionRecordsInA;
        flow decisionsBFlow of Common::DecisionRecords from recordDecision::decisionsOut to mergeAct::decisionRecordsInB;
        flow cameraTracksFlow of Common::CameraNetworkTracks from provideCameraTracksAct::cameraTracksOut to mergeAct::cameraTracksIn;
        flow mergedToAnalystsFlow of Common::DetectionReportsAndTracks from mergeAct::mergedOut to judgeAlertsAct::mergedIn;
        flow handOverSectorFlow of Common::CoordinationMessage from handOverSector::msgOut to handOverSector::msgIn;
        flow rotateRechargeFlow of Common::CoordinationMessage from rotateRecharge::msgOut to rotateRecharge::msgIn;
        flow rechargeRequestFlow of Common::CoordinationMessage from rotateRecharge::msgOut to serviceAndRechargeAct::rechargeIn;
        flow redistributeCoverageFlow of Common::CoordinationMessage from redistributeCoverage::msgOut to redistributeCoverage::msgIn;
        flow deconflictMembersFlow of Common::CoordinationMessage from deconflictMembers::msgOut to deconflictMembers::msgIn;
        flow relayLinkFlow of Common::CoordinationMessage from relayLink::msgOut to relayLink::msgIn;
        flow correlateTracksFlow of Common::Track from correlateTracks::trackOut to correlateTracks::trackIn;
        flow handOverTrackFlow of Common::Track from handOverTrack::trackOut to handOverTrack::trackIn;
        flow admitMemberFlow of Common::CoordinationMessage from admitMember::msgOut to admitMember::msgIn;

        // hazards stated at SA are satisfied here by path, never restated (CV-19/safety option)
        satisfy SurveillanceDroneSwarm::SA::Hazards::PositionDriftHazard by navigateAgainstStoredMaps;
        satisfy SurveillanceDroneSwarm::SA::Hazards::MeshJammingHazard by relayLink;
        satisfy SurveillanceDroneSwarm::SA::Hazards::MisclassificationHazard by detectAndClassifyObjects;
        satisfy SurveillanceDroneSwarm::SA::Hazards::SensingDegradedUnnoticedHazard by presentStatusPicture;
        satisfy SurveillanceDroneSwarm::SA::Hazards::StaleTrackHazard by correlateTracks;
        satisfy SurveillanceDroneSwarm::SA::Hazards::SpoofedMemberHazard by admitMember;
        satisfy SurveillanceDroneSwarm::SA::Hazards::MixedClassifierVersionsHazard by manageClassifierVersion;
        satisfy SurveillanceDroneSwarm::SA::Hazards::OperatorOverloadHazard by reportDetections;

        // hazards this layer adds, visible once the population's member definition exchanges over a peer mesh
        package Hazards {
            doc /* hazards added at LA: risks that become visible once the population's member definition (SurveillanceDrone, above) is instantiated as members exchanging over a peer mesh link and the functions above are allocated to the placeholder logical component. Each is satisfied below by the coordination function that mitigates it. */

            #Hazard requirement MemberCollisionHazard {
                subject s : SurveillanceDroneSwarm::LA::SurveillanceDrone;
                doc /* two members sharing the same airspace fail to deconflict their flight paths and risk collision. */
            }
            #Hazard requirement PrematureDepartureHazard {
                subject s : SurveillanceDroneSwarm::LA::SurveillanceDrone;
                doc /* a member leaves its sector for recall or recharge before a handover to a peer completes, leaving a gap in watch. */
            }
            #Hazard requirement UncoveredMemberLossHazard {
                subject s : SurveillanceDroneSwarm::LA::SurveillanceDrone;
                doc /* a member is lost or grounded and the fleet does not redistribute coverage quickly enough, leaving its sector unwatched. */
            }
            #Hazard requirement UnrelayedIsolationHazard {
                subject s : SurveillanceDroneSwarm::LA::SurveillanceDrone;
                doc /* an isolated member finds no peer able to relay for it and drops out of coordination without anyone noticing. */
            }
        }
        satisfy Hazards::MemberCollisionHazard by deconflictMembers;
        satisfy Hazards::PrematureDepartureHazard by handOverSector;
        satisfy Hazards::UncoveredMemberLossHazard by redistributeCoverage;
        satisfy Hazards::UnrelayedIsolationHazard by relayLink;

        // ── architecture, alternative 2 ──
        // ===== LA alternative 2 of 2: decentralized swarm coordination, thin ground gateway =====
        // Genuinely different split from alternative 1: alternative 1 keeps the deciding
        // #Coordination on the ground; this alternative settles ALL eight #Coordination
        // functions onboard, over the mesh, among the members themselves (>= half, per the
        // house rule, is satisfied at 8/8). The five #C2 functions keep a ground usage here
        // too, hosted on one logical ground component, so a human still tasks, supervises,
        // recalls and is shown status and acknowledges reports from one place.

        #Member part def SurveillanceDrone {
          doc /* the replicable member of the twelve-drone population, as realised at LA-2: one surveillance drone carrying its own watch, sensing, navigation, coordination and reporting functions, and the ports it needs to reach its peers over the mesh and the ground station over the ground link. Coordinator choice: at any time the member with the lowest platform id among those currently reachable over the mesh acts as sector-handover/redistribution coordinator for its reachable group; every member runs the same election rule, so any reachable member can take over instantly if the incumbent drops off the mesh -- no ground confirmation is needed to replace it, and a healed partition re-elects by the same rule. When the ground link drops, onboard coordination (handOverSector, rotateRecharge, redistributeCoverage, deconflictMembers, relayLink, correlateTracks, handOverTrack, admitMember) continues unchanged, since none of it depends on groundStation; only new tasking, the operator's view of status and acknowledgement are delayed until the link returns. When groundStation itself fails, the fleet keeps watching and coordinating on the same onboard basis indefinitely, but no new tasking, supervision or recall can reach it until a ground station is restored. */

          out port meshOut : Common::MeshPort {
            doc /* transmits coordination and relay traffic to a peer drone over the mesh radio. */
          }
          in port meshIn : ~Common::MeshPort {
            doc /* receives coordination and relay traffic from a peer drone over the mesh radio. */
          }
          in port taskingIn : Common::MissionTasking {
            doc /* takes in the area of interest, sectors and mission window relayed down from the ground station. */
          }
          in port commandIn : Common::SupervisoryAndRecallCommands {
            doc /* takes in priorities, the sector to look at more closely and the reporting threshold, relayed down from the ground station. */
          }
          in port recallIn : Common::SupervisoryAndRecallCommands {
            doc /* takes in a recall-and-land order for the fleet or for this drone, relayed down from the ground station. */
          }
          out port reportsOut : Common::DetectionReportsAndTracks {
            doc /* sends this drone's triaged, de-duplicated detection reports and tracks toward the ground station. */
          }
          out port decisionsOut : Common::DecisionRecords {
            doc /* sends the decision record for every report this drone has sent toward the ground station. */
          }
          out port statusOut : Common::StatusPicture {
            doc /* sends this drone's position, activity, coverage and degradation toward the ground station's status picture. */
          }
          out port rechargeRequestOut : Common::CoordinationMessage {
            doc /* sends a recharge-slot request, negotiated onboard by rotateRecharge, toward the ground station and on to the ground crew. */
          }

          #Mode state def MemberMode {
            doc /* the operating mode of one member drone in LA-2, nested inside the #Member part def itself so the brief's named modes are states of SurveillanceDrone's own machine; carries the rules the system never breaks. */

            initial start;
            transition start -> Landed;

            state Landed {
              doc /* grounded, not watching: recalled, out of cleared airspace, quarantined, or recharging. */
            }
            state Watching {
              doc /* actively holding assigned sector watch under normal conditions. */
            }
            state NavigationDegraded {
              doc /* the brief's named mode: no satellite positioning; navigating by matching camera views against stored maps. */
            }
            state SensingDegraded {
              doc /* the brief's named mode: this drone's sensors cannot be trusted as they are. */
            }
            state Isolated {
              doc /* the brief's named mode: cut off from the other drones. */
            }
            state Quarantined {
              doc /* the brief's named mode: failed admission; takes no part in coordination until readmitted. */
            }
            state Recalled {
              doc /* under a recall-and-land order; no longer watching, heading to land. */
            }
            state OutsideClearedAirspace {
              doc /* outside the airspace authority's cleared limits; no longer watching, heading to land. */
            }

            transition Landed -> Watching;
            transition Watching -> NavigationDegraded;
            transition NavigationDegraded -> Watching;
            transition Watching -> SensingDegraded;
            transition SensingDegraded -> Watching;
            transition Watching -> Isolated;
            transition Isolated -> Watching;
            transition Isolated -> Landed;
            transition Watching -> Recalled;
            transition NavigationDegraded -> Recalled;
            transition SensingDegraded -> Recalled;
            transition Isolated -> Recalled;
            transition Recalled -> Landed;
            transition Watching -> OutsideClearedAirspace;
            transition OutsideClearedAirspace -> Landed;
            transition Watching -> Quarantined;
            transition Quarantined -> Landed;

            @SysproseVerification::PropertyPattern {
              doc /* RecallWins: once a drone is recalled, it does not watch again until it has landed. */
              attribute pattern = "absence";
              attribute scope = "between";
              attribute q = "state Recalled";
              attribute r = "state Landed";
              attribute p = "state Watching";
            }
            @SysproseVerification::PropertyPattern {
              doc /* ReturnsWhenIsolated: from any situation a drone can be in, it can always get back to landed; an isolated drone included. */
              attribute pattern = "recovery";
              attribute scope = "globally";
              attribute p = "state Landed";
            }
            @SysproseVerification::PropertyPattern {
              doc /* GeofenceBreachEndsWatch: once a drone is outside its cleared airspace, it does not watch until it has landed. */
              attribute pattern = "absence";
              attribute scope = "between";
              attribute q = "state OutsideClearedAirspace";
              attribute r = "state Landed";
              attribute p = "state Watching";
            }
            @SysproseVerification::PropertyPattern {
              doc /* QuarantinedStaysOut: once a drone is quarantined, it takes no part in coordination until it has been readmitted. */
              attribute pattern = "absence";
              attribute scope = "between";
              attribute q = "state Quarantined";
              attribute r = "state Landed";
              attribute p = "state Watching";
            }
          }

          #State state def MemberState {
            doc /* the coarse platform status of one member drone, independent of its watch mode, nested inside the #Member part def. */
            initial start;
            transition start -> Idle;
            state Idle {
              doc /* on the ground, available but not tasked. */
            }
            state Active {
              doc /* airborne and performing tasked activity. */
            }
            state Recharging {
              doc /* at a recharge point being serviced by the ground crew. */
            }
            transition Idle -> Active;
            transition Active -> Recharging;
            transition Recharging -> Idle;
            transition Active -> Idle;
          }

          state mode : MemberMode {
            doc /* this drone's operating mode: watching, degraded, isolated, quarantined, recalled, outside cleared airspace, or landed. */
          }
          state platformStatus : MemberState {
            doc /* this drone's coarse platform status: idle, active or recharging. */
          }
        }
        part fleet : SurveillanceDrone [12] {
          doc /* the twelve-member fleet: every member performs the watch, sensing, navigation, reporting and all eight coordination functions of this architecture. */
          state configuration : FleetConfiguration {
            doc /* the fleet-level watch configuration: normal coverage or mesh-degraded (the brief's named MeshDegraded fleet mode). */
          }
        }
        part memberA : SurveillanceDrone {
          doc /* first representative member, used to show the pairwise mesh interaction pattern between peers. */
        }
        part memberB : SurveillanceDrone {
          doc /* second representative member, used to show the pairwise mesh interaction pattern between peers. */
        }
        interface peerLink : Common::MeshLink connect memberA.meshOut to memberB.meshIn {
          doc /* the mandated peer link between the two representative members: memberA's coordination traffic reaching memberB. */
        }
        interface peerLinkReturn : Common::MeshLink connect memberB.meshOut to memberA.meshIn {
          doc /* the return leg of the peer link: memberB's coordination traffic reaching memberA. */
        }
        interface fleetMeshDown : Common::MeshLink connect fleet.meshOut to memberA.meshIn {
          doc /* the rest of the fleet's mesh traffic reaching memberA, closing the ring so every mesh port is used. */
        }
        interface fleetMeshUp : Common::MeshLink connect memberB.meshOut to fleet.meshIn {
          doc /* memberB's mesh traffic reaching the rest of the fleet, closing the ring so every mesh port is used. */
        }
        part def GroundStation {
          doc /* the single logical ground-side component of LA-2: a thin gateway that hosts all five command-and-control functions and classifier version management, and relays tasking, supervision, recall, reports, decisions, status and recharge requests between the operations centre, duty controller, ground crew and the fleet. It does not do any of the eight coordination functions, which are settled entirely onboard in this architecture. */

          in port taskingInExt : Common::MissionTasking {
            doc /* takes in mission tasking from the operations centre. */
          }
          in port commandInExt : Common::SupervisoryAndRecallCommands {
            doc /* takes in supervisory commands from the duty controller. */
          }
          in port recallInExt : Common::SupervisoryAndRecallCommands {
            doc /* takes in a recall-and-land order from the duty controller. */
          }
          in port ackInExt : Common::ReportAcknowledgements {
            doc /* takes in the duty controller's acknowledgement of a detection report. */
          }
          out port reportsOutExt : Common::DetectionReportsAndTracks {
            doc /* sends triaged, de-duplicated reports and tracks to the operations centre. */
          }
          out port decisionsOutExt : Common::DecisionRecords {
            doc /* sends decision records to the operations centre. */
          }
          out port statusOutExt : Common::StatusPicture {
            doc /* sends the assembled fleet status picture to the duty controller. */
          }
          out port rechargeOutExt : Common::CoordinationMessage {
            doc /* sends a recharge-slot request to the ground crew. */
          }

          out port taskingOutFleet : Common::MissionTasking {
            doc /* relays mission tasking down to the fleet. */
          }
          out port commandOutFleet : Common::SupervisoryAndRecallCommands {
            doc /* relays supervisory commands down to the fleet. */
          }
          out port recallOutFleet : Common::SupervisoryAndRecallCommands {
            doc /* relays a recall-and-land order down to the fleet. */
          }
          in port reportsInFleet : Common::DetectionReportsAndTracks {
            doc /* takes in detection reports and tracks from the fleet. */
          }
          in port decisionsInFleet : Common::DecisionRecords {
            doc /* takes in decision records from the fleet. */
          }
          in port statusInFleet : Common::StatusPicture {
            doc /* takes in each member's contribution to the status picture. */
          }
          in port rechargeInFleet : Common::CoordinationMessage {
            doc /* takes in recharge-slot requests from the fleet. */
          }
        }
        part groundStation : GroundStation {
          doc /* the one instance of the ground gateway in LA-2. */
          state mode : GroundStationMode {
            doc /* the ground station's own operating mode. */
          }
          state platformStatus : GroundStationStatus {
            doc /* the ground station's coarse platform status. */
          }
        }
        #Mode state def GroundStationMode {
          doc /* the ground station's operating mode: linked to the fleet under normal conditions, or degraded when the ground link itself is down. In this architecture the fleet keeps watching regardless, since coordination does not depend on this link. */
          initial start;
          transition start -> Linked;
          state Linked {
            doc /* the ground link to the fleet is up. */
          }
          state LinkDegraded {
            doc /* the ground link to the fleet, the operations centre or the duty controller is down or degraded. */
          }
          transition Linked -> LinkDegraded;
          transition LinkDegraded -> Linked;
        }
        #State state def GroundStationStatus {
          doc /* the coarse platform status of the ground station. */
          initial start;
          transition start -> Idle;
          state Idle {
            doc /* no active mission tasking is being relayed. */
          }
          state Active {
            doc /* mission tasking is active and the gateway is relaying reports, decisions and status. */
          }
          transition Idle -> Active;
          transition Active -> Idle;
        }
        // ----- ground-fleet relay connections: each of the fleet's three usages (fleet,
        // memberA, memberB) is wired so no port is left dangling. -----

        connection taskingDown_fleet connect groundStation.taskingOutFleet to fleet.taskingIn {
          doc /* relays mission tasking to the fleet. */
        }
        connection taskingDown_A connect groundStation.taskingOutFleet to memberA.taskingIn {
          doc /* relays mission tasking to memberA. */
        }
        connection taskingDown_B connect groundStation.taskingOutFleet to memberB.taskingIn {
          doc /* relays mission tasking to memberB. */
        }
        connection commandDown_fleet connect groundStation.commandOutFleet to fleet.commandIn {
          doc /* relays supervisory commands to the fleet. */
        }
        connection commandDown_A connect groundStation.commandOutFleet to memberA.commandIn {
          doc /* relays supervisory commands to memberA. */
        }
        connection commandDown_B connect groundStation.commandOutFleet to memberB.commandIn {
          doc /* relays supervisory commands to memberB. */
        }
        connection recallDown_fleet connect groundStation.recallOutFleet to fleet.recallIn {
          doc /* relays a recall-and-land order to the fleet. */
        }
        connection recallDown_A connect groundStation.recallOutFleet to memberA.recallIn {
          doc /* relays a recall-and-land order to memberA. */
        }
        connection recallDown_B connect groundStation.recallOutFleet to memberB.recallIn {
          doc /* relays a recall-and-land order to memberB. */
        }
        connection reportsUp_fleet connect fleet.reportsOut to groundStation.reportsInFleet {
          doc /* the fleet's detection reports and tracks reaching the ground station. */
        }
        connection reportsUp_A connect memberA.reportsOut to groundStation.reportsInFleet {
          doc /* memberA's detection reports and tracks reaching the ground station. */
        }
        connection reportsUp_B connect memberB.reportsOut to groundStation.reportsInFleet {
          doc /* memberB's detection reports and tracks reaching the ground station. */
        }
        connection decisionsUp_fleet connect fleet.decisionsOut to groundStation.decisionsInFleet {
          doc /* the fleet's decision records reaching the ground station. */
        }
        connection decisionsUp_A connect memberA.decisionsOut to groundStation.decisionsInFleet {
          doc /* memberA's decision records reaching the ground station. */
        }
        connection decisionsUp_B connect memberB.decisionsOut to groundStation.decisionsInFleet {
          doc /* memberB's decision records reaching the ground station. */
        }
        connection statusUp_fleet connect fleet.statusOut to groundStation.statusInFleet {
          doc /* the fleet's status contribution reaching the ground station. */
        }
        connection statusUp_A connect memberA.statusOut to groundStation.statusInFleet {
          doc /* memberA's status contribution reaching the ground station. */
        }
        connection statusUp_B connect memberB.statusOut to groundStation.statusInFleet {
          doc /* memberB's status contribution reaching the ground station. */
        }
        connection rechargeUp_fleet connect fleet.rechargeRequestOut to groundStation.rechargeInFleet {
          doc /* the fleet's recharge-slot requests reaching the ground station. */
        }
        connection rechargeUp_A connect memberA.rechargeRequestOut to groundStation.rechargeInFleet {
          doc /* memberA's recharge-slot requests reaching the ground station. */
        }
        connection rechargeUp_B connect memberB.rechargeRequestOut to groundStation.rechargeInFleet {
          doc /* memberB's recharge-slot requests reaching the ground station. */
        }
        // ----- ground station to the SA-level actors (upward references; never restated) -----

        connection taskingFromOpsCentre connect SurveillanceDroneSwarm::SA::operationsCentre.taskingOut to groundStation.taskingInExt {
          doc /* mission tasking arriving from the operations centre. */
        }
        connection commandFromDutyController connect SurveillanceDroneSwarm::SA::dutyController.supervisionOut to groundStation.commandInExt {
          doc /* supervisory commands arriving from the duty controller. */
        }
        connection recallFromDutyController connect SurveillanceDroneSwarm::SA::dutyController.recallOut to groundStation.recallInExt {
          doc /* recall-and-land orders arriving from the duty controller. */
        }
        connection ackFromDutyController connect SurveillanceDroneSwarm::SA::dutyController.ackOut to groundStation.ackInExt {
          doc /* report acknowledgements arriving from the duty controller. */
        }
        connection reportsToOpsCentre connect groundStation.reportsOutExt to SurveillanceDroneSwarm::SA::operationsCentre.reportsIn {
          doc /* triaged reports and tracks sent to the operations centre. */
        }
        connection decisionsToOpsCentre connect groundStation.decisionsOutExt to SurveillanceDroneSwarm::SA::operationsCentre.decisionsIn {
          doc /* decision records sent to the operations centre. */
        }
        connection statusToDutyController connect groundStation.statusOutExt to SurveillanceDroneSwarm::SA::dutyController.statusIn {
          doc /* the fleet status picture sent to the duty controller. */
        }
        connection rechargeToGroundCrew connect groundStation.rechargeOutExt to SurveillanceDroneSwarm::SA::groundCrew.rechargeIn {
          doc /* recharge-slot requests sent to the ground crew. */
        }
        // ----- allocation: every SA function realised by exactly one LA component -----
        // on-board (fleet): the five base watch/report functions plus all eight
        // #Coordination functions -- the alternative-2 decision. Bare names: these
        // allocate the local action usages of this document, not the SA layer's.
        allocate holdSectorWatch to fleet;
        allocate detectAndClassifyObjects to fleet;
        allocate navigateAgainstStoredMaps to fleet;
        allocate reportDetections to fleet;
        allocate recordDecision to fleet;
        allocate handOverSector to fleet;
        allocate rotateRecharge to fleet;
        allocate redistributeCoverage to fleet;
        allocate deconflictMembers to fleet;
        allocate relayLink to fleet;
        allocate correlateTracks to fleet;
        allocate handOverTrack to fleet;
        allocate admitMember to fleet;
        // ground (groundStation): all five #C2 functions keep a ground usage, plus
        // classifier version management held centrally to avoid mixed versions.
        allocate taskMission to groundStation;
        allocate commandSupervision to groundStation;
        allocate recallAndLand to groundStation;
        allocate presentStatusPicture to groundStation;
        allocate acknowledgeReport to groundStation;
        allocate manageClassifierVersion to groundStation;
        // ----- rules the system never breaks (CV-18): carried on the member's machine -----
        satisfy SurveillanceDroneSwarm::SA::RecallWins by fleet;
        satisfy SurveillanceDroneSwarm::SA::ReturnsWhenIsolated by fleet;
        satisfy SurveillanceDroneSwarm::SA::GeofenceBreachEndsWatch by fleet;
        satisfy SurveillanceDroneSwarm::SA::QuarantinedStaysOut by fleet;
        // ----- hazards stated at SA: satisfied here by path, never restated -----
        satisfy SurveillanceDroneSwarm::SA::Hazards::PositionDriftHazard by fleet;
        satisfy SurveillanceDroneSwarm::SA::Hazards::MeshJammingHazard by fleet;
        satisfy SurveillanceDroneSwarm::SA::Hazards::MisclassificationHazard by fleet;
        satisfy SurveillanceDroneSwarm::SA::Hazards::SensingDegradedUnnoticedHazard by groundStation;
        satisfy SurveillanceDroneSwarm::SA::Hazards::StaleTrackHazard by fleet;
        satisfy SurveillanceDroneSwarm::SA::Hazards::SpoofedMemberHazard by fleet;
        satisfy SurveillanceDroneSwarm::SA::Hazards::MixedClassifierVersionsHazard by groundStation;
        satisfy SurveillanceDroneSwarm::SA::Hazards::OperatorOverloadHazard by groundStation;
        // ----- hazards stated at LA (by the other alternative's section): satisfied here
        // too, by THIS architecture's own components, since a hazard satisfied only by a
        // shared function does not count for this alternative. Never restated. -----
        satisfy SurveillanceDroneSwarm::LA::Hazards::MemberCollisionHazard by fleet;
        satisfy SurveillanceDroneSwarm::LA::Hazards::PrematureDepartureHazard by fleet;
        satisfy SurveillanceDroneSwarm::LA::Hazards::UncoveredMemberLossHazard by fleet;
        satisfy SurveillanceDroneSwarm::LA::Hazards::UnrelayedIsolationHazard by fleet;
        // ----- hazards LA-2 adds: risks specific to settling all eight coordination
        // functions onboard the mesh without a ground arbiter, not yet covered above -----
        package HazardsLA2 {
          doc /* hazards this architecture adds by moving all eight coordination functions onboard the mesh, where the hazards stated above do not yet cover the consequences of that specific placement decision. */

          #Hazard requirement CoordinationForkHazard {
            doc /* under heavy jamming the mesh can partition into two groups; each half, deciding sector handover and redistribution onboard without a ground arbiter, can independently reassign the same sector, and neither half can see the other's claim until the partition heals. */
            subject s : SurveillanceDroneSwarm::LA::SurveillanceDrone;
          }
          #Hazard requirement GroundBlindSpotHazard {
            doc /* because coordination decisions are settled onboard without waiting for ground confirmation, the status picture assembled at the ground station can lag the fleet's true onboard state during a mesh degradation, hiding a genuine coverage gap from the duty controller until the next status update arrives. */
            subject s : SurveillanceDroneSwarm::LA::GroundStation;
          }
        }
        satisfy HazardsLA2::CoordinationForkHazard by fleet;
        satisfy HazardsLA2::GroundBlindSpotHazard by groundStation;
        // ----- measures of effectiveness: LA-2's own worst-case estimate, with basis -----
        #Estimate attribute areaUnderWatchShare :> Common::areaUnderWatchShare = 0.92 {
          doc /* basis: SA requires >= 0.9. Onboard handOverSector and redistributeCoverage let the fleet re-spread within one mesh exchange instead of waiting on a ground decision, so LA-2's worst case sits above the SA floor. */
        }
        #Estimate attribute coverageLossOnMemberLoss :> Common::coverageLossOnMemberLoss = 0.18 {
          doc /* basis: brief allows <= 0.25. redistributeCoverage runs onboard the instant a member drops off the mesh, without waiting for a ground link round trip, so the loss before re-spread is smaller than a ground-arbitrated redistribution would allow. */
        }
        #Estimate attribute jammedMeshAreaUnderWatchShare :> Common::jammedMeshAreaUnderWatchShare = 0.78 {
          doc /* basis: brief requires >= 0.75. With half the links jammed, relayLink and deconflictMembers run entirely onboard among whichever members can still reach each other, so watch continues without needing the ground link at all; the remaining loss comes from the partitions relayLink cannot bridge. */
        }
        #Estimate attribute groundLinkLossAreaUnderWatchShare :> Common::groundLinkLossAreaUnderWatchShare = 0.92 {
          doc /* basis: target set here at 0.9, the brief's continuous-watch figure. This is LA-2's defining strength: none of the eight coordination functions depend on the ground link, so losing groundStation's uplink to the fleet does not stall handovers, rotation or redistribution -- only presentStatusPicture, acknowledgement and new tasking are delayed. */
        }
        #Estimate attribute watchEnduranceHours :> Common::watchEnduranceHours = 30 {
          doc /* basis: target set here at >= 24 h. rotateRecharge, settled onboard, keeps the fleet's 40-minute-flight/60-minute-recharge cycle running without a ground scheduler in the loop, so endurance is bounded by the ground crew's servicing rate rather than by link availability. */
        }
        #Estimate attribute reportLatencySeconds :> Common::reportLatencySeconds = 50 {
          doc /* basis: brief allows <= 60 s with the link up. correlateTracks runs onboard before a report leaves the fleet, adding a small onboard triage step ahead of the single ground-link hop through groundStation to the operations centre. */
        }
        #Estimate attribute positionErrorWithoutGnssMeters :> Common::positionErrorWithoutGnssMeters = 42 {
          doc /* basis: brief allows <= 50 m after 10 minutes without satellite positioning. navigateAgainstStoredMaps, onboard on every member, matches camera views against stored maps regardless of mesh or ground-link state, so the drift estimate does not change with coordination placement. */
        }
        #Estimate attribute reportHoldMinutes :> Common::reportHoldMinutes = 34 {
          doc /* basis: brief requires >= 30 min. reportDetections holds a member's reports onboard whenever groundStation's uplink is down; since coordination and sector watch continue independently of the ground link in LA-2, a cut-off member keeps flying and holding rather than landing early, giving slightly more hold time than a design that needs the ground link for coordination. */
        }
        #Estimate attribute reportsLostInLinkGap :> Common::reportsLostInLinkGap = 0 {
          doc /* basis: brief says none. reportDetections and recordDecision, both onboard, queue reports and their decision records until groundStation's uplink returns; nothing is discarded because none of the onboard functions require the ground link to keep running. */
        }
        #Estimate attribute missedDetectionShare :> Common::missedDetectionShare = 0.08 {
          doc /* basis: brief allows <= 0.1. detectAndClassifyObjects runs onboard on every member regardless of mesh or ground-link condition; the only degradation this architecture adds is the rare coordination fork during a mesh partition (CoordinationForkHazard), which can leave a sliver of a sector briefly unwatched. */
        }
        #Estimate attribute falseAlarmsPerHour :> Common::falseAlarmsPerHour = 1.6 {
          doc /* basis: brief allows <= 2/h. correlateTracks and handOverTrack, both onboard, de-duplicate and drop stale tracks before a report ever reaches groundStation, so the ground-side gate sees fewer spurious alerts than an unfiltered feed would produce. */
        }
        #Estimate attribute operatorAlertsPerHour :> Common::operatorAlertsPerHour = 17 {
          doc /* basis: the operator can judge at most 20/h. groundStation, hosting presentStatusPicture and acknowledgeReport, is the single gate the operator sees; with onboard correlation already thinning duplicates, the worst-case rate stays under the cap with headroom. */
        }
        #Estimate attribute acknowledgedReportsThatMatterShare :> Common::acknowledgedReportsThatMatterShare = 0.81 {
          doc /* basis: brief requires >= 0.8. onboard triage in reportDetections and correlateTracks removes low-confidence duplicates before groundStation ever shows them to the duty controller, keeping the acknowledged set weighted toward reports that matter. */
        }
        #Estimate attribute onboardClassificationCostUsd :> Common::onboardClassificationCostUsd = 285 {
          doc /* basis: brief allows <= 300 USD per drone. detectAndClassifyObjects runs fully onboard every member (as it must, to keep watching through a link or mesh gap), which is the most compute-hungry placement this cap has to cover; 285 USD leaves headroom under the cap. */
        }
        #prose part laTradeOff {
        doc /* Architecture trade-off for LA. Alternative 2 was taken.
                 alternative 1: total 0.67 (measures 0.86, review 0.28, structure 0.78, resilience 0.19)
                 alternative 2: total 0.90 (measures 1.00, review 0.56, structure 0.84, resilience 0.63)
                 The measures term scores the worst case of each alternative's own #Estimate: claims its architecture states with their basis, not measurements.
                 I would take Alternative 2. Alternative 1 puts every deciding coordination function on groundControlStation, including deconflictMembers and relayLink, which only make sense on the mesh. The result is a ground-hosted catch-all component. The model's own documentation says coordination stops fleet-wide on link or station loss, and that members fly their last directive (localFallbackOnIsolation) with no controlled landing. It accepts that single point of failure as a hazard and misses two targets: groundLinkLoss 0.55 and endurance 20 h. Alternative 2 moves all eight coordination functions onto SurveillanceDrone, with a lowest-id coordinator election, and reduces GroundStation to a gateway for C2 and classifier versions. Coordination, correlation and report holding therefore survive a lost link. Its weaknesses are real and should be fixed at the next layer. The member is overloaded, and the four rules sit on the same MemberMode that detects and coordinates, with no independent monitor. If the ground station fails, the fleet keeps flying with no recall path and no landing policy. Recharge requests reach the ground crew only through groundStation, so the claims of 0.92 coverage with the ground down and 30 h endurance are overstated. coverageLossOnMemberLoss 0.18 is below the duty-cycle floor of about 0.21 and has no mechanism behind it. The two new hazards are 'satisfied' by the components that cause them, and the triple wiring (fleet, memberA, memberB) plus the ring 'so every mesh port is used' pads the model without adding architecture. Even so, Alternative 2's split of responsibilities is the one that survives the next layer. */
        }
    }
    package PA {
        #prompt part paGuidance {
            doc /* PA: the components that will be built. Behaviour parts are hosted in node parts by nesting, physical links are typed, item definitions carry units, and resource budgets are require constraints. */
        }

        // the system, to be decomposed into physical components
        part def SurveillanceDroneSwarmPhysical {
            out port meshOut : LA::SurveillanceDrone::meshOut;
            in port meshIn : LA::SurveillanceDrone::meshIn;
            in port taskingIn : LA::SurveillanceDrone::taskingIn;
            in port commandIn : LA::SurveillanceDrone::commandIn;
            in port recallIn : LA::SurveillanceDrone::recallIn;
            out port reportsOut : LA::SurveillanceDrone::reportsOut;
            out port decisionsOut : LA::SurveillanceDrone::decisionsOut;
            out port statusOut : LA::SurveillanceDrone::statusOut;
            out port rechargeRequestOut : LA::SurveillanceDrone::rechargeRequestOut;
            doc /* TODO: decompose into components and move the functions onto them. */
        }

        // the population: 12 identical members (CV-16)
        #prose part fleetFact {
            doc /* Population: 12 members of SurveillanceDrone, carried by fleet, exchanging through Common::MeshLink. Carried from the brief; the architecture instantiates it. */
        }

        // actors, carried over unchanged
        #Actor part def DutyController {
            doc /* TODO: check this actor's interface against LA. */
        }
        part dutyController : DutyController;
        trace dutyController to SurveillanceDroneSwarm::LA::dutyController;
        #Actor part def Analysts {
            doc /* TODO: check this actor's interface against LA. */
        }
        part analysts : Analysts;
        trace analysts to SurveillanceDroneSwarm::LA::analysts;
        #Actor part def OperationsCentre {
            doc /* TODO: check this actor's interface against LA. */
        }
        part operationsCentre : OperationsCentre;
        trace operationsCentre to SurveillanceDroneSwarm::LA::operationsCentre;
        #Actor part def AirspaceAuthority {
            doc /* TODO: check this actor's interface against LA. */
        }
        part airspaceAuthority : AirspaceAuthority;
        trace airspaceAuthority to SurveillanceDroneSwarm::LA::airspaceAuthority;
        #Actor part def GroundCrew {
            doc /* TODO: check this actor's interface against LA. */
        }
        part groundCrew : GroundCrew;
        trace groundCrew to SurveillanceDroneSwarm::LA::groundCrew;
        #Actor part def FixedCameraNetworkOwner {
            doc /* TODO: check this actor's interface against LA. */
        }
        part fixedCameraNetworkOwner : FixedCameraNetworkOwner;
        trace fixedCameraNetworkOwner to SurveillanceDroneSwarm::LA::fixedCameraNetworkOwner;
        #Actor part def ProgrammeSponsor {
            doc /* TODO: check this actor's interface against LA. */
        }
        part programmeSponsor : ProgrammeSponsor;
        trace programmeSponsor to SurveillanceDroneSwarm::LA::programmeSponsor;

        // functions, carried over from LA: every one of them has to be realised here
        action def HoldSectorWatch {
            doc /* TODO: how `holdSectorWatch` is realised at PA. */
        }
        action def DetectAndClassifyObjects {
            doc /* TODO: how `detectAndClassifyObjects` is realised at PA. */
        }
        action def NavigateAgainstStoredMaps {
            doc /* TODO: how `navigateAgainstStoredMaps` is realised at PA. */
        }
        action def ReportDetections {
            doc /* TODO: how `reportDetections` is realised at PA. */
        }
        action def RecordDecision {
            doc /* TODO: how `recordDecision` is realised at PA. */
        }
        action def PresentStatusPicture {
            doc /* TODO: how `presentStatusPicture` is realised at PA. */
        }
        action def TaskMission {
            doc /* TODO: how `taskMission`, `taskMissionAct` are realised at PA. */
        }
        action def CommandSupervision {
            doc /* TODO: how `commandSupervision`, `commandSupervisionAct` are realised at PA. */
        }
        action def RecallAndLand {
            doc /* TODO: how `recallAndLand`, `recallAndLandAct` are realised at PA. */
        }
        action def AcknowledgeReport {
            doc /* TODO: how `acknowledgeReport`, `acknowledgeReportAct` are realised at PA. */
        }
        action def HandOverSector {
            doc /* TODO: how `handOverSector` is realised at PA. */
        }
        action def RotateRecharge {
            doc /* TODO: how `rotateRecharge` is realised at PA. */
        }
        action def RedistributeCoverage {
            doc /* TODO: how `redistributeCoverage` is realised at PA. */
        }
        action def DeconflictMembers {
            doc /* TODO: how `deconflictMembers` is realised at PA. */
        }
        action def RelayLink {
            doc /* TODO: how `relayLink` is realised at PA. */
        }
        action def CorrelateTracks {
            doc /* TODO: how `correlateTracks` is realised at PA. */
        }
        action def HandOverTrack {
            doc /* TODO: how `handOverTrack` is realised at PA. */
        }
        action def AdmitMember {
            doc /* TODO: how `admitMember` is realised at PA. */
        }
        action def ManageClassifierVersionFunction {
            doc /* TODO: how `manageClassifierVersion` is realised at PA. */
        }
        action def MergeWithCameraNetworkTracks {
            doc /* TODO: how `mergeAct` is realised at PA. */
        }
        action def ViewStatusPicture {
            doc /* TODO: how `viewStatusAct` is realised at PA. */
        }
        action def ServiceAndRecharge {
            doc /* TODO: how `serviceAndRechargeAct` is realised at PA. */
        }
        action def ProvideCameraTracks {
            doc /* TODO: how `provideCameraTracksAct` is realised at PA. */
        }
        action def JudgeAlerts {
            doc /* TODO: how `judgeAlertsAct` is realised at PA. */
        }
        action holdSectorWatch : HoldSectorWatch;
        trace holdSectorWatch to SurveillanceDroneSwarm::LA::holdSectorWatch;
        action detectAndClassifyObjects : DetectAndClassifyObjects;
        trace detectAndClassifyObjects to SurveillanceDroneSwarm::LA::detectAndClassifyObjects;
        action navigateAgainstStoredMaps : NavigateAgainstStoredMaps;
        trace navigateAgainstStoredMaps to SurveillanceDroneSwarm::LA::navigateAgainstStoredMaps;
        action reportDetections : ReportDetections {
            out reportsOut : Common::DetectionReportsAndTracks;
            in ackIn : Common::ReportAcknowledgements;
        }
        trace reportDetections to SurveillanceDroneSwarm::LA::reportDetections;
        action recordDecision : RecordDecision {
            out decisionsOut : Common::DecisionRecords;
        }
        trace recordDecision to SurveillanceDroneSwarm::LA::recordDecision;
        #C2 action presentStatusPicture : PresentStatusPicture {
            out statusOut : Common::StatusPicture;
        }
        trace presentStatusPicture to SurveillanceDroneSwarm::LA::presentStatusPicture;
        #C2 action taskMission : TaskMission {
            in taskingIn : Common::MissionTasking;
        }
        trace taskMission to SurveillanceDroneSwarm::LA::taskMission;
        #C2 action commandSupervision : CommandSupervision {
            in supervisionIn : Common::SupervisoryAndRecallCommands;
        }
        trace commandSupervision to SurveillanceDroneSwarm::LA::commandSupervision;
        #C2 action recallAndLand : RecallAndLand {
            in recallIn : Common::SupervisoryAndRecallCommands;
        }
        trace recallAndLand to SurveillanceDroneSwarm::LA::recallAndLand;
        #C2 action acknowledgeReport : AcknowledgeReport {
            in ackIn : Common::ReportAcknowledgements;
        }
        trace acknowledgeReport to SurveillanceDroneSwarm::LA::acknowledgeReport;
        #Coordination action handOverSector : HandOverSector {
            out msgOut : Common::CoordinationMessage;
            in msgIn : Common::CoordinationMessage;
        }
        trace handOverSector to SurveillanceDroneSwarm::LA::handOverSector;
        #Coordination action rotateRecharge : RotateRecharge {
            out msgOut : Common::CoordinationMessage;
            in msgIn : Common::CoordinationMessage;
        }
        trace rotateRecharge to SurveillanceDroneSwarm::LA::rotateRecharge;
        #Coordination action redistributeCoverage : RedistributeCoverage {
            out msgOut : Common::CoordinationMessage;
            in msgIn : Common::CoordinationMessage;
        }
        trace redistributeCoverage to SurveillanceDroneSwarm::LA::redistributeCoverage;
        #Coordination action deconflictMembers : DeconflictMembers {
            out msgOut : Common::CoordinationMessage;
            in msgIn : Common::CoordinationMessage;
        }
        trace deconflictMembers to SurveillanceDroneSwarm::LA::deconflictMembers;
        #Coordination action relayLink : RelayLink {
            in msgIn : Common::CoordinationMessage;
            out msgOut : Common::CoordinationMessage;
        }
        trace relayLink to SurveillanceDroneSwarm::LA::relayLink;
        #Coordination action correlateTracks : CorrelateTracks {
            in trackIn : Common::Track;
            out trackOut : Common::Track;
        }
        trace correlateTracks to SurveillanceDroneSwarm::LA::correlateTracks;
        #Coordination action handOverTrack : HandOverTrack {
            in trackIn : Common::Track;
            out trackOut : Common::Track;
        }
        trace handOverTrack to SurveillanceDroneSwarm::LA::handOverTrack;
        #Coordination action admitMember : AdmitMember {
            in msgIn : Common::CoordinationMessage;
            out msgOut : Common::CoordinationMessage;
        }
        trace admitMember to SurveillanceDroneSwarm::LA::admitMember;
        action manageClassifierVersion : ManageClassifierVersionFunction;
        trace manageClassifierVersion to SurveillanceDroneSwarm::LA::manageClassifierVersion;
        #C2 action taskMissionAct : TaskMission {
            out taskingOutA : Common::MissionTasking;
            out taskingOutB : Common::MissionTasking;
        }
        allocate taskMissionAct to operationsCentre;
        trace taskMissionAct to SurveillanceDroneSwarm::LA::taskMissionAct;
        action mergeAct : MergeWithCameraNetworkTracks {
            in swarmReportsInA : Common::DetectionReportsAndTracks;
            in swarmReportsInB : Common::DetectionReportsAndTracks;
            in decisionRecordsInA : Common::DecisionRecords;
            in decisionRecordsInB : Common::DecisionRecords;
            in cameraTracksIn : Common::CameraNetworkTracks;
            out mergedOut : Common::DetectionReportsAndTracks;
        }
        allocate mergeAct to operationsCentre;
        trace mergeAct to SurveillanceDroneSwarm::LA::mergeAct;
        #C2 action commandSupervisionAct : CommandSupervision {
            out supervisionOutA : Common::SupervisoryAndRecallCommands;
            out supervisionOutB : Common::SupervisoryAndRecallCommands;
        }
        allocate commandSupervisionAct to dutyController;
        trace commandSupervisionAct to SurveillanceDroneSwarm::LA::commandSupervisionAct;
        #C2 action recallAndLandAct : RecallAndLand {
            out recallOutA : Common::SupervisoryAndRecallCommands;
            out recallOutB : Common::SupervisoryAndRecallCommands;
        }
        allocate recallAndLandAct to dutyController;
        trace recallAndLandAct to SurveillanceDroneSwarm::LA::recallAndLandAct;
        #C2 action acknowledgeReportAct : AcknowledgeReport {
            out ackOut : Common::ReportAcknowledgements;
        }
        allocate acknowledgeReportAct to dutyController;
        trace acknowledgeReportAct to SurveillanceDroneSwarm::LA::acknowledgeReportAct;
        action viewStatusAct : ViewStatusPicture {
            in statusInA : Common::StatusPicture;
            in statusInB : Common::StatusPicture;
        }
        allocate viewStatusAct to dutyController;
        trace viewStatusAct to SurveillanceDroneSwarm::LA::viewStatusAct;
        action serviceAndRechargeAct : ServiceAndRecharge {
            in rechargeIn : Common::CoordinationMessage;
        }
        allocate serviceAndRechargeAct to groundCrew;
        trace serviceAndRechargeAct to SurveillanceDroneSwarm::LA::serviceAndRechargeAct;
        action provideCameraTracksAct : ProvideCameraTracks {
            out cameraTracksOut : Common::CameraNetworkTracks;
        }
        allocate provideCameraTracksAct to fixedCameraNetworkOwner;
        trace provideCameraTracksAct to SurveillanceDroneSwarm::LA::provideCameraTracksAct;
        action judgeAlertsAct : JudgeAlerts {
            in mergedIn : Common::DetectionReportsAndTracks;
        }
        allocate judgeAlertsAct to analysts;
        trace judgeAlertsAct to SurveillanceDroneSwarm::LA::judgeAlertsAct;

        // interactions, carried over as functional exchanges
        flow taskingToAFlow of Common::MissionTasking from taskMissionAct::taskingOutA to taskMission::taskingIn;
        flow taskingToBFlow of Common::MissionTasking from taskMissionAct::taskingOutB to taskMission::taskingIn;
        flow supervisionToAFlow of Common::SupervisoryAndRecallCommands from commandSupervisionAct::supervisionOutA to commandSupervision::supervisionIn;
        flow supervisionToBFlow of Common::SupervisoryAndRecallCommands from commandSupervisionAct::supervisionOutB to commandSupervision::supervisionIn;
        flow recallToAFlow of Common::SupervisoryAndRecallCommands from recallAndLandAct::recallOutA to recallAndLand::recallIn;
        flow recallToBFlow of Common::SupervisoryAndRecallCommands from recallAndLandAct::recallOutB to recallAndLand::recallIn;
        flow ackToAFlow of Common::ReportAcknowledgements from acknowledgeReportAct::ackOut to reportDetections::ackIn;
        flow ackToSystemFlow of Common::ReportAcknowledgements from acknowledgeReportAct::ackOut to acknowledgeReport::ackIn;
        flow statusAFlow of Common::StatusPicture from presentStatusPicture::statusOut to viewStatusAct::statusInA;
        flow statusBFlow of Common::StatusPicture from presentStatusPicture::statusOut to viewStatusAct::statusInB;
        flow reportsAFlow of Common::DetectionReportsAndTracks from reportDetections::reportsOut to mergeAct::swarmReportsInA;
        flow reportsBFlow of Common::DetectionReportsAndTracks from reportDetections::reportsOut to mergeAct::swarmReportsInB;
        flow decisionsAFlow of Common::DecisionRecords from recordDecision::decisionsOut to mergeAct::decisionRecordsInA;
        flow decisionsBFlow of Common::DecisionRecords from recordDecision::decisionsOut to mergeAct::decisionRecordsInB;
        flow cameraTracksFlow of Common::CameraNetworkTracks from provideCameraTracksAct::cameraTracksOut to mergeAct::cameraTracksIn;
        flow mergedToAnalystsFlow of Common::DetectionReportsAndTracks from mergeAct::mergedOut to judgeAlertsAct::mergedIn;
        flow handOverSectorFlow of Common::CoordinationMessage from handOverSector::msgOut to handOverSector::msgIn;
        flow rotateRechargeFlow of Common::CoordinationMessage from rotateRecharge::msgOut to rotateRecharge::msgIn;
        flow rechargeRequestFlow of Common::CoordinationMessage from rotateRecharge::msgOut to serviceAndRechargeAct::rechargeIn;
        flow redistributeCoverageFlow of Common::CoordinationMessage from redistributeCoverage::msgOut to redistributeCoverage::msgIn;
        flow deconflictMembersFlow of Common::CoordinationMessage from deconflictMembers::msgOut to deconflictMembers::msgIn;
        flow relayLinkFlow of Common::CoordinationMessage from relayLink::msgOut to relayLink::msgIn;
        flow correlateTracksFlow of Common::Track from correlateTracks::trackOut to correlateTracks::trackIn;
        flow handOverTrackFlow of Common::Track from handOverTrack::trackOut to handOverTrack::trackIn;
        flow admitMemberFlow of Common::CoordinationMessage from admitMember::msgOut to admitMember::msgIn;

        // ── architecture, alternative 2 ──
        // ===== Physical node kinds: hardware that hosts behaviour =====

        #Node part def MeshRadio {
            doc /* Drone-to-drone mesh radio hardware. Carries coordination traffic (handovers, rotation, redistribution, deconfliction, relay, track correlation, admission) and does not depend on the ground link. */
        }
        #Node part def GroundLinkRadio {
            doc /* Radio hardware for the link between a drone and the ground station. Not always available: degraded by radio interference, range and terrain. */
        }
        #Node part def StoredMapsStore {
            doc /* On-board store of reference imagery a drone matches its camera view against when satellite positioning is unavailable. */
        }
        #Node part def RechargePoint {
            doc /* Where a drone lands, recharges (about 60 minutes) and is serviced by the ground crew. Shared ground infrastructure, not carried by a drone. */

            attribute rechargeMinutesBudget = 60 [min];
            require constraint {
                doc /* memberRechargeMinutes budget: recharge takes at most about 60 minutes per drone. */
                rechargeMinutesBudget <= 60 [min]
            }
        }
        // ===== Variability: how a drone navigates without GNSS =====

        #Variant part def StoredMapMatchingNav {
            doc /* Variant: navigate by matching live camera frames against stored maps when GNSS is unavailable. This architecture's chosen variant. */
        }
        #Variant part def DeadReckoningNav {
            doc /* Variant: navigate by inertial dead reckoning when GNSS is unavailable, as an alternative to stored-map matching. Not selected here, but tagged so it is where-used-findable. */
        }
        // ===== Physical link media, typed by connection defs (CV-05) =====

        connection def MeshRadioLink {
            doc /* The intermittent inter-drone mesh radio medium that carries the peer link between two members. */
            end a : Common::MeshPort;
            end b : ~Common::MeshPort;
        }
        connection def GroundRadioLink {
            doc /* The medium that carries the link between a drone's ground-link radio and the ground station's radio. */
            end drone : Common::GroundLinkPort;
            end ground : ~Common::GroundLinkPort;
        }
        // ===== The replicable element (CV-16) =====

        #Member part def SurveillanceDrone {
            doc /* The replicable element: one of the 12 identical surveillance drones. Alternative 2 (distributed): 7 of 8 Coordination functions are decided on board, over the mesh, without waiting on the ground.
                 Coordinator choice and replacement: for each coordination exchange (sector handover, recharge rotation, coverage redistribution, deconfliction, relay, track correlation and hand-over) the initiating member proposes and the peers it reaches over the mesh acknowledge; ties are broken by lowest member id currently reachable. Coordinator role is per-exchange and not held by a fixed member, so a mesh drop simply removes that member from the next negotiation rather than stalling the swarm.
                 Ground link drop: this drone keeps holding sector watch, negotiating handover/rotation/redistribution/deconfliction/relay/track-handover with reachable peers, and buffers its own reports until the link (direct or relayed) returns.
                 Ground node failure: the fleet's on-board coordination is unaffected (it never depended on the ground station); only admitMember (mesh admission of new members) and the operator-facing C2 functions are unavailable until the ground station returns — existing members carry on watching and coordinating.
                 Its MemberState/MemberMode machines below are overridden on recall, geofence breach and quarantine by the nested safetyMonitor component, independent of what this drone's own detect/classify/decide behaviour otherwise decides — see the checked properties on those machines. */

            out port meshOut : Common::MeshPort;
            in port meshIn : ~Common::MeshPort;
            out port groundLinkPort : Common::GroundLinkPort;

            part meshRadio : MeshRadio {
                doc /* This drone's mesh radio hardware, carrying meshOut/meshIn traffic. */
            }
            part groundRadio : GroundLinkRadio {
                doc /* This drone's ground-link radio hardware. Present on every drone so any drone can relay; only the currently relaying drone's link is live. */
            }
            part storedMaps : StoredMapsStore {
                doc /* This drone's local copy of reference imagery for map-matching navigation. */
            }

            variation part navigationFallback : StoredMapMatchingNav {
                doc /* Variation point: which technique this drone uses to navigate without GNSS. */
                variant part mapMatching : StoredMapMatchingNav;
                variant part deadReckoning : DeadReckoningNav;
            }

            attribute flightEnduranceMinutesBudget = 40 [min];
            require constraint {
                doc /* memberFlightEnduranceMinutes budget: this drone flies for about 40 minutes per sortie. */
                flightEnduranceMinutesBudget >= 40 [min]
            }

            attribute onboardClassificationCostBudget = 300;
            require constraint {
                doc /* onboardClassificationCostUsd budget: on-board classification computing costs no more than 300 USD per drone. USD is not an ISQ unit, so the budget is carried unitless; the currency is stated here. */
                onboardClassificationCostBudget <= 300
            }

            part safetyMonitor : SafetyMonitor {
                doc /* This drone's dedicated override-authority component: it forces the recall, geofence-breach and quarantine outcomes carried by this drone's own MemberState/MemberMode machines below, independent of what its own detection, classification or coordination behaviour otherwise decides. */
            }

            #State state def MemberState {
                doc /* Flight/operational state of this drone, overridden on recall/geofence by safetyMonitor. Carries RecallWins and GeofenceBreachEndsWatch (CV-18). Isolated is a flight state here so recovery-to-Landed can be checked across it. */

                initial start;
                state Landed;
                state Launching;
                state Watching;
                state Isolated;
                state Recalled;
                state OutsideClearance;
                state Landing;

                transition start -> Landed;
                transition Landed -> Launching;
                transition Launching -> Watching;
                transition Watching -> Isolated;
                transition Isolated -> Watching;
                transition Isolated -> Landing;
                transition Watching -> Recalled;
                transition Watching -> OutsideClearance;
                transition Recalled -> Landing;
                transition OutsideClearance -> Landing;
                transition Landing -> Landed;

                @SysproseVerification::PropertyPattern {
                    doc /* RecallWins: once a drone is recalled, it does not watch again until it has landed. Enforced by safetyMonitor, overriding this drone's own coordination/detection behaviour. */
                    attribute pattern = "absence";
                    attribute scope = "between";
                    attribute q = "state Recalled";
                    attribute r = "state Landed";
                    attribute p = "state Watching";
                }
                @SysproseVerification::PropertyPattern {
                    doc /* GeofenceBreachEndsWatch: once a drone is outside its cleared airspace, it does not watch until it has landed. Enforced by safetyMonitor. */
                    attribute pattern = "absence";
                    attribute scope = "between";
                    attribute q = "state OutsideClearance";
                    attribute r = "state Landed";
                    attribute p = "state Watching";
                }
                @SysproseVerification::PropertyPattern {
                    doc /* ReturnsWhenIsolated: from any situation the drone can be in, it can always get back to landed; an isolated drone included. Enforced by safetyMonitor. */
                    attribute pattern = "recovery";
                    attribute scope = "globally";
                    attribute p = "state Landed";
                }
            }

            #Mode state def MemberMode {
                doc /* On-board condition mode: GNSS/sensing degradation and mesh admission status. Carries QuarantinedStaysOut (CV-18), enforced by safetyMonitor. */

                initial modeStart;
                state Nominal;
                state NavigationDegraded;
                state SensingDegraded;
                state Quarantined;
                state Readmitting;
                state Readmitted;

                transition modeStart -> Nominal;
                transition Nominal -> NavigationDegraded;
                transition NavigationDegraded -> Nominal;
                transition Nominal -> SensingDegraded;
                transition SensingDegraded -> Nominal;
                transition Nominal -> Quarantined;
                transition Quarantined -> Readmitting;
                transition Readmitting -> Readmitted;
                transition Readmitted -> Nominal;

                @SysproseVerification::PropertyPattern {
                    doc /* QuarantinedStaysOut: once a drone is quarantined, it takes no part in coordination until it has been readmitted. Enforced by safetyMonitor. */
                    attribute pattern = "absence";
                    attribute scope = "between";
                    attribute q = "state Quarantined";
                    attribute r = "state Readmitted";
                    attribute p = "state Nominal";
                }
            }

            perform action memberStateMachine : MemberState {
                doc /* Executes this drone's flight/operational state machine. */
            }
            perform action memberModeMachine : MemberMode {
                doc /* Executes this drone's condition-mode state machine. */
            }
        }
        // ===== The rule-enforcing monitor, kept separate from detect/classify/decide (CV-18) =====

        part def SafetyMonitor {
            doc /* Dedicated on-board override-authority component, nested in every SurveillanceDrone, kept separate from the parts that detect, classify or decide what to report. It forces the recall, geofence-breach and quarantine outcomes carried by the drone's own MemberState/MemberMode machines (RecallWins, GeofenceBreachEndsWatch, ReturnsWhenIsolated, QuarantinedStaysOut), regardless of what the drone's detection, classification or coordination behaviour independently decides. */
        }
        // ===== Fleet-level configuration (CV-16) =====

        #Configuration state def FleetConfiguration {
            doc /* Fleet-wide coordination configuration. MeshDegraded is the brief-named mode of the fleet when a share of inter-drone links is jammed. */
            initial fleetStart;
            state Nominal;
            state MeshDegraded;
            transition fleetStart -> Nominal;
            transition Nominal -> MeshDegraded;
            transition MeshDegraded -> Nominal;
        }
        // ===== Ground node =====

        #Node part def GroundStation {
            doc /* The operations centre's physical ground node: console, C2 software and the mesh-admission authority. In alternative 2 this is a thin node: it keeps every #C2 function and only the AdmitMember #Coordination function; the rest of Coordination runs on board the fleet. */

            in port groundLinkPortA : ~Common::GroundLinkPort;
            in port groundLinkPortB : ~Common::GroundLinkPort;

            part groundRadioNode : GroundLinkRadio {
                doc /* The ground station's own ground-link radio hardware: the fixed end of the ground link, whichever drone is currently relaying. */
            }

            #State state def GroundOperatingState {
                doc /* Ground station operating state. */
                initial gsStart;
                state Idle;
                state Supervising;
                transition gsStart -> Idle;
                transition Idle -> Supervising;
                transition Supervising -> Idle;
            }
            #Mode state def GroundLinkMode {
                doc /* Ground-side link mode: whether the ground link radio currently has a connected drone. */
                initial glStart;
                state LinkUp;
                state LinkDown;
                transition glStart -> LinkDown;
                transition LinkDown -> LinkUp;
                transition LinkUp -> LinkDown;
            }
            perform action groundOperatingStateMachine : GroundOperatingState {
                doc /* Executes the ground station's operating-state machine. */
            }
            perform action groundLinkModeMachine : GroundLinkMode {
                doc /* Executes the ground station's link-mode machine. */
            }

            attribute operatorAlertsPerHourBudget = 20;
            attribute operatorSecondsPerAlertBudget = 30 [s];
            require constraint {
                doc /* operatorAlertsPerHour budget: at most 20 alerts per hour reach the duty controller. */
                operatorAlertsPerHourBudget <= 20
            }
            require constraint {
                doc /* operatorSecondsPerAlert budget: at least 30 seconds is available to judge each alert. */
                operatorSecondsPerAlertBudget >= 30 [s]
            }
        }
        // ===== Top-level parts: the population and the ground =====

        attribute fleetSizeValue = 12;
        require constraint {
            doc /* fleetSize budget: at most 12 drones can be fielded, fixed by the brief. */
            fleetSizeValue <= 12
        }
        attribute areaOfInterestBudget = 25;
        require constraint {
            doc /* areaOfInterestKm2 budget: the design must cover an area of interest of up to 25 km^2 (unit stated in doc; km^2 is not a plain library unit here). */
            areaOfInterestBudget >= 25
        }
        part fleet : SurveillanceDrone [12] {
            doc /* The fielded fleet: the multiplicity that carries the count of 12 identical drones (CV-16). Never named individually; every function every member performs is allocated to this usage. */
            perform action fleetConfigurationMachine : FleetConfiguration {
                doc /* Executes the fleet-wide coordination configuration machine, including MeshDegraded. */
            }
        }
        part memberA : SurveillanceDrone {
            doc /* Representative member A: one end of the peer mesh link and one leg of the ground link. */
        }
        part memberB : SurveillanceDrone {
            doc /* Representative member B: the peer of memberA across the mesh link, and the other leg of the ground link. */
        }
        part groundStation : GroundStation {
            doc /* The single ground station usage: the operations centre's physical presence in this architecture. */
        }
        part rechargePoint : RechargePoint {
            doc /* The shared recharge point and ground crew station the fleet rotates through. */
        }
        // ===== Physical links, typed by connection defs (CV-05, CV-16) =====

        connection peerLink : MeshRadioLink connect memberA.meshOut to memberB.meshIn {
            doc /* Physical mesh link, A to B, typed by the intermittent mesh radio medium; carried by each drone's meshRadio node. */
        }
        connection peerLinkReturn : MeshRadioLink connect memberB.meshOut to memberA.meshIn {
            doc /* The return leg of the mesh link, B to A, so neither representative's mesh ports are left dangling. */
        }
        connection groundLinkA : GroundRadioLink connect memberA.groundLinkPort to groundStation.groundLinkPortA {
            doc /* Physical ground link from representative A to the ground station, carried by groundRadio and groundRadioNode. */
        }
        connection groundLinkB : GroundRadioLink connect memberB.groundLinkPort to groundStation.groundLinkPortB {
            doc /* Physical ground link from representative B to the ground station. */
        }
        // ===== Allocations: the 28 functions of this layer, each to a bare-named part (CV-04, CV-06) =====

        allocate holdSectorWatch to fleet;
        allocate detectAndClassifyObjects to fleet;
        allocate navigateAgainstStoredMaps to fleet;
        allocate reportDetections to fleet;
        allocate recordDecision to fleet;
        allocate presentStatusPicture to groundStation;
        allocate taskMission to groundStation;
        allocate commandSupervision to groundStation;
        allocate recallAndLand to groundStation;
        allocate recallAndLand to fleet;
        allocate acknowledgeReport to groundStation;
        allocate handOverSector to fleet;
        allocate rotateRecharge to fleet;
        allocate redistributeCoverage to fleet;
        allocate deconflictMembers to fleet;
        allocate relayLink to fleet;
        allocate correlateTracks to fleet;
        allocate handOverTrack to fleet;
        allocate admitMember to groundStation;
        allocate manageClassifierVersion to groundStation;
        // ===== Hazards stated above, satisfied here by path (never restated) =====

        satisfy SurveillanceDroneSwarm::SA::Hazards::PositionDriftHazard by fleet;
        satisfy SurveillanceDroneSwarm::SA::Hazards::MeshJammingHazard by fleet;
        satisfy SurveillanceDroneSwarm::SA::Hazards::MisclassificationHazard by fleet;
        satisfy SurveillanceDroneSwarm::SA::Hazards::SensingDegradedUnnoticedHazard by fleet;
        satisfy SurveillanceDroneSwarm::SA::Hazards::StaleTrackHazard by fleet;
        satisfy SurveillanceDroneSwarm::SA::Hazards::SpoofedMemberHazard by groundStation;
        satisfy SurveillanceDroneSwarm::SA::Hazards::MixedClassifierVersionsHazard by groundStation;
        satisfy SurveillanceDroneSwarm::SA::Hazards::OperatorOverloadHazard by groundStation;
        satisfy SurveillanceDroneSwarm::LA::Hazards::MemberCollisionHazard by fleet;
        satisfy SurveillanceDroneSwarm::LA::Hazards::PrematureDepartureHazard by fleet;
        satisfy SurveillanceDroneSwarm::LA::Hazards::UncoveredMemberLossHazard by fleet;
        satisfy SurveillanceDroneSwarm::LA::Hazards::UnrelayedIsolationHazard by fleet;
        satisfy SurveillanceDroneSwarm::LA::HazardsLA2::CoordinationForkHazard by fleet;
        satisfy SurveillanceDroneSwarm::LA::HazardsLA2::GroundBlindSpotHazard by groundStation;
        // ===== Rules stated at SA, carried by the monitor's machine, satisfied here by path (CV-18) =====

        satisfy SurveillanceDroneSwarm::SA::RecallWins by fleet;
        satisfy SurveillanceDroneSwarm::SA::ReturnsWhenIsolated by fleet;
        satisfy SurveillanceDroneSwarm::SA::GeofenceBreachEndsWatch by fleet;
        satisfy SurveillanceDroneSwarm::SA::QuarantinedStaysOut by fleet;
        // ===== Hazards this layer adds (safety option) =====

        package Hazards {
            #Hazard requirement GroundLinkRadioFailureHazard {
                doc /* PA-added: the physical ground link radio on the relaying member, or at the ground station, fails outright rather than merely degrading, losing the ground link regardless of radio interference conditions. */
            }
            #Hazard requirement RechargeContentionHazard {
                doc /* PA-added: more drones need the recharge point at once than the ground crew can turn around within a rotation cycle, so a scheduled handover has no relieving drone. */
            }
        }
        satisfy Hazards::GroundLinkRadioFailureHazard by fleet;
        satisfy Hazards::RechargeContentionHazard by rechargePoint;
        // ===== Measures of effectiveness: this architecture's worst-case estimate (CV-17) =====

        #Estimate attribute areaUnderWatchShare :> Common::areaUnderWatchShare = 0.92 {
            doc /* Worst case for alternative 2: on-board HandOverSector and RedistributeCoverage keep sector rotation running without waiting on the ground link, holding coverage above the brief's 0.9 target even during a busy rotation. */
        }
        #Estimate attribute coverageLossOnMemberLoss :> Common::coverageLossOnMemberLoss {
            doc /* Derived (CV-17): follows from fleetSizeValue, the brief-fixed fleet size. Losing one of fleetSizeValue drones removes its even 1/N share of coverage before on-board RedistributeCoverage re-spreads the rest. No literal stated; fixed by the assert constraint below. */
        }
        assert constraint {
            doc /* coverageLossOnMemberLoss follows from the brief-fixed fleet size, not an independent estimate. */
            coverageLossOnMemberLoss == 1.0 / fleetSizeValue
        }
        #Estimate attribute jammedMeshAreaUnderWatchShare :> Common::jammedMeshAreaUnderWatchShare = 0.78 {
            doc /* Worst case: with half the mesh links jammed, on-board coordination has fewer intact peers to negotiate handover and redistribution with, so the margin above the brief's 0.75 target is tighter than a ground-decided design would need for the link itself, but coordination still completes without the ground link. */
        }
        #Estimate attribute groundLinkLossAreaUnderWatchShare :> Common::groundLinkLossAreaUnderWatchShare = 0.91 {
            doc /* Worst case: this is alternative 2's deciding trade-off. With 7 of 8 Coordination functions decided on board, coverage while the ground link or ground station is down is barely different from the nominal case, clearing the 0.9 target set here to match the continuous-watch figure. */
        }
        #Estimate attribute watchEnduranceHours :> Common::watchEnduranceHours = 48 [h] {
            doc /* Worst case: on-board RotateRecharge sustains continuous rotation across the fleet through the recharge cycle without a ground decision on every handover, clearing the 24 h target set here; bounded at 48 h by ground-crew/logistics turnaround, not by coordination. */
        }
        #Estimate attribute reportLatencySeconds :> Common::reportLatencySeconds = 45 [s] {
            doc /* Worst case with the ground link up: on-board triage reduces what must cross the ground link, keeping latency under the brief's 60 s allowance. */
        }
        #Estimate attribute positionErrorWithoutGnssMeters :> Common::positionErrorWithoutGnssMeters = 35 [m] {
            doc /* Worst case after 10 minutes without GNSS: stored-map matching bounds drift under the brief's 50 m allowance. */
        }
        #Estimate attribute reportHoldMinutes :> Common::reportHoldMinutes = 45 [min] {
            doc /* Worst case: on-board hold, sized against onboard storage, clears the brief's 30 minute minimum. */
        }
        #Estimate attribute reportsLostInLinkGap :> Common::reportsLostInLinkGap = 0 {
            doc /* Worst case: on-board hold-and-forward with no ground decision needed to keep holding means no report is dropped across a link gap, meeting the brief's none-lost requirement. */
        }
        #Estimate attribute missedDetectionShare :> Common::missedDetectionShare = 0.08 {
            doc /* Worst case for the on-board classifier under degraded weather, lighting and decoys, within the brief's 0.10 allowance. */
        }
        #Estimate attribute falseAlarmsPerHour :> Common::falseAlarmsPerHour = 1.5 {
            doc /* Worst case, count per hour reaching the operator after on-board triage; 1/h is not a plain library unit so the value is carried unitless. Within the brief's 2/h allowance. */
        }
        #Estimate attribute operatorAlertsPerHour :> Common::operatorAlertsPerHour = 16 {
            doc /* Worst case, count per hour after on-board triage; unitless for the same reason as falseAlarmsPerHour. Within the operatorAlertsPerHourBudget of 20/h. */
        }
        #Estimate attribute acknowledgedReportsThatMatterShare :> Common::acknowledgedReportsThatMatterShare = 0.83 {
            doc /* Worst case: on-board triage before the report reaches the operator raises the share that matters above the brief's 0.8 target. */
        }
        #Estimate attribute onboardClassificationCostUsd :> Common::onboardClassificationCostUsd = 275 {
            doc /* Worst case per drone; USD is not an ISQ unit so carried unitless per onboardClassificationCostBudget on SurveillanceDrone. Within the 300 USD cap. */
        }
        #prose part paTradeOff {
        doc /* Architecture trade-off for PA. Alternative 2 was taken.
                 alternative 1: total 0.75 (measures 0.93, review 0.50, structure 0.80, resilience 0.00)
                 alternative 2: total 0.88 (measures 1.00, review 0.50, structure 0.83, resilience 0.63)
                 The measures term scores the worst case of each alternative's own #Estimate: claims its architecture states with their basis, not measurements.
                 I would take alternative 2, on condition that its physical breakdown is filled in. The whole decision is where coordination lives. Alternative 1 puts all seven deciding coordination calls in groundStation.swarmCoordinator and formally accepts the consequence (GroundCoordinatorLossHazard): when the link or ground node is lost, drones fly their last assignment, rotation stops, and nothing plans a landing. Its own estimate of 0.55 coverage misses the 0.9 target, and it is optimistic, because with 40-minute flights and no recharge rotation coverage falls toward zero after one sortie. Alternative 2 moves those decisions onto the drones and gives each drone a real SafetyMonitor, separate from detection and classification. That keeps coverage and recall working through a ground outage. What still stops is admission, classifier-version control and any defined limit on flying unsupervised. Alternative 1 is the better model of hardware: missionComputer, reportStore, flightController and a ground ReportTriage can be bought and hosted, and its coverage-loss-per-drone figure (0.25) is honestly derived. Alternative 2 overclaims. Its 'on-board triage' behind the operator-workload estimates has no function or component, it has no compute or report store, and 1/12 coverage loss ignores that only about 4–5 drones are airborne at once. That is why alternative 2 scores low on realisability. Those gaps can be fixed by adding parts in the next layer. Alternative 1's weakness would mean re-architecting. */
        }
    }
    package EPBS {
        #prompt part epbsGuidance {
            doc /* EPBS: the configuration items actually procured, built or delivered to realise SurveillanceDroneSwarm's PA physical breakdown. Alternative 2's physical gaps (mission compute, report store, on-board triage, classifier-version/admission control) are closed here as named CIs, each carrying its own contract and verification case. Ground-side and drone-side software are split from the hardware they run on so a HWCI can be re-hosted without re-procuring its CSCI, and vice versa. */
        }

        // --- Drone air-vehicle hardware CI: airframe, flight controller, sensors, mission computer and on-board report store ---
        #CI_HWCI part def DroneAirVehicleItem {
            doc /* Hardware configuration item for one surveillance drone: airframe, flight controller, sensor payload, mission computer and on-board report-store hardware. Folds in the compute/storage hardware the PA trade-off flagged as missing from alternative 2. */
            attribute flightEnduranceMinutes = 40;
            attribute onboardClassificationCostUsd = 275;
        }
        part fleetCi : DroneAirVehicleItem [12] {
            doc /* The 12 fielded drone air-vehicle HWCIs, one per fleet member. */
        }
        trace fleetCi to SurveillanceDroneSwarm::PA::fleet;
        trace fleetCi to SurveillanceDroneSwarm::PA::memberA;
        trace fleetCi to SurveillanceDroneSwarm::PA::memberB;

        requirement def DroneAirVehicleContract {
            doc /* Contract a drone air-vehicle HWCI must meet: sortie endurance and on-board compute cost. */
            subject ci : DroneAirVehicleItem;
            attribute id = "EPBS-01";
            assume constraint {
                doc /* Assumes the brief-fixed fleet size this CI is procured against. */
                SurveillanceDroneSwarm::PA::fleetSizeValue <= 12
            }
            require constraint {
                doc /* memberFlightEnduranceMinutes budget: at least 40 minutes per sortie. */
                ci.flightEnduranceMinutes >= 40
            }
            require constraint {
                doc /* onboardClassificationCostUsd cap: at most 300 USD of on-board classification compute per drone. */
                ci.onboardClassificationCostUsd <= 300
            }
        }
        satisfy DroneAirVehicleContract by fleetCi;
        verification def VerifyDroneAirVehicleContract {
            doc /* Verifies the drone air-vehicle HWCI against its endurance and compute-cost contract. */
            subject ci : DroneAirVehicleItem;
            objective { verify DroneAirVehicleContract; }
        }

        // --- Drone mission software CI: on-board detect/classify/report, navigation fallback, triage and 7-of-8 coordination ---
        #CI_CSCI part def DroneMissionSoftwareItem {
            doc /* Software configuration item hosted on the drone air-vehicle HWCI: detection, classification and Unknown-when-uncertain reporting, stored-map-matching navigation, hold-and-forward buffering across a link gap, and the on-board coordination functions (handover, rotation, redistribution, deconfliction, relay, track correlation, track handover). Closes the PA trade-off's 'no function or component' gap behind on-board triage. */
            attribute reportHoldMinutes = 45;
            attribute reportsLostInLinkGap = 0;
            attribute missedDetectionShare = 0.08;
            attribute reportLatencySeconds = 45;
        }
        part droneMissionSoftwareCi : DroneMissionSoftwareItem [12] {
            doc /* The on-board mission software CSCI running on each of the 12 drones. */
        }
        trace droneMissionSoftwareCi to SurveillanceDroneSwarm::PA::SurveillanceDrone;
        trace droneMissionSoftwareCi to SurveillanceDroneSwarm::PA::SurveillanceDrone::navigationFallback;
        trace droneMissionSoftwareCi to SurveillanceDroneSwarm::PA::StoredMapMatchingNav;

        requirement def DroneMissionSoftwareContract {
            doc /* Contract the drone mission software CSCI must meet: report holding, no reports lost in a link gap, detection quality, and report latency once the link is up. */
            subject ci : DroneMissionSoftwareItem;
            attribute id = "EPBS-02";
            assume constraint {
                doc /* Assumes the brief-fixed area of interest this CI's detection/triage load is sized against. */
                SurveillanceDroneSwarm::PA::areaOfInterestBudget <= 25
            }
            require constraint {
                doc /* reportHoldMinutes target: hold at least 30 minutes of reports while cut off. */
                ci.reportHoldMinutes >= 30
            }
            require constraint {
                doc /* reportsLostInLinkGap target: none lost across a link gap. */
                ci.reportsLostInLinkGap <= 0
            }
            require constraint {
                doc /* missedDetectionShare target: at most 0.10 of real objects go undetected. */
                ci.missedDetectionShare <= 0.1
            }
            require constraint {
                doc /* reportLatencySeconds target: at most 60 seconds old when the link is up. */
                ci.reportLatencySeconds <= 60
            }
        }
        satisfy DroneMissionSoftwareContract by droneMissionSoftwareCi;
        verification def VerifyDroneMissionSoftwareContract {
            doc /* Verifies the drone mission software CSCI against its hold, no-loss, detection and latency contract. */
            subject ci : DroneMissionSoftwareItem;
            objective { verify DroneMissionSoftwareContract; }
        }

        // --- Safety monitor CI: dedicated override-authority hardware, kept separate from mission software ---
        #CI_HWCI part def SafetyMonitorItem {
            doc /* Dedicated on-board override-authority hardware/firmware module, procured and integrated separately from the drone mission software CSCI, so recall, geofence-breach and quarantine outcomes are enforced independently of detection, classification or coordination behaviour. */
            attribute isolationLevel = 1;
        }
        part safetyMonitorCi : SafetyMonitorItem [12] {
            doc /* One safety-monitor HWCI per drone, nested in but procured independently of the drone air-vehicle HWCI. */
        }
        trace safetyMonitorCi to SurveillanceDroneSwarm::PA::SurveillanceDrone::safetyMonitor;

        requirement def SafetyMonitorContract {
            doc /* Contract the safety-monitor CI must meet: independence from the mission software it can override. */
            subject ci : SafetyMonitorItem;
            attribute id = "EPBS-03";
            assume constraint {
                doc /* Assumes the brief-fixed fleet size this CI is procured against. */
                SurveillanceDroneSwarm::PA::fleetSizeValue <= 12
            }
            require constraint {
                doc /* Must be a physically/logically separate isolation domain from the drone mission software CSCI. */
                ci.isolationLevel >= 1
            }
        }
        satisfy SafetyMonitorContract by safetyMonitorCi;
        verification def VerifySafetyMonitorContract {
            doc /* Verifies the safety-monitor CI keeps its override authority independent of the mission software. */
            subject ci : SafetyMonitorItem;
            objective { verify SafetyMonitorContract; }
        }

        // --- Mesh radio CI: COTS drone-to-drone radio hardware ---
        #CI_COTS part def MeshRadioItem {
            doc /* COTS mesh radio hardware carrying inter-drone coordination traffic, independent of the ground link. */
            attribute jammedLinkAvailability = 0.6;
        }
        part meshRadioCi : MeshRadioItem [12] {
            doc /* One COTS mesh radio unit per drone. */
        }
        trace meshRadioCi to SurveillanceDroneSwarm::PA::SurveillanceDrone::meshRadio;
        trace meshRadioCi to SurveillanceDroneSwarm::PA::MeshRadio;

        requirement def MeshRadioContract {
            doc /* Contract the mesh radio CI must meet: keep a usable share of peer links available even when half the mesh is jammed. */
            subject ci : MeshRadioItem;
            attribute id = "EPBS-04";
            assume constraint {
                doc /* Assumes the brief-fixed fleet size this CI is procured against. */
                SurveillanceDroneSwarm::PA::fleetSizeValue <= 12
            }
            require constraint {
                doc /* At least half the mesh's links stay usable under jamming, matching the FleetConfiguration::MeshDegraded assumption on-board coordination relies on. */
                ci.jammedLinkAvailability >= 0.5
            }
        }
        satisfy MeshRadioContract by meshRadioCi;
        verification def VerifyMeshRadioContract {
            doc /* Verifies the mesh radio CI's usable-link share under jamming. */
            subject ci : MeshRadioItem;
            objective { verify MeshRadioContract; }
        }

        // --- Ground-link radio CI: COTS radio hardware, one def shared by drone-side and ground-side usages ---
        #CI_COTS part def GroundLinkRadioItem {
            doc /* COTS ground-link radio hardware, procured identically for every drone (so any drone can relay) and for the ground station. Procuring one unit per drone provides fleet-wide redundancy against a single radio failing outright (PA::Hazards::GroundLinkRadioFailureHazard). */
            attribute fleetRedundantUnits = 12;
        }
        part droneGroundRadioCi : GroundLinkRadioItem [12] {
            doc /* The ground-link radio hardware carried by every drone. */
        }
        trace droneGroundRadioCi to SurveillanceDroneSwarm::PA::SurveillanceDrone::groundRadio;
        part groundStationRadioCi : GroundLinkRadioItem {
            doc /* The ground station's own ground-link radio hardware, the fixed end of the link. */
        }
        trace groundStationRadioCi to SurveillanceDroneSwarm::PA::GroundStation::groundRadioNode;

        requirement def GroundLinkRadioContract {
            doc /* Contract the ground-link radio CI must meet: enough independently procured units across the fleet that one radio failing outright does not lose the ground link for good. */
            subject ci : GroundLinkRadioItem;
            attribute id = "EPBS-05";
            assume constraint {
                doc /* Assumes the brief-fixed fleet size this CI is procured against. */
                SurveillanceDroneSwarm::PA::fleetSizeValue <= 12
            }
            require constraint {
                doc /* At least dual redundancy across the fleet's ground-link radios. */
                ci.fleetRedundantUnits >= 2
            }
        }
        satisfy GroundLinkRadioContract by droneGroundRadioCi;
        satisfy GroundLinkRadioContract by groundStationRadioCi;
        verification def VerifyGroundLinkRadioContract {
            doc /* Verifies the ground-link radio CI's fleet-wide redundancy. */
            subject ci : GroundLinkRadioItem;
            objective { verify GroundLinkRadioContract; }
        }

        // --- Stored-map store CI: COTS reference-imagery storage each drone matches against without GNSS ---
        #CI_COTS part def StoredMapsStoreItem {
            doc /* COTS on-board storage holding the reference imagery each drone matches its camera view against when satellite positioning is unavailable. The currency and coverage of this store is what bounds a drone's position drift (PositionDriftHazard mitigation). */
            attribute positionErrorWithoutGnssMeters = 35;
        }
        part storedMapsStoreCi : StoredMapsStoreItem [12] {
            doc /* One stored-map store per drone. */
        }
        trace storedMapsStoreCi to SurveillanceDroneSwarm::PA::SurveillanceDrone::storedMaps;
        trace storedMapsStoreCi to SurveillanceDroneSwarm::PA::StoredMapsStore;

        requirement def StoredMapsStoreContract {
            doc /* Contract the stored-map store CI must meet: bound a drone's position error after 10 minutes without GNSS. */
            subject ci : StoredMapsStoreItem;
            attribute id = "EPBS-06";
            assume constraint {
                doc /* Assumes the brief-fixed fleet size this CI is procured against. */
                SurveillanceDroneSwarm::PA::fleetSizeValue <= 12
            }
            require constraint {
                doc /* positionErrorWithoutGnssMeters target: at most 50 m after 10 minutes without GNSS. */
                ci.positionErrorWithoutGnssMeters <= 50
            }
        }
        satisfy StoredMapsStoreContract by storedMapsStoreCi;
        verification def VerifyStoredMapsStoreContract {
            doc /* Verifies the stored-map store CI keeps position drift within budget. */
            subject ci : StoredMapsStoreItem;
            objective { verify StoredMapsStoreContract; }
        }

        // --- Ground station hardware CI ---
        #CI_HWCI part def GroundStationItem {
            doc /* Hardware configuration item for the operations centre's physical ground node: console, mounting for the ground-link radio, and the physical hosting for the ground control software CI. */
            attribute groundLinkPortCount = 2;
        }
        part groundStationCi : GroundStationItem {
            doc /* The single fielded ground station hardware CI. */
        }
        trace groundStationCi to SurveillanceDroneSwarm::PA::groundStation;

        requirement def GroundStationContract {
            doc /* Contract the ground station hardware CI must meet: enough ground-link port capacity to host the link. */
            subject ci : GroundStationItem;
            attribute id = "EPBS-07";
            assume constraint {
                doc /* Assumes the brief-fixed area of interest the ground station's mission serves. */
                SurveillanceDroneSwarm::PA::areaOfInterestBudget <= 25
            }
            require constraint {
                doc /* At least two ground-link ports, matching PA::GroundStation's two port usages. */
                ci.groundLinkPortCount >= 2
            }
        }
        satisfy GroundStationContract by groundStationCi;
        verification def VerifyGroundStationContract {
            doc /* Verifies the ground station hardware CI's port capacity. */
            subject ci : GroundStationItem;
            objective { verify GroundStationContract; }
        }

        // --- Ground control software CI: C2, admission and merge/triage software hosted on the ground station ---
        #CI_CSCI part def GroundControlSoftwareItem {
            doc /* Software configuration item hosted on the ground station HWCI: mission tasking, supervision, recall, status picture, report acknowledgement, mesh admission (the one Coordination function kept off the drones in alternative 2), classifier-version registration at admission, camera-network track merge, and alert throttling before reports reach the duty controller. */
            attribute operatorAlertsPerHour = 16;
            attribute operatorSecondsPerAlert = 30;
            attribute falseAlarmsPerHour = 1.5;
        }
        part groundControlSoftwareCi : GroundControlSoftwareItem {
            doc /* The single ground control software CSCI running on the ground station. */
        }
        trace groundControlSoftwareCi to SurveillanceDroneSwarm::PA::groundStation;

        requirement def GroundControlSoftwareContract {
            doc /* Contract the ground control software CI must meet: keep alerts within what the single duty controller can judge, with enough time per alert, and few false alarms. */
            subject ci : GroundControlSoftwareItem;
            attribute id = "EPBS-08";
            assume constraint {
                doc /* Assumes the brief-fixed operator-alert budget this CI's triage is sized against. */
                SurveillanceDroneSwarm::PA::GroundStation::operatorAlertsPerHourBudget <= 20
            }
            require constraint {
                doc /* operatorAlertsPerHour target: at most 20 alerts per hour reach the duty controller. */
                ci.operatorAlertsPerHour <= 20
            }
            require constraint {
                doc /* operatorSecondsPerAlert budget: at least 30 seconds available to judge each alert. */
                ci.operatorSecondsPerAlert >= 30
            }
            require constraint {
                doc /* falseAlarmsPerHour target: at most 2 false alarms per hour reach the operator. */
                ci.falseAlarmsPerHour <= 2
            }
        }
        satisfy GroundControlSoftwareContract by groundControlSoftwareCi;
        verification def VerifyGroundControlSoftwareContract {
            doc /* Verifies the ground control software CI's alert throughput, judging time and false-alarm rate. */
            subject ci : GroundControlSoftwareItem;
            objective { verify GroundControlSoftwareContract; }
        }

        // --- Recharge point CI: shared ground infrastructure and ground-crew station ---
        #CI_HWCI part def RechargePointItem {
            doc /* Hardware configuration item for the shared recharge point the fleet rotates through: charging bays, ground-crew servicing station. Sized with enough simultaneous bays that a scheduled handover always has a relieving drone (mitigates RechargeContentionHazard). */
            attribute rechargeMinutes = 60;
            attribute simultaneousDroneSlots = 2;
        }
        part rechargePointCi : RechargePointItem {
            doc /* The single fielded recharge point and ground-crew station. */
        }
        trace rechargePointCi to SurveillanceDroneSwarm::PA::rechargePoint;

        requirement def RechargePointContract {
            doc /* Contract the recharge point CI must meet: turnaround time per drone and enough simultaneous capacity to avoid recharge contention. */
            subject ci : RechargePointItem;
            attribute id = "EPBS-09";
            assume constraint {
                doc /* Assumes the brief-fixed recharge-time budget this CI is procured against. */
                SurveillanceDroneSwarm::PA::RechargePoint::rechargeMinutesBudget <= 60
            }
            require constraint {
                doc /* memberRechargeMinutes budget: at most about 60 minutes per drone. */
                ci.rechargeMinutes <= 60
            }
            require constraint {
                doc /* At least two simultaneous bays, so one scheduled handover is never left without a relieving drone. */
                ci.simultaneousDroneSlots >= 2
            }
        }
        satisfy RechargePointContract by rechargePointCi;
        verification def VerifyRechargePointContract {
            doc /* Verifies the recharge point CI's turnaround time and simultaneous capacity. */
            subject ci : RechargePointItem;
            objective { verify RechargePointContract; }
        }

        // --- EPBS-added hazards: procurement-level failure modes this layer's configuration-item choices introduce. None of SA's or PA's hazards are restated. ---
        package Hazards {
            #Hazard requirement CiClassifierAdmissionSkewHazard {
                doc /* EPBS hazard: procuring the ground control software CI and the on-board drone mission software CI as independently released configuration items risks the admission gate's registered classifier version drifting out of sync with what a drone is actually running, letting a stale or unregistered classifier version reach the fleet undetected. Distinct from SA::Hazards::MixedClassifierVersionsHazard, which is about the fleet-behaviour effect; this is the CI-release-discipline cause. */
                subject ci : GroundControlSoftwareItem;
                attribute id = "EPBS-HZ-01";
            }

            #Hazard #Accepted requirement SafetyMonitorSoleSourceHazard {
                doc /* EPBS hazard, accepted: the safety-monitor HWCI is sole-sourced from one supplier line; a disruption or recall of that line would leave the fleet without independently procured override-authority hardware. Accepted per program baseline — managed operationally by contract sparing, outside this model's scope. */
                subject ci : SafetyMonitorItem;
                attribute id = "EPBS-HZ-02";
            }

            #Hazard #Accepted requirement RechargePointSoleFacilityHazard {
                doc /* EPBS hazard, accepted: fielding a single recharge point and ground-crew station is itself a single point of failure for the whole fleet's turnaround, distinct from PA::Hazards::RechargeContentionHazard's bay-scheduling risk — an outage of the facility itself removes charging capability fleet-wide, not just contends for it. Accepted per the program's fixed single-site plan at this fleet size; a redundant site is out of procurement scope. */
                subject ci : RechargePointItem;
                attribute id = "EPBS-HZ-03";
            }
        }

        // --- Hazard satisfaction: every hazard stated so far (SA's eight, PA's two, this layer's one non-accepted), by the CI that mitigates it. None of SA's/PA's are restated; EPBS's two accepted hazards are tagged #Accepted above instead of satisfied. ---
        satisfy SurveillanceDroneSwarm::SA::Hazards::PositionDriftHazard by storedMapsStoreCi;
        satisfy SurveillanceDroneSwarm::SA::Hazards::MeshJammingHazard by meshRadioCi;
        satisfy SurveillanceDroneSwarm::SA::Hazards::MisclassificationHazard by droneMissionSoftwareCi;
        satisfy SurveillanceDroneSwarm::SA::Hazards::SensingDegradedUnnoticedHazard by droneMissionSoftwareCi;
        satisfy SurveillanceDroneSwarm::SA::Hazards::StaleTrackHazard by droneMissionSoftwareCi;
        satisfy SurveillanceDroneSwarm::SA::Hazards::SpoofedMemberHazard by groundControlSoftwareCi;
        satisfy SurveillanceDroneSwarm::SA::Hazards::MixedClassifierVersionsHazard by groundControlSoftwareCi;
        satisfy SurveillanceDroneSwarm::SA::Hazards::OperatorOverloadHazard by groundControlSoftwareCi;
        satisfy SurveillanceDroneSwarm::PA::Hazards::GroundLinkRadioFailureHazard by droneGroundRadioCi;
        satisfy SurveillanceDroneSwarm::PA::Hazards::GroundLinkRadioFailureHazard by groundStationRadioCi;
        satisfy SurveillanceDroneSwarm::PA::Hazards::RechargeContentionHazard by rechargePointCi;
        satisfy SurveillanceDroneSwarm::EPBS::Hazards::CiClassifierAdmissionSkewHazard by groundControlSoftwareCi;
    }
}
