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
