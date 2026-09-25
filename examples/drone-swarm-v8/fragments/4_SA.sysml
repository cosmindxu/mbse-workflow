    package SA {
    doc /* System-level architecture of SurveillanceDroneSwarm as a single black box: its boundary ports on the environment, the actors it faces across that boundary, and the functions it performs, each traced to the operational activity it realises. The watchAsset population declared at OA is taken over here as one box; its member definition (SurveillanceDrone) is carried down to LA and is never instantiated at this layer -- no fleet, no representatives, no internal structure. */

    // ===== Actors the system faces across its boundary =====

    #Actor part def SwarmSupervisor {
        doc /* the single operator who tasks, commands, recalls and watches the whole swarm; source of mission tasking, supervisory command and recall, recipient of the status picture */
        out port missionTaskingOut : Common::MissionTasking {
            doc /* mission tasking issued toward the system */
        }
        out port supervisoryCommandOut : Common::SupervisoryCommand {
            doc /* supervisory command issued toward the system */
        }
        out port recallOrderOut : Common::RecallOrder {
            doc /* recall order issued toward the system, at any time */
        }
        in port statusPictureIn : Common::StatusPicture {
            doc /* status picture received from the system */
        }
    }

    #Actor part def OperationsCentreAnalyst {
        doc /* watches feeds and reports, judges what matters, acknowledges each detection report; the one whose attention triage protects */
        out port reportAcknowledgementOut : Common::ReportAcknowledgement {
            doc /* acknowledgement issued for a received detection report */
        }
        in port detectionReportsIn : Common::DetectionReport {
            doc /* detection reports received from the system */
        }
        in port correlatedTracksIn : Common::Track {
            doc /* correlated tracks received from the system, merged here with the fixed camera network's tracks */
        }
        in port triagedAlertStreamIn : Common::TriagedAlert {
            doc /* the triaged, duplicate-merged alert stream received from the system */
        }
        in port decisionRecordIn : Common::DecisionRecord {
            doc /* the decision record received for each report */
        }
    }

    #Actor part def AirspaceAuthority {
        doc /* clears when and where anything may fly; its geofence and window gate every sortie */
        out port airspaceClearanceOut : Common::AirspaceClearance {
            doc /* the cleared volume and window issued to the system */
        }
    }

    #Actor part def OperatingEnvironment {
        doc /* the physical world the swarm watches and flies in: the objects to be detected, the conditions that degrade sensing, radio interference, satellite-positioning outages and the weather it must operate within */
        out port movingObjectsInAreaOut : Common::MovingObjectsInArea {
            doc /* the moving objects present in the watched area */
        }
        out port sceneConditionsOut : Common::SceneConditions {
            doc /* lighting, weather and deliberately misleading paint or shapes */
        }
        out port radioInterferenceOut : Common::RadioInterference {
            doc /* a source of interference degrading the mesh or the ground-station link */
        }
        out port satellitePositioningOutageOut : Common::SatellitePositioningOutage {
            doc /* an interval during which satellite positioning is unavailable */
        }
        out port weatherLimitOut : Common::WeatherLimit {
            doc /* the weather condition the swarm is currently operating in */
        }
    }

    // ===== Carried population member definition (CV-16): the replicable element, never instantiated at SA =====

    #Member part def SurveillanceDrone {
        doc /* the one replicable member of the watchAsset population, the twelve identical drones the system is realised by. Carried at SA as a definition only -- no usage, no fleet, no representatives at this layer, because the system is still one box here. LA instantiates it as the fleet and as coordination/C2 representatives; PA realises it physically. */
        out port meshOut : Common::MeshPeerPort {
            doc /* this member's outgoing mesh link to a peer member */
        }
        in port meshIn : ~Common::MeshPeerPort {
            doc /* this member's incoming mesh link from a peer member, the conjugate of meshOut */
        }
    }

    // ===== The system as one black box =====

    part def SurveillanceDroneSwarmSystem {
        doc /* the SurveillanceDroneSwarm: one black-box system that takes over the watchAsset operational entity (SurveillanceDroneSwarm::OA::watchAsset). It carries the tasked area from unwatched and unreported to continuously watched with acknowledged detection reports at the operations centre. The population that realises it -- twelve identical SurveillanceDrone members -- is carried down to LA as one member definition and is never instantiated here: this box has no internal parts. */

        in port missionTaskingIn : Common::MissionTasking {
            doc /* the area of interest, its sectors and the mission window */
        }
        in port supervisoryCommandIn : Common::SupervisoryCommand {
            doc /* priorities, a sector to look at more closely, and the reporting threshold */
        }
        in port recallOrderIn : Common::RecallOrder {
            doc /* an order to recall and land the whole swarm or one drone */
        }
        in port reportAcknowledgementIn : Common::ReportAcknowledgement {
            doc /* the operations centre confirming each detection report */
        }
        in port movingObjectsInAreaIn : Common::MovingObjectsInArea {
            doc /* the objects the mission is about */
        }
        in port sceneConditionsIn : Common::SceneConditions {
            doc /* conditions that degrade what the sensors can tell apart */
        }
        in port airspaceClearanceIn : Common::AirspaceClearance {
            doc /* the cleared volume and window the system may fly in */
        }
        in port radioInterferenceIn : Common::RadioInterference {
            doc /* interference affecting the mesh or the ground-station link */
        }
        in port satellitePositioningOutageIn : Common::SatellitePositioningOutage {
            doc /* a satellite-positioning outage in effect */
        }
        in port weatherLimitIn : Common::WeatherLimit {
            doc /* the weather the system must operate within */
        }
        out port detectionReportsOut : Common::DetectionReport {
            doc /* position, time, class, confidence and provenance for each detected object */
        }
        out port correlatedTracksOut : Common::Track {
            doc /* one track per object, for merging with the fixed camera network's tracks */
        }
        out port triagedAlertStreamOut : Common::TriagedAlert {
            doc /* what is most likely to matter, first, duplicates merged, sized to one operator */
        }
        out port statusPictureOut : Common::StatusPicture {
            doc /* where every drone is, what it is doing, coverage and what is degraded */
        }
        out port decisionRecordOut : Common::DecisionRecord {
            doc /* for every report: frames, classifier version, threshold in force and who acknowledged it */
        }

        mode : SwarmOperatingMode {
            doc /* the system's operating mode as a whole */
        }
        availability : SwarmAvailabilityState {
            doc /* whether the system as a whole can currently be tasked and is delivering the watch */
        }
    }

    part swarmSupervisor : SwarmSupervisor {
        doc /* the supervisor on duty for this operation, facing the system at its boundary */
    }
    part opsCentreAnalyst : OperationsCentreAnalyst {
        doc /* the analyst on duty at the operations centre, facing the system at its boundary */
    }
    part airspaceAuthority : AirspaceAuthority {
        doc /* the airspace authority governing this operation's area of interest */
    }
    part operatingEnvironment : OperatingEnvironment {
        doc /* the physical environment this operation watches and flies in */
    }
    part surveillanceDroneSwarm : SurveillanceDroneSwarmSystem {
        doc /* the system under design, as one instance for this operation */
    }

    // ===== System ports wired to the actors =====

    connection missionTaskingLink connect surveillanceDroneSwarm.missionTaskingIn to swarmSupervisor.missionTaskingOut {
        doc /* carries mission tasking from the supervisor to the system */
    }
    connection supervisoryCommandLink connect surveillanceDroneSwarm.supervisoryCommandIn to swarmSupervisor.supervisoryCommandOut {
        doc /* carries supervisory command from the supervisor to the system */
    }
    connection recallOrderLink connect surveillanceDroneSwarm.recallOrderIn to swarmSupervisor.recallOrderOut {
        doc /* carries a recall order from the supervisor to the system at any time */
    }
    connection statusPictureLink connect surveillanceDroneSwarm.statusPictureOut to swarmSupervisor.statusPictureIn {
        doc /* carries the status picture from the system to the supervisor */
    }
    connection reportAckLink connect surveillanceDroneSwarm.reportAcknowledgementIn to opsCentreAnalyst.reportAcknowledgementOut {
        doc /* carries the analyst's acknowledgement of each detection report to the system */
    }
    connection detectionReportsLink connect surveillanceDroneSwarm.detectionReportsOut to opsCentreAnalyst.detectionReportsIn {
        doc /* carries detection reports from the system to the analyst */
    }
    connection correlatedTracksLink connect surveillanceDroneSwarm.correlatedTracksOut to opsCentreAnalyst.correlatedTracksIn {
        doc /* carries correlated tracks from the system to the analyst */
    }
    connection triagedAlertLink connect surveillanceDroneSwarm.triagedAlertStreamOut to opsCentreAnalyst.triagedAlertStreamIn {
        doc /* carries the triaged alert stream from the system to the analyst */
    }
    connection decisionRecordLink connect surveillanceDroneSwarm.decisionRecordOut to opsCentreAnalyst.decisionRecordIn {
        doc /* carries the decision record from the system to the analyst */
    }
    connection airspaceClearanceLink connect surveillanceDroneSwarm.airspaceClearanceIn to airspaceAuthority.airspaceClearanceOut {
        doc /* carries airspace clearance from the airspace authority to the system */
    }
    connection movingObjectsLink connect surveillanceDroneSwarm.movingObjectsInAreaIn to operatingEnvironment.movingObjectsInAreaOut {
        doc /* carries the objects present in the area to the system's sensors */
    }
    connection sceneConditionsLink connect surveillanceDroneSwarm.sceneConditionsIn to operatingEnvironment.sceneConditionsOut {
        doc /* carries scene conditions to the system's sensors */
    }
    connection radioInterferenceLink connect surveillanceDroneSwarm.radioInterferenceIn to operatingEnvironment.radioInterferenceOut {
        doc /* carries radio interference exposure to the system */
    }
    connection satOutageLink connect surveillanceDroneSwarm.satellitePositioningOutageIn to operatingEnvironment.satellitePositioningOutageOut {
        doc /* carries satellite-positioning outage exposure to the system */
    }
    connection weatherLimitLink connect surveillanceDroneSwarm.weatherLimitIn to operatingEnvironment.weatherLimitOut {
        doc /* carries the current weather to the system */
    }

    // ===== System modes and states (CV-07) =====
    // SwarmOperatingMode also carries, at this layer, the brief's member modes (NavigationDegraded,
    // SensingDegraded, Isolated, Quarantined) and the fleet mode (MeshDegraded), because the member
    // and the fleet are not instantiated here -- the system is still one box. It also carries the
    // four rules the system never breaks (CV-18): RecallWins, GeofenceBreachEndsWatch,
    // QuarantinedStaysOut and ReturnsWhenIsolated.

    #Mode state def SwarmOperatingMode {
        doc /* the system's operating mode as a whole, abstracted from individual members' duty cycles, which are carried at LA */
        initial start;
        transition start -> Watching;
        state Watching {
            doc /* holding continuous watch over the tasked area */
        }
        state Degraded {
            doc /* operating with reduced coverage or reliability: interference, GNSS outage, weather or member loss */
        }
        state NavigationDegraded {
            doc /* the brief's member mode: navigation is degraded (e.g. a GNSS outage in effect) and position estimates are less trustworthy */
        }
        state SensingDegraded {
            doc /* the brief's member mode: a sensor has degraded and reports drawn from it are marked less reliable */
        }
        state Isolated {
            doc /* the brief's member mode: cut off from the mesh, unable to coordinate with the rest of the swarm */
        }
        state MeshDegraded {
            doc /* the brief's fleet mode: the mesh as a whole is degraded, e.g. by radio interference, and coordination is impaired */
        }
        state AirspaceBreach {
            doc /* outside the cleared volume or window issued by the airspace authority; watch does not resume until landed */
        }
        state Quarantined {
            doc /* the brief's member mode: excluded from coordination on suspicion of not being a genuine member, pending readmission */
        }
        state Recalled {
            doc /* returning to land following a recall order */
        }
        state Grounded {
            doc /* not flying: fully landed, whether recalled, faulted, quarantined, in airspace breach, or awaiting airspace clearance */
        }
        transition Watching -> Degraded;
        transition Degraded -> Watching;
        transition Watching -> NavigationDegraded;
        transition NavigationDegraded -> Watching;
        transition Watching -> SensingDegraded;
        transition SensingDegraded -> Watching;
        transition Watching -> Isolated;
        transition Isolated -> Watching;
        transition Watching -> MeshDegraded;
        transition MeshDegraded -> Watching;
        transition Watching -> AirspaceBreach;
        transition AirspaceBreach -> Grounded;
        transition Watching -> Quarantined;
        transition Quarantined -> Grounded;
        transition Watching -> Recalled;
        transition Degraded -> Recalled;
        transition Recalled -> Grounded;
        transition Grounded -> Watching;

        @SysproseVerification::PropertyPattern {
            doc /* RecallWins: once the swarm is recalled, it does not watch again until it has landed */
            attribute pattern = "absence";
            attribute scope = "between";
            attribute q = "state Recalled";
            attribute r = "state Grounded";
            attribute p = "state Watching";
        }
        @SysproseVerification::PropertyPattern {
            doc /* GeofenceBreachEndsWatch: once the swarm is outside its cleared airspace, it does not watch until it has landed */
            attribute pattern = "absence";
            attribute scope = "between";
            attribute q = "state AirspaceBreach";
            attribute r = "state Grounded";
            attribute p = "state Watching";
        }
        @SysproseVerification::PropertyPattern {
            doc /* QuarantinedStaysOut: once quarantined, the swarm takes no part in watch until it has landed and can be readmitted */
            attribute pattern = "absence";
            attribute scope = "between";
            attribute q = "state Quarantined";
            attribute r = "state Grounded";
            attribute p = "state Watching";
        }
        @SysproseVerification::PropertyPattern {
            doc /* ReturnsWhenIsolated: from any situation the swarm can be in, it can always get back to landed, an isolated member's situation included */
            attribute pattern = "recovery";
            attribute scope = "globally";
            attribute p = "state Grounded";
        }
    }

    #State state def SwarmAvailabilityState {
        doc /* whether the system as a whole can currently be tasked and is delivering the watch */
        initial start;
        transition start -> Nominal;
        state Nominal {
            doc /* available: accepting tasking and commands, delivering reports at target coverage */
        }
        state Constrained {
            doc /* available but operating under an active constraint: interference, GNSS outage, weather or airspace limits */
        }
        state Unavailable {
            doc /* not available: grounded or recalled, not delivering the watch */
        }
        transition Nominal -> Constrained;
        transition Constrained -> Nominal;
        transition Nominal -> Unavailable;
        transition Constrained -> Unavailable;
        transition Unavailable -> Nominal;
    }

    // ===== Coordination functions of the system (#Coordination), each traced to its OA activity, each with a flow =====

    #Coordination action handOverSector : SurveillanceDroneSwarm::OA::HandOverSector {
        doc /* the system's function that settles sector handover between members, entirely within the swarm's boundary; traces to OA::HandOverSector */
        flow sectorHandoverFlow of Common::SectorAssignment from reqOut to reqIn;
    }
    #Coordination action rotateRecharge : SurveillanceDroneSwarm::OA::RotateRecharge {
        doc /* the system's function that settles recharge rotation between members; traces to OA::RotateRecharge */
        flow rechargeRotationFlow of Common::RechargeRotationPlan from reqOut to reqIn;
    }
    #Coordination action redistributeCoverage : SurveillanceDroneSwarm::OA::RedistributeCoverage {
        doc /* the system's function that re-spreads members across sectors as one leaves, rejoins or is lost; traces to OA::RedistributeCoverage */
        flow coverageRedistributionFlow of Common::CoverageRedistributionPlan from reqOut to reqIn;
    }
    #Coordination action deconflictFlight : SurveillanceDroneSwarm::OA::DeconflictFlight {
        doc /* the system's function that keeps members apart in the air; traces to OA::DeconflictFlight */
        flow deconflictionFlow of Common::DeconflictionAdvisory from reqOut to reqIn;
    }
    #Coordination action relayThroughNeighbour : SurveillanceDroneSwarm::OA::RelayThroughNeighbour {
        doc /* the system's function that forwards one member's traffic through another when a direct path is unavailable; traces to OA::RelayThroughNeighbour */
        flow relayFlow of Common::RelayedMessage from reqOut to reqIn;
    }
    #Coordination action correlateTracks : SurveillanceDroneSwarm::OA::CorrelateTracks {
        doc /* the system's function that merges observations of the same object from different members into one track; traces to OA::CorrelateTracks */
        flow trackCorrelationFlow of Common::Track from reqOut to reqIn;
    }
    #Coordination action handOverTrack : SurveillanceDroneSwarm::OA::HandOverTrack {
        doc /* the system's function that passes custody of a track between members; traces to OA::HandOverTrack */
        flow trackHandoverFlow of Common::Track from reqOut to reqIn;
    }
    #Coordination action admitMember : SurveillanceDroneSwarm::OA::AdmitMember {
        doc /* the system's function that decides whether a candidate joins the mesh; traces to OA::AdmitMember */
        flow admissionRequestFlow of Common::MembershipRequest from admitReqOut to admitReqIn;
        flow admissionDecisionFlow of Common::MembershipDecision from admitDecOut to admitDecIn;
    }

    // ===== Command-and-control functions of the system (#C2), each traced to its OA activity, each with a flow =====

    #C2 action taskSurveillanceMission : SurveillanceDroneSwarm::OA::TaskSurveillanceMission {
        doc /* the system's function that takes mission tasking from the supervisor; traces to OA::TaskSurveillanceMission */
        flow missionTaskingFlow of Common::MissionTasking from cmdOut to cmdIn;
    }
    #C2 action issueSupervisoryCommand : SurveillanceDroneSwarm::OA::IssueSupervisoryCommand {
        doc /* the system's function that takes a supervisory command from the supervisor; traces to OA::IssueSupervisoryCommand */
        flow supervisoryCommandFlow of Common::SupervisoryCommand from cmdOut to cmdIn;
    }
    #C2 action recallToLand : SurveillanceDroneSwarm::OA::RecallToLand {
        doc /* the system's function that takes a recall order from the supervisor at any time; traces to OA::RecallToLand */
        flow recallFlow of Common::RecallOrder from cmdOut to cmdIn;
    }
    #C2 action presentStatusPicture : SurveillanceDroneSwarm::OA::PresentStatusPicture {
        doc /* the system's function that assembles and presents the status picture; traces to OA::PresentStatusPicture */
        flow statusPictureFlow of Common::StatusPicture from cmdOut to cmdIn;
    }
    #C2 action acknowledgeDetectionReport : SurveillanceDroneSwarm::OA::AcknowledgeDetectionReport {
        doc /* the system's function that takes the analyst's acknowledgement of a detection report; traces to OA::AcknowledgeDetectionReport */
        flow acknowledgementFlow of Common::ReportAcknowledgement from ackOut to ackIn;
    }

    // ===== Core watch, detect and report functions, each traced to its OA activity =====

    action watchSector : SurveillanceDroneSwarm::OA::WatchSector {
        doc /* the system's function that holds continuous watch over an assigned sector from altitude; traces to OA::WatchSector */
    }
    action detectAndClassify : SurveillanceDroneSwarm::OA::DetectAndClassify {
        doc /* the system's function that detects moving objects and classifies them well enough to say whether they matter, saying Unknown rather than forcing a class; traces to OA::DetectAndClassify */
    }
    action reportDetection : SurveillanceDroneSwarm::OA::ReportDetection {
        doc /* the system's function that carries one detection report to the operations centre; traces to OA::ReportDetection */
        flow detectionReportFlow of Common::DetectionReport from reportOut to reportIn;
    }
    action triageReports {
        doc /* the system's function that ranks and merges detection reports into a bounded alert stream for the operator and keeps a decision record for every report; traces to the OA capability ReportTriageAndDecisionRecord, which has no dedicated OA activity of its own */
        out port triagedAlertOut : Common::TriagedAlert {
            doc /* the triaged alert this function produces */
        }
        out port decisionRecordOut : Common::DecisionRecord {
            doc /* the decision record this function keeps for a report */
        }
    }

    // ===== Explicit traces from every SA function to the OA activity it realises (CV-03) =====
    // The ": OA::X" type ascription above shows specialisation but is not read as a trace by the
    // checker; every function is also traced explicitly here.

    trace watchSector to SurveillanceDroneSwarm::OA::WatchSector;
    trace detectAndClassify to SurveillanceDroneSwarm::OA::DetectAndClassify;
    trace reportDetection to SurveillanceDroneSwarm::OA::ReportDetection;
    trace triageReports to SurveillanceDroneSwarm::OA::ReportTriageAndDecisionRecord;
    trace handOverSector to SurveillanceDroneSwarm::OA::HandOverSector;
    trace rotateRecharge to SurveillanceDroneSwarm::OA::RotateRecharge;
    trace redistributeCoverage to SurveillanceDroneSwarm::OA::RedistributeCoverage;
    trace deconflictFlight to SurveillanceDroneSwarm::OA::DeconflictFlight;
    trace relayThroughNeighbour to SurveillanceDroneSwarm::OA::RelayThroughNeighbour;
    trace correlateTracks to SurveillanceDroneSwarm::OA::CorrelateTracks;
    trace handOverTrack to SurveillanceDroneSwarm::OA::HandOverTrack;
    trace admitMember to SurveillanceDroneSwarm::OA::AdmitMember;
    trace taskSurveillanceMission to SurveillanceDroneSwarm::OA::TaskSurveillanceMission;
    trace issueSupervisoryCommand to SurveillanceDroneSwarm::OA::IssueSupervisoryCommand;
    trace recallToLand to SurveillanceDroneSwarm::OA::RecallToLand;
    trace presentStatusPicture to SurveillanceDroneSwarm::OA::PresentStatusPicture;
    trace acknowledgeDetectionReport to SurveillanceDroneSwarm::OA::AcknowledgeDetectionReport;

    // ===== Allocation: every SA function is allocated to the system =====

    allocate handOverSector to surveillanceDroneSwarm;
    allocate rotateRecharge to surveillanceDroneSwarm;
    allocate redistributeCoverage to surveillanceDroneSwarm;
    allocate deconflictFlight to surveillanceDroneSwarm;
    allocate relayThroughNeighbour to surveillanceDroneSwarm;
    allocate correlateTracks to surveillanceDroneSwarm;
    allocate handOverTrack to surveillanceDroneSwarm;
    allocate admitMember to surveillanceDroneSwarm;
    allocate taskSurveillanceMission to surveillanceDroneSwarm;
    allocate issueSupervisoryCommand to surveillanceDroneSwarm;
    allocate recallToLand to surveillanceDroneSwarm;
    allocate presentStatusPicture to surveillanceDroneSwarm;
    allocate acknowledgeDetectionReport to surveillanceDroneSwarm;
    allocate watchSector to surveillanceDroneSwarm;
    allocate detectAndClassify to surveillanceDroneSwarm;
    allocate reportDetection to surveillanceDroneSwarm;
    allocate triageReports to surveillanceDroneSwarm;

    // ===== Capability traces: every SA capability traces to OA =====

    use case continuousAreaWatch : SurveillanceDroneSwarm::OA::ContinuousAreaWatch {
        doc /* traces to OA::ContinuousAreaWatch; realised by watchSector held across the fleet through rotateRecharge and redistributeCoverage */
    }
    use case detectionClassificationAndReporting : SurveillanceDroneSwarm::OA::DetectionClassificationAndReporting {
        doc /* traces to OA::DetectionClassificationAndReporting; realised by detectAndClassify and reportDetection */
    }
    use case swarmSelfCoordination : SurveillanceDroneSwarm::OA::SwarmSelfCoordination {
        doc /* traces to OA::SwarmSelfCoordination; realised by the eight #Coordination functions */
    }
    use case supervisedCommandAndControl : SurveillanceDroneSwarm::OA::SupervisedCommandAndControl {
        doc /* traces to OA::SupervisedCommandAndControl; realised by the five #C2 functions */
    }
    use case disconnectedOperationAndReconciliation : SurveillanceDroneSwarm::OA::DisconnectedOperationAndReconciliation {
        doc /* traces to OA::DisconnectedOperationAndReconciliation; realised by reportDetection holding reports across a ground-link gap and delivering them once restored */
    }
    use case reportTriageAndDecisionRecord : SurveillanceDroneSwarm::OA::ReportTriageAndDecisionRecord {
        doc /* traces to OA::ReportTriageAndDecisionRecord; realised by triageReports */
    }
    use case gracefulDegradation : SurveillanceDroneSwarm::OA::GracefulDegradation {
        doc /* traces to OA::GracefulDegradation; realised by redistributeCoverage and admitMember bounding coverage loss as members leave, rejoin or are lost */
    }
    use case airspaceComplianceAndSafeRecovery : SurveillanceDroneSwarm::OA::AirspaceComplianceAndSafeRecovery {
        doc /* traces to OA::AirspaceComplianceAndSafeRecovery; realised at this layer by the system's airspaceClearanceIn boundary and its recall/grounded modes, carried in detail by the member's rules at LA */
    }

    // ===== Hazards this layer adds: what the system as a whole can do wrong at its boundary =====

    package Hazards {
        doc /* boundary-level hazards named by the brief, stated once here at SA and satisfied by path below; never restated at LA or PA */

        #Hazard requirement PositionDriftHazard {
            subject sys : SurveillanceDroneSwarmSystem;
            doc /* without satellite positioning, a member's position estimate drifts and its reports place objects in the wrong place */
        }
        #Hazard requirement MeshJammingHazard {
            subject sys : SurveillanceDroneSwarmSystem;
            doc /* interference cuts the links between members, and coordination stalls */
        }
        #Hazard requirement MisclassificationHazard {
            subject sys : SurveillanceDroneSwarmSystem;
            doc /* a detection is reported as the wrong class, or a forced class where Unknown was the truth */
        }
        #Hazard requirement SensingDegradedUnnoticedHazard {
            subject sys : SurveillanceDroneSwarmSystem;
            doc /* a sensor degrades and nobody knows the reports from it are unreliable */
        }
        #Hazard requirement StaleTrackHazard {
            subject sys : SurveillanceDroneSwarmSystem;
            doc /* a track is shown as current after nothing has seen the object for a while */
        }
        #Hazard requirement SpoofedMemberHazard {
            subject sys : SurveillanceDroneSwarmSystem;
            doc /* something that is not one of the members joins the mesh and takes part in coordination */
        }
        #Hazard requirement MixedClassifierVersionsHazard {
            subject sys : SurveillanceDroneSwarmSystem;
            doc /* members run different classifier versions and classify the same object differently */
        }
        #Hazard requirement OperatorOverloadHazard {
            subject sys : SurveillanceDroneSwarmSystem;
            doc /* more alerts reach the operator than they can judge, and they accept what is in front of them */
        }
    }

    satisfy Hazards::PositionDriftHazard by surveillanceDroneSwarm;
    satisfy Hazards::MeshJammingHazard by relayThroughNeighbour;
    satisfy Hazards::MisclassificationHazard by detectAndClassify;
    satisfy Hazards::SensingDegradedUnnoticedHazard by presentStatusPicture;
    satisfy Hazards::StaleTrackHazard by correlateTracks;
    satisfy Hazards::SpoofedMemberHazard by admitMember;
    satisfy Hazards::MixedClassifierVersionsHazard by SurveillanceDroneSwarm::OA::classifierRelease;
    satisfy Hazards::OperatorOverloadHazard by triageReports;

    // ===== Rules the system never breaks (CV-18): stated once here, carried by SwarmOperatingMode above =====

    #Rule requirement RecallWins {
        subject sys : SurveillanceDroneSwarmSystem;
        doc /* RecallWins: once a drone is recalled, it does not watch again until it has landed */
    }
    #Rule requirement ReturnsWhenIsolated {
        subject sys : SurveillanceDroneSwarmSystem;
        doc /* ReturnsWhenIsolated: from any situation a drone can be in, it can always get back to landed, an isolated drone included */
    }
    #Rule requirement GeofenceBreachEndsWatch {
        subject sys : SurveillanceDroneSwarmSystem;
        doc /* GeofenceBreachEndsWatch: once a drone is outside its cleared airspace, it does not watch until it has landed */
    }
    #Rule requirement QuarantinedStaysOut {
        subject sys : SurveillanceDroneSwarmSystem;
        doc /* QuarantinedStaysOut: once a drone is quarantined, it takes no part in coordination until it has been readmitted */
    }

    // ===== Numeric budgets worth stating at the boundary (CV verification knob; non-blocking) =====

    require constraint operatorAlertBudget {
        doc /* the triaged alert stream reaching the operator must not exceed the operator's judged capacity of 20 alerts per hour, per OperatorAttention */
    }
    require constraint areaUnderWatchBudget {
        doc /* the share of the area of interest under watch at any moment must reach at least 0.9, the first measure an architecture is judged on */
    }
        // carried from the layer above; restored by the orchestrator
        allocate taskSurveillanceMission to watchAsset;
        allocate issueSupervisoryCommand to watchAsset;
        allocate recallToLand to watchAsset;
        allocate presentStatusPicture to watchAsset;
        allocate acknowledgeDetectionReport to watchAsset;
        allocate handOverSector to watchAsset;
        allocate rotateRecharge to watchAsset;
        allocate redistributeCoverage to watchAsset;
        allocate deconflictFlight to watchAsset;
        allocate relayThroughNeighbour to watchAsset;
        allocate correlateTracks to watchAsset;
        allocate handOverTrack to watchAsset;
        allocate admitMember to watchAsset;
        allocate handOverSector to system;
        trace handOverSector to SurveillanceDroneSwarm::OA::alphaHandOverSector;
        trace handOverSector to SurveillanceDroneSwarm::OA::bravoHandOverSector;
        allocate rotateRecharge to system;
        trace rotateRecharge to SurveillanceDroneSwarm::OA::alphaRotateRecharge;
        trace rotateRecharge to SurveillanceDroneSwarm::OA::bravoRotateRecharge;
        allocate redistributeCoverage to system;
        trace redistributeCoverage to SurveillanceDroneSwarm::OA::alphaRedistributeCoverage;
        trace redistributeCoverage to SurveillanceDroneSwarm::OA::bravoRedistributeCoverage;
        allocate deconflictFlight to system;
        trace deconflictFlight to SurveillanceDroneSwarm::OA::alphaDeconflictFlight;
        trace deconflictFlight to SurveillanceDroneSwarm::OA::bravoDeconflictFlight;
        allocate relayThroughNeighbour to system;
        trace relayThroughNeighbour to SurveillanceDroneSwarm::OA::alphaRelayThroughNeighbour;
        trace relayThroughNeighbour to SurveillanceDroneSwarm::OA::bravoRelayThroughNeighbour;
        allocate correlateTracks to system;
        trace correlateTracks to SurveillanceDroneSwarm::OA::alphaCorrelateTracks;
        trace correlateTracks to SurveillanceDroneSwarm::OA::bravoCorrelateTracks;
        allocate handOverTrack to system;
        trace handOverTrack to SurveillanceDroneSwarm::OA::alphaHandOverTrack;
        trace handOverTrack to SurveillanceDroneSwarm::OA::bravoHandOverTrack;
        allocate admitMember to system;
        trace admitMember to SurveillanceDroneSwarm::OA::alphaAdmitMember;
        trace admitMember to SurveillanceDroneSwarm::OA::bravoAdmitMember;
        allocate taskSurveillanceMission to system;
        trace taskSurveillanceMission to SurveillanceDroneSwarm::OA::alphaTaskSurveillanceMission;
        trace taskSurveillanceMission to SurveillanceDroneSwarm::OA::bravoTaskSurveillanceMission;
        allocate issueSupervisoryCommand to system;
        trace issueSupervisoryCommand to SurveillanceDroneSwarm::OA::alphaIssueSupervisoryCommand;
        trace issueSupervisoryCommand to SurveillanceDroneSwarm::OA::bravoIssueSupervisoryCommand;
        allocate recallToLand to system;
        trace recallToLand to SurveillanceDroneSwarm::OA::alphaRecallToLand;
        trace recallToLand to SurveillanceDroneSwarm::OA::bravoRecallToLand;
        allocate presentStatusPicture to system;
        trace presentStatusPicture to SurveillanceDroneSwarm::OA::alphaPresentStatusPicture;
        trace presentStatusPicture to SurveillanceDroneSwarm::OA::bravoPresentStatusPicture;
        allocate acknowledgeDetectionReport to system;
        trace acknowledgeDetectionReport to SurveillanceDroneSwarm::OA::alphaAcknowledgeDetectionReport;
        trace acknowledgeDetectionReport to SurveillanceDroneSwarm::OA::bravoAcknowledgeDetectionReport;
    }
