# Overnet Core Specification

## Status of This Document

This document defines the Overnet core protocol and platform architecture.

It is the foundational specification in a broader Overnet specification family. Additional Overnet specifications are expected to define adapter behavior, application profiles, Overnet program runtime behavior, storage profiles, operational guidance, registries, and other extensions built on top of this core.

This document uses the key words MUST, MUST NOT, REQUIRED, SHALL, SHALL NOT, SHOULD, SHOULD NOT, RECOMMENDED, NOT RECOMMENDED, MAY, and OPTIONAL as described in BCP 14.

This document distinguishes between:

- normative sections, which define required behavior
- informative sections, which provide guidance, rationale, or examples

## Companion Specifications

This document defines only the Overnet core.

The following companion specifications are especially relevant to the current draft:

- [Overnet Relay Specification](relay.md), which defines the first concrete relay metadata, query, subscription, and derived-object read surface
- [Overnet Private Messaging Specification](private-messaging.md), which defines encrypted relay-carried private direct messaging
- [Overnet Program Runtime Specification](programs/runtime.md), which defines the runtime/program boundary for runnable Overnet programs
- [Overnet Program Protocol Specification](programs/protocol.md), which defines the framed program/runtime wire protocol
- [Overnet Program Services Specification](programs/services.md), which defines the baseline runtime-managed service methods
- [IRC Adapter Specification](adapters/irc.md), which defines the first concrete adapter mapping

Companion specifications MAY define additional normative requirements for adapters, application profiles, storage or replication profiles, registries, and operational guidance.

## 1. Introduction

### 1.1 What This Document Defines

This document defines the Overnet core specification.

Overnet is a higher-level protocol and application platform for building networked systems such as chat, email, code hosting, marketplaces, and websites.

Overnet is built on top of Nostr. It uses Nostr as an underlying decentralized event distribution substrate while defining a higher-level application model above it. In that sense, Overnet is not a replacement for Nostr, but a system built on Nostr that adds stronger application-level structure for identity, signed operations, object and event exchange, capability discovery, interoperability, and platform semantics.

This document is intentionally limited to the Overnet core. It defines the stable shared semantics that other Overnet specifications will build upon. Those future specifications are expected to cover areas such as protocol adapters, application profiles, Overnet program runtime behavior, storage profiles, operational guidance, and other specialized or domain-specific behavior.

It is intended to provide a common application-facing model above lower-level transports, storage systems, and existing protocols. Rather than forcing every application to directly integrate with every underlying protocol or service, Overnet defines a stable core model for identity, signed operations, object and event exchange, capability discovery, and interoperability.

Overnet is not a single website, a single hosted platform, or a single relay implementation. It is a protocol and platform architecture that can be implemented by different operators, applications, and infrastructure providers. A deployment may be small and self-hosted, large and multi-tenant, or specialized for a particular class of applications.

Overnet is also not limited to purely native applications. A central goal of the platform is to make adapters first-class components rather than afterthoughts. Existing systems such as IRC, email, code hosting platforms, and Nostr-based systems should be able to participate through explicit, auditable translation layers instead of ad hoc one-off integrations.

### 1.2 Why Overnet Exists

Many important networked applications are currently fragmented across isolated protocols, hosted platforms, and incompatible trust models. Chat lives in one set of systems, email in another, code hosting in another, and websites in yet another. Even when those systems are open in some sense, they usually expose different identity models, different security assumptions, different extension points, and different deployment expectations.

This fragmentation creates several recurring problems:

- application developers must repeatedly solve the same integration and interoperability problems
- users become dependent on specific hosted platforms or protocol silos
- operators often have poor control over the full stack they are running
- bridges between systems are usually fragile, lossy, and poorly specified
- security and provenance are often weakened once data crosses protocol boundaries
- building a new application category often means reinventing identity, messaging, storage, and policy layers from scratch

Overnet is being created to address these problems by defining a reusable core that can support many classes of applications while still allowing independent operators, independent implementations, and integration with existing systems.

The goal is not to replace every existing protocol overnight, nor to pretend all systems are identical. The goal is to define a coherent higher-level model that can sit above existing protocols and services where useful, support native Overnet applications where appropriate, and make translation between systems explicit, inspectable, and predictable.

### 1.3 The Basic Idea

The basic idea behind Overnet is that many application domains share a common set of needs:

- identities that can authenticate and authorize actions
- signed and auditable operations
- exchange of objects, events, and references
- subscriptions, querying, and state synchronization
- capability negotiation between clients and servers
- policy enforcement by operators
- extensibility without breaking interoperability

Instead of rebuilding these concerns separately for every application domain, Overnet defines them once at the platform layer.

Applications built on Overnet should be able to rely on a stable core model even when the underlying deployment differs. One deployment might store data locally, another might replicate across relays, and another might expose adapter-backed views of external services. The application should not need to be tightly coupled to each of those implementation details.

This allows Overnet to function both as a native application substrate and as an interoperability layer.

### 1.4 Relationship to Existing Protocols and Services

Overnet is designed to coexist with existing protocols and services rather than assuming a blank-slate network.

Some systems are already distributed by nature. Others are widely deployed and difficult to replace. Others still provide user communities, archives, or workflows that remain valuable. For these reasons, Overnet treats adapters as part of the architecture.

As a general design rule, Overnet companion specifications SHOULD reuse existing Nostr NIPs where they are semantically adequate for the required behavior. Overnet-specific semantics SHOULD be defined only when existing NIPs are insufficient, misleading, or incompatible with required Overnet invariants. When a companion specification chooses not to reuse a relevant existing NIP, it SHOULD explain that choice explicitly.

An adapter may expose external systems through Overnet semantics by mapping identities, objects, events, permissions, and errors into the Overnet model. Some adapters are protocol bridges that provide ongoing interoperability between systems. That mapping must be explicit. Where translation is lossy, synthetic, delayed, partial, or security-sensitive, the implementation must expose that fact rather than hiding it.

This design is important for two reasons. First, it reduces the amount of migration required to make Overnet useful. Second, it allows applications and operators to reason about provenance and trust when information originates outside a native Overnet environment.

### 1.5 What Overnet Is Not

Overnet is not:

- a requirement to use one transport, one database, one deployment model, or one operator
- a mandate that every relay implement every feature or every adapter
- a claim that all adapted systems can be represented without loss
- a UI specification or product design guide, except where user-facing behavior is necessary for security or interoperability
- a replacement for careful protocol-specific design in adapter profiles

The core specification intentionally stays smaller than the total set of possible applications built on it.

### 1.6 Freedom, Decentralization, and Design Objectives

Overnet is intended to support a computing model that values software freedom, decentralization, self-hostability, operator choice, and user control.

The system is designed around the idea that important network services should not depend on a single provider, a single mandatory implementation, or a single point of policy control. Users and operators should be able to run their own infrastructure, inspect implementations, choose which capabilities to support, and participate in a wider network without asking permission from a central authority.

Building on Nostr aligns with these goals. Nostr already provides a decentralized event-oriented foundation that avoids many of the control points found in centralized platforms. Overnet builds on that foundation to make it possible to support richer classes of applications while preserving decentralization as a core architectural property rather than treating it as an optional deployment detail.

Overnet is intended to provide the following properties:

- a minimal stable core for application interoperability
- strong identity, provenance, and auditability
- first-class support for end-to-end encrypted application data through companion specifications
- self-hostability and operator choice
- first-class support for adapters, including protocol bridges where needed
- application-facing consistency despite backend diversity
- forward-compatible extension and profile mechanisms
- clear conformance targets for clients, relays, and adapters
- support for decentralized deployment and governance models

These objectives shape the rest of the specification. When optional features, profiles, or adapter-specific requirements are defined, they should extend the core without weakening its security model, reducing operator freedom, or making interoperability ambiguous.

### 1.7 Scope

This specification defines the Overnet core.

In particular, it defines:

- the Overnet core model
- the Overnet trust and security model
- core client and relay behavior
- the application-facing semantics that Overnet components expose
- the core capability, profile, and extension mechanisms
- the base conformance requirements on which other Overnet specifications can build

This specification is written to be extensible. It is intended to support future companion specifications, including but not limited to:

- adapter specifications
- application profile specifications
- program runtime or program-protocol specifications
- storage and replication profile specifications
- operational and deployment guidance
- registries and extension specifications

This specification does not require any single transport, storage backend, deployment model, or external adapter.

### 1.8 Non-Goals

This specification does not:

- attempt to fully define every Overnet application domain in a single document
- require a single global operator
- require a single canonical relay implementation
- require every deployment to implement every adapter or feature profile
- define UI or product design requirements except where necessary for security or interoperability
- define every adapter, application profile, storage profile, or deployment model that may exist within the broader Overnet ecosystem

## 2. Conformance Language and Document Conventions

### 2.1 Requirement Keywords

The key words MUST, MUST NOT, REQUIRED, SHALL, SHALL NOT, SHOULD, SHOULD NOT, RECOMMENDED, NOT RECOMMENDED, MAY, and OPTIONAL in this document are to be interpreted as normative requirement terms when, and only when, they appear in all capitals.

### 2.2 Normative and Informative Content

Unless a section states otherwise, the main body of this specification is normative.

The following sections are informative unless they explicitly state normative requirements:

- Status of This Document
- Companion Specifications
- Introduction
- Open Issues and Future Work
- appendices titled as rationale, considerations, or change history

Examples, explanations, and rationale are informative unless they are explicitly marked as requirements.

### 2.3 Data Type and Encoding Conventions

Overnet core events use structured JSON content for primary application data.

All Overnet textual protocol elements MUST be Unicode scalar values encoded as UTF-8.

Implementations MUST emit valid UTF-8 for every textual protocol element.

Implementations MUST reject malformed UTF-8 at protocol boundaries before interpreting the affected value as Overnet text.

Profiles and companion specifications MUST NOT define alternate encodings for textual protocol elements.

Data that is not text MUST be represented by an explicitly typed binary form, such as a byte field or an encoded string whose encoding is defined by the applicable specification.

Unless a profile states otherwise, string comparison, field names, type names, capability names, and namespace identifiers are exact and case-sensitive.

Where this specification requires canonical representation, implementations MUST preserve the exact structured meaning of the represented data and MUST NOT treat semantically distinct encodings as interchangeable.

### 2.4 Extension and Namespace Conventions

The core defines namespaces for core-defined event types, object types, fields, tags, capabilities, and profiles.

Extensions MUST use names that do not collide with core-defined names or with other applicable names in scope.

An implementation MAY ignore unrecognized extension elements unless this specification or an applicable profile requires rejection. Unrecognized extension elements MUST NOT change the required interpretation of recognized core semantics.

## 3. Terminology

This section defines the core terms used throughout this specification.

Unless stated otherwise, these definitions are normative.

### 3.1 Core Entities

#### 3.1.1 Client

A client is software that speaks Overnet on behalf of a user, service, or application component.

A client may authenticate identities, publish or receive Overnet data, negotiate capabilities, manage subscriptions, and present Overnet resources to users or other software.

A client is not required to provide a user interface. Command-line tools, background agents, bots, and service-side components may all qualify as clients if they implement client-side Overnet behavior.

#### 3.1.2 Application

An application is software built on Overnet semantics to provide end-user or programmatic functionality such as chat, email, code hosting, publishing, marketplaces, or other higher-level services.

An application may include one or more clients, local services, storage layers, or adapter components. The term application refers to the higher-level system or product behavior, not only to a single process.

#### 3.1.3 Relay

A relay is an Overnet server-side component that accepts, validates, stores, forwards, serves, filters, or otherwise processes Overnet data and requests.

An Overnet relay may be built on top of one or more Nostr relays, may embed Nostr relay behavior directly, or may combine Overnet-specific logic with underlying Nostr infrastructure.

In this specification, relay refers to the Overnet-side server role unless a section explicitly says Nostr relay.

The Overnet core defines the relay role and minimum responsibilities. The [Overnet Relay Specification](relay.md) defines the first concrete relay metadata, query, subscription, and derived-object read surface.

#### 3.1.4 Node

A node is any network-participating Overnet component or deployment endpoint that implements one or more protocol roles.

A node may act as a client, relay, adapter host, storage peer, or a combination of these roles.

Node is a generic deployment term. Client and relay are role-specific terms.

#### 3.1.5 Adapter

An adapter is a component that maps an external system, protocol, service, or storage mechanism into Overnet semantics.

An adapter may translate identities, objects, events, permissions, metadata, errors, or capabilities between Overnet and a non-Overnet system.

For example, a system such as GitLab may be exposed through an adapter that maps repositories, issues, merge requests, users, permissions, and related events into Overnet semantics.

Some adapters are protocol bridges, meaning they provide ongoing interoperability between Overnet and another protocol or service, potentially including synchronization, event translation, identity mapping, and provenance across system boundaries.

An adapter does not imply perfect equivalence between the two systems. Where the mapping is partial, lossy, delayed, synthetic, or policy-constrained, that fact must be made explicit by the implementation.

#### 3.1.6 Operator

An operator is the person, organization, or administrative authority that controls the deployment, administration, or policy of an Overnet deployment.

An operator may define local policy, retention rules, access controls, rate limits, moderation rules, storage classes, or deployment topology, subject to the interoperability requirements of this specification.

Not every Overnet component has a distinct operator as a separate role. For example, an adapter may exist only as embedded library code inside an application, in which case any relevant operational control belongs to the enclosing deployment rather than to a separate adapter operator.

#### 3.1.7 Identity

An identity is the Overnet-recognized representation of an actor within the Overnet trust model.

An identity is used for authentication, authorization, attribution, delegation, policy evaluation, and provenance.

An identity may be native to Overnet, derived from Nostr credentials or identifiers, or mapped from an external system by an adapter.

### 3.2 Core Data Concepts

#### 3.2.1 Object

An object is a distinct logical resource represented within Overnet.

Examples may include messages, documents, issues, repositories, mail items, web resources, listings, or application-defined entities.

An object is the thing being referred to, acted upon, or synchronized, even when its state is described through one or more events.

#### 3.2.2 Event

An event is a signed or otherwise authenticated record of an action, assertion, transition, publication, observation, or state-affecting occurrence within Overnet.

Overnet is built on Nostr and therefore relies on an underlying event-oriented model. Overnet may define additional structure, semantics, and constraints for how events are interpreted at the application platform layer.

An event may create, mutate, annotate, supersede, reference, or otherwise relate to one or more objects, depending on the applicable profile.

#### 3.2.3 Reference

A reference is a structured pointer from one Overnet resource or data unit to another.

A reference may identify an object, event, identity, namespace entry, capability, profile element, external resource, or adapter-defined target.

References may be direct or indirect, but their semantics must be unambiguous within the applicable context.

#### 3.2.4 Namespace

A namespace is a controlled naming domain used to identify types, fields, extensions, capabilities, profiles, or other protocol elements without collision.

Namespaces may be defined by the core specification, by registered extension processes, or by implementation-specific or vendor-specific mechanisms as allowed by this specification.

#### 3.2.5 Capability

A capability is a declared unit of protocol, feature, or behavioral support that can be advertised, negotiated, required, or relied upon by Overnet components.

Capabilities allow clients, relays, and adapters to determine what features are supported without assuming that every implementation provides every optional behavior.

A capability does not by itself grant authorization. Capability support and permission to perform an action are separate concerns.

#### 3.2.6 Profile

A profile is a named application specification that defines a set of constraints, extensions, behaviors, mappings, or conformance requirements refining the Overnet core for a particular use case or interoperability target.

Profiles may define application behavior, adapter behavior, storage rules, security requirements, or feature bundles.

A profile may require specific capabilities, additional validation rules, or additional data model constraints.

Machine-readable profile contract documents are defined by the [Overnet Profile Contract Specification](profile-contracts.md). Profile contracts describe profile-specific semantics without replacing the Overnet core event envelope. Profile contracts are optional at the core protocol level; absence of a selected profile contract does not make a core-valid event invalid.

#### 3.2.7 Policy

A policy is a rule set enforced by an operator, relay, application, or adapter concerning acceptance, rejection, transformation, retention, moderation, access, or other handling of Overnet data or actions.

Policies may vary between deployments unless this specification marks a behavior as mandatory for interoperability.

#### 3.2.8 Subscription

A subscription is a standing or semi-standing request by which a client asks to receive matching Overnet data, updates, or state changes over time.

Subscriptions may be bounded, continuous, filtered, resumable, or profile-specific.

#### 3.2.9 Provenance

Provenance is metadata describing the origin of data, the identity or system from which it was derived, and any relevant translation, mapping, or transformation applied before it was exposed through Overnet.

Provenance is required for all Overnet data. Adapted data is subject to stricter provenance requirements than native Overnet data.

#### 3.2.10 Authority Record

An authority record is a native Overnet object that binds an external adapter origin to the set of Nostr public keys that are authoritative for adapting that origin into Overnet.

An authority record is ordinary signed Overnet data. It grants no privilege by itself; it is an assertion whose weight depends entirely on whether a consumer trusts the identity that signed it.

#### 3.2.11 Trust Anchor

A trust anchor is an authority record, or a public key permitted to sign authority records for a given scope, that a consumer has decided to trust through configuration, operator policy, or a profile-defined mechanism.

Trust anchors are how a consumer roots provenance verification in identities it has chosen to trust, without any mandatory central registry.

#### 3.2.12 Provenance Verification

Provenance verification is the consumer-side operation that evaluates whether the signing identity of an adapted event is authoritative for the external origin the event claims, relative to the consumer's trust anchors.

Provenance verification does not decide whether an event is admitted or stored. It decides whether adapted data may be presented as carrying authoritative external attribution or authority.

### 3.3 Compliance Terms

#### 3.3.1 Core-Compliant Client

A core-compliant client is an implementation that satisfies all mandatory client requirements defined by the Overnet core specification.

Support for optional capabilities or profiles is not required unless separately claimed.

#### 3.3.2 Core-Compliant Relay

A core-compliant relay is an implementation that satisfies all mandatory relay requirements defined by the Overnet core specification.

Support for optional capabilities or profiles is not required unless separately claimed.

#### 3.3.3 Adapter-Compliant Implementation

An adapter-compliant implementation is an implementation that satisfies the mandatory adapter-related requirements of this specification and of any adapter specification or adapter profile it claims to support.

#### 3.3.4 Supported Capability

A supported capability is a capability that an implementation advertises and implements according to this specification or according to the relevant registered extension or profile.

An implementation must not advertise a capability unless it actually implements the required behavior for that capability.

#### 3.3.5 Supported Profile

A supported profile is a profile that an implementation explicitly claims to implement and for which it satisfies all mandatory requirements.

#### 3.3.6 Overnet Program

An Overnet program is a runnable implementation artifact that produces, consumes, stores, transports, or otherwise acts on Overnet data.

An Overnet program may implement one or more Overnet roles and may support one or more companion specifications, but it is not itself a semantic companion specification merely by virtue of being runnable software.

#### 3.3.7 Native Overnet Data

Native Overnet data is data created and represented directly according to Overnet rules rather than being derived from an external system through an adapter.

#### 3.3.8 Adapted Data

Adapted data is data that originates outside native Overnet semantics and is exposed within Overnet through an adapter.

Adapted data must retain provenance sufficient to distinguish it from native Overnet data and to communicate any relevant translation limitations.

## 4. Architecture Overview

### 4.1 Architectural Model

Overnet is defined directly on top of Nostr.

The canonical wire and signature unit for Overnet core data is a Nostr event conforming to the Overnet core profile defined by this specification. Overnet does not define a transport-independent core in this document.

Overnet adds a higher-level application model on top of Nostr. In particular, it defines:

- stable object semantics derived from events
- structured event content for Overnet core events
- standardized reference semantics
- application-facing operations for publication, retrieval, querying, subscription, capability discovery, and related behavior
- provenance, authorization, and conformance requirements beyond raw Nostr usage

The Overnet core is not by itself a complete execution environment for runnable software. A separate Overnet program runtime or program-protocol specification is expected to define how Overnet programs communicate with a host runtime, receive services, and emit data through a standardized language-agnostic boundary.

### 4.2 Roles and Responsibilities

The core roles are client, relay, and adapter.

A client acts on behalf of a user, service, or automated process. A relay provides Overnet server behavior, which may be implemented atop one or more Nostr relays or equivalent relay-side infrastructure. An adapter maps external systems into Overnet semantics.

A single deployment MAY implement more than one role.

An Overnet program is a runnable implementation artifact that participates in one or more of these roles. Overnet programs are not themselves semantic companion specifications.

### 4.3 Trust Boundaries

The client trust boundary is where identities are controlled and authenticated actions are initiated.

The relay trust boundary is where validation, policy enforcement, storage policy, capability exposure, and query or subscription behavior are applied.

The adapter trust boundary is where external identities, permissions, objects, and events are mapped into Overnet semantics. Adapters MUST disclose provenance and any known translation limitations.

When an applicable companion specification defines end-to-end encrypted content, plaintext trust is limited to the authorized endpoints that hold the required decryption keys. Relays, generic transport services, and ordinary storage nodes MUST be treated as opaque ciphertext carriers unless the applicable companion specification explicitly defines a trusted-decryption role.

### 4.4 Relationship to Nostr

Overnet relies on Nostr for baseline event transport, event identity, event signing, and event verification.

This specification may impose stricter requirements than generic Nostr usage. A valid Nostr event is not automatically a valid Overnet core event.

Overnet core events use structured JSON content as the primary carrier of application data together with standardized Nostr tag usage for references, indexing, and related metadata.

### 4.5 Relationship to External Systems via Adapters

External protocols and systems participate in Overnet through adapters.

The core specification defines baseline adapter invariants, including identity mapping, permission mapping, provenance, and disclosure of partial or lossy translation. Detailed rules for any specific adapter are expected to be defined by companion adapter specifications.

### 4.5.1 Adapters Versus Programs

An adapter is a semantic mapping layer. It defines how an external system is expressed within Overnet.

A program is a runnable implementation artifact that produces, consumes, stores, transports, or otherwise acts on Overnet data.

Adapter specifications define source-system mapping semantics. Programs implement the core and any companion specifications they claim to support. Programs do not require separate semantic companion specifications merely by virtue of being runnable software, although a future Overnet program runtime or program-protocol specification may define common execution contracts for programs.

### 4.5.2 Adapter Directionality

Where the external system, trust model, and deployment scope permit semantically honest two-way interoperability, an adapter specification SHOULD aim to define both directions of the mapping:

- how external-system observations or actions are expressed through Overnet semantics
- how appropriate Overnet actions, state, or presentation are expressed back toward the external system

Bi-directionality is not required when a reverse mapping would be misleading, unsafe, materially lossy, operationally out of scope, or unsupported by the source system.

If a companion adapter specification intentionally defines only one direction, or only a partial reverse mapping, it SHOULD say so explicitly and identify the omitted direction or class of operations.

### 4.6 Adapter Fidelity Principles

Adapters are required to preserve source-system semantics as faithfully as possible.

An adapter specification or implementation MUST NOT reshape external data into a more convenient Overnet form when doing so would hide, weaken, or misstate the original system's actual semantics.

In particular:

- the scope of a mapped concept SHOULD remain the same as in the source system whenever Overnet can represent that scope directly
- an adapter MUST NOT represent a network-scoped concept as object-scoped, channel-scoped, user-scoped, or session-scoped unless the companion specification explicitly documents that transformation and its consequences
- an adapter MUST NOT overstate identity stability, object stability, authorship, authorization, or capability beyond what the source system actually provides
- an observed external action MUST be distinguishable from native Overnet authority unless a companion specification explicitly defines equivalent authority semantics
- adapted data presented as carrying authoritative external identity, authorship, or authority MUST be distinguishable from adapted data whose external attribution is unverified or forged, as defined by the provenance verification model in §7.9
- lossy, synthetic, delayed, partial, inferred, or policy-shaped mappings MUST be disclosed through provenance, limitations, companion specification text, or a combination of those mechanisms
- derived views, convenience projections, or implementation-local aggregations MUST NOT be treated as the canonical meaning of adapted data unless the companion specification explicitly defines them as such

When a source-system concept does not cleanly fit an existing generic Overnet vocabulary, a companion specification SHOULD prefer a source-specific object or event type rather than forcing the concept into a generic shape that distorts its meaning.

## 5. Core Design Principles

### 5.1 Minimal Stable Core

The Overnet core SHOULD remain as small as possible while still providing a useful baseline for interoperable applications.

### 5.2 Application-Developer-Oriented Semantics

The core MUST define application-facing operations and semantics clearly enough that developers can build against the core directly and that a concrete API binding can be specified without inventing new semantics.

### 5.3 Nostr-Native Foundation

The core MUST remain directly grounded in Nostr transport and event semantics rather than introducing a transport-neutral abstraction layer in this document.

### 5.4 Objects Derived from Events

Events are primary. Objects are stable semantic resources whose state is derived from one or more related events over time.

### 5.5 Explicit Provenance

All Overnet data MUST carry provenance. Adapted data MUST carry provenance sufficient to distinguish it from native Overnet data and to disclose relevant mapping or translation limitations.

### 5.6 Honest Capability Exposure

Capability discovery MUST be accurate and meaningful for the current client or policy context. An implementation MAY scope capability disclosure, but it MUST NOT falsely advertise support.

### 5.7 Extensibility Through Profiles and Capabilities

The core SHOULD enable future growth through profiles, capabilities, namespaces, and versioned companion specifications rather than by expanding the core unnecessarily.

### 5.8 Operator Choice

The core MUST allow independent operators to apply local policy, retention, and deployment choices so long as they do not violate core interoperability requirements.

### 5.9 End-to-End Encryption as a First-Class Capability

Overnet fully supports end-to-end encryption as a first-class capability.

This means the core MUST allow companion specifications to define encrypted application data and encrypted workflows without breaking:

- core identity and signature semantics
- provenance requirements
- relay interoperability
- capability discovery
- conformance reporting

The core does not require all Overnet data to be end-to-end encrypted. Public and intentionally shared data remain valid core use cases.

A core-compliant implementation MUST NOT assume that relays, generic queries, derived-object reads, moderation systems, adapters, or other intermediaries can inspect or derive encrypted payload contents unless an applicable companion specification explicitly defines such access as part of the trusted model.

## 6. Core Object and Event Model

### 6.1 Overview

Overnet core state is represented through events and derived objects.

An event is the canonical signed unit carried over Nostr. An object is a stable semantic resource identified independently from any single event. Current object state is derived from one or more related events.

### 6.2 Canonical Event Representation

An Overnet core event MUST be represented as a Nostr event conforming to the Overnet core profile.

Overnet defines three Nostr event kinds:

| Kind | Name | Nostr behavior |
|------|------|----------------|
| 7800 | Overnet Event | Regular (stored, never replaced) |
| 37800 | Overnet State | Parameterized replaceable (latest per pubkey + `d` tag) |
| 7801 | Overnet Removal | Regular (stored, never replaced) |

**Kind 7800 (Overnet Event)** is used for immutable event log entries: messages, comments, actions, mutations, and other events that accumulate over time.

**Kind 37800 (Overnet State)** is used for current state of single-author objects: profiles, settings, adapter mappings, and any object where one pubkey owns the canonical latest state. The Nostr `d` tag MUST be set to the object identifier. A kind `37800` event MUST include exactly one `d` tag. Because this kind is parameterized replaceable, Nostr relays will automatically retain only the latest event per pubkey and `d` tag combination.

**Kind 7801 (Overnet Removal)** is used for tombstone events that mark an object or prior event as removed. A kind `7801` event MUST use `overnet_et` value `"core.removal"`. A kind `7801` event MUST include exactly one `e` tag identifying the Nostr event ID being tombstoned. The `body` field of a kind `7801` event MUST be an empty JSON object.

These kind numbers are working values subject to change before registration with the Nostr kind registry.

The content of an Overnet core event MUST be a JSON string conforming to the content schema defined in §6.3.

### 6.3 Required Fields

Overnet core events carry required fields in two locations: Nostr tags and the JSON content body. Tags are used for fields that relays need to filter on. Content is used for structured data that is only needed after retrieval.

#### 6.3.1 Required Nostr Tags

Every Overnet core event MUST include the following tags:

| Tag | Value | Description |
|-----|-------|-------------|
| `overnet_v` | semver string | Core specification version (currently `"0.1.0"`) |
| `overnet_et` | string | Event type (e.g., `"chat.message"`, `"repo.commit"`) |
| `overnet_ot` | string | Object type (e.g., `"chat.channel"`, `"repo.issue"`) |
| `overnet_oid` | string | Object identifier |

The core-defined tags `overnet_v`, `overnet_et`, `overnet_ot`, and `overnet_oid` are singular. An Overnet core event MUST NOT include more than one instance of any of those tags.

Tag names use the `overnet_` prefix to avoid collision with Nostr core tags and other protocols. Nostr relays can filter on these tags without parsing the event content.

Every Overnet core event MUST also include the following single-letter compatibility mirror tags:

| Tag | Mirror Of | Description |
|-----|-----------|-------------|
| `v` | `overnet_v` | Compatibility mirror of the Overnet core version |
| `t` | `overnet_et` | Compatibility mirror of the Overnet event type |
| `o` | `overnet_ot` | Compatibility mirror of the Overnet object type |
| `d` | `overnet_oid` | Compatibility mirror of the Overnet object identifier |

These single-letter tags exist to provide an interoperable mapping onto standard NIP-01 filter and NIP-77 negentropy filter semantics without requiring nonstandard `#overnet_*` filter keys in transports that only standardize single-letter tag filters.

The `v`, `t`, `o`, and `d` mirror tags are singular. An Overnet core event MUST NOT include more than one instance of any of those tags.

The mirror tags MUST exactly match the corresponding canonical `overnet_*` tag values.

For kind `37800`, the required `d` tag for parameterized replaceable semantics and the `d` compatibility mirror are the same tag. Its value MUST equal `overnet_oid`.

The following fields are carried by the Nostr event structure itself and MUST NOT be duplicated in tags or content:

- **Authoring identity**: the Nostr event `pubkey`
- **Event timestamp**: the Nostr event `created_at`
- **Event identifier**: the Nostr event `id`

*Example (informative). Nostr tags for a chat message event:*

```json
[
  ["overnet_v", "0.1.0"],
  ["overnet_et", "chat.message"],
  ["overnet_ot", "chat.channel"],
  ["overnet_oid", "a1b2c3d4"],
  ["v", "0.1.0"],
  ["t", "chat.message"],
  ["o", "chat.channel"],
  ["d", "a1b2c3d4"]
]
```

#### 6.3.2 Required Content Fields

The Nostr event `content` field MUST be a JSON object with the following structure:

```json
{
  "provenance": { ... },
  "body": { ... }
}
```

The `provenance` field is REQUIRED on all Overnet core events. Its structure is defined in §6.3.3.

The `body` field is REQUIRED. It MUST be a JSON object.

The `body` field contains profile-defined payload data. The core does not define the structure of `body`; applicable profiles define what fields appear inside it.

Core-defined fields occupy the top level of the content JSON object. Profiles MUST NOT add fields at the top level; all profile-specific data MUST go inside `body`. This separation ensures that future core fields cannot collide with profile-defined fields.

#### 6.3.3 Provenance

The `provenance` object describes the origin of the data carried by the event.

**For native Overnet data:**

```json
{
  "provenance": {
    "type": "native"
  }
}
```

**For adapted data:**

```json
{
  "provenance": {
    "type": "adapted",
    "protocol": "irc",
    "origin": "irc.libera.chat/#overnet",
    "external_identity": "someircnick",
    "limitations": ["unsigned", "no_edit_history"]
  }
}
```

The `type` field is REQUIRED. It MUST be `"native"` or `"adapted"`.

When `type` is `"adapted"`, the following fields are REQUIRED:

| Field | Type | Description |
|-------|------|-------------|
| `protocol` | string | The external protocol or system (e.g., `"irc"`, `"email"`, `"gitlab"`) |
| `origin` | string | The specific external source (e.g., `"irc.libera.chat/#overnet"`) |
| `limitations` | array of strings | Known translation limitations (MAY be empty) |

Adapted provenance MUST also include at least one of `external_identity` or `external_scope`.

The `external_identity` field is REQUIRED when the event is attributable to a specific external actor. It MUST contain the identity of the original author in the external system (e.g., an IRC nickname, an email address).

The `external_scope` field is REQUIRED when the adapted data is an aggregate or derived view that is not attributable to one specific external actor. It MUST identify the external scope over which the adapted view was derived (e.g., `"channel_membership"`, `"mailing_list_thread"`).

#### 6.3.4 Core Limitation Identifiers

The following limitation identifiers are defined by the core. Adapter specifications MAY define additional identifiers using namespaced names (e.g., `irc.no_presence`, `email.no_attachments`).

| Identifier | Meaning |
|---|---|
| `unsigned` | Original data has no cryptographic signature from the external author |
| `no_edit_history` | Edit or revision history from the external system is not preserved |
| `lossy` | Some content or metadata was lost or simplified in translation |
| `delayed` | Data may not reflect real-time state of the external system |
| `synthetic_identity` | The external identity was constructed or inferred, not directly authenticated |
| `partial` | Only a subset of the external resource's data is represented |

#### 6.3.5 Complete Event Examples

This section is informative. It shows complete Nostr events conforming to the Overnet core profile.

*Example 1. A native Overnet Event (kind 7800) representing a chat message:*

```json
{
  "id": "a1e2f3...",
  "pubkey": "b4c5d6...",
  "created_at": 1744300800,
  "kind": 7800,
  "tags": [
    ["overnet_v", "0.1.0"],
    ["overnet_et", "chat.message"],
    ["overnet_ot", "chat.channel"],
    ["overnet_oid", "f47ac10b-58cc-4372-a567-0e02b2c3d479"],
    ["v", "0.1.0"],
    ["t", "chat.message"],
    ["o", "chat.channel"],
    ["d", "f47ac10b-58cc-4372-a567-0e02b2c3d479"]
  ],
  "content": "{\"provenance\":{\"type\":\"native\"},\"body\":{\"text\":\"Hello, world!\"}}",
  "sig": "e7f8a9..."
}
```

In this example:

- `kind` is 7800 (Overnet Event), so the relay stores it as a regular immutable event.
- `overnet_v` identifies the core spec version. A relay can filter for all Overnet 0.1.0 events.
- `overnet_et` is `"chat.message"`, defined by a chat profile (not the core).
- `overnet_ot` and `overnet_oid` identify the object this event pertains to — a chat channel with a UUID.
- `pubkey` is the authoring identity. `created_at` is the event timestamp. These are not duplicated in tags or content.
- `content` is a JSON string. The `provenance` type is `"native"`. The `body` contains profile-defined payload.

*Example 2. An adapted event from IRC:*

```json
{
  "id": "c3d4e5...",
  "pubkey": "a1b2c3...",
  "created_at": 1744300860,
  "kind": 7800,
  "tags": [
    ["overnet_v", "0.1.0"],
    ["overnet_et", "chat.message"],
    ["overnet_ot", "chat.channel"],
    ["overnet_oid", "irc:libera.chat:#overnet"],
    ["v", "0.1.0"],
    ["t", "chat.message"],
    ["o", "chat.channel"],
    ["d", "irc:libera.chat:#overnet"]
  ],
  "content": "{\"provenance\":{\"type\":\"adapted\",\"protocol\":\"irc\",\"origin\":\"irc.libera.chat/#overnet\",\"external_identity\":\"alice\",\"limitations\":[\"unsigned\",\"no_edit_history\"]},\"body\":{\"text\":\"Hello from IRC!\"}}",
  "sig": "d5e6f7..."
}
```

In this example:

- `pubkey` is the adapter's Nostr key, not the original IRC user's.
- `provenance.external_identity` is `"alice"`, the IRC nickname.
- `provenance.limitations` declares that the original message has no cryptographic signature and edit history is not available.
- `overnet_oid` uses a protocol-scoped identifier (`irc:libera.chat:#overnet`) as defined by the IRC adapter spec.

*Example 3. An Overnet State event (kind 37800) representing a user profile:*

```json
{
  "id": "e5f6a7...",
  "pubkey": "b4c5d6...",
  "created_at": 1744300900,
  "kind": 37800,
  "tags": [
    ["d", "b4c5d6..."],
    ["overnet_v", "0.1.0"],
    ["overnet_et", "identity.profile"],
    ["overnet_ot", "identity.profile"],
    ["overnet_oid", "b4c5d6..."],
    ["v", "0.1.0"],
    ["t", "identity.profile"],
    ["o", "identity.profile"]
  ],
  "content": "{\"provenance\":{\"type\":\"native\"},\"body\":{\"display_name\":\"Alice\",\"bio\":\"Overnet early adopter\"}}",
  "sig": "f8a9b0..."
}
```

In this example:

- `kind` is 37800 (Overnet State). The relay keeps only the latest event per pubkey + `d` tag.
- The `d` tag is set to the object identifier, as required by §6.2 for kind 37800.
- Publishing a new event with the same `kind`, `pubkey`, and `d` tag replaces this one on any NIP-01 relay.

*Example 4. An Overnet Removal event (kind 7801):*

```json
{
  "id": "b2c3d4...",
  "pubkey": "b4c5d6...",
  "created_at": 1744301000,
  "kind": 7801,
  "tags": [
    ["overnet_v", "0.1.0"],
    ["overnet_et", "core.removal"],
    ["overnet_ot", "chat.channel"],
    ["overnet_oid", "f47ac10b-58cc-4372-a567-0e02b2c3d479"],
    ["v", "0.1.0"],
    ["t", "core.removal"],
    ["o", "chat.channel"],
    ["d", "f47ac10b-58cc-4372-a567-0e02b2c3d479"],
    ["e", "a1e2f3..."]
  ],
  "content": "{\"provenance\":{\"type\":\"native\"},\"body\":{}}",
  "sig": "c4d5e6..."
}
```

In this example:

- `kind` is 7801 (Overnet Removal).
- The `e` tag references the Nostr event ID of the event being removed, using the standard Nostr event reference tag.
- `overnet_et` is `"core.removal"`, a core-defined event type.
- `overnet_ot` and `overnet_oid` identify the object whose event history is being tombstoned.
- The `body` is empty; the removal's meaning comes from the reference, not from payload data.

*Example 5. An Overnet delegation event authorizing delegated removal for one object:*

```json
{
  "id": "c7d8e9...",
  "pubkey": "b4c5d6...",
  "created_at": 1744300950,
  "kind": 7800,
  "tags": [
    ["overnet_v", "0.1.0"],
    ["overnet_et", "core.delegation"],
    ["overnet_ot", "chat.channel"],
    ["overnet_oid", "f47ac10b-58cc-4372-a567-0e02b2c3d479"],
    ["v", "0.1.0"],
    ["t", "core.delegation"],
    ["o", "chat.channel"],
    ["d", "f47ac10b-58cc-4372-a567-0e02b2c3d479"]
  ],
  "content": "{\"provenance\":{\"type\":\"native\"},\"body\":{\"action\":\"remove\",\"delegate_pubkey\":\"a1b2c3...\",\"expires_at\":1744304600}}",
  "sig": "d0e1f2..."
}
```

In this example:

- `kind` is 7800 because the delegation is a normal immutable event.
- `overnet_et` is `"core.delegation"`, a core-defined event type.
- `overnet_ot` and `overnet_oid` scope the delegation to one object.
- `body.action` is `"remove"`, the only delegated action defined by the baseline core.
- `body.delegate_pubkey` identifies the native Nostr pubkey allowed to issue delegated removals for that object.
- `body.expires_at` is optional. When present, the delegation is invalid after that timestamp.

### 6.4 Optional Fields

The core MAY permit optional fields for profile selection, adapter mapping metadata, authorization context, revision metadata, auxiliary timestamps, and other extension data.

Optional fields MUST NOT silently change the meaning of core-required fields.

### 6.5 Object Identity

Objects MUST have stable object identifiers distinct from event identifiers.

Object identifiers MUST be non-empty strings. Object identifiers MUST be globally unique across all object types. Object identifiers MUST be stable across revisions of the same logical object.

The core does not mandate a specific identifier format. Profiles MUST define identifier schemes for their object types that ensure global uniqueness structurally (for example, through UUIDs, content-addressed hashes, or protocol-scoped identifiers).

### 6.6 Event Identity

The canonical identifier for an Overnet event is the identifier of the underlying Nostr event.

No separate core event identifier scheme is defined in this document.

### 6.7 References and Linking

The core defines baseline reference semantics for links between events, objects, identities, and provenance sources.

Core reference relationships include at least:

- reference to another event
- reference to an object
- reference to an identity
- reference to a source or external origin
- reference indicating revision, supersession, replacement, or removal relationships

Profiles MAY define additional reference types.

### 6.8 Metadata and Extension Fields

The core defines namespace rules for event types, object types, capabilities, profiles, fields, and tags.

Extensions MUST be namespaced. Unrecognized extension fields MUST NOT alter the required interpretation of core semantics.

### 6.9 Immutability, Mutation, and Derived State

Events are immutable once published.

Objects have stable identities and MAY change state over time through related events. A core-compliant implementation MUST derive object state using the baseline derivation rules defined by this specification. Profiles MAY add more specific derivation rules.

### 6.10 Ordering and Time Semantics

The core does not define a strict global ordering model.

The baseline ordering model for derivation and conflict handling MUST use, in order:

- explicit reference relationships such as supersession or replacement where present
- event timestamps as defined by the underlying Nostr event and any applicable core semantics
- deterministic event identifier ordering as a final tie-breaker

Profiles MAY refine ordering rules where needed.

### 6.11 Conflict Resolution

When multiple events imply conflicting object state, a core-compliant implementation MUST apply the baseline ordering and reference rules of this specification.

Profiles MAY define more specific conflict-resolution behavior for particular object types or workflows.

### 6.12 Revision, Supersession, and Replacement

The core defines baseline semantics for revision, supersession, and replacement relationships.

An implementation MUST be able to determine when one event revises, supersedes, or replaces the effect of another event according to core rules and any applicable profile rules.

### 6.13 Removal and Tombstones

The core defines protocol-level removal semantics through tombstone or equivalent removal events.

A removal event affects the derived state and visibility of an object or prior event according to core rules and applicable profile rules. Physical erasure, retention duration, and storage reclamation remain deployment policy unless otherwise required by a profile.

For baseline core authorization, a kind `7801` removal MUST be authorized against the exact target event identified by its `e` tag. If the referenced target event is unavailable, or if the available target event does not match the `e` tag, authorization cannot be established and the removal MUST be rejected.

Under the baseline core authorization model, a kind `7801` removal is authorized only when the removal event's Nostr `pubkey` matches the authoring `pubkey` of the target event identified by the `e` tag.

A delegated removal MAY be authorized by a separate delegation event. When a kind `7801` removal uses delegation, it MUST include exactly one `overnet_delegate` tag whose value is the Nostr event ID of the delegation event being used for authorization.

When a delegated removal is evaluated, the referenced delegation event MUST be available. If the referenced delegation event is unavailable, authorization cannot be established and the removal MUST be rejected.

The referenced delegation event MUST:

- be an Overnet event with `overnet_et` value `"core.delegation"`
- have the same `overnet_ot` and `overnet_oid` values as the removal event
- have a `body.action` value of `"remove"`
- have a `body.delegate_pubkey` value equal to the removal event's authoring `pubkey`
- have an authoring `pubkey` equal to the target event's authoring `pubkey`
- not be expired at the removal event's `created_at` timestamp when `body.expires_at` is present

If a kind `7801` removal does not use delegation, it MUST NOT include an `overnet_delegate` tag.

### 6.14 Delegation Events

The core defines a baseline delegation mechanism for delegated removals.

A delegation event is an Overnet event with `kind` `7800` and `overnet_et` value `"core.delegation"`.

A baseline core delegation event MUST:

- be native Overnet data with `provenance.type` value `"native"`
- include `overnet_ot` and `overnet_oid` identifying the single object to which the delegation applies
- include a `body` object with required fields `action` and `delegate_pubkey`

The baseline core defines exactly one delegation action:

| Field | Type | Description |
|---|---|---|
| `action` | string | MUST be `"remove"` |
| `delegate_pubkey` | 64-character lowercase hex string | Native Nostr pubkey allowed to issue delegated removals for the object |
| `expires_at` | integer | OPTIONAL Unix timestamp after which the delegation is invalid |

The baseline core does not define delegation revocation. Profiles or later core revisions MAY define explicit revocation behavior.

### 6.15 Adapter Authority Records

The core defines a baseline object for binding an external adapter origin to the Nostr public keys authoritative for adapting that origin. This object is the resolution mechanism referenced by the adapted-authorization rule in §7.2 and the provenance verification model in §7.9.

An adapter authority record is an Overnet State event with `kind` `37800` and `overnet_et` and `overnet_ot` values `"core.adapter_authority"`.

An adapter authority record MUST:

- be native Overnet data with `provenance.type` value `"native"`
- set `overnet_oid` (and the `d` mirror) to the authority scope identifier `"<protocol>:<origin>"`, where `<protocol>` and `<origin>` are the `body.protocol` and `body.origin` values
- include a `body` object with the fields defined below

Because the object is a kind `37800` parameterized replaceable event, each signing pubkey has at most one current authority record per authority scope. A signer revises its record by publishing a newer event for the same scope, and MAY revoke it by publishing a record with an empty `pubkeys` array.

The `body` fields are:

| Field | Type | Description |
|---|---|---|
| `protocol` | string | The external protocol or system this authority applies to (e.g., `"irc"`) |
| `origin` | string | The external origin, or origin prefix, this record is authoritative for |
| `origin_match` | string | OPTIONAL. `"exact"` (default) or `"prefix"`. See below. |
| `pubkeys` | array of 64-character lowercase hex strings | The Nostr pubkeys authoritative for adapting the origin. MAY be empty. |
| `not_before` | integer | OPTIONAL Unix timestamp before which the record is not yet in effect |
| `not_after` | integer | OPTIONAL Unix timestamp after which the record is no longer in effect |

`body.protocol` and `body.origin` are REQUIRED. `body.pubkeys` is REQUIRED and MUST be an array; an empty array is a valid assertion that no pubkey is currently authoritative for the scope.

When `body.origin_match` is `"exact"` or absent, the record applies only to adapted events whose `provenance.origin` equals `body.origin`.

When `body.origin_match` is `"prefix"`, the record applies to adapted events whose `provenance.origin` equals `body.origin` or begins with `body.origin` followed by a scope separator. The scope separator for an origin space is defined by the applicable adapter specification; a companion specification that permits prefix authority MUST define the separator so that prefix matching cannot span an unintended origin boundary.

Signing an adapter authority record asserts only that the signer claims the listed pubkeys are authoritative for the origin. The record carries authority for a consumer only when that consumer trusts the signer as a trust anchor for the scope, as defined in §7.9. The core defines no mandatory global registry of authority records and no privileged authority-record signer.



### 7.1 Identity Model

Nostr public keys are the baseline identity form in the Overnet core.

The core also allows adapted or mapped external identities through adapters, provided that such mappings carry provenance and obey the relevant adapter and profile rules.

### 7.2 Authentication and Baseline Authorization

The baseline authentication model is Nostr-based authentication.

Where interactive or session-level authentication is required, a relay or service MUST use a Nostr-compatible authenticated mechanism. Adapter-backed systems MAY additionally expose mapped external authentication context, but this does not replace the baseline identity and verification model of the core.

The baseline authorization model is conservative. Unless an applicable profile or explicit delegation rule states otherwise, a native Overnet event that revises or removes prior event state is authorized only when the acting Nostr `pubkey` matches the authoring `pubkey` of the target event.

For adapted data, a revision or removal is authorized only when it is issued by the same adapter `pubkey` that authored the adapted target event, unless an applicable companion specification defines a different rule.

The baseline continuity rule above governs authorization between two events with the same adapter pubkey, but it does not by itself establish whether a given pubkey is the legitimate adapter for an external origin. That question is answered by the adapter authority records defined in §6.15, evaluated through the provenance verification model in §7.9.

Moderator, administrative, or delegated override authority is not part of the baseline core authorization model. Implementations MUST NOT assume such override authority unless it is explicitly defined by the core or by an applicable companion specification.

### 7.3 Delegation

The core defines baseline delegation semantics.

A delegated action MUST identify the acting identity, the delegated or authorizing context where applicable, and any scope or provenance required to interpret that action safely.

### 7.4 Service Identities and Automation

The core permits service identities, automated agents, and background processes.

Such identities MUST be distinguishable from ordinary user-controlled identities where that distinction is relevant to authorization, provenance, or policy.

### 7.5 Key Rotation and Revocation

The core recognizes that identity material may rotate or be revoked, but this document does not define a full universal revocation system.

Implementations and profiles MAY define additional mechanisms for continuity, revocation signaling, or local trust policy.

### 7.6 Replay Protection

The core requires baseline replay protection for authenticated operations.

At minimum, implementations MUST prevent trivial replay of identical operations where replay would violate protocol semantics, authorization semantics, or relay policy.

### 7.7 Trust Relationships

A relay validates and serves Overnet data, but relay acceptance alone does not imply that all semantic claims carried by an event are true.

Adapted data carries additional trust boundaries. An implementation MUST make clear whether data is native or adapted and MUST preserve provenance sufficient for clients to evaluate trust. The provenance verification model in §7.9 defines how a consumer evaluates whether the signing identity of an adapted event is authoritative for the external origin it claims.

### 7.8 Threat Model

Implementations SHOULD assume the possibility of forged external mappings, replayed operations, compromised identities, misleading provenance, conflicting event ordering, and policy-sensitive capability exposure.

The core security and privacy requirements are defined later in this document.

### 7.9 Adapter Provenance Verification

Provenance in an adapted event is self-asserted. Any identity may sign an event that claims any external protocol, origin, and external identity. A relay that accepts an event validates its Nostr signature, structure, and local policy, but relay acceptance does not establish that the signing identity is authoritative for the external origin the event claims (§7.7). Overnet does not close this gap by restricting who may publish, because permissionless publication is a core design objective (§1.6, §5.1, §5.8). Instead, the core defines a consumer-side verification boundary at which forged external attribution becomes detectable and non-authoritative, without preventing the event from being carried.

#### 7.9.1 Trust Anchors

A consumer maintains a set of trust anchors. A trust anchor designates a signing identity that the consumer trusts to assert adapter authority records (§6.15) for a stated protocol and origin scope.

Trust anchors MUST be established by explicit consumer configuration or operator policy. The core does not define a mandatory global registry and does not privilege any signer; which anchors a consumer trusts is a local decision, consistent with operator choice (§5.8).

A companion specification or profile MAY define mechanisms for discovering or distributing authority records, but the decision to trust an anchor remains with the consumer. A consumer MAY adopt a trust-on-first-use policy, but such a policy is weaker: absent an anchored record, an unfamiliar signing identity yields the `unverified` outcome below rather than `forged`.

An authority record is a *trusted authority record* for a consumer when it is anchored directly by that consumer, or when it is signed by an identity the consumer has anchored as permitted to assert authority records for the relevant scope. The baseline core does not define transitive anchor chains; a profile MAY define them.

#### 7.9.2 The Verification Operation

Provenance verification takes an adapted event and the consumer's trusted authority records and produces exactly one outcome.

An authority record is *applicable* to an adapted event when it is a trusted authority record, its `body.protocol` equals the event's `provenance.protocol`, and its origin selector matches the event's `provenance.origin` under the matching rule in §6.15. An applicable record is *in effect* at the event's `created_at` when it is well-formed and within any `not_before`/`not_after` window it declares.

The outcome is determined as follows:

| Outcome | Condition |
|---|---|
| `authoritative` | At least one applicable authority record is in effect and lists the event's signing `pubkey`, and no applicable in-effect record contradicts that determination. |
| `forged` | At least one applicable authority record is in effect, and no applicable in-effect record lists the event's signing `pubkey`. |
| `unverified` | No applicable authority record is known. Authority is neither confirmed nor refuted. |
| `unresolvable` | An applicable authority record exists but no safe determination can be made — for example the applicable record is malformed, is outside its validity window, or in-effect applicable records conflict in a way the consumer's policy cannot reconcile. |

Verification applies to adapted data. Native Overnet data (`provenance.type` value `"native"`) is not subject to this operation; its authority is governed by the baseline identity and authorization model (§7.1, §7.2).

The `forged` outcome is positive evidence that the signing identity is not authoritative for the origin it claims. The `unverified` outcome is the permissionless default and MUST NOT be reported as `forged`: it means the consumer holds no applicable anchor, not that misattribution was detected.

#### 7.9.3 Consumer Conformance Obligations

A consumer that renders or acts on adapted data:

- MUST NOT present adapted data as carrying authoritative external identity, authorship, or authority unless verification yields `authoritative`
- MUST be able to distinguish the four outcomes in §7.9.2 wherever that distinction affects presentation, authorization, or trust
- MUST NOT present an event whose outcome is `forged` as authoritative external attribution, and SHOULD surface, quarantine, or reject it as a provenance violation according to policy
- MAY present `unverified` adapted data, but MUST NOT represent it as verified or authoritative external attribution
- MUST treat `unresolvable` as not authoritative

A consumer that does not verify provenance MUST NOT represent adapted external attribution as authoritative. A consumer MAY decline to implement verification only by declining to make authoritative claims about adapted attribution at all.

These obligations constrain how a consumer *presents and trusts* adapted data. They do not require a relay to reject unverifiable events, and they do not make an unverified or forged event invalid as a core event; such an event remains a structurally valid carrier whose external attribution has simply not been established.

## 8. Core Protocol Semantics

### 8.1 Discovery

A core-compliant implementation MUST provide capability discovery for the current client or policy context.

Capability discovery MAY be scoped by authentication, authorization, deployment policy, or local configuration, but it MUST be accurate for the context in which it is returned.

### 8.2 Session Establishment

The core allows both stateless and session-oriented interaction patterns, provided that required authentication and authorization semantics are preserved.

Where a session or challenge step is used, the implementation MUST bind it to the authenticated identity and protect against replay according to core rules.

### 8.3 Publish Operations

The core defines publication of Overnet core events as a standard operation.

A relay MUST validate the published event against Nostr verification rules, core Overnet requirements, local policy, and any applicable profile requirements before accepting it.

### 8.4 Query Operations

The core defines baseline query operations for both events and derived objects.

A core-compliant implementation MUST support retrieval by reference and baseline filtering semantics. Profiles MAY define additional query behavior.

### 8.5 Subscription Operations

The core defines subscriptions as a standard operation.

A core-compliant implementation MUST support baseline subscription semantics for matching updates. Profiles MAY refine subscription behavior.

### 8.6 Acknowledgements and Delivery Outcomes

A publish, query, subscription, or other protocol operation MUST result in a meaningful success, rejection, or partial-outcome indication.

An implementation MUST distinguish at least between accepted, rejected, unavailable, unauthorized, unsupported, and partial or lossy outcomes where those categories apply.

### 8.7 Error Semantics

The core defines baseline error categories and semantics. Profiles MAY define more specific error conditions.

A core-compliant implementation MUST expose errors in a form that allows a client to distinguish at least invalid input, authentication failure, authorization failure, unsupported capability or profile, not found, policy rejection, and internal failure.

### 8.8 Idempotency

Where repeating an operation would have the same intended semantic effect, a core-compliant implementation SHOULD treat the operation as idempotent or return a result that makes duplicate handling explicit.

### 8.9 Pagination and Streaming

The core permits paginated query results and streaming or incremental delivery for subscriptions and large result sets.

Where pagination or streaming is used, the implementation MUST preserve enough continuity information for a client to resume or continue safely according to core rules.

### 8.10 Conflict Handling and Consistency Model

The core provides baseline consistency through event validation, deterministic reference interpretation, baseline ordering, and baseline conflict resolution.

The core does not require global instantaneous consistency. A client MUST be able to distinguish between authoritative absence, temporary unavailability, policy-limited visibility, and unsupported operations where those distinctions are relevant.

## 9. Relay Requirements

### 9.1 Minimum Relay Responsibilities

A core-compliant relay MUST provide a meaningful baseline application-facing surface.

At minimum, a core-compliant relay MUST support:

- validation and acceptance or rejection of Overnet core event publication
- retrieval of events by reference
- retrieval of derived objects by reference
- baseline query and filtering operations
- baseline subscriptions
- capability discovery for the current context
- baseline authorization behavior
- provenance exposure
- baseline error semantics
- protocol-level handling of revision, supersession, and removal semantics

The [Overnet Relay Specification](relay.md) defines the first concrete companion surface for satisfying those responsibilities.

### 9.2 Capability Advertisement

A relay MUST advertise its supported core capabilities accurately for the current client or policy context.

A relay MAY withhold capability details that are not available to the current client, but it MUST NOT claim support for behavior that is unavailable in that context.

### 9.3 Validation and Verification

A relay MUST verify underlying Nostr event validity and MUST validate Overnet core requirements before accepting a core event.

A relay MUST reject events that fail core validation, profile validation where applicable, or local policy enforcement.

### 9.4 Policy Enforcement

A relay MAY apply local policy concerning access control, moderation, rate limiting, retention, visibility, and related matters.

Local policy MUST NOT silently change the defined meaning of core protocol elements.

### 9.5 Storage and Retention Controls

A relay MAY implement deployment-specific storage and retention policy.

A relay MUST expose enough protocol-level information for clients to distinguish between removed data, unavailable data, policy-hidden data, and unsupported retrieval where those states are observable.

### 9.6 Abuse Prevention and Rate Limiting

A relay MAY apply rate limits, quota controls, abuse detection, or other resource-protection mechanisms.

Such mechanisms SHOULD be reflected through baseline error or outcome semantics rather than through silent misbehavior.

### 9.7 Audit and Observability Requirements

A relay SHOULD retain enough internal observability to explain acceptance, rejection, policy-limited visibility, and capability exposure for operational and debugging purposes.

This requirement does not imply public disclosure of internal logs.

### 9.8 Optional Relay Features

Any relay behavior beyond the required baseline MAY be exposed through advertised capabilities and supported profiles.

## 10. Client and Application Requirements

### 10.1 Minimum Client Responsibilities

A core-compliant client MUST provide a meaningful baseline developer-facing surface.

At minimum, a core-compliant client MUST be able to:

- authenticate using the baseline Nostr-based model where required
- publish Overnet core events
- retrieve events by reference
- retrieve derived objects by reference
- perform baseline query and filtering operations
- establish and consume baseline subscriptions
- inspect capability exposure for the current context
- inspect provenance
- handle baseline error categories

### 10.2 Capability Negotiation

A client MUST NOT assume support for optional behavior that has not been advertised or otherwise guaranteed by the core.

A client SHOULD use capability discovery before relying on optional capabilities or profiles.

### 10.3 Authentication and Authorization Flows

A client MUST preserve the distinction between authentication success and authorization success.

A client SHOULD present or expose enough information for developers to distinguish authorization failure from unsupported capability, policy restriction, or other failure classes.

### 10.4 Local State and Caching

A client MAY cache events, objects, query results, capability information, and related state.

A client that caches derived objects SHOULD preserve enough source event and provenance information to update or invalidate that state correctly.

### 10.5 Offline and Reconnect Behavior

A client MAY operate with partial or cached state while offline.

Upon reconnection, a client SHOULD use baseline query and subscription semantics to reconcile state and SHOULD avoid treating stale cached data as authoritative when fresher data is available.

### 10.6 User Consent and Security-Sensitive Actions

A client SHOULD distinguish between ordinary read operations and operations that publish, revise, remove, delegate, or otherwise materially affect Overnet state.

Profiles MAY define stricter requirements for user confirmation or policy-aware presentation.

### 10.7 Error Handling Requirements

A client MUST handle baseline error categories deterministically and MUST NOT collapse all failures into an undifferentiated generic error where the protocol supplies a more specific classification.

## 11. Capabilities, Profiles, and Extension Mechanisms

This section defines the mechanisms by which the Overnet core can be extended without changing the meaning of the core itself.

### 11.1 Capability Model

A capability is a named unit of optional or additional supported behavior.

The core defines the baseline capability model and requires accurate contextual advertisement of supported capabilities.

### 11.2 Capability Discovery

A core-compliant implementation MUST support capability discovery for the current context.

Capability discovery MUST be truthful for the current context and MAY be scoped by policy, authentication, authorization, or deployment configuration.

### 11.3 Base Profiles

The Overnet core itself defines the base profile that core-compliant implementations MUST satisfy.

### 11.4 Optional Feature Profiles

Additional profiles MAY refine the core for particular application classes, adapter behavior, storage rules, security rules, or other specialized domains.

A profile is a named application specification. A profile MUST NOT contradict core semantics unless the core explicitly permits such refinement.

### 11.5 Version Negotiation

The core defines explicit version identifiers for the core itself and expects profiles to define their own versioning where needed.

An implementation MUST NOT claim support for a profile or capability version it does not implement.

### 11.6 Extension Namespaces

The core defines namespace rules for all extension points, including object types, event types, fields, tags, capabilities, and profile-defined additions.

Extensions MUST use namespaces that avoid collision with core-defined names and with other profile-defined names.

### 11.7 Experimental and Vendor Extensions

Experimental, private, deployment-local, and vendor-defined behavior MAY exist, provided that it is namespaced and does not silently alter required core semantics.

### 11.8 Deprecation Rules

A deprecated capability, field, or profile element SHOULD remain interpretable for a defined compatibility period where practical.

Removal of a deprecated element MUST NOT be presented as backward-compatible support for that same element.

## 12. Data Storage and Lifecycle

### 12.1 Storage Classes

The core allows implementations to store native and adapted data using deployment-specific storage strategies.

The core does not require a single storage engine or replication design.

### 12.2 Retention Model

Retention policy is deployment-specific unless a profile states otherwise.

The core requires that retention-related outcomes exposed to clients be represented meaningfully through protocol semantics such as availability, removal, policy limitation, or not found.

### 12.3 Replication and Redundancy

The core permits replicated or redundant storage, but does not require a specific replication mechanism in this document.

Future companion specifications MAY define storage or replication profiles.

### 12.4 Garbage Collection

Garbage collection, compaction, and storage reclamation are deployment concerns.

These mechanisms MUST NOT silently change the protocol-level meaning of retained visible data.

### 12.5 Export and Migration Considerations

An implementation SHOULD preserve enough canonical event, object, reference, and provenance information to support export, migration, or rebuild of derived state where practical.

### 12.6 Operator Policy Controls

Operators MAY define local storage classes, retention limits, and archival policies.

Such controls SHOULD be surfaced to clients through capabilities, policy-aware behavior, or other explicit semantics rather than through silent inconsistency.

## 13. Security and Privacy Requirements

### 13.1 Mandatory Security Properties

A core-compliant implementation MUST preserve underlying Nostr event verification and MUST enforce the core rules for provenance, authorization, and contextual capability honesty.

### 13.2 Authorization Requirements

The core defines a baseline authorization model.

An implementation MUST distinguish authentication from authorization and MUST NOT treat optional capability support as equivalent to permission to perform an action.

### 13.3 Provenance and Integrity Requirements

All Overnet data MUST carry provenance as defined in §6.3.3.

Adapted data MUST disclose its origin, relevant mapping context, and any known translation limitations as defined in §6.3.3 and §6.3.4.

A consumer MUST NOT present adapted data as carrying authoritative external identity, authorship, or authority except as permitted by the provenance verification model in §7.9. Adapted external attribution that has not been verified as `authoritative` MUST NOT be represented as authoritative.

### 13.4 Privacy Considerations

Implementations SHOULD minimize unnecessary exposure of identity, mapping, capability, and policy information.

Capability discovery MAY be scoped, but when disclosed it MUST remain accurate for the current context.

When an implementation claims support for an end-to-end encrypted companion specification, only authorized endpoints MAY access the protected plaintext for that specification.

Relay acceptance, storage, forwarding, capability exposure, query support, or subscription support MUST NOT be interpreted as authorization to inspect decrypted encrypted content.

### 13.5 Metadata Exposure

A relay or service MAY limit metadata disclosure according to policy, provided that it does not misrepresent protocol state.

An implementation SHOULD make clear when information is hidden due to policy rather than nonexistent.

End-to-end encryption does not by itself eliminate metadata exposure. Companion specifications SHOULD identify which routing, timing, identity, or policy metadata remain observable even when content confidentiality is preserved.

### 13.6 Abuse, Spam, and Resource Exhaustion

Implementations MAY employ anti-abuse and anti-exhaustion controls such as rate limiting, filtering, moderation, and quota enforcement.

Such controls SHOULD be represented through defined outcome or error semantics rather than by silent corruption of core behavior.

## 14. Conformance

### 14.1 Core Client Conformance

A core-compliant client MUST satisfy all mandatory client requirements in this specification.

A core-compliant client that renders or acts on adapted data MUST satisfy the consumer conformance obligations for provenance verification in §7.9.3.

Support for optional capabilities or profiles is not implied unless explicitly claimed.

### 14.2 Core Relay Conformance

A core-compliant relay MUST satisfy all mandatory relay requirements in this specification.

Support for optional capabilities or profiles is not implied unless explicitly claimed.

### 14.3 Profile Conformance

An implementation claiming profile support MUST satisfy all mandatory requirements of that profile in addition to the Overnet core requirements on which it depends.

### 14.4 Version Compatibility Rules

An implementation MUST identify the core version it supports and MUST NOT claim compatibility with unsupported profile or capability versions.

### 14.5 Testability Requirements

Conformance requirements in the core SHOULD be written so that they can be verified through fixtures, protocol tests, conformance suites, or other repeatable means.

An implementation MUST NOT claim conformance on the basis of partial or approximate support for mandatory behavior.

## 15. Open Issues and Future Work

This section is informative.

The following topics remain intentionally open or are expected to be completed by companion specifications or later revisions:

- advanced query and filter behavior beyond the current relay companion specification
- subscription resume and continuation rules
- the exact session-oriented authentication handshake details where used
- stronger identity continuity, rotation, and revocation mechanisms
- standard discovery and distribution mechanisms for adapter authority records (§6.15), including how consumers obtain candidate records before deciding whether to anchor them
- governance conventions for delegated or transitive trust anchors and for reconciling competing authority records for the same origin
- concrete reference tag conventions for revision, supersession, and removal relationships
- detailed adapter specifications for systems such as IRC, email, and GitLab-like systems
- a language-agnostic program runtime or program-protocol specification for Overnet programs
- application profile specifications such as chat, email, code hosting, marketplaces, and websites
- storage and replication profiles
- registry governance and publication details
- registration of Overnet kind numbers (7800, 37800, 7801) with the Nostr kind registry

## Appendix A. Rationale

## Appendix B. Security Considerations

## Appendix C. Privacy Considerations

## Appendix D. Change Log
