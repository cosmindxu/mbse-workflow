// A product family of this workflow's own: an inspection platform offered with
// one of two sensor heads and one of two power packs, a selection constraint
// pairing them, and two configurations. The bonus lane (S60) runs
// `sysprose variability` over it; the unit test holds its verdicts.
package SensorFamily {
    part def SensorHead;
    part def Optical :> SensorHead;
    part def Thermal :> SensorHead;
    part def PowerPack;
    part def Battery :> PowerPack;
    part def Tethered :> PowerPack;

    // A reference-form variant is named by the usage it references.
    part standardBattery : Battery;
    part longTether : Tethered;

    part def InspectionPlatform {
        variation part head : SensorHead {
            variant part optical : Optical;
            variant part thermal : Thermal;
        }
        variation part power : PowerPack {
            variant standardBattery;
            variant longTether;
        }
        // The thermal head draws more than the battery gives.
        assert constraint powerFitsHead {
            not (head == head::thermal and power == power::standardBattery)
        }
    }

    part fieldKit : InspectionPlatform {
        part :>> head = head::optical;
        part :>> power :> power::standardBattery;
    }
    part plantSurvey : InspectionPlatform {
        part :>> head = head::thermal;
        part :>> power = power::longTether;
    }
}
