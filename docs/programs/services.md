# Overnet Program Services Specification

## Status of This Document

This document defines the baseline Overnet Program Services as a companion specification to the Overnet Program Runtime, the Overnet Program Protocol, and the Overnet core.

It is a working draft.

Unless stated otherwise, the main body of this document is normative.

## 1. Purpose

This specification defines the concrete runtime service methods exposed between an Overnet Program Runtime and an Overnet program.

The runtime specification defines which service families exist.

The protocol specification defines framing, message envelopes, and handshake behavior.

This document defines the baseline methods, parameters, results, and service-specific notifications for:

- configuration
- secrets
- document and object storage
- append-only event storage
- subscriptions
- relay-backed Nostr event publishing, querying, and subscriptions
- timers and scheduled jobs
- adapter sessions
- Overnet event emission
- Overnet state emission
- encrypted private-message emission
- capability advertisement emission
- logs and health reporting

## 2. Relationship to Other Specifications

This specification is a companion specification to:

- the Overnet core
- the Overnet Program Runtime specification
- the Overnet Program Protocol specification

The Overnet core remains authoritative for Overnet data semantics.

The Overnet Program Runtime specification remains authoritative for:

- runtime authority boundaries
- service families
- validation and permissions

The Overnet Program Protocol specification remains authoritative for:

- framing
- message envelopes
- request/response rules
- notifications

This document is authoritative for the baseline program service methods.

## 3. Conventions

### 3.1 Method Names

Method names are exact, case-sensitive strings.

This document uses namespaced method names of the form:

```text
<service>.<operation>
```

### 3.2 Required Permissions

Each service method defined in this document is subject to runtime permission enforcement.

A runtime MUST reject a method call when the calling program instance lacks the required permission for that service operation.

This document names baseline permission identifiers. A runtime MAY define more specific internal permissions, but it MUST preserve the baseline semantics defined here.

### 3.3 Result Shape

Unless otherwise stated:

- successful requests return a response with `ok = true`
- request-specific result data appears in the `result` object
- no result fields are implied beyond those defined here

## 4. Configuration Service

### 4.1 Overview

Configuration is host-managed and delivered during initialization.

The configuration service exists so that a program may inspect the currently active configuration and, where allowed, discover configuration metadata.

### 4.2 `config.get`

Required permission:

- `config.read`

Request:

```json
{
  "type": "request",
  "id": "cfg-1",
  "method": "config.get",
  "params": {}
}
```

Successful result:

| Field | Type | Required | Description |
|---|---|---|---|
| `config` | object | yes | Current effective configuration for the program instance |

### 4.3 `config.describe`

Required permission:

- `config.read`

Successful result MAY include:

| Field | Type | Required | Description |
|---|---|---|---|
| `schema` | object | no | Runtime-known configuration schema or schema reference |
| `schema_ref` | string | no | Runtime-known schema reference identifier or URI |
| `version` | string | no | Runtime-known configuration version |

## 5. Secrets Service

### 5.1 Overview

The secrets service allows a program to obtain runtime-managed access to named secret material supplied by the runtime.

The runtime MUST control which secrets are visible to each program instance.

The baseline program protocol MUST NOT require the runtime to return raw secret plaintext values to the program over ordinary JSON request/response messages.

Instead, the baseline secrets service issues opaque secret handles that remain meaningful only inside the runtime/host trust boundary.

### 5.2 Secret Handle Model

A secret handle is a runtime-issued opaque capability token representing access to a specific named secret.

The runtime MUST ensure that:

- secret handles are opaque to the program
- secret handles are scoped to the issuing program instance
- secret handles have a limited lifetime and MAY be revoked earlier by runtime policy
- services that accept secret handles resolve them inside the runtime or host boundary rather than requiring the program to receive raw secret plaintext

Programs MUST treat secret handles as sensitive values and SHOULD avoid logging or persisting them unless explicitly required by the runtime contract for a later service.

### 5.3 `secrets.get`

Required permission:

- `secrets.read`

Request parameters:

| Field | Type | Required | Description |
|---|---|---|---|
| `name` | string | yes | Runtime-known secret identifier |

Successful result:

| Field | Type | Required | Description |
|---|---|---|---|
| `name` | string | yes | Resolved secret identifier |
| `secret_handle` | object | yes | Runtime-issued opaque secret handle |

The `secret_handle` object MUST include:

| Field | Type | Required | Description |
|---|---|---|---|
| `id` | string | yes | Opaque runtime-issued handle identifier |
| `expires_at` | integer | yes | Unix timestamp after which the handle is no longer valid |

The runtime MUST NOT return the raw secret value as part of the baseline `secrets.get` response.

If the runtime cannot securely issue secret handles for a given program instance, the secrets service SHOULD be unavailable for that instance rather than falling back to returning raw secret plaintext.

The `params` object for `secrets.get` MAY include:

| Field | Type | Required | Description |
|---|---|---|---|
| `purpose` | string | no | Declared intended use for the issued handle |

Production-oriented runtimes SHOULD require `purpose` so that secret handles can be bound to an explicit intended use.

### 5.4 Purpose Binding and Handle Audience

The runtime MUST bind issued secret handles to an intended audience.

An audience MAY include:

- a declared purpose string
- one or more allowed runtime service methods
- one or more allowed adapter identifiers
- additional runtime-defined constraints that narrow how the handle may be consumed

If the program supplies a `purpose` value and the runtime issues a handle, the runtime MUST bind that handle to the declared purpose.

Any runtime-managed service that accepts secret handles MUST reject a handle presented outside its allowed audience, including mismatched purpose, method, adapter, consumer role, adapter slot, or instance binding.

Service-specific specifications that accept secret handles SHOULD define the expected purpose values or equivalent audience constraints.

### 5.5 Secret-Handle Inputs in Other Services

Later runtime-managed service methods MAY declare one or more parameters as secret-handle inputs.

Unless a later companion specification defines a more specific structure, a secret-handle input SHOULD use the same `secret_handle` object shape returned by `secrets.get`.

When a runtime resolves a secret-handle input for another service, the runtime MUST validate all of the following before using the referenced secret material:

- the handle exists
- the handle is still within its valid lifetime
- the handle has not been revoked
- the handle was issued for the same program instance
- the handle audience allows the consuming service and operation

The program MUST NOT be able to extend the lifetime or broaden the audience of a handle by editing the object returned from `secrets.get`.

The runtime remains authoritative for handle validity even if the program presents an `expires_at` value that appears current.

### 5.6 Access Control and Name Enumeration

The `secrets.read` permission authorizes access to the secrets service family, not unconditional access to every secret name known to the runtime.

The runtime MUST enforce per-secret authorization policy in addition to coarse-grained service permission checks.

Per-secret policy MAY be based on:

- program identity
- instance identity
- environment or deployment role
- operator policy
- service- or adapter-specific requirements

For unauthorized or unknown secret names, the runtime MUST return the same protocol error code and SHOULD avoid detail, timing, or metadata differences that allow programs to enumerate which secret names exist.

Production-oriented runtimes MUST support per-secret authorization policy in addition to coarse service-family permission checks.

### 5.7 Runtime-Advertised Secret Service Metadata

If the runtime includes service-level details for the secrets service in `runtime.init.params.services`, the secrets service object MAY include:

| Field | Type | Required | Description |
|---|---|---|---|
| `mode` | string | no | Secret access mode such as `handle_only` |
| `default_handle_ttl_ms` | integer | no | Default lifetime for issued secret handles |
| `purpose_binding_required` | boolean | no | Whether the runtime requires an explicit purpose on `secrets.get` |
| `supports_per_secret_acl` | boolean | no | Whether the runtime enforces per-secret authorization beyond coarse service permission |
| `supports_audit` | boolean | no | Whether the runtime records internal audit events for secret lifecycle and access |
| `supports_rotation` | boolean | no | Whether the runtime supports rotation of underlying secret material |
| `supports_revocation` | boolean | no | Whether the runtime supports early handle revocation before expiry |

If the runtime conforms to this handle-only model, `mode` SHOULD be `handle_only`.

### 5.8 Plaintext Handling and Memory Hygiene

This specification does not require or assume portable guaranteed zeroization of secret plaintext inside high-level language runtimes.

Security for the baseline secrets service is achieved primarily by:

- preventing plaintext exposure to programs over the ordinary protocol
- minimizing plaintext lifetime
- minimizing plaintext copies
- isolating privileged secret consumers
- enforcing revocation, rotation, auditing, and least privilege

Therefore:

- the runtime MUST resolve secret handles as late as practical for the consuming operation
- the runtime MUST use resolved plaintext only for the immediate consuming operation
- the runtime MUST NOT persist resolved plaintext in ordinary runtime-managed configuration, storage, session state, or notifications visible to programs
- the runtime MUST discard any temporary plaintext copies as soon as practical after handoff to the privileged consumer
- implementations MAY perform best-effort memory clearing of temporary plaintext buffers, but MUST NOT claim guaranteed destruction unless they document a concrete platform-specific secure-erasure mechanism

If a runtime-managed operation requires a component to receive plaintext, that component becomes part of the secret trust boundary for the duration of that operation.

### 5.9 Redaction, Logging, and Audit

The runtime MUST NOT place raw secret plaintext into protocol-visible:

- successful service results
- structured error details
- runtime-generated notifications
- service metadata advertised during initialization

The runtime SHOULD avoid placing secret-handle ids into protocol-visible errors or notifications unless a service contract explicitly requires it.

If the runtime records audit data for secret access, it SHOULD record:

- program or instance identity
- requested secret name or policy identifier
- issuance time
- expiry time
- purpose or audience binding when present
- success or failure outcome

Production-oriented runtimes MUST record internal audit events for at least:

- handle issuance attempts
- handle resolution attempts
- authorization denials
- expiry
- revocation
- rotation

The runtime MUST NOT place raw secret plaintext into audit records.

The runtime SHOULD avoid placing raw handle ids into audit records unless an implementation-specific operational requirement makes that necessary.

### 5.10 Revocation and Rotation

The runtime MUST be able to revoke secret handles before their nominal expiry time.

At minimum, the runtime MUST revoke or invalidate all outstanding secret handles for a program instance when that instance terminates.

The runtime SHOULD also revoke or invalidate outstanding secret handles when:

- the relevant secret value rotates
- operator policy changes
- the program loses authorization for the secret
- the runtime detects suspected handle leakage or misuse

If a secret rotates behind a stable secret name, the runtime SHOULD allow the program to request a new handle without requiring the program to receive raw secret plaintext.

Production-oriented runtimes MUST support both revocation and rotation.

### 5.11 Host Storage Requirements

For production-oriented runtimes, secret material MUST be sourced from a host-managed secret provider or equivalent secure host facility rather than ordinary program configuration or ordinary runtime-managed document storage.

Examples include:

- operating-system credential stores
- dedicated secret managers
- KMS-backed secret stores
- HSM-backed or hardware-protected facilities where available

The runtime MUST NOT persist raw secret plaintext in baseline runtime-managed:

- configuration payloads delivered to programs
- document storage
- append-only event storage
- subscription notifications
- timer payloads

If the runtime must materialize plaintext in memory in order to complete a runtime-managed operation, it SHOULD minimize the scope and lifetime of that plaintext as much as practical.

### 5.12 Bearer-Capability and Transport Considerations

Secret handles are bearer capabilities.

Any program that possesses a valid handle may be able to cause the runtime to consume the associated secret within the handle's allowed audience.

Therefore:

- programs MUST treat secret handles as sensitive
- runtimes SHOULD keep handle lifetimes short
- runtimes SHOULD bind handles narrowly to audience and purpose
- runtimes SHOULD redact handle ids from logs and debug output

If a runtime transports program protocol traffic across a boundary other than a local supervised process transport, that transport MUST provide confidentiality and integrity guarantees strong enough to prevent passive disclosure or active tampering of secret handles.

## 6. Document and Object Storage Service

### 6.1 Overview

The baseline runtime storage model includes document or object storage for structured program data.

This storage is suitable for:

- derived state
- indexes
- caches
- checkpoints
- metadata
- program-local records managed through the runtime

### 6.2 Storage Keys

The runtime MUST treat document keys as exact strings.

This specification does not define a universal path syntax beyond exact string keys.

### 6.3 `storage.put`

Required permission:

- `storage.write`

Request parameters:

| Field | Type | Required | Description |
|---|---|---|---|
| `key` | string | yes | Document key |
| `value` | object | yes | Stored JSON object |

Successful result:

| Field | Type | Required | Description |
|---|---|---|---|
| `key` | string | yes | Stored document key |

### 6.4 `storage.get`

Required permission:

- `storage.read`

Request parameters:

| Field | Type | Required | Description |
|---|---|---|---|
| `key` | string | yes | Document key |

Successful result:

| Field | Type | Required | Description |
|---|---|---|---|
| `key` | string | yes | Document key |
| `value` | object | yes | Stored JSON object |

### 6.5 `storage.delete`

Required permission:

- `storage.write`

Request parameters:

| Field | Type | Required | Description |
|---|---|---|---|
| `key` | string | yes | Document key |

Successful result MAY be an empty object.

### 6.6 `storage.list`

Required permission:

- `storage.read`

Request parameters:

| Field | Type | Required | Description |
|---|---|---|---|
| `prefix` | string | no | Key prefix filter |

Successful result:

| Field | Type | Required | Description |
|---|---|---|---|
| `keys` | array of strings | yes | Matching keys visible to the program |

## 7. Append-Only Event Storage Service

### 7.1 Overview

The baseline runtime storage model also includes append-only event storage.

This service is intended for:

- program-generated event journals
- checkpoints tied to observed event streams
- runtime-managed append-only logs exposed to programs

This service is not defined as a full relational query layer.

### 7.2 `events.append`

Required permission:

- `events.append`

Request parameters:

| Field | Type | Required | Description |
|---|---|---|---|
| `stream` | string | yes | Runtime-defined stream name |
| `event` | object | yes | JSON object to append |

Successful result:

| Field | Type | Required | Description |
|---|---|---|---|
| `stream` | string | yes | Target stream |
| `offset` | integer | yes | Runtime-assigned append offset |

### 7.3 `events.read`

Required permission:

- `events.read`

Request parameters:

| Field | Type | Required | Description |
|---|---|---|---|
| `stream` | string | yes | Runtime-defined stream name |
| `after_offset` | integer | no | Exclusive lower bound |
| `limit` | integer | no | Maximum number of entries requested |

Successful result:

| Field | Type | Required | Description |
|---|---|---|---|
| `stream` | string | yes | Source stream |
| `entries` | array | yes | Ordered stream entries |

Each `entries` item MUST include:

| Field | Type | Required | Description |
|---|---|---|---|
| `offset` | integer | yes | Runtime-assigned offset |
| `event` | object | yes | Stored JSON event payload |

## 8. Subscription Service

### 8.1 Overview

The subscription service allows programs to receive Overnet data or runtime-managed event updates through runtime-controlled subscriptions.

### 8.2 `subscriptions.open`

Required permission:

- `subscriptions.read`

Request parameters:

| Field | Type | Required | Description |
|---|---|---|---|
| `subscription_id` | string | yes | Program-chosen subscription identifier unique within the session |
| `query` | object | yes | Baseline subscription query |

The baseline `query` object MAY include:

| Field | Type | Required | Description |
|---|---|---|---|
| `kind` | integer | no | Match Overnet event kind |
| `overnet_et` | string | no | Match Overnet event type |
| `overnet_ot` | string | no | Match Overnet object type |
| `overnet_oid` | string | no | Match Overnet object identifier |

If `query` is an empty object, it MUST mean "all visible baseline subscription items available to this program instance".

For `private_message` subscription items defined by section 11:

- `query.kind`, when present, MUST match the visible transport event kind
- `query.overnet_et`, when present, MUST match the logical private-message `private_type`
- `query.overnet_ot`, when present, MUST match the logical private-message `object_type`
- `query.overnet_oid`, when present, MUST match the logical private-message `object_id`

If `query` contains fields other than the baseline fields defined here, the runtime MUST reject the request with `protocol.invalid_params`.

Successful result:

| Field | Type | Required | Description |
|---|---|---|---|
| `subscription_id` | string | yes | Opened subscription identifier |

### 8.3 `subscriptions.close`

Required permission:

- `subscriptions.read`

Request parameters:

| Field | Type | Required | Description |
|---|---|---|---|
| `subscription_id` | string | yes | Previously opened subscription identifier |

### 8.4 `runtime.subscription_event` Notification

The runtime MUST deliver subscription results using a notification with:

- `method` value `runtime.subscription_event`

Notification parameters:

| Field | Type | Required | Description |
|---|---|---|---|
| `subscription_id` | string | yes | Subscription identifier |
| `item_type` | string | yes | Delivered item class |
| `data` | object | yes | Delivered full wire-format Overnet object |

The baseline `item_type` values are:

- `event`
- `state`
- `private_message`
- `capability`

When `item_type` is `capability`, the `data` object MUST use the same baseline capability advertisement object shape defined for `overnet.emit_capabilities`.

When `item_type` is `private_message`, the `data` object MUST include:

| Field | Type | Required | Description |
|---|---|---|---|
| `transport` | object | yes | Relay-visible wrapped private-message transport object |
| `private_type` | string | yes | Logical private-message item type |
| `object_type` | string | yes | Logical private-message object type |
| `object_id` | string | yes | Logical private-message object identifier |

When `item_type` is `private_message`, the `data` object MAY additionally include:

| Field | Type | Required | Description |
|---|---|---|---|
| `decrypted_rumor` | object | no | Runtime-validated decrypted rumor object when the trusted-decrypted candidate form was used |
| `sender_identity` | string | no | Cleartext routing or presentational sender identity supplied by the ingress boundary |

## 9. Nostr Relay Services

### 9.1 Overview

The `nostr.*` service family allows a program to use runtime-mediated Nostr relay operations without directly linking to a specific Nostr library.

These methods are transport primitives.

This document does not define application-specific interpretation of returned Nostr events.

Programs and companion specifications that use these methods remain responsible for:

- selecting meaningful relay URLs
- choosing Nostr filters
- interpreting returned Nostr event semantics

### 9.2 Shared Filter Rules

Methods in this section that accept `filters` use baseline Nostr filter objects.

For the baseline runtime service contract:

- `filters` MUST be a non-empty array
- each entry in `filters` MUST be an object
- the runtime MAY pass additional filter fields through unchanged to the underlying Nostr implementation
- if `filters` is not a non-empty array of objects, the runtime MUST reject the request with `protocol.invalid_params`

This document does not define the full Nostr filter language.

### 9.3 `nostr.publish_event`

Required permission:

- `nostr.write`

Request parameters:

| Field | Type | Required | Description |
|---|---|---|---|
| `relay_url` | string | yes | Target relay URL |
| `event` | object | yes | Signed Nostr event object to publish |
| `timeout_ms` | integer | no | Optional positive publish timeout in milliseconds |

Successful result:

| Field | Type | Required | Description |
|---|---|---|---|
| `accepted` | boolean | yes | Whether the relay accepted the publish |
| `event_id` | string | no | Published event id when available |
| `message` | string | no | Relay-provided status message when available |

The runtime MUST pass the supplied event object to the underlying Nostr publish operation without adding Overnet-specific semantic interpretation.

### 9.4 `nostr.query_events`

Required permission:

- `nostr.read`

Request parameters:

| Field | Type | Required | Description |
|---|---|---|---|
| `relay_url` | string | yes | Target relay URL |
| `filters` | array | yes | Non-empty array of Nostr filter objects |
| `timeout_ms` | integer | no | Optional positive query timeout in milliseconds |

Successful result:

| Field | Type | Required | Description |
|---|---|---|---|
| `events` | array | yes | Matching Nostr events returned by the relay query |

The returned `events` array MUST contain full Nostr event objects.

### 9.5 `nostr.open_subscription`

Required permission:

- `nostr.read`

Request parameters:

| Field | Type | Required | Description |
|---|---|---|---|
| `subscription_id` | string | yes | Program-chosen subscription identifier unique within the session |
| `relay_url` | string | yes | Target relay URL |
| `filters` | array | yes | Non-empty array of Nostr filter objects |
| `timeout_ms` | integer | no | Optional positive query timeout in milliseconds used for the initial seeded snapshot |

Successful result:

| Field | Type | Required | Description |
|---|---|---|---|
| `subscription_id` | string | yes | Opened subscription identifier |
| `events` | array | yes | Seeded relay snapshot for the supplied filters at open time |

The runtime MUST treat `subscription_id` as scoped to the calling session.

If a program attempts to open the same `subscription_id` twice in one session, the runtime MUST reject the request.

### 9.6 `nostr.read_subscription_snapshot`

Required permission:

- `nostr.read`

Request parameters:

| Field | Type | Required | Description |
|---|---|---|---|
| `subscription_id` | string | yes | Previously opened subscription identifier |
| `refresh` | boolean or integer | no | When true or `1`, force an immediate relay refresh before returning the snapshot |

Successful result:

| Field | Type | Required | Description |
|---|---|---|---|
| `events` | array | yes | Current cached snapshot for the subscription |

If `refresh` is not supplied, the runtime MAY return the current cached snapshot without forcing a new relay query.

If `subscription_id` is unknown, the runtime MUST reject the request.

### 9.7 `nostr.close_subscription`

Required permission:

- `nostr.read`

Request parameters:

| Field | Type | Required | Description |
|---|---|---|---|
| `subscription_id` | string | yes | Previously opened subscription identifier |

Successful result:

| Field | Type | Required | Description |
|---|---|---|---|
| `closed` | boolean | yes | Whether the runtime closed the subscription |

If `subscription_id` is unknown, the runtime MUST reject the request.

### 9.8 `runtime.subscription_event` for Nostr Relay Subscriptions

The runtime uses the baseline `runtime.subscription_event` notification defined in section 8.4 for relay-backed Nostr subscriptions as well.

For relay-backed Nostr subscription updates:

- `params.subscription_id` MUST identify the open `nostr.open_subscription`
- `params.item_type` MUST be `nostr.event`
- `params.data` MUST contain the full Nostr event object that triggered the update

Closing a Nostr relay subscription SHOULD discard queued `runtime.subscription_event` notifications for that subscription that have not yet been delivered to the program.

## 10. Timers and Scheduled Jobs Service

### 10.1 Overview

The timers service allows a program to request runtime-managed future callbacks.

### 10.2 `timers.schedule`

Required permission:

- `timers.write`

Request parameters:

| Field | Type | Required | Description |
|---|---|---|---|
| `timer_id` | string | yes | Program-chosen timer identifier unique within the session |
| `at` | integer | no | Unix timestamp for scheduled delivery |
| `delay_ms` | integer | no | Delay in milliseconds from acceptance time |
| `repeat_ms` | integer | no | Optional repeat interval in milliseconds |
| `payload` | object | no | Timer-associated payload returned on delivery |

Exactly one of `at` or `delay_ms` MUST be supplied.

Successful result:

| Field | Type | Required | Description |
|---|---|---|---|
| `timer_id` | string | yes | Scheduled timer identifier |

### 10.3 `timers.cancel`

Required permission:

- `timers.write`

Request parameters:

| Field | Type | Required | Description |
|---|---|---|---|
| `timer_id` | string | yes | Scheduled timer identifier |

### 10.4 `runtime.timer_fired` Notification

The runtime MUST deliver timer firings using a notification with:

- `method` value `runtime.timer_fired`

Notification parameters:

| Field | Type | Required | Description |
|---|---|---|---|
| `timer_id` | string | yes | Timer identifier |
| `fired_at` | integer | yes | Unix timestamp of delivery |
| `payload` | object | no | Timer-associated payload |

## 11. Overnet Data Emission Services

### 11.1 Overview

Programs emit candidate Overnet data through runtime service methods.

The runtime MUST validate these outputs before accepting them.

### 11.2 `overnet.emit_event`

Required permission:

- `overnet.emit_event`

Request parameters:

| Field | Type | Required | Description |
|---|---|---|---|
| `event` | object | yes | Candidate full wire-format Overnet/Nostr event object |

Successful result:

| Field | Type | Required | Description |
|---|---|---|---|
| `accepted` | boolean | yes | Runtime acceptance result; MUST be `true` on success |
| `event_id` | string | no | Runtime-known event identifier when available |

### 11.3 `overnet.emit_state`

Required permission:

- `overnet.emit_state`

Request parameters:

| Field | Type | Required | Description |
|---|---|---|---|
| `state` | object | yes | Candidate full wire-format Overnet/Nostr state event object |

Successful result:

| Field | Type | Required | Description |
|---|---|---|---|
| `accepted` | boolean | yes | Runtime acceptance result; MUST be `true` on success |
| `event_id` | string | no | Runtime-known event identifier when available |

### 11.4 `overnet.emit_private_message`

Required permission:

- `overnet.emit_private_message`

Request parameters:

| Field | Type | Required | Description |
|---|---|---|---|
| `message` | object | yes | Candidate encrypted private-message transport object |

The `message` object MUST include:

| Field | Type | Required | Description |
|---|---|---|---|
| `transport` | object | yes | Candidate visible wrapped transport object |

The `message` object MAY also include:

| Field | Type | Required | Description |
|---|---|---|---|
| `private_type` | string | no | Required when the candidate uses the opaque endpoint-blind form |
| `object_type` | string | no | Required when the candidate uses the opaque endpoint-blind form |
| `object_id` | string | no | Required when the candidate uses the opaque endpoint-blind form |
| `sender_identity` | string | no | Optional cleartext routing or presentational sender identity |

The candidate private-message object MUST use one of the following forms:

- trusted-decrypted candidate form
- opaque endpoint-blind candidate form

For the trusted-decrypted candidate form:

- `message.transport.decrypted_rumor` MUST be present and MUST be an object
- the runtime MUST treat `message.transport` as the candidate visible wrapped event object, except that `message.transport.decrypted_rumor` is runtime-visible validation context and is not part of the relay-visible wrapped event itself

For the opaque endpoint-blind candidate form:

- `message.transport.decrypted_rumor` MUST be absent
- `message.private_type`, `message.object_type`, and `message.object_id` MUST be present
- the runtime MUST validate and store those logical metadata fields without assuming access to the decrypted message body
- `message.sender_identity`, when present, is cleartext routing or presentational metadata rather than decrypted message content

Successful result:

| Field | Type | Required | Description |
|---|---|---|---|
| `accepted` | boolean | yes | Runtime acceptance result; MUST be `true` on success |
| `event_id` | string | no | Runtime-known visible wrapped event identifier when available |
| `rumor_id` | string | no | Runtime-known decrypted rumor identifier when available |

### 11.5 `overnet.emit_capabilities`

Required permission:

- `overnet.emit_capabilities`

Request parameters:

| Field | Type | Required | Description |
|---|---|---|---|
| `capabilities` | array | yes | Candidate capability advertisement objects |

Each capability advertisement object MUST include:

| Field | Type | Required | Description |
|---|---|---|---|
| `name` | string | yes | Capability name |
| `version` | string | yes | Capability version identifier |

Each capability advertisement object MAY include:

| Field | Type | Required | Description |
|---|---|---|---|
| `details` | object | no | Structured capability-specific metadata |

For `overnet.emit_event` and `overnet.emit_state`, the runtime MUST interpret the supplied object as the full candidate wire-format event to validate, not as a partial draft requiring runtime completion.

For `overnet.emit_private_message`, the runtime MUST interpret the supplied object as the full candidate private-message transport object to validate, not as a partial draft requiring runtime completion.

Successful result:

| Field | Type | Required | Description |
|---|---|---|---|
| `accepted` | boolean | yes | Runtime acceptance result; MUST be `true` on success |

## 12. Adapter Session Services

### 12.1 Overview

The adapter service allows a program to use runtime-managed adapters through explicit adapter sessions.

In the baseline model:

- a program opens an adapter session for a specific adapter id
- the runtime returns an adapter session id
- the program uses that session to request direct mapping or derived output
- the program closes the session when it is done

This baseline surface is intentionally narrow. Later revisions MAY define richer adapter session operations.

### 12.2 `adapters.open_session`

Required permission:

- `adapters.use`

Request parameters:

| Field | Type | Required | Description |
|---|---|---|---|
| `adapter_id` | string | yes | Runtime-known adapter identifier |
| `config` | object | no | Session-specific adapter configuration |
| `secret_handles` | object | no | Adapter-defined secret inputs as secret-handle objects |

If `secret_handles` is present:

- each key identifies an adapter-defined secret input slot
- each value MUST use the baseline `secret_handle` object shape defined by the secrets service
- the runtime MUST resolve those handles inside the runtime or host boundary before exposing the resulting secret material to the adapter
- the runtime MUST expose resolved plaintext only to the immediate privileged adapter-side consumer for the session-opening operation
- the runtime MUST NOT persist resolved plaintext in adapter session identifiers, adapter-visible ordinary session configuration, or program-visible runtime state

The runtime MUST validate each supplied secret handle using the secret-handle rules defined for the secrets service, including:

- same-instance binding
- lifetime validity
- revocation status
- audience and purpose binding when applicable

The runtime MUST NOT echo raw secret plaintext back to the program in the `adapters.open_session` result or in adapter-session identifiers.

The runtime MUST NOT place resolved plaintext from `secret_handles` into:

- adapter result payloads
- runtime-generated notifications
- runtime-managed document storage
- append-only event storage

After the runtime hands resolved plaintext to the privileged session-opening consumer, the runtime MUST discard its own temporary plaintext copies as soon as practical.

Adapter companion specifications SHOULD define which adapter configuration slots are secret-bearing.

When an adapter companion specification defines a secret-bearing input, the program MUST supply that value through `secret_handles` rather than ordinary plaintext `config`.

Successful result:

| Field | Type | Required | Description |
|---|---|---|---|
| `adapter_session_id` | string | yes | Runtime-assigned adapter session identifier |

### 12.3 `adapters.map_input`

Required permission:

- `adapters.use`

Request parameters:

| Field | Type | Required | Description |
|---|---|---|---|
| `adapter_session_id` | string | yes | Previously opened adapter session identifier |
| `input` | object | yes | Adapter-specific input object |

Successful result:

| Field | Type | Required | Description |
|---|---|---|---|
| `events` | array | no | Candidate full wire-format Overnet/Nostr events produced by the adapter |
| `state` | array | no | Candidate full wire-format Overnet/Nostr state events produced by the adapter |
| `capabilities` | array | no | Candidate capability advertisement objects produced by the adapter |

If `capabilities` is present, each item MUST use the same baseline capability object shape defined for `overnet.emit_capabilities`.

Adapter-defined `input` objects SHOULD NOT contain raw secret plaintext.

If a later adapter companion specification requires secret-bearing operational input beyond session opening, it SHOULD define secret-handle input fields explicitly and MUST require runtime-side secret-handle resolution rather than plaintext transport through ordinary adapter input objects.

### 12.4 `adapters.derive`

Required permission:

- `adapters.use`

Request parameters:

| Field | Type | Required | Description |
|---|---|---|---|
| `adapter_session_id` | string | yes | Previously opened adapter session identifier |
| `operation` | string | yes | Adapter-defined derivation operation name |
| `input` | object | yes | Adapter-defined derivation input object |

Successful result:

| Field | Type | Required | Description |
|---|---|---|---|
| `events` | array | no | Candidate full wire-format Overnet/Nostr events produced by the adapter |
| `state` | array | no | Candidate full wire-format Overnet/Nostr state events produced by the adapter |
| `capabilities` | array | no | Candidate capability advertisement objects produced by the adapter |

If `capabilities` is present, each item MUST use the same baseline capability object shape defined for `overnet.emit_capabilities`.

### 12.5 `adapters.close_session`

Required permission:

- `adapters.use`

Request parameters:

| Field | Type | Required | Description |
|---|---|---|---|
| `adapter_session_id` | string | yes | Previously opened adapter session identifier |

Successful result MAY be an empty object.

## 13. Logging and Health Services

### 13.1 `program.log` Notification

Programs SHOULD emit structured logs through a notification with:

- `method` value `program.log`

Notification parameters:

| Field | Type | Required | Description |
|---|---|---|---|
| `level` | string | yes | Log severity |
| `message` | string | yes | Human-readable log message |
| `context` | object | no | Structured contextual data |

### 13.2 `program.health` Notification

Programs SHOULD emit structured health updates through a notification with:

- `method` value `program.health`

Notification parameters:

| Field | Type | Required | Description |
|---|---|---|---|
| `status` | string | yes | Program health state such as `ready`, `degraded`, or `failed` |
| `message` | string | no | Human-readable status explanation |
| `details` | object | no | Structured health detail |

## 14. Permission Identifiers

This version defines the following baseline permission identifiers:

| Permission | Meaning |
|---|---|
| `config.read` | Read runtime-managed configuration |
| `secrets.read` | Request runtime-managed secret handles |
| `storage.read` | Read runtime-managed document storage |
| `storage.write` | Write runtime-managed document storage |
| `events.read` | Read runtime-managed append-only event streams |
| `events.append` | Append to runtime-managed event streams |
| `subscriptions.read` | Open and close runtime-managed subscriptions |
| `nostr.read` | Query relays and read relay-backed Nostr subscription snapshots |
| `nostr.write` | Publish Nostr events through runtime-managed relay access |
| `timers.write` | Schedule and cancel runtime-managed timers |
| `adapters.use` | Open, use, and close runtime-managed adapter sessions |
| `overnet.emit_event` | Emit candidate Overnet events |
| `overnet.emit_state` | Emit candidate Overnet state |
| `overnet.emit_private_message` | Emit encrypted private-message transport items |
| `overnet.emit_capabilities` | Emit candidate capability advertisements |

## 15. Error Expectations

When rejecting service requests, the runtime SHOULD use the structured error model from the program protocol specification.

Typical error codes include:

- `runtime.permission_denied`
- `runtime.validation_failed`
- `runtime.service_unavailable`
- `protocol.invalid_params`

Service-specific companion specifications MAY define additional structured error detail.

## 16. Open Issues

The following areas remain open for later revision:

- richer document query operations
- stream compaction or retention semantics
- subscription query language details
- timer persistence across runtime restarts
- secret rotation and leasing semantics
- more precise capability advertisement structure
- richer adapter session operations beyond `open_session`, `map_input`, `derive`, and `close_session`
- bulk or transactional service operations
