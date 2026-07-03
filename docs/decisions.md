# Overnet Design Decisions

This document records significant design decisions made during the development of the Overnet specification family.

## D001: Use a Small Kind Range Instead of a Single Kind

**Date:** 2026-04-10

**Decision:** Overnet uses three Nostr event kinds rather than a single kind.

- Kind 7800 (Overnet Event) — regular, for immutable event log entries
- Kind 37800 (Overnet State) — parameterized replaceable, for single-author object state
- Kind 7801 (Overnet Removal) — regular, for tombstones

**Alternatives considered:**

- Single regular kind for all Overnet events, with event_type in content distinguishing them. Simpler, but cannot leverage Nostr's built-in replaceable event behavior.
- Large kind range with a separate kind per Overnet event type. Too many kinds to register and coordinate, splits semantics across two layers.

**Rationale:** Some Overnet objects have state owned by a single pubkey (profiles, adapter mappings) where parameterized replaceable behavior from NIP-01 relays is directly useful. Other objects accumulate events from multiple pubkeys (collaborative documents, issue trackers) where replaceability does not apply. A small kind range gives us both behaviors without excessive complexity. Removal gets its own kind so relays can handle tombstones distinctly at the storage layer.

## D002: Overnet-Prefixed Tag Names

**Date:** 2026-04-10

**Decision:** Overnet-specific Nostr tags use the `overnet_` prefix (e.g., `overnet_v`, `overnet_et`, `overnet_ot`, `overnet_oid`).

**Alternatives considered:**

- Single-letter tags (e.g., `v`, `t`, `o`, `O`). Shorter, but single-letter tags are scarce in Nostr and some are already claimed (e.g., `t` is hashtags). Collision risk with future NIPs.
- Shorter prefix (e.g., `ov_`). Marginally shorter but less readable and less obviously namespaced.

**Rationale:** The `overnet_` prefix eliminates collision risk with Nostr core tags and other protocols. NIP-01 relays can filter on any tag name, so longer names have no performance disadvantage. Clarity and collision safety are worth the extra bytes.

## D003: Tags for Filtering, Content for Payload

**Date:** 2026-04-10

**Decision:** Fields that relays need to filter on (version, event type, object type, object ID) go in Nostr tags. Structured data only needed after retrieval (provenance, profile-specific payload) goes in the JSON content body. No field is duplicated across both locations.

**Alternatives considered:**

- Everything in content JSON, no custom tags. Relays cannot filter without parsing content.
- Duplicate key fields in both tags and content for convenience. Creates a class of bugs where tags and content disagree.

**Rationale:** Nostr relays filter on tags efficiently. Putting indexable fields in tags means even non-Overnet-aware relays can serve useful queries. The "one authoritative location" rule avoids inconsistency.

## D004: Content JSON Uses body Wrapper for Profile Data

**Date:** 2026-04-10

**Decision:** The content JSON has two top-level keys: `provenance` (core-defined) and `body` (profile-defined payload). Profiles MUST NOT add fields at the top level.

**Alternatives considered:**

- Flat structure where profile fields are alongside provenance at the top level. Simpler, but creates collision risk between profiles and future core fields.

**Rationale:** The `body` wrapper cleanly separates the core envelope from profile-specific data. The cost is one extra key. The benefit is that core and profile namespaces can never collide.

## D005: Provenance Structure

**Date:** 2026-04-10

**Decision:** Provenance is a required JSON object in content with `type` ("native" or "adapted"). Adapted provenance additionally requires `protocol`, `origin`, and `limitations`. The `external_identity` field is required when the event is attributable to a specific external actor.

**Alternatives considered:**

- Provenance in tags. Too complex and structured for tag representation.
- Minimal provenance (just native/adapted flag). Insufficient for clients to evaluate trust of adapted data.

**Rationale:** Clients need to know where data came from and what was lost in translation. The adapter's Nostr pubkey is already on the event; the provenance struct adds the external system details.

## D006: Core Limitation Identifier Registry

**Date:** 2026-04-10

**Decision:** The core defines a base set of limitation identifiers (unsigned, no_edit_history, lossy, delayed, synthetic_identity, partial). Adapter specs extend this with namespaced identifiers.

**Alternatives considered:**

- Free-form strings with no registry. Leads to inconsistency across adapters.
- Adapter-only registries with no core set. Clients cannot display trust indicators consistently across adapter types.

**Rationale:** A small core set ensures consistent vocabulary for the most common translation limitations. Namespaced extensions allow adapters to express protocol-specific limitations without polluting the core set.

## D007: Object IDs Are Globally Unique, Format Defined by Profiles

**Date:** 2026-04-10

**Decision:** Object IDs must be globally unique non-empty strings. The core does not mandate a format. Profiles define ID schemes for their object types and are responsible for structural uniqueness (e.g., UUIDs, content-addressed hashes, protocol-scoped identifiers).

**Alternatives considered:**

- Core-mandated UUID format. Would force synthetic IDs on adapted objects that already have natural identifiers.
- Global object ID registry. Antithetical to decentralization; cannot require a central registry when anyone can self-host.
- Type-scoped IDs (only unique within object type). Requires embedding type in ID or always querying with type, adds complexity.

**Rationale:** Different object types have different natural identifiers. Adapted objects should be able to use identifiers derived from their origin system. Global uniqueness is ensured structurally by profile-defined schemes, not by a central registry.

## D008: Semver for Core Version Identifier

**Date:** 2026-04-10

**Decision:** The core specification version is a semver string (e.g., "0.1.0"). The current draft version is "0.1.0".

**Alternatives considered:**

- Simple integer. Easy to compare but provides no signal about breaking vs. non-breaking changes.
- Date-based (e.g., "2026-04"). Unambiguous ordering but no semantic meaning.

**Rationale:** Semver is widely understood and communicates the nature of changes. The 0.x range signals pre-stability. Breaking changes bump the major version.

## D009: Delegation Uses Separate Events and Object-Scoped Removal Grants

**Date:** 2026-04-13

**Decision:** The baseline core delegation mechanism uses separate Overnet events with `overnet_et` value `core.delegation`. A delegation applies to exactly one object, authorizes only the `remove` action, and is referenced from a delegated removal by a dedicated `overnet_delegate` tag.

**Alternatives considered:**

- Inline delegation material inside removal events. Simpler one-shot validation, but duplicates grant data and makes reuse, auditability, and later revocation harder.
- Broader delegation scopes such as object-type-wide or profile-wide grants. More operationally convenient, but too much authority for the first baseline mechanism.
- Event-scoped grants. Precise, but too narrow to be useful as a baseline moderation/administration primitive.

**Rationale:** Separate delegation events fit the event-oriented model, keep grants auditable, and leave room for later revocation and richer scope models. Object-scoped grants are narrow enough for a safe first version while still being useful. A dedicated `overnet_delegate` tag avoids ambiguity with the `e` tag already used to identify the target event being removed.

## D010: Relay Semantics Use a Nostr-Native Generic Relay Baseline with Optional Profiles

**Date:** 2026-04-14

**Decision:** Overnet relay semantics are defined in a companion relay specification that keeps the baseline relay role Nostr-native for event publication, event queries, and event subscriptions, while allowing optional advertised profiles for storage, replication, pricing, and related operator policy.

The first relay companion specification covers:

- generic relay metadata
- event publication
- a narrow event query filter surface
- replay-plus-live subscriptions
- a narrow by-reference derived-object read surface

The first relay companion specification does not attempt to define the full storage and replication model. Large-data distribution is expected to be addressed later, potentially by reusing NIP-35 rather than inventing a separate torrent metadata format.

**Alternatives considered:**

- Put all relay, storage, replication, and pricing semantics into one first relay specification. Too much scope for a first concrete relay draft.
- Define a new Overnet-specific relay transport immediately. Unnecessary protocol sprawl while Overnet remains Nostr-native.
- Define only raw event relay behavior and defer derived objects entirely. Too weak for the baseline generic relay role already chosen for Overnet.

**Rationale:** A generic relay needs to be useful immediately without forcing every volunteer-operated relay to become a full archive or large-object storage node. Keeping the first relay companion specification narrow makes it implementable and testable. Keeping event publication and subscription behavior Nostr-native preserves alignment with the Overnet core and with existing Nostr infrastructure. Optional profiles leave room for volunteer, archive, paid, and storage-heavy relay roles without overloading the baseline.

## D011: Relay-Carried Private Direct Messages Use NIP-17 Rather Than Public Overnet Core Events

**Date:** 2026-04-14

**Decision:** One-to-one relay-carried private direct messages use `NIP-17` encrypted transport rather than ordinary public Overnet core events.

The logical Overnet item types remain `chat.dm_message` and `chat.dm_notice`, but when those items are intended to remain private from generic relay operators:

- the logical message is represented as a kind `14` rumor
- the rumor is sealed and gift-wrapped according to `NIP-17`
- the relay-visible event is kind `1059`
- the decrypted payload carries the Overnet logical fields needed to recover `chat.dm` semantics

`NIP-04` is not part of the Overnet private direct-message profile.

**Alternatives considered:**

- Publish direct-message bodies as ordinary public kind `7800` Overnet core events. Simpler, but defeats relay-level privacy.
- Define a custom Overnet encrypted direct-message transport unrelated to existing Nostr private-message work. Unnecessary duplication and weaker ecosystem alignment.
- Continue treating all direct messages as local-only semantics with no relay-carried private transport. Too limiting once direct messages need to cross relay or instance boundaries.

**Rationale:** The Overnet core event model is intentionally public and relay-queryable. Private direct messages have different requirements. Using `NIP-17` keeps Overnet aligned with existing Nostr private-messaging mechanisms while preserving Overnet application semantics in the decrypted payload. It also lets generic relays store and forward opaque encrypted messages without pretending they can derive public objects or inspect private content.

## D012: Companion Specifications Prefer Existing NIPs Over New Overnet-Specific Semantics

**Date:** 2026-04-15

**Decision:** Overnet companion specifications SHOULD reuse existing Nostr NIPs where they are semantically adequate for the required behavior.

Overnet-specific semantics SHOULD be defined only when existing NIPs are insufficient, misleading, or incompatible with required Overnet invariants. When a companion specification chooses not to reuse a relevant existing NIP, it SHOULD explain that choice explicitly.

**Alternatives considered:**

- Treat each companion specification as free to define new Overnet-specific semantics whenever that seems convenient. Too much protocol sprawl and too little ecosystem reuse.
- Require reuse of every potentially relevant existing NIP. Too rigid when an existing NIP is too loose, too differently scoped, or otherwise a poor fit for the invariants Overnet needs.

**Rationale:** Overnet is intended to build on Nostr, not to shadow it with a parallel specification stack. Reusing existing NIPs where they already solve the problem keeps Overnet aligned with the wider ecosystem, reduces duplication, and makes companion specifications easier to justify and review. Making the rule preference-based rather than absolute preserves room for narrower profiles, stricter mappings, and genuinely new semantics when existing NIPs do not provide the required guarantees.

## D013: UTF-8 Is Required for Textual Protocol Elements

**Date:** 2026-06-25

**Decision:** Overnet textual protocol elements are Unicode scalar values encoded as UTF-8. Implementations reject malformed UTF-8 at protocol boundaries. Binary data uses explicitly typed binary forms rather than alternate text encodings.

**Alternatives considered:**

- Permit implementation-defined text encodings. This preserves compatibility with legacy systems, but makes interoperation ambiguous and pushes encoding bugs into application logic.
- Let adapter specifications define their own text encodings. This fits some external protocols, but creates different text models for different Overnet surfaces and weakens the core interoperability contract.
- Treat text fields as arbitrary byte strings. This avoids early decoding failures, but makes display, comparison, signatures, validation, and bridge behavior less predictable.

**Rationale:** A single required text encoding gives clients, relays, adapters, and runtimes one shared interpretation of protocol text. UTF-8 is already the natural encoding for JSON-based Overnet protocol surfaces and for Nostr-compatible event data. Requiring explicit binary forms keeps opaque bytes possible without letting ambiguous byte strings masquerade as text.

## D014: Profile Contracts Describe Profile Semantics Without Replacing Core Events

**Date:** 2026-06-27

**Decision:** Overnet defines an optional Profile Contract format for machine-readable profile semantics. A profile contract describes object types, event types, payload schemas, references, authorization metadata, privacy expectations, capabilities, and fixtures for a profile. It does not replace the Nostr event as the canonical signed wire unit, and it does not replace the Overnet core event envelope.

Profile contracts are decentralized. Standard Overnet profiles may publish contracts under namespaces reserved by the Overnet specification family. Applications and adapters may publish their own contracts under namespaces they control.

**Alternatives considered:**

- No machine-readable profile contract. This keeps the spec simpler, but leaves validators, adapters, clients, and scale-test tools to hardcode profile semantics or parse prose.
- JSON Schema only for `content.body`. This helps payload validation, but it cannot describe event kinds, object types, required tags, references, capabilities, privacy expectations, authorization metadata, fixtures, or state derivation.
- A centralized universal application schema. This makes tooling easier in the narrow case, but it turns Overnet into a schema committee and conflicts with decentralization and application sovereignty.

**Rationale:** The core defines the universal envelope. Profiles define profile-specific meaning. A small contract format gives tools a stable automation surface without requiring Overnet to define every possible application type. This is especially important for conformance validators, adapters, and automated test systems, which can use contracts to generate realistic workloads and report profile-aware results.

## D015: Profile Contracts Compose Through Explicit Dependencies

**Date:** 2026-06-27

**Decision:** Profile Contract v1 supports composition by loading multiple independent contracts as a contract set. A contract may declare explicit profile dependencies in `depends_on`, and reference declarations may target object or event types from those dependency profiles.

Profile Contract v1 does not support inheritance, mixins, imports, overrides, or mutation of definitions from another contract. Each contract owns only its own namespace. Cross-contract references are valid only when covered by an explicit dependency declaration and resolved by the selected contract set.

Contract set validation rejects duplicate profile entries, missing dependency contracts, dependency contracts whose `profile_version` does not satisfy the declared version requirement, and external reference targets that do not exist in the resolved dependency contract.

**Alternatives considered:**

- No composition. Simpler, but forces every useful application contract to duplicate identity, authorization, storage, payment, or moderation semantics.
- Inheritance or mixins. More expressive, but turns profile contracts into a schema programming language too early.
- Implicit cross-profile references. Convenient in small examples, but makes validation dependent on ambient knowledge and weakens automation.

**Rationale:** Explicit dependency-based composition gives validators, adapters, clients, and automated test systems a deterministic way to load related profile semantics without centralizing all application behavior or allowing one contract to rewrite another contract's meaning. Keeping V1 limited to explicit references leaves room for later extension without committing to inheritance semantics now.

## D016: One Namespaced Error Code Vocabulary Across Companion Protocols

**Date:** 2026-07-02

**Decision:** All request/response protocols in the specification family that reuse the Overnet Program Protocol envelope share one error code convention. Envelope-level failures use the shared `protocol.` baseline codes defined in the Program Protocol specification, section 8. Domain-specific failures use a protocol-specific namespace prefix: `runtime.` and `program.` for the program protocol, `auth.` for the auth-agent protocol. The auth-agent protocol's original bare codes (`invalid_request`, `policy_denied`, and the rest) are replaced: `invalid_request` splits into the applicable `protocol.` codes, and the auth-domain codes gain the `auth.` prefix.

**Alternatives considered:**

- Keep separate vocabularies per protocol. No migration cost, but the two vocabularies were already drifting apart, and every consumer that handles both surfaces has to maintain a mapping.
- Namespace all auth codes under `auth.` including envelope failures (e.g., `auth.invalid_request`). Keeps one prefix per protocol, but hides the fact that envelope-level failures are the same failure across protocols and would leave `invalid_request` conflating malformed envelopes, unknown methods, and malformed params.
- A single flat shared list without namespaces. Smallest codes, but collision-prone as companion protocols add domain codes.

**Rationale:** Envelope handling is implemented once (shared framing, shared error object), so envelope-level errors should have exactly one name across protocols. Namespacing domain codes by protocol keeps each protocol free to evolve its own vocabulary without collisions while remaining self-describing in logs and tests. Splitting `invalid_request` also restores information the auth protocol was discarding: unknown methods and malformed params are distinguishable failure classes in the program protocol and become so in the auth-agent protocol.

## D017: Runtime Diagnostics Are an Opt-In Runtime Contract

**Date:** 2026-07-03

**Decision:** The Overnet Program Runtime specification defines runtime diagnostics as an optional, opt-in runtime contract for command and service execution. Diagnostics are runtime-generated diagnostic records, not Nostr events, not Overnet events, and not baseline program protocol messages.

When a runtime implements diagnostics, the default diagnostic facility is safe by construction: it must not change operation behavior, diagnostic sink failures must not fail the operation, and default diagnostic records must not include request parameters, response results, secrets, auth artifacts, bearer tokens, message bodies, decrypted private-message content, or structured error details.

**Alternatives considered:**

- Leave diagnostics entirely implementation-local. This avoids specification work, but it lets runtime implementations drift on privacy and failure semantics.
- Define diagnostics as baseline program protocol notifications. This makes diagnostics portable, but it exposes runtime-internal operational data to supervised programs and couples diagnostics to one transport too early.
- Define a mandatory observability subsystem. This overconstrains implementations before deployment and operator needs are better understood.

**Rationale:** Applications should be able to get useful runtime diagnostics without hand-instrumenting every service path, but diagnostics are dangerous if they leak payloads or change behavior. Making diagnostics opt-in and implementation-defined at the sink/transport layer preserves implementation freedom while giving all runtimes one safety contract.
