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
    doc /* Hazards this split of responsibilities adds: what a ground-centred decision point and its hand-offs to the drones introduce. */
    #Hazard requirement GroundCoordinatorSinglePointHazard {
        subject c : GroundSwarmCoordinator;
        doc /* All handover, rotation and redistribution decisions are taken in one ground component; if it or its path to the drones is lost, no sector is handed over and no rotation is planned, and coverage decays as drones reach their endurance. */
    }
    #Hazard requirement DirectiveHandOffLostHazard {
        subject c : GroundSwarmCoordinator;
        doc /* A directive from the ground to a drone is lost or arrives late, so a sector is left with nobody assigned while the drone it was taken from has already left. */
    }
    #Hazard requirement ReportRelayLossHazard {
        subject m : SwarmMember;
        doc /* A report relayed through a neighbour is lost when the neighbour is lost, jammed or quarantined before the report reaches the ground. */
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

        // ── architecture, alternative 1 ──
        doc /* LA, architecture alternative 1: ground-centred command and control. The ground station decides every coordination that needs the whole picture: sector handover, recharge rotation, coverage redistribution, deconfliction, track correlation and admission. The twelve identical drones execute those directives, relay reports through neighbours over the mesh, and fall back to a stand-alone safe behaviour when the ground path is lost. Nothing physical is chosen here: how the ground path is carried is left to PA. */

        attribute fleetCount = 12.0 { doc /* The twelve drones the brief fixes, restated here because a constraint body cannot reach Common. */ }
        attribute sortieMinutes = 40.0 { doc /* Flight endurance of one drone, transit included, as the brief fixes it. */ }
        attribute turnaroundMinutes = 20.0 { doc /* Battery-swap turnaround on the ground, as the brief fixes it. */ }
        attribute transitMinutesEachWay = 3.0 { doc /* Design assumption, not fixed by the brief: the recharge point sits near the middle of the roughly 5 km by 5 km area, so a leg is about 2.7 km, which is 3 minutes at 18 m/s. It is spent from the 40 minutes of endurance. */ }
        attribute footprintSquareKm = 3.0 { doc /* Area one drone keeps under watch at watch altitude, as the brief fixes it. */ }
        attribute taskedAreaSquareKm = 25.0 { doc /* Largest tasked area, as the brief fixes it. */ }
        attribute jammedLinkFraction = 0.5 { doc /* Share of links between drones jammed in the jamming test condition, as the brief fixes it. */ }
        attribute watchingMembers = fleetCount * (sortieMinutes - 2.0 * transitMinutesEachWay) / (sortieMinutes + turnaroundMinutes) { doc /* Average number of drones on station at any moment: each drone watches for its endurance minus the two transit legs out of every sortie plus turnaround cycle of 60 minutes. Each drone covers 3.0 km2 against a fair share of 25/12 km2, so the watched share below is derived from the per-member footprint and is not bounded by the airborne share of the fleet. */ }
        part def GroundSwarmCoordinator {
            doc /* Ground component that takes every decision needing the whole picture: it decides sector handover, recharge rotation, coverage redistribution and flight deconfliction, correlates the tracks of all drones into one track per object, and admits or refuses members by identity and classifier version. It is the deciding point of this architecture and therefore its single point of failure. */
            in port taskingIn : Common::TaskingOrder { doc /* The tasked area, sectors and mission window from the console. */ }
            in port priorityIn : Common::PriorityDirective { doc /* Priorities and the sector to look at more closely, used when redistributing coverage. */ }
            in port statusIn : Common::MemberStatus { doc /* Position, activity, battery and degradations of every drone. */ }
            in port trackIn : Common::Track { doc /* Tracks held by each drone, to be correlated. */ }
            in port admissionIn : Common::AdmissionRequest { doc /* Identity and classifier version offered by a drone asking to take part. */ }
            in port directiveAckIn : Common::DirectiveAck { doc /* Acknowledgement of each directive by the drone it went to. */ }
            out port directiveOut : Common::CoordinationDirective { doc /* Sector assignment, handover, rotation, redistribution, deconfliction and admission verdict for the drones. */ }
            out port correlatedTrackOut : Common::Track { doc /* One correlated track per object, with stale ones marked, for triage. */ }

            #Mode state def SwarmCoordinatorModes {
                doc /* How far the coordinator can reach the drones: all of them, part of them because of jamming, or none. */
                initial start;
                transition start -> FleetReachable;
                state FleetReachable { doc /* Every drone answers; directives reach all of them. */ }
                state FleetPartiallyReachable { doc /* A share of the paths to drones is jammed; directives go over the surviving paths and through relaying neighbours. */ }
                state FleetUnreachable { doc /* No drone answers; each drone acts on its last assignment and its stand-alone rules. */ }
                transition jamPaths first FleetReachable accept jamNotice : Common::MemberSituationNotice then FleetPartiallyReachable;
                transition restorePaths first FleetPartiallyReachable accept restoreNotice : Common::MemberSituationNotice then FleetReachable;
                transition losePaths first FleetPartiallyReachable accept lossNotice : Common::MemberSituationNotice then FleetUnreachable;
                transition regainPaths first FleetUnreachable accept regainNotice : Common::MemberSituationNotice then FleetPartiallyReachable;
            }

            #State state def SwarmCoordinatorStates {
                doc /* What the coordinator is doing about the tasking: waiting for it, planning sectors, or supervising the plan. */
                initial start;
                transition start -> AwaitingTasking;
                state AwaitingTasking { doc /* No tasking yet; nothing to coordinate. */ }
                state Planning { doc /* Dividing the tasked area into sectors and assigning drones to them. */ }
                state Supervising { doc /* Directing handovers, rotation, redistribution and deconfliction against the plan. */ }
                transition receiveTasking first AwaitingTasking accept tasking : Common::TaskingOrder then Planning;
                transition planReady first Planning accept planned : Common::CoordinationDirective then Supervising;
                transition retask first Supervising accept retasking : Common::TaskingOrder then Planning;
            }
        }
        part def GroundOperatorConsole {
            doc /* Ground component through which the one operator tasks, commands, recalls and watches the swarm, and through which each detection report is acknowledged. It carries every command-and-control function. */
            out port taskingOut : Common::TaskingOrder { doc /* Tasking issued to the coordinator and the drones. */ }
            out port priorityOut : Common::PriorityDirective { doc /* Priorities and the reporting threshold issued to the coordinator, the drones and the record store. */ }
            out port recallOut : Common::RecallDirective { doc /* Recall of the whole swarm or of one drone, issuable at any time. */ }
            in port statusIn : Common::MemberStatus { doc /* Status of every drone, for the status picture. */ }
            in port alertsIn : Common::TriagedAlerts { doc /* Triaged alerts the operator judges. */ }
            in port recordsIn : Common::DecisionRecords { doc /* Decision records shown alongside the alerts. */ }
            out port receiptOut : Common::ReportReceipt { doc /* Acknowledgement of a detection report; the drones clear it and the record store notes who acknowledged. */ }
        }
        part def GroundAlertTriage {
            doc /* Ground component that ranks reports so the ones most likely to matter reach the operator first and merges duplicates using the correlated tracks, keeping the alert rate inside what one operator can judge. */
            in port reportsIn : Common::DetectionReport { doc /* Detection reports from all drones. */ }
            in port trackIn : Common::Track { doc /* Correlated tracks, used to recognise duplicates of one object. */ }
            out port alertsOut : Common::TriagedAlerts { doc /* Ranked, de-duplicated alerts for the console. */ }
        }
        part def GroundDecisionRecordStore {
            doc /* Ground component that keeps, for every report, the frames it came from, the classifier version, the reporting threshold in force and who acknowledged it. */
            in port reportIn : Common::DetectionReport { doc /* Each detection report with its provenance. */ }
            in port thresholdIn : Common::PriorityDirective { doc /* The reporting threshold in force when the report was made. */ }
            in port receiptIn : Common::ReportReceipt { doc /* Who acknowledged the report. */ }
            out port recordsOut : Common::DecisionRecords { doc /* The decision records, shown at the console. */ }
        }
        #Member part def SwarmMember {
            doc /* One of the twelve identical drones. It detects and classifies in its sector, holds and delivers its reports, relays neighbours' reports and hands tracks over across the mesh, and carries out the directives the ground coordinator sends. Its own state machines carry the safety rules, so it lands, recovers or stays out of coordination without waiting for the ground. */
            out port meshOut : Common::MeshPort { doc /* Traffic to a neighbour over the mesh: relayed reports and track handover. */ }
            in port meshIn : ~Common::MeshPort { doc /* Traffic from a neighbour over the mesh. */ }
            in port directiveIn : Common::CoordinationDirective { doc /* Directive from the ground coordinator. */ }
            out port directiveAckOut : Common::DirectiveAck { doc /* Acknowledgement of each directive, so a lost hand-off is noticed. */ }
            out port admissionOut : Common::AdmissionRequest { doc /* Identity and classifier version offered for admission. */ }
            out port statusOut : Common::MemberStatus { doc /* Position, activity and degradations, sensing degradation included. */ }
            out port trackOut : Common::Track { doc /* Tracks held by this drone, stale ones marked. */ }
            out port reportOut : Common::DetectionReport { doc /* Detection reports, held while cut off. */ }
            in port receiptIn : Common::ReportReceipt { doc /* Acknowledgement that lets the drone clear a held report. */ }
            in port taskingIn : Common::TaskingOrder { doc /* Tasking and mission window. */ }
            in port priorityIn : Common::PriorityDirective { doc /* Priorities and the reporting threshold in force. */ }
            in port recallIn : Common::RecallDirective { doc /* Recall order, issuable at any time. */ }

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
                state Nominal { doc /* The drone has positioning, trusted sensors, contact with the swarm and admission, and takes part in coordination. */ }
                state NavigationDegraded { doc /* The drone has no satellite positioning and navigates by what its camera sees against stored maps. */ }
                state SensingDegraded { doc /* The drone's sensors cannot be trusted as they are, and what it reports from them is marked accordingly. */ }
                state Isolated { doc /* The drone is cut off from the other drones and from the ground coordinator; it coordinates with none of them and acts on its last assignment. */ }
                state Quarantined { doc /* The drone has failed admission at the ground coordinator and takes no part in coordination until it has been readmitted. */ }
                state Readmitted { doc /* The drone has passed the readmission check and is about to take part in coordination again. */ }
                transition losePositioning first Nominal accept positioningLost : Common::MemberSituationNotice then NavigationDegraded;
                transition regainPositioning first NavigationDegraded accept positioningBack : Common::MemberSituationNotice then Nominal;
                transition degradeSensing first Nominal accept sensingBad : Common::MemberSituationNotice then SensingDegraded;
                transition restoreSensing first SensingDegraded accept sensingGood : Common::MemberSituationNotice then Nominal;
                transition loseContact first Nominal accept contactLost : Common::MemberSituationNotice then Isolated;
                transition regainContact first Isolated accept contactBack : Common::MemberSituationNotice then Nominal;
                transition failAdmission first Nominal accept refusal : Common::CoordinationDirective then Quarantined;
                transition readmit first Quarantined accept readmission : Common::CoordinationDirective then Readmitted;
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
                state Landed { doc /* On the ground, battery being swapped or waiting for a launch directive. */ }
                state Transiting { doc /* Flying from the recharge point to the sector the coordinator assigned. */ }
                state Watching { doc /* Holding watch over its sector. */ }
                state Returning { doc /* Flying back to the recharge point to swap the battery, or to land when the wind is above moderate. */ }
                state Recalled { doc /* Recalled by order and on its way down; it does not watch until landed. */ }
                state Recovering { doc /* Cut off from the swarm and the ground coordinator, returning to the recovery point on its own. */ }
                state OutsideClearance { doc /* Outside the cleared airspace or the clearance withdrawn: on its way down, and it does not watch until landed. */ }
                transition launch first Landed accept launchDirective : Common::CoordinationDirective then Transiting;
                transition Transiting -> Watching;
                transition endWatch first Watching accept releaseDirective : Common::CoordinationDirective then Returning;
                transition Returning -> Landed;
                transition recallWhileTransiting first Transiting accept recallOrderA : Common::RecallDirective then Recalled;
                transition recallWhileWatching first Watching accept recallOrderB : Common::RecallDirective then Recalled;
                transition Recalled -> Landed;
                transition loseSwarmContact first Watching accept contactNoticeA : Common::MemberSituationNotice then Recovering;
                transition loseContactInTransit first Transiting accept contactNoticeB : Common::MemberSituationNotice then Recovering;
                transition Recovering -> Landed;
                transition leaveClearanceWhileWatching first Watching accept clearanceNoticeA : Common::AirspaceClearance then OutsideClearance;
                transition leaveClearanceInTransit first Transiting accept clearanceNoticeB : Common::AirspaceClearance then OutsideClearance;
                transition OutsideClearance -> Landed;
                transition windLimit first Watching accept windNotice : Common::MemberSituationNotice then Returning;
            }
        }
        part groundCoordinator : GroundSwarmCoordinator { doc /* The ground coordinator: the one place where sector, rotation, redistribution, deconfliction, correlation and admission are decided. */ }
        part operatorConsole : GroundOperatorConsole { doc /* The console of the one operator; command and control sit here. */ }
        part groundTriage : GroundAlertTriage { doc /* Alert triage in front of the operator. */ }
        part groundRecordStore : GroundDecisionRecordStore { doc /* Decision records of every report. */ }
        part fleet : SwarmMember [12] { doc /* The twelve identical drones. */ }
        part memberA : SwarmMember { doc /* First representative of the population, one end of the peer exchange over the mesh. */ }
        part memberB : SwarmMember { doc /* Second representative of the population, the other end of the peer exchange over the mesh. */ }
        interface peerLink : Common::MeshInterface connect memberA.meshOut to memberB.meshIn { doc /* Peer exchange from one drone to a neighbour over the mesh: relayed reports and track handover. */ }
        interface peerLinkBack : Common::MeshInterface connect memberB.meshOut to memberA.meshIn { doc /* The same exchange in the other direction. */ }
        connection taskingToFleet connect operatorConsole.taskingOut to fleet.taskingIn { doc /* Tasking reaches every drone. */ }
        connection taskingToCoordinator connect operatorConsole.taskingOut to groundCoordinator.taskingIn { doc /* Tasking reaches the coordinator, which plans sectors from it. */ }
        connection priorityToFleet connect operatorConsole.priorityOut to fleet.priorityIn { doc /* Priorities and the reporting threshold reach every drone. */ }
        connection priorityToCoordinator connect operatorConsole.priorityOut to groundCoordinator.priorityIn { doc /* Priorities reach the coordinator for redistribution. */ }
        connection priorityToRecordStore connect operatorConsole.priorityOut to groundRecordStore.thresholdIn { doc /* The reporting threshold in force is kept for the decision records. */ }
        connection recallToFleet connect operatorConsole.recallOut to fleet.recallIn { doc /* Recall goes straight to the drones, not through the coordinator, so it stays effective when the coordinator is lost. */ }
        connection directivesToFleet connect groundCoordinator.directiveOut to fleet.directiveIn { doc /* Coordination directives from the ground to the drones. */ }
        connection directiveAcks connect fleet.directiveAckOut to groundCoordinator.directiveAckIn { doc /* Drones acknowledge each directive. */ }
        connection admissionRequests connect fleet.admissionOut to groundCoordinator.admissionIn { doc /* Drones offer identity and classifier version for admission. */ }
        connection statusToCoordinator connect fleet.statusOut to groundCoordinator.statusIn { doc /* Drone status feeds the coordinator's decisions. */ }
        connection statusToConsole connect fleet.statusOut to operatorConsole.statusIn { doc /* Drone status feeds the status picture. */ }
        connection tracksToCoordinator connect fleet.trackOut to groundCoordinator.trackIn { doc /* Tracks from all drones go to the coordinator for correlation. */ }
        connection correlatedTracksToTriage connect groundCoordinator.correlatedTrackOut to groundTriage.trackIn { doc /* Correlated tracks let triage merge duplicates. */ }
        connection reportsToTriage connect fleet.reportOut to groundTriage.reportsIn { doc /* Detection reports go to triage. */ }
        connection reportsToRecords connect fleet.reportOut to groundRecordStore.reportIn { doc /* Detection reports go to the record store. */ }
        connection alertsToConsole connect groundTriage.alertsOut to operatorConsole.alertsIn { doc /* Triaged alerts go to the operator. */ }
        connection receiptsToFleet connect operatorConsole.receiptOut to fleet.receiptIn { doc /* Acknowledgement lets drones clear held reports. */ }
        connection receiptsToRecords connect operatorConsole.receiptOut to groundRecordStore.receiptIn { doc /* Acknowledgement records who acknowledged the report. */ }
        connection recordsToConsole connect groundRecordStore.recordsOut to operatorConsole.recordsIn { doc /* Decision records are available at the console. */ }
        allocate handOverSector to groundCoordinator;
        allocate rotateRecharge to groundCoordinator;
        allocate redistributeCoverage to groundCoordinator;
        allocate deconflictFlight to groundCoordinator;
        allocate correlateTracks to groundCoordinator;
        allocate admitMember to groundCoordinator;
        allocate relayReportsThroughNeighbour to fleet;
        allocate handOverTrack to fleet;
        allocate detectAndClassifyObject to fleet;
        allocate deliverDetectionReport to fleet;
        allocate applySupervisoryDirectives to fleet;
        allocate reportMemberStatus to fleet;
        allocate reportTrackPicture to fleet;
        allocate returnToRecoveryPoint to fleet;
        allocate taskSurveillanceArea to operatorConsole;
        allocate commandSupervisoryPriorities to operatorConsole;
        allocate recallAndLand to operatorConsole;
        allocate presentStatusPicture to operatorConsole;
        allocate acknowledgeDetectionReport to operatorConsole;
        allocate triageAlerts to groundTriage;
        allocate keepDecisionRecords to groundRecordStore;
        satisfy SurveillanceDroneSwarm::SA::Hazards::PositionDriftHazard by fleet;
        satisfy SurveillanceDroneSwarm::SA::Hazards::MeshJammingHazard by fleet;
        satisfy SurveillanceDroneSwarm::SA::Hazards::MisclassificationHazard by fleet;
        satisfy SurveillanceDroneSwarm::SA::Hazards::SensingDegradedUnnoticedHazard by fleet;
        satisfy SurveillanceDroneSwarm::SA::Hazards::StaleTrackHazard by groundCoordinator;
        satisfy SurveillanceDroneSwarm::SA::Hazards::SpoofedMemberHazard by groundCoordinator;
        satisfy SurveillanceDroneSwarm::SA::Hazards::MixedClassifierVersionsHazard by groundCoordinator;
        satisfy SurveillanceDroneSwarm::SA::Hazards::OperatorOverloadHazard by groundTriage;
        satisfy Hazards::GroundCoordinatorSinglePointHazard by fleet;
        satisfy Hazards::DirectiveHandOffLostHazard by groundCoordinator;
        satisfy Hazards::ReportRelayLossHazard by fleet;
        satisfy LA::Hazards::CoordinationConcentrationHazard by fleet;
        satisfy LA::Hazards::SectorHandOffLostHazard by groundCoordinator;
        satisfy LA::Hazards::RelayedReportDroppedHazard by fleet;
        satisfy LA::Hazards::TrackHandOverGapHazard by groundCoordinator;
        satisfy SurveillanceDroneSwarm::SA::RecallWins by fleet;
        satisfy SurveillanceDroneSwarm::SA::ReturnsWhenIsolated by fleet;
        satisfy SurveillanceDroneSwarm::SA::GeofenceBreachEndsWatch by fleet;
        satisfy SurveillanceDroneSwarm::SA::QuarantinedStaysOut by fleet;
        assert constraint { areaUnderWatchFraction == watchingMembers * footprintSquareKm / taskedAreaSquareKm }
        assert constraint { coverageLossAfterMemberLossFraction == 1.0 / watchingMembers }
        assert constraint { coverageUnderMeshJammingFraction == watchingMembers * footprintSquareKm / taskedAreaSquareKm * (1.0 - jammedLinkFraction * turnaroundMinutes / (sortieMinutes + turnaroundMinutes)) }
    }
