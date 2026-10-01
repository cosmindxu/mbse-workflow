    package PA {
        #prompt part paGuidance {
            doc /* PA: the components that will be built. Behaviour parts are hosted in node parts by nesting, physical links are typed, item definitions carry units, and resource budgets are require constraints. */
        }

        // the system, to be decomposed into physical components
        part def SurveillanceDroneSwarmPhysical {
            out port reportsOut : LA::SwarmMember::reportsOut;
            out port trackPictureOut : LA::SwarmMember::trackPictureOut;
            out port statusOut : LA::SwarmMember::statusOut;
            in port taskingIn : LA::SwarmMember::taskingIn;
            in port priorityIn : LA::SwarmMember::priorityIn;
            in port recallIn : LA::SwarmMember::recallIn;
            in port receiptIn : LA::SwarmMember::receiptIn;
            doc /* The system as one physical whole, carried over from LA with its ports. It is built from the PA parts declared beside it — fleet, groundStation, groundRecallTransmitter, groundAlertTriage, groundDecisionRecordStore — which carry the functions (see the allocations); mainAssembly is its usage. */
        }

        // the population: 12 identical members (CV-16)
        #prose part fleetFact {
            doc /* Population: 12 members of SwarmMember, carried by fleet, exchanging through Common::MeshInterface. Carried from the brief; the architecture instantiates it. */
        }

        // functions, carried over from LA: every one of them has to be realised here
        action def HandOverSector {
            doc /* Realises LA::HandOverSector at PA: performed on board every drone of the fleet (allocate handOverSector to fleet). */
        }
        action def RotateRecharge {
            doc /* Realises LA::RotateRecharge at PA: performed on board every drone of the fleet (allocate rotateRecharge to fleet). */
        }
        action def RedistributeCoverage {
            doc /* Realises LA::RedistributeCoverage at PA: performed on board every drone of the fleet (allocate redistributeCoverage to fleet). */
        }
        action def DeconflictFlight {
            doc /* Realises LA::DeconflictFlight at PA: performed on board every drone of the fleet (allocate deconflictFlight to fleet). */
        }
        action def RelayReportsThroughNeighbour {
            doc /* Realises LA::RelayReportsThroughNeighbour at PA: performed on board every drone of the fleet (allocate relayReportsThroughNeighbour to fleet). */
        }
        action def CorrelateTracks {
            doc /* Realises LA::CorrelateTracks at PA: performed on board every drone of the fleet (allocate correlateTracks to fleet). */
        }
        action def HandOverTrack {
            doc /* Realises LA::HandOverTrack at PA: performed on board every drone of the fleet (allocate handOverTrack to fleet). */
        }
        action def AdmitMember {
            doc /* Realises LA::AdmitMember at PA: performed on board every drone of the fleet (allocate admitMember to fleet). */
        }
        action def TaskSurveillanceArea {
            doc /* Realises LA::TaskSurveillanceArea at PA: performed by the ground station (groundStation, command and control only) (allocate taskSurveillanceArea to groundStation). */
        }
        action def CommandSupervisoryPriorities {
            doc /* Realises LA::CommandSupervisoryPriorities at PA: performed by the ground station (groundStation, command and control only) (allocate commandSupervisoryPriorities to groundStation). */
        }
        action def RecallAndLand {
            doc /* Realises LA::RecallAndLand at PA: performed by the ground recall transmitter, the direct recall path from the ground to the fleet (allocate recallAndLand to groundRecallTransmitter). */
        }
        action def PresentStatusPicture {
            doc /* Realises LA::PresentStatusPicture at PA: performed by the ground station (groundStation, command and control only) (allocate presentStatusPicture to groundStation). */
        }
        action def AcknowledgeDetectionReport {
            doc /* Realises LA::AcknowledgeDetectionReport at PA: performed by the ground station (groundStation, command and control only) (allocate acknowledgeDetectionReport to groundStation). */
        }
        action def DetectAndClassifyObject {
            doc /* Realises LA::DetectAndClassifyObject at PA: performed on board every drone of the fleet (allocate detectAndClassifyObject to fleet). */
        }
        action def DeliverDetectionReport {
            doc /* Realises LA::DeliverDetectionReport at PA: performed on board every drone of the fleet (allocate deliverDetectionReport to fleet). */
        }
        action def ApplySupervisoryDirectives {
            doc /* Realises LA::ApplySupervisoryDirectives at PA: performed on board every drone of the fleet (allocate applySupervisoryDirectives to fleet). */
        }
        action def ReportMemberStatus {
            doc /* Realises LA::ReportMemberStatus at PA: performed on board every drone of the fleet (allocate reportMemberStatus to fleet). */
        }
        action def ReportTrackPicture {
            doc /* Realises LA::ReportTrackPicture at PA: performed on board every drone of the fleet (allocate reportTrackPicture to fleet). */
        }
        action def ReturnToRecoveryPoint {
            doc /* Realises LA::ReturnToRecoveryPoint at PA: performed on board every drone of the fleet (allocate returnToRecoveryPoint to fleet). */
        }
        action def TriageAlerts {
            doc /* Realises LA::TriageAlerts at PA: performed by the ground alert-triage node, before the operator (allocate triageAlerts to groundAlertTriage). */
        }
        action def KeepDecisionRecords {
            doc /* Realises LA::KeepDecisionRecords at PA: performed by the ground decision-record store (allocate keepDecisionRecords to groundDecisionRecordStore). */
        }
        #Coordination action handOverSector : HandOverSector;
        trace handOverSector to SurveillanceDroneSwarm::LA::handOverSector;
        #Coordination action rotateRecharge : RotateRecharge;
        trace rotateRecharge to SurveillanceDroneSwarm::LA::rotateRecharge;
        #Coordination action redistributeCoverage : RedistributeCoverage;
        trace redistributeCoverage to SurveillanceDroneSwarm::LA::redistributeCoverage;
        #Coordination action deconflictFlight : DeconflictFlight;
        trace deconflictFlight to SurveillanceDroneSwarm::LA::deconflictFlight;
        #Coordination action relayReportsThroughNeighbour : RelayReportsThroughNeighbour;
        trace relayReportsThroughNeighbour to SurveillanceDroneSwarm::LA::relayReportsThroughNeighbour;
        #Coordination action correlateTracks : CorrelateTracks;
        trace correlateTracks to SurveillanceDroneSwarm::LA::correlateTracks;
        #Coordination action handOverTrack : HandOverTrack;
        trace handOverTrack to SurveillanceDroneSwarm::LA::handOverTrack;
        #Coordination action admitMember : AdmitMember;
        trace admitMember to SurveillanceDroneSwarm::LA::admitMember;
        #C2 action taskSurveillanceArea : TaskSurveillanceArea;
        trace taskSurveillanceArea to SurveillanceDroneSwarm::LA::taskSurveillanceArea;
        #C2 action commandSupervisoryPriorities : CommandSupervisoryPriorities;
        trace commandSupervisoryPriorities to SurveillanceDroneSwarm::LA::commandSupervisoryPriorities;
        #C2 action recallAndLand : RecallAndLand;
        trace recallAndLand to SurveillanceDroneSwarm::LA::recallAndLand;
        #C2 action presentStatusPicture : PresentStatusPicture;
        trace presentStatusPicture to SurveillanceDroneSwarm::LA::presentStatusPicture;
        #C2 action acknowledgeDetectionReport : AcknowledgeDetectionReport;
        trace acknowledgeDetectionReport to SurveillanceDroneSwarm::LA::acknowledgeDetectionReport;
        action detectAndClassifyObject : DetectAndClassifyObject;
        trace detectAndClassifyObject to SurveillanceDroneSwarm::LA::detectAndClassifyObject;
        action deliverDetectionReport : DeliverDetectionReport;
        trace deliverDetectionReport to SurveillanceDroneSwarm::LA::deliverDetectionReport;
        action applySupervisoryDirectives : ApplySupervisoryDirectives;
        trace applySupervisoryDirectives to SurveillanceDroneSwarm::LA::applySupervisoryDirectives;
        action reportMemberStatus : ReportMemberStatus;
        trace reportMemberStatus to SurveillanceDroneSwarm::LA::reportMemberStatus;
        action reportTrackPicture : ReportTrackPicture;
        trace reportTrackPicture to SurveillanceDroneSwarm::LA::reportTrackPicture;
        action returnToRecoveryPoint : ReturnToRecoveryPoint;
        trace returnToRecoveryPoint to SurveillanceDroneSwarm::LA::returnToRecoveryPoint;
        action triageAlerts : TriageAlerts;
        trace triageAlerts to SurveillanceDroneSwarm::LA::triageAlerts;
        action keepDecisionRecords : KeepDecisionRecords;
        trace keepDecisionRecords to SurveillanceDroneSwarm::LA::keepDecisionRecords;

        // ── architecture, alternative 2 ──
        // ===== media (typed physical links) =====
        connection def MeshRadioMedium {
            doc /* The radio medium between two drones: a mesh radio that does not depend on the ground link and that interference can degrade. It carries hand-over, rotation, deconfliction, relay, track and admission traffic. */
        }
        connection def GroundLinkMedium {
            doc /* The intermittently available radio link between the drones and the ground station (tasking, priorities, reports, status, acknowledgements). It may be down for minutes; members hold reports meanwhile. */
        }
        connection def RecallRadioMedium {
            doc /* A dedicated recall broadcast radio from the ground recall transmitter straight to every drone. It is separate from the mesh and from the ground link, so an order to land does not depend on the ground station or on the coordination path. */
        }
        connection def GroundLanMedium {
            doc /* Wired local network between the ground components at the ground site (station, triage, record store, recall transmitter). */
        }
        // ===== behaviour parts (hosted by nesting inside node parts) =====
        part def PerceptionSoftware {
            doc /* Behaviour on the member: detects moving objects in the member's sector and classifies them, says Unknown below the reporting threshold, and marks frames from a degraded sensor. Realises detectAndClassifyObject. */
        }
        part def SwarmCoordinationSoftware {
            doc /* Behaviour on the member: the eight coordination functions - sector hand-over, recharge rotation, coverage redistribution, deconfliction, report relay, track correlation, track hand-over and member admission with the classifier-version check - run over the mesh with no coordinator. Coordination traffic has its own priority class on the radio. */
        }
        part def ReportHoldSoftware {
            doc /* Behaviour on the member: keeps each report in the non-volatile store until it is acknowledged, delivers reports over the ground link or a neighbour, and reports status and the track picture (a track is stale after 120 s). Realises deliverDetectionReport, reportMemberStatus, reportTrackPicture. */
        }
        part def DirectiveUptakeSoftware {
            doc /* Behaviour on the member: takes up tasking, priorities and the reporting threshold given by the duty controller. Realises applySupervisoryDirectives together with the safety monitor's recall handling. */
        }
        part def NavigationSoftware {
            doc /* Behaviour on the member: fuses satellite positioning, inertial data and camera matching against stored maps, so position stays bounded when satellite positioning is out. */
        }
        part def FlightRuleMonitor {
            doc /* Behaviour on the member, separate from perception and coordination: enforces recall, clearance and geofence and the return to the recovery point; it holds the member's state machine and lands the drone when contact or clearance is lost. Realises returnToRecoveryPoint and the landing on recall. */
        }
        part def CommandAndControlSoftware {
            doc /* Behaviour on the ground station: tasking, supervisory priorities, the swarm status picture and forwarding of the operations centre's acknowledgements. It does not coordinate the swarm. */
        }
        part def RecallIssuerSoftware {
            doc /* Behaviour on the recall transmitter: repeats a recall order to the whole swarm or one drone until each member has reported landing or recall accepted. */
        }
        part def AlertRankingSoftware {
            doc /* Behaviour on the triage node: ranks reports by confidence, class and sector priority, merges duplicates from several drones and releases at most the hourly alert cap to the operator; held alerts stay in a ranked backlog whose size is shown. */
        }
        part def DecisionRecordSoftware {
            doc /* Behaviour on the record store: keeps for each report its frames, classifier version, reporting threshold in force and who acknowledged it. */
        }
        // ===== node parts on the drone =====
        #Node part def MeshRadioNode {
            doc /* The mesh radio of one drone; the physical carrier of the peer link. */
            out port rfOut : Common::MeshPort;
            in port rfIn : ~Common::MeshPort;
        }
        #Node part def GroundLinkRadioNode {
            doc /* The drone's radio to the ground station; carries reports, status, tracks, tasking, priorities and receipts when the link is up. */
        }
        #Node part def MissionComputerNode {
            doc /* The drone's mission computer with the classification accelerator and the non-volatile report store; hosts perception, swarm coordination, report hold and directive uptake. */
            part perception : PerceptionSoftware;
            part swarmCoordination : SwarmCoordinationSoftware;
            part reportHold : ReportHoldSoftware;
            part directiveUptake : DirectiveUptakeSoftware;
        }
        #Node part def NavigationNode {
            doc /* The drone's navigation unit: satellite receiver, inertial unit and the camera path used for map matching. */
            part navigator : NavigationSoftware;
        }
        #Node part def SafetyMonitorNode {
            doc /* An independent microcontroller with its own supply and watchdog and the dedicated recall receiver; kept apart from the mission computer so a fault in detecting and classifying cannot disable recall, geofence or the return to the recovery point. */
            part ruleMonitor : FlightRuleMonitor;
        }
        // ===== the population member =====
        #Member part def SwarmMember {
            doc /* One of the twelve identical drones. It performs all eight coordination functions itself over the mesh, so the watch does not depend on the ground station or the ground link. It is built from a mesh radio, a ground-link radio, a mission computer, a navigation unit and an independent safety monitor. */
            out port meshOut : Common::MeshPort;
            in port meshIn : ~Common::MeshPort;
            out port reportsOut : Common::DetectionReport;
            out port trackPictureOut : Common::Track;
            out port statusOut : Common::MemberStatus;
            in port taskingIn : Common::TaskingOrder;
            in port priorityIn : Common::PriorityDirective;
            in port recallIn : Common::RecallDirective;
            in port receiptIn : Common::ReportReceipt;

            #Node part meshRadio : MeshRadioNode;
            #Node part groundRadio : GroundLinkRadioNode;
            #Node part missionComputer : MissionComputerNode;
            #Node part navigation : NavigationNode;
            #Node part safetyMonitor : SafetyMonitorNode;

            #Mode state def SwarmMemberModes {
                doc /* Operating condition of one member: nominal, without satellite positioning, sensors not trustworthy, cut off from the other members, or failed admission and readmitted. Carries the rule QuarantinedStaysOut. */
                @SysproseVerification::PropertyPattern {
                    doc /* QuarantinedStaysOut: Once a drone is quarantined, it takes no part in coordination until it has been readmitted. */
                    attribute pattern = "absence";
                    attribute scope = "between";
                    attribute q = "state Quarantined";
                    attribute r = "state Readmitted";
                    attribute p = "state Nominal";
                }
                initial start;
                state Nominal { doc /* Positioning, trusted sensors, contact with the mesh and admission: takes part in coordination. */ }
                state NavigationDegraded { doc /* No satellite positioning; navigates by what its camera sees against stored maps. */ }
                state SensingDegraded { doc /* Sensors cannot be trusted as they are; what it reports from them is marked accordingly. */ }
                state Isolated { doc /* Cut off from the other drones and coordinating with none of them. */ }
                state Quarantined { doc /* Failed admission (identity or classifier version); takes no part in coordination until readmitted. */ }
                state Readmitted { doc /* Passed the readmission check and about to take part in coordination again. */ }
                transition start -> Nominal;
                transition Nominal -> NavigationDegraded;
                transition NavigationDegraded -> Nominal;
                transition Nominal -> SensingDegraded;
                transition SensingDegraded -> Nominal;
                transition Nominal -> Isolated;
                transition NavigationDegraded -> Isolated;
                transition SensingDegraded -> Isolated;
                transition admissionFails first Nominal accept peerVerdict : Common::MemberStatus do action quarantineSelf then Quarantined;
                transition readmissionPasses first Quarantined accept readmitVerdict : Common::MemberStatus do action resumeCoordination then Readmitted;
                transition Isolated -> Readmitted;
                transition Isolated -> Quarantined;
                transition Readmitted -> Nominal;
            }

            #State state def SwarmMemberStates {
                doc /* Where one member is in its sortie: on the ground, flying out, watching, flying back, recalled, outside its cleared airspace, or returning to the recovery point on its own. Executed by the independent safety monitor. Carries the rules RecallWins, GeofenceBreachEndsWatch and ReturnsWhenIsolated. */
                @SysproseVerification::PropertyPattern {
                    doc /* RecallWins: Once a drone is recalled, it does not watch again until it has landed. */
                    attribute pattern = "absence";
                    attribute scope = "between";
                    attribute q = "state Recalled";
                    attribute r = "state Landed";
                    attribute p = "state Watching";
                }
                @SysproseVerification::PropertyPattern {
                    doc /* GeofenceBreachEndsWatch: Once a drone is outside its cleared airspace, it does not watch until it has landed. */
                    attribute pattern = "absence";
                    attribute scope = "between";
                    attribute q = "state OutsideClearance";
                    attribute r = "state Landed";
                    attribute p = "state Watching";
                }
                @SysproseVerification::PropertyPattern {
                    doc /* ReturnsWhenIsolated: From any situation a drone can be in, it can always get back to landed; an isolated drone included. */
                    attribute pattern = "recovery";
                    attribute scope = "globally";
                    attribute p = "state Landed";
                }
                initial start;
                state Landed { doc /* On the ground, battery being swapped or waiting for tasking. */ }
                state Transiting { doc /* Flying from the recharge point to its sector, or to a sector just taken over. */ }
                state Watching { doc /* Holding watch over its sector. */ }
                state Returning { doc /* Flying back to the recharge point once relieved, or to land when the wind is above moderate. */ }
                state Recalled { doc /* Recalled by order and on its way down; does not watch until landed. */ }
                state Recovering { doc /* Cut off and returning to the recovery point on its own. */ }
                state OutsideClearance { doc /* Outside the cleared airspace or clearance withdrawn: on its way down, does not watch until landed. */ }
                transition start -> Landed;
                transition Landed -> Transiting;
                transition Transiting -> Watching;
                transition Watching -> Returning;
                transition Returning -> Landed;
                transition recallWhileWatching first Watching accept recallW : Common::RecallDirective do action descendOnRecallW then Recalled;
                transition recallWhileTransiting first Transiting accept recallT : Common::RecallDirective do action descendOnRecallT then Recalled;
                transition recallWhileReturning first Returning accept recallR : Common::RecallDirective do action descendOnRecallR then Recalled;
                transition Recalled -> Landed;
                transition clearanceLostWhileWatching first Watching accept clearanceW : Common::TaskingOrder do action descendOnClearanceW then OutsideClearance;
                transition clearanceLostWhileTransiting first Transiting accept clearanceT : Common::TaskingOrder do action descendOnClearanceT then OutsideClearance;
                transition OutsideClearance -> Landed;
                transition Watching -> Recovering;
                transition Transiting -> Recovering;
                transition Recovering -> Landed;
            }
        }
        // ===== node parts on the ground =====
        #Node part def GroundStationNode {
            doc /* The ground station, thin by design: command and control only (tasking, supervisory priorities, status picture, acknowledgements). It does not coordinate the swarm; if it or its link is lost the members keep the watch. Hosts the base radio of the ground link. */
            in port statusIn : Common::MemberStatus;
            in port trackPictureIn : Common::Track;
            in port alertsIn : Common::TriagedAlerts;
            in port recordsIn : Common::DecisionRecords;
            out port taskingOut : Common::TaskingOrder;
            out port priorityOut : Common::PriorityDirective;
            out port recallOut : Common::RecallDirective;
            out port receiptOut : Common::ReportReceipt;
            out port recordReceiptOut : Common::ReportReceipt;
            part commandSoftware : CommandAndControlSoftware;

            #Mode state def GroundStationModes {
                doc /* Whether the ground station can reach the swarm and the operations centre: with the link down it can neither task nor recall through it and the members carry on alone. */
                initial start;
                state LinkUp { doc /* The link is available: tasking, command, reports, status and acknowledgements pass. */ }
                state LinkDown { doc /* The link is unavailable: the station holds what it has; the swarm coordinates and holds reports on its own. */ }
                transition start -> LinkUp;
                transition LinkUp -> LinkDown;
                transition LinkDown -> LinkUp;
            }
            #State state def GroundStationStates {
                doc /* What the ground station is doing for the operator: waiting for tasking, supervising, or issuing a recall. */
                initial start;
                state Standby { doc /* No mission window tasked; nothing supervised. */ }
                state Supervising { doc /* Tasking and priorities out, status picture shown, reports acknowledged. */ }
                state Recalling { doc /* A recall order is being issued to the whole swarm or one drone. */ }
                transition start -> Standby;
                transition Standby -> Supervising;
                transition Supervising -> Recalling;
                transition Recalling -> Supervising;
                transition Supervising -> Standby;
                transition Recalling -> Standby;
            }
        }
        #Node part def GroundRecallTransmitterNode {
            doc /* A ground recall transmitter with its own radio and its own operator panel, so an order to land reaches the drones directly and does not depend on the ground station or the ground link. It also takes the order from the station when that is up. */
            in port recallIn : Common::RecallDirective;
            out port recallOut : Common::RecallDirective;
            part recallIssuer : RecallIssuerSoftware;
        }
        #Node part def GroundAlertTriageNode {
            doc /* A server that ranks the reports of all drones, merges duplicates and releases alerts to the operator inside the hourly cap. Kept apart from the record store so that losing the ranker does not lose the provenance record. */
            in port reportsIn : Common::DetectionReport;
            out port alertsOut : Common::TriagedAlerts;
            part alertRanker : AlertRankingSoftware;
        }
        #Node part def GroundDecisionRecordStoreNode {
            doc /* A server with durable storage for the decision records. It receives every report itself and the acknowledgements, independently of triage. */
            in port reportsIn : Common::DetectionReport;
            in port receiptIn : Common::ReportReceipt;
            out port recordsOut : Common::DecisionRecords;
            part recordKeeper : DecisionRecordSoftware;
        }
        part mainAssembly : SurveillanceDroneSwarmPhysical;
        part fleet : SwarmMember [12] {
            doc /* The twelve identical drones. Every function a member performs, and all eight coordination functions, sit here. */
        }
        part memberA : SwarmMember {
            doc /* First representative member, one end of the peer link. */
        }
        part memberB : SwarmMember {
            doc /* Second representative member, the other end of the peer link. */
        }
        #Node part groundStation : GroundStationNode {
            doc /* The ground station: command and control only. */
        }
        #Node part groundRecallTransmitter : GroundRecallTransmitterNode {
            doc /* The direct recall path from the ground to the fleet. */
        }
        #Node part groundAlertTriage : GroundAlertTriageNode {
            doc /* Alert ranking and merging before the operator. */
        }
        #Node part groundDecisionRecordStore : GroundDecisionRecordStoreNode {
            doc /* Durable decision records of every report. */
        }
        // ===== peer link: exchange and physical carrier, both directions =====
        interface peerLink : Common::MeshInterface connect memberA.meshOut to memberB.meshIn {
            doc /* Coordination traffic from representative A to representative B over the mesh. */
        }
        interface peerLinkReturn : Common::MeshInterface connect memberB.meshOut to memberA.meshIn {
            doc /* The return direction: B answers A, so a hand-over can be confirmed and an admission answered. */
        }
        connection meshRadioLinkAB : MeshRadioMedium connect memberA.meshRadio.rfOut to memberB.meshRadio.rfIn {
            doc /* The radio path that carries the peer link from A to B; a jammed link is this connection degraded. */
        }
        connection meshRadioLinkBA : MeshRadioMedium connect memberB.meshRadio.rfOut to memberA.meshRadio.rfIn {
            doc /* The radio path that carries the return direction from B to A. */
        }
        // ===== ground links =====
        connection reportsFeed : GroundLinkMedium connect fleet.reportsOut to groundAlertTriage.reportsIn {
            doc /* Detection reports from the drones to the triage server. */
        }
        connection reportsRecordFeed : GroundLinkMedium connect fleet.reportsOut to groundDecisionRecordStore.reportsIn {
            doc /* The same reports also go straight to the record store, so the record survives the loss of the triage server. */
        }
        connection trackPictureFeed : GroundLinkMedium connect fleet.trackPictureOut to groundStation.trackPictureIn {
            doc /* Tracks held by the drones to the ground station. */
        }
        connection statusFeed : GroundLinkMedium connect fleet.statusOut to groundStation.statusIn {
            doc /* Member status, degradations included, for the status picture. */
        }
        connection taskingFeed : GroundLinkMedium connect groundStation.taskingOut to fleet.taskingIn {
            doc /* Tasking from the station to the drones. */
        }
        connection priorityFeed : GroundLinkMedium connect groundStation.priorityOut to fleet.priorityIn {
            doc /* Supervisory priorities and reporting threshold to the drones. */
        }
        connection receiptFeed : GroundLinkMedium connect groundStation.receiptOut to fleet.receiptIn {
            doc /* Acknowledgements back to the drones so they can clear held reports. */
        }
        connection recallRequestFeed : GroundLanMedium connect groundStation.recallOut to groundRecallTransmitter.recallIn {
            doc /* A recall order from the station to the recall transmitter. */
        }
        connection recallBroadcastFeed : RecallRadioMedium connect groundRecallTransmitter.recallOut to fleet.recallIn {
            doc /* The direct recall broadcast from the transmitter to the drones. */
        }
        connection recordReceiptFeed : GroundLanMedium connect groundStation.recordReceiptOut to groundDecisionRecordStore.receiptIn {
            doc /* Who acknowledged each report, to the record store. */
        }
        connection alertsFeed : GroundLanMedium connect groundAlertTriage.alertsOut to groundStation.alertsIn {
            doc /* Ranked alerts from triage to the station for the operator. */
        }
        connection recordsFeed : GroundLanMedium connect groundDecisionRecordStore.recordsOut to groundStation.recordsIn {
            doc /* Decision records from the store to the station. */
        }
        // ===== fleet-level condition =====
        #Configuration state def FleetConfiguration {
            doc /* Condition of the mesh between drones, taken over the whole twelve-drone fleet. */
            initial start;
            state MeshIntact { doc /* The links between drones are all usable. */ }
            state MeshDegraded { doc /* A share of the links between drones is jammed and the swarm coordinates over what is left. */ }
            transition start -> MeshIntact;
            transition MeshIntact -> MeshDegraded;
            transition MeshDegraded -> MeshIntact;
        }
        // ===== allocation: one per function =====
        allocate handOverSector to fleet;
        allocate rotateRecharge to fleet;
        allocate redistributeCoverage to fleet;
        allocate deconflictFlight to fleet;
        allocate relayReportsThroughNeighbour to fleet;
        allocate correlateTracks to fleet;
        allocate handOverTrack to fleet;
        allocate admitMember to fleet;
        allocate taskSurveillanceArea to groundStation;
        allocate commandSupervisoryPriorities to groundStation;
        allocate recallAndLand to groundRecallTransmitter;
        allocate presentStatusPicture to groundStation;
        allocate acknowledgeDetectionReport to groundStation;
        allocate detectAndClassifyObject to fleet;
        allocate deliverDetectionReport to fleet;
        allocate applySupervisoryDirectives to fleet;
        allocate reportMemberStatus to fleet;
        allocate reportTrackPicture to fleet;
        allocate returnToRecoveryPoint to fleet;
        allocate triageAlerts to groundAlertTriage;
        allocate keepDecisionRecords to groundDecisionRecordStore;
        trace fleet to SurveillanceDroneSwarm::LA::fleet;
        trace memberA to SurveillanceDroneSwarm::LA::memberA;
        trace memberB to SurveillanceDroneSwarm::LA::memberB;
        trace peerLink to SurveillanceDroneSwarm::LA::peerLink;
        trace groundStation to SurveillanceDroneSwarm::LA::groundStation;
        trace groundRecallTransmitter to SurveillanceDroneSwarm::LA::groundStation;
        trace groundAlertTriage to SurveillanceDroneSwarm::LA::triageUnit;
        trace groundDecisionRecordStore to SurveillanceDroneSwarm::LA::triageUnit;
        // ===== budgets the brief fixes, restated as valued attributes and held by require constraints =====
        attribute fleetMemberCount = 12 { doc /* Twelve drones, fixed by the brief. */ }
        attribute memberFlightMinutes = 40 { doc /* One sortie, about 40 minutes, transit included. Unit: minutes. */ }
        attribute memberTurnaroundMinutes = 20 { doc /* Battery swap on the ground, about 20 minutes. Unit: minutes. */ }
        attribute memberCruiseMetresPerSecond = 18 { doc /* Cruise speed between recharge point and sector. Unit: metres per second. */ }
        attribute sectorReachMetres = 4000 { doc /* Worst-case distance from the recharge point to a sector, one way. Unit: metres. Carried from the logical basis. */ }
        attribute memberTransitMinutes = 7.41 { doc /* Round trip out and back at cruise speed, 2 x 4000 m / 18 m/s = 7.41 min, spent from the same 40 minutes. Unit: minutes. */ }
        attribute memberFootprintSquareKilometres = 3.0 { doc /* Area under watch at once from one drone. Unit: square kilometres. */ }
        attribute areaOfInterestSquareKilometres = 25 { doc /* The tasked area, up to 25 square kilometres. */ }
        attribute memberCoverageFraction = 0.12 { doc /* Share of the tasked area one watching drone covers: 3.0 / 25. It is more than 1/12 because only the airborne drones watch; the area estimate follows from it, worked in the estimate's doc. */ }
        assert constraint { areaUnderWatchFraction == fleetMemberCount * ((memberFlightMinutes - memberTransitMinutes) / (memberFlightMinutes + memberTurnaroundMinutes)) * memberCoverageFraction }
        assert constraint { coverageLossAfterMemberLossFraction == memberCoverageFraction / areaUnderWatchFraction }
        attribute jammedLinkFraction = 0.5 { doc /* Share of the links between drones jammed in the brief's jamming test condition, restated here because a constraint body cannot reach Common. */ }
        attribute sectorGapShareOfLostHandOver { doc /* Share of a sector's watch lost when its hand-over is lost, derived by the assert constraint below (CV-17): 10 / 32.59 = 0.307. The leaving member stays until the neighbour confirms, so a lost hand-over leaves the sector empty for about half a swap turnaround, 20 / 2 = 10 min, out of the watch a member keeps between hand-overs, its flight less the round trip, 40 - 7.41 = 32.59 min. The same as LA: the physical architecture changes none of these times. */ }
        assert constraint { doc /* A lost hand-over empties the sector for half a swap turnaround, out of the watch between hand-overs. */ sectorGapShareOfLostHandOver == (memberTurnaroundMinutes / 2) / (memberFlightMinutes - memberTransitMinutes) }
        assert constraint { doc /* Correlated worst case: a jammer covering a neighbourhood jams every confirmation path, so the share of hand-overs lost is the share of links jammed. */ coverageUnderMeshJammingFraction == areaUnderWatchFraction * (1 - jammedLinkFraction * sectorGapShareOfLostHandOver) }
        attribute operatorSecondsPerAlert = 30 { doc /* The least time the operator needs per alert. Unit: seconds. */ }
        attribute alertCapPerHour = 20 { doc /* Alerts the triage node releases to the operator per hour; alerts above it wait in the ranked backlog. Unit: 1/h. */ }
        attribute trackStaleAfterSeconds = 120 { doc /* A track is marked stale once nothing has seen the object for this long. Unit: seconds. */ }
        attribute reportStoreCapacityReports = 2000 { doc /* Reports the on-board non-volatile store can hold. Sizing assumption, a placeholder until the customer states the report rate. */ }
        attribute peakReportsPerMemberPerMinute = 6 { doc /* Peak report rate of one drone. Sizing assumption, a placeholder. Unit: 1/min. */ }
        attribute acceleratorModuleCostUsd = 230 { doc /* Classification accelerator module per drone. Unit: USD. */ }
        attribute modelMemoryCostUsd = 60 { doc /* Memory for the classifier model and frame buffer per drone. Unit: USD. */ }
        attribute reportStoreFlashCostUsd = 30 { doc /* Non-volatile report store per drone. Unit: USD. */ }
        attribute identityElementCostUsd = 30 { doc /* Secure identity element used for admission per drone. Unit: USD. */ }
        require constraint { doc /* The fleet is not larger than the twelve the brief fixes. */ fleetMemberCount <= 12 }
        require constraint { doc /* A sortie lasts at least the 40 minutes the brief fixes. */ memberFlightMinutes >= 40 }
        require constraint { doc /* The swap turnaround is no longer than 20 minutes. */ memberTurnaroundMinutes <= 20 }
        require constraint { doc /* Cruise speed is at least 18 m/s. */ memberCruiseMetresPerSecond >= 18 }
        require constraint { doc /* One drone keeps at least 3.0 square kilometres under watch. */ memberFootprintSquareKilometres >= 3 }
        require constraint { doc /* The area to cover is no more than 25 square kilometres. */ areaOfInterestSquareKilometres <= 25 }
        require constraint { doc /* The per-member coverage fraction is the footprint over the area. */ memberCoverageFraction * areaOfInterestSquareKilometres == memberFootprintSquareKilometres }
        require constraint { doc /* The transit time covers the round trip to the farthest sector at cruise speed. */ memberTransitMinutes * memberCruiseMetresPerSecond * 60 >= 2 * sectorReachMetres }
        require constraint { doc /* Transit fits inside the endurance, so a drone reaches its sector and returns on one battery. */ memberTransitMinutes < memberFlightMinutes }
        require constraint { doc /* The alerts released per hour fit in the operator's hour at the time each needs. */ alertCapPerHour * operatorSecondsPerAlert <= 3600 }
        require constraint { doc /* The operator has at least 30 seconds per alert. */ operatorSecondsPerAlert >= 30 }
        require constraint { doc /* A track goes stale within 120 seconds. */ trackStaleAfterSeconds <= 120 }
        require constraint { doc /* The on-board store holds the reports of one whole sortie at the peak rate. */ reportStoreCapacityReports >= memberFlightMinutes * peakReportsPerMemberPerMinute }
        // ===== worst-case estimates, directly in this package =====
        #Estimate attribute areaUnderWatchFraction :> Common::areaUnderWatchFraction {
            doc /* Worst case, derived from this layer's own values by the assert constraint below (CV-17): 12 x (40 - 7.41) / 60 x 0.12 = 0.782. Twelve drones, a 40 min sortie and a 20 min swap keep each drone airborne 40 of every 60 minutes; the round trip to a sector up to 4 km away at 18 m/s takes 7.41 of those 40; one watching drone covers 0.12 of the area (3.0 of 25 km2). The same arithmetic LA states, over PA's own attributes: the physical architecture changes none of the numbers it rests on. Target 0.9 is not met; it would need the round trip under 2.5 min. */
        }
        #Estimate attribute coverageLossAfterMemberLossFraction :> Common::coverageLossAfterMemberLossFraction {
            doc /* Worst case, derived by the assert constraint below (CV-17): one watching drone holds 0.12 of the area out of the 0.782 under watch, 0.12 / 0.782 = 0.153 of the coverage lost before any re-spread. It is the same wherever redistribution runs, because the loss precedes it; the member-centred redistribution then re-spreads from the last agreed assignment without waiting for the ground. */
        }
        #Estimate attribute coverageUnderMeshJammingFraction :> Common::coverageUnderMeshJammingFraction {
            doc /* Worst case, derived from this layer's own values by the assert constraint above (CV-17): 0.782 x (1 - 0.5 x 0.307) = 0.662. The baseline under watch less the gaps of lost hand-overs: a jammer covering a neighbourhood jams every confirmation path there together, so in the worst case the share of hand-overs lost equals the share of links jammed, the brief's 0.5; each lost hand-over leaves its sector empty for about half a swap turnaround, 10 min out of the 32.59 min a member watches between hand-overs, 0.307, derived from the same time model as the 0.782. The same arithmetic LA states: the physical architecture adds no modelled confirmation path and changes none of the inputs, so the value equals LA's. Placeholder target 0.75 is not met. */
        }
        #Estimate attribute reportAgeAtOperationsCentreSeconds :> Common::reportAgeAtOperationsCentreSeconds = 40 {
            doc /* Worst case 40 s with the link up. About 5 s to classify, up to three relay hops of about 2 s each through neighbours, about 5 s on the ground link, about 20 s queuing at the triage server, and about 4 s to write the record. Relay hop count is the driver. Units are seconds. */
        }
        #Estimate attribute positionErrorWithoutSatelliteMetres :> Common::positionErrorWithoutSatelliteMetres = 80 {
            doc /* Worst case 80 m after ten minutes without satellite positioning. About 10.8 km flown in ten minutes at 18 m/s; the inertial unit bridges between camera matches against stored maps, but over featureless ground the bound is loose and the inertial drift alone is not better than that. Placeholder target 50 m is not met. Units are metres. */
        }
        #Estimate attribute reportHoldWhileCutOffMinutes :> Common::reportHoldWhileCutOffMinutes = 40 {
            doc /* Worst case 40 minutes: a cut-off drone holds every report in its non-volatile store for at least the whole 40 min sortie (the memberFlightMinutes budget), and the store (2000 reports against 40 x 6 = 240 needed) is not the limit; held reports survive the battery swap on board and are cleared only on acknowledgement. Units are minutes. */
        }
        #Estimate attribute missedDetectionFraction :> Common::missedDetectionFraction = 0.12 {
            doc /* Worst case 0.12. Poor lighting, weather and deliberately misleading paint or shapes reduce what the sensors can tell apart; the classifier runs on the drone at full frame rate. Placeholder target 0.10 is not met. */
        }
        #Estimate attribute falseAlarmsPerHour :> Common::falseAlarmsPerHour = 3 {
            doc /* Worst case 3 per hour reaching the operator, with the reporting threshold held at the level that gives the missed-detection figure above; a higher threshold trades false alarms for misses. Units are 1/h. */
        }
        #Estimate attribute alertsReachingOperatorPerHour :> Common::alertsReachingOperatorPerHour {
            doc /* Worst case, derived: the triage node releases at most the hourly cap of 20 alerts to the operator, best first; the rest wait in a ranked backlog that is shown, not dropped. 20 alerts at 30 s each is 600 s of the operator's hour. Units are 1/h. */
        }
        assert constraint { doc /* Alerts reaching the operator per hour equal the cap the triage node enforces. */ alertsReachingOperatorPerHour == alertCapPerHour }
        #Estimate attribute acknowledgedReportsThatMatterFraction :> Common::acknowledgedReportsThatMatterFraction = 0.75 {
            doc /* Worst case 0.75. Triage ranks by confidence, class and the sector priority the operator gave, which the logical split lacked (0.7 on confidence alone); there is still no feedback from the operator on what mattered. Placeholder target 0.8 is not met. */
        }
        #Estimate attribute onboardClassificationCostUsdPerMember :> Common::onboardClassificationCostUsdPerMember {
            doc /* Worst case, derived: the whole classification runs on the drone. Accelerator module 230 + model and frame memory 60 + non-volatile report store 30 + secure identity element 30 = 350 USD per member. Placeholder target 300 USD is not met. Units are USD. */
        }
        assert constraint { doc /* The per-member cost is the sum of the on-board parts. */ onboardClassificationCostUsdPerMember == acceleratorModuleCostUsd + modelMemoryCostUsd + reportStoreFlashCostUsd + identityElementCostUsd }
        #Estimate attribute unattendedWatchDurationHours :> Common::unattendedWatchDurationHours {
            doc /* Worst case, derived by the assert constraint below (CV-17): batteries are swapped by ground crew, so without people the watch ends when the first 40 min sortie is spent, 40 / 60 = 0.667 h. The same as LA: the physical architecture changes neither number. The brief states no number for this measure, so it has no target: the estimate is reported until the customer's figure comes. Units are hours. */
        }
        assert constraint { doc /* Without ground crew to swap batteries, the watch lasts one sortie; 60 minutes to the hour. */ unattendedWatchDurationHours == memberFlightMinutes / 60 }
        // ===== hazards this physical split adds =====
        package Hazards {
            doc /* Hazards the chosen technology adds at the physical layer: a store that loses data, a monitor that shares a fault, a radio that drops silently, a cap that hides an alert, a record store that fails, a radio that saturates. */
            #Hazard requirement HeldReportStoreCorruptionHazard {
                subject s : MissionComputerNode;
                doc /* About the non-volatile report store in the member's mission computer: a battery swap or a power dip during a write corrupts or erases reports that were never acknowledged, and the drone believes they are still held. */
            }
            #Hazard requirement MonitorCommonCauseHazard {
                subject s : SafetyMonitorNode;
                doc /* About the safety monitor: if it shares supply or clock with the mission computer, one brownout or software crash disables recall, geofence and the return to the recovery point at once. */
            }
            #Hazard requirement RecallRadioSilentHazard {
                subject s : GroundRecallTransmitterNode;
                doc /* About the recall transmitter: its radio fails or is jammed without notice, and the operator believes the order to land was sent and taken. */
            }
            #Hazard requirement AlertCapHidesAlertHazard {
                subject s : GroundAlertTriageNode;
                doc /* About the hourly alert cap in the triage node: an alert that matters is held in the backlog behind lesser ones and reaches the operator late. */
            }
            #Hazard requirement DecisionRecordStoreLossHazard {
                subject s : GroundDecisionRecordStoreNode;
                doc /* About the record store: it fails or fills, and the frames, classifier version, threshold and acknowledgement of reports already acted on are lost. */
            }
            #Hazard requirement MeshRadioSaturationHazard {
                subject s : MeshRadioNode;
                doc /* About the mesh radio: relay, status and admission traffic share the one radio with hand-over messages, so a burst of relayed reports delays a hand-over and a sector goes unwatched. */
            }
        }
        satisfy Hazards::HeldReportStoreCorruptionHazard by fleet;
        satisfy Hazards::MonitorCommonCauseHazard by fleet;
        satisfy Hazards::RecallRadioSilentHazard by groundRecallTransmitter;
        satisfy Hazards::RecallRadioSilentHazard by groundStation;
        satisfy Hazards::AlertCapHidesAlertHazard by groundAlertTriage;
        satisfy Hazards::DecisionRecordStoreLossHazard by groundDecisionRecordStore;
        satisfy Hazards::MeshRadioSaturationHazard by fleet;
        // ===== hazards stated above, satisfied here by the components =====
        satisfy SurveillanceDroneSwarm::SA::Hazards::PositionDriftHazard by fleet;
        satisfy SurveillanceDroneSwarm::SA::Hazards::MeshJammingHazard by fleet;
        satisfy SurveillanceDroneSwarm::SA::Hazards::MisclassificationHazard by fleet;
        satisfy SurveillanceDroneSwarm::SA::Hazards::SensingDegradedUnnoticedHazard by fleet;
        satisfy SurveillanceDroneSwarm::SA::Hazards::SensingDegradedUnnoticedHazard by groundStation;
        satisfy SurveillanceDroneSwarm::SA::Hazards::StaleTrackHazard by fleet;
        satisfy SurveillanceDroneSwarm::SA::Hazards::SpoofedMemberHazard by fleet;
        satisfy SurveillanceDroneSwarm::SA::Hazards::MixedClassifierVersionsHazard by fleet;
        satisfy SurveillanceDroneSwarm::SA::Hazards::OperatorOverloadHazard by groundAlertTriage;
        satisfy SurveillanceDroneSwarm::LA::Hazards::CoordinationConcentrationHazard by fleet;
        satisfy SurveillanceDroneSwarm::LA::Hazards::SectorHandOffLostHazard by fleet;
        satisfy SurveillanceDroneSwarm::LA::Hazards::RelayedReportDroppedHazard by fleet;
        satisfy SurveillanceDroneSwarm::LA::Hazards::TrackHandOverGapHazard by fleet;
        satisfy SurveillanceDroneSwarm::LA::Hazards::SplitCoordinationHazard by fleet;
        satisfy SurveillanceDroneSwarm::LA::Hazards::LostHandoffHazard by fleet;
        satisfy SurveillanceDroneSwarm::LA::Hazards::GroundStationSinglePointHazard by groundRecallTransmitter;
        satisfy SurveillanceDroneSwarm::LA::Hazards::GroundStationSinglePointHazard by fleet;
        satisfy SurveillanceDroneSwarm::LA::Hazards::TriageUnitSinglePointHazard by groundDecisionRecordStore;
        #prose part paTradeOff {
        doc /* Architecture trade-off for PA. Alternative 2 was taken.
                 alternative 1: total 0.53 (measures 0.25, review 0.47, structure 0.93, resilience 0.25)
                 alternative 2: total 0.76 (measures 0.33, review 0.75, structure 0.86, resilience 1.00)
                 The measures term scores the worst case of each alternative's own #Estimate: claims its architecture states with their basis, not measurements.
                 The decision is where the deciding authority sits, and the two alternatives answer it cleanly enough to be compared on consequences rather than style.

        Alternative 1 concentrates hand-over, rotation, redistribution, deconfliction, admission and track correlation in `GroundSwarmCoordinator` and `GroundTrackFusion`, both nested in one `groundCoordinator : GroundCoordinationNode`. Its behaviour decomposition on the member is actually the finer of the two — `DetectorClassifier`, `HeldReportStore`, `NeighbourRelayAgent`, `TrackHandoverAgent`, `MemberHealthReporter`, `DirectiveHandler`, `FlightSafetyMonitor`, `BatteryEnduranceMonitor` are each one job — and separating `groundTriage` from `groundRecordStore`, with `reportsToRecords` taking reports straight off the fleet, is the right call for provenance in both alternatives. The problem is what the boundary then has to carry. Every coordination decision crosses `GroundLinkMedium` twice (`coordinationUplink` up, `assignmentDownlink` down) on a link the model itself types as intermittent, and the ports that carry it (`SwarmMember::coordOut/coordIn`) are typed `Common::MeshPort` — mesh semantics pushed over the ground radio. `GroundCoordinatorModes.FleetUnreachable` states the consequence in the model's own words: the drones act on their last assignment and coverage decays as endurance runs out. Rotation stops, so a drone due to recharge either abandons a sector or overstays; `correlateTracks` stops, so the operator loses the fused picture at `groundStation.trackPictureIn` even though the ground segment is intact. `reportHoldWhileCutOffMinutes` = 40 min is met, but it only says the data survives — the coordination does not.

        The estimate that should be discounted is Alternative 1's `coverageLossAfterMemberLossFraction` = 0.153, with the basis "the loss precedes the ground coordinator's redistribution, so it is the same as for a member-centred split". True for the instant, but the measure exists to separate ground-coordinated from member-coordinated restoration, and the basis measures only the moment before restoration. `Hazards::CoordinatorHostFailureHazard` says redistribution stops entirely when `GroundCoordinationNode` fails, so in that state the 0.153 is never re-spread at all. Worse, it is discharged by `satisfy Hazards::CoordinatorHostFailureHazard by fleet` — and `SwarmMember`'s own doc says the deciding coordination "is done for it by the ground coordinator". The fleet hosts no coordination behaviour part; the mitigation is nominal, and the same applies to `satisfy LA::Hazards::GroundStationSinglePointHazard by fleet`. `satisfy Hazards::AssignmentLatencyHazard by groundCoordinator` has the coordinator mitigating its own round-trip latency, and `groundLinkTransceiver`, whose `LinkGatewayManager` is supposed to manage that link and is the hazard's subject, appears in no connection at all — the fleet ports wire straight to the ground nodes. `handOverLossShareUnderJamming` = 0.15 is flagged by its own author as an assumption whose premise (jamming hits the mesh but not the ground link) the same doc then contradicts; for an architecture that routes all coordination over the ground link, that is the assumption that matters most.

        Alternative 2 keeps the ground boundary thin: `taskingFeed`, `priorityFeed`, `statusFeed`, `reportsFeed`, `receiptFeed` and nothing that decides. Losing `groundStation : GroundStationNode` costs tasking, priorities, status picture and acknowledgements — not the watch, not deconfliction, not redistribution, and not recall, because `recallAndLand` is allocated to a separate `groundRecallTransmitter : GroundRecallTransmitterNode` with its own operator panel on its own `RecallRadioMedium`. Alternative 1's `DirectRecallIssuer` bypasses the coordinator but is a behaviour part inside `groundStation` riding `recallDownlink : GroundLinkMedium`, so it dies with either the station or the link. On the rules: Alternative 2's `SafetyMonitorNode` is an independent microcontroller with its own supply, watchdog and dedicated recall receiver, holds the member state machine, and its transitions are triggered (`recallWhileWatching ... accept recallW : Common::RecallDirective`), so `RecallWins` and `GeofenceBreachEndsWatch` are enforced by a component that neither classifies nor decides. Alternative 1's `FlightSafetyMonitor` is correctly kept off the mission computer, but recall reaches it through `DirectiveHandler`, which is hosted on `MissionComputerNode` alongside `DetectorClassifier` — the rule-enforcement chain runs through the classifier's host — and its state machines carry the same property patterns over untriggered transitions, which makes them harder to hold a supplier to.

        Alternative 2 is not free of criticism. `SwarmCoordinationSoftware` is one part doing all eight coordination functions on the hardest host to update, and `ReportHoldSoftware` bundles delivery, status and track picture. `MeshRadioSaturationHazard` is real and honestly declared: the "dedicated coordination priority class" is a claim in a doc, not a modelled separation. Its `alertsReachingOperatorPerHour` = 20 meets the target by construction — `alertCapPerHour` is the cap — and `AlertCapHidesAlertHazard` admits the risk simply moves into latency; Alternative 1's 21/h rests on a more genuine mechanism (one fused track per object before ranking) that does not pay off enough. Its 350 USD overcounts `onboardClassificationCostUsdPerMember` by including the report-store flash and identity element, which are not classification; Alternative 1's 320 USD is un-itemised, so neither figure is trustworthy and both fail. Alternative 1's real advantage is procurement and change: a coordination server is one item on commodity hardware, testable on the ground, and changing the coordination algorithm touches one box rather than twelve airframes under a classifier-version admission check.

        That advantage does not survive the two resilience questions this comparison exists to answer. I would take Alternative 2. */
        }
    }
