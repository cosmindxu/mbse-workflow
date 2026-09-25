/**
 * The final audit's fleet row at EPBS reads the configuration items that
 * realise PA's fleet. v4's first audit printed "—" there beside a `[12]` CI.
 */
import { describe, expect, it } from 'vitest';
import { epbsFleet } from '../../src/audit/final.ts';

describe('the fleet at EPBS', () => {
  const text = [
    'package EPBS {',
    '  part droneAirframeCi : DroneAirframeItem [12] { doc /* airframes */ }',
    '  trace droneAirframeCi to SurveillanceSwarm::PA::fleet;',
    '  part groundStationCi : GroundStationItem;',
    '  trace groundStationCi to SurveillanceSwarm::PA::groundStation;',
    '}',
  ].join('\n');
  const elements = [
    { qualifiedName: 'SurveillanceSwarm::EPBS::droneAirframeCi', multiplicity: '12' },
    { qualifiedName: 'SurveillanceSwarm::EPBS::groundStationCi', multiplicity: '' },
  ];

  it('names the item that realises the fleet, with its multiplicity', () => {
    expect(epbsFleet(text, elements, 'SurveillanceSwarm', 'fleet')).toBe('`droneAirframeCi` [12]');
  });

  it('is empty when nothing realises the fleet', () => {
    expect(epbsFleet(text, elements, 'SurveillanceSwarm', 'swarm')).toBeUndefined();
  });
});
