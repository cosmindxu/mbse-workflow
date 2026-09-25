/**
 * The house rules (CV-01..CV-15) an authoring agent works under.
 *
 * They are not style: each one is where the approach's concept meets what
 * Sysprose actually accepts, measured probe by probe in
 * `mbse-approaches/03-sysprose-mapping/`. The rule text goes into the system
 * prompt of every step that names it, and a diagnostic code that has a rule
 * behind it (see `codes.ts`) carries the rule into the repair prompt.
 */
export interface Convention {
  id: string;
  title: string;
  rule: string;
}

export const CONVENTIONS: readonly Convention[] = [
  {
    id: 'CV-01',
    title: 'One file, one package per layer',
    rule: 'One .sysml file per model; one package per layer inside the root package (package OA { … }, package SA { … }). Cross-layer references use qualified names; shared definitions live in package Common. Sysprose has no cross-file import.',
  },
  {
    id: 'CV-02',
    title: 'Layer and kind tags are user-defined keywords',
    rule: 'Tags are bare metadata defs in package Kinds (metadata def OA;) applied as a #Kw prefix (#OA part def Authority;). Never invent a tag that package Kinds does not declare.',
  },
  {
    id: 'CV-03',
    title: 'Inter-layer realization',
    rule: 'Realization between layers is trace <lower> to <upper>;. Requirement refinement is refine <upper> by <lower>;, derivation is derive requirement <lower> from <upper>;. Never use dependency for realization.',
  },
  {
    id: 'CV-04',
    title: 'Function to structure allocation',
    rule: 'Allocation is the bare form: allocate <actionUsage> to <partUsage>;. There is no allocation def.',
  },
  {
    id: 'CV-05',
    title: 'Exchanges',
    rule: 'Functional exchange = flow <name> of <ItemDef> from <fn>.<outPort> to <fn>.<inPort>; between action usages that own directional ports. Component exchange = connection <name> connect <part>.<port> to <part>.<port>; (or interface <name> : <IfcDef> connect …). Physical link = a connection typed by a connection def. A link between two members of a population is a connection between two representatives, typed at PA by the connection def of the medium that carries it; the radio carrying it is a #Node part, never an actor.',
  },
  {
    id: 'CV-06',
    title: 'Hosting and deployment',
    rule: 'Hosting is nesting: the behaviour part is declared inside the node part. Add allocate behaviourPart to nodePart; only when nesting cannot express it (shared hosting).',
  },
  {
    id: 'CV-07',
    title: 'Modes versus states',
    rule: 'Two state defs per element, tagged #Mode and #State. Triggers are accept <event> : <ItemDef>; guards are if <expr>; effects are do action <name>. There is no after(n) time trigger and no guarded succession. There is no entry pseudostate: a machine opens at `initial start; transition start -> S;`, or without one at its first-declared state — never `entry;` or `transition entry -> S;`.',
  },
  {
    id: 'CV-08',
    title: 'Scenarios',
    rule: 'A scenario is an occurrence def holding ref part lifelines and message <m> of <Item> from <a> to <b>; in time order, or flow from a to b between actions. Combined fragments (loop/par/alt) are not representable — say it in doc. An exchange scenario between two members has two lifelines typed by the same member definition: ref part a : <Member>; ref part b : <Member>;.',
  },
  {
    id: 'CV-09',
    title: 'Requirements',
    rule: 'requirement def (or a requirement usage) with subject, assume constraint { … }, require constraint { … }, attribute id = "…", doc /* text */. Satisfaction is satisfy R by part;. Verification is verification def V { subject …; objective { verify R; } }. Statement kinds are #\'requirement\', #prose, #prompt. A requirement def and its usage are counted separately — satisfy both.',
  },
  {
    id: 'CV-10',
    title: 'Method guidance lives in the model',
    rule: 'Step guidance is a #prompt element with a doc, one per layer package, retrieved with prompts --element <Root>::<Layer>.',
  },
  {
    id: 'CV-11',
    title: 'Views and viewpoints',
    rule: 'concern def, viewpoint def { frame c : Concern; } and view def V { render asTreeDiagram; } are accepted. expose is not: state a view\'s scope in doc.',
  },
  {
    id: 'CV-12',
    title: 'Variability',
    rule: 'variation part x : T { variant part a : A; variant part b : B; } parses but is not reified — tag variants #Variant so elements and where-used can find them.',
  },
  {
    id: 'CV-13',
    title: 'Control nodes',
    rule: 'Declare control nodes bare (fork f; join j; decide d; merge m; initial i; done e;) and wire them with first a then f; succession f then b;. A guarded branch is if <cond> <target> else <target>;.',
  },
  {
    id: 'CV-14',
    title: 'Configuration items',
    rule: 'One part def per configuration item in package EPBS, tagged #CI_CSCI / #CI_HWCI / #CI_COTS, realising a PA part with trace ci to paPart;. Cardinality is multiplicity.',
  },
  {
    id: 'CV-15',
    title: 'Non-model artefacts',
    rule: 'A trade study, a rationale, a workshop output is a #prose part with a doc — or an analysis def with subject/return when a computation is meant.',
  },
  {
    id: 'CV-16',
    title: 'Populations (replicable elements)',
    rule: 'N identical members are ONE #Member part def — the replicable element — declaring out port meshOut : Common::<PeerPort>; in port meshIn : ~Common::<PeerPort>;. A fleet usage carries the count, part fleet : <Member> [N]; — never N named parts, never a multiplicity on the definition. An exchange between members is written between two named representatives, part memberA : <Member>; part memberB : <Member>;, joined by interface peerLink : Common::<PeerInterface> connect memberA.meshOut to memberB.meshIn;. Indexed ends (fleet[1].meshOut) do not parse, and a connection from a usage to itself is not a peer link. A function every member performs is allocated to the fleet; a function one member performs for the others — coordination, command and control — is allocated to a representative or to a ground component, and that allocation is the architecture decision. Members performing one activity are usages of one action def, and a coordination or command-and-control function is counted by that definition: on board when every usage sits on a member or the fleet. Fleet-level states are a #Configuration state def; each member keeps its own #Mode and #State.',
  },
  {
    id: 'CV-17',
    title: 'Measures and estimates',
    rule: 'A measure of effectiveness is one #MoE attribute in Common with a require constraint holding it to its target. Each architecture states what it achieves as #Estimate attribute <measure> :> Common::<measure> = <worst-case value> { doc /* the basis */ } at the level of its layer. The estimate is what the trade-off bounds: a require clause is not a fact, and a value on a subsetting attribute is not a value on Common\'s, so bounding the Common name decides nothing. Where the brief fixes the numbers a measure follows from, derive it instead of stating it: restate those numbers as valued attributes of this layer (a constraint body cannot reach Common), leave the #Estimate without a literal, and fix it with assert constraint { <measure> == <expression over them> }. The solver then finds one value both ways, and the trade-off shows it as derived. One case of this is checked and blocks: a share the measure\'s own definition says holds at any moment cannot exceed the share of the population that is airborne at any moment, which the brief fixes as flight / (flight + recharge). An architecture whose members each cover more than their share may say so \u2014 state the per-member coverage as a valued attribute and derive the measure from it \u2014 but it may not simply state a larger number, because that is a claim the brief\'s own budgets contradict.',
  },
  {
    id: 'CV-18',
    title: 'Rules the system never breaks',
    rule: 'A rule the brief says the system never breaks is a #Rule requirement stated once at SA, satisfied by the part whose state machine carries it, and carried from SA down inside that state def as @SysproseVerification::PropertyPattern { doc /* <RuleName>: … */ attribute pattern = "…"; attribute scope = "…"; attribute p = "state …"; } — the doc names the rule, no other attribute is allowed. Three kinds: wins-until is pattern absence, scope between, q the state that starts it, r the state that ends it, p the state that must not hold; preceded-by is pattern precedence, scope globally, s the state that comes first, p the one that follows; can-always-return is pattern recovery, scope globally, p the state reachable from everywhere. "After Q never P" fails on a machine that returns to P after landing, so wins-until is between; a plain "never P" needs a state that exists and is never reached, which reachability forbids. Existence and response are never used: the checker cannot decide them.',
  },
  {
    id: 'CV-19',
    title: 'What the brief fixes by name',
    rule: 'Hazards, modes and items the brief names keep the brief\'s names. A brief hazard is a #Hazard requirement of that name in SA::Hazards, stated once and satisfied below by path (satisfy SA::Hazards::X by <part>) — never restated at LA or PA. A brief mode is a state of that name in a state def of its owner: the #Member def for a member, the fleet usage or a #Configuration machine for the fleet, a ground component for the ground. An item whose fields the brief lists is an item def in Common with exactly those attributes, each with a doc.',
  },
];

const BY_ID = new Map(CONVENTIONS.map((c) => [c.id, c]));

export const convention = (id: string): Convention | undefined => BY_ID.get(id);

export const conventionsFor = (ids: readonly string[]): Convention[] =>
  ids.map((id) => BY_ID.get(id)).filter((c): c is Convention => c !== undefined);
