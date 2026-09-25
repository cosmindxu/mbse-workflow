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
}
