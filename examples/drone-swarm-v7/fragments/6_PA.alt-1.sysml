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

        // ── architecture, alternative 1 ──
        /* ===================== Common-typed local infrastructure ===================== */

        doc /* physical ground-link radio node type flown aboard each drone; the member-side end of every GroundLinkRadio channel */
        part def MemberGroundRadio {
            out port uplinkOut : Common::GroundLinkPort;
            in port downlinkIn : ~Common::GroundLinkPort;
        }
        doc /* physical ground-link radio node type at the operations centre; the ground end of every drone's GroundLinkRadio channel */
        part def GroundStationRadio {
            in port uplinkIn : ~Common::GroundLinkPort;
            out port downlinkOut : Common::GroundLinkPort;
        }
        doc /* physical mesh radio node aboard each drone; carries MeshRadio traffic, decides nothing itself */
        part def MemberMeshRadio {
            doc /* the #Node that realises meshOut/meshIn on SurveillanceDrone; carries #Coordination traffic to and from other members */
        }
        doc /* off-the-shelf on-board classifier tier: higher accuracy, closer to the 300 USD cap */
        part def COTSClassifierModule {
            doc /* the classifier variant this architecture's onboardClassificationCostUsd estimate assumes */
        }
        doc /* lighter on-board classifier tier: trades accuracy for cost margin */
        part def LowPowerClassifierModule {
            doc /* kept as the fallback #Variant, not the one this estimate assumes */
        }
        doc /* on-board compute that runs the classifier against sensorPod frames; cost-capped by ComputingCostCap */
        part def MissionComputer {
            doc /* the on-board classifier tier is an alternative-1 design choice, tagged #Variant so it can be traded against cost and missedDetectionShare */
            variation part classifierModule : COTSClassifierModule {
                doc /* variability point: which classifier tier missionComputer runs */
                #Variant variant part cots : COTSClassifierModule {
                    doc /* the tier this architecture's onboardClassificationCostUsd estimate assumes */
                }
                #Variant variant part lowPower : LowPowerClassifierModule {
                    doc /* the lighter tier, kept as the cost-margin alternative */
                }
            }
        }
        doc /* the drone's camera/sensor payload that MissionComputer classifies frames from */
        part def SensorPod {
            doc /* source of MovingObjectsInArea frames; degrades under WeatherLightingAndDecoys */
        }
        doc /* matches live camera views against StoredMaps to hold a position estimate while SatellitePositioningOutage lasts */
        part def MapMatchNavigator {
            doc /* realises NavigateWithoutSatellitePositioning; bounds positionErrorWithoutGnssMeters */
        }
        doc /* flies the drone inside AirspaceClearance and WeatherLightingAndDecoys limits, and executes recall and landing */
        part def FlightController {
            doc /* carries the airborne side of RecallWins and GeofenceBreachEndsWatch */
        }
        doc /* holds DetectionReportsAndTracks and DecisionRecords produced while the ground link is down, until it returns */
        part def ReportStore {
            doc /* realises OperateThroughLinkGap; bounded by reportHoldMinutes so reportsLostInLinkGap stays at zero */
        }
        doc /* alternative 1's centralised swarm coordination: decides handOverSector, rotateRecharge, redistributeCoverage, deconflictMembers, correlateTracks, handOverTrack and admitMember for the whole fleet; the architecture decision this alternative makes */
        part def SwarmCoordinator {
            doc /* every deciding #Coordination function except relayLink, which stays on the fleet because every member performs it */
        }
        doc /* the DutyController's single seat: taskMission, commandSupervision, recallAndLand, presentStatusPicture and acknowledgeReport */
        part def SupervisionConsole {
            doc /* keeps all five #C2 functions on the ground, as both alternatives must */
        }
        doc /* ranks and de-duplicates DetectionReportsAndTracks before they reach the operator, and keeps the DecisionRecord for each */
        part def ReportTriage {
            doc /* realises TriageReports and KeepDecisionRecord centrally, using full-swarm context */
        }
        doc /* the operations-centre ground station hosting alternative 1's centralised coordination, supervision and triage (CV-06: hosting is nesting) */
        part def GroundStationNode {
            part swarmCoordinator : SwarmCoordinator;
            part supervisionConsole : SupervisionConsole;
            part reportTriage : ReportTriage;
            #Node part groundLinkRadio : GroundStationRadio;
        }
        doc /* the ground crew's servicing activity between sorties */
        part def GroundCrewService {
            doc /* realises RechargePointAndGroundCrew's servicing side */
        }
        doc /* where a drone lands, recharges for about memberRechargeMinutesPA, and is serviced before rejoining rotateRecharge */
        part def RechargePointNode {
            part groundCrewService : GroundCrewService;
        }
        /* ===================== The population (CV-16) ===================== */

        doc /* the replicable surveillance drone; CV-16's one member definition for the fleet usage and both named representatives. Its own #Mode and #State machines are nested here so RecallWins, ReturnsWhenIsolated, GeofenceBreachEndsWatch and QuarantinedStaysOut are carried directly by SurveillanceDrone, and NavigationDegraded, SensingDegraded, Isolated and Quarantined are states of this machine. */
        #Member part def SurveillanceDrone {
            out port meshOut : Common::MeshPort;
            in port meshIn : ~Common::MeshPort;

            doc /* the drone's sensing and navigation operating condition, independent of its lifecycle status */
            #Mode state def SurveillanceDroneMode {
                initial modeStart;
                doc /* satellite positioning and sensing both trusted */
                state Nominal;
                doc /* NavigationDegraded: no satellite positioning; navigates by matching camera views against StoredMaps */
                state NavigationDegraded;
                doc /* SensingDegraded: the drone's sensors cannot be trusted as they are */
                state SensingDegraded;

                transition modeStart -> Nominal;
                transition Nominal -> NavigationDegraded;
                transition NavigationDegraded -> Nominal;
                transition Nominal -> SensingDegraded;
                transition SensingDegraded -> Nominal;
            }
            doc /* the drone's operational lifecycle: airborne watch and coordination status, admission and clearance status; carries the rules the swarm never breaks */
            #State state def SurveillanceDroneState {
                initial start;
                doc /* on the ground, not flying */
                state Landed;
                doc /* departing towards its assigned sector */
                state TakingOff;
                doc /* holding watch over its assigned sector */
                state Watching;
                doc /* exchanging handover, rotation, redistribution, deconfliction, relay, track-correlation or admission traffic with other members */
                state Coordinating;
                doc /* Isolated: cut off from the other drones over the mesh */
                state Isolated;
                doc /* recalled by the operator or by swarmCoordinator; must land before it may watch again (RecallWins) */
                state Recalled;
                doc /* outside its cleared airspace; must land before it may watch again (GeofenceBreachEndsWatch) */
                state OutsideClearance;
                doc /* descending to land */
                state Landing;
                doc /* Quarantined: failed admission; takes no part in coordination until readmitted (QuarantinedStaysOut) */
                state Quarantined;
                doc /* passed a repeated admission check by admitMember and may resume coordination */
                state Readmitted;

                transition start -> Landed;
                transition Landed -> TakingOff;
                transition TakingOff -> Watching;
                transition TakingOff -> Quarantined;
                transition Watching -> Coordinating;
                transition Coordinating -> Watching;
                transition Watching -> Isolated;
                transition Isolated -> Landing;
                transition Isolated -> Coordinating;
                transition Watching -> Recalled;
                transition Coordinating -> Recalled;
                transition Recalled -> Landing;
                transition Watching -> OutsideClearance;
                transition Coordinating -> OutsideClearance;
                transition OutsideClearance -> Landing;
                transition Quarantined -> Readmitted;
                transition Readmitted -> Watching;
                transition Readmitted -> Coordinating;
                transition Landing -> Landed;

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
                    doc /* QuarantinedStaysOut: once a drone is quarantined, it takes no part in coordination until it has been readmitted. */
                    attribute pattern = "absence";
                    attribute scope = "between";
                    attribute q = "state Quarantined";
                    attribute r = "state Readmitted";
                    attribute p = "state Coordinating";
                }
                @SysproseVerification::PropertyPattern {
                    doc /* ReturnsWhenIsolated: from any situation a drone can be in, it can always get back to landed; an isolated drone included. */
                    attribute pattern = "recovery";
                    attribute scope = "globally";
                    attribute p = "state Landed";
                }
            }

            state mode : SurveillanceDroneMode;
            state status : SurveillanceDroneState;

            doc /* carries MeshRadio traffic for #Coordination handover, rotation, redistribution, deconfliction, relay, track-correlation and admission exchanges with peers */
            #Node part meshRadio : MemberMeshRadio;
            doc /* carries GroundLinkRadio traffic to and from groundStation */
            #Node part groundLinkRadio : MemberGroundRadio;
            part missionComputer : MissionComputer;
            part sensorPod : SensorPod;
            part mapMatchNavigator : MapMatchNavigator;
            part flightController : FlightController;
            part reportStore : ReportStore;
        }
        doc /* the fielded population: up to fleetSizePA identical drones; CV-16's fleet usage carrying the count, never one instance */
        part fleet : SurveillanceDrone [12] {
            state fleetStatus : FleetConfiguration;
        }
        doc /* CV-16 representative A, standing for either end of any pair of fleet members exchanging mesh traffic */
        part memberA : SurveillanceDrone;
        doc /* CV-16 representative B */
        part memberB : SurveillanceDrone;
        doc /* the physical medium type that carries mesh traffic between two members: the intermittent, jammable mesh radio bearer (CV-05) */
        connection def MeshRadioLink {
            end a : Common::MeshPort;
            end b : ~Common::MeshPort;
        }
        doc /* the mesh link between two drones, carried by MeshRadio and typed by MeshRadioLink; carries #Coordination traffic between peers */
        connection peerLink : MeshRadioLink connect memberA.meshOut to memberB.meshIn;
        doc /* every drone's report and status uplink to the ground station, over GroundLinkRadio; not always available (bounds groundLinkLossAreaUnderWatchShare) */
        connection uplink : Common::GroundLinkChannel connect fleet.groundLinkRadio.uplinkOut to groundStation.groundLinkRadio.uplinkIn;
        doc /* tasking, supervisory and recall commands, and swarmCoordinator's/supervisionConsole's decisions, from the ground to every drone */
        connection downlink : Common::GroundLinkChannel connect groundStation.groundLinkRadio.downlinkOut to fleet.groundLinkRadio.downlinkIn;
        /* ===================== Top-level physical nodes ===================== */

        doc /* the operations centre's ground station */
        #Node part groundStation : GroundStationNode;
        doc /* the recharge point and ground crew */
        #Node part rechargePoint : RechargePointNode;
        /* ===================== State definitions (modes and states option) ===================== */

        doc /* the fleet-wide share of jammed mesh links, tracked so the swarm can tell nominal mesh conditions from degraded ones */
        #Configuration state def FleetConfiguration {
            initial fleetStart;
            doc /* fewer than half the mesh links are jammed */
            state MeshNominal;
            doc /* MeshDegraded: a share of the links between drones is jammed */
            state MeshDegraded;

            transition fleetStart -> MeshNominal;
            transition MeshNominal -> MeshDegraded;
            transition MeshDegraded -> MeshNominal;
        }
        /* ===================== Allocations: every function to a physical part ===================== */

        doc /* alternative 1 keeps the deciding #Coordination functions on the ground */
        allocate handOverSector to groundStation.swarmCoordinator;
        allocate rotateRecharge to groundStation.swarmCoordinator;
        allocate redistributeCoverage to groundStation.swarmCoordinator;
        allocate deconflictMembers to groundStation.swarmCoordinator;
        allocate correlateTracks to groundStation.swarmCoordinator;
        allocate handOverTrack to groundStation.swarmCoordinator;
        allocate admitMember to groundStation.swarmCoordinator;
        doc /* relayLink is something every member performs, so it stays on the fleet rather than being a ground decision */
        allocate relayLink to fleet;
        doc /* every #C2 function keeps a ground usage, as both alternatives require */
        allocate taskMission to groundStation.supervisionConsole;
        allocate commandSupervision to groundStation.supervisionConsole;
        allocate recallAndLand to groundStation.supervisionConsole;
        allocate presentStatusPicture to groundStation.supervisionConsole;
        allocate acknowledgeReport to groundStation.supervisionConsole;
        doc /* on-board functions every member performs for itself: sensing, classification, navigation, reporting and decision-keeping */
        allocate holdSectorWatch to fleet;
        allocate detectAndClassifyObjects to fleet;
        allocate navigateAgainstStoredMaps to fleet;
        allocate reportDetections to fleet;
        allocate recordDecision to fleet;
        doc /* classifier version consistency across the fleet is a central decision in this ground-centric alternative, held alongside triage and supervision */
        allocate manageClassifierVersion to groundStation.supervisionConsole;
        /* ===================== Hazards this layer adds (CV-19 / safety option) ===================== */

        package Hazards {
            doc /* hazards alternative 1 (ground-decided coordination) adds on top of the ones already stated above; none of the brief's names are restated here */

            #Hazard #Accepted requirement GroundCoordinatorLossHazard {
                subject coordinator : SwarmCoordinator;
                doc /* Accepted: alternative 1 puts every deciding #Coordination function on groundStation.swarmCoordinator. When the ground link or the ground station is down, no new handover, rotation or redistribution decision is made; members hold their last assignment and keep watching, and relayLink (allocated to the fleet) keeps relaying detections towards each member's reportStore. This is why groundLinkLossAreaUnderWatchShare is estimated well below target for this alternative rather than mitigated further here; alternative 2 removes this single point by moving #Coordination onto the members themselves. */
            }

            #Hazard requirement CentralAdmissionGapHazard {
                doc /* A quarantined drone cannot be readmitted while the ground link is down, because admitMember is decided on the ground by groundStation.swarmCoordinator; it stays quarantined, taking no part in coordination, for as long as the gap lasts. */
            }
        }
        doc /* PositionDriftHazard: mitigated on board, by mapMatchNavigator inside every fleet member */
        satisfy SurveillanceDroneSwarm::SA::Hazards::PositionDriftHazard by fleet;
        doc /* MeshJammingHazard: mitigated by the fleet's mesh radios and relayLink redundancy */
        satisfy SurveillanceDroneSwarm::SA::Hazards::MeshJammingHazard by fleet;
        doc /* MisclassificationHazard: mitigated by each member's on-board classifier, which may report Unknown */
        satisfy SurveillanceDroneSwarm::SA::Hazards::MisclassificationHazard by fleet;
        doc /* SensingDegradedUnnoticedHazard: mitigated by the member's SensingDegraded mode, which makes degraded sensing visible rather than silent */
        satisfy SurveillanceDroneSwarm::SA::Hazards::SensingDegradedUnnoticedHazard by fleet;
        doc /* StaleTrackHazard: mitigated by correlateTracks and handOverTrack, decided centrally by groundStation, marking a track's staleness */
        satisfy SurveillanceDroneSwarm::SA::Hazards::StaleTrackHazard by groundStation;
        doc /* SpoofedMemberHazard: mitigated by admitMember, decided centrally by groundStation, the effective gatekeeper in this alternative */
        satisfy SurveillanceDroneSwarm::SA::Hazards::SpoofedMemberHazard by groundStation;
        doc /* MixedClassifierVersionsHazard: mitigated by groundStation.supervisionConsole holding one classifier version across the fleet */
        satisfy SurveillanceDroneSwarm::SA::Hazards::MixedClassifierVersionsHazard by groundStation;
        doc /* OperatorOverloadHazard: mitigated by groundStation.reportTriage, which caps what reaches the operator */
        satisfy SurveillanceDroneSwarm::SA::Hazards::OperatorOverloadHazard by groundStation;
        doc /* CentralAdmissionGapHazard: mitigated by the member holding Quarantined until the ground link returns and admitMember can run */
        satisfy Hazards::CentralAdmissionGapHazard by fleet;
        /* ===================== Resource budgets restated locally, for derivation (CV-17) ===================== */

        doc /* restates the brief-fixed fleetSize budget (<= 12) so coverageLossOnMemberLoss can be derived below; a constraint body cannot reach Common's fleetSize directly */
        attribute fleetSizePA : Real = 12;
        doc /* restates the brief-fixed memberFlightEnduranceMinutes budget (about 40 min) */
        attribute memberFlightEnduranceMinutesPA : Real = 40;
        doc /* restates the brief-fixed memberRechargeMinutes budget (about 60 min) */
        attribute memberRechargeMinutesPA : Real = 60;
        doc /* worst-case members concurrently airborne: fleetSizePA * memberFlightEnduranceMinutesPA / (memberFlightEnduranceMinutesPA + memberRechargeMinutesPA) = 12*40/100 = 4.8, floored to the worst case of 4 evenly-spread members before the swarm re-spreads */
        attribute airborneMembersPA : Real = 4;
        require constraint computingCostBudget {
            doc /* ComputingCostCap: on-board classification computing must not exceed 300 USD per drone */
            onboardClassificationCostUsd <= 300
        }
        require constraint operatorWorkloadBudget {
            doc /* OperatorWorkloadLimit: at most 20 alerts reach the operator per hour */
            operatorAlertsPerHour <= 20
        }
        require constraint rechargeCycleBudget {
            doc /* RechargePointAndGroundCrew: a drone's recharge, restated here in minutes, must not exceed the fixed budget rotateRecharge plans against */
            memberRechargeMinutesPA <= 60
        }
        /* ===================== Estimates: this architecture's worst-case value per MoE (CV-17) ===================== */

        #Estimate attribute coverageLossOnMemberLoss :> Common::coverageLossOnMemberLoss {
            doc /* derived, not stated: with about airborneMembersPA members concurrently airborne, losing one costs about one airborne member's share of the watch before the swarm re-spreads */
        }
        assert constraint { coverageLossOnMemberLoss == 1 / airborneMembersPA }
        #Estimate attribute areaUnderWatchShare :> Common::areaUnderWatchShare = 0.9 {
            doc /* nominal case, ground link up: sectors are sized so at least one of the airborneMembersPA concurrently airborne drones watches every sector at all times, matching HoldContinuousWatch */
        }
        #Estimate attribute jammedMeshAreaUnderWatchShare :> Common::jammedMeshAreaUnderWatchShare = 0.8 {
            doc /* the mesh carries only handover/rotation/relay #Coordination traffic in this alternative, not the deciding function itself, which runs on groundStation over the ground link; jamming half the mesh links slows handover and relay but a drone with its ground link up keeps watching its assigned sector */
        }
        #Estimate attribute groundLinkLossAreaUnderWatchShare :> Common::groundLinkLossAreaUnderWatchShare = 0.55 {
            doc /* alternative 1's weak point, see Hazards::GroundCoordinatorLossHazard: every deciding #Coordination function and all #C2 sit on groundStation, so when the ground link or ground station is down no new handover, rotation or redistribution decision is made and coverage decays below target for the outage's duration */
        }
        #Estimate attribute watchEnduranceHours :> Common::watchEnduranceHours = 26 {
            doc /* continuous rotateRecharge decisions from groundStation.swarmCoordinator keep members cycling through rechargePoint indefinitely while the ground link holds; bounded here by an assumed 26 h before ground crew need to intervene on equipment, not by the swarm's own endurance */
        }
        #Estimate attribute reportLatencySeconds :> Common::reportLatencySeconds = 45 [SI::s] {
            doc /* detection to ground: on-board classification, one groundLinkRadio hop over GroundLinkRadio, then reportTriage; no extra mesh hop, since the deciding path in this alternative runs straight to the ground */
        }
        #Estimate attribute positionErrorWithoutGnssMeters :> Common::positionErrorWithoutGnssMeters = 40 [SI::m] {
            doc /* mapMatchNavigator matching camera views against StoredMaps for 10 minutes without satellite positioning */
        }
        #Estimate attribute reportHoldMinutes :> Common::reportHoldMinutes = 35 {
            doc /* reportStore is sized to outlast the expected ground-link gap by a margin above the 30-minute target */
        }
        #Estimate attribute reportsLostInLinkGap :> Common::reportsLostInLinkGap = 0 {
            doc /* reportStore holds every report until the ground link returns, within reportHoldMinutes; OperateThroughLinkGap loses none */
        }
        #Estimate attribute missedDetectionShare :> Common::missedDetectionShare = 0.08 {
            doc /* missionComputer's on-board classifier (see the classifierModule variation), with SensingDegraded reported rather than silently trusted */
        }
        #Estimate attribute falseAlarmsPerHour :> Common::falseAlarmsPerHour = 1.5 {
            doc /* groundStation.reportTriage runs with full-swarm context, de-duplicating before an alert reaches the operator */
        }
        #Estimate attribute operatorAlertsPerHour :> Common::operatorAlertsPerHour = 18 {
            doc /* groundStation.reportTriage caps what reaches supervisionConsole, inside OperatorWorkloadLimit */
        }
        #Estimate attribute acknowledgedReportsThatMatterShare :> Common::acknowledgedReportsThatMatterShare = 0.82 {
            doc /* centralised triage improves the precision of what the DutyController is asked to acknowledge */
        }
        #Estimate attribute onboardClassificationCostUsd :> Common::onboardClassificationCostUsd = 280 {
            doc /* USD per drone, missionComputer's cots classifier variant (see classifierModule); the ground carries the heavier cross-checking (correlateTracks, reportTriage), so the on-board tier can stay under the 300 USD ComputingCostCap */
        }
    }
