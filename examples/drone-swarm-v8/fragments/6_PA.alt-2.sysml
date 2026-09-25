    package PA {
        #prompt part paGuidance {
            doc /* PA: the components that will be built. Behaviour parts are hosted in node parts by nesting, physical links are typed, item definitions carry units, and resource budgets are require constraints. */
        }

        // the system, to be decomposed into physical components
        part def SurveillanceDroneSwarmPhysical {
            in port taskingIn : LA::SurveillanceDrone::taskingIn;
            in port commandIn : LA::SurveillanceDrone::commandIn;
            in port recallIn : LA::SurveillanceDrone::recallIn;
            out port detectionReportOut : LA::SurveillanceDrone::detectionReportOut;
            out port trackOut : LA::SurveillanceDrone::trackOut;
            doc /* TODO: decompose into components and move the functions onto them. */
        }

        // the population: 12 identical members (CV-16)
        #prose part fleetFact {
            doc /* Population: 12 members of SurveillanceDrone, carried by fleet, exchanging through Common::MeshLink. Carried from the brief; the architecture instantiates it. */
        }

        // actors, carried over unchanged
        #Actor part def SwarmSupervisor {
            doc /* TODO: check this actor's interface against LA. */
        }
        part swarmSupervisor : SwarmSupervisor;
        trace swarmSupervisor to SurveillanceDroneSwarm::LA::swarmSupervisor;
        #Actor part def OperationsCentreAnalyst {
            doc /* TODO: check this actor's interface against LA. */
        }
        part opsCentreAnalyst : OperationsCentreAnalyst;
        trace opsCentreAnalyst to SurveillanceDroneSwarm::LA::opsCentreAnalyst;
        #Actor part def AirspaceAuthority {
            doc /* TODO: check this actor's interface against LA. */
        }
        part airspaceAuthority : AirspaceAuthority;
        trace airspaceAuthority to SurveillanceDroneSwarm::LA::airspaceAuthority;
        #Actor part def OperatingEnvironment {
            doc /* TODO: check this actor's interface against LA. */
        }
        part operatingEnvironment : OperatingEnvironment;
        trace operatingEnvironment to SurveillanceDroneSwarm::LA::operatingEnvironment;

        // functions, carried over from LA: every one of them has to be realised here
        action def HandOverSector {
            doc /* TODO: how `handOverSector` is realised at PA. */
            out reqOut : Common::SectorAssignment;
            in reqIn : Common::SectorAssignment;
        }
        action def RotateRecharge {
            doc /* TODO: how `rotateRecharge` is realised at PA. */
            out reqOut : Common::RechargeRotationPlan;
            in reqIn : Common::RechargeRotationPlan;
        }
        action def RedistributeCoverage {
            doc /* TODO: how `redistributeCoverage` is realised at PA. */
            out reqOut : Common::CoverageRedistributionPlan;
            in reqIn : Common::CoverageRedistributionPlan;
        }
        action def DeconflictFlight {
            doc /* TODO: how `deconflictFlight` is realised at PA. */
            out reqOut : Common::DeconflictionAdvisory;
            in reqIn : Common::DeconflictionAdvisory;
        }
        action def RelayThroughNeighbour {
            doc /* TODO: how `relayThroughNeighbour` is realised at PA. */
            out reqOut : Common::RelayedMessage;
            in reqIn : Common::RelayedMessage;
        }
        action def CorrelateTracks {
            doc /* TODO: how `correlateTracks` is realised at PA. */
            out reqOut : Common::Track;
            in reqIn : Common::Track;
        }
        action def HandOverTrack {
            doc /* TODO: how `handOverTrack` is realised at PA. */
            out reqOut : Common::Track;
            in reqIn : Common::Track;
        }
        action def AdmitMember {
            doc /* TODO: how `admitMember` is realised at PA. */
            out admitReqOut : Common::MembershipRequest;
            in admitReqIn : Common::MembershipRequest;
            out admitDecOut : Common::MembershipDecision;
            in admitDecIn : Common::MembershipDecision;
        }
        action def TaskSurveillanceMission {
            doc /* TODO: how `taskSurveillanceMission` is realised at PA. */
            out cmdOut : Common::MissionTasking;
            in cmdIn : Common::MissionTasking;
        }
        action def IssueSupervisoryCommand {
            doc /* TODO: how `issueSupervisoryCommand` is realised at PA. */
            out cmdOut : Common::SupervisoryCommand;
            in cmdIn : Common::SupervisoryCommand;
        }
        action def RecallToLand {
            doc /* TODO: how `recallToLand` is realised at PA. */
            out cmdOut : Common::RecallOrder;
            in cmdIn : Common::RecallOrder;
        }
        action def PresentStatusPicture {
            doc /* TODO: how `presentStatusPicture` is realised at PA. */
            out cmdOut : Common::StatusPicture;
            in cmdIn : Common::StatusPicture;
        }
        action def AcknowledgeDetectionReport {
            doc /* TODO: how `acknowledgeDetectionReport` is realised at PA. */
            out ackOut : Common::ReportAcknowledgement;
            in ackIn : Common::ReportAcknowledgement;
        }
        action def WatchSector {
            doc /* TODO: how `watchSector` is realised at PA. */
        }
        action def DetectAndClassify {
            doc /* TODO: how `detectAndClassify` is realised at PA. */
        }
        action def ReportDetection {
            doc /* TODO: how `reportDetection` is realised at PA. */
            out reportOut : Common::DetectionReport;
            in reportIn : Common::DetectionReport;
        }
        action def TriageReportsDefinition {
            doc /* TODO: how `triageReports` is realised at PA. */
        }
        #Coordination action handOverSector : HandOverSector;
        trace handOverSector to SurveillanceDroneSwarm::LA::handOverSector;
        #Coordination action rotateRecharge : RotateRecharge;
        trace rotateRecharge to SurveillanceDroneSwarm::LA::rotateRecharge;
        #Coordination action redistributeCoverage : RedistributeCoverage;
        trace redistributeCoverage to SurveillanceDroneSwarm::LA::redistributeCoverage;
        #Coordination action deconflictFlight : DeconflictFlight;
        trace deconflictFlight to SurveillanceDroneSwarm::LA::deconflictFlight;
        #Coordination action relayThroughNeighbour : RelayThroughNeighbour;
        trace relayThroughNeighbour to SurveillanceDroneSwarm::LA::relayThroughNeighbour;
        #Coordination action correlateTracks : CorrelateTracks;
        trace correlateTracks to SurveillanceDroneSwarm::LA::correlateTracks;
        #Coordination action handOverTrack : HandOverTrack;
        trace handOverTrack to SurveillanceDroneSwarm::LA::handOverTrack;
        #Coordination action admitMember : AdmitMember;
        trace admitMember to SurveillanceDroneSwarm::LA::admitMember;
        #C2 action taskSurveillanceMission : TaskSurveillanceMission;
        trace taskSurveillanceMission to SurveillanceDroneSwarm::LA::taskSurveillanceMission;
        #C2 action issueSupervisoryCommand : IssueSupervisoryCommand;
        trace issueSupervisoryCommand to SurveillanceDroneSwarm::LA::issueSupervisoryCommand;
        #C2 action recallToLand : RecallToLand;
        trace recallToLand to SurveillanceDroneSwarm::LA::recallToLand;
        #C2 action presentStatusPicture : PresentStatusPicture;
        trace presentStatusPicture to SurveillanceDroneSwarm::LA::presentStatusPicture;
        #C2 action acknowledgeDetectionReport : AcknowledgeDetectionReport;
        trace acknowledgeDetectionReport to SurveillanceDroneSwarm::LA::acknowledgeDetectionReport;
        action watchSector : WatchSector;
        trace watchSector to SurveillanceDroneSwarm::LA::watchSector;
        action detectAndClassify : DetectAndClassify;
        trace detectAndClassify to SurveillanceDroneSwarm::LA::detectAndClassify;
        action reportDetection : ReportDetection;
        trace reportDetection to SurveillanceDroneSwarm::LA::reportDetection;
        action triageReports : TriageReportsDefinition {
            out triagedAlertOut : Common::TriagedAlert;
            out decisionRecordOut : Common::DecisionRecord;
        }
        trace triageReports to SurveillanceDroneSwarm::LA::triageReports;

        // ── architecture, alternative 2 ──
        // ===== Function allocation: the architecture decision (CV-16), written first as required =====
        // 17 functions, each allocated at least once; recallToLand also reaches every member directly.
        allocate handOverSector to fleet;
        allocate rotateRecharge to memberA;
        allocate redistributeCoverage to memberA;
        allocate deconflictFlight to fleet;
        allocate relayThroughNeighbour to fleet;
        allocate correlateTracks to memberA;
        allocate handOverTrack to memberB;
        allocate admitMember to memberA;
        allocate taskSurveillanceMission to groundStation;
        allocate issueSupervisoryCommand to groundStation;
        allocate recallToLand to groundStation;
        allocate recallToLand to fleet;
        allocate presentStatusPicture to groundStation;
        allocate acknowledgeDetectionReport to groundStation;
        allocate watchSector to fleet;
        allocate detectAndClassify to fleet;
        allocate reportDetection to fleet;
        allocate triageReports to groundStation;
        doc /* Physical Architecture, alternative 2 of 2 (distributed / drone-centric). Ground-facing tasking, supervisory command, recall, status and acknowledgement each keep a usage on the ground, as every alternative must, but all eight member-to-member coordination functions run on a member or the fleet: what every member does for itself is allocated to the fleet, and what one member decides for the others is allocated to an elected/rotating onboard representative rather than to the ground. This is the opposite boundary from a ground-centred alternative 1. Each member's own safety-rule enforcement lives in a dedicated onboard SafetyMonitor, kept apart from the behaviour part that detects, classifies and decides what to report, so a fault in that behaviour cannot itself defeat a checked rule. */

        // ===== Physical connection media (typed links, CV-16 / CV-05) =====
        connection def RFMeshLink {
            doc /* The physical RF medium that types the mesh link between two representative drones; carried in hardware by each drone's onboard MeshRadioUnit #Node part, never modelled as an actor. */
        }
        connection def RFGroundLink {
            doc /* The physical RF medium that types the ground-station link between the currently elected coordinator drone and the ground station; not always available. */
        }
        // ===== Physical node part definitions =====
        #Node part def MeshRadioUnit {
            doc /* The physical mesh radio hardware nested inside every member; the tangible bearer of the RFMeshLink connection between representatives. A hardware fault here removes a member's coordination bearer even without interference. */
        }
        #Node part def GroundRadioUnit {
            doc /* The physical ground-link radio hardware, nested in every member (any member may be elected coordinator) and in the ground station node; the tangible bearer of the RFGroundLink connection. */
            out port linkOut : Common::GroundLinkPort;
            in port linkIn : ~Common::GroundLinkPort;
        }
        // ===== State machines (modes/states option) =====
        #Mode state def DroneMode {
            doc /* Operational mode machine for one swarm member. The checked safety rules below are driven by this member's dedicated SafetyMonitor component, not by the behaviour part that detects, classifies and reports, so that logic overrides continued mission activity whenever a rule requires it. */

            initial start;
            state Nominal {
                doc /* Normal watch/patrol mode: behaviour freely runs detect, classify, report, and this member's share of onboard coordination. */
            }
            state NavigationDegraded {
                doc /* GNSS lost or degraded; navigating on stored maps and camera odometry, per the brief's navigation-degraded mode. */
            }
            state SensingDegraded {
                doc /* Onboard sensor confidence below threshold; still airborne but classification quality reduced. */
            }
            state Isolated {
                doc /* Mesh contact with every peer lost; autonomously heading for the physical recovery point. */
            }
            state Quarantined {
                doc /* Held out of the mesh after a spoofing or classifier-version-mismatch suspicion, pending re-vetting by the elected coordinator. */
            }
            state ReAdmitted {
                doc /* Re-vetted by the coordinator's admitMember decision and cleared to resume normal mesh participation. */
            }
            state Recalled {
                doc /* A recall order has been accepted; mission watch must not resume until landed (RecallWins). */
            }
            state GeofenceBreached {
                doc /* Outside the authorised area of interest; watch must not resume until landed (GeofenceBreachEndsWatch). */
            }
            state Landed {
                doc /* Safely on the ground, whether after a recall, a geofence breach, or a scheduled rotation. */
            }
            state AtRecoveryPoint {
                doc /* Docked at the physical recovery point; the state ReturnsWhenIsolated guarantees is always reachable again. */
            }

            transition start -> Nominal;
            transition Nominal -> NavigationDegraded;
            transition NavigationDegraded -> Nominal;
            transition Nominal -> SensingDegraded;
            transition SensingDegraded -> Nominal;
            transition Nominal -> Isolated;
            transition Isolated -> AtRecoveryPoint;
            transition AtRecoveryPoint -> Nominal;
            transition Nominal -> Quarantined;
            transition Quarantined -> ReAdmitted;
            transition ReAdmitted -> Nominal;
            transition Nominal -> Recalled;
            transition Recalled -> Landed;
            transition Landed -> Nominal;
            transition Nominal -> GeofenceBreached;
            transition GeofenceBreached -> Landed;

            @SysproseVerification::PropertyPattern {
                doc /* RecallWins: once a recall order is accepted until the member has landed, it must not resume Nominal watch activity. */
                attribute pattern = "absence";
                attribute scope = "between";
                attribute q = "state Recalled";
                attribute r = "state Landed";
                attribute p = "state Nominal";
            }
            @SysproseVerification::PropertyPattern {
                doc /* ReturnsWhenIsolated: whatever else happens to a member, it can always get back to its physical recovery point. */
                attribute pattern = "recovery";
                attribute scope = "globally";
                attribute p = "state AtRecoveryPoint";
            }
            @SysproseVerification::PropertyPattern {
                doc /* GeofenceBreachEndsWatch: once outside the authorised area until landed, the member must not resume Nominal watch. */
                attribute pattern = "absence";
                attribute scope = "between";
                attribute q = "state GeofenceBreached";
                attribute r = "state Landed";
                attribute p = "state Nominal";
            }
            @SysproseVerification::PropertyPattern {
                doc /* QuarantinedStaysOut: once quarantined until formally re-admitted, the member must not resume Nominal watch. */
                attribute pattern = "absence";
                attribute scope = "between";
                attribute q = "state Quarantined";
                attribute r = "state ReAdmitted";
                attribute p = "state Nominal";
            }
        }
        #State state def DroneState {
            doc /* Power/health state machine for a member's onboard compute and radios, distinct from its operational DroneMode machine above. */
            initial start;
            state PoweredOff {
                doc /* Airframe unpowered, on the ground. */
            }
            state SelfTest {
                doc /* Boot-time self-test of compute, radios and sensors. */
            }
            state Active {
                doc /* Compute and radios powered and healthy. */
            }
            state Fault {
                doc /* A detected hardware fault in compute or radio; grounds for recall. */
            }
            transition start -> PoweredOff;
            transition PoweredOff -> SelfTest;
            transition SelfTest -> Active;
            transition Active -> Fault;
            transition Fault -> SelfTest;
            transition Active -> PoweredOff;
        }
        #Configuration state def FleetConfiguration {
            doc /* Fleet-level mesh-configuration modes, independent of each member's own DroneMode/DroneState machines. */
            initial start;
            state FullMesh {
                doc /* Every member reaches every other member over the mesh. */
            }
            state MeshDegraded {
                doc /* Some peer links are jammed or lost; coordination continues over the remaining links and via relay. */
            }
            state MeshPartitioned {
                doc /* The mesh has split into disjoint groups; each group elects its own coordinator until reunited. */
            }
            transition start -> FullMesh;
            transition FullMesh -> MeshDegraded;
            transition MeshDegraded -> FullMesh;
            transition MeshDegraded -> MeshPartitioned;
            transition MeshPartitioned -> MeshDegraded;
        }
        // ===== Onboard safety monitor: enforces the rules, separate from the behaviour that decides what to report =====
        part def SafetyMonitor {
            doc /* Independent onboard component that drives DroneMode's transitions and overrides the behaviour part's detect/classify/report/coordinate activity whenever RecallWins, ReturnsWhenIsolated, GeofenceBreachEndsWatch or QuarantinedStaysOut requires it. Kept apart from the behaviour part so a fault in classification or reporting logic cannot itself defeat a rule it is supposed to obey. */
        }
        // ===== The population's replicable element (CV-16) =====
        #Member part def SurveillanceDrone {
            doc /* The replicable element every one of the twelve drones is. Nests the LA-defined member behaviour (detect, classify, report, and its share of coordination) plus its own mesh and ground radios and its own safety monitor. A coordinator is elected among members by coordinatorElectionPolicy (default: the member with the most remaining flight time takes the ground-link and cross-sector deciding role) and is replaced by the same policy whenever it recalls, rotates for recharge, or drops off the mesh; any member can hold the role because every member carries identical radio hardware. If the ground link drops, members keep flying their assigned sectors and negotiating handOverSector/deconflictFlight/relayThroughNeighbour over the mesh alone, buffering reports until the link returns (see reportHoldDurationMinutes). If the ground station itself fails, the swarm keeps flying and self-coordinating the same way — no ground component holds a coordination assignment the members cannot rebuild — until an operator restores or replaces the ground node. */

            out port meshOut : Common::MeshPeerPort;
            in port meshIn : ~Common::MeshPeerPort;

            part behaviour : SurveillanceDroneSwarm::LA::SurveillanceDrone {
                doc /* Hosts the LA-defined member behaviour (detect, classify, report, share of coordination) by nesting, inside this physical member. */
            }
            part meshRadio : MeshRadioUnit {
                doc /* This member's mesh radio hardware. */
            }
            part groundRadio : GroundRadioUnit {
                doc /* This member's ground-link radio hardware, used only while this member holds the elected coordinator role. */
            }
            part safetyMonitor : SafetyMonitor {
                doc /* This member's independent rule-enforcing monitor. */
            }

            state mode : DroneMode;
            state health : DroneState;

            #Variant attribute coordinatorElectionPolicy : String = "rotating-by-remaining-flight-time" {
                doc /* Design option: how the onboard coordinator role is (re)elected among members. Alternative 2 could equally choose a fixed-seniority or bid-based policy without changing the rest of the architecture; tagged as a variation point. */
            }
        }
        // ===== Ground station node =====
        #Node part def GroundControlStation {
            doc /* The fixed ground station. Directly hosts the ground-facing realization of every #C2 function; retains a usage of every #C2 function in both alternatives, and carries its own ground-link radio. */
            part groundRadio : GroundRadioUnit {
                doc /* The ground station's own ground-link radio. */
            }
        }
        #Node part def RecoveryPointNode {
            doc /* The physical recovery point a drone returns to autonomously once isolated from the swarm, realizing the state AtRecoveryPoint the ReturnsWhenIsolated rule guarantees is always reachable. */
        }
        #Node part def RechargeBay {
            doc /* The ground point and crew where a battery pack is swapped rather than charged in place, giving the fixed 20-minute turnaround; the swap contacts wear with repeated cycles. */
            part battery : Common::BatteryPack {
                doc /* The battery pack swapped at this bay. */
            }
        }
        // ===== The population, surviving into the physical architecture (CV-16) =====
        part fleet : SurveillanceDrone [12] {
            doc /* The physical population: twelve identical members, never collapsed to one instance. */
            state configuration : FleetConfiguration;
        }
        part memberA : SurveillanceDrone {
            doc /* Representative member A: currently the elected onboard coordinator and the swarm's ground-link gateway. */
        }
        part memberB : SurveillanceDrone {
            doc /* Representative member B: an ordinary peer, exhibited to carry the mesh link to memberA. */
        }
        connection meshPeerLink : RFMeshLink connect memberA.meshOut to memberB.meshIn {
            doc /* The link between two members of the population: a connection between two representatives, typed at PA by the connection def of the medium (RFMeshLink) that carries member-to-member coordination traffic. */
        }
        part groundStation : GroundControlStation {
            doc /* The single physical ground station. */
        }
        part recoveryPoint : RecoveryPointNode {
            doc /* The physical recovery point, reachable independently of the mesh or ground link. */
        }
        part rechargeBay : RechargeBay {
            doc /* The physical recharge bay serving the fleet's rotation. */
        }
        connection groundLink : RFGroundLink connect memberA.groundRadio.linkOut to groundStation.groundRadio.linkIn {
            doc /* The physical ground-station link, carried by whichever member currently holds the elected coordinator role rather than by every member at once; this architecture's own choice of where the ground-facing gateway sits. */
        }
        // ===== Resource budgets restated as local valued attributes and require constraints (CV-17) =====
        part def PhysicalBudgets {
            doc /* Restates the brief's fixed fleet-and-endurance numbers as valued attributes of this layer, because a constraint body cannot reach Common; used below to derive the population-share estimates and to state resource budgets as require constraints. */

            attribute flightDuration : ISQ::DurationValue = 2400 [s] {
                doc /* The fixed 40-minute (2400 s) flight endurance per sortie. */
            }
            attribute turnaroundDuration : ISQ::DurationValue = 1200 [s] {
                doc /* The fixed 20-minute (1200 s) battery-swap turnaround. */
            }
            attribute fleetCount : Real = 12 {
                doc /* The fixed twelve drones. */
            }
            attribute sensorFootprintAreaSqm : Real = 3000000 {
                doc /* About 3.0 km^2 (3,000,000 m^2) watched from altitude by one drone; unit dropped to a plain number since km^2 is not a library token, kept here in the doc. */
            }
            attribute areaOfInterestSqm : Real = 25000000 {
                doc /* Up to 25 km^2 (25,000,000 m^2) area of interest, fixed by the brief; unit dropped here for the same reason. */
            }

            require constraint FlightEnduranceBudget {
                doc /* The airframe/battery design must deliver at least the fixed flight endurance the coverage arithmetic depends on. */
                flightDuration >= 2400 [s]
            }
            require constraint GroundTurnaroundBudget {
                doc /* The recharge bay's battery-swap turnaround must not exceed the fixed 20-minute budget the airborne-share arithmetic depends on. */
                turnaroundDuration <= 1200 [s]
            }
            require constraint SensorFootprintBudget {
                doc /* Each member's sensor at watch altitude must cover at least the fixed footprint the coverage arithmetic depends on. */
                sensorFootprintAreaSqm >= 3000000
            }
        }
        part physicalBudgets : PhysicalBudgets {
            doc /* This architecture's instance of the physical budgets. */
        }
        // ===== Worst-case estimates of the measures of effectiveness (CV-17) =====
        part def AlternativeTwoEstimates {
            doc /* Alternative 2's worst-case estimate for each measure of effectiveness, with its basis; the population-share measures are derived from physicalBudgets rather than stated as a literal, per the checked case. */

            #Estimate attribute areaUnderWatchFraction :> Common::areaUnderWatchFraction {
                doc /* Left without a literal: derived below, because a share held "at any moment" cannot exceed what the fleet's airborne share and per-member footprint actually tile over the area of interest. */
            }
            #Estimate attribute coverageUnderMeshJammingFraction :> Common::coverageUnderMeshJammingFraction {
                doc /* Left without a literal: derived below from areaUnderWatchFraction and the onboard-coordination resilience factor. */
            }
            #Estimate attribute watchEnduranceHoursWithoutPeople :> Common::watchEnduranceHoursWithoutPeople = 12 {
                doc /* Basis: the fixed 40/20-minute duty cycle rotates through all twelve members indefinitely without operator intervention as long as the recharge bay and classifier release stay constant. */
            }
            #Estimate attribute reportDeliveryLatencySeconds :> Common::reportDeliveryLatencySeconds = 45 {
                doc /* Basis: onboard correlation at the elected coordinator plus one mesh relay hop before the ground link adds latency against a direct per-drone ground link; worst case 45 s, inside the 60 s target. */
            }
            #Estimate attribute positionErrorAfterGnssLossMetres :> Common::positionErrorAfterGnssLossMetres = 45 {
                doc /* Basis: camera navigation against stored maps over the fixed 10-minute GNSS outage budget; a navigation figure this architecture's coordination choice does not change. */
            }
            #Estimate attribute reportHoldDurationMinutes :> Common::reportHoldDurationMinutes = 35 {
                doc /* Basis: the elected coordinator's onboard store holds reports through a ground-link gap and reconciles once the link returns; worst case 35 min, above the 30 min target. */
            }
            #Estimate attribute missedDetectionFraction :> Common::missedDetectionFraction = 0.08 {
                doc /* Basis: classifier performance at the reporting threshold in force; an architecture-neutral figure carried from LA. */
            }
            #Estimate attribute falseAlarmsPerHour :> Common::falseAlarmsPerHour = 1.5 {
                doc /* Basis: classifier performance at the reporting threshold in force; an architecture-neutral figure carried from LA. */
            }
            #Estimate attribute alertsReachingOperatorPerHour :> Common::alertsReachingOperatorPerHour = 18 {
                doc /* Basis: onboard triage and duplicate-merge ahead of the ground console keep the operator within the fixed 20-per-hour capacity. */
            }
            #Estimate attribute acknowledgedReportsThatMatterFraction :> Common::acknowledgedReportsThatMatterFraction = 0.82 {
                doc /* Basis: triage ranking at the ground console surfaces what matters first; worst case 0.82, above the 0.8 target. */
            }
            #Estimate attribute coverageDropAfterMemberLossFraction :> Common::coverageDropAfterMemberLossFraction = 0.20 {
                doc /* Basis: redistributeCoverage is decided onboard by the elected coordinator without waiting on the ground link, so re-spreading after a loss is faster than a ground-decided scheme; worst case 0.20, inside the 0.25 target. */
            }
            #Estimate attribute onboardClassifierCostUsdPerDrone :> Common::onboardClassifierCostUsdPerDrone = 280 {
                doc /* Basis: the onboard compute board priced for the chosen classifier release; worst case 280 USD per drone, inside the 300 USD target. */
            }

            attribute meshJammingResilienceFactor : Real = 0.85 {
                doc /* The share of areaUnderWatchFraction this architecture retains with half the mesh links jammed, because coordination is carried by the elected onboard representative and by every member's own deconfliction/relay behaviour rather than solely over the ground link; a valued attribute of this layer, not a claim on Common. */
            }

            assert constraint {
                doc /* Derivation: areaUnderWatchFraction cannot exceed what the fleet's airborne share and each member's footprint actually tile over the area of interest. */
                areaUnderWatchFraction == (physicalBudgets.fleetCount * (physicalBudgets.flightDuration / (physicalBudgets.flightDuration + physicalBudgets.turnaroundDuration)) * physicalBudgets.sensorFootprintAreaSqm) / physicalBudgets.areaOfInterestSqm
            }
            assert constraint {
                doc /* Mesh-jamming coverage derives from the same watch share, discounted by the onboard-coordination resilience factor above. */
                coverageUnderMeshJammingFraction == areaUnderWatchFraction * meshJammingResilienceFactor
            }
        }
        part alternativeTwoEstimates : AlternativeTwoEstimates {
            doc /* This architecture's instance of the estimates above. */
        }
        // ===== Hazards this layer adds (safety option) =====
        package Hazards {
            doc /* Hazards introduced by alternative 2's own physical and organisational choices: concentrating coordination on one elected onboard node and the mesh radio hardware itself. Neither restates a hazard named above. */

            #Hazard requirement LeaderNodeLossHazard {
                doc /* Concentrating coordination on one elected representative means losing that specific airframe stalls handOverSector, rotateRecharge, redistributeCoverage, correlateTracks, handOverTrack and admitMember until another member is elected. */
            }
            #Hazard requirement MeshRadioHardwareFailureHazard {
                doc /* The physical mesh radio unit can fail from a hardware fault or wear rather than from interference, silently removing a member's coordination bearer even when radio interference is not present. */
            }
            #Hazard #Accepted requirement BatteryContactWearHazard {
                doc /* Accepted: the battery-swap contacts at the recharge bay wear with repeated mating cycles. Mitigated by scheduled ground-crew visual inspection at every swap, outside the software boundary the rest of this architecture addresses. */
            }
        }
        satisfy Hazards::LeaderNodeLossHazard by memberA;
        satisfy Hazards::MeshRadioHardwareFailureHazard by fleet;
        // ===== Brief hazards (SA/LA), satisfied here by this alternative's own physical components =====
        satisfy SA::Hazards::PositionDriftHazard by fleet;
        satisfy SA::Hazards::MeshJammingHazard by fleet;
        satisfy SA::Hazards::MisclassificationHazard by fleet;
        satisfy SA::Hazards::SensingDegradedUnnoticedHazard by fleet;
        satisfy SA::Hazards::StaleTrackHazard by memberA;
        satisfy SA::Hazards::SpoofedMemberHazard by memberA;
        satisfy SA::Hazards::MixedClassifierVersionsHazard by memberA;
        satisfy SA::Hazards::OperatorOverloadHazard by groundStation;
        satisfy LA::Hazards::PeerCoordinationSinglePointHazard by fleet;
        satisfy LA::Hazards::CoordinationDivergenceHazard by memberA;
    }
