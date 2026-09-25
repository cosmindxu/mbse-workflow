/**
 * Where the local study corpus is.
 *
 * The corpus (`mbse-approaches`) is the provenance of this project's step
 * table, conventions and predicates, and it stays on this machine: nothing
 * derived from it — the reference model, the payloads recorded from it — is
 * committed here. What the code carries is its own operating rules and
 * pointers to row ids, which is why the tests that need the corpus skip
 * cleanly on a checkout that does not have it.
 */
import { existsSync } from 'node:fs';
import { homedir } from 'node:os';
import { resolve } from 'node:path';

export const corpusDir = (): string =>
  process.env.MBSE_APPROACHES_DIR ?? resolve(homedir(), 'Work/mbse-approaches');

export const corpusPath = (...parts: string[]): string => resolve(corpusDir(), ...parts);

export const referenceModelPath = (): string =>
  process.env.MBSE_REFERENCE_MODEL ?? corpusPath('evidence/examples/M1-levelcrossing.sysml');

export const hasCorpus = (): boolean => existsSync(referenceModelPath());
