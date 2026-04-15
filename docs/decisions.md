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
