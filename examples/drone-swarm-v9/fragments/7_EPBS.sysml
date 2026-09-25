    package EPBS {
      doc /* End-product breakdown: one configuration item per thing procured, built or delivered for the SurveillanceDroneSwarm. Each item realises a physical part of the layer above, carries its contract as a requirement definition and is verified by a verification definition. Counts are multiplicities on the usages, never on the definitions. */

      // ---------------------------------------------------------------
      // Hardware and commercial-off-the-shelf configuration items
      // ---------------------------------------------------------------

      #CI_HWCI part def DroneAirframe {
        doc /* The drone itself: airframe, propulsion and flight controller. One item type, twelve fielded. Endurance and cruise speed are the brief's fixed numbers; transit to and from the recharge point is spent out of the same endurance. */
        attribute enduranceMinutes : Real = 40;
        attribute cruiseSpeedMetresPerSecond : Real = 18;
        attribute startStateOfChargeFraction : Real = 1.0;
      }

      #CI_COTS part def SensorPayload {
        doc /* The camera payload on each drone, bought as a commercial item. It sets the instantaneous footprint under watch and is the part most exposed to going out of production. */
        attribute footprintSquareKilometres : Real = 3.0;
        attribute qualifiedSourceCount : Real = 2;
        attribute interfaceStandardised : Boolean = true;
        attribute withinOperatingEnvelope : Boolean = true;
      }

      #CI_COTS part def OnboardComputeModule {
        doc /* The commercial computing module on each drone that runs classification, navigation against stored maps and the report store. Its unit cost decides how much classification sits on the drone rather than on the ground. */
        attribute unitCostUsd : Real;
        attribute reportStorageHoldMinutes : Real = 30;
        attribute withinOperatingEnvelope : Boolean = true;
      }

      #CI_COTS part def BatteryPack {
        doc /* The swappable battery pack. Packs are swapped at the recharge point, not charged in the drone, in about twenty minutes of turnaround, so the pack supply is what keeps sectors filled while drones rotate. */
        attribute packEnduranceMinutes : Real = 40;
        attribute swapTurnaroundMinutes : Real = 20;
        attribute qualifiedSourceCount : Real = 2;
        attribute withinOperatingEnvelope : Boolean = true;
      }

      #CI_COTS part def MeshRadioModule {
        doc /* The radio on each drone that carries coordination traffic between drones over the mesh, independent of the link to the operations centre, and that holds the per-drone credential used at admission. */
        attribute authenticatesPeers : Boolean = true;
        attribute independentOfGroundLink : Boolean = true;
        attribute withinOperatingEnvelope : Boolean = true;
      }

      #CI_HWCI part def GroundStationEquipment {
        doc /* The ground station hardware from which the swarm is tasked and watched and, in the ground-centred architecture, coordinated. One is fielded. */
        attribute supervisedMembers : Real = 12;
        attribute withinOperatingEnvelope : Boolean = true;
      }

      #CI_COTS part def GroundLinkRadio {
        doc /* The commercial radio that forms the intermittent link between the ground station and the operations centre, carrying tasking, command, reports, status and acknowledgements. */
        attribute carriesAcknowledgements : Boolean = true;
        attribute toleratesGaps : Boolean = true;
        attribute withinOperatingEnvelope : Boolean = true;
      }

      // ---------------------------------------------------------------
      // Software configuration items
      // ---------------------------------------------------------------

      #CI_CSCI part def DroneFlightSoftware {
        doc /* Flight and navigation software on each drone: stays inside the cleared airspace, lands on recall, on breach of clearance or above moderate wind, returns to the recovery point when isolated, and navigates by camera against stored maps when satellite positioning is out. */
        attribute satelliteOutageMinutes : Real = 10;
        attribute positionErrorMetres : Real;
        attribute landsWhenRecalledOrOutsideClearance : Boolean = true;
        attribute returnsToRecoveryPointWhenIsolated : Boolean = true;
        attribute signedBaseline : Boolean = true;
      }

      #CI_CSCI part def DetectionClassifierSoftware {
        doc /* The on-board detection and classification software. It says Unknown rather than forcing a class below the reporting threshold and stamps every report with its own classifier version. */
        attribute missedDetectionFraction : Real;
        attribute falseAlarmsPerHour : Real;
        attribute reportsUnknownBelowThreshold : Boolean = true;
        attribute stampsClassifierVersion : Boolean = true;
        attribute withinOperatingEnvelope : Boolean = true;
      }

      #CI_CSCI part def ReportStoreForwardSoftware {
        doc /* On-board software that holds each detection report while the drone is cut off, forwards it when a path exists and keeps it until the operations centre acknowledges it, so none is lost in a link gap. */
        attribute holdWhileCutOffMinutes : Real = 30;
        attribute reportsLost : Real = 0;
        attribute retainsUntilAcknowledged : Boolean = true;
        attribute withinOperatingEnvelope : Boolean = true;
      }

      #CI_CSCI #Variant part def MemberCoordinationSoftware {
        doc /* Variant for the member-centred architecture: the coordination software each drone runs to settle sector handover, recharge rotation, coverage redistribution, deconfliction, link relay, track correlation, track handover and member admission over the mesh. */
        attribute areaUnderWatchFraction : Real;
        attribute coverageLossAfterMemberLossFraction : Real;
        attribute coverageUnderMeshJammingFraction : Real;
        attribute meshLinksJammedFraction : Real = 0.5;
        attribute admitsOnlyAuthenticated : Boolean = true;
      }

      #CI_CSCI #Variant part def GroundCoordinationSoftware {
        doc /* Variant for the ground-centred architecture: the coordination software that runs on the ground station and settles the same coordination functions for the drones. It is the alternative to member coordination, not an addition to it. */
        attribute areaUnderWatchFraction : Real;
        attribute coverageLossAfterMemberLossFraction : Real;
        attribute coverageUnderMeshJammingFraction : Real;
        attribute meshLinksJammedFraction : Real = 0.5;
        attribute admitsOnlyAuthenticated : Boolean = true;
      }

      #CI_CSCI part def AlertTriageSoftware {
        doc /* Ground software that ranks reports so that what is most likely to matter reaches the operator first and merges duplicates, keeping the alert rate inside what one operator can judge. */
        attribute alertsReachingOperatorPerHour : Real;
        attribute operatorSecondsPerAlert : Real = 30;
        attribute mergesDuplicates : Boolean = true;
        attribute withinOperatingEnvelope : Boolean = true;
      }

      #CI_CSCI part def DecisionRecordSoftware {
        doc /* Ground software that keeps, for every report, the frames it came from, the classifier version, the reporting threshold in force and who acknowledged it. */
        attribute recordsFrames : Boolean = true;
        attribute recordsClassifierVersion : Boolean = true;
        attribute recordsThreshold : Boolean = true;
        attribute recordsAcknowledger : Boolean = true;
        attribute withinOperatingEnvelope : Boolean = true;
      }

      #CI_CSCI part def OperatorConsoleSoftware {
        doc /* Ground software through which one operator tasks, commands, recalls and watches the swarm and acknowledges each report. It presents the swarm tracks in a form that can be merged with the fixed camera network's tracks and marks a track stale after the stated time. */
        attribute trackStaleAfterSeconds : Real = 120;
        attribute offersTaskCommandRecall : Boolean = true;
        attribute presentsStatusPicture : Boolean = true;
        attribute acknowledgesEachReport : Boolean = true;
        attribute tracksMergeableWithFixedNetwork : Boolean = true;
        attribute withinOperatingEnvelope : Boolean = true;
      }

      #CI_CSCI part def FleetLoaderSoftware {
        doc /* Ground software that loads one signed software baseline, classifier included, onto every drone and verifies what each drone runs before it flies, so no version drifts across the fleet. */
        attribute distinctBaselinesInFleet : Real = 1;
        attribute verifiesBeforeFlight : Boolean = true;
        attribute withinOperatingEnvelope : Boolean = true;
      }

      // ---------------------------------------------------------------
      // Fielded usages: the cardinality is the multiplicity
      // ---------------------------------------------------------------

      part droneAirframes : DroneAirframe [12] {
        doc /* The twelve fielded drone airframes; the fleet size is fixed by the brief. */
      }
      part sensorPayloads : SensorPayload [12] {
        doc /* One camera payload per drone. */
      }
      part computeModules : OnboardComputeModule [12] {
        doc /* One on-board computing module per drone. */
      }
      part batteryPacks : BatteryPack [24] {
        doc /* Battery packs in circulation: one set in the drones and one set at the recharge point, so a swap never waits for a pack. The count is a sizing assumption held for the acquirer to confirm. */
      }
      part meshRadios : MeshRadioModule [12] {
        doc /* One mesh radio per drone. */
      }
      part groundStationEquipment : GroundStationEquipment [1] {
        doc /* The single ground station. */
      }
      part groundLinkRadio : GroundLinkRadio [1] {
        doc /* The single radio to the operations centre. */
      }
      part flightSoftware : DroneFlightSoftware [12] {
        doc /* Flight software installed on each drone. */
      }
      part classifierSoftware : DetectionClassifierSoftware [12] {
        doc /* The same classifier baseline installed on each drone. */
      }
      part storeForwardSoftware : ReportStoreForwardSoftware [12] {
        doc /* Report store-and-forward installed on each drone. */
      }
      #Variant part memberCoordination : MemberCoordinationSoftware [12] {
        doc /* Member-centred variant: coordination software installed on each drone. */
      }
      #Variant part groundCoordination : GroundCoordinationSoftware [1] {
        doc /* Ground-centred variant: coordination software installed on the ground station. */
      }
      part alertTriage : AlertTriageSoftware [1] {
        doc /* Alert triage on the ground station. */
      }
      part decisionRecords : DecisionRecordSoftware [1] {
        doc /* Decision record keeping on the ground station. */
      }
      part operatorConsole : OperatorConsoleSoftware [1] {
        doc /* The operator console software on the ground station. */
      }
      part fleetLoader : FleetLoaderSoftware [1] {
        doc /* The fleet baseline loader on the ground station. */
      }

      // ---------------------------------------------------------------
      // Realisation: each configuration item traces to the part it realises
      // ---------------------------------------------------------------

      trace DroneAirframe to SurveillanceDroneSwarm::PA::SwarmMember;
      trace SensorPayload to SurveillanceDroneSwarm::PA::SwarmMember;
      trace OnboardComputeModule to SurveillanceDroneSwarm::PA::SwarmMember;
      trace BatteryPack to SurveillanceDroneSwarm::PA::SwarmMember;
      trace MeshRadioModule to SurveillanceDroneSwarm::PA::SwarmMember;
      trace DroneFlightSoftware to SurveillanceDroneSwarm::PA::SwarmMember;
      trace DetectionClassifierSoftware to SurveillanceDroneSwarm::PA::SwarmMember;
      trace ReportStoreForwardSoftware to SurveillanceDroneSwarm::PA::SwarmMember;
      trace MemberCoordinationSoftware to SurveillanceDroneSwarm::PA::SwarmMember;
      trace GroundStationEquipment to SurveillanceDroneSwarm::PA::GroundStation;
      trace GroundLinkRadio to SurveillanceDroneSwarm::PA::GroundStation;
      trace GroundCoordinationSoftware to SurveillanceDroneSwarm::PA::GroundStation;
      trace AlertTriageSoftware to SurveillanceDroneSwarm::PA::GroundStation;
      trace DecisionRecordSoftware to SurveillanceDroneSwarm::PA::GroundStation;
      trace OperatorConsoleSoftware to SurveillanceDroneSwarm::PA::GroundStation;
      trace FleetLoaderSoftware to SurveillanceDroneSwarm::PA::GroundStation;

      // Realisation of the PA usages: the fleet and its two representatives are
      // built from the drone airframe and the mesh radio; the ground-side usages
      // are realised by the ground station hardware and the software that runs on it.
      trace DroneAirframe to SurveillanceDroneSwarm::PA::fleet;
      trace DroneAirframe to SurveillanceDroneSwarm::PA::memberA;
      trace DroneAirframe to SurveillanceDroneSwarm::PA::memberB;
      trace MeshRadioModule to SurveillanceDroneSwarm::PA::memberA;
      trace MeshRadioModule to SurveillanceDroneSwarm::PA::memberB;
      trace GroundStationEquipment to SurveillanceDroneSwarm::PA::groundRecallTransmitter;
      trace OperatorConsoleSoftware to SurveillanceDroneSwarm::PA::groundRecallTransmitter;
      trace AlertTriageSoftware to SurveillanceDroneSwarm::PA::groundAlertTriage;
      trace DecisionRecordSoftware to SurveillanceDroneSwarm::PA::groundDecisionRecordStore;
      trace DroneAirframe to SurveillanceDroneSwarm::PA::mainAssembly;
      trace GroundStationEquipment to SurveillanceDroneSwarm::PA::mainAssembly;

      // ---------------------------------------------------------------
      // Contracts: one requirement definition per configuration item
      // ---------------------------------------------------------------

      requirement def DroneAirframeContract {
        subject airframe : DroneAirframe;
        attribute id = "EPBS-CI-01";
        doc /* Starting from a freshly swapped pack, the airframe flies about 40 minutes at about 18 m/s cruise; transit to and from the recharge point is spent from that endurance. */
        assume constraint { airframe.startStateOfChargeFraction >= 1.0 }
        require constraint { airframe.enduranceMinutes >= 40 and airframe.cruiseSpeedMetresPerSecond >= 18 }
      }

      requirement def SensorPayloadContract {
        subject payload : SensorPayload;
        attribute id = "EPBS-CI-02";
        doc /* The payload keeps about 3.0 km2 under watch at once, has a standardised interface and has at least two qualified sources, so a discontinued model can be replaced without redesign. */
        assume constraint { payload.withinOperatingEnvelope == true }
        require constraint { payload.footprintSquareKilometres >= 3.0 and payload.qualifiedSourceCount >= 2 and payload.interfaceStandardised == true }
      }

      requirement def OnboardComputeModuleContract {
        subject compute : OnboardComputeModule;
        attribute id = "EPBS-CI-03";
        doc /* On-board classification computing costs no more than 300 USD per drone (a placeholder awaiting the customer's number) and its storage holds reports for at least 30 minutes while cut off. */
        assume constraint { compute.withinOperatingEnvelope == true }
        require constraint { compute.unitCostUsd <= 300 and compute.reportStorageHoldMinutes >= 30 }
      }

      requirement def BatteryPackContract {
        subject pack : BatteryPack;
        attribute id = "EPBS-CI-04";
        doc /* A pack gives at least 40 minutes of flight, is swapped in no more than 20 minutes, and is available from at least two qualified sources so that one supplier stopping does not stop the rotation. */
        assume constraint { pack.withinOperatingEnvelope == true }
        require constraint { pack.packEnduranceMinutes >= 40 and pack.swapTurnaroundMinutes <= 20 and pack.qualifiedSourceCount >= 2 }
      }

      requirement def MeshRadioModuleContract {
        subject radio : MeshRadioModule;
        attribute id = "EPBS-CI-05";
        doc /* The mesh radio works without the link to the operations centre and admits only peers that present a valid credential. */
        assume constraint { radio.withinOperatingEnvelope == true }
        require constraint { radio.independentOfGroundLink == true and radio.authenticatesPeers == true }
      }

      requirement def GroundStationEquipmentContract {
        subject station : GroundStationEquipment;
        attribute id = "EPBS-CI-06";
        doc /* The ground station supervises all twelve drones at once. */
        assume constraint { station.withinOperatingEnvelope == true }
        require constraint { station.supervisedMembers >= 12 }
      }

      requirement def GroundLinkRadioContract {
        subject linkRadio : GroundLinkRadio;
        attribute id = "EPBS-CI-07";
        doc /* The ground link carries acknowledgements and tolerates gaps in availability without losing what it carries. */
        assume constraint { linkRadio.withinOperatingEnvelope == true }
        require constraint { linkRadio.carriesAcknowledgements == true and linkRadio.toleratesGaps == true }
      }

      requirement def DroneFlightSoftwareContract {
        subject software : DroneFlightSoftware;
        attribute id = "EPBS-CI-08";
        doc /* After ten minutes without satellite positioning the position error is at most 50 m (a placeholder awaiting the customer's number); the drone lands on recall or outside clearance and returns to the recovery point when isolated; it runs a signed baseline. */
        assume constraint { software.satelliteOutageMinutes <= 10 }
        require constraint { software.positionErrorMetres <= 50 and software.landsWhenRecalledOrOutsideClearance == true and software.returnsToRecoveryPointWhenIsolated == true and software.signedBaseline == true }
      }

      requirement def DetectionClassifierSoftwareContract {
        subject detector : DetectionClassifierSoftware;
        attribute id = "EPBS-CI-09";
        doc /* Missed detections stay at or below 0.10 of real objects and false alarms at or below 2 per hour (placeholders awaiting the customer's numbers); below the reporting threshold the class is Unknown; every report carries the classifier version. */
        assume constraint { detector.withinOperatingEnvelope == true }
        require constraint { detector.missedDetectionFraction <= 0.1 and detector.falseAlarmsPerHour <= 2 and detector.reportsUnknownBelowThreshold == true and detector.stampsClassifierVersion == true }
      }

      requirement def ReportStoreForwardSoftwareContract {
        subject store : ReportStoreForwardSoftware;
        attribute id = "EPBS-CI-10";
        doc /* A drone that is cut off holds its reports for at least 30 minutes (a placeholder awaiting the customer's number) without losing any, and keeps each until it is acknowledged. */
        assume constraint { store.withinOperatingEnvelope == true }
        require constraint { store.holdWhileCutOffMinutes >= 30 and store.reportsLost <= 0 and store.retainsUntilAcknowledged == true }
      }

      requirement def MemberCoordinationSoftwareContract {
        subject coordination : MemberCoordinationSoftware;
        attribute id = "EPBS-CI-11";
        doc /* With drones coordinating among themselves, at least 0.9 of the area stays under watch, one lost drone costs at most 0.25 of coverage before re-spreading, and with half the links jammed at least 0.75 stays under watch (a placeholder). Only authenticated drones are admitted. */
        assume constraint { coordination.meshLinksJammedFraction <= 0.5 }
        require constraint { coordination.areaUnderWatchFraction >= 0.9 and coordination.coverageLossAfterMemberLossFraction <= 0.25 and coordination.coverageUnderMeshJammingFraction >= 0.75 and coordination.admitsOnlyAuthenticated == true }
      }

      requirement def GroundCoordinationSoftwareContract {
        subject coordination : GroundCoordinationSoftware;
        attribute id = "EPBS-CI-12";
        doc /* With the ground station coordinating, the same coverage figures hold: at least 0.9 of the area under watch, at most 0.25 lost with one drone, at least 0.75 kept with half the links jammed (a placeholder). Only authenticated drones are admitted. */
        assume constraint { coordination.meshLinksJammedFraction <= 0.5 }
        require constraint { coordination.areaUnderWatchFraction >= 0.9 and coordination.coverageLossAfterMemberLossFraction <= 0.25 and coordination.coverageUnderMeshJammingFraction >= 0.75 and coordination.admitsOnlyAuthenticated == true }
      }

      requirement def AlertTriageSoftwareContract {
        subject triage : AlertTriageSoftware;
        attribute id = "EPBS-CI-13";
        doc /* No more than 20 alerts an hour reach the operator (a placeholder awaiting the customer's number), which at 30 seconds an alert stays inside what one operator can judge; duplicates are merged. */
        assume constraint { triage.withinOperatingEnvelope == true }
        require constraint { triage.alertsReachingOperatorPerHour <= 20 and triage.alertsReachingOperatorPerHour * triage.operatorSecondsPerAlert <= 3600 and triage.mergesDuplicates == true }
      }

      requirement def DecisionRecordSoftwareContract {
        subject records : DecisionRecordSoftware;
        attribute id = "EPBS-CI-14";
        doc /* For every report the record holds the frames it came from, the classifier version, the reporting threshold in force and who acknowledged it. */
        assume constraint { records.withinOperatingEnvelope == true }
        require constraint { records.recordsFrames == true and records.recordsClassifierVersion == true and records.recordsThreshold == true and records.recordsAcknowledger == true }
      }

      requirement def OperatorConsoleSoftwareContract {
        subject console : OperatorConsoleSoftware;
        attribute id = "EPBS-CI-15";
        doc /* One operator can task, command, recall and watch the whole swarm and acknowledge each report; tracks go stale after 120 seconds unseen (a placeholder) and are mergeable with the fixed camera network's tracks. */
        assume constraint { console.withinOperatingEnvelope == true }
        require constraint { console.trackStaleAfterSeconds <= 120 and console.offersTaskCommandRecall == true and console.presentsStatusPicture == true and console.acknowledgesEachReport == true and console.tracksMergeableWithFixedNetwork == true }
      }

      requirement def FleetLoaderSoftwareContract {
        subject loader : FleetLoaderSoftware;
        attribute id = "EPBS-CI-16";
        doc /* The whole fleet runs one baseline, and each drone's baseline is verified before it flies. */
        assume constraint { loader.withinOperatingEnvelope == true }
        require constraint { loader.distinctBaselinesInFleet <= 1 and loader.verifiesBeforeFlight == true }
      }

      // ---------------------------------------------------------------
      // Verification: one case per contract
      // ---------------------------------------------------------------

      verification def VerifyDroneAirframe {
        doc /* Flight test of endurance and cruise speed from a freshly swapped pack. */
        subject airframe : DroneAirframe;
        objective { verify DroneAirframeContract; }
      }
      verification def VerifySensorPayload {
        doc /* Measurement of footprint under watch and audit of the interface specification and sources. */
        subject payload : SensorPayload;
        objective { verify SensorPayloadContract; }
      }
      verification def VerifyOnboardComputeModule {
        doc /* Cost check and a storage hold test at the report rate. */
        subject compute : OnboardComputeModule;
        objective { verify OnboardComputeModuleContract; }
      }
      verification def VerifyBatteryPack {
        doc /* Discharge test for endurance, timed swap at the recharge point and audit of sources. */
        subject pack : BatteryPack;
        objective { verify BatteryPackContract; }
      }
      verification def VerifyMeshRadioModule {
        doc /* Mesh test with the ground link off and admission test with a valid and an invalid credential. */
        subject radio : MeshRadioModule;
        objective { verify MeshRadioModuleContract; }
      }
      verification def VerifyGroundStationEquipment {
        doc /* Demonstration of supervising twelve drones at once. */
        subject station : GroundStationEquipment;
        objective { verify GroundStationEquipmentContract; }
      }
      verification def VerifyGroundLinkRadio {
        doc /* Link test with gaps: acknowledgements survive and nothing carried is lost. */
        subject linkRadio : GroundLinkRadio;
        objective { verify GroundLinkRadioContract; }
      }
      verification def VerifyDroneFlightSoftware {
        doc /* Flight test with satellite positioning withheld for ten minutes, recall, clearance breach and isolation. */
        subject software : DroneFlightSoftware;
        objective { verify DroneFlightSoftwareContract; }
      }
      verification def VerifyDetectionClassifierSoftware {
        doc /* Scored run on recorded and live scenes, including misleading paint and shapes, for missed detections, false alarms and Unknown below threshold. */
        subject detector : DetectionClassifierSoftware;
        objective { verify DetectionClassifierSoftwareContract; }
      }
      verification def VerifyReportStoreForwardSoftware {
        doc /* Cut-off test of 30 minutes then reconciliation against the operations centre's acknowledgements. */
        subject store : ReportStoreForwardSoftware;
        objective { verify ReportStoreForwardSoftwareContract; }
      }
      verification def VerifyMemberCoordinationSoftware {
        doc /* Swarm simulation and field trial: member rotation, one member lost, half the mesh links jammed. */
        subject coordination : MemberCoordinationSoftware;
        objective { verify MemberCoordinationSoftwareContract; }
      }
      verification def VerifyGroundCoordinationSoftware {
        doc /* The same swarm simulation and field trial with coordination on the ground station. */
        subject coordination : GroundCoordinationSoftware;
        objective { verify GroundCoordinationSoftwareContract; }
      }
      verification def VerifyAlertTriageSoftware {
        doc /* Replay of a recorded alert stream measuring alerts reaching the operator per hour and duplicate merging. */
        subject triage : AlertTriageSoftware;
        objective { verify AlertTriageSoftwareContract; }
      }
      verification def VerifyDecisionRecordSoftware {
        doc /* Inspection of the record of a sample of reports for all four items. */
        subject records : DecisionRecordSoftware;
        objective { verify DecisionRecordSoftwareContract; }
      }
      verification def VerifyOperatorConsoleSoftware {
        doc /* Operator demonstration of task, command, recall, acknowledgement and stale marking, and a merge with fixed-network tracks. */
        subject console : OperatorConsoleSoftware;
        objective { verify OperatorConsoleSoftwareContract; }
      }
      verification def VerifyFleetLoaderSoftware {
        doc /* Load to all twelve drones and check that the baseline each reports is the same. */
        subject loader : FleetLoaderSoftware;
        objective { verify FleetLoaderSoftwareContract; }
      }

      // ---------------------------------------------------------------
      // Satisfaction of the contracts by the fielded items
      // ---------------------------------------------------------------

      satisfy DroneAirframeContract by droneAirframes;
      satisfy SensorPayloadContract by sensorPayloads;
      satisfy OnboardComputeModuleContract by computeModules;
      satisfy BatteryPackContract by batteryPacks;
      satisfy MeshRadioModuleContract by meshRadios;
      satisfy GroundStationEquipmentContract by groundStationEquipment;
      satisfy GroundLinkRadioContract by groundLinkRadio;
      satisfy DroneFlightSoftwareContract by flightSoftware;
      satisfy DetectionClassifierSoftwareContract by classifierSoftware;
      satisfy ReportStoreForwardSoftwareContract by storeForwardSoftware;
      satisfy MemberCoordinationSoftwareContract by memberCoordination;
      satisfy GroundCoordinationSoftwareContract by groundCoordination;
      satisfy AlertTriageSoftwareContract by alertTriage;
      satisfy DecisionRecordSoftwareContract by decisionRecords;
      satisfy OperatorConsoleSoftwareContract by operatorConsole;
      satisfy FleetLoaderSoftwareContract by fleetLoader;

      // ---------------------------------------------------------------
      // Hazards this layer adds, and their mitigation
      // ---------------------------------------------------------------

      package Hazards {
        doc /* Hazards introduced by what is procured: a supplier that stops shipping, a software version that drifts across the fleet, a part that goes out of production. */

        #Hazard requirement BatterySupplierStopsShippingHazard {
          subject pack : BatteryPack;
          doc /* The only source of battery packs stops shipping, swaps at the recharge point stop being possible, drones cannot rotate and the area under watch falls below what is required. */
        }

        #Hazard requirement FleetFlightSoftwareVersionDriftHazard {
          subject software : DroneFlightSoftware;
          doc /* Field updates reach some drones and not others, so the fleet runs different flight and coordination builds that disagree on handover, admission or clearance handling. */
        }

        #Hazard requirement SensorPayloadObsolescenceHazard {
          subject payload : SensorPayload;
          doc /* The camera model goes out of production; a substitute with different optics is fitted to some drones, the footprint shrinks and the classifier meets images it was not validated on. */
        }
      }

      satisfy Hazards::BatterySupplierStopsShippingHazard by batteryPacks;
      satisfy Hazards::FleetFlightSoftwareVersionDriftHazard by fleetLoader;
      satisfy Hazards::SensorPayloadObsolescenceHazard by sensorPayloads;

      // Hazards stated above that a configuration item here also mitigates.
      satisfy SurveillanceDroneSwarm::SA::Hazards::MixedClassifierVersionsHazard by fleetLoader;
      satisfy SurveillanceDroneSwarm::SA::Hazards::SpoofedMemberHazard by meshRadios;
      satisfy SurveillanceDroneSwarm::SA::Hazards::PositionDriftHazard by flightSoftware;
    }
