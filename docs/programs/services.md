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
- timers and scheduled jobs
- Overnet event emission
- Overnet state emission
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

The secrets service allows a program to resolve named or referenced secret material supplied by the runtime.

The runtime MUST control which secrets are visible to each program instance.

### 5.2 `secrets.get`

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
| `value` | string | yes | Secret value |

The runtime SHOULD avoid exposing secret values that the calling program instance is not explicitly allowed to read.

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
- `capability`

When `item_type` is `capability`, the `data` object MUST use the same baseline capability advertisement object shape defined for `overnet.emit_capabilities`.

## 9. Timers and Scheduled Jobs Service

### 9.1 Overview

The timers service allows a program to request runtime-managed future callbacks.

### 9.2 `timers.schedule`

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

### 9.3 `timers.cancel`

Required permission:

- `timers.write`

Request parameters:

| Field | Type | Required | Description |
|---|---|---|---|
| `timer_id` | string | yes | Scheduled timer identifier |

### 9.4 `runtime.timer_fired` Notification

The runtime MUST deliver timer firings using a notification with:

- `method` value `runtime.timer_fired`

Notification parameters:

| Field | Type | Required | Description |
|---|---|---|---|
| `timer_id` | string | yes | Timer identifier |
| `fired_at` | integer | yes | Unix timestamp of delivery |
| `payload` | object | no | Timer-associated payload |

## 10. Overnet Data Emission Services

### 10.1 Overview

Programs emit candidate Overnet data through runtime service methods.

The runtime MUST validate these outputs before accepting them.

### 10.2 `overnet.emit_event`

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

### 10.3 `overnet.emit_state`

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

### 10.4 `overnet.emit_capabilities`

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

Successful result:

| Field | Type | Required | Description |
|---|---|---|---|
| `accepted` | boolean | yes | Runtime acceptance result; MUST be `true` on success |

## 11. Logging and Health Services

### 11.1 `program.log` Notification

Programs SHOULD emit structured logs through a notification with:

- `method` value `program.log`

Notification parameters:

| Field | Type | Required | Description |
|---|---|---|---|
| `level` | string | yes | Log severity |
| `message` | string | yes | Human-readable log message |
| `context` | object | no | Structured contextual data |

### 11.2 `program.health` Notification

Programs SHOULD emit structured health updates through a notification with:

- `method` value `program.health`

Notification parameters:

| Field | Type | Required | Description |
|---|---|---|---|
| `status` | string | yes | Program health state such as `ready`, `degraded`, or `failed` |
| `message` | string | no | Human-readable status explanation |
| `details` | object | no | Structured health detail |

## 12. Permission Identifiers

This version defines the following baseline permission identifiers:

| Permission | Meaning |
|---|---|
| `config.read` | Read runtime-managed configuration |
| `secrets.read` | Resolve runtime-managed secrets |
| `storage.read` | Read runtime-managed document storage |
| `storage.write` | Write runtime-managed document storage |
| `events.read` | Read runtime-managed append-only event streams |
| `events.append` | Append to runtime-managed event streams |
| `subscriptions.read` | Open and close runtime-managed subscriptions |
| `timers.write` | Schedule and cancel runtime-managed timers |
| `overnet.emit_event` | Emit candidate Overnet events |
| `overnet.emit_state` | Emit candidate Overnet state |
| `overnet.emit_capabilities` | Emit candidate capability advertisements |

## 13. Error Expectations

When rejecting service requests, the runtime SHOULD use the structured error model from the program protocol specification.

Typical error codes include:

- `runtime.permission_denied`
- `runtime.validation_failed`
- `runtime.service_unavailable`
- `protocol.invalid_params`

Service-specific companion specifications MAY define additional structured error detail.

## 14. Open Issues

The following areas remain open for later revision:

- richer document query operations
- stream compaction or retention semantics
- subscription query language details
- timer persistence across runtime restarts
- secret rotation and leasing semantics
- more precise capability advertisement structure
- bulk or transactional service operations
