    package LA {
        doc /* Logical architecture of the SurveillanceDroneSwarm. The system is decomposed into logical functions, the member definition of the twelve-drone population and the state machines every member and the fleet follow. Every logical function realises an SA function. Nothing physical is chosen: every function stays allocated to one placeholder component, mainComponent, and whether the coordination and command-and-control functions end up on the ground or on the members is the decision of the next step, which also places the counted fleet and its peer representatives. */

        // ---------------------------------------------------------------
        // Placeholder component
        // ---------------------------------------------------------------

        part def SurveillanceDroneSwarmLogical {
            doc /* Placeholder logical component that holds every logical function until the next step decomposes it into logical components in more than one way and compares the ways. It is not a design choice. */
        }


        // ---------------------------------------------------------------
        // Coordination functions between members (realise SA functions)
        // ---------------------------------------------------------------

        #Coordination action def HandOverSector :> SurveillanceDroneSwarm::SA::HandOverSector {
            doc /* Logical function: a member that leaves to recharge hands its sector to a neighbour and stays until the neighbour confirms, so the sector stays watched. Realises SA::HandOverSector. */
        }

        #Coordination action def RotateRecharge :> SurveillanceDroneSwarm::SA::RotateRecharge {
            doc /* Logical function: members agree who leaves to recharge and who takes the place, so the rotation never empties a sector. Realises SA::RotateRecharge. */
        }

        #Coordination action def RedistributeCoverage :> SurveillanceDroneSwarm::SA::RedistributeCoverage {
            doc /* Logical function: members re-spread over the area when one is lost or leaves. It works from the last agreed assignment when links are jammed and can be performed by any member, so no single holder is needed. Realises SA::RedistributeCoverage. */
        }

        #Coordination action def DeconflictFlight :> SurveillanceDroneSwarm::SA::DeconflictFlight {
            doc /* Logical function: members announce flight intent so that two drones do not occupy the same airspace. Realises SA::DeconflictFlight. */
        }

        #Coordination action def RelayReportsThroughNeighbour :> SurveillanceDroneSwarm::SA::RelayReportsThroughNeighbour {
            doc /* Logical function: a member that cannot reach the operations centre sends its reports through a neighbour that can, and keeps each report until it is handed over. Realises SA::RelayReportsThroughNeighbour. */
        }

        #Coordination action def CorrelateTracks :> SurveillanceDroneSwarm::SA::CorrelateTracks {
            doc /* Logical function: members agree that tracks seen by different drones are the same object, giving one track per object. Realises SA::CorrelateTracks. */
        }

        #Coordination action def HandOverTrack :> SurveillanceDroneSwarm::SA::HandOverTrack {
            doc /* Logical function: a track is handed to the drone that watches the sector the object moves into. Realises SA::HandOverTrack. */
        }

        #Coordination action def AdmitMember :> SurveillanceDroneSwarm::SA::AdmitMember {
            doc /* Logical function: a drone is checked before it takes part in coordination, including the classifier version it runs; one that fails is quarantined until readmitted. Realises SA::AdmitMember. */
        }

        // ---------------------------------------------------------------
        // Command and control functions (realise SA functions)
        // ---------------------------------------------------------------

        #C2 action def TaskSurveillanceArea :> SurveillanceDroneSwarm::SA::TaskSurveillanceArea {
            doc /* Logical function: the swarm is tasked with the area of interest, its sectors and the mission window. Realises SA::TaskSurveillanceArea. */
        }

        #C2 action def CommandSupervisoryPriorities :> SurveillanceDroneSwarm::SA::CommandSupervisoryPriorities {
            doc /* Logical function: priorities, a sector to look at more closely and the reporting threshold are given to the swarm. Realises SA::CommandSupervisoryPriorities. */
        }

        #C2 action def RecallAndLand :> SurveillanceDroneSwarm::SA::RecallAndLand {
            doc /* Logical function: an order to recall and land the whole swarm or one drone, issuable at any time. Realises SA::RecallAndLand. */
        }

        #C2 action def PresentStatusPicture :> SurveillanceDroneSwarm::SA::PresentStatusPicture {
            doc /* Logical function: shows where every drone is, what it is doing, how much of the area is under watch and what is degraded. Realises SA::PresentStatusPicture. */
        }

        #C2 action def AcknowledgeDetectionReport :> SurveillanceDroneSwarm::SA::AcknowledgeDetectionReport {
            doc /* Logical function: each detection report is confirmed at the operations centre so nothing is lost in a link gap. Realises SA::AcknowledgeDetectionReport. */
        }

        // ---------------------------------------------------------------
        // Sensing, reporting and record functions (realise SA functions)
        // ---------------------------------------------------------------

        action def DetectAndClassifyObject :> SurveillanceDroneSwarm::SA::DetectAndClassifyObject {
            doc /* Logical function: detects a moving object in the member's sector and classifies it, saying Unknown when confidence is short of the reporting threshold. Realises SA::DetectAndClassifyObject. */
        }

        action def DeliverDetectionReport :> SurveillanceDroneSwarm::SA::DeliverDetectionReport {
            doc /* Logical function: delivers a report with position and time to the operations centre, holds it while cut off and clears it only on acknowledgement. Realises SA::DeliverDetectionReport. */
        }

        action def ApplySupervisoryDirectives :> SurveillanceDroneSwarm::SA::ApplySupervisoryDirectives {
            doc /* Logical function: a drone takes up the tasking, priorities and recall given by the duty controller and lands on recall. Realises SA::ApplySupervisoryDirectives. */
        }

        action def ReportMemberStatus :> SurveillanceDroneSwarm::SA::ReportMemberStatus {
            doc /* Logical function: a drone reports its position, activity and degradations, sensing degradation included, for the status picture. Realises SA::ReportMemberStatus. */
        }

        action def ReportTrackPicture :> SurveillanceDroneSwarm::SA::ReportTrackPicture {
            doc /* Logical function: reports the tracks held, one per object, marking a track stale once nothing has seen the object for 120 seconds. Realises SA::ReportTrackPicture. */
        }

        action def ReturnToRecoveryPoint :> SurveillanceDroneSwarm::SA::ReturnToRecoveryPoint {
            doc /* Logical function: a drone that has lost contact with the swarm returns to the recovery point on its own. Realises SA::ReturnToRecoveryPoint. */
        }

        action def TriageAlerts :> SurveillanceDroneSwarm::SA::TriageAlerts {
            doc /* Logical function: ranks reports so that what is most likely to matter reaches the operator first, merges duplicates and keeps the alert rate inside what one operator can judge. Realises SA::TriageAlerts. */
        }

        action def KeepDecisionRecords :> SurveillanceDroneSwarm::SA::KeepDecisionRecords {
            doc /* Logical function: keeps for every report the frames it came from, the classifier version, the reporting threshold in force and who acknowledged it. Realises SA::KeepDecisionRecords. */
        }

        // ---------------------------------------------------------------
        // Function usages, all allocated to the placeholder
        // ---------------------------------------------------------------

        action handOverSector : HandOverSector {
            doc /* Usage of the sector hand-over function; allocated to the placeholder until the next step places it. */
        }
        action rotateRecharge : RotateRecharge {
            doc /* Usage of the recharge rotation function; allocated to the placeholder until the next step places it. */
        }
        action redistributeCoverage : RedistributeCoverage {
            doc /* Usage of the coverage redistribution function; allocated to the placeholder until the next step places it. */
        }
        action deconflictFlight : DeconflictFlight {
            doc /* Usage of the flight deconfliction function; allocated to the placeholder until the next step places it. */
        }
        action relayReportsThroughNeighbour : RelayReportsThroughNeighbour {
            doc /* Usage of the report relay function; allocated to the placeholder until the next step places it. */
        }
        action correlateTracks : CorrelateTracks {
            doc /* Usage of the track correlation function; allocated to the placeholder until the next step places it. */
        }
        action handOverTrack : HandOverTrack {
            doc /* Usage of the track hand-over function; allocated to the placeholder until the next step places it. */
        }
        action admitMember : AdmitMember {
            doc /* Usage of the member admission function; allocated to the placeholder until the next step places it. */
        }
        action taskSurveillanceArea : TaskSurveillanceArea {
            doc /* Usage of the tasking function; allocated to the placeholder until the next step places it. */
        }
        action commandSupervisoryPriorities : CommandSupervisoryPriorities {
            doc /* Usage of the supervisory command function; allocated to the placeholder until the next step places it. */
        }
        action recallAndLand : RecallAndLand {
            doc /* Usage of the recall function; allocated to the placeholder until the next step places it. */
        }
        action presentStatusPicture : PresentStatusPicture {
            doc /* Usage of the status presentation function; allocated to the placeholder until the next step places it. */
        }
        action acknowledgeDetectionReport : AcknowledgeDetectionReport {
            doc /* Usage of the report acknowledgement function; allocated to the placeholder until the next step places it. */
        }
        action detectAndClassifyObject : DetectAndClassifyObject {
            doc /* Usage of the detection and classification function; allocated to the placeholder until the next step places it. */
        }
        action deliverDetectionReport : DeliverDetectionReport {
            doc /* Usage of the report delivery function; allocated to the placeholder until the next step places it. */
        }
        action applySupervisoryDirectives : ApplySupervisoryDirectives {
            doc /* Usage of the directive uptake function; allocated to the placeholder until the next step places it. */
        }
        action reportMemberStatus : ReportMemberStatus {
            doc /* Usage of the status reporting function; allocated to the placeholder until the next step places it. */
        }
        action reportTrackPicture : ReportTrackPicture {
            doc /* Usage of the track reporting function; allocated to the placeholder until the next step places it. */
        }
        action returnToRecoveryPoint : ReturnToRecoveryPoint {
            doc /* Usage of the return-to-recovery function; allocated to the placeholder until the next step places it. */
        }
        action triageAlerts : TriageAlerts {
            doc /* Usage of the alert triage function; allocated to the placeholder until the next step places it. */
        }
        action keepDecisionRecords : KeepDecisionRecords {
            doc /* Usage of the decision record function; allocated to the placeholder until the next step places it. */
        }

        // ---------------------------------------------------------------
        // Member definition: the replicable element of the population
        // ---------------------------------------------------------------


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

            transition MeshIntact -> MeshDegraded;
            transition MeshDegraded -> MeshIntact;
        }

        // ---------------------------------------------------------------
        // Worst-case estimates of the measures of effectiveness (CV-17)
        // These are the worst of the ground-centred and member-centred
        // allocations, because that choice is not taken at this layer.
        // ---------------------------------------------------------------

        #Estimate attribute areaUnderWatchFraction :> Common::areaUnderWatchFraction = 0.78 {
            doc /* Worst case 0.78. Basis: twelve drones, 40 min endurance, 20 min battery swap gives at most 40/60 airborne. Transit of up to 4 km each way at 18 m/s is about 7.4 min of the 40, leaving about 32.6 min of watching per 60 min cycle, so about 6.5 drones watch at a time. 6.5 x 3.0 km2 is about 19.6 km2 of 25 km2. Target 0.9 is not met by this arithmetic. */
        }

        #Estimate attribute coverageLossAfterMemberLossFraction :> Common::coverageLossAfterMemberLossFraction = 0.16 {
            doc /* Worst case 0.16. Basis: one watching drone holds about 3.0 km2 of the roughly 19.6 km2 under watch, about 0.15, before any re-spread; the same for either allocation because the loss precedes the redistribution. */
        }

        #Estimate attribute coverageUnderMeshJammingFraction :> Common::coverageUnderMeshJammingFraction = 0.58 {
            doc /* Worst case 0.58. Basis: with half the links jammed, at worst half of the hand-overs between neighbours fail and leave a sector empty for part of a swap turnaround, so the 0.78 baseline is cut by about a quarter. The member-centred allocation is the worse case. Placeholder target 0.75 is not met. */
        }

        #Estimate attribute reportAgeAtOperationsCentreSeconds :> Common::reportAgeAtOperationsCentreSeconds = 40 {
            doc /* Worst case 40 s with the link up. Basis: about 5 s to classify, up to three relay hops of about 2 s each through neighbours, about 5 s on the ground link and about 20 s for triage queuing. Relay hop count is the driver; units are seconds. */
        }

        #Estimate attribute positionErrorWithoutSatelliteMetres :> Common::positionErrorWithoutSatelliteMetres = 80 {
            doc /* Worst case 80 m after ten minutes without satellite positioning. Basis: about 10.8 km flown in ten minutes at 18 m/s; camera matching against stored maps bounds the drift, but over featureless ground the bound is loose. Placeholder target 50 m is not met. Units are metres. */
        }

        #Estimate attribute reportHoldWhileCutOffMinutes :> Common::reportHoldWhileCutOffMinutes = 40 {
            doc /* Worst case 40 min. Basis: the hold is bounded by one 40 min sortie, after which the drone lands and its held reports survive the battery swap on board. Units are minutes. */
        }

        #Estimate attribute missedDetectionFraction :> Common::missedDetectionFraction = 0.12 {
            doc /* Worst case 0.12. Basis: poor lighting, weather and deliberately misleading paint or shapes reduce what the sensors can tell apart. Placeholder target 0.10 is not met. */
        }

        #Estimate attribute falseAlarmsPerHour :> Common::falseAlarmsPerHour = 3 {
            doc /* Worst case 3 per hour reaching the operator. Basis: the reporting threshold is held at the level that gives the missed-detection figure above; a higher threshold trades false alarms for missed detections. Units are 1/h. */
        }

        #Estimate attribute alertsReachingOperatorPerHour :> Common::alertsReachingOperatorPerHour = 24 {
            doc /* Worst case 24 per hour after triage. Basis: duplicates from several drones are merged, but with all twelve drones flying and busy sectors the remaining alerts still exceed 20. At 30 s per alert the operator could judge up to 120 per hour. Units are 1/h. */
        }

        #Estimate attribute acknowledgedReportsThatMatterFraction :> Common::acknowledgedReportsThatMatterFraction = 0.7 {
            doc /* Worst case 0.7. Basis: triage ranks by classification confidence only at this layer, without operator feedback on what mattered. */
        }

        #Estimate attribute onboardClassificationCostUsdPerMember :> Common::onboardClassificationCostUsdPerMember = 350 {
            doc /* Worst case 350 USD per member. Basis: the case in which the whole classification runs on the drone, as in the member-centred allocation. Placeholder target 300 USD is not met. Units are USD. */
        }

        #Estimate attribute unattendedWatchDurationHours :> Common::unattendedWatchDurationHours = 0.7 {
            doc /* Worst case 0.7 h. Basis: batteries are swapped by ground crew, so without people the watch ends when the first 40 min sortie is spent. The 12 h figure is a target set here, not the customer's. Units are hours. */
        }

        // ---------------------------------------------------------------
        // Hazards this layer adds (a split of responsibilities)
        // ---------------------------------------------------------------

        package Hazards {
            doc /* Hazards the logical split of responsibilities adds, each stated once here and satisfied below by the function that mitigates it. */

            #Hazard requirement CoordinationConcentrationHazard {
                subject s : SurveillanceDroneSwarmLogical;
                doc /* About the coordination and command-and-control functions of the logical system: if they end up on one component, a ground station or a single member, the loss of that component stalls sector hand-over, rotation and redistribution for the whole swarm. */
            }

            #Hazard requirement SectorHandOffLostHazard {
                subject m : SwarmMember;
                doc /* About handOverSector between members: a member leaves to recharge before the neighbour has taken the sector, because the hand-over message was jammed or the neighbour was lost, and the sector is unwatched. */
            }

            #Hazard requirement RelayedReportDroppedHazard {
                subject m : SwarmMember;
                doc /* About relayReportsThroughNeighbour: a report handed to a neighbour for relay is dropped on the way, and the originating member believes it has been delivered. */
            }

            #Hazard requirement TrackHandOverGapHazard {
                subject m : SwarmMember;
                doc /* About handOverTrack and correlateTracks: a track is handed to a drone that does not take it up, or two drones both keep it, so the object is lost or shown twice. */
            }
        doc /* Hazards the member-centred split adds at LA: what moving coordination onto the members, and concentrating command and triage in single ground components, introduces. */

        #Hazard requirement SplitCoordinationHazard {
            subject m : SwarmMember;
            doc /* When jamming partitions the mesh, sub-swarms coordinate separately: two of them take the same sector while another sector is left empty, or two members leave to recharge from the same sector. */
        }
        #Hazard requirement LostHandoffHazard {
            subject m : SwarmMember;
            doc /* A sector or a track handed from one member to a neighbour is dropped in the hand-off: the leaving member has gone and the receiving member never took it, so the sector goes unwatched or the track goes stale unnoticed. */
        }
        #Hazard requirement GroundStationSinglePointHazard {
            subject g : GroundStation;
            doc /* All command and control sits in the one ground station: if it or its link is lost, tasking, supervisory priorities, recall and the status picture are unavailable and the operator cannot see or stop the swarm. */
        }
        #Hazard requirement TriageUnitSinglePointHazard {
            subject t : AlertTriageUnit;
            doc /* All reports pass through the one triage unit: if it fails, detection reports and decision records stop reaching the operator, or reach them unranked and unmerged. */
        }
        }
        satisfy SurveillanceDroneSwarm::SA::Hazards::MeshJammingHazard by relayReportsThroughNeighbour;
        satisfy SurveillanceDroneSwarm::SA::Hazards::MisclassificationHazard by detectAndClassifyObject;
        satisfy SurveillanceDroneSwarm::SA::Hazards::SensingDegradedUnnoticedHazard by reportMemberStatus;
        satisfy SurveillanceDroneSwarm::SA::Hazards::StaleTrackHazard by reportTrackPicture;
        satisfy SurveillanceDroneSwarm::SA::Hazards::SpoofedMemberHazard by admitMember;
        satisfy SurveillanceDroneSwarm::SA::Hazards::MixedClassifierVersionsHazard by admitMember;
        satisfy SurveillanceDroneSwarm::SA::Hazards::OperatorOverloadHazard by triageAlerts;

        satisfy Hazards::CoordinationConcentrationHazard by redistributeCoverage;
        satisfy Hazards::SectorHandOffLostHazard by rotateRecharge;
        satisfy Hazards::RelayedReportDroppedHazard by deliverDetectionReport;
        satisfy Hazards::TrackHandOverGapHazard by correlateTracks;
            // carried from the layer above; restored by the orchestrator
            allocate taskSurveillanceArea to dutyController;
            trace taskSurveillanceArea to SurveillanceDroneSwarm::SA::taskSurveillanceArea;
            allocate commandSupervisoryPriorities to dutyController;
            trace commandSupervisoryPriorities to SurveillanceDroneSwarm::SA::commandSupervisoryPriorities;
            allocate recallAndLand to dutyController;
            trace recallAndLand to SurveillanceDroneSwarm::SA::recallAndLand;
            allocate presentStatusPicture to groundStation;
            trace presentStatusPicture to SurveillanceDroneSwarm::SA::presentStatusPicture;
            allocate acknowledgeDetectionReport to operationsCentreAnalyst;
            trace acknowledgeDetectionReport to SurveillanceDroneSwarm::SA::acknowledgeDetectionReport;
            trace handOverSector to SurveillanceDroneSwarm::SA::handOverSector;
            trace rotateRecharge to SurveillanceDroneSwarm::SA::rotateRecharge;
            trace redistributeCoverage to SurveillanceDroneSwarm::SA::redistributeCoverage;
            trace deconflictFlight to SurveillanceDroneSwarm::SA::deconflictFlight;
            trace relayReportsThroughNeighbour to SurveillanceDroneSwarm::SA::relayReportsThroughNeighbour;
            trace correlateTracks to SurveillanceDroneSwarm::SA::correlateTracks;
            trace handOverTrack to SurveillanceDroneSwarm::SA::handOverTrack;
            trace admitMember to SurveillanceDroneSwarm::SA::admitMember;
            trace detectAndClassifyObject to SurveillanceDroneSwarm::SA::detectAndClassifyObject;
            trace deliverDetectionReport to SurveillanceDroneSwarm::SA::deliverDetectionReport;
            trace applySupervisoryDirectives to SurveillanceDroneSwarm::SA::applySupervisoryDirectives;
            trace reportMemberStatus to SurveillanceDroneSwarm::SA::reportMemberStatus;
            trace reportTrackPicture to SurveillanceDroneSwarm::SA::reportTrackPicture;
            trace returnToRecoveryPoint to SurveillanceDroneSwarm::SA::returnToRecoveryPoint;
            trace triageAlerts to SurveillanceDroneSwarm::SA::triageAlerts;
            trace keepDecisionRecords to SurveillanceDroneSwarm::SA::keepDecisionRecords;

        // ── architecture, alternative 2 ──
        #Member part def SwarmMember {
            doc /* One of the twelve identical drones, member-centred: besides sensing, classifying and reporting, every member itself performs the whole of swarm coordination (sector handover, recharge rotation, coverage redistribution, deconfliction, link relay, track correlation, track handover, member admission) over the mesh, so the watch does not depend on the ground station or the ground link. */
            out port meshOut : Common::MeshPort;
            in port meshIn : ~Common::MeshPort;
            out port reportsOut : Common::DetectionReport;
            out port trackPictureOut : Common::Track;
            out port statusOut : Common::MemberStatus;
            in port taskingIn : Common::TaskingOrder;
            in port priorityIn : Common::PriorityDirective;
            in port recallIn : Common::RecallDirective;
            in port receiptIn : Common::ReportReceipt;

            #Mode state def SwarmMemberModes {
                doc /* Operating condition of one member: nominal, without satellite positioning, sensors not trustworthy, cut off from the other members, or failed admission and readmitted. Carries the rule QuarantinedStaysOut. */
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
                    doc /* The member has positioning, trusted sensors, contact with the mesh and admission, and takes part in coordination. */
                }
                state NavigationDegraded {
                    doc /* The member has no satellite positioning and navigates by what its camera sees against stored maps. */
                }
                state SensingDegraded {
                    doc /* The member's sensors cannot be trusted as they are, and what it reports from them is marked accordingly. */
                }
                state Isolated {
                    doc /* The member is cut off from the other members and coordinates with none of them; it keeps watching its own sector on its own until it must recover. */
                }
                state Quarantined {
                    doc /* The member has failed admission (identity or classifier version) and takes no part in coordination until it has been readmitted. */
                }
                state Readmitted {
                    doc /* The member has passed the readmission check and is about to take part in coordination again. */
                }
                transition Nominal -> NavigationDegraded;
                transition NavigationDegraded -> Nominal;
                transition Nominal -> SensingDegraded;
                transition SensingDegraded -> Nominal;
                transition Nominal -> Isolated;
                transition Isolated -> Nominal;
                transition Nominal -> Quarantined;
                transition Quarantined -> Readmitted;
                transition Readmitted -> Nominal;
            }

            #State state def SwarmMemberStates {
                doc /* Where one member is in its sortie: on the ground, flying out, watching, flying back, recalled, outside its cleared airspace, or returning to the recovery point on its own. Carries the rules RecallWins, GeofenceBreachEndsWatch and ReturnsWhenIsolated. */
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
                    doc /* Flying from the recharge point to its sector, or to the sector it has just taken over from a neighbour. */
                }
                state Watching {
                    doc /* Holding watch over its sector. */
                }
                state Returning {
                    doc /* Flying back to the recharge point to swap the battery once relieved, or to land when the wind is above moderate. */
                }
                state Recalled {
                    doc /* Recalled by order and on its way down; it does not watch until landed. */
                }
                state Recovering {
                    doc /* Cut off and returning to the recovery point on its own. */
                }
                state OutsideClearance {
                    doc /* Outside the cleared airspace or the clearance withdrawn: on its way down, and it does not watch until landed. */
                }
                transition Landed -> Transiting;
                transition Transiting -> Watching;
                transition Watching -> Returning;
                transition Returning -> Landed;
                transition Transiting -> Recalled;
                transition Watching -> Recalled;
                transition Recalled -> Landed;
                transition Transiting -> Recovering;
                transition Watching -> Recovering;
                transition Recovering -> Landed;
                transition Transiting -> OutsideClearance;
                transition Watching -> OutsideClearance;
                transition OutsideClearance -> Landed;
            }
        }
        part def GroundStation {
            doc /* The thin ground component of the member-centred split: it only carries command and control (tasking, supervisory priorities, recall, status picture, acknowledgement). It does not coordinate the swarm; if it is lost the members keep the watch. */
            in port statusIn : Common::MemberStatus;
            in port trackPictureIn : Common::Track;
            in port alertsIn : Common::TriagedAlerts;
            in port recordsIn : Common::DecisionRecords;
            out port taskingOut : Common::TaskingOrder;
            out port priorityOut : Common::PriorityDirective;
            out port recallOut : Common::RecallDirective;
            out port receiptOut : Common::ReportReceipt;
            out port recordReceiptOut : Common::ReportReceipt;

            #Mode state def GroundStationModes {
                doc /* Whether the ground station can reach the swarm and the operations centre: with the link up it supervises, with the link down it can neither task nor recall and the members carry on alone. */
                initial start;
                transition start -> LinkUp;
                state LinkUp {
                    doc /* The link to the operations centre is available: tasking, command, reports, status and acknowledgements pass. */
                }
                state LinkDown {
                    doc /* The link is unavailable: the station holds what it has and the swarm coordinates and holds reports on its own. */
                }
                transition LinkUp -> LinkDown;
                transition LinkDown -> LinkUp;
            }

            #State state def GroundStationStates {
                doc /* What the ground station is doing for the operator: waiting for tasking, supervising the swarm, or issuing a recall. */
                initial start;
                transition start -> Standby;
                state Standby {
                    doc /* No mission window is tasked; nothing is being supervised. */
                }
                state Supervising {
                    doc /* Tasking and priorities are out, the status picture is presented and reports are acknowledged. */
                }
                state Recalling {
                    doc /* A recall order is being issued to the whole swarm or one drone. */
                }
                transition Standby -> Supervising;
                transition Supervising -> Recalling;
                transition Recalling -> Supervising;
                transition Supervising -> Standby;
            }
        }
        part def AlertTriageUnit {
            doc /* Ranks the reports of all members so that what most likely matters reaches the operator first, merges duplicates, and keeps the decision record of every report. Kept apart from the ground station so that command and control stays thin. */
            in port reportsIn : Common::DetectionReport;
            in port receiptIn : Common::ReportReceipt;
            out port alertsOut : Common::TriagedAlerts;
            out port decisionRecordsOut : Common::DecisionRecords;
        }
        part fleet : SwarmMember [12] {
            doc /* The twelve identical drones; every function a member performs, and all eight coordination functions, sit here. */
        }
        part memberA : SwarmMember {
            doc /* First representative member, one end of the peer link. */
        }
        part memberB : SwarmMember {
            doc /* Second representative member, the other end of the peer link. */
        }
        interface peerLink : Common::MeshInterface connect memberA.meshOut to memberB.meshIn;
        part groundStation : GroundStation {
            doc /* The ground station: command and control only. */
        }
        part triageUnit : AlertTriageUnit {
            doc /* The alert triage and decision-record component between the members and the operator. */
        }
        connection reportsFeed connect fleet.reportsOut to triageUnit.reportsIn;
        connection trackPictureFeed connect fleet.trackPictureOut to groundStation.trackPictureIn;
        connection statusFeed connect fleet.statusOut to groundStation.statusIn;
        connection taskingFeed connect groundStation.taskingOut to fleet.taskingIn;
        connection priorityFeed connect groundStation.priorityOut to fleet.priorityIn;
        connection recallFeed connect groundStation.recallOut to fleet.recallIn;
        connection receiptFeed connect groundStation.receiptOut to fleet.receiptIn;
        connection recordReceiptFeed connect groundStation.recordReceiptOut to triageUnit.receiptIn;
        connection alertsFeed connect triageUnit.alertsOut to groundStation.alertsIn;
        connection recordsFeed connect triageUnit.decisionRecordsOut to groundStation.recordsIn;
        allocate handOverSector to fleet;
        allocate rotateRecharge to fleet;
        allocate redistributeCoverage to fleet;
        allocate deconflictFlight to fleet;
        allocate relayReportsThroughNeighbour to fleet;
        allocate correlateTracks to fleet;
        allocate handOverTrack to fleet;
        allocate admitMember to fleet;
        allocate detectAndClassifyObject to fleet;
        allocate deliverDetectionReport to fleet;
        allocate applySupervisoryDirectives to fleet;
        allocate reportMemberStatus to fleet;
        allocate reportTrackPicture to fleet;
        allocate returnToRecoveryPoint to fleet;
        allocate taskSurveillanceArea to groundStation;
        allocate commandSupervisoryPriorities to groundStation;
        allocate recallAndLand to groundStation;
        allocate acknowledgeDetectionReport to groundStation;
        allocate triageAlerts to triageUnit;
        allocate keepDecisionRecords to triageUnit;
        satisfy SurveillanceDroneSwarm::SA::Hazards::PositionDriftHazard by fleet;
        satisfy SurveillanceDroneSwarm::SA::Hazards::MeshJammingHazard by fleet;
        satisfy SurveillanceDroneSwarm::SA::Hazards::MisclassificationHazard by fleet;
        satisfy SurveillanceDroneSwarm::SA::Hazards::SensingDegradedUnnoticedHazard by fleet;
        satisfy SurveillanceDroneSwarm::SA::Hazards::StaleTrackHazard by fleet;
        satisfy SurveillanceDroneSwarm::SA::Hazards::SpoofedMemberHazard by fleet;
        satisfy SurveillanceDroneSwarm::SA::Hazards::MixedClassifierVersionsHazard by fleet;
        satisfy SurveillanceDroneSwarm::SA::Hazards::OperatorOverloadHazard by triageUnit;
        satisfy LA::Hazards::CoordinationConcentrationHazard by fleet;
        satisfy LA::Hazards::SectorHandOffLostHazard by fleet;
        satisfy LA::Hazards::RelayedReportDroppedHazard by fleet;
        satisfy LA::Hazards::TrackHandOverGapHazard by fleet;
        satisfy Hazards::SplitCoordinationHazard by fleet;
        satisfy Hazards::LostHandoffHazard by fleet;
        satisfy Hazards::GroundStationSinglePointHazard by fleet;
        satisfy Hazards::TriageUnitSinglePointHazard by fleet;
        satisfy SurveillanceDroneSwarm::SA::RecallWins by fleet;
        satisfy SurveillanceDroneSwarm::SA::ReturnsWhenIsolated by fleet;
        satisfy SurveillanceDroneSwarm::SA::GeofenceBreachEndsWatch by fleet;
        satisfy SurveillanceDroneSwarm::SA::QuarantinedStaysOut by fleet;
        attribute fleetMemberCount = 12;
        attribute memberFlightMinutes = 40;
        attribute memberTurnaroundMinutes = 20;
        attribute sectorTransitMinutes = 6.6;
        attribute memberCoverageFraction = 0.12;
        assert constraint { areaUnderWatchFraction == fleetMemberCount * ((memberFlightMinutes - sectorTransitMinutes) / (memberFlightMinutes + memberTurnaroundMinutes)) * memberCoverageFraction }
        #prose part laTradeOff {
        doc /* Architecture trade-off for LA. Alternative 2 was taken.
                 alternative 1: total 0.52 (measures 0.29, review 0.44, structure 0.84, resilience 0.25)
                 alternative 2: total 0.65 (measures 0.29, review 0.56, structure 0.86, resilience 0.81)
                 The measures term scores the worst case of each alternative's own #Estimate: claims its architecture states with their basis, not measurements.
                 This comparison exists to place command and control, and the two alternatives differ exactly there: Alternative 1 puts sector handover, rotation, redistribution, deconfliction, track correlation and admission inside one GroundSwarmCoordinator; Alternative 2 puts all eight on SwarmMember and leaves a thin GroundStation holding only tasking, priorities, recall, acknowledgement and the status picture. I would take Alternative 2. The deciding evidence is the two components' own state machines. SwarmCoordinatorModes.FleetUnreachable says each drone 'acts on its last assignment' — coverage then decays as endurance runs out, and Alternative 1 discharges its own GroundCoordinatorSinglePointHazard and CoordinationConcentrationHazard onto fleet while allocating no coordination function to fleet, so that mitigation is unbacked. GroundStationModes.LinkDown says the members coordinate and hold reports on their own, and the allocations back it. Alternative 1 is also the weaker model on its own arithmetic: watchingMembers evaluates to 6.8, contradicting the stated 0.78 and 0.16, so three measures score vacuous against Alternative 2's one, and its coverageUnderMeshJammingFraction basis literally blames 'the member-centred allocation' for a worst case that belongs to a ground-centred decision path. Alternative 1 is not without merit and two of its choices should be carried across: recallToFleet, which keeps recall alive when the coordinator dies — Alternative 2 has no equivalent and its operator cannot stop the swarm with the station gone; and the split of GroundDecisionRecordStore from GroundAlertTriage, which Alternative 2 collapses into one AlertTriageUnit so that losing the ranker loses the provenance record. Alternative 1's triggered transitions are also the better basis for checking RecallWins and QuarantinedStaysOut than Alternative 2's untriggered ones. Before PA, Alternative 2 needs four fixes: a direct recall path to fleet, records split out of AlertTriageUnit, triggers and a return direction on the peer link (one unidirectional MeshPort cannot be the whole evidence for eight coordination functions, least of all distributed admitMember), and a rule monitor separate from the component that detects and classifies — neither alternative has one today. */
        }
    }
