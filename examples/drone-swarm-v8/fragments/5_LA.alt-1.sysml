    package LA {
        #prompt part laGuidance {
            doc /* LA: decompose the system into logical components. Every logical function traces to a system function; components exchange through ports; nothing physical is decided yet. */
        }

        // The system, one placeholder box at this step. Decomposing it into distinct logical
        // sub-components is the next step's job, done several ways and compared; every function
        // below therefore stays allocated to this single component, as the skeleton requires.
        part def SurveillanceDroneSwarmLogical {
            in port missionTaskingIn : SA::SurveillanceDroneSwarmSystem::missionTaskingIn;
            in port supervisoryCommandIn : SA::SurveillanceDroneSwarmSystem::supervisoryCommandIn;
            in port recallOrderIn : SA::SurveillanceDroneSwarmSystem::recallOrderIn;
            out port statusPictureOut : SA::SurveillanceDroneSwarmSystem::statusPictureOut;
            in port reportAcknowledgementIn : SA::SurveillanceDroneSwarmSystem::reportAcknowledgementIn;
            out port detectionReportsOut : SA::SurveillanceDroneSwarmSystem::detectionReportsOut;
            out port correlatedTracksOut : SA::SurveillanceDroneSwarmSystem::correlatedTracksOut;
            out port triagedAlertStreamOut : SA::SurveillanceDroneSwarmSystem::triagedAlertStreamOut;
            out port decisionRecordOut : SA::SurveillanceDroneSwarmSystem::decisionRecordOut;
            in port airspaceClearanceIn : SA::SurveillanceDroneSwarmSystem::airspaceClearanceIn;
            in port movingObjectsInAreaIn : SA::SurveillanceDroneSwarmSystem::movingObjectsInAreaIn;
            in port sceneConditionsIn : SA::SurveillanceDroneSwarmSystem::sceneConditionsIn;
            in port radioInterferenceIn : SA::SurveillanceDroneSwarmSystem::radioInterferenceIn;
            in port satellitePositioningOutageIn : SA::SurveillanceDroneSwarmSystem::satellitePositioningOutageIn;
            in port weatherLimitIn : SA::SurveillanceDroneSwarmSystem::weatherLimitIn;
            ref mode : SurveillanceDroneSwarm::SA::SwarmOperatingMode;
            ref availability : SurveillanceDroneSwarm::SA::SwarmAvailabilityState;
            doc /* the SurveillanceDroneSwarm as one logical box: every SA boundary port carried through unchanged, plus a reference to the system-level mode and availability state defined at SA. All logical functions below are allocated here; splitting this box into named logical components is deferred to the next step. */
        }

        // ---- architecture decision (CV-16): where #Coordination and #C2 are allocated ----
        #Variant #prose part coordinationAllocationDecision {
            doc /* architecture decision: the intent is that the eight #Coordination functions (handOverSector, rotateRecharge, redistributeCoverage, deconflictFlight, relayThroughNeighbour, correlateTracks, handOverTrack, admitMember) end up onboard -- on the fleet and its members -- so mesh self-coordination survives independently of the ground-station link, per MeshRadio and SwarmSelfCoordination; and that the five #C2 functions (taskSurveillanceMission, issueSupervisoryCommand, recallToLand, presentStatusPicture, acknowledgeDetectionReport) stay ground-facing only, because they are exercised by SwarmSupervisor and OperationsCentreAnalyst, and SafetyAuthority requires recall/geofence authority to stay independent of onboard software. At this step, before logical components are chosen, this dialect's functions-only rule keeps all thirteen allocated to mainComponent, the single placeholder box; the onboard/ground split above becomes a real allocation once components are decomposed in the next step. This is one candidate variant; a ground-held-coordinator variant is the alternative compared at trade time. */
        }

        // ---- the population (CV-16): definition carried forward; instantiation deferred to the next step ----
        #Mode state def MemberMode {
            doc /* each member's own operating mode: watching its sector, degraded in some named way, recalled, quarantined, or grounded. Carries the brief-named member modes and the rules RecallWins, ReturnsWhenIsolated, GeofenceBreachEndsWatch and QuarantinedStaysOut. */
            initial start;
            state Watching {
                doc /* holding watch over the member's assigned sector. */
            }
            state NavigationDegraded {
                doc /* the brief's member mode: no satellite positioning; navigates by camera against stored maps. */
            }
            state SensingDegraded {
                doc /* the brief's member mode: this member's sensors cannot be trusted as they are. */
            }
            state Isolated {
                doc /* the brief's member mode: cut off from the other members. */
            }
            state Quarantined {
                doc /* the brief's member mode: failed admission, takes no part in coordination until readmitted. */
            }
            state AirspaceBreach {
                doc /* outside the cleared volume or window issued by the airspace authority; watch does not resume until landed. */
            }
            state Recalled {
                doc /* returning to land following a recall order. */
            }
            state Grounded {
                doc /* landed: whether recalled, quarantined, in airspace breach, or awaiting clearance. */
            }
            transition start -> Watching;
            transition Watching -> NavigationDegraded;
            transition NavigationDegraded -> Watching;
            transition Watching -> SensingDegraded;
            transition SensingDegraded -> Watching;
            transition Watching -> Isolated;
            transition Isolated -> Watching;
            transition Isolated -> Recalled;
            transition Isolated -> Grounded;
            transition Watching -> AirspaceBreach;
            transition AirspaceBreach -> Grounded;
            transition Watching -> Recalled;
            transition Recalled -> Grounded;
            transition Watching -> Quarantined;
            transition Quarantined -> Grounded;
            transition Grounded -> Watching;

            @SysproseVerification::PropertyPattern {
                doc /* RecallWins: once a drone is recalled, it does not watch again until it has landed. */
                attribute pattern = "absence";
                attribute scope = "between";
                attribute q = "state Recalled";
                attribute r = "state Grounded";
                attribute p = "state Watching";
            }
            @SysproseVerification::PropertyPattern {
                doc /* ReturnsWhenIsolated: from any situation a drone can be in, it can always get back to landed; an isolated drone included. */
                attribute pattern = "recovery";
                attribute scope = "globally";
                attribute p = "state Grounded";
            }
            @SysproseVerification::PropertyPattern {
                doc /* GeofenceBreachEndsWatch: once a drone is outside its cleared airspace, it does not watch until it has landed. */
                attribute pattern = "absence";
                attribute scope = "between";
                attribute q = "state AirspaceBreach";
                attribute r = "state Grounded";
                attribute p = "state Watching";
            }
            @SysproseVerification::PropertyPattern {
                doc /* QuarantinedStaysOut: once a drone is quarantined, it takes no part in coordination until it has been readmitted. */
                attribute pattern = "absence";
                attribute scope = "between";
                attribute q = "state Quarantined";
                attribute r = "state Grounded";
                attribute p = "state Watching";
            }
        }

        #State state def MemberOperationalState {
            doc /* each member's own health/availability state, distinct from its operating mode: whether it can currently be tasked and is delivering its share of the watch. */
            initial start;
            state Available {
                doc /* flying, healthy, able to watch or coordinate. */
            }
            state Constrained {
                doc /* flying but limited by an active constraint: navigation, sensing, mesh, weather or airspace. */
            }
            state Unavailable {
                doc /* grounded, recalled or quarantined; not delivering its share of the watch. */
            }
            transition start -> Available;
            transition Available -> Constrained;
            transition Constrained -> Available;
            transition Available -> Unavailable;
            transition Constrained -> Unavailable;
            transition Unavailable -> Available;
        }

        #Configuration state def FleetConfiguration {
            doc /* the fleet-level configuration state, distinct from any one member's mode: whether the mesh among members is fully connected or a share of its links is jammed. Attached to the fleet usage once the population is instantiated, at the next step. */
            initial start;
            state MeshNominal {
                doc /* all mesh links available; full coordination across the fleet. */
            }
            state MeshDegraded {
                doc /* the brief's fleet mode: a share of the links between members is jammed and the swarm coordinates over what is left. */
            }
            transition start -> MeshNominal;
            transition MeshNominal -> MeshDegraded;
            transition MeshDegraded -> MeshNominal;
        }


        #prose part fleetFact {
            doc /* Population fact carried forward from the brief: 12 identical members of SurveillanceDrone (the #Member part def above), exchanging through Common::MeshLink -- never collapsed into one instance. This step keeps every function allocated only to mainComponent, per the functions-only rule; the fleet usage of multiplicity 12 and the two representative peers joined by a peer interface (CV-16) are instantiated at the next step, when logical components are chosen. */
        }

        // ---- actors, carried over unchanged ----
        #Actor part def SwarmSupervisor {
            out port missionTaskingOut : SA::SwarmSupervisor::missionTaskingOut;
            out port supervisoryCommandOut : SA::SwarmSupervisor::supervisoryCommandOut;
            out port recallOrderOut : SA::SwarmSupervisor::recallOrderOut;
            in port statusPictureIn : SA::SwarmSupervisor::statusPictureIn;
            doc /* the single operator who tasks, commands, recalls and watches the whole swarm rather than flying each drone; unchanged from SA. */
        }
        part swarmSupervisor : SwarmSupervisor;
        trace swarmSupervisor to SurveillanceDroneSwarm::SA::swarmSupervisor;

        #Actor part def OperationsCentreAnalyst {
            out port reportAcknowledgementOut : SA::OperationsCentreAnalyst::reportAcknowledgementOut;
            in port detectionReportsIn : SA::OperationsCentreAnalyst::detectionReportsIn;
            in port correlatedTracksIn : SA::OperationsCentreAnalyst::correlatedTracksIn;
            in port triagedAlertStreamIn : SA::OperationsCentreAnalyst::triagedAlertStreamIn;
            in port decisionRecordIn : SA::OperationsCentreAnalyst::decisionRecordIn;
            doc /* watches feeds and reports, judges what matters, and acknowledges each detection report; unchanged from SA. */
        }
        part opsCentreAnalyst : OperationsCentreAnalyst;
        trace opsCentreAnalyst to SurveillanceDroneSwarm::SA::opsCentreAnalyst;

        #Actor part def AirspaceAuthority {
            out port airspaceClearanceOut : SA::AirspaceAuthority::airspaceClearanceOut;
            doc /* clears when and where anything may fly; its geofence and window gate every sortie; unchanged from SA. */
        }
        part airspaceAuthority : AirspaceAuthority;
        trace airspaceAuthority to SurveillanceDroneSwarm::SA::airspaceAuthority;

        #Actor part def OperatingEnvironment {
            out port movingObjectsInAreaOut : SA::OperatingEnvironment::movingObjectsInAreaOut;
            out port sceneConditionsOut : SA::OperatingEnvironment::sceneConditionsOut;
            out port radioInterferenceOut : SA::OperatingEnvironment::radioInterferenceOut;
            out port satellitePositioningOutageOut : SA::OperatingEnvironment::satellitePositioningOutageOut;
            out port weatherLimitOut : SA::OperatingEnvironment::weatherLimitOut;
            doc /* the physical world the swarm watches and flies in; unchanged from SA. */
        }
        part operatingEnvironment : OperatingEnvironment;
        trace operatingEnvironment to SurveillanceDroneSwarm::SA::operatingEnvironment;

        // ---- functions, carried over from SA: every one realised here, allocated to mainComponent ----
        action def HandOverSector {
            doc /* realised by the mesh: two members agree which of them watches a sector next and exchange the assignment, so the sector is never left unwatched during the swap. */
            out reqOut : Common::SectorAssignment;
            in reqIn : Common::SectorAssignment;
        }
        action def RotateRecharge {
            doc /* realised by the mesh: members agree the order in which they leave for the recharge point and swap batteries, keeping the fleet's airborne share up. */
            out reqOut : Common::RechargeRotationPlan;
            in reqIn : Common::RechargeRotationPlan;
        }
        action def RedistributeCoverage {
            doc /* realised by the mesh: the remaining members re-spread across sectors when one leaves, rejoins or is lost, bounding the resulting coverage drop. */
            out reqOut : Common::CoverageRedistributionPlan;
            in reqIn : Common::CoverageRedistributionPlan;
        }
        action def DeconflictFlight {
            doc /* realised by the mesh: members exchange position and intent to keep separated in the air. */
            out reqOut : Common::DeconflictionAdvisory;
            in reqIn : Common::DeconflictionAdvisory;
        }
        action def RelayThroughNeighbour {
            doc /* realised by the mesh: a member forwards a peer's traffic when the peer's direct path to the rest of the swarm or the ground link is unavailable. */
            out reqOut : Common::RelayedMessage;
            in reqIn : Common::RelayedMessage;
        }
        action def CorrelateTracks {
            doc /* realised by the mesh: observations of the same object from different members are merged into one track rather than one per observing drone. */
            out reqOut : Common::Track;
            in reqIn : Common::Track;
        }
        action def HandOverTrack {
            doc /* realised by the mesh: custody of a track is passed from the member that has been observing it to another, e.g. as the object moves between sectors. */
            out reqOut : Common::Track;
            in reqIn : Common::Track;
        }
        action def AdmitMember {
            doc /* realised by the mesh: a candidate's membership request is checked before it takes part in coordination; failure leads to Quarantined rather than silent trust. */
            out admitReqOut : Common::MembershipRequest;
            in admitReqIn : Common::MembershipRequest;
            out admitDecOut : Common::MembershipDecision;
            in admitDecIn : Common::MembershipDecision;
        }
        action def TaskSurveillanceMission {
            doc /* realised at the ground-facing boundary: mission tasking from the supervisor is taken in and turned into a mission window and sectors for the fleet. */
            out cmdOut : Common::MissionTasking;
            in cmdIn : Common::MissionTasking;
        }
        action def IssueSupervisoryCommand {
            doc /* realised at the ground-facing boundary: priorities, a sector to look at more closely and the reporting threshold are taken from the supervisor. */
            out cmdOut : Common::SupervisoryCommand;
            in cmdIn : Common::SupervisoryCommand;
        }
        action def RecallToLand {
            doc /* realised at the ground-facing boundary: a recall order for the whole swarm or one member is taken at any time and drives the affected member(s) toward Recalled. */
            out cmdOut : Common::RecallOrder;
            in cmdIn : Common::RecallOrder;
        }
        action def PresentStatusPicture {
            doc /* realised at the ground-facing boundary: position, activity, coverage and degradation are assembled across the fleet into one status picture for the supervisor. */
            out cmdOut : Common::StatusPicture;
            in cmdIn : Common::StatusPicture;
        }
        action def AcknowledgeDetectionReport {
            doc /* realised at the ground-facing boundary: the analyst's acknowledgement of a detection report is taken in so nothing is lost across a link gap. */
            out ackOut : Common::ReportAcknowledgement;
            in ackIn : Common::ReportAcknowledgement;
        }
        action def WatchSector {
            doc /* holds continuous watch over an assigned sector from altitude; performed by each member over its own sector. */
        }
        action def DetectAndClassify {
            doc /* detects moving objects and classifies them well enough to say whether they matter, reporting Unknown rather than forcing a class when the evidence does not support one. */
        }
        action def ReportDetection {
            doc /* carries one detection report -- position, time, class, confidence, provenance and classifier version -- to the operations centre, holding it across a ground-link gap if needed. */
            out reportOut : Common::DetectionReport;
            in reportIn : Common::DetectionReport;
        }
        action def TriageReportsDefinition {
            doc /* ranks and merges detection reports into a bounded alert stream for the operator and keeps a decision record for every report. */
        }

        #Coordination action handOverSector : HandOverSector;
        trace handOverSector to SurveillanceDroneSwarm::SA::handOverSector;

        #Coordination action rotateRecharge : RotateRecharge;
        trace rotateRecharge to SurveillanceDroneSwarm::SA::rotateRecharge;

        #Coordination action redistributeCoverage : RedistributeCoverage;
        trace redistributeCoverage to SurveillanceDroneSwarm::SA::redistributeCoverage;

        #Coordination action deconflictFlight : DeconflictFlight;
        trace deconflictFlight to SurveillanceDroneSwarm::SA::deconflictFlight;

        #Coordination action relayThroughNeighbour : RelayThroughNeighbour;
        trace relayThroughNeighbour to SurveillanceDroneSwarm::SA::relayThroughNeighbour;

        #Coordination action correlateTracks : CorrelateTracks;
        trace correlateTracks to SurveillanceDroneSwarm::SA::correlateTracks;

        #Coordination action handOverTrack : HandOverTrack;
        trace handOverTrack to SurveillanceDroneSwarm::SA::handOverTrack;

        #Coordination action admitMember : AdmitMember;
        trace admitMember to SurveillanceDroneSwarm::SA::admitMember;

        #C2 action taskSurveillanceMission : TaskSurveillanceMission;
        trace taskSurveillanceMission to SurveillanceDroneSwarm::SA::taskSurveillanceMission;

        #C2 action issueSupervisoryCommand : IssueSupervisoryCommand;
        trace issueSupervisoryCommand to SurveillanceDroneSwarm::SA::issueSupervisoryCommand;

        #C2 action recallToLand : RecallToLand;
        trace recallToLand to SurveillanceDroneSwarm::SA::recallToLand;

        #C2 action presentStatusPicture : PresentStatusPicture;
        trace presentStatusPicture to SurveillanceDroneSwarm::SA::presentStatusPicture;

        #C2 action acknowledgeDetectionReport : AcknowledgeDetectionReport;
        trace acknowledgeDetectionReport to SurveillanceDroneSwarm::SA::acknowledgeDetectionReport;

        action watchSector : WatchSector;
        trace watchSector to SurveillanceDroneSwarm::SA::watchSector;

        action detectAndClassify : DetectAndClassify;
        trace detectAndClassify to SurveillanceDroneSwarm::SA::detectAndClassify;

        action reportDetection : ReportDetection;
        trace reportDetection to SurveillanceDroneSwarm::SA::reportDetection;

        action triageReports : TriageReportsDefinition {
            out triagedAlertOut : Common::TriagedAlert;
            out decisionRecordOut : Common::DecisionRecord;
        }
        trace triageReports to SurveillanceDroneSwarm::SA::triageReports;

        // ---- verification: numeric budgets worth writing for a later solver ----
        require constraint coverageArithmetic {
            doc /* worst-case coverage arithmetic behind the areaUnderWatchFraction estimate: with a 40-minute flight and a 20-minute turnaround, at most 12 * 40/(40+20) = 8 members are airborne at once; at 3.0 km2 each that is 24 km2 against an area of interest of up to 25 km2. */
        }
        require constraint operatorAlertHeld {
            doc /* the alertsReachingOperatorPerHour estimate must stay within the operatorAlertCapacityPerHour budget (20/hour, fixed by OperatorAttention); triageReports is the function that bounds and merges the stream to hold this. */
        }

        // ---- CV-17: this architecture's own worst-case estimate for every measure of effectiveness ----
        #Estimate attribute areaUnderWatchFraction :> Common::areaUnderWatchFraction = 0.90 {
            doc /* basis: coverageArithmetic above -- 8 of 12 members airborne at once at 3.0 km2 each gives ~24 km2 of the up-to-25 km2 area of interest, i.e. ~0.90, at the boundary of the 0.9 target. */
        }
        #Estimate attribute watchEnduranceHoursWithoutPeople :> Common::watchEnduranceHoursWithoutPeople = 10.0 {
            doc /* basis: rotateRecharge keeps the fleet cycling through RechargePointAndBatterySwap indefinitely in principle, but GroundCrew presence at the swap point is itself a human dependency; 10 hours is this architecture's conservative worst case, short of the 12-hour target, and needs confirming with the customer. */
        }
        #Estimate attribute reportDeliveryLatencySeconds :> Common::reportDeliveryLatencySeconds = 45.0 {
            doc /* basis: correlateTracks and reportDetection run onboard, so a report reaches the ground link without waiting on a ground-side correlation step; 45s worst case against the 60s target. */
        }
        #Estimate attribute positionErrorAfterGnssLossMetres :> Common::positionErrorAfterGnssLossMetres = 40.0 {
            doc /* basis: NavigationDegraded members navigate by camera against StoredMaps for the 10-minute gnssOutageToleratedMinutes budget; 40m worst case against the 50m target. */
        }
        #Estimate attribute coverageUnderMeshJammingFraction :> Common::coverageUnderMeshJammingFraction = 0.80 {
            doc /* basis: because handOverSector, redistributeCoverage and relayThroughNeighbour are intended to run onboard (this architecture's variant), the fleet keeps re-spreading over the surviving half of its links (jammedLinkShareFraction 0.5) without waiting on the ground link; 0.80 worst case against the 0.75 target. */
        }
        #Estimate attribute reportHoldDurationMinutes :> Common::reportHoldDurationMinutes = 45.0 {
            doc /* basis: reportDetection buffers reports onboard through a GroundStationLink gap; 45 minutes worst case against the 30-minute target. */
        }
        #Estimate attribute missedDetectionFraction :> Common::missedDetectionFraction = 0.08 {
            doc /* basis: detectAndClassify against SceneConditions worst case; 0.08 against the 0.1 target. */
        }
        #Estimate attribute falseAlarmsPerHour :> Common::falseAlarmsPerHour = 1.5 {
            doc /* basis: detectAndClassify with triageReports merging duplicates before the operator sees them; 1.5/hour against the 2/hour target. */
        }
        #Estimate attribute alertsReachingOperatorPerHour :> Common::alertsReachingOperatorPerHour = 18.0 {
            doc /* basis: triageReports bounds the stream below operatorAlertCapacityPerHour (20/hour); 18/hour worst case, see operatorAlertHeld above. */
        }
        #Estimate attribute acknowledgedReportsThatMatterFraction :> Common::acknowledgedReportsThatMatterFraction = 0.82 {
            doc /* basis: triageReports ranks by what is most likely to matter first; 0.82 against the 0.8 target. */
        }
        #Estimate attribute coverageDropAfterMemberLossFraction :> Common::coverageDropAfterMemberLossFraction = 0.20 {
            doc /* basis: redistributeCoverage re-spreads the remaining 11 members onboard immediately on a loss; 0.20 against the 0.25 target. */
        }
        #Estimate attribute onboardClassifierCostUsdPerDrone :> Common::onboardClassifierCostUsdPerDrone = 280.0 {
            doc /* basis: detectAndClassify running onboard each member against ClassifierRelease; 280 USD/drone worst case against the 300 USD target -- carried forward to PA for a real bill of materials. */
        }

        // ---- safety: hazards this layer adds, beyond those stated at SA ----
        package Hazards {
            doc /* hazards introduced by this layer's own split of responsibilities: allocating coordination onboard, across representative members, rather than to a single ground coordinator, and keeping C2 solely on the ground-facing boundary. Never restates an SA-named hazard. */

            #Hazard requirement PeerCoordinationSinglePointHazard {
                doc /* a single point of failure this layer's intended split introduces: handOverSector, rotateRecharge and admitMember are each meant to be carried out by one member acting for its peers; if that member fails or drops out mid-exchange, the coordination step is left incomplete until another member takes over. */
            }

            #Hazard #Accepted requirement GroundLinkC2SinglePathHazard {
                doc /* accepted: the five #C2 functions are allocated only to mainComponent, the ground-facing boundary; a total GroundStationLink loss removes the supervisory command, recall and acknowledgement path until the link returns. Accepted because DisconnectedOperationAndReconciliation already keeps detectAndClassify and reportDetection running through the gap, and SafetyAuthority requires recall and geofence authority to stay independent of onboard software rather than delegated to the fleet. */
            }
        #Hazard #Accepted requirement GroundCoordinationSinglePointOfFailureHazard {
            doc /* this architecture centralises sector handover, rotation, redistribution, deconfliction, admission and track correlation in one ground component, groundCoordinator; if that component or the ground-station link fails, the fleet loses its deciding coordination even though every member and the mesh itself remain healthy. Accepted as the defining trade-off of the ground-centred alternative: centralising the deciding coordination is what buys the low reportDeliveryLatencySeconds and low onboardClassifierCostUsdPerDrone estimates below; a member-held alternative trades those away for resilience to this single point, and that is exactly the choice the customer is asked to make between the two architectures. */
            subject affected : SurveillanceDroneSwarm::LA::GroundCoordinator;
        }
        #Hazard requirement DirectiveHandoffLossOnLinkGapHazard {
            doc /* a coordination directive issued by the ground and in flight to a member when the ground-station link drops is lost before it lands on that member, leaving a sector hand-over or rotation half-completed until the link is restored */
            subject affected : SurveillanceDroneSwarm::LA::SurveillanceDrone;
        }
        }
        satisfy SurveillanceDroneSwarm::SA::Hazards::MeshJammingHazard by relayThroughNeighbour;
        satisfy SurveillanceDroneSwarm::SA::Hazards::MisclassificationHazard by detectAndClassify;
        satisfy SurveillanceDroneSwarm::SA::Hazards::StaleTrackHazard by correlateTracks;
        satisfy SurveillanceDroneSwarm::SA::Hazards::SpoofedMemberHazard by admitMember;
        satisfy SurveillanceDroneSwarm::SA::Hazards::MixedClassifierVersionsHazard by reportDetection;
        satisfy SurveillanceDroneSwarm::SA::Hazards::OperatorOverloadHazard by triageReports;
        satisfy Hazards::PeerCoordinationSinglePointHazard by redistributeCoverage;

        // ── architecture, alternative 1 ──
        doc /* Logical Architecture, alternative 1 of 2 -- ground-centred coordination and command-and-control. The deciding coordination functions (sector handover, recharge rotation, coverage redistribution, deconfliction, member admission) and all command-and-control functions sit in ground components that never fly -- groundCoordinator, missionControl and triageCentre, modelled as sibling logical components at this layer rather than nested in one wrapping box, so that each function is allocated directly to the part that performs it; only the two coordination functions that are inseparable from mesh hardware itself (relaying a member's traffic, handing a track's custody to a neighbour) execute on the members. This is a genuinely different split from a member-held alternative: intelligence is centralised at the cost of dependence on the ground-station link, stated below as an accepted hazard rather than hidden. Because handOverSector, rotateRecharge and admitMember are decided centrally by groundCoordinator rather than negotiated peer-to-peer, this design also removes the specific single-member-brokers-for-its-peers failure mode that PeerCoordinationSinglePointHazard names: there is no rotating peer broker to lose, only the accepted single point at the ground component itself. */

        #prose part groundSegmentNote {
            doc /* the three ground components below -- groundCoordinator, missionControl, triageCentre -- together form the fixed ground segment of this architecture: none of them fly, and none of the deciding coordination or command-and-control functions leave the ground. If the ground-station link drops, every member keeps watching, deconflicting, relaying and handing off tracks over the mesh on its own, but no new sector handover, recharge rotation, coverage redistribution, deconfliction advisory or admission decision can be made until the link returns -- coordination freezes at its last-issued directive. If a ground component itself fails while the link is healthy, the same freeze applies to whichever function that component carried: groundCoordinator's loss stops sector, rotation, redistribution, deconfliction and admission decisions and track correlation; missionControl's loss stops new tasking, supervisory command, recall relay, status picture and acknowledgement; triageCentre's loss stops triage and the decision record, though raw reports continue to queue at the members. */
        }
        part def GroundCoordinator {
            doc /* the ground-held decision function for the whole fleet: settles sector handover, recharge rotation, coverage redistribution, deconfliction and member admission, and correlates every member's raw track observations into one track per object. If the ground-station link drops, no new decision of any of these kinds can be issued -- every member holds its last-received directive and keeps watching, deconflicting and relaying on its own until the link returns. If this component itself fails while the link is healthy, the same freeze applies even though the link is fine: the fleet has no other place these decisions are made. */
            in port memberStatusIn : Common::MemberStatusReport {
                doc /* each member's periodic status, the raw material for every coordination decision made here */
            }
            in port memberTrackObservationsIn : Common::Track {
                doc /* a member's raw observation of an object, before correlation into one track */
            }
            out port directiveOut : Common::CoordinationDirective {
                doc /* the sector, rotation, redistribution, deconfliction or admission decision issued down to the fleet */
            }
            out port correlatedTracksOut : Common::Track {
                doc /* one track per object, merged from every member's raw observations, for the operations centre */
            }
        }
        part def MissionControl {
            doc /* the ground-held command-and-control function: takes tasking, supervisory command, recall and report acknowledgement from the supervisor and analyst, relays recall down to the fleet, and assembles the status picture from member status */
            in port missionTaskingIn : Common::MissionTasking {
                doc /* the area of interest, its sectors and the mission window, from the supervisor */
            }
            in port supervisoryCommandIn : Common::SupervisoryCommand {
                doc /* priorities, a sector to look at more closely, and the reporting threshold, from the supervisor */
            }
            in port recallOrderIn : Common::RecallOrder {
                doc /* an order to recall and land the whole swarm or one drone, from the supervisor, at any time */
            }
            in port reportAcknowledgementIn : Common::ReportAcknowledgement {
                doc /* the analyst's confirmation of a detection report */
            }
            in port memberStatusIn : Common::MemberStatusReport {
                doc /* each member's status, assembled here into the status picture */
            }
            out port statusPictureOut : Common::StatusPicture {
                doc /* where every member is, what it is doing, how much coverage there is and what is degraded */
            }
            out port recallRelayOut : Common::RecallOrder {
                doc /* the recall order relayed down to the fleet */
            }
        }
        part def TriageCentre {
            doc /* the ground-held triage function: ranks and merges member detection reports into a bounded alert stream for the operator, keeps a decision record for every report, and forwards the reports themselves to the operations centre */
            in port detectionReportsIn : Common::DetectionReport {
                doc /* a raw detection report from a member */
            }
            out port triagedAlertStreamOut : Common::TriagedAlert {
                doc /* what is most likely to matter, first, duplicates merged, sized to one operator */
            }
            out port decisionRecordOut : Common::DecisionRecord {
                doc /* for every report: the frames it came from, the classifier version, the threshold in force and who acknowledged it */
            }
            out port detectionReportsOut : Common::DetectionReport {
                doc /* the triaged detection report forwarded on to the operations centre */
            }
        }
        part groundCoordinator : GroundCoordinator {
            doc /* the deciding-coordination usage for this operation; a directly-declared logical component so every coordination function is allocated straight to it */
        }
        part missionControl : MissionControl {
            doc /* the command-and-control usage for this operation; a directly-declared logical component so every C2 function is allocated straight to it */
        }
        part triageCentre : TriageCentre {
            doc /* the triage-and-decision-record usage for this operation; a directly-declared logical component so triageReports is allocated straight to it */
        }
        #Member part def SurveillanceDrone {
            doc /* the single replicable member of the watchAsset population: senses and classifies within its assigned sector, holds its own reports through a ground-link gap, executes the sector, rotation, redistribution, deconfliction and admission directives the ground decides, and relays traffic or hands a track to a neighbour directly over the mesh when a direct path to the ground is unavailable */

            out port meshOut : Common::MeshPeerPort {
                doc /* this member's outgoing mesh link to a peer member, carrying relay traffic and track hand-off */
            }
            in port meshIn : ~Common::MeshPeerPort {
                doc /* this member's incoming mesh link from a peer member, the conjugate of meshOut */
            }
            in port directiveIn : Common::CoordinationDirective {
                doc /* the ground's sector, rotation, redistribution, deconfliction or admission decision for this member */
            }
            out port statusOut : Common::MemberStatusReport {
                doc /* this member's position, activity, battery level and sector, fed to the ground */
            }
            out port detectionOut : Common::DetectionReport {
                doc /* a raw detection report, held through a ground-link gap and delivered once the link returns */
            }
            out port trackObservationOut : Common::Track {
                doc /* this member's raw observation of an object, sent to the ground for correlation */
            }
            in port recallIn : Common::RecallOrder {
                doc /* a recall order relayed by the ground, or issued to this member alone */
            }
            in port airspaceClearanceIn : Common::AirspaceClearance {
                doc /* the cleared volume and window this member may fly in */
            }
            in port movingObjectsIn : Common::MovingObjectsInArea {
                doc /* the objects present in this member's sector */
            }
            in port sceneConditionsIn : Common::SceneConditions {
                doc /* lighting, weather and deliberately misleading paint or shapes affecting what this member's sensors can tell apart */
            }
            in port radioInterferenceIn : Common::RadioInterference {
                doc /* interference degrading the mesh this member depends on for relay and track hand-off */
            }
            in port satOutageIn : Common::SatellitePositioningOutage {
                doc /* a satellite-positioning outage affecting this member */
            }
            in port weatherIn : Common::WeatherLimit {
                doc /* the weather this member is currently operating in */
            }

            #Mode state def MemberMode {
                doc /* the member's flight and watch mode; carries the three rules that govern when it may watch and when it must land */
                initial start;
                transition start -> Grounded;
                state Grounded {
                    doc /* not flying: landed, whether recalled, in airspace breach, or awaiting clearance */
                }
                state Transiting {
                    doc /* flying between the recharge point and its assigned sector */
                }
                state Watching {
                    doc /* holding watch over its assigned sector */
                }
                state Recalled {
                    doc /* returning to land following a recall order */
                }
                state AirspaceBreach {
                    doc /* outside the cleared volume or window; watch does not resume until landed */
                }
                state Isolated {
                    doc /* cut off from the mesh; returning to the recovery point on its own */
                }
                state NavigationDegraded {
                    doc /* no satellite positioning; navigating by camera against stored maps */
                }
                state SensingDegraded {
                    doc /* a sensor cannot be trusted as it is; watching continues but reports are marked less reliable */
                }
                transition Grounded -> Transiting;
                transition Transiting -> Watching;
                transition Watching -> Recalled;
                transition Recalled -> Grounded;
                transition Watching -> AirspaceBreach;
                transition AirspaceBreach -> Grounded;
                transition Watching -> Isolated;
                transition Isolated -> Grounded;
                transition Watching -> NavigationDegraded;
                transition NavigationDegraded -> Watching;
                transition Watching -> SensingDegraded;
                transition SensingDegraded -> Watching;

                @SysproseVerification::PropertyPattern {
                    doc /* RecallWins: once a drone is recalled, it does not watch again until it has landed */
                    attribute pattern = "absence";
                    attribute scope = "between";
                    attribute q = "state Recalled";
                    attribute r = "state Grounded";
                    attribute p = "state Watching";
                }
                @SysproseVerification::PropertyPattern {
                    doc /* GeofenceBreachEndsWatch: once a drone is outside its cleared airspace, it does not watch until it has landed */
                    attribute pattern = "absence";
                    attribute scope = "between";
                    attribute q = "state AirspaceBreach";
                    attribute r = "state Grounded";
                    attribute p = "state Watching";
                }
                @SysproseVerification::PropertyPattern {
                    doc /* ReturnsWhenIsolated: from any situation a drone can be in, it can always get back to landed, an isolated drone included */
                    attribute pattern = "recovery";
                    attribute scope = "globally";
                    attribute p = "state Grounded";
                }
            }

            #State state def MemberParticipationState {
                doc /* the member's standing with respect to mesh coordination: whether it is taking part or excluded pending readmission */
                initial start;
                transition start -> Coordinating;
                state Coordinating {
                    doc /* taking part in mesh coordination */
                }
                state Quarantined {
                    doc /* failed admission; takes no part in coordination until readmitted */
                }
                state Readmitted {
                    doc /* passed a fresh admission check; about to resume coordinating */
                }
                transition Coordinating -> Quarantined;
                transition Quarantined -> Readmitted;
                transition Readmitted -> Coordinating;

                @SysproseVerification::PropertyPattern {
                    doc /* QuarantinedStaysOut: once a drone is quarantined, it takes no part in coordination until it has been readmitted */
                    attribute pattern = "absence";
                    attribute scope = "between";
                    attribute q = "state Quarantined";
                    attribute r = "state Readmitted";
                    attribute p = "state Coordinating";
                }
            }
        }
        part fleet : SurveillanceDrone [12] {
            doc /* the twelve identical drones realising the watchAsset population, rotated through recharge by the ground coordinator */
            state config : FleetConfiguration {
                doc /* the fleet's current mesh configuration */
            }
        }
        part memberA : SurveillanceDrone {
            doc /* a representative member, used to show the pairwise mesh interaction (relay, track hand-off) between two members */
        }
        part memberB : SurveillanceDrone {
            doc /* the peer representative memberA exchanges with directly over the mesh */
        }
        interface peerLink : Common::MeshLink connect memberA.meshOut to memberB.meshIn {
            doc /* the peer-to-peer mesh link between two members, carried physically by MeshRadio and realised at PA; independent of the ground-station link */
        }
        connection missionTaskingLink connect swarmSupervisor.missionTaskingOut to missionControl.missionTaskingIn {
            doc /* mission tasking from the supervisor into mission control */
        }
        connection supervisoryCommandLink connect swarmSupervisor.supervisoryCommandOut to missionControl.supervisoryCommandIn {
            doc /* supervisory command from the supervisor into mission control */
        }
        connection recallOrderLink connect swarmSupervisor.recallOrderOut to missionControl.recallOrderIn {
            doc /* a recall order from the supervisor into mission control, at any time */
        }
        connection statusPictureLink connect missionControl.statusPictureOut to swarmSupervisor.statusPictureIn {
            doc /* the assembled status picture back to the supervisor */
        }
        connection reportAckLink connect opsCentreAnalyst.reportAcknowledgementOut to missionControl.reportAcknowledgementIn {
            doc /* the analyst's acknowledgement of a detection report into mission control */
        }
        connection detectionReportsLink connect triageCentre.detectionReportsOut to opsCentreAnalyst.detectionReportsIn {
            doc /* triaged detection reports to the analyst */
        }
        connection correlatedTracksLink connect groundCoordinator.correlatedTracksOut to opsCentreAnalyst.correlatedTracksIn {
            doc /* correlated tracks to the analyst, for merging with the fixed camera network */
        }
        connection triagedAlertLink connect triageCentre.triagedAlertStreamOut to opsCentreAnalyst.triagedAlertStreamIn {
            doc /* the triaged alert stream to the analyst */
        }
        connection decisionRecordLink connect triageCentre.decisionRecordOut to opsCentreAnalyst.decisionRecordIn {
            doc /* the decision record to the analyst, for every report */
        }
        connection airspaceClearanceLink connect airspaceAuthority.airspaceClearanceOut to fleet.airspaceClearanceIn {
            doc /* airspace clearance to every member */
        }
        connection movingObjectsLink connect operatingEnvironment.movingObjectsInAreaOut to fleet.movingObjectsIn {
            doc /* the moving objects present in the area, to every member's sensors */
        }
        connection sceneConditionsLink connect operatingEnvironment.sceneConditionsOut to fleet.sceneConditionsIn {
            doc /* scene conditions to every member's sensors */
        }
        connection radioInterferenceLink connect operatingEnvironment.radioInterferenceOut to fleet.radioInterferenceIn {
            doc /* radio interference exposure to every member's mesh link */
        }
        connection satOutageLink connect operatingEnvironment.satellitePositioningOutageOut to fleet.satOutageIn {
            doc /* satellite-positioning outage exposure to every member */
        }
        connection weatherLimitLink connect operatingEnvironment.weatherLimitOut to fleet.weatherIn {
            doc /* the current weather to every member */
        }
        connection directiveLink connect groundCoordinator.directiveOut to fleet.directiveIn {
            doc /* the ground's coordination directive down to the fleet -- the deciding link this architecture depends on */
        }
        connection statusToCoordinatorLink connect fleet.statusOut to groundCoordinator.memberStatusIn {
            doc /* member status feeding every coordination decision */
        }
        connection statusToMissionControlLink connect fleet.statusOut to missionControl.memberStatusIn {
            doc /* member status feeding the assembled status picture */
        }
        connection detectionUplinkLink connect fleet.detectionOut to triageCentre.detectionReportsIn {
            doc /* raw detection reports up to triage, over the not-always-available ground-station link */
        }
        connection trackUplinkLink connect fleet.trackObservationOut to groundCoordinator.memberTrackObservationsIn {
            doc /* raw track observations up to correlation */
        }
        connection recallRelayLink connect missionControl.recallRelayOut to fleet.recallIn {
            doc /* recall relayed down to the fleet as a whole or to one member */
        }
        allocate handOverSector to groundCoordinator;
        allocate rotateRecharge to groundCoordinator;
        allocate redistributeCoverage to groundCoordinator;
        allocate deconflictFlight to groundCoordinator;
        allocate admitMember to groundCoordinator;
        allocate correlateTracks to groundCoordinator;
        allocate relayThroughNeighbour to fleet;
        allocate handOverTrack to fleet;
        allocate taskSurveillanceMission to missionControl;
        allocate issueSupervisoryCommand to missionControl;
        allocate recallToLand to missionControl;
        allocate presentStatusPicture to missionControl;
        allocate acknowledgeDetectionReport to missionControl;
        allocate triageReports to triageCentre;
        allocate watchSector to fleet;
        allocate detectAndClassify to fleet;
        allocate reportDetection to fleet;
        satisfy SurveillanceDroneSwarm::SA::RecallWins by fleet;
        satisfy SurveillanceDroneSwarm::SA::ReturnsWhenIsolated by fleet;
        satisfy SurveillanceDroneSwarm::SA::GeofenceBreachEndsWatch by fleet;
        satisfy SurveillanceDroneSwarm::SA::QuarantinedStaysOut by fleet;
        satisfy SurveillanceDroneSwarm::SA::Hazards::PositionDriftHazard by fleet;
        satisfy SurveillanceDroneSwarm::SA::Hazards::MeshJammingHazard by groundCoordinator;
        satisfy SurveillanceDroneSwarm::SA::Hazards::MisclassificationHazard by fleet;
        satisfy SurveillanceDroneSwarm::SA::Hazards::SensingDegradedUnnoticedHazard by fleet;
        satisfy SurveillanceDroneSwarm::SA::Hazards::StaleTrackHazard by groundCoordinator;
        satisfy SurveillanceDroneSwarm::SA::Hazards::SpoofedMemberHazard by groundCoordinator;
        satisfy SurveillanceDroneSwarm::SA::Hazards::MixedClassifierVersionsHazard by missionControl;
        satisfy SurveillanceDroneSwarm::SA::Hazards::OperatorOverloadHazard by triageCentre;
        satisfy Hazards::DirectiveHandoffLossOnLinkGapHazard by fleet;
        attribute fleetSizeValue : Real = 12 {
            doc /* restated from the brief's fixed fleet-size budget, for use in the derivations below */
        }
        attribute enduranceMinutesValue : Real = 40 {
            doc /* restated from the brief's fixed per-member flight-endurance budget */
        }
        attribute turnaroundMinutesValue : Real = 20 {
            doc /* restated from the brief's fixed ground-turnaround budget */
        }
        attribute footprintValue : Real = 3.0 {
            doc /* restated from the brief's fixed per-member sensor-footprint budget */
        }
        attribute areaOfInterestValue : Real = 25.0 {
            doc /* restated from the brief's fixed, worst-case area-of-interest budget */
        }
        attribute jammedLinkShareValue : Real = 0.5 {
            doc /* restated from the brief's fixed jammed-link-share budget */
        }
        attribute airborneShare : Real = enduranceMinutesValue / (enduranceMinutesValue + turnaroundMinutesValue) {
            doc /* the share of the population airborne at any moment; no coverage measure below is allowed to exceed what follows from this */
        }
        attribute airborneCount : Real = fleetSizeValue * airborneShare {
            doc /* how many of the twelve members are airborne at any moment, on average */
        }
        attribute coverageCapacity : Real = airborneCount * footprintValue {
            doc /* the area the airborne members can cover at any moment, before it is compared with the area of interest */
        }
        attribute meshDependentCoverageShare : Real = 0.08 {
            doc /* this architecture's own valued attribute: only relay and track hand-off depend on the mesh for coverage, since sector assignment, rotation, redistribution and deconfliction are decided on the ground and do not depend on the mesh at all -- the reason this split is chosen */
        }
        assert constraint { areaUnderWatchFraction == coverageCapacity / areaOfInterestValue }
        assert constraint { coverageUnderMeshJammingFraction == areaUnderWatchFraction * (1.0 - jammedLinkShareValue * meshDependentCoverageShare) }
        assert constraint { coverageDropAfterMemberLossFraction == footprintValue / coverageCapacity }
    }
