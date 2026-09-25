    package SA {
        #prompt part saGuidance {
            doc /* SA: the system is one black-box part with ports. Every function is allocated to the system or to an actor, and traces to at least one operational activity. No design choices here. */
        }

        // the system, black box
        part def SurveillanceDroneSwarmSystem {
            doc /* The whole surveillance drone swarm seen as one black box: the twelve-drone population, its mesh, its on-board sensing and its tasking, reporting and status functions, with no internal structure. It takes tasking, supervisory command, recall, acknowledgements, airspace clearance, serviced drones and the moving objects in the area, and gives detection reports, triaged alerts, the track picture, the status picture, decision records and arriving drones. */
            in port taskingIn : Common::TaskingOrder;
            in port supervisoryIn : Common::PriorityDirective;
            in port recallIn : Common::RecallDirective;
            in port acknowledgementIn : Common::ReportReceipt;
            in port objectsIn : Common::MovingObjectsInArea;
            in port clearanceIn : Common::AirspaceClearance;
            in port servicedDroneIn : Common::DroneServiced;
            out port reportsOut : Common::DetectionReport;
            out port alertsOut : Common::TriagedAlerts;
            out port trackPictureOut : Common::Track;
            out port statusOut : Common::MemberStatus;
            out port decisionRecordsOut : Common::DecisionRecords;
            out port rechargeArrivalOut : Common::DroneArrival;
            out port recoveryArrivalOut : Common::DroneArrival;
        }
        part system : SurveillanceDroneSwarmSystem {
            doc /* The system under design: the twelve-drone swarm as one black box. */
        }
        trace system to SurveillanceDroneSwarm::OA::watchAsset;

        #prose part environmentConstraints {
            doc /* Constraining inputs carried as constraints on the system, not as ports, because no actor sends them: RadioInterference (degrades the mesh and the ground link), SatellitePositioningOutage (minutes at a time), WeatherLightingAndDeception (sensing degrades; the swarm lands above moderate wind), FixedCameraNetwork tracks that swarm tracks must be mergeable with, OperatorAttentionLimit (a bounded number of alerts per hour), and WatchAndReportOnlyScope (weapons, interception and anything done to what is detected are out of scope). The clearance from the airspace authority does arrive through a port, clearanceIn. */
        }

        // the population: 12 identical members (CV-16)
        #Member part def SwarmMember {
            doc /* One member of the twelve-drone population: a small drone that flies about 40 minutes at about 18 m/s and keeps about 3.0 km2 under watch. At SA the system is still one black box: this definition is carried, not instantiated, and holds the two state machines every member follows. */
            out port meshOut : Common::MeshPort;
            in port meshIn : ~Common::MeshPort;

            #Mode state def SwarmMemberModes {
                doc /* Operating condition of one drone: nominal, without satellite positioning, sensors not trustworthy, cut off from the other drones, or failed admission and readmitted. Carries the rule QuarantinedStaysOut. */
                @SysproseVerification::PropertyPattern {
                    doc /* QuarantinedStaysOut: once a drone is quarantined, it takes no part in coordination until it has been readmitted. */
                    attribute pattern = "absence";
                    attribute scope = "between";
                    attribute q = "state Quarantined";
                    attribute r = "state Readmitted";
                    attribute p = "state Nominal";
                }
                initial start;
                transition start -> Nominal;
                state Nominal {
                    doc /* The drone has positioning, trusted sensors, contact with the swarm and admission, and takes part in coordination. */
                }
                state NavigationDegraded {
                    doc /* The drone has no satellite positioning and navigates by what its camera sees against stored maps. */
                }
                state SensingDegraded {
                    doc /* The drone's sensors cannot be trusted as they are, and what it reports from them is marked accordingly. */
                }
                state Isolated {
                    doc /* The drone is cut off from the other drones and coordinates with none of them. */
                }
                state Quarantined {
                    doc /* The drone has failed admission and takes no part in coordination until it has been readmitted. */
                }
                state Readmitted {
                    doc /* The drone has passed the readmission check and is about to take part in coordination again. */
                }
                transition losePositioning first Nominal accept positioningLost : Common::PositioningStatus do action navigateByCamera then NavigationDegraded;
                transition regainPositioning first NavigationDegraded accept positioningRegained : Common::PositioningStatus do action resumeSatelliteNavigation then Nominal;
                transition degradeSensing first Nominal accept sensorHealthLost : Common::SensorHealthStatus do action markReportsUnreliable then SensingDegraded;
                transition restoreSensing first SensingDegraded accept sensorHealthRestored : Common::SensorHealthStatus do action clearReportMarking then Nominal;
                transition loseContact first Nominal accept meshContactLost : Common::MeshLinkStatus do action coordinateWithNone then Isolated;
                transition regainContact first Isolated accept meshContactRegained : Common::MeshLinkStatus do action resumeCoordination then Nominal;
                transition failAdmission first Nominal accept admissionFailed : Common::AdmissionExchange do action stopCoordinating then Quarantined;
                transition readmit first Quarantined accept readmissionPassed : Common::AdmissionExchange do action rejoinAfterCheck then Readmitted;
                transition Readmitted -> Nominal;
            }

            #State state def SwarmMemberStates {
                doc /* Where one drone is in its sortie: on the ground, flying out, watching, flying back, recalled, outside its cleared airspace, or returning to the recovery point on its own. Carries the rules RecallWins, GeofenceBreachEndsWatch and ReturnsWhenIsolated. */
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
                    doc /* ReturnsWhenIsolated: from any situation a drone can be in, it can always get back to landed; an isolated drone included. */
                    attribute pattern = "recovery";
                    attribute scope = "globally";
                    attribute p = "state Landed";
                }
                initial start;
                transition start -> Landed;
                state Landed {
                    doc /* On the ground, battery being swapped or waiting for tasking. */
                }
                state Transiting {
                    doc /* Flying from the recharge point to its sector. */
                }
                state Watching {
                    doc /* Holding watch over its sector. */
                }
                state Returning {
                    doc /* Flying back to the recharge point to swap the battery, or to land when the wind is above moderate. */
                }
                state Recalled {
                    doc /* Recalled by order and on its way down; it does not watch until landed. */
                }
                state Recovering {
                    doc /* Cut off from the swarm and returning to the recovery point on its own. */
                }
                state OutsideClearance {
                    doc /* Outside the cleared airspace or the clearance withdrawn: on its way down, and it does not watch until landed. */
                }
                transition launch first Landed accept assignment : Common::TaskingOrder do action startSortie then Transiting;
                transition Transiting -> Watching;
                transition endWatch first Watching accept rotationSlot : Common::RechargeRotationSlot do action handSectorAndReturn then Returning;
                transition Returning -> Landed;
                transition recallWhileTransiting first Transiting accept recallDirective : Common::RecallDirective do action abortTransitAndLand then Recalled;
                transition recallWhileWatching first Watching accept recallDirective : Common::RecallDirective do action abortWatchAndLand then Recalled;
                transition Recalled -> Landed;
                transition loseSwarmContact first Watching accept contactLost : Common::MeshLinkStatus do action headForRecoveryPoint then Recovering;
                transition loseContactInTransit first Transiting accept contactLostEnRoute : Common::MeshLinkStatus do action headForRecoveryPointFromTransit then Recovering;
                transition Recovering -> Landed;
                transition leaveClearanceWhileWatching first Watching accept clearanceUpdate : Common::AirspaceClearance do action stopWatchOutsideClearance then OutsideClearance;
                transition leaveClearanceInTransit first Transiting accept clearanceUpdateEnRoute : Common::AirspaceClearance do action stopTransitOutsideClearance then OutsideClearance;
                transition OutsideClearance -> Landed;
                transition windLimit first Watching accept weatherNow : Common::WeatherCondition do action landInWind then Returning;
            }
        }
        #prose part fleetFact {
            doc /* Population: 12 members of SwarmMember, carried by fleet, exchanging through Common::MeshInterface. Carried from the brief; instantiated from LA down. */
        }

        // fleet-level configuration: the condition of the mesh over the whole population
        #Configuration state def FleetConfiguration {
            doc /* Condition of the mesh between drones, taken over the whole twelve-drone population. */
            initial start;
            transition start -> MeshIntact;
            state MeshIntact {
                doc /* The links between drones are all usable. */
            }
            state MeshDegraded {
                doc /* A share of the links between drones is jammed and the swarm coordinates over what is left. */
            }
            transition meshJammed first MeshIntact accept jamming : Common::MeshLinkStatus do action coordinateOverRemainingLinks then MeshDegraded;
            transition meshRestored first MeshDegraded accept linksRestored : Common::MeshLinkStatus do action resumeFullCoordination then MeshIntact;
        }

        // actors: every operational entity the system is not
        #Actor part def DutyController {
            doc /* Operations-centre operator who tasks the swarm, issues supervisory command and recall. Exchanges through three outgoing ports. */
            out port taskingOut : Common::TaskingOrder;
            out port priorityOut : Common::PriorityDirective;
            out port recallOut : Common::RecallDirective;
        }
        part dutyController : DutyController {
            doc /* The one operator who supervises the whole swarm. */
        }
        trace dutyController to SurveillanceDroneSwarm::OA::dutyController;
        #Actor part def OperationsCentreAnalyst {
            doc /* Judges the alerts, acknowledges each detection report and merges swarm tracks with the fixed camera network's tracks. Receives reports, alerts, the swarm track picture, decision records and the camera tracks; returns the acknowledgement. */
            in port reportsIn : Common::DetectionReport;
            in port alertsIn : Common::TriagedAlerts;
            in port trackPictureIn : Common::Track;
            in port recordsIn : Common::DecisionRecords;
            in port cameraTrackIn : Common::Track;
            out port receiptOut : Common::ReportReceipt;
        }
        part operationsCentreAnalyst : OperationsCentreAnalyst {
            doc /* The analyst at the operations centre. */
        }
        trace operationsCentreAnalyst to SurveillanceDroneSwarm::OA::operationsCentreAnalyst;
        #Actor part def AirspaceAuthority {
            doc /* Grants and withdraws the clearance that says when and where anything may fly. Exchanges through one outgoing port. */
            out port clearanceOut : Common::AirspaceClearance;
        }
        part airspaceAuthority : AirspaceAuthority {
            doc /* The authority whose clearance bounds every flight. */
        }
        trace airspaceAuthority to SurveillanceDroneSwarm::OA::airspaceAuthority;
        #Actor part def GroundCrew {
            doc /* Services drones between sorties and recovers drones that return on their own; hands serviced drones back to the swarm. */
            out port servicedDroneOut : Common::DroneServiced;
        }
        part groundCrew : GroundCrew {
            doc /* The crew at the recharge point and the recovery point. */
        }
        trace groundCrew to SurveillanceDroneSwarm::OA::groundCrew;
        #Actor part def FixedCameraNetworkOperator {
            doc /* Keeps the existing fixed camera network and its own tracks in service. It has no exchange with the system at SA; its tracks reach the analyst through the camera network. */
        }
        part fixedCameraNetworkOperator : FixedCameraNetworkOperator {
            doc /* The operator of the fixed camera network. */
        }
        trace fixedCameraNetworkOperator to SurveillanceDroneSwarm::OA::fixedCameraNetworkOperator;
        #Actor part def GroundStationNode {
            doc /* The station that tasks and watches the swarm and shows its status picture. At SA it receives the status picture; whether it also coordinates the swarm is the command-and-control architecture decision taken later. */
            in port statusIn : Common::MemberStatus;
        }
        part groundStation : GroundStationNode {
            doc /* The ground station used today. */
        }
        trace groundStation to SurveillanceDroneSwarm::OA::groundStation;
        #Actor part def MeshRadio {
            doc /* The radio mesh carrying coordination traffic between drones; it does not depend on the link to the operations centre. It is a medium inside the swarm, so it has no port on the system at SA; PA types the member-to-member links by it. */
        }
        part meshRadioBetweenDrones : MeshRadio {
            doc /* The mesh radio that carries the traffic between drones. */
        }
        trace meshRadioBetweenDrones to SurveillanceDroneSwarm::OA::meshRadioBetweenDrones;
        #Actor part def GroundLinkRadio {
            doc /* The intermittently available radio link carrying tasking, command, reports, status and acknowledgements to and from the operations centre. It is the medium under the ports to the operations-centre actors; its intermittency is carried as a constraint and allocated at PA. */
        }
        part groundLinkToOperationsCentre : GroundLinkRadio {
            doc /* The intermittent link to the operations centre. */
        }
        trace groundLinkToOperationsCentre to SurveillanceDroneSwarm::OA::groundLinkToOperationsCentre;
        #Actor part def RechargePoint {
            doc /* Where batteries are swapped, not charged in place; about 20 minutes of turnaround. Receives drones that come down to be serviced. */
            in port arrivalIn : Common::DroneArrival;
        }
        part batterySwapAtRechargePoint : RechargePoint {
            doc /* The recharge point where ground crew swap batteries. */
        }
        trace batterySwapAtRechargePoint to SurveillanceDroneSwarm::OA::batterySwapAtRechargePoint;
        #Actor part def RecoveryPoint {
            doc /* The point a drone that has lost contact with the swarm returns to on its own rather than becoming a hazard. Receives such drones. */
            in port arrivalIn : Common::DroneArrival;
        }
        part recoveryPoint : RecoveryPoint {
            doc /* The recovery point for drones that return on their own. */
        }
        trace recoveryPoint to SurveillanceDroneSwarm::OA::recoveryPoint;
        #Actor part def FixedCameraNetwork {
            doc /* The existing camera network; it stays and keeps its own tracks, which swarm reports must be mergeable with. */
            out port cameraTrackOut : Common::Track;
        }
        part fixedCameraNetwork : FixedCameraNetwork {
            doc /* The existing fixed camera network. */
        }
        trace fixedCameraNetwork to SurveillanceDroneSwarm::OA::fixedCameraNetwork;
        #Actor part def MovingObjectsSource {
            doc /* The moving objects in the tasked area that the swarm must detect, classify and place in time and space. An environment source, not an operational entity of OA, so it carries no trace. */
            out port objectsOut : Common::MovingObjectsInArea;
        }
        part movingObjectsInArea : MovingObjectsSource {
            doc /* Whatever moves through the tasked area. */
        }

        // the system ports wired to the actors
        connection taskingLink connect dutyController.taskingOut to system.taskingIn;
        connection supervisoryLink connect dutyController.priorityOut to system.supervisoryIn;
        connection recallLink connect dutyController.recallOut to system.recallIn;
        connection acknowledgementLink connect operationsCentreAnalyst.receiptOut to system.acknowledgementIn;
        connection objectsLink connect movingObjectsInArea.objectsOut to system.objectsIn;
        connection clearanceLink connect airspaceAuthority.clearanceOut to system.clearanceIn;
        connection servicedDroneLink connect groundCrew.servicedDroneOut to system.servicedDroneIn;
        connection reportsLink connect system.reportsOut to operationsCentreAnalyst.reportsIn;
        connection alertsLink connect system.alertsOut to operationsCentreAnalyst.alertsIn;
        connection trackPictureLink connect system.trackPictureOut to operationsCentreAnalyst.trackPictureIn;
        connection statusLink connect system.statusOut to groundStation.statusIn;
        connection decisionRecordsLink connect system.decisionRecordsOut to operationsCentreAnalyst.recordsIn;
        connection rechargeArrivalLink connect system.rechargeArrivalOut to batterySwapAtRechargePoint.arrivalIn;
        connection recoveryArrivalLink connect system.recoveryArrivalOut to recoveryPoint.arrivalIn;
        connection cameraTracksLink connect fixedCameraNetwork.cameraTrackOut to operationsCentreAnalyst.cameraTrackIn;

        // capabilities, carried over with the system as subject
        #Capability use case def WatchTheTaskedArea {
            doc /* Hold continuous watch over a tasked area of up to 25 km2 and turn what happens there into acknowledged, triaged detection reports at the operations centre. */
            subject s : SurveillanceDroneSwarmSystem;
        }
        trace WatchTheTaskedArea to SurveillanceDroneSwarm::OA::WatchTheTaskedArea;
        #Capability use case def ContinuousSectorWatch {
            doc /* At any moment at least one drone watches each sector, as members leave to recharge and rejoin. */
            subject s : SurveillanceDroneSwarmSystem;
        }
        trace ContinuousSectorWatch to SurveillanceDroneSwarm::OA::ContinuousSectorWatch;
        #Capability use case def MovingObjectDetectionAndClassification {
            doc /* Detect moving objects, classify them well enough to say whether they matter, and say Unknown rather than force a class below the reporting threshold. */
            subject s : SurveillanceDroneSwarmSystem;
        }
        trace MovingObjectDetectionAndClassification to SurveillanceDroneSwarm::OA::MovingObjectDetectionAndClassification;
        #Capability use case def ReportDeliveryAndReconciliation {
            doc /* Deliver each report with position and time, keep detecting and holding reports while cut off, and reconcile with none lost once the link is back. */
            subject s : SurveillanceDroneSwarmSystem;
        }
        trace ReportDeliveryAndReconciliation to SurveillanceDroneSwarm::OA::ReportDeliveryAndReconciliation;
        #Capability use case def SwarmSelfCoordination {
            doc /* Settle sector handover, recharge rotation, coverage redistribution, deconfliction, link relay, track correlation, track handover and member admission between the drones over the mesh. */
            subject s : SurveillanceDroneSwarmSystem;
        }
        trace SwarmSelfCoordination to SurveillanceDroneSwarm::OA::SwarmSelfCoordination;
        #Capability use case def OperatorSupervisionOfTheSwarm {
            doc /* Let one operator task, command, recall and watch the whole swarm rather than fly each drone, and acknowledge each report. */
            subject s : SurveillanceDroneSwarmSystem;
        }
        trace OperatorSupervisionOfTheSwarm to SurveillanceDroneSwarm::OA::OperatorSupervisionOfTheSwarm;
        #Capability use case def AlertTriage {
            doc /* Triage reports before they reach the operator, most likely to matter first and duplicates merged, so the alert rate stays inside what one operator can judge. */
            subject s : SurveillanceDroneSwarmSystem;
        }
        trace AlertTriage to SurveillanceDroneSwarm::OA::AlertTriage;
        #Capability use case def DecisionRecordKeeping {
            doc /* Keep, for every report, the frames it came from, the classifier version, the reporting threshold in force and who acknowledged it. */
            subject s : SurveillanceDroneSwarmSystem;
        }
        trace DecisionRecordKeeping to SurveillanceDroneSwarm::OA::DecisionRecordKeeping;
        #Capability use case def GracefulDegradationUnderLoss {
            doc /* Keep flying and watching when a drone is lost, the mesh is jammed or the ground link or ground station drops, with the loss of coverage bounded. */
            subject s : SurveillanceDroneSwarmSystem;
        }
        trace GracefulDegradationUnderLoss to SurveillanceDroneSwarm::OA::GracefulDegradationUnderLoss;
        #Capability use case def AirspaceComplianceAndSafeRecovery {
            doc /* Stay inside cleared airspace, land when it is not cleared or wind exceeds moderate, and return to a recovery point when contact with the swarm is lost. */
            subject s : SurveillanceDroneSwarmSystem;
        }
        trace AirspaceComplianceAndSafeRecovery to SurveillanceDroneSwarm::OA::AirspaceComplianceAndSafeRecovery;
        #Capability use case def ClassifierVersionConsistency {
            doc /* Keep one classifier version across the fleet and know which version each drone runs, so one object is not classified differently by different drones. */
            subject s : SurveillanceDroneSwarmSystem;
        }
        trace ClassifierVersionConsistency to SurveillanceDroneSwarm::OA::ClassifierVersionConsistency;

        // function definitions
        action def TaskSurveillanceArea {
            doc /* The duty controller tasks the swarm with the area of interest, its sectors and the mission window. */
            out taskingOut;
        }
        action def CommandSupervisoryPriorities {
            doc /* The duty controller gives priorities, a sector to look at more closely and the reporting threshold. */
            out priorityOut;
        }
        action def RecallAndLand {
            doc /* An order to recall and land the whole swarm or one drone, issuable at any time. */
            out recallOut;
        }
        action def PresentStatusPicture {
            doc /* Shows where every drone is, what it is doing, how much of the area is under watch and what is degraded. */
            in statusIn;
        }
        action def AcknowledgeDetectionReport {
            doc /* The operations centre confirms each detection report so nothing is lost in a link gap, judging the triaged alerts it is given. */
            in reportIn;
            in alertsIn;
            out receiptOut;
        }
        action def MergeSwarmTracks {
            doc /* The analyst merges swarm tracks with the camera network's tracks, one track per object. */
            in swarmTrackIn;
            in cameraTrackIn;
        }
        action def ProvideCameraTracks {
            doc /* The fixed camera network provides its own tracks. */
            out cameraTrackOut;
        }
        action def SwapBattery {
            doc /* Ground crew swap a landed drone's battery at the recharge point, about 20 minutes. */
        }
        action def RecoverReturnedDrone {
            doc /* Ground crew recover a drone that returned to the recovery point on its own. */
        }
        action def GrantAirspaceClearance {
            doc /* The airspace authority grants or withdraws the clearance that bounds when and where anything may fly. */
        }
        action def HandOverSector {
            doc /* A drone hands its sector to a neighbour when it leaves to recharge, so the sector stays watched. */
            out handoverOut;
            in handoverIn;
        }
        action def RotateRecharge {
            doc /* Members agree who leaves to recharge and who takes the place, so the rotation never empties a sector. */
            out rotationOut;
            in rotationIn;
        }
        action def RedistributeCoverage {
            doc /* Members re-spread over the area when one is lost or leaves, so the share of area under watch stays high. */
            out coverageOut;
            in coverageIn;
        }
        action def DeconflictFlight {
            doc /* Members announce flight intent to each other so that two drones do not occupy the same airspace. */
            out intentOut;
            in intentIn;
        }
        action def RelayReportsThroughNeighbour {
            doc /* A member that cannot reach the operations centre sends its reports through a neighbour that can. */
            out relayOut;
            in relayIn;
        }
        action def CorrelateTracks {
            doc /* Members agree that tracks seen by different drones are the same object, giving one track per object. */
            out correlationOut;
            in correlationIn;
        }
        action def HandOverTrack {
            doc /* A track is handed to the drone that watches the sector the object moves into. */
            out trackHandoverOut;
            in trackHandoverIn;
        }
        action def AdmitMember {
            doc /* A drone is checked before it takes part in coordination, including the classifier version it runs; one that fails takes no part until readmitted. */
            out admissionOut;
            in admissionIn;
        }
        action def DetectAndClassifyObject {
            doc /* A drone detects a moving object in its sector and classifies it, saying Unknown when confidence is short of the reporting threshold. */
            out detectionOut;
        }
        action def DeliverDetectionReport {
            doc /* A drone delivers a report with position and time to the operations centre, holds it while cut off, and clears it on acknowledgement. */
            in detectionIn;
            out reportOut;
            in receiptIn;
        }
        action def ApplySupervisoryDirectives {
            doc /* A drone takes up the tasking, priorities and recall given by the duty controller, and lands on recall. */
            in taskingIn;
            in priorityIn;
            in recallIn;
        }
        action def ReportMemberStatus {
            doc /* A drone reports its position, activity and degradations, sensing degradation included, for the status picture. */
            out statusOut;
        }
        action def ReportTrackPicture {
            doc /* A drone reports the tracks it holds, marking a track stale once nothing has seen the object, so the analyst can merge them with the camera network's tracks. */
            out trackPictureOut;
        }
        action def ReturnToRecoveryPoint {
            doc /* A drone that has lost contact with the swarm returns to the recovery point on its own. */
        }
        action def TriageAlerts {
            doc /* Ranks the reports so that what is most likely to matter reaches the operator first, with duplicates merged, keeping the alert rate inside what one operator can judge. */
            in reportsIn;
            out alertsOut;
        }
        action def KeepDecisionRecords {
            doc /* Keeps, for every report, the frames it came from, the classifier version, the reporting threshold in force and who acknowledged it. */
            in reportIn;
            in receiptIn;
        }

        // functions: command and control
        #C2 action taskSurveillanceArea : TaskSurveillanceArea {
            doc /* Command and control: the duty controller tasks the swarm with the area, sectors and mission window. */
        }
        allocate taskSurveillanceArea to dutyController;
        trace taskSurveillanceArea to SurveillanceDroneSwarm::OA::issueTasking;
        #C2 action commandSupervisoryPriorities : CommandSupervisoryPriorities {
            doc /* Command and control: the duty controller gives priorities, a sector to look at more closely and the reporting threshold. */
        }
        allocate commandSupervisoryPriorities to dutyController;
        trace commandSupervisoryPriorities to SurveillanceDroneSwarm::OA::issuePriorities;
        #C2 action recallAndLand : RecallAndLand {
            doc /* Command and control: the duty controller recalls and lands the whole swarm or one drone at any time. */
        }
        allocate recallAndLand to dutyController;
        trace recallAndLand to SurveillanceDroneSwarm::OA::issueRecall;
        #C2 action presentStatusPicture : PresentStatusPicture {
            doc /* Command and control: the ground station shows the status picture of the swarm. */
        }
        allocate presentStatusPicture to groundStation;
        trace presentStatusPicture to SurveillanceDroneSwarm::OA::presentStatus;
        #C2 action acknowledgeDetectionReport : AcknowledgeDetectionReport {
            doc /* Command and control: the analyst acknowledges each detection report and judges the triaged alerts. */
        }
        allocate acknowledgeDetectionReport to operationsCentreAnalyst;
        trace acknowledgeDetectionReport to SurveillanceDroneSwarm::OA::acknowledgeReports;

        // functions performed by actors
        action mergeTracks : MergeSwarmTracks {
            doc /* The analyst merges swarm tracks with the fixed camera network's tracks. */
        }
        allocate mergeTracks to operationsCentreAnalyst;
        trace mergeTracks to SurveillanceDroneSwarm::OA::mergeTracks;
        action provideCameraTracks : ProvideCameraTracks {
            doc /* The fixed camera network keeps and provides its own tracks. */
        }
        allocate provideCameraTracks to fixedCameraNetwork;
        trace provideCameraTracks to SurveillanceDroneSwarm::OA::provideCameraTracks;
        action swapBatteryAct : SwapBattery {
            doc /* Ground crew swap a landed drone's battery. */
        }
        allocate swapBatteryAct to groundCrew;
        trace swapBatteryAct to SurveillanceDroneSwarm::OA::swapBatteryAct;
        action recoverDroneAct : RecoverReturnedDrone {
            doc /* Ground crew recover a drone that returned on its own. */
        }
        allocate recoverDroneAct to groundCrew;
        trace recoverDroneAct to SurveillanceDroneSwarm::OA::recoverDroneAct;
        action grantClearanceAct : GrantAirspaceClearance {
            doc /* The airspace authority grants or withdraws the clearance. */
        }
        allocate grantClearanceAct to airspaceAuthority;
        trace grantClearanceAct to SurveillanceDroneSwarm::OA::grantClearanceAct;

        // functions: coordination between members, one function for the members performing one activity
        #Coordination action handOverSector : HandOverSector {
            doc /* Members hand a sector to a neighbour when one leaves to recharge. */
        }
        allocate handOverSector to system;
        trace handOverSector to SurveillanceDroneSwarm::OA::alphaHandOverSector;
        trace handOverSector to SurveillanceDroneSwarm::OA::bravoHandOverSector;
        #Coordination action rotateRecharge : RotateRecharge {
            doc /* Members agree the recharge rotation so no sector is emptied. */
        }
        allocate rotateRecharge to system;
        trace rotateRecharge to SurveillanceDroneSwarm::OA::alphaRotateRecharge;
        trace rotateRecharge to SurveillanceDroneSwarm::OA::bravoRotateRecharge;
        #Coordination action redistributeCoverage : RedistributeCoverage {
            doc /* Members re-spread over the area when one is lost or leaves. */
        }
        allocate redistributeCoverage to system;
        trace redistributeCoverage to SurveillanceDroneSwarm::OA::alphaRedistributeCoverage;
        trace redistributeCoverage to SurveillanceDroneSwarm::OA::bravoRedistributeCoverage;
        #Coordination action deconflictFlight : DeconflictFlight {
            doc /* Members announce flight intent so two drones do not share airspace. */
        }
        allocate deconflictFlight to system;
        trace deconflictFlight to SurveillanceDroneSwarm::OA::alphaDeconflictFlight;
        trace deconflictFlight to SurveillanceDroneSwarm::OA::bravoDeconflictFlight;
        #Coordination action relayReportsThroughNeighbour : RelayReportsThroughNeighbour {
            doc /* A member without a link to the operations centre relays reports through a neighbour. */
        }
        allocate relayReportsThroughNeighbour to system;
        trace relayReportsThroughNeighbour to SurveillanceDroneSwarm::OA::alphaRelayReports;
        trace relayReportsThroughNeighbour to SurveillanceDroneSwarm::OA::bravoRelayReports;
        #Coordination action correlateTracks : CorrelateTracks {
            doc /* Members agree tracks seen by different drones are one object. */
        }
        allocate correlateTracks to system;
        trace correlateTracks to SurveillanceDroneSwarm::OA::alphaCorrelateTracks;
        trace correlateTracks to SurveillanceDroneSwarm::OA::bravoCorrelateTracks;
        #Coordination action handOverTrack : HandOverTrack {
            doc /* A track is handed to the drone watching the sector the object moves into. */
        }
        allocate handOverTrack to system;
        trace handOverTrack to SurveillanceDroneSwarm::OA::alphaHandOverTrack;
        trace handOverTrack to SurveillanceDroneSwarm::OA::bravoHandOverTrack;
        #Coordination action admitMember : AdmitMember {
            doc /* A drone is checked, its classifier version included, before it takes part in coordination. */
        }
        allocate admitMember to system;
        trace admitMember to SurveillanceDroneSwarm::OA::alphaAdmitMember;
        trace admitMember to SurveillanceDroneSwarm::OA::bravoAdmitMember;

        // functions the members perform for the mission
        action detectAndClassifyObject : DetectAndClassifyObject {
            doc /* Detects moving objects in the sector and classifies them, or says Unknown. */
        }
        allocate detectAndClassifyObject to system;
        trace detectAndClassifyObject to SurveillanceDroneSwarm::OA::alphaDetect;
        trace detectAndClassifyObject to SurveillanceDroneSwarm::OA::bravoDetect;
        action deliverDetectionReport : DeliverDetectionReport {
            doc /* Delivers, holds while cut off, and clears on acknowledgement, each detection report. */
        }
        allocate deliverDetectionReport to system;
        trace deliverDetectionReport to SurveillanceDroneSwarm::OA::alphaDeliver;
        trace deliverDetectionReport to SurveillanceDroneSwarm::OA::bravoDeliver;
        action applySupervisoryDirectives : ApplySupervisoryDirectives {
            doc /* Takes up tasking, priorities and recall, and lands on recall. */
        }
        allocate applySupervisoryDirectives to system;
        trace applySupervisoryDirectives to SurveillanceDroneSwarm::OA::alphaDirectives;
        trace applySupervisoryDirectives to SurveillanceDroneSwarm::OA::bravoDirectives;
        action reportMemberStatus : ReportMemberStatus {
            doc /* Reports position, activity and degradations for the status picture. */
        }
        allocate reportMemberStatus to system;
        trace reportMemberStatus to SurveillanceDroneSwarm::OA::alphaStatus;
        trace reportMemberStatus to SurveillanceDroneSwarm::OA::bravoStatus;
        action reportTrackPicture : ReportTrackPicture {
            doc /* Reports the tracks held, one per object, stale ones marked. */
        }
        allocate reportTrackPicture to system;
        trace reportTrackPicture to SurveillanceDroneSwarm::OA::alphaTrackPicture;
        trace reportTrackPicture to SurveillanceDroneSwarm::OA::bravoTrackPicture;
        action returnToRecoveryPoint : ReturnToRecoveryPoint {
            doc /* Returns a cut-off drone to the recovery point on its own. */
        }
        allocate returnToRecoveryPoint to system;
        trace returnToRecoveryPoint to SurveillanceDroneSwarm::OA::alphaReturn;
        trace returnToRecoveryPoint to SurveillanceDroneSwarm::OA::bravoReturn;

        // functions the capabilities AlertTriage and DecisionRecordKeeping introduce; OA has no activity for them, so they trace to the capability and to the acknowledgement they serve
        action triageAlerts : TriageAlerts {
            doc /* Ranks reports most-likely-to-matter first and merges duplicates before they reach the operator. */
        }
        allocate triageAlerts to system;
        trace triageAlerts to SurveillanceDroneSwarm::OA::AlertTriage;
        trace triageAlerts to SurveillanceDroneSwarm::OA::acknowledgeReports;
        action keepDecisionRecords : KeepDecisionRecords {
            doc /* Keeps the decision record of every report: frames, classifier version, threshold in force and who acknowledged it. */
        }
        allocate keepDecisionRecords to system;
        trace keepDecisionRecords to SurveillanceDroneSwarm::OA::DecisionRecordKeeping;
        trace keepDecisionRecords to SurveillanceDroneSwarm::OA::acknowledgeReports;

        // interactions, carried over as functional exchanges
        flow handOverSectorAtoB of Common::SectorHandoverProposal from handOverSector.handoverOut to handOverSector.handoverIn;
        flow rotateRechargeAtoB of Common::RechargeRotationSlot from rotateRecharge.rotationOut to rotateRecharge.rotationIn;
        flow redistributeCoverageAtoB of Common::CoverageAssignment from redistributeCoverage.coverageOut to redistributeCoverage.coverageIn;
        flow deconflictFlightAtoB of Common::FlightIntent from deconflictFlight.intentOut to deconflictFlight.intentIn;
        flow relayReportsAtoB of Common::DetectionReport from relayReportsThroughNeighbour.relayOut to relayReportsThroughNeighbour.relayIn;
        flow correlateTracksAtoB of Common::Track from correlateTracks.correlationOut to correlateTracks.correlationIn;
        flow handOverTrackAtoB of Common::Track from handOverTrack.trackHandoverOut to handOverTrack.trackHandoverIn;
        flow admitMemberAtoB of Common::AdmissionExchange from admitMember.admissionOut to admitMember.admissionIn;
        flow detectionAlpha of Common::DetectionReport from detectAndClassifyObject.detectionOut to deliverDetectionReport.detectionIn;
        flow reportFromAlpha of Common::DetectionReport from deliverDetectionReport.reportOut to acknowledgeDetectionReport.reportIn;
        flow receiptToAlpha of Common::ReportReceipt from acknowledgeDetectionReport.receiptOut to deliverDetectionReport.receiptIn;
        flow statusFromAlpha of Common::MemberStatus from reportMemberStatus.statusOut to presentStatusPicture.statusIn;
        flow trackPictureFromAlpha of Common::Track from reportTrackPicture.trackPictureOut to mergeTracks.swarmTrackIn;
        flow cameraTracksToMerge of Common::Track from provideCameraTracks.cameraTrackOut to mergeTracks.cameraTrackIn;
        flow taskingToAlpha of Common::TaskingOrder from taskSurveillanceArea.taskingOut to applySupervisoryDirectives.taskingIn;
        flow prioritiesToAlpha of Common::PriorityDirective from commandSupervisoryPriorities.priorityOut to applySupervisoryDirectives.priorityIn;
        flow recallToAlpha of Common::RecallDirective from recallAndLand.recallOut to applySupervisoryDirectives.recallIn;
        flow reportsToTriage of Common::DetectionReport from deliverDetectionReport.reportOut to triageAlerts.reportsIn;
        flow alertsToJudgement of Common::TriagedAlerts from triageAlerts.alertsOut to acknowledgeDetectionReport.alertsIn;
        flow reportsToRecords of Common::DetectionReport from deliverDetectionReport.reportOut to keepDecisionRecords.reportIn;
        flow receiptsToRecords of Common::ReportReceipt from acknowledgeDetectionReport.receiptOut to keepDecisionRecords.receiptIn;

        // rules the system never breaks (CV-18), stated once and satisfied by the member whose machines carry them
        #Rule requirement RecallWins {
            doc /* Once a drone is recalled, it does not watch again until it has landed. */
            subject m : SwarmMember;
        }
        satisfy RecallWins by SwarmMember;
        #Rule requirement ReturnsWhenIsolated {
            doc /* From any situation a drone can be in, it can always get back to landed; an isolated drone included. */
            subject m : SwarmMember;
        }
        satisfy ReturnsWhenIsolated by SwarmMember;
        #Rule requirement GeofenceBreachEndsWatch {
            doc /* Once a drone is outside its cleared airspace, it does not watch until it has landed. */
            subject m : SwarmMember;
        }
        satisfy GeofenceBreachEndsWatch by SwarmMember;
        #Rule requirement QuarantinedStaysOut {
            doc /* Once a drone is quarantined, it takes no part in coordination until it has been readmitted. */
            subject m : SwarmMember;
        }
        satisfy QuarantinedStaysOut by SwarmMember;

        // hazards at the system boundary
        package Hazards {
            doc /* Hazards the system as a whole adds at its boundary, each stated once here and satisfied below by the function or component that mitigates it. */
            #Hazard requirement PositionDriftHazard {
                doc /* Without satellite positioning, a drone's position estimate drifts and its reports place objects in the wrong place. */
                subject m : SwarmMember;
            }
            #Hazard requirement MeshJammingHazard {
                doc /* Interference cuts the links between drones, and coordination stalls. */
                subject s : SurveillanceDroneSwarmSystem;
            }
            #Hazard requirement MisclassificationHazard {
                doc /* A detection is reported as the wrong class, or a forced class where Unknown was the truth. */
                subject s : SurveillanceDroneSwarmSystem;
            }
            #Hazard requirement SensingDegradedUnnoticedHazard {
                doc /* A sensor degrades and nobody knows the reports from it are unreliable. */
                subject m : SwarmMember;
            }
            #Hazard requirement StaleTrackHazard {
                doc /* A track is shown as current after nothing has seen the object for a while. */
                subject s : SurveillanceDroneSwarmSystem;
            }
            #Hazard requirement SpoofedMemberHazard {
                doc /* Something that is not one of the drones joins the mesh and takes part in coordination. */
                subject s : SurveillanceDroneSwarmSystem;
            }
            #Hazard requirement MixedClassifierVersionsHazard {
                doc /* Drones run different classifier versions and classify the same object differently. */
                subject s : SurveillanceDroneSwarmSystem;
            }
            #Hazard requirement OperatorOverloadHazard {
                doc /* More alerts reach the operator than they can judge, and they accept what is in front of them. */
                subject s : SurveillanceDroneSwarmSystem;
            }
        }
        satisfy SurveillanceDroneSwarm::SA::Hazards::PositionDriftHazard by SwarmMember;
        satisfy SurveillanceDroneSwarm::SA::Hazards::MeshJammingHazard by redistributeCoverage;
        satisfy SurveillanceDroneSwarm::SA::Hazards::MisclassificationHazard by detectAndClassifyObject;
        satisfy SurveillanceDroneSwarm::SA::Hazards::SensingDegradedUnnoticedHazard by reportMemberStatus;
        satisfy SurveillanceDroneSwarm::SA::Hazards::StaleTrackHazard by reportTrackPicture;
        satisfy SurveillanceDroneSwarm::SA::Hazards::SpoofedMemberHazard by admitMember;
        satisfy SurveillanceDroneSwarm::SA::Hazards::MixedClassifierVersionsHazard by admitMember;
        satisfy SurveillanceDroneSwarm::SA::Hazards::OperatorOverloadHazard by triageAlerts;

        // hazards stated at OA, satisfied here by path
        satisfy SurveillanceDroneSwarm::OA::Hazards::ManualCoordinationLagHazard by handOverSector;
        satisfy SurveillanceDroneSwarm::OA::Hazards::UnrecoveredDroneHazard by returnToRecoveryPoint;
        satisfy SurveillanceDroneSwarm::OA::Hazards::ReportLostInLinkGapHazard by deliverDetectionReport;
        satisfy SurveillanceDroneSwarm::OA::Hazards::WatchBeyondClearanceHazard by SwarmMember;
    }
