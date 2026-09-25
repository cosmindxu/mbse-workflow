/**
 * A layer, as the transition rules need to see it.
 *
 * Not a report: the published payloads drop exactly what a transition needs —
 * relationships are reported through the elements they attach to, so a flow's
 * item and a parameter's direction are not in them. The model itself has both,
 * and the transitions run in process, so they read it.
 */
import type { ElementRecord, Model } from '@core/index';
import type { Layer } from '../spec/layers.ts';

export interface ParamView {
  name: string;
  direction?: 'in' | 'out' | 'inout';
  /** Type reference as it should be written from inside the root package. */
  type?: string;
}

/** Elements this project writes for its own bookkeeping, never carried down. */
export const isBookkeeping = (keywords: readonly string[]): boolean =>
  keywords.includes('prompt') || keywords.includes('prose');

export interface ActionView {
  name: string;
  qualifiedName: string;
  /** The action definition this usage is typed by, as a reference. */
  def?: string;
  defName?: string;
  doc?: string;
  params: ParamView[];
  keywords: string[];
  /** Tags on the definition: an OA author tags `#Coordination action def X`, not its usages. */
  defKeywords?: string[];
  /** Parameters declared on the definition, which every usage of it has without restating them. */
  defParams?: ParamView[];
}

export interface PartView {
  name: string;
  qualifiedName: string;
  def?: string;
  defName?: string;
  doc?: string;
  isActor: boolean;
  ports: ParamView[];
  keywords: string[];
  /** As written, e.g. `12` or `2..*`; absent for a single usage. */
  multiplicity?: string;
}

export interface PartDefView {
  name: string;
  qualifiedName: string;
  isActor: boolean;
  ports: ParamView[];
  doc?: string;
  keywords: string[];
}

export interface FlowView {
  name?: string;
  /** The item the flow carries, as written. */
  payload?: string;
  /** `action.port`, relative to the layer package. */
  from?: string;
  to?: string;
}

/**
 * A connection or interface usage, with the ends it joins.
 *
 * Needed to tell a peer link between two members from anything else: the
 * published connectivity payload lifts ends to declared ports, so
 * `memberA.meshOut` and `memberB.meshOut` both read as `Member::meshOut`.
 * The model keeps the usage path, and this reads it.
 */
export interface ConnectionView {
  name?: string;
  /** Simple name of the connection or interface definition, when typed. */
  type?: string;
  /** `usage::port`, relative to the layer package. */
  from?: string;
  to?: string;
  metaclass: 'ConnectionUsage' | 'InterfaceUsage';
}

export interface SuccessionView {
  from?: string;
  to?: string;
}

export interface UseCaseView {
  name: string;
  qualifiedName: string;
  subjectType?: string;
  doc?: string;
  keywords: string[];
}

export interface StateDefView {
  name: string;
  qualifiedName: string;
  keywords: string[];
  doc?: string;
}

export interface AllocationView {
  /** Qualified name of the action. */
  action: string;
  actionName: string;
  /** Qualified name of the part. */
  part: string;
  partName: string;
}

export interface LayerView {
  root: string;
  layer: Layer;
  actions: ActionView[];
  parts: PartView[];
  partDefs: PartDefView[];
  useCases: UseCaseView[];
  states: StateDefView[];
  flows: FlowView[];
  connections: ConnectionView[];
  successions: SuccessionView[];
  allocations: AllocationView[];
}

/* ─────────────────────────────── extraction ─────────────────────────────── */

const docOf = (model: Model, el: ElementRecord): string | undefined => {
  const doc = model.children(el.id).find((c) => c.eClass === 'Documentation');
  const body = doc?.attrs.body;
  return typeof body === 'string' ? body : undefined;
};



export function buildLayerView(
  model: Model,
  root: string,
  layer: Layer,
  actorDefNames: Set<string>,
  keywordsAt: (qualifiedName: string) => string[],
): LayerView {
  const pkg = model.resolveQualifiedName(`${root}::${layer}`);
  const view: LayerView = {
    root,
    layer,
    actions: [],
    parts: [],
    partDefs: [],
    useCases: [],
    states: [],
    flows: [],
    connections: [],
    successions: [],
    allocations: [],
  };
  if (!pkg) return view;

  const keywordsOf = (el: ElementRecord): string[] => keywordsAt(model.qualifiedName(el.id));

  /** A type reference that resolves from anywhere inside the root package. */
  const typeRef = (el: ElementRecord): string | undefined => {
    const type = model.typesOf(el.id)[0];
    if (!type) return undefined;
    const qn = model.qualifiedName(type.id);
    return qn.startsWith(`${root}::`) ? qn.slice(root.length + 2) : qn;
  };
  const localName = (id: string): string => {
    const qn = model.qualifiedName(id);
    const at = `${root}::${layer}::`;
    return qn.startsWith(at) ? qn.slice(at.length) : qn;
  };
  /**
   * A flow's end, as a flow may name it.
   *
   * Everything below the layer on this path is a usage, and a path through
   * usages is a feature chain — written with dots. A qualified name resolves
   * to one element, so `a::b::c` on a flow end is a connector with a single
   * endpoint, which is what the checker then says it is. v7 never showed this
   * because its ends were two segments, where the qualified name happens to
   * resolve; v8 put an activity inside an actor's part and the third segment
   * stopped resolving. The dots are correct in both.
   */
  const endName = (id: string): string => localName(id).split('::').join('.');
  // `in item x : T;` is an ItemUsage with a direction, and is as much a
  // parameter as `in x : T;`. Measured: v5's OA declared every parameter that
  // way, on the definitions, and T-01 carried none — 15 flows lost both ends.
  const featuresOf = (el: ElementRecord): ParamView[] =>
    model
      .children(el.id)
      .filter((c) => c.eClass === 'PortUsage' || c.eClass === 'ReferenceUsage' || (c.eClass === 'ItemUsage' && !!c.attrs.direction))
      .filter((c) => c.declaredName)
      .map((c) => ({
        name: c.declaredName as string,
        direction: c.attrs.direction as ParamView['direction'],
        type: typeRef(c),
      }));

  for (const el of model.children(pkg.id)) {
    const name = el.declaredName;
    switch (el.eClass) {
      case 'ActionUsage': {
        if (!name) break;
        const type = model.typesOf(el.id)[0];
        view.actions.push({
          name,
          qualifiedName: model.qualifiedName(el.id),
          def: type ? typeRef(el) : undefined,
          defName: type?.declaredName,
          doc: docOf(model, el),
          params: featuresOf(el),
          keywords: keywordsOf(el),
          defKeywords: type ? keywordsAt(model.qualifiedName(type.id)) : [],
          defParams: type ? featuresOf(type) : [],
        });
        break;
      }
      case 'PartUsage': {
        if (!name) break;
        const type = model.typesOf(el.id)[0];
        view.parts.push({
          name,
          qualifiedName: model.qualifiedName(el.id),
          def: typeRef(el),
          defName: type?.declaredName,
          doc: docOf(model, el),
          isActor: type ? actorDefNames.has(model.qualifiedName(type.id)) : false,
          ports: featuresOf(el),
          keywords: keywordsOf(el),
          multiplicity: typeof el.attrs.multiplicity === 'string' ? el.attrs.multiplicity : undefined,
        });
        break;
      }
      case 'PartDefinition': {
        if (!name) break;
        view.partDefs.push({
          name,
          qualifiedName: model.qualifiedName(el.id),
          isActor: actorDefNames.has(model.qualifiedName(el.id)),
          ports: featuresOf(el),
          doc: docOf(model, el),
          keywords: keywordsOf(el),
        });
        break;
      }
      case 'UseCaseDefinition': {
        if (!name) break;
        const subject = model.children(el.id).find((c) => c.attrs.requirementRole === 'subject');
        view.useCases.push({
          name,
          qualifiedName: model.qualifiedName(el.id),
          subjectType: subject ? typeRef(subject) : undefined,
          doc: docOf(model, el),
          keywords: keywordsOf(el),
        });
        break;
      }
      case 'StateDefinition': {
        if (!name) break;
        view.states.push({
          name,
          qualifiedName: model.qualifiedName(el.id),
          keywords: keywordsOf(el),
          doc: docOf(model, el),
        });
        break;
      }
      case 'Flow': {
        view.flows.push({
          name: name ?? undefined,
          payload: typeof el.attrs.payload === 'string' ? el.attrs.payload : undefined,
          from: el.source?.[0] ? endName(el.source[0]) : undefined,
          to: el.target?.[0] ? endName(el.target[0]) : undefined,
        });
        break;
      }
      case 'ConnectionUsage':
      case 'InterfaceUsage': {
        view.connections.push({
          name: name ?? undefined,
          type: model.typesOf(el.id)[0]?.declaredName ?? undefined,
          from: el.source?.[0] ? localName(el.source[0]) : undefined,
          to: el.target?.[0] ? localName(el.target[0]) : undefined,
          metaclass: el.eClass,
        });
        break;
      }
      case 'Succession':
      case 'SuccessionAsUsage': {
        view.successions.push({
          from: el.source?.[0] ? localName(el.source[0]) : undefined,
          to: el.target?.[0] ? localName(el.target[0]) : undefined,
        });
        break;
      }
      case 'Allocation': {
        const from = el.source?.[0];
        const to = el.target?.[0];
        if (!from || !to) break;
        view.allocations.push({
          action: model.qualifiedName(from),
          actionName: localName(from),
          part: model.qualifiedName(to),
          partName: localName(to),
        });
        break;
      }
      default:
        break;
    }
  }
  return view;
}
