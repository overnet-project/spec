# Overnet Program Protocol Specification

## Status of This Document

This document defines the baseline Overnet Program Protocol as a companion specification to the Overnet Program Runtime and the Overnet core.

It is a working draft.

Unless stated otherwise, the main body of this document is normative.

## 1. Purpose

This specification defines the concrete on-the-wire protocol used between an Overnet Program Runtime and an Overnet program.

The runtime specification defines the architectural contract. This document defines the baseline message transport, framing, message envelope, request/response rules, notifications, handshake, and protocol errors needed to implement that contract in a language-agnostic way.

## 2. Relationship to Other Specifications

This specification is a companion specification to:

- the Overnet core
- the Overnet Program Runtime specification

The Overnet core remains authoritative for Overnet data semantics.

The Overnet Program Runtime specification remains authoritative for:

- runtime responsibilities
- lifecycle semantics
- service families
- validation and permission boundaries

This document is authoritative for the baseline program/runtime message protocol.

## 3. Design Goals

The baseline program protocol MUST be:

- language-agnostic
- portable across operating systems, including Windows
- suitable for local supervised execution
- unambiguous about message boundaries
- usable for both request/response and asynchronous runtime notifications
- strict about malformed input and protocol errors

## 4. Baseline Transport

### 4.1 Streams

The required baseline transport is bidirectional communication over the program process standard input and standard output streams.

The runtime writes protocol frames to the program's standard input.

The program writes protocol frames to its standard output.

Standard error is not part of the protocol stream and MUST NOT be used for protocol messages.

### 4.2 JSON Encoding

Each protocol message payload MUST be a single JSON object encoded as UTF-8.

The payload object MUST NOT rely on whitespace, key ordering, or newline behavior for framing or interpretation.

## 5. Framing

### 5.1 Length Prefix

Each protocol message MUST be framed using an ASCII decimal length prefix followed by a single line feed (`LF`, byte `0x0A`) followed by exactly that many bytes of UTF-8 JSON payload.

The frame format is:

```text
<decimal-length>\n<json-payload-bytes>
```

Where:

- `<decimal-length>` is the number of bytes in `<json-payload-bytes>`
- the length prefix is encoded using ASCII digits only
- the payload is exactly one JSON object

### 5.2 Example Frame

The following is an informative framing example:

```text
25
{"type":"hello","id":"1"}
```

In a real frame, the `25` length value MUST equal the exact byte length of the JSON payload.

### 5.3 Framing Errors

The following are protocol errors:

- a missing length prefix
- a non-numeric length prefix
- a negative length
- a payload shorter than the declared length
- trailing payload bytes that do not begin a valid next frame
- a payload that is not valid UTF-8 JSON object data

A conforming implementation MUST treat framing errors as fatal to the current session.

### 5.4 Message Size Limits

A runtime MUST impose a maximum permitted frame size.

If a peer sends a frame larger than the permitted maximum, the receiver MUST treat that as a protocol error.

This specification does not define one universal maximum frame size.

## 6. Message Model

### 6.1 Top-Level Message Object

Every protocol message MUST be a JSON object with:

| Field | Type | Required | Description |
|---|---|---|---|
| `type` | string | yes | Message class |
| `method` | string | required for requests and notifications | Operation name |
| `id` | string | required for requests and responses | Correlation identifier |

Additional fields depend on message type.

### 6.2 Message Types

The baseline message types are:

- `request`
- `response`
- `notification`

No other top-level `type` values are defined by this version.

### 6.3 Requests

A request message MUST contain:

| Field | Type | Required |
|---|---|---|
| `type` | string | yes, value `request` |
| `id` | string | yes |
| `method` | string | yes |
| `params` | object | no, defaults to empty object |

The sender of a request expects exactly one response with the same `id`.

### 6.4 Responses

A response message MUST contain:

| Field | Type | Required |
|---|---|---|
| `type` | string | yes, value `response` |
| `id` | string | yes |
| `ok` | boolean | yes |

If `ok` is `true`, the response MAY contain:

| Field | Type | Required |
|---|---|---|
| `result` | object | no, defaults to empty object |

If `ok` is `false`, the response MUST contain:

| Field | Type | Required |
|---|---|---|
| `error` | object | yes |

### 6.5 Notifications

A notification message MUST contain:

| Field | Type | Required |
|---|---|---|
| `type` | string | yes, value `notification` |
| `method` | string | yes |
| `params` | object | no, defaults to empty object |

Notifications do not have message identifiers and MUST NOT receive responses.

## 7. Correlation and Ordering

### 7.1 Request Identifiers

Request identifiers are opaque strings.

The sender of a request MUST NOT reuse an `id` while a prior request with the same `id` is still unresolved.

### 7.2 Response Matching

A response MUST match exactly one in-flight request by `id`.

A response with an unknown `id` is a protocol error.

### 7.3 Ordering

This protocol does not require strict global ordering across unrelated requests and notifications.

However:

- responses MUST correspond to the correct request `id`
- initialization ordering rules defined by this specification MUST be respected
- a receiver MUST process fatal protocol errors in the order they are detected

## 8. Protocol Error Model

### 8.1 Structured Error Object

When a response has `ok` equal to `false`, its `error` object MUST contain:

| Field | Type | Required | Description |
|---|---|---|---|
| `code` | string | yes | Stable error code |
| `message` | string | yes | Human-readable explanation |

The `error` object MAY also contain:

| Field | Type | Required | Description |
|---|---|---|---|
| `details` | object | no | Structured error-specific detail |

### 8.2 Baseline Error Codes

This version defines the following baseline error codes:

| Code | Meaning |
|---|---|
| `protocol.invalid_message` | Message envelope is malformed |
| `protocol.unknown_message_type` | `type` is not recognized |
| `protocol.unknown_method` | `method` is not recognized in this context |
| `protocol.invalid_params` | `params` is missing required structure |
| `protocol.unknown_request_id` | Response `id` does not match an in-flight request |
| `protocol.version_mismatch` | Runtime and program do not share a compatible protocol version |
| `runtime.permission_denied` | Runtime denied the requested operation |
| `runtime.validation_failed` | Candidate Overnet data failed validation |
| `runtime.service_unavailable` | Requested runtime service is unavailable |
| `program.operation_failed` | Program-side operation failed |

Error codes are namespaced by the layer that raises them. The `protocol.`
codes above are shared: companion request/response protocols in this
specification family that reuse this envelope (for example, the auth-agent
protocol) MUST use the applicable `protocol.` codes for envelope-level
failures, and MUST namespace their domain-specific codes with a
protocol-specific prefix (such as `runtime.`, `program.`, or `auth.`).

### 8.3 Fatal Errors

Some protocol errors are fatal to the session.

At minimum, framing errors and irrecoverably malformed message envelopes MUST be treated as fatal.

Implementations MAY terminate the session immediately after detecting a fatal protocol error.

## 9. Session Handshake

### 9.1 Overview

Each session MUST begin with a program-to-runtime hello followed by runtime-selected initialization.

Normal operation MUST NOT begin until handshake completion.

### 9.2 Program `program.hello` Notification

The program MUST begin the session by sending a notification with:

- `method` value `program.hello`

The `params` object for `program.hello` MUST include:

| Field | Type | Required | Description |
|---|---|---|---|
| `program_id` | string | yes | Program identity as asserted by the program |
| `supported_protocol_versions` | array of strings | yes | Protocol versions the program can speak |

The `params` object for `program.hello` MAY include:

| Field | Type | Required | Description |
|---|---|---|---|
| `program_version` | string | no | Program implementation version |
| `metadata` | object | no | Additional startup metadata |

If the runtime and program share no compatible protocol version, the runtime MUST send a `runtime.fatal` notification if it can do so safely, and then MUST terminate the session.

### 9.3 Runtime `runtime.init` Request

After receiving `program.hello` and selecting a compatible version, the runtime MUST send a request with:

- `method` value `runtime.init`

The `params` object for `runtime.init` MUST include:

| Field | Type | Required | Description |
|---|---|---|---|
| `protocol_version` | string | yes | Runtime-selected compatible program protocol version |
| `instance_id` | string | yes | Runtime-assigned instance identifier |
| `program_id` | string | yes | Program identity as known to the runtime |
| `config` | object | yes | Host-managed configuration payload |
| `permissions` | array | yes | Granted permission identifiers |
| `services` | object | yes | Runtime-advertised service availability and service-level details |

The `program_id` field identifies the supervised program instance, not the runtime.

### 9.4 Program `runtime.init` Response

The program MUST respond to `runtime.init`.

If the program accepts initialization, it MUST send a successful response.

If the program cannot operate with the supplied protocol version or initialization state, it MUST send an error response and the runtime MAY terminate the session.

### 9.5 Program Ready Notification

After successful initialization, the program MUST signal readiness by sending a notification with:

- `method` value `program.ready`

The `params` object for `program.ready` MAY include additional program-reported startup metadata.

The runtime MUST NOT assume the program is ready for normal operation until `program.ready` is received.

## 10. Baseline Notifications

This version defines the following baseline notifications:

| Direction | Method | Meaning |
|---|---|---|
| program -> runtime | `program.hello` | Program identity and supported protocol versions |
| program -> runtime | `program.ready` | Program completed initialization |
| program -> runtime | `program.log` | Structured log entry |
| program -> runtime | `program.health` | Structured health or readiness update |
| runtime -> program | `runtime.fatal` | Fatal runtime or protocol condition after which the session will terminate |

Additional notifications MAY be defined by the runtime service specifications.

### 10.1 `runtime.fatal`

The runtime MAY emit a notification with:

- `method` value `runtime.fatal`

When the runtime emits `runtime.fatal`, it MUST terminate the session after sending the notification if it can do so safely.

The `params` object for `runtime.fatal` MUST include:

| Field | Type | Required | Description |
|---|---|---|---|
| `code` | string | yes | Stable fatal error code |
| `message` | string | yes | Human-readable fatal error message |

The `params` object for `runtime.fatal` MAY include:

| Field | Type | Required | Description |
|---|---|---|---|
| `phase` | string | no | Session phase such as `handshake` |
| `details` | object | no | Structured fatal-error detail |

## 11. Baseline Request Families

This document defines the handshake request family and orderly shutdown request directly.

Additional request families for:

- storage
- subscriptions
- secrets
- timers
- event emission
- state emission
- capability advertisement

are defined or extended by the Overnet Program Services companion specification.

### 11.1 `runtime.shutdown`

The runtime MUST request orderly shutdown using a request with:

- `method` value `runtime.shutdown`

The `params` object for `runtime.shutdown` MAY include:

| Field | Type | Required | Description |
|---|---|---|---|
| `reason` | string | no | Human-readable shutdown reason |

The program MUST respond to `runtime.shutdown`.

A successful response indicates that the program has accepted the orderly shutdown request and completed its protocol-level shutdown work.

## 12. Logging and Standard Error

If a program emits ordinary diagnostics to standard error, the runtime MAY capture them for debugging or operator visibility.

Standard error output is not a substitute for structured protocol notifications such as `program.log` or `program.health`.

Runtime diagnostics are defined by the Overnet Program Runtime specification. They are not baseline protocol messages.

## 13. Security Considerations

Implementations MUST treat all protocol input as untrusted.

In particular:

- length prefixes MUST be bounds-checked
- UTF-8 and JSON parsing failures MUST be handled safely
- unknown or malformed messages MUST NOT be interpreted as valid operations
- successful protocol exchange MUST NOT be treated as equivalent to permission to bypass runtime validation or policy

## 14. Open Issues

The following areas remain open for later revision:

- manifest or package metadata for programs
- session resumption semantics
- whether alternative transport bindings such as HTTP should be defined later
- richer progress-reporting and streaming-response semantics
