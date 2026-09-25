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
        #Hazard requirement CoordinationDivergenceHazard {
            doc /* with sector handover, recharge rotation and coverage redistribution decided independently by members rather than arbitrated by the ground, two members may reach conflicting local decisions at the same moment — e.g. both vacating the same sector for recharge — with no ground arbiter to break the tie */
        }
        #Hazard #Accepted requirement GroundAdmissionBottleneckHazard {
            doc /* accepted: because admitMember stays solely at the ground control station, a lost ground link blocks admission or readmission of any member until the link returns. This is deliberately fail-closed — an un-vetted candidate is safer excluded than admitted — and existing members' watch is unaffected since the other seven #Coordination functions run on board regardless of ground reachability */
        }
        }
        satisfy SurveillanceDroneSwarm::SA::Hazards::MeshJammingHazard by relayThroughNeighbour;
        satisfy SurveillanceDroneSwarm::SA::Hazards::MisclassificationHazard by detectAndClassify;
        satisfy SurveillanceDroneSwarm::SA::Hazards::StaleTrackHazard by correlateTracks;
        satisfy SurveillanceDroneSwarm::SA::Hazards::SpoofedMemberHazard by admitMember;
        satisfy SurveillanceDroneSwarm::SA::Hazards::MixedClassifierVersionsHazard by reportDetection;
        satisfy SurveillanceDroneSwarm::SA::Hazards::OperatorOverloadHazard by triageReports;
        satisfy Hazards::PeerCoordinationSinglePointHazard by redistributeCoverage;

        // ── architecture, alternative 2 ──
        doc /* Logical architecture, alternative 2 of 2: drone-centred coordination. The eight #Coordination functions are settled peer-to-peer by the members themselves over the mesh, with a deterministic tie-break so independent local decisions do not collide; only member admission (a security decision) and all five #C2 functions stay anchored to the ground control station. This is a genuinely different split from a ground-centred alternative: here the fleet is the locus of swarm self-management and the ground station is reduced to tasking, command, recall, status assembly, acknowledgement handling, member vetting and operator-facing triage. */

        #prose part droneCentricRationale {
            doc /* Trade-off note: pushing handOverSector, rotateRecharge, redistributeCoverage, deconflictFlight, relayThroughNeighbour, correlateTracks and handOverTrack onto the fleet means coordination keeps working with half the mesh links jammed (coverageUnderMeshJammingFraction) and shortens report latency (no ground round-trip before correlation). The cost is that this alternative cannot rely on a ground arbiter to resolve conflicting local decisions, and needs more onboard compute per drone than a ground-centred split, which the classifier-cost estimate reflects. */
        }
        /* ===================== the population (CV-16) ===================== */

        #Member part def SurveillanceDrone {
            doc /* the one replicable member of the watchAsset population: one of the twelve identical drones. In this alternative it hosts its own sensing, navigation and the bulk of swarm self-coordination, deciding sector handover, recharge rotation, coverage redistribution, deconfliction, relay, track correlation and track handover together with its peers over the mesh, without waiting on the ground station. A coordinator for a given exchange is whichever member currently holds the lowest droneId among reachable peers for that sector/topic (a deterministic, mesh-computable tie-break); if it drops out mid-exchange the next-lowest reachable id takes over immediately, so no single member's loss stalls coordination -- this rotating-coordinator mechanism is exactly what mitigates PeerCoordinationSinglePointHazard below. If the ground link drops, the fleet keeps handing over sectors, rotating recharge, redistributing coverage, deconflicting flight, relaying and correlating tracks entirely over the mesh; only new-member admission and ground-issued tasking/recall wait for the link. If the ground station itself fails, the fleet continues flying its last tasking and self-coordinating indefinitely, but cannot admit new members and cannot receive a fresh recall order until a ground station returns. */

            out port meshOut : SurveillanceDroneSwarm::Common::MeshPeerPort {
                doc /* this member's outgoing mesh link to a peer member, carrying coordination traffic */
            }
            in port meshIn : ~SurveillanceDroneSwarm::Common::MeshPeerPort {
                doc /* this member's incoming mesh link from a peer member, the conjugate of meshOut */
            }
            in port taskingIn : SurveillanceDroneSwarm::Common::MissionTasking {
                doc /* mission tasking relayed down from the ground control station */
            }
            in port commandIn : SurveillanceDroneSwarm::Common::SupervisoryCommand {
                doc /* supervisory command relayed down from the ground control station */
            }
            in port recallIn : SurveillanceDroneSwarm::Common::RecallOrder {
                doc /* recall order relayed down from the ground control station, actionable at any time */
            }
            out port detectionReportOut : SurveillanceDroneSwarm::Common::DetectionReport {
                doc /* a detection this member produced, sent up to the ground control station once correlated on board */
            }
            out port trackOut : SurveillanceDroneSwarm::Common::Track {
                doc /* a correlated track this member (or its correlating peer) holds custody of, sent up to the ground control station */
            }

            #Mode state def SurveillanceDroneMode {
                doc /* this member's operating mode; carries, unchanged in shape from SA, the rules the member's machine must never break */
                initial start;
                transition start -> Grounded;
                transition Grounded -> Transiting;
                transition Transiting -> Watching;
                transition Watching -> Recharging;
                transition Recharging -> Transiting;
                transition Watching -> NavigationDegraded;
                transition NavigationDegraded -> Watching;
                transition Watching -> SensingDegraded;
                transition SensingDegraded -> Watching;
                transition Watching -> Isolated;
                transition Isolated -> Grounded;
                transition NavigationDegraded -> Isolated;
                transition Watching -> AirspaceBreach;
                transition AirspaceBreach -> Grounded;
                transition Watching -> Quarantined;
                transition Quarantined -> Grounded;
                transition Grounded -> Quarantined;
                transition Watching -> Recalled;
                transition Transiting -> Recalled;
                transition Recalled -> Grounded;

                state Grounded {
                    doc /* not flying: landed, whether recalled, quarantined, in airspace breach or awaiting clearance */
                }
                state Transiting {
                    doc /* flying between the recharge point and an assigned sector */
                }
                state Watching {
                    doc /* holding continuous watch over the assigned sector */
                    @SysproseVerification::PropertyPattern {
                        doc /* RecallWins: once this drone is recalled, it does not watch again until it has landed */
                        attribute pattern = "absence";
                        attribute scope = "between";
                        attribute q = "state Recalled";
                        attribute r = "state Grounded";
                        attribute p = "state Watching";
                    }
                    @SysproseVerification::PropertyPattern {
                        doc /* GeofenceBreachEndsWatch: once this drone is outside its cleared airspace, it does not watch until it has landed */
                        attribute pattern = "absence";
                        attribute scope = "between";
                        attribute q = "state AirspaceBreach";
                        attribute r = "state Grounded";
                        attribute p = "state Watching";
                    }
                    @SysproseVerification::PropertyPattern {
                        doc /* QuarantinedStaysOut: once this drone is quarantined, it takes no part in coordination, and does not watch, until it has been readmitted */
                        attribute pattern = "absence";
                        attribute scope = "between";
                        attribute q = "state Quarantined";
                        attribute r = "state Grounded";
                        attribute p = "state Watching";
                    }
                    @SysproseVerification::PropertyPattern {
                        doc /* ReturnsWhenIsolated: from any situation this drone can be in, it can always get back to Grounded, an isolated drone included */
                        attribute pattern = "recovery";
                        attribute scope = "globally";
                        attribute p = "state Grounded";
                    }
                }
                state Recharging {
                    doc /* on the ground at the recharge point having its battery swapped */
                }
                state NavigationDegraded {
                    doc /* the brief's member mode: no satellite positioning; navigating by camera against stored maps */
                }
                state SensingDegraded {
                    doc /* the brief's member mode: a sensor cannot be trusted as it is */
                }
                state Isolated {
                    doc /* the brief's member mode: cut off from the mesh, unable to coordinate with peers */
                }
                state AirspaceBreach {
                    doc /* outside the cleared volume or window; watch does not resume until landed */
                }
                state Quarantined {
                    doc /* the brief's member mode: excluded from coordination on suspicion of not being a genuine member, pending readmission by the ground control station */
                }
                state Recalled {
                    doc /* returning to land following a recall order */
                }
            }

            #State state def SurveillanceDroneTaskState {
                doc /* this member's internal task-execution state, an axis distinct from its operating mode: what it is doing with its sensing and radio right now */
                initial start;
                transition start -> Idle;
                transition Idle -> Sensing;
                transition Sensing -> Coordinating;
                transition Coordinating -> Sensing;
                transition Sensing -> Reporting;
                transition Reporting -> Sensing;
                transition Sensing -> Idle;

                state Idle {
                    doc /* not currently sensing, coordinating or reporting */
                }
                state Sensing {
                    doc /* actively detecting and classifying objects in the assigned sector */
                }
                state Coordinating {
                    doc /* exchanging coordination traffic with a peer over the mesh */
                }
                state Reporting {
                    doc /* sending a detection report or track up to the ground control station */
                }
            }

            state mode : SurveillanceDroneMode {
                doc /* this member's current operating mode */
            }
            state task : SurveillanceDroneTaskState {
                doc /* this member's current task-execution state */
            }
        }
        part fleet : SurveillanceDrone[12] {
            doc /* the twelve identical drones of the watchAsset population; in this alternative the fleet carries the majority of #Coordination functions on board */
        }
        part memberA : SurveillanceDrone {
            doc /* representative member used to show a peer-to-peer mesh exchange */
        }
        part memberB : SurveillanceDrone {
            doc /* representative member used to show a peer-to-peer mesh exchange */
        }
        interface peerLink : SurveillanceDroneSwarm::Common::MeshLink connect memberA.meshOut to memberB.meshIn {
            doc /* the mesh peer link between two members, carried by MeshRadio, that lets coordination and command traffic pass member to member independent of the ground link */
        }
        part fleetConfiguration : FleetConfiguration {
            doc /* the fleet's own configuration usage, separate from any individual member's mode or state */
        }
        /* ===================== the ground control station ===================== */

        part def GroundControlStation {
            doc /* the fixed, ground-based logical component: in this alternative it tasks, commands, recalls, watches and acknowledges for the supervisor and analyst, vets candidate members before admission, and triages the fleet's output for the operator — but it does not decide sector handover, recharge rotation, coverage redistribution, deconfliction, relay, or track correlation/handover, which the fleet settles itself. */

            out port taskingOut : SurveillanceDroneSwarm::Common::MissionTasking {
                doc /* mission tasking relayed down to the fleet */
            }
            out port commandOut : SurveillanceDroneSwarm::Common::SupervisoryCommand {
                doc /* supervisory command relayed down to the fleet */
            }
            out port recallOut : SurveillanceDroneSwarm::Common::RecallOrder {
                doc /* a recall order relayed down to the fleet, at any time */
            }
            in port detectionReportIn : SurveillanceDroneSwarm::Common::DetectionReport {
                doc /* a detection report received from a member */
            }
            in port trackIn : SurveillanceDroneSwarm::Common::Track {
                doc /* a correlated track received from a member */
            }

            attribute classifierVersion : String {
                doc /* the one classifier version this station holds and distributes as the ClassifierRelease resource, so every member's running version is known and kept aligned */
            }

            #Mode state def GroundControlStationMode {
                doc /* this ground component's own operating mode */
                initial start;
                transition start -> Active;
                transition Active -> LinkDegraded;
                transition LinkDegraded -> Active;
                transition Active -> Offline;
                transition Offline -> Active;

                state Active {
                    doc /* the ground-station link is up and tasking, command, status and triage flow normally */
                }
                state LinkDegraded {
                    doc /* the ground-station link to some or all of the fleet is degraded; the fleet continues on its own coordination while this station waits */
                }
                state Offline {
                    doc /* the ground-station link is down; the fleet is disconnected and holding its own reports until it returns */
                }
            }
            #State state def GroundControlStationState {
                doc /* this ground component's internal processing state */
                initial start;
                transition start -> Idle;
                transition Idle -> Triaging;
                transition Triaging -> Idle;
                transition Idle -> Vetting;
                transition Vetting -> Idle;

                state Idle {
                    doc /* awaiting the next tasking, command, report or admission request */
                }
                state Triaging {
                    doc /* ranking and merging reports into the triaged alert stream and writing the decision record */
                }
                state Vetting {
                    doc /* deciding whether a candidate joins the mesh */
                }
            }
            state mode : GroundControlStationMode {
                doc /* this component's current operating mode */
            }
            state processing : GroundControlStationState {
                doc /* this component's current processing state */
            }

            #Variant attribute useGroundRelayFallback : Boolean = false {
                doc /* design option: whether the ground station additionally relays mesh traffic between isolated members when peer relay cannot reach them; off by default in this drone-centric alternative, which relies on relayThroughNeighbour on the fleet */
            }
        }
        part groundControlStation : GroundControlStation {
            doc /* the ground control station on duty for this operation: tasking, command, recall, status assembly, acknowledgement handling, member vetting and operator-facing triage all live here in this alternative */
        }
        connection downlinkTasking connect groundControlStation.taskingOut to fleet.taskingIn {
            doc /* carries mission tasking from the ground control station down to the fleet */
        }
        connection downlinkCommand connect groundControlStation.commandOut to fleet.commandIn {
            doc /* carries supervisory command from the ground control station down to the fleet */
        }
        connection downlinkRecall connect groundControlStation.recallOut to fleet.recallIn {
            doc /* carries a recall order from the ground control station down to the fleet, at any time */
        }
        connection uplinkDetections connect fleet.detectionReportOut to groundControlStation.detectionReportIn {
            doc /* carries a member's detection report up to the ground control station for triage and delivery to the analyst */
        }
        connection uplinkTracks connect fleet.trackOut to groundControlStation.trackIn {
            doc /* carries a member's correlated track up to the ground control station for delivery to the analyst */
        }
        /* ===================== logical functions, realising the system functions from SA, and their allocation ===================== */

        /* #Coordination — allocated to the fleet (on board) except admitMember, which stays a ground vetting decision in this alternative; 7 of 8 on the members satisfies "at least half" */
        allocate handOverSector to fleet;
        allocate rotateRecharge to fleet;
        allocate redistributeCoverage to fleet;
        allocate deconflictFlight to fleet;
        allocate relayThroughNeighbour to fleet;
        allocate correlateTracks to fleet;
        allocate handOverTrack to fleet;
        allocate admitMember to groundControlStation;
        /* #C2 — kept on the ground in both alternatives */
        allocate taskSurveillanceMission to groundControlStation;
        allocate issueSupervisoryCommand to groundControlStation;
        allocate recallToLand to groundControlStation;
        allocate presentStatusPicture to groundControlStation;
        allocate acknowledgeDetectionReport to groundControlStation;
        /* other system functions */
        allocate watchSector to fleet;
        allocate detectAndClassify to fleet;
        allocate reportDetection to fleet;
        allocate triageReports to groundControlStation;
        /* ===================== rules carried down from SA (CV-18) ===================== */
        satisfy SurveillanceDroneSwarm::SA::RecallWins by fleet;
        satisfy SurveillanceDroneSwarm::SA::ReturnsWhenIsolated by fleet;
        satisfy SurveillanceDroneSwarm::SA::GeofenceBreachEndsWatch by fleet;
        satisfy SurveillanceDroneSwarm::SA::QuarantinedStaysOut by fleet;
        /* ===================== hazards named by the brief, satisfied here by path (never restated) ===================== */
        satisfy SurveillanceDroneSwarm::SA::Hazards::PositionDriftHazard by fleet;
        satisfy SurveillanceDroneSwarm::SA::Hazards::MeshJammingHazard by fleetConfiguration;
        satisfy SurveillanceDroneSwarm::SA::Hazards::MisclassificationHazard by fleet;
        satisfy SurveillanceDroneSwarm::SA::Hazards::SensingDegradedUnnoticedHazard by fleet;
        satisfy SurveillanceDroneSwarm::SA::Hazards::StaleTrackHazard by fleet;
        satisfy SurveillanceDroneSwarm::SA::Hazards::SpoofedMemberHazard by groundControlStation;
        satisfy SurveillanceDroneSwarm::SA::Hazards::MixedClassifierVersionsHazard by groundControlStation;
        satisfy SurveillanceDroneSwarm::SA::Hazards::OperatorOverloadHazard by groundControlStation;
        satisfy Hazards::CoordinationDivergenceHazard by fleet;
        satisfy Hazards::PeerCoordinationSinglePointHazard by fleet;
        /* ===================== measures of effectiveness: this alternative's worst-case estimate for every measure (CV-17) ===================== */

        attribute fleetSizeValue : Real = 12 {
            doc /* restates FleetAndEnduranceBudget's fleet size, fixed by the brief, for this layer's derivation */
        }
        attribute flightMinutesValue : Real = 40 {
            doc /* restates memberFlightEnduranceMinutes, fixed by the brief */
        }
        attribute turnaroundMinutesValue : Real = 20 {
            doc /* restates groundTurnaroundMinutes, fixed by the brief */
        }
        attribute footprintValue : Real = 3.0 {
            doc /* restates sensorFootprintSquareKilometres, fixed by the brief */
        }
        attribute areaOfInterestValue : Real = 25 {
            doc /* restates areaOfInterestSquareKilometres at its worst-case (largest) value, fixed by the brief */
        }
        attribute airborneShareValue : Real {
            doc /* the share of the fleet airborne at any moment, which the brief fixes as flight/(flight+recharge); this bounds areaUnderWatchFraction and is not stated larger than that bound */
        }
        assert constraint {
            airborneShareValue == flightMinutesValue / (flightMinutesValue + turnaroundMinutesValue)
        }
        assert constraint {
            areaUnderWatchFraction == (fleetSizeValue * airborneShareValue * footprintValue) / areaOfInterestValue
        }
    }
