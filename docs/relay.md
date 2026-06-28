# Overnet Relay Specification

## Status of This Document

This document defines the Overnet Relay as a companion specification to the Overnet core.

It is a working draft.

Unless stated otherwise, the main body of this document is normative.

## 1. Purpose

This specification defines the first concrete relay-facing semantics for Overnet.

The Overnet core defines:

- the relay role
- the relay trust boundary
- minimum relay responsibilities
- core Overnet event validity rules

This document defines:

- the baseline relay metadata surface
- baseline event publication behavior
- the first concrete event query filter surface
- baseline subscription behavior
- baseline negentropy reconciliation support
- a narrow derived-object read surface
- baseline relay outcome codes

This version is intentionally narrow. It does not attempt to fully define replication policy, archive semantics, large-object storage, pricing flows, or advanced moderation models.

## 2. Relationship to the Overnet Core and to Nostr

This specification is a companion specification to the Overnet core.

The Overnet core remains authoritative for:

- event, object, and provenance semantics
- relay trust boundaries
- minimum relay responsibilities
- conformance requirements on Overnet data

This specification is authoritative for:

- the first concrete relay query and subscription surface
- relay metadata fields needed for client interoperability
- the first baseline derived-object read shape

Overnet remains Nostr-native.

A conforming Overnet relay may be implemented atop one or more underlying Nostr relays, may embed Nostr relay behavior directly, or may combine both approaches.

In this version:

- event publication uses the NIP-01 `EVENT` message
- event queries and subscriptions use the NIP-01 `REQ` and `CLOSE` messages
- event-set reconciliation uses the NIP-77 `NEG-OPEN`, `NEG-MSG`, and `NEG-CLOSE` messages
- relay-to-client event delivery uses the NIP-01 `EVENT`, `EOSE`, `OK`, `NOTICE`, and `CLOSED` messages
- machine-readable relay metadata extends the NIP-11 relay information document
- the narrow derived-object read surface uses a companion HTTP endpoint on the same relay origin

This specification does not define a new transport for event publication, event queries, or event subscriptions.

This specification also does not define the full Overnet storage and replication profile. A later companion specification is expected to define large-data storage and replication behavior, potentially reusing `NIP-35` where appropriate.

Encrypted relay-carried private direct messages are defined separately in the [Overnet Private Messaging Specification](private-messaging.md).

## 3. Scope of This Version

This version defines the first generic relay profile.

A generic relay under this specification MUST support all of the following:

- publication of Overnet core events
- validation and structured acceptance or rejection of published events
- retrieval of matching visible events through the baseline query surface
- replay plus live-update subscriptions through the baseline subscription surface
- NIP-77 negentropy reconciliation sessions for matching visible events
- retrieval of a narrow derived object view by direct object reference
- machine-readable metadata describing relay capabilities, limits, and service policy

This version does not define:

- archive-grade durability guarantees
- replication-count guarantees
- peer-assisted large-data distribution behavior
- pricing or payment execution flows
- relay peering policy, topology, scheduling, or filter selection strategy
- advanced subscription resume semantics
- broad object-list queries or object subscriptions

## 4. Relay Profiles

### 4.1 Generic Relay

A generic relay is the baseline Overnet relay role.

Every generic relay MUST implement the behavior defined in this specification.

### 4.2 Optional Relay Profiles

This specification defines the following optional profile names for advertised relay metadata:

- `volunteer-basic`
- `volunteer-plus`
- `archive`
- `paid`
- `private`

This version assigns descriptive meaning to those names but does not define mandatory numeric limits for them.

### 4.3 `volunteer-basic`

A relay advertising `relay_profile` value `volunteer-basic`:

- MUST implement the full generic relay behavior
- MAY enforce bounded retention, bandwidth, subscription, and storage limits
- SHOULD use safe bounded defaults suitable for ordinary volunteer operators
- MUST NOT claim archive-grade durability merely by virtue of using the `volunteer-basic` name

## 5. Relay Information Document

### 5.1 Overview

The baseline machine-readable relay metadata surface is the NIP-11 relay information document extended with an `overnet` object.

The `overnet` object MUST include:

| Field | Type | Required | Description |
|---|---|---|---|
| `core_version` | string | yes | Supported Overnet core version |
| `relay_profile` | string | yes | Advertised relay profile name |
| `capabilities` | array of strings | yes | Supported Overnet relay capabilities |
| `limits` | object | yes | Machine-readable service limits |
| `service_policies` | object | yes | Machine-readable access policy for baseline services |
| `profile_contracts` | object | no | Machine-readable profile contract policy and advertised selected contract context |
| `pricing_url` | string | no | Human-readable pricing or operator policy page |

The `capabilities` array for a generic relay MUST include all of:

- `overnet.events.publish`
- `overnet.events.query`
- `overnet.events.subscribe`
- `overnet.events.sync`
- `overnet.objects.read`

Optional capability names MAY be advertised for behavior beyond this specification.

If the relay information document includes the standard NIP-11 `supported_nips` field, a generic relay MUST include `77`.

The `limits` object MUST include:

| Field | Type | Required | Description |
|---|---|---|---|
| `retention_seconds` | integer or null | yes | Retention horizon in seconds, or `null` when not declared |
| `max_event_bytes` | integer | yes | Maximum accepted event size in bytes |
| `max_filter_limit` | integer | yes | Maximum accepted `limit` value for one filter |
| `max_subscriptions` | integer | yes | Maximum concurrent subscriptions per client connection |
| `max_negentropy_sessions` | integer | yes | Maximum concurrent NIP-77 negentropy sessions per client connection |

The `service_policies` object MUST include:

| Field | Type | Required | Description |
|---|---|---|---|
| `publish` | string | yes | One of `open`, `auth`, `paid`, `closed` |
| `query` | string | yes | One of `open`, `auth`, `paid`, `closed` |
| `subscribe` | string | yes | One of `open`, `auth`, `paid`, `closed` |
| `sync` | string | yes | One of `open`, `auth`, `paid`, `closed` |
| `object_read` | string | yes | One of `open`, `auth`, `paid`, `closed` |

### 5.2 Profile Contract Metadata

Profile contracts are defined by the [Overnet core Profile section](core.md#326-profile) and the [Overnet Profile Contract Specification](profile-contracts.md).

A relay MAY select one or more profile contracts as local relay policy.

If a relay enforces profile contract policy for publish acceptance, the relay information document's `overnet` object MUST include a `profile_contracts` object that accurately describes that policy.

The `profile_contracts` object MUST include:

| Field | Type | Required | Description |
|---|---|---|---|
| `configured` | boolean | yes | Whether the relay has a selected profile contract context |
| `enforced` | boolean | yes | Whether selected profile contracts affect publish acceptance |
| `policy` | string | yes | One of `off`, `known`, `required` |
| `profiles` | array of strings | yes | Profile namespaces selected by the relay |
| `event_types` | array of strings | yes | Event type names defined by the selected profile contract context |

If `profile_contracts` is present, `configured` MUST be `true`.

The `policy` field has the following meaning:

- `off`: selected profile contracts are advertised but do not affect publish acceptance.
- `known`: events whose `overnet_et` matches a selected profile contract event type are subject to profile-aware event validation. Other core-valid events are not rejected only because no selected profile contract defines their event type.
- `required`: non-core events are rejected unless their `overnet_et` matches exactly one event type definition in the selected profile contract context and the event passes profile-aware event validation.

Core event types defined by the Overnet core, including [`core.delegation`](core.md#614-delegation-events) and [`core.removal`](core.md#613-removal-and-tombstones), remain governed by core validation. A relay MUST NOT reject a core event type only because no selected profile contract defines that core event type.

When `policy` is `known` or `required`, the selected profile contract context MUST be valid according to the Overnet Profile Contract Specification.

The relay information document MAY include additional `profile_contracts` fields for contract identifiers, retrieval locations, hashes, or operator-specific contract metadata.

The following `profile_contracts` object is informative.

```json
{
  "configured": true,
  "enforced": true,
  "policy": "known",
  "profiles": ["chat"],
  "event_types": ["chat.message"]
}
```

### 5.3 Example Relay Information Document

The following example is informative.

```json
{
  "name": "Volunteer Relay 01",
  "description": "Bounded community Overnet relay",
  "supported_nips": [1, 11, 42, 77],
  "overnet": {
    "core_version": "0.1.0",
    "relay_profile": "volunteer-basic",
    "capabilities": [
      "overnet.events.publish",
      "overnet.events.query",
      "overnet.events.subscribe",
      "overnet.events.sync",
      "overnet.objects.read"
    ],
    "limits": {
      "retention_seconds": 604800,
      "max_event_bytes": 65536,
      "max_filter_limit": 100,
      "max_subscriptions": 32,
      "max_negentropy_sessions": 8
    },
    "service_policies": {
      "publish": "open",
      "query": "open",
      "subscribe": "open",
      "sync": "open",
      "object_read": "open"
    }
  }
}
```

## 6. Relay Outcome Codes

### 6.1 Overview

This specification defines the following relay outcome codes:

- `accepted`
- `invalid`
- `unauthorized`
- `payment_required`
- `policy_denied`
- `not_found`
- `unsupported`
- `unavailable`

### 6.2 Nostr Message Prefix Rules

For `OK` and `CLOSED` messages:

- successful results MUST begin with `accepted:`
- unsuccessful results MUST begin with one of:
  - `invalid:`
  - `unauthorized:`
  - `payment_required:`
  - `policy_denied:`
  - `not_found:`
  - `unsupported:`
  - `unavailable:`

The text after the prefix is implementation-defined human-readable detail.

## 7. Event Publication

### 7.1 Publish Message

Clients publish Overnet events using the NIP-01 `EVENT` message with a Nostr event claiming Overnet semantics.

### 7.2 Validation Pipeline

Before accepting an Overnet publish, a relay MUST perform all of the following:

1. verify Nostr event structure and signature validity
2. verify Overnet core validity
3. verify any applicable companion profile requirements, including the profile contract policy advertised in §5.2
4. apply current operator policy for the client and event

When a relay rejects a publish because profile-aware validation fails or because the relay's profile contract policy rejects an otherwise core-valid non-core event, the relay MUST return an `OK` message with success value `false` and a message beginning with `invalid:`.

If the event is accepted, the relay MUST return an `OK` message with:

- the event id
- success value `true`
- a message beginning with `accepted:`

If the event is rejected, the relay MUST return an `OK` message with:

- the event id
- success value `false`
- a message beginning with one of the failure prefixes defined in §6.2

### 7.3 Example Publish Result

The following example is informative.

```json
["OK", "9c0f...", true, "accepted: stored"]
```

```json
["OK", "9c0f...", false, "invalid: overnet core validation failed"]
```

## 8. Event Query Filters

### 8.1 Filter Object

The baseline event query and subscription surface uses the NIP-01 `REQ` message.

For this specification, a generic relay MUST support the following filter keys:

- `ids`
- `authors`
- `kinds`
- `since`
- `until`
- `limit`
- `#overnet_v`
- `#overnet_et`
- `#overnet_ot`
- `#overnet_oid`

The `#overnet_v`, `#overnet_et`, `#overnet_ot`, and `#overnet_oid` fields are Overnet-defined extensions to the NIP-01 filter object shape.

Those fields are arrays of strings and match against the corresponding Overnet tag values.

A relay MAY support additional filter keys.

### 8.2 Matching Rules

An event matches a filter only if it satisfies every filter key present in that filter object.

If a `REQ` message contains multiple filter objects, a visible event matches the request if it matches at least one of those filter objects.

### 8.3 Ordering

For the initial stored replay phase of a subscription, matching visible events MUST be sent in ascending order by:

1. `created_at`
2. `id`

### 8.4 Example Query

The following example is informative.

```json
[
  "REQ",
  "sub-1",
  {
    "kinds": [7800],
    "#overnet_et": ["chat.message"],
    "#overnet_ot": ["chat.channel"],
    "#overnet_oid": ["irc:local:#overnet"],
    "limit": 50
  }
]
```

## 9. Event Subscriptions

### 9.1 Replay Plus Live Updates

When a relay accepts a `REQ` subscription:

1. it MUST send the matching visible stored events for the request
2. it MUST then send `EOSE`
3. it MUST then continue sending newly accepted visible matching events until the subscription is closed or the connection ends

This version does not define resume or continuation tokens.

### 9.2 Closing a Subscription

Clients close a subscription using the NIP-01 `CLOSE` message.

If a relay rejects a `REQ` request or terminates a request early, it MUST send `CLOSED` with a reason beginning with one of the prefixes defined in §6.2.

## 10. Negentropy Reconciliation

### 10.1 Required Support

A generic relay MUST support NIP-77 negentropy reconciliation using:

- `NEG-OPEN`
- `NEG-MSG`
- `NEG-CLOSE`

Negentropy reconciliation is a set-reconciliation surface over currently visible events. It does not itself transfer events. Event upload and download continue to use the ordinary NIP-01 `EVENT` and `REQ` flows described by NIP-77.

The accepted negentropy session filter defines the visible event set being reconciled for that session.

### 10.2 Filter Compatibility

NIP-77 defines the `NEG-OPEN` filter as a NIP-01 filter object.

Accordingly, this version of the Overnet Relay Specification requires generic relays to support negentropy sessions for:

- standard NIP-01 filter fields such as `ids`, `authors`, `kinds`, `since`, and `until`
- the Overnet compatibility mirror tag filters `#v`, `#t`, `#o`, and `#d`

The Overnet compatibility mirror tags are defined by the Overnet core as exact mirrors of:

- `#v` -> `overnet_v`
- `#t` -> `overnet_et`
- `#o` -> `overnet_ot`
- `#d` -> `overnet_oid`

For interoperable Overnet object and tag synchronization over negentropy, clients and relays SHOULD use `#v`, `#t`, `#o`, and `#d` instead of nonstandard `#overnet_*` negentropy filters.

This version does not require `#overnet_v`, `#overnet_et`, `#overnet_ot`, or `#overnet_oid` inside `NEG-OPEN` filters.

An implementation MAY support additional negentropy filter keys, but such support is implementation-specific unless and until a later Overnet companion specification standardizes a broader interoperable mapping.

### 10.3 Example Negentropy Filter

The following example is informative.

```json
[
  "NEG-OPEN",
  "neg-1",
  {
    "kinds": [7800, 37800, 7801],
    "#t": ["chat.message"],
    "#o": ["chat.channel"],
    "#d": ["irc:local:#overnet"]
  },
  "61"
]
```

## 11. Derived Object Reads

### 11.1 Scope

This version defines only a narrow derived-object read surface by direct object reference.

This version does not define object search, object subscriptions, or broad object-list queries.

### 11.2 Endpoint

A generic relay MUST provide the following HTTP endpoint:

```text
GET /.well-known/overnet/v1/object?type=<object_type>&id=<object_id>
```

The `type` parameter is the Overnet object type.

The `id` parameter is the Overnet object identifier.

### 11.3 Successful Response

On success, the relay MUST return HTTP `200` with a JSON object containing:

| Field | Type | Required | Description |
|---|---|---|---|
| `object_type` | string | yes | Requested object type |
| `object_id` | string | yes | Requested object identifier |
| `removed` | boolean | yes | Whether the object is currently represented as removed in the visible relay view |
| `state_event` | object or null | yes | Latest visible matching kind `37800` event, or `null` |
| `removal_event` | object or null | yes | Latest visible matching kind `7801` event for the same object reference, or `null` |

For this version:

- `state_event` MUST be the latest visible matching kind `37800` event by `created_at` then `id`
- `removal_event` MUST be the latest visible matching kind `7801` event by `created_at` then `id`
- the response MUST reflect current relay visibility after policy filtering

### 11.4 Error Responses

If the relay cannot fulfill the object read, it MUST return one of the following HTTP status codes with a JSON body containing `error.code` set to the corresponding relay outcome code:

| HTTP status | `error.code` |
|---|---|
| `400` | `invalid` |
| `401` | `unauthorized` |
| `402` | `payment_required` |
| `403` | `policy_denied` |
| `404` | `not_found` |
| `501` | `unsupported` |
| `503` | `unavailable` |

### 11.5 Example Object Read Response

The following example is informative.

```json
{
  "object_type": "chat.channel",
  "object_id": "irc:local:#overnet",
  "removed": false,
  "state_event": {
    "id": "7b5d...",
    "kind": 37800
  },
  "removal_event": null
}
```

## 12. Optional Storage and Replication Profiles

This specification does not define the full Overnet storage and replication model.

A relay MAY advertise additional capabilities beyond this specification for:

- stronger durability classes
- archive behavior
- relay-local or relay-assisted replication
- large-object storage or peer-assisted distribution

A later companion specification is expected to define that behavior concretely.

Where large-object distribution is defined later, Overnet MAY reuse `NIP-35` rather than defining a separate torrent metadata format.

Encrypted relay-carried private direct messages defined by the [Overnet Private Messaging Specification](private-messaging.md) are outside the public event query and generic derived-object read guarantees defined by this specification.

## 13. Conformance

### 13.1 Generic Relay Conformance

A relay claiming conformance to this specification as a generic relay MUST:

- expose an NIP-11 relay information document with the required `overnet` fields from §5
- support event publication as defined in §7
- support event queries and subscriptions with the filter keys from §8
- support replay plus live subscriptions as defined in §9
- support negentropy reconciliation as defined in §10
- support the object-read endpoint from §11

Support for storage, replication, archive, payment, or other optional behavior is not implied unless explicitly advertised.

## 14. Open Issues and Future Work

This section is informative.

The following topics remain open for later relay-related work:

- replication and durability profiles
- relay-assisted or peer-assisted large-object distribution
- concrete pricing and payment execution flows
- broader object query and object subscription behavior
- subscription resume and continuation semantics
- relay-to-relay peering policy, topology, scheduling, and filter selection behavior
- whether ordinary event queries should standardize the `#v`, `#t`, `#o`, and `#d` compatibility mirror filters in addition to the canonical `#overnet_*` filter keys

NIP-77 negentropy is expected to be the baseline foundation for later relay-to-relay peering work.
