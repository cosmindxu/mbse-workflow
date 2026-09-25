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
    // ---- Hazards this alternative adds ----
            doc /* hazards added at LA: risks visible once the coordination-decision and command-and-control
                 functions are allocated to specific logical components. */

            #Hazard #Accepted requirement GroundLinkSinglePointOfFailureHazard {
                doc /* Because this alternative centralises the deciding half of inter-member coordination at
                     the ground control station, a lost ground link stalls sector handover, recharge rotation,
                     redistribution, deconfliction, relay assignment, track correlation, track handover and
                     admission fleet-wide, even though detection, classification, navigation and local
                     report-holding continue on board. Accepted for this alternative: the trade study's second
                     alternative addresses it by moving at least half of the coordination functions onto the
                     members so they keep settling among themselves without the ground link; the low
                     groundLinkLossAreaUnderWatchShare estimate below states the residual risk this alternative
                     carries instead of mitigating it. */
                subject s : GroundControlStation;
            }
            }
            satisfy Hazards::MemberCollisionHazard by deconflictMembers;
            satisfy Hazards::PrematureDepartureHazard by handOverSector;
            satisfy Hazards::UncoveredMemberLossHazard by redistributeCoverage;
            satisfy Hazards::UnrelayedIsolationHazard by relayLink;

            // ── architecture, alternative 1 ──
            doc /* Logical Architecture, alternative 1 of 2: Ground-Centralised Coordination. The deciding half of
                 every #Coordination function and all five #C2 functions are hosted in one ground logical
                 component, groundControlStation; the twelve-member fleet keeps the per-member mission functions
                 (watch, detect and classify, navigate against stored maps, hold and send its own reports, keep
                 its own decision-record contribution) on board, so the data path survives a ground-link gap even
                 though re-planning coordination does not. Alternative 2 is expected to move at least half of the
                 eight #Coordination functions onto the members instead. */

            // ---- Ground logical component ----

            part def GroundControlStation {
                doc /* the ground-hosted logical component of this alternative: takes in tasking, supervision,
                     recall and acknowledgement from the operations centre and duty controller, forwards them to
                     the fleet, aggregates the fleet's detections, decision-record contributions and status, and
                     makes the deciding half of inter-member coordination -- sector handover, recharge rotation,
                     coverage redistribution, deconfliction, mesh relay assignment, track correlation, track
                     handover and admission -- issuing its directives to the fleet. If the ground link drops,
                     re-planning coordination stalls fleet-wide (no new handover, rotation, redistribution,
                     deconfliction, relay assignment, correlation, track handover or admission decisions), while
                     onboard watch, detection, classification, navigation and local report-holding continue
                     unaffected because those stay allocated to the fleet. If the ground control station itself
                     fails, the same coordination functions stop being decided anywhere in this alternative --
                     there is no member-side fallback for them -- until the station is restored or the fleet is
                     re-tasked under alternative 2's split. */
                in port taskingIn : Common::MissionTasking { doc /* mission tasking taken in from the operations centre. */ }
                in port supervisionIn : Common::SupervisoryAndRecallCommands { doc /* supervisory commands taken in from the duty controller. */ }
                in port recallIn : Common::SupervisoryAndRecallCommands { doc /* recall-and-land orders taken in from the duty controller. */ }
                in port ackIn : Common::ReportAcknowledgements { doc /* report acknowledgements taken in from the duty controller. */ }
                out port reportsOut : Common::DetectionReportsAndTracks { doc /* triaged, de-duplicated reports and tracks sent to the operations centre. */ }
                out port decisionsOut : Common::DecisionRecords { doc /* decision records sent to the operations centre. */ }
                out port statusOut : Common::StatusPicture { doc /* the aggregated status picture sent to the duty controller. */ }
                out port rechargeRequestOut : Common::CoordinationMessage { doc /* recharge-slot requests sent to the ground crew. */ }
                out port missionOut : Common::MissionTasking { doc /* mission tasking forwarded down to the fleet. */ }
                out port commandOut : Common::SupervisoryAndRecallCommands { doc /* supervisory and recall-and-land commands forwarded down to the fleet. */ }
                out port ackForwardOut : Common::ReportAcknowledgements { doc /* acknowledgement forwarded to the member whose decision record it closes out. */ }
                out port directiveOut : Common::CoordinationMessage { doc /* the deciding coordination directives -- handover, rotation, redistribution, deconfliction, relay assignment, correlation, track handover, admission -- issued to the fleet. */ }
                in port detectionsIn : Common::DetectionReportsAndTracks { doc /* each member's local detections and tracks, taken in for correlation and triage. */ }
                in port decisionsIn : Common::DecisionRecords { doc /* each member's decision-record contribution, taken in for completion. */ }
                in port statusIn : Common::StatusPicture { doc /* each member's status contribution, taken in for aggregation. */ }
            }
            part groundControlStation : GroundControlStation {
                doc /* the single ground logical component of this alternative; hosts every deciding #Coordination usage and every #C2 usage. */
            }
            // ---- Population: one member definition, a fleet usage carrying the count, two representatives ----

            #Member part def SurveillanceDrone {
                doc /* one member of the fielded population: replicable and identical, carrying its own onboard
                     watch, detect-and-classify, navigate-against-stored-maps and report/decision-record functions,
                     plus the mesh peer ports used for peer-to-peer traffic and directive relay. In this
                     alternative the member executes locally but does not decide sector handover, recharge
                     rotation, redistribution, deconfliction, relay assignment, track correlation, track handover
                     or admission -- those are decided by the ground control station. Carries its own #Mode
                     machine, nested directly here per CV-18/CV-19, holding the brief's named degraded modes and
                     the four rules the system never breaks. */
                out port meshOut : Common::MeshPort { doc /* outbound peer mesh traffic to another member. */ }
                in port meshIn : ~Common::MeshPort { doc /* inbound peer mesh traffic from another member. */ }
                in port directiveIn : Common::CoordinationMessage { doc /* the ground control station's coordination directive for this member. */ }
                in port missionIn : Common::MissionTasking { doc /* mission tasking forwarded from the ground control station. */ }
                in port commandIn : Common::SupervisoryAndRecallCommands { doc /* supervisory and recall-and-land commands forwarded from the ground control station. */ }
                in port ackForwardIn : Common::ReportAcknowledgements { doc /* acknowledgement forwarded from the ground control station for a report this member sent. */ }
                out port detectionsOut : Common::DetectionReportsAndTracks { doc /* this member's own local detections and tracks, sent up for correlation and triage. */ }
                out port decisionOut : Common::DecisionRecords { doc /* this member's decision-record contribution, sent up for completion. */ }
                out port statusOut : Common::StatusPicture { doc /* this member's position, activity, coverage and degradation, sent up for aggregation. */ }

                #Variant attribute localFallbackOnIsolation = true { doc /* design option: whether an isolated member falls back to its last ground-issued directive instead of holding position; on in this alternative to bound coverage loss during brief ground-link gaps. */ }

                #Mode state def MemberMode {
                    doc /* this member's own operating-mode machine, owned directly by SurveillanceDrone: nominal
                         watching, the brief's named degraded and constrained conditions, and landed. Carries the
                         four rules the system never breaks so they are checked on the part def the brief assigns
                         them to, per CV-18/CV-19, rather than on a shared placeholder machine. */
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
                        doc /* cut off from the other drones; per localFallbackOnIsolation, falls back to the last ground-issued directive rather than holding position. */
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

                state mode : MemberMode;
                state status : MemberStatus { doc /* this member's coarse platform status. */ }
            }
            part fleet : SurveillanceDrone [12] {
                doc /* the population: twelve identical member drones, replicated from the SurveillanceDrone
                     member definition; each carries its own MemberMode/MemberStatus, and together they carry the
                     fleet-level FleetConfiguration. */
                state config : FleetConfiguration { doc /* the fleet-level watch configuration shared by the population. */ }
            }
            part memberA : SurveillanceDrone { doc /* representative member, used to show the peer mesh interface between two drones. */ }
            part memberB : SurveillanceDrone { doc /* representative peer of memberA across the mesh link. */ }
            interface peerLink : Common::MeshLink connect memberA.meshOut to memberB.meshIn {
                doc /* the peer mesh link between two representative drones, carried by MeshRadio; models the
                     drone-to-drone traffic -- directive relay, handover execution, track handover -- that does
                     not depend on the ground link. */
            }
            // ---- Ground <-> external actors (this layer's boundary, not the SA system's ports) ----

            connection taskingLinkLA connect SurveillanceDroneSwarm::SA::operationsCentre.taskingOut to groundControlStation.taskingIn {
                doc /* carries mission tasking from the operations centre into the ground control station. */
            }
            connection supervisionLinkLA connect SurveillanceDroneSwarm::SA::dutyController.supervisionOut to groundControlStation.supervisionIn {
                doc /* carries supervisory commands from the duty controller into the ground control station. */
            }
            connection recallLinkLA connect SurveillanceDroneSwarm::SA::dutyController.recallOut to groundControlStation.recallIn {
                doc /* carries recall-and-land orders from the duty controller into the ground control station. */
            }
            connection ackLinkLA connect SurveillanceDroneSwarm::SA::dutyController.ackOut to groundControlStation.ackIn {
                doc /* carries report acknowledgements from the duty controller into the ground control station. */
            }
            connection reportsLinkLA connect groundControlStation.reportsOut to SurveillanceDroneSwarm::SA::operationsCentre.reportsIn {
                doc /* carries the ground-finalised, triaged detection reports and tracks to the operations centre. */
            }
            connection decisionsLinkLA connect groundControlStation.decisionsOut to SurveillanceDroneSwarm::SA::operationsCentre.decisionsIn {
                doc /* carries decision records to the operations centre. */
            }
            connection statusLinkLA connect groundControlStation.statusOut to SurveillanceDroneSwarm::SA::dutyController.statusIn {
                doc /* carries the aggregated status picture to the duty controller. */
            }
            connection rechargeLinkLA connect groundControlStation.rechargeRequestOut to SurveillanceDroneSwarm::SA::groundCrew.rechargeIn {
                doc /* carries recharge-slot requests to the ground crew. */
            }
            // ---- Ground <-> fleet (internal) ----

            connection missionForward connect groundControlStation.missionOut to fleet.missionIn {
                doc /* forwards mission tasking from the ground control station to every member. */
            }
            connection commandForward connect groundControlStation.commandOut to fleet.commandIn {
                doc /* forwards supervisory and recall-and-land commands from the ground control station to every member. */
            }
            connection ackForward connect groundControlStation.ackForwardOut to fleet.ackForwardIn {
                doc /* forwards acknowledgement to the member whose decision record it closes out. */
            }
            connection directiveForward connect groundControlStation.directiveOut to fleet.directiveIn {
                doc /* carries the ground control station's coordination directives to the fleet. */
            }
            connection detectionsUp connect fleet.detectionsOut to groundControlStation.detectionsIn {
                doc /* carries each member's local detections and tracks up for correlation and triage. */
            }
            connection decisionsUp connect fleet.decisionOut to groundControlStation.decisionsIn {
                doc /* carries each member's decision-record contribution up for completion. */
            }
            connection statusUp connect fleet.statusOut to groundControlStation.statusIn {
                doc /* carries each member's status contribution up for aggregation. */
            }
            // ---- Function allocation: one allocate per function ----

            allocate holdSectorWatch to fleet;
            allocate detectAndClassifyObjects to fleet;
            allocate navigateAgainstStoredMaps to fleet;
            allocate reportDetections to fleet;
            allocate recordDecision to fleet;
            allocate manageClassifierVersion to groundControlStation;
            allocate presentStatusPicture to groundControlStation;
            allocate taskMission to groundControlStation;
            allocate commandSupervision to groundControlStation;
            allocate recallAndLand to groundControlStation;
            allocate acknowledgeReport to groundControlStation;
            allocate handOverSector to groundControlStation;
            allocate rotateRecharge to groundControlStation;
            allocate redistributeCoverage to groundControlStation;
            allocate deconflictMembers to groundControlStation;
            allocate relayLink to groundControlStation;
            allocate correlateTracks to groundControlStation;
            allocate handOverTrack to groundControlStation;
            allocate admitMember to groundControlStation;
            // ---- Modes and states ----

            #State state def MemberStatus {
                doc /* the coarse platform status of one member drone, independent of its watch mode. */
                initial start; transition start -> Idle;
                state Idle { doc /* on the ground, available but not tasked. */ }
                state Active { doc /* airborne and performing tasked activity. */ }
                state Recharging { doc /* at a recharge point being serviced by the ground crew, about 60 minutes. */ }
                transition Idle -> Active;
                transition Active -> Recharging;
                transition Recharging -> Idle;
            }
            // ---- Rules, carried from SA, satisfied by the member's own state machine (MemberMode, nested above) ----

            satisfy SurveillanceDroneSwarm::SA::RecallWins by fleet;
            satisfy SurveillanceDroneSwarm::SA::ReturnsWhenIsolated by fleet;
            satisfy SurveillanceDroneSwarm::SA::GeofenceBreachEndsWatch by fleet;
            satisfy SurveillanceDroneSwarm::SA::QuarantinedStaysOut by fleet;
            // ---- Hazards stated at SA, satisfied by path here ----

            satisfy SurveillanceDroneSwarm::SA::Hazards::PositionDriftHazard by fleet;
            satisfy SurveillanceDroneSwarm::SA::Hazards::MeshJammingHazard by groundControlStation;
            satisfy SurveillanceDroneSwarm::SA::Hazards::MisclassificationHazard by fleet;
            satisfy SurveillanceDroneSwarm::SA::Hazards::SensingDegradedUnnoticedHazard by fleet;
            satisfy SurveillanceDroneSwarm::SA::Hazards::StaleTrackHazard by groundControlStation;
            satisfy SurveillanceDroneSwarm::SA::Hazards::SpoofedMemberHazard by groundControlStation;
            satisfy SurveillanceDroneSwarm::SA::Hazards::MixedClassifierVersionsHazard by groundControlStation;
            satisfy SurveillanceDroneSwarm::SA::Hazards::OperatorOverloadHazard by groundControlStation;
            // ---- Hazards stated at LA, satisfied by a component of this architecture (not only by the shared function) ----

            satisfy LA::Hazards::MemberCollisionHazard by groundControlStation;
            satisfy LA::Hazards::PrematureDepartureHazard by groundControlStation;
            satisfy LA::Hazards::UncoveredMemberLossHazard by groundControlStation;
            satisfy LA::Hazards::UnrelayedIsolationHazard by groundControlStation;
            // ---- Measures of effectiveness: this architecture's own worst-case estimate ----

            attribute laFleetSize = 12.0 { doc /* restated from the brief's fixed fleet-size budget (fleetSize), to derive coverageLossOnMemberLoss. */ }
            attribute laMemberFlightEnduranceMinutes = 40.0 { doc /* restated from the brief's fixed flight-endurance budget (memberFlightEnduranceMinutes), to derive coverageLossOnMemberLoss. */ }
            attribute laMemberRechargeMinutes = 60.0 { doc /* restated from the brief's fixed recharge-time budget (memberRechargeMinutes), to derive coverageLossOnMemberLoss. */ }
            #Estimate attribute areaUnderWatchShare :> Common::areaUnderWatchShare = 0.90 { doc /* worst case with the ground link up: ground-scheduled rotation across 12 drones (40 min flight, 60 min recharge) keeps the tasked sectors watched at the brief's 0.9 continuous-watch figure; basis: FleetOfTwelveDrones, memberFlightEnduranceMinutes, memberRechargeMinutes. */ }
            #Estimate attribute coverageLossOnMemberLoss :> Common::coverageLossOnMemberLoss { doc /* derived worst case: the share of coverage lost when one drone is lost is the reciprocal of the number of members concurrently active under the flight/recharge duty cycle, before the ground control station redistributes coverage; basis: fleetSize, memberFlightEnduranceMinutes, memberRechargeMinutes restated above. */ }
            assert constraint { coverageLossOnMemberLoss == 1.0 / (laFleetSize * laMemberFlightEnduranceMinutes / (laMemberFlightEnduranceMinutes + laMemberRechargeMinutes)) }
            #Estimate attribute jammedMeshAreaUnderWatchShare :> Common::jammedMeshAreaUnderWatchShare = 0.80 { doc /* worst case with half the mesh links jammed: normal tasking and rotation are directed over the ground link, not the mesh, so watch continues; only relay-for-isolated-members, track correlation and track handover degrade; basis: RadioInterference, ground-link-directed coordination. */ }
            #Estimate attribute groundLinkLossAreaUnderWatchShare :> Common::groundLinkLossAreaUnderWatchShare = 0.55 { doc /* worst case while the ground link or ground station is down: sector handover, recharge rotation, redistribution, deconfliction, relay assignment, track correlation, track handover and admission are all decided at the ground control station in this alternative, so re-planning stalls fleet-wide and coverage decays below the 0.9 target until the link returns; basis: this alternative's ground-centralised coordination allocation, contrasted with alternative 2. */ }
            #Estimate attribute watchEnduranceHours :> Common::watchEnduranceHours = 20.0 { doc /* worst case: ground-scheduled rotation sustains the watch indefinitely while the ground link holds, but a prolonged ground-link outage degrades scheduling within a working day, so the guaranteed endurance without people is capped below the brief's 24 h target; basis: memberFlightEnduranceMinutes, memberRechargeMinutes, RechargePointAndGroundCrew. */ }
            #Estimate attribute reportLatencySeconds :> Common::reportLatencySeconds = 45.0 { doc /* worst case with the ground link up: a mesh hop to a ground-link-capable member plus ground-station triage before forwarding to the operations centre; basis: MeshRadio and GroundLinkRadio hop budget. */ }
            #Estimate attribute positionErrorWithoutGnssMeters :> Common::positionErrorWithoutGnssMeters = 40.0 { doc /* worst case after 10 minutes without satellite positioning: onboard camera-against-stored-map navigation, unaffected by where coordination is decided; basis: StoredMaps, NavigateWithoutSatellitePositioning. */ }
            #Estimate attribute reportHoldMinutes :> Common::reportHoldMinutes = 45.0 { doc /* worst case: a cut-off member holds its reports on board regardless of coordination placement, since detection, classification and report-holding stay onboard; basis: OperateThroughLinkGap, reportDetections and recordDecision allocated to fleet. */ }
            #Estimate attribute reportsLostInLinkGap :> Common::reportsLostInLinkGap = 0 { doc /* worst case: none, since report generation and holding are allocated to the fleet, not the ground control station, so a ground-link gap cannot lose a held report; basis: fleet allocation of reportDetections and recordDecision. */ }
            #Estimate attribute missedDetectionShare :> Common::missedDetectionShare = 0.08 { doc /* worst case: onboard detection and classification are unaffected by coordination placement; basis: DetectClassifyAndReport, onboard sensing. */ }
            #Estimate attribute falseAlarmsPerHour :> Common::falseAlarmsPerHour = 1.8 { doc /* worst case: raw member detections queue without the ground station's correlation during a ground-link gap, raising duplicate/false alarms until the link returns and correlateTracks resumes; basis: correlateTracks and handOverTrack allocated to the ground control station in this alternative. */ }
            #Estimate attribute operatorAlertsPerHour :> Common::operatorAlertsPerHour = 15.0 { doc /* worst case: centralising triage at the single ground control station gives one choke point to cap the rate reaching the duty controller, comfortably under the 20/h OperatorWorkloadLimit; basis: ground-centralised triage before reportsOut. */ }
            #Estimate attribute acknowledgedReportsThatMatterShare :> Common::acknowledgedReportsThatMatterShare = 0.82 { doc /* worst case: centralised, consistent triage at the ground control station improves the precision of what reaches the duty controller; basis: correlateTracks and recordDecision allocated to the ground control station. */ }
            #Estimate attribute onboardClassificationCostUsd :> Common::onboardClassificationCostUsd = 280.0 { doc /* worst case per drone: the same onboard classifier hardware is assumed regardless of coordination placement, since detectAndClassifyObjects stays onboard; basis: ComputingCostCap. */ }
        }
