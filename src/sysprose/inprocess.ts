/**
 * Sysprose driven in process: one library parse per node process, ~170 ms per
 * model load after the first, against ~3 s for a CLI spawn.
 *
 * Every report here is built from the same API function the CLI's own
 * subcommand calls, and `trace`, `elements` and `requirements` reproduce the
 * assembly the CLI does on top of it (axis derivation, the re-derived-element
 * filter, the statement-kind column). What that buys is an audit packet a
 * reader can reproduce with `npm run sysprose -- <cmd>` and get the same
 * numbers back; `test/unit/backend-parity.test.ts` is what keeps it true.
 */
import { execFile } from 'node:child_process';
import { readFileSync } from 'node:fs';
import { promisify } from 'node:util';
import type { ElementRecord, Model } from '@core/index';
import {
  boundsReport,
  connectivityReport,
  consistencyReport,
  countUnfollowedTypings,
  evidenceStatus,
  faultTreeReport,
  behaviourReport,
  impactClosure,
  isUserElement,
  keywordUsesOn,
  modelMetrics,
  orphanReport,
  promptsFor,
  reachReport,
  refinementReport,
  requirementSatisfaction,
  traceabilityMatrix,
  verifyModel,
} from '@api/index';
import { resolveFullName, statementKindOf } from '@semantics/index';
import { buildGrid } from '@diagram/grid';
import { buildRequirementsTable } from '@diagram/requirements-table';
import { loadModelText } from '@text/load';
import { checkText } from '@text/check';
import { TRACE_PRESETS } from '@sysprose/scripts/lib/sysprose-spec';
import { ElementRefError, type Loaded, type SysproseBackend, type TagIndex } from './backend.ts';
import { SerialQueue } from './queue.ts';
import { buildLayerView, type LayerView } from '../transition/view.ts';
import type { Layer } from '../spec/layers.ts';
import type {
  CheckReport,
  ElementRef,
  ElementRow,
  RequirementRow,
  RequirementsPayload,
  StatementKindFilter,
  SysproseVersion,
  TraceLink,
  TracePayload,
  TraceRelation,
} from './types.ts';

const exec = promisify(execFile);

const label = (ref: { declaredName?: string; qualifiedName: string; id: string }): string =>
  ref.declaredName ?? (ref.qualifiedName || ref.id);

const qname = (model: Model, id: string): string => model.qualifiedName(id) || id;

export interface InProcessOptions {
  /** The Sysprose checkout being driven — reported, never imported from. */
  dir: string;
  /** The commit the mapping and the predicates were measured against. */
  expectedCommit: string;
}

export class InProcessBackend implements SysproseBackend {
  readonly kind = 'inprocess' as const;
  readonly #queue = new SerialQueue();
  readonly #opts: InProcessOptions;

  constructor(opts: InProcessOptions) {
    this.#opts = opts;
  }

  async version(): Promise<SysproseVersion> {
    let commit = 'unknown';
    try {
      const { stdout } = await exec('git', ['-C', this.#opts.dir, 'rev-parse', '--short=7', 'HEAD']);
      commit = stdout.trim();
    } catch {
      /* not a checkout, or no git: reported as unknown rather than guessed */
    }
    return {
      dir: this.#opts.dir,
      commit,
      expected: this.#opts.expectedCommit,
      matches: commit.startsWith(this.#opts.expectedCommit) || this.#opts.expectedCommit.startsWith(commit),
    };
  }

  async withModel<T>(text: string, displayName: string, fn: (m: Loaded) => Promise<T> | T): Promise<T> {
    return this.#queue.run(async () => {
      const { model, report } = await loadModelText(text, { library: 'full', displayName });
      if (!model) {
        // Nothing parsed at all. The report is the whole answer, and every
        // caller wants it rather than an exception with the findings inside.
        throw new NothingLoadedError(displayName, report);
      }
      return fn({ model, report, text, displayName });
    });
  }

  async check(text: string, displayName: string): Promise<CheckReport> {
    return this.#queue.run(() => checkText(text, { library: 'full', displayName }));
  }

  /* ───────────────────────────── reports ───────────────────────────── */

  elements(m: Loaded, includeLibrary = false): ElementRow[] {
    const grid = buildGrid(m.model, { excludeLibrary: !includeLibrary });
    return grid.rows
      .filter((r) => {
        const el = m.model.get(r.id);
        if (!el) return false;
        return isUserElement(m.model, el) || (includeLibrary && el.attrs.isLibrary === true);
      })
      .map((r) => ({
        id: r.id,
        qualifiedName: qname(m.model, r.id),
        name: r.cells.name,
        metaclass: r.cells.metaclass,
        type: r.cells.type,
        multiplicity: r.cells.multiplicity,
        value: r.cells.value,
        redefines: r.cells.redefines,
        doc: r.cells.doc,
      }));
  }

  tags(m: Loaded): TagIndex {
    const byElement = new Map<string, string[]>();
    const byKeyword = new Map<string, string[]>();
    for (const el of m.model.all()) {
      if (!isUserElement(m.model, el)) continue;
      const uses = keywordUsesOn(m.model, el);
      if (uses.length === 0) continue;
      const qn = qname(m.model, el.id);
      const words = uses.map((u) => u.keyword);
      byElement.set(qn, words);
      for (const w of words) byKeyword.set(w, [...(byKeyword.get(w) ?? []), qn]);
    }
    return {
      byElement,
      byKeyword,
      has: (qn, keyword) => (byElement.get(qn) ?? []).includes(keyword),
      taggedWith: (keyword) => byKeyword.get(keyword) ?? [],
    };
  }

  layerView(m: Loaded, layer: Layer): LayerView {
    const tags = this.tags(m);
    const actorDefs = new Set(tags.taggedWith('Actor'));
    const root = m.model.roots()[0]?.declaredName ?? '';
    return buildLayerView(m.model, root, layer, actorDefs, (qn) => tags.byElement.get(qn) ?? []);
  }

  trace(m: Loaded, relation: TraceRelation, from?: string, to?: string): TracePayload {
    const model = m.model;
    const relKinds = TRACE_PRESETS.get(relation);
    if (!relKinds) throw new ElementRefError(`unknown relation \`${relation}\``);

    const derived = traceAxes(model, relKinds);
    for (const [flag, kind] of [
      ['from', from],
      ['to', to],
    ] as const) {
      if (kind !== undefined && model.ofKind(kind).length === 0) {
        throw new ElementRefError(`--${flag} names a metaclass this model has none of (\`${kind}\`)`);
      }
    }
    const fromKinds = from ? [from] : derived.fromKinds;
    const toKinds = to ? [to] : derived.toKinds;

    const rows = new Map<string, ElementRef>();
    const columns = new Map<string, ElementRef>();
    const links = new Map<string, { from: string; to: string; relationshipId: string }>();
    for (const f of fromKinds) {
      for (const t of toKinds) {
        for (const rel of relKinds) {
          const matrix = traceabilityMatrix(model, f, t, rel);
          for (const r of matrix.rows) rows.set(r.id, r as ElementRef);
          for (const c of matrix.columns) columns.set(c.id, c as ElementRef);
          for (const l of matrix.links) links.set(`${l.relationshipId}|${l.from}|${l.to}`, l);
        }
      }
    }
    const rowList = [...rows.values()];
    const columnList = [...columns.values()];
    const linked = new Set([...links.values()].map((l) => `${l.from}|${l.to}`));

    const candidates = new Map<string, ElementRecord>();
    for (const kind of new Set([...fromKinds, ...toKinds])) {
      for (const el of model.ofKind(kind)) candidates.set(el.id, el);
    }
    const pool = [...candidates.values()];
    const libraryExcluded = pool.filter((el) => el.attrs.isLibrary === true).length;
    const implicitExcluded = pool.filter(
      (el) => el.attrs.isLibrary !== true && !isUserElement(model, el),
    ).length;
    const unresolvedTypings = countUnfollowedTypings(model, [...rows.keys(), ...columns.keys()]);

    const linkList: TraceLink[] = [...links.values()].map((l) => ({
      ...l,
      fromName: qname(model, l.from),
      toName: qname(model, l.to),
    }));

    return {
      relation,
      relationshipKinds: [...relKinds],
      fromKinds,
      toKinds,
      rows: rowList,
      columns: columnList,
      cells: rowList.map((r) => columnList.map((c) => linked.has(`${r.id}|${c.id}`))),
      links: linkList,
      unlinkedRows: rowList
        .filter((r) => !columnList.some((c) => linked.has(`${r.id}|${c.id}`)))
        .map(label),
      unlinkedColumns: columnList
        .filter((c) => !rowList.some((r) => linked.has(`${r.id}|${c.id}`)))
        .map(label),
      libraryExcluded,
      implicitExcluded,
      unresolvedTypings,
    };
  }

  connectivity(m: Loaded) {
    return connectivityReport(m.model);
  }

  orphans(m: Loaded) {
    return orphanReport(m.model);
  }

  stats(m: Loaded) {
    return modelMetrics(m.model);
  }

  requirements(m: Loaded, kind?: StatementKindFilter): RequirementsPayload {
    const model = m.model;
    const sat = requirementSatisfaction(model);
    const table = buildRequirementsTable(model);
    const status = new Map(sat.requirements.map((r) => [r.requirement.id, r]));

    const rows: RequirementRow[] = table.rows
      .filter((r) => {
        const el = model.get(r.id);
        return el !== undefined && isUserElement(model, el);
      })
      .map((r) => {
        const st = status.get(r.id);
        return {
          id: r.id,
          number: r.number,
          reqId: r.reqId,
          name: r.name || qname(model, r.id),
          metaclass: r.eClass,
          kind: statementKindOf(model, r.id),
          text: r.text,
          satisfied: st ? st.satisfied : null,
          satisfiedBy: st ? st.satisfiers.map(label) : r.refs.satisfiedBy.map((x) => x.label),
          verifiedBy: r.refs.verifiedBy.map((x) => x.label),
          refinedBy: r.refs.refinedBy.map((x) => x.label),
          tracedTo: r.refs.tracedTo.map((x) => x.label),
          derivedFrom: r.refs.derivedFrom.map((x) => x.label),
        };
      });
    const rowIds = new Set(rows.map((r) => r.id));
    for (const st of sat.requirements) {
      if (rowIds.has(st.requirement.id)) continue;
      rows.push({
        id: st.requirement.id,
        number: '',
        reqId: '',
        name: label(st.requirement as ElementRef),
        metaclass: st.requirement.eClass,
        kind: statementKindOf(model, st.requirement.id),
        text: '',
        satisfied: st.satisfied,
        satisfiedBy: st.satisfiers.map(label),
        verifiedBy: [],
        refinedBy: [],
        tracedTo: [],
        derivedFrom: [],
      });
    }

    const kept = kind ? rows.filter((r) => r.kind === kind) : rows;
    const counted = kept.filter((r) => r.satisfied !== null);
    return {
      total: kind ? counted.length : sat.total,
      satisfied: kind ? counted.filter((r) => r.satisfied === true).length : sat.satisfied,
      coverage: kind
        ? counted.length === 0
          ? 1
          : counted.filter((r) => r.satisfied === true).length / counted.length
        : sat.coverage,
      libraryExcluded: sat.libraryExcluded,
      implicitExcluded: sat.implicitExcluded,
      nonNormativeExcluded: rows.filter((r) => r.satisfied === null).length,
      kind: kind ?? null,
      rows: kept,
    };
  }

  reach(m: Loaded, scope?: string) {
    const scopeId = scope ? this.#resolve(m.model, scope).id : undefined;
    return reachReport(m.model, scopeId ? { scopeId } : {});
  }

  prompts(m: Loaded, ref: string) {
    return promptsFor(m.model, this.#resolve(m.model, ref).id);
  }

  whereUsed(m: Loaded, ref: string, depth = 1) {
    const report = impactClosure(m.model, this.#resolve(m.model, ref).id, depth);
    return { ...report, requestedDepth: depth };
  }

  verify(m: Loaded) {
    return verifyModel(m.model, { sourceText: m.text });
  }

  consistency(m: Loaded) {
    return consistencyReport(m.model, { sourceText: m.text });
  }

  refine(m: Loaded, via: 'composition' | 'derive' | 'refine' | 'all' = 'composition') {
    return refinementReport(m.model, { via, sourceText: m.text });
  }

  bounds(m: Loaded, measure: string, sense: 'min' | 'max' = 'max') {
    return boundsReport(m.model, { measure, sense, sourceText: m.text });
  }

  faultTree(m: Loaded) {
    return faultTreeReport(m.model, { sourceText: m.text });
  }

  evidenceStatus(m: Loaded) {
    return evidenceStatus(m.model);
  }

  behaviour(m: Loaded, machineId: string, pattern?: string) {
    return behaviourReport(m.model, { machineId, ...(pattern ? { pattern } : {}) });
  }

  /** The CLI's three-step narrowing: id, then the language's own resolution, then a unique suffix. */
  #resolve(model: Model, ref: string): ElementRecord {
    const byId = model.get(ref);
    if (byId) return byId;
    const byName = resolveFullName(model, ref, null);
    if (byName) return byName;
    const candidates = model.all().filter((el) => {
      if (!isUserElement(model, el)) return false;
      const qn = model.qualifiedName(el.id);
      return qn === ref || qn.endsWith(`::${ref}`) || el.declaredShortName === ref;
    });
    if (candidates.length === 1) return candidates[0];
    if (candidates.length === 0) {
      throw new ElementRefError(`no element matches \`${ref}\``);
    }
    throw new ElementRefError(
      `\`${ref}\` is ambiguous — ${candidates.length} elements match`,
      candidates.map((c) => qname(model, c.id)),
    );
  }
}

/** Nothing parsed: the report is the whole answer. */
export class NothingLoadedError extends Error {
  readonly report: CheckReport;
  constructor(displayName: string, report: CheckReport) {
    super(`nothing loaded from ${displayName}`);
    this.name = 'NothingLoadedError';
    this.report = report;
  }
}

function traceAxes(model: Model, relKinds: readonly string[]): { fromKinds: string[]; toKinds: string[] } {
  const edges = model.all().filter((el) => relKinds.includes(el.eClass) && isUserElement(model, el));
  const kindsOn = (end: 'source' | 'target'): string[] => {
    const seen: string[] = [];
    for (const e of edges) {
      for (const id of e[end] ?? []) {
        const k = model.get(id)?.eClass;
        if (k && !seen.includes(k)) seen.push(k);
      }
    }
    return seen;
  };
  return { fromKinds: kindsOn('source'), toKinds: kindsOn('target') };
}

/** Read a model file the way the CLI does, for callers that have a path. */
export const readModelFile = (path: string): string => readFileSync(path, 'utf8');
