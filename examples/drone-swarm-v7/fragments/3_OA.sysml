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
