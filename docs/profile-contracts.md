# Overnet Profile Contract Specification

## 1. Purpose

This document defines the Overnet Profile Contract v1 format.

A profile contract is a machine-readable description of how an Overnet profile
uses the Overnet core event envelope. It describes profile-specific object
types, event types, payload schemas, reference declarations, authorization
metadata, privacy expectations, capabilities, and fixtures.

A profile contract is not a new Overnet wire format. The canonical signed wire
unit remains a Nostr event conforming to the Overnet core profile.

A profile contract is not a central registry of every possible Overnet
application. Applications may define their own profile contracts. Standard
profiles may publish profile contracts for shared interoperability.

## 2. Relationship to the Core

The Overnet core defines the event envelope:

- Nostr event kind
- Overnet core tags
- compatibility mirror tags
- JSON `content`
- `content.provenance`
- `content.body`

A profile contract defines profile-specific meaning inside that envelope.

Core validation and profile-contract validation are separate steps.
Profile-aware event validation is applied only after Overnet core validation
succeeds. A profile contract cannot weaken, override, or remove any Overnet core
requirement.

Profile contracts are optional at the core protocol level. An application can
produce core-valid Overnet events without publishing, selecting, or advertising
a profile contract. Absence of a selected profile contract does not make a
core-valid event invalid.

Profile-aware event validation requires a selected valid profile contract. If no
profile contract is selected, profile-aware event validation is not performed.

Relays, clients, test harnesses, deployments, and applications can require
profile contracts for profile-aware features, local policy, test generation,
documentation, or interoperability. That requirement is outside core event
validity.

Profile-specific payload data remains inside `content.body`. A profile contract
does not define profile-specific top-level fields in `content`.

## 3. Contract Document Format

An Overnet Profile Contract v1 document is a UTF-8 JSON object.

The document MUST conform to
`schemas/profile-contract-v1.schema.json`.

The schema defines structural validity. The prose rules in this document define
cross-field validity where JSON Schema cannot express the full relationship.

The top-level object contains:

| Field | Type | Required | Description |
|---|---:|---:|---|
| `contract_version` | integer | yes | Contract format version. For this document, the value is `1`. |
| `profile` | string | yes | Profile namespace. |
| `profile_version` | string | yes | Version of the profile described by the contract. |
| `status` | string | yes | Contract stability status. |
| `description` | string | yes | Human-readable summary. |
| `capabilities` | array | yes | Capability identifiers associated with the profile. |
| `object_types` | object | yes | Object type definitions keyed by object type name. |
| `event_types` | object | yes | Event type definitions keyed by event type name. |
| `fixtures` | object | yes | Valid and invalid conformance fixture paths. |
| `extensions` | object | yes | Extension point for contract consumers that opt into additional semantics. |

Top-level fields other than the fields listed above are invalid outside
`extensions`.

### 3.1 Profile Namespace

The `profile` field is a non-empty lowercase namespace string matching:

```text
^[a-z0-9]+(?:[._-][a-z0-9]+)*$
```

Profile namespaces defined by the Overnet specification family, such as `core`,
`chat`, `identity`, and `irc`, are reserved for those specifications.

Non-core applications SHOULD use a namespace they control, such as a DNS-derived
or organization-derived prefix.

### 3.2 Profile Version

The `profile_version` field is a semantic version string matching:

```text
^\d+\.\d+\.\d+$
```

The `profile_version` describes the profile semantics. It is distinct from
`contract_version`, which describes the profile contract file format.

### 3.3 Status

The `status` field is one of:

- `draft`
- `stable`
- `deprecated`

## 4. Object Type Definitions

The `object_types` field maps object type names to object type definitions.

Each object type name starts with the contract `profile` value followed by a
period. For example, a contract with `"profile": "chat"` may define
`"chat.channel"`.

An object type definition contains:

| Field | Type | Required | Description |
|---|---:|---:|---|
| `description` | string | yes | Human-readable object type summary. |
| `id` | object | yes | Object identifier rules. |
| `state` | object | yes | Object state derivation declaration. |
| `extensions` | object | yes | Extension point. |

### 4.1 Object Identifier Rules

The `id` object contains:

| Field | Type | Required | Description |
|---|---:|---:|---|
| `scheme` | string | yes | Identifier scheme. |
| `pattern` | string or null | yes | Optional regular expression for object identifiers. |
| `examples` | array | yes | Example object identifiers. |

The `scheme` field is one of:

- `profile-defined`
- `uuid`
- `uri`
- `content-addressed`
- `opaque`

If `pattern` is not null, validators SHOULD treat it as a regular expression
that object identifiers for the object type are expected to match.

### 4.2 Object State Declaration

The `state` object contains:

| Field | Type | Required | Description |
|---|---:|---:|---|
| `derivation` | string | yes | How current object state is derived. |
| `state_event_type` | string or null | yes | Event type that carries current state, when applicable. |

The `derivation` field is one of:

- `event-log`
- `latest-per-author`
- `external-authoritative`
- `profile-defined`

If `state_event_type` is not null, it identifies an event type defined by the
same contract.

## 5. Event Type Definitions

The `event_types` field maps event type names to event type definitions.

Each event type name starts with the contract `profile` value followed by a
period. For example, a contract with `"profile": "chat"` may define
`"chat.message"`.

An event type definition contains:

| Field | Type | Required | Description |
|---|---:|---:|---|
| `description` | string | yes | Human-readable event type summary. |
| `kind` | integer | yes | Nostr kind used by the event. |
| `object_type` | string | yes | Object type targeted by the event. |
| `required_tags` | array | yes | Tags required by this profile event type. |
| `body_schema` | object | yes | JSON Schema for `content.body`. |
| `references` | array | yes | Declared references used by this event type. |
| `state_effect` | string | yes | Event effect on object state. |
| `authorization` | object | yes | Authorization model declaration. |
| `privacy` | string | yes | Payload privacy expectation. |
| `extensions` | object | yes | Extension point. |

### 5.1 Event Kind

The `kind` field is either `7800` or `37800`.

Kind `7800` is used for immutable Overnet event-log entries.

Kind `37800` is used for Overnet state events that rely on Nostr
parameterized-replaceable semantics.

Profile contracts do not define event type semantics for kind `7801`. Kind
`7801` is reserved for core removal events.

### 5.2 Object Type Link

The `object_type` field identifies an object type defined by the same contract.

The event type's `object_type` field corresponds to the event's `overnet_ot`
tag value.

### 5.3 Required Tags

The `required_tags` array includes:

- `overnet_v`
- `overnet_et`
- `overnet_ot`
- `overnet_oid`
- `v`
- `t`
- `o`
- `d`

If `kind` is `37800`, the `required_tags` array includes `d`.

The `required_tags` array MAY include additional tag names required by the
profile event type.

The `required_tags` array has no duplicate values.

### 5.4 Body Schema

The `body_schema` object defines the JSON Schema for `content.body`.

The `body_schema` value is a JSON object.

The `body_schema.type` value is `"object"`.

The `body_schema` object SHOULD use JSON Schema Draft 2020-12 vocabulary.

Profile contracts define only `content.body`. They do not define the top-level
`content.provenance` field or any profile-specific top-level `content` field.

### 5.5 Reference Declarations

Each `references` entry contains:

| Field | Type | Required | Description |
|---|---:|---:|---|
| `name` | string | yes | Profile-local reference name. |
| `required` | boolean | yes | Whether the reference is required. |
| `tag` | string or null | yes | Nostr tag carrying the reference, when tag-carried. |
| `target_object_type` | string or null | yes | Target object type, when object-typed. |
| `target_event_type` | string or null | yes | Target event type, when event-typed. |

If `target_object_type` is not null, it identifies an object type defined by the
same contract.

If `target_event_type` is not null, it identifies an event type defined by the
same contract.

When `required` is true and `tag` is not null, the reference is a required
tag-carried reference. Section 7 defines profile-aware event validation for
required tag-carried references.

### 5.6 State Effect

The `state_effect` field is one of:

- `none`
- `creates`
- `updates`
- `removes`
- `profile-defined`

The `state_effect` field is declarative. Object derivation rules that cannot be
expressed by one of these values remain profile-defined.

### 5.7 Authorization

The `authorization` object contains:

| Field | Type | Required | Description |
|---|---:|---:|---|
| `model` | string | yes | Authorization model identifier. |
| `description` | string | yes | Human-readable authorization summary. |

The `model` field is one of:

- `open`
- `author-is-object-owner`
- `delegated`
- `external-authority`
- `profile-defined`

A profile contract does not grant authorization by itself. It declares the
authorization model that implementations must enforce according to the profile
specification.

### 5.8 Privacy

The `privacy` field is one of:

- `public`
- `encrypted`
- `profile-defined`

If `privacy` is `encrypted`, the profile specification identifies the
applicable encryption or private-message companion specification. A profile
contract alone is not sufficient to define encryption behavior.

## 6. Fixtures

The `fixtures` object contains:

| Field | Type | Required | Description |
|---|---:|---:|---|
| `valid` | array | yes | Paths to valid fixtures. |
| `invalid` | array | yes | Paths to invalid fixtures. |

Fixture paths are relative to the repository or package root that publishes the
contract.

The fixture files for this specification live in `fixtures/profile-contracts/`.

Contract-document fixtures use the common fixture envelope with
`input.contract`:

```json
{
  "description": "fixture purpose",
  "input": {
    "contract": { "...": "..." }
  },
  "expected": {
    "overnet_valid": true,
    "profile_contract_valid": true
  }
}
```

Profile-event fixtures use the common fixture envelope with `input.event` and
either `input.contract` or `input.contract_fixture`:

```json
{
  "description": "fixture purpose",
  "input": {
    "contract_fixture": "fixtures/profile-contracts/valid-chat-message-contract.json",
    "event": { "...": "..." }
  },
  "expected": {
    "overnet_valid": true,
    "profile_contract_valid": true,
    "profile_event_valid": true
  }
}
```

When no profile contract is selected, profile-aware event validation is not
applicable. Fixtures for this case set `expected.profile_contract_selected` to
`false` and `expected.profile_event_validation` to `"not_applicable"`.

For invalid profile contracts, `expected.overnet_valid` is `false`,
`expected.profile_contract_valid` is `false`, and `expected.reason` identifies
the failed rule.

For invalid profile events where core validation has already succeeded,
`expected.overnet_valid` is `true`, `expected.profile_contract_valid` is `true`,
`expected.profile_event_valid` is `false`, and `expected.reason` identifies the
failed profile-aware validation rule.

## 7. Profile-Aware Event Validation

This section defines how profile-aware validators use a contract after core
event validation succeeds.

Profile-aware event validation is only active when a valid profile contract is
selected.

A profile-aware validator MUST extract the event type from the `overnet_et` tag.

A profile-aware validator MUST find an event type definition with a matching
name in the selected profile contract.

A profile-aware validator MUST reject an event when the event's Nostr `kind`
does not equal the contract event type's `kind`.

A profile-aware validator MUST reject an event when the event's `overnet_ot`
tag does not equal the contract event type's `object_type`.

A profile-aware validator MUST reject an event when any tag listed in
`required_tags` is absent.

A profile-aware validator MUST reject an event when `content.body` does not
conform to the contract event type's `body_schema`.

A profile-aware validator MUST apply required tag-carried reference checks
defined in `references`.

Authorization enforcement is profile-specific. Passing the profile contract
shape checks does not prove that the event is authorized.

## 8. Discovery and Publication

Profile contracts MAY be published in specification repositories, application
repositories, relay metadata, package metadata, or other distribution channels.

The core protocol does not require a central registry of profile contracts.

Implementations that advertise support for a profile SHOULD also advertise the
contract identifier or retrieval location they use for that profile.

## 9. Informative Example

The following example is informative.

```json
{
  "contract_version": 1,
  "profile": "chat",
  "profile_version": "1.0.0",
  "status": "draft",
  "description": "Example chat profile contract.",
  "capabilities": ["chat.events"],
  "object_types": {
    "chat.channel": {
      "description": "A chat channel.",
      "id": {
        "scheme": "profile-defined",
        "pattern": "^channel:[a-z0-9][a-z0-9._-]*$",
        "examples": ["channel:general"]
      },
      "state": {
        "derivation": "event-log",
        "state_event_type": null
      },
      "extensions": {}
    }
  },
  "event_types": {
    "chat.message": {
      "description": "A message sent to a chat channel.",
      "kind": 7800,
      "object_type": "chat.channel",
      "required_tags": [
        "overnet_v",
        "overnet_et",
        "overnet_ot",
        "overnet_oid",
        "v",
        "t",
        "o",
        "d"
      ],
      "body_schema": {
        "type": "object",
        "additionalProperties": false,
        "required": ["text"],
        "properties": {
          "text": {
            "type": "string",
            "minLength": 1
          }
        }
      },
      "references": [],
      "state_effect": "creates",
      "authorization": {
        "model": "open",
        "description": "Any authorized channel participant may send a message."
      },
      "privacy": "public",
      "extensions": {}
    }
  },
  "fixtures": {
    "valid": ["fixtures/profile-contracts/valid-profile-event-chat-message.json"],
    "invalid": []
  },
  "extensions": {}
}
```

## 10. Informative Use by overnet-burner

`overnet-burner` can consume profile contracts to generate realistic workloads.

For example, a burner scenario can request an event mix by event type:

```yaml
profiles:
  - path: ../spec/profiles/chat/profile-contract.json

workload:
  mix:
    - event_type: chat.message
      rate_per_second: 500
```

The burner can use the contract to choose the Nostr kind, required tags,
`content.body` shape, reference requirements, and report categories. The
contract remains a consumer input for burner; it is not authored by burner and
does not replace the profile specification.
