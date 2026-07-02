# Overnet Authentication Agent Specification

## Status of This Document

This document defines the Overnet Authentication Agent as a companion specification to the Overnet core and the existing Overnet program specifications.

It is a working draft.

Unless stated otherwise, the main body of this document is normative.

## 1. Purpose

This specification defines a standard local authentication agent model for Overnet programs and Overnet-compatible bridge components.

Its purpose is to make user-scoped authentication, session establishment, delegation, renewal, and approval policy:

- consistent across Overnet programs
- safe for local key custody
- usable from both native Overnet programs and legacy-protocol bridges
- understandable to users
- strict about trust boundaries

This document exists because raw challenge handling, raw signed-event construction, and ad hoc program-local key access are not an acceptable long-term user experience or security model.

## 2. Relationship to Other Specifications

This specification is a companion specification to:

- the Overnet core
- the Overnet Program Runtime specification
- the Overnet Program Protocol specification
- the Overnet Program Services specification
- any companion specification that defines one authenticated program or adapter surface

The Overnet core remains authoritative for:

- identity semantics
- native Nostr verification rules
- event validity
- delegation semantics defined by the core
- replay and authorization safety rules

The Overnet Program Runtime, Program Protocol, and Program Services specifications remain authoritative for:

- the runtime/program boundary
- runtime framing and service methods
- runtime-managed permissions and service behavior

This document is authoritative for:

- the local authentication-agent boundary
- the local authentication-agent trust model
- local authentication approval and policy semantics
- the baseline local authentication-agent protocol
- short-lived authenticated session semantics shared across Overnet programs
- bridge requirements for legacy protocols using the local authentication agent

Nothing in this specification allows a program, bridge, relay, or remote service to bypass core validation, redefine core identity semantics, or obtain the user's raw private key.

## 3. Design Goals

The Overnet Authentication Agent MUST:

- keep raw private keys local
- isolate keys from ordinary programs and bridges
- support multiple local identities for one user
- support per-user deployment
- support reusable approval policy without becoming a blind signing oracle
- work for both native Overnet programs and legacy-protocol bridge components
- support short-lived remote sessions and renewals
- make first-contact trust and service-identity changes explicit

This specification is designed so that:

- a user may use one local identity across multiple Overnet programs
- different Overnet programs may reuse one consistent local auth story
- bridge components may automate legacy-protocol auth flows without receiving raw key material
- approval prompts are meaningful and reviewable rather than opaque

## 4. Terms

### 4.1 Authentication Agent

An authentication agent is one local per-user service that:

- accesses one or more local identities through configured secret backends
- evaluates approval policy
- signs recognized authentication or delegation artifacts
- returns structured signed results or session artifacts to local clients
- tracks non-secret session state where needed for renewal or revocation

This document also uses the shorter term "auth agent".

### 4.2 Auth-Agent Client

An auth-agent client is one local program component that talks to the auth agent over the local auth-agent protocol defined by this document.

An auth-agent client MAY be:

- a native Overnet program
- a local UI
- a CLI tool
- a bridge component for one legacy protocol

### 4.3 Bridge

A bridge is one local component that translates between:

- one external or legacy client/protocol surface
- and the local auth-agent protocol

Examples include:

- an IRC helper
- an IRC client plugin
- a ZNC module
- a mail client helper

### 4.4 Local Identity

A local identity is one named user-controlled signing identity known to the auth agent.

A local identity includes:

- one stable local identity identifier
- one signing backend reference
- one presented public identity
- optional user-facing display metadata

This document does not require one local identity to be the user's only Overnet identity.

### 4.5 Remote Service Identity

A remote service identity is one stable cryptographic identity representing the remote Overnet-capable service being trusted.

A remote service identity is distinct from:

- a hostname
- a transport URL
- a presentational server name
- a user nickname

Locators such as hostnames and URLs are still important, but they are not the primary trust anchor.

When represented as structured data in this document, a remote service identity object SHOULD include:

| Field | Type | Required | Description |
|---|---|---|---|
| `scheme` | string | yes | Service-identity scheme identifier |
| `value` | string | yes | Stable service-identity value |
| `display` | string | no | User-facing service label |

### 4.6 Locator

A locator is one transport or routing reference for a remote service, such as:

- a hostname
- a URL
- a presented network endpoint
- another companion-spec-defined connection reference

### 4.7 Scope

A scope is one structured or string-identified remote auth context to which the request applies.

Examples include:

- `irc://<server_name>/<network>`
- a program-specific namespace
- a companion-spec-defined resource or workspace scope

### 4.8 Action Type

An action type identifies what kind of auth-agent approval is being requested.

This document defines the following baseline action types:

- `session.authenticate`
- `session.delegate`
- `session.renew`

Companion specifications MAY define narrower action types so long as they preserve the shared approval and session semantics defined here.

### 4.9 Session

A session is one short-lived authorization context binding all of the following:

- one local identity
- one auth-agent client or program identity
- one remote service identity or provisional locator trust context
- one scope
- one action type or compatible action family
- one expiry boundary

### 4.10 Session Artifact

A session artifact is one typed output returned by the auth agent for use by a program or bridge.

Examples include:

- one signed Nostr event
- one remote-service session token
- one companion-spec-defined session grant

## 5. Architectural Model

### 5.1 Per-User Local Service

The baseline deployment model is one auth-agent instance per local user account.

An implementation MUST NOT require one system-wide auth agent shared across all local users.

This baseline model is required because:

- keys are user-scoped
- approvals are user-scoped
- local per-user IPC permissions naturally fit per-user trust boundaries

### 5.2 Programs and Bridges Use the Agent

A local program or bridge that needs user-scoped authentication SHOULD use the auth agent rather than reading raw key material directly.

A companion specification MAY require use of the auth agent for specific authenticated surfaces.

### 5.3 The Agent Is Not a Generic Signing Oracle

An auth agent MUST NOT sign arbitrary opaque material merely because a local client asked it to do so.

An auth agent MUST only approve request types that it:

- recognizes
- can validate structurally
- can explain meaningfully to the user
- can bind to explicit trust and approval policy

If an auth-agent client submits an unrecognized or semantically opaque request, the auth agent MUST reject it.

## 6. Local Identity and Secret Backend Model

### 6.1 Multiple Local Identities

An auth agent MUST support more than one named local identity for the same user.

The auth agent MAY automatically choose one local identity only when:

- approval policy already fixes the identity safely
- or exactly one permitted identity is available in the current context

Otherwise the auth agent MUST require explicit identity selection.

### 6.2 Pluggable Secret Backends

The auth agent MUST support a pluggable secret-backend model.

Supported backend types MAY include:

- an internal agent-managed key store
- file-backed secret material
- `pass` or equivalent password-store integrations
- operating-system keychain integrations
- hardware-backed or remote-signing integrations defined later

This document does not require one specific backend.

### 6.3 Key Isolation

The auth agent MUST NOT expose raw private key material to an auth-agent client as part of the baseline protocol.

Programs and bridges MUST receive only:

- structured signed outputs
- opaque local session handles
- non-secret identity metadata

### 6.4 Identity Metadata

An auth agent MAY expose non-secret metadata for each local identity, including:

- local identity identifier
- public key or equivalent public identity
- display label
- default-identity hint
- backend type

The auth agent MUST treat backend-specific secrets, unlock material, and raw private key material as agent-private.

## 6A. Reference Implementation Config Example

This section is informative.

The `core-perl` reference implementation currently uses one JSON config file for the local auth-agent daemon.

Example:

```json
{
  "daemon": {
    "endpoint": "/tmp/overnet-auth.sock"
  },
  "identities": [
    {
      "identity_id": "default",
      "backend_type": "pass",
      "backend_config": {
        "entry": "overnet-priv-key"
      },
      "public_identity": {
        "scheme": "nostr.pubkey",
        "value": "274722f14ff06e2a790322ae1cee2d28c9cb0ffcd18d78d3bc7cca3f19e9764d"
      }
    }
  ],
  "policies": [
    {
      "identity_id": "default",
      "program_id": "irc.bridge",
      "locator": "irc://irc.example.test/overnet",
      "scope": "irc://irc.example.test/overnet",
      "action": "session.authenticate"
    },
    {
      "identity_id": "default",
      "program_id": "irc.bridge",
      "locator": "irc://irc.example.test/overnet",
      "scope": "irc://irc.example.test/overnet",
      "action": "session.delegate"
    }
  ]
}
```

The reference implementation currently recognizes:

- `daemon.endpoint`
- `daemon.socket_mode`
- `identities`
- `policies`
- `service_pins`
- `sessions`

## 7. Remote Service Identity and Trust

### 7.1 Primary Trust Anchor

Approval policy SHOULD bind primarily to one remote service identity rather than only to locators such as hostnames or URLs.

A companion specification that uses this auth model SHOULD define:

- how the remote service presents one stable cryptographic identity
- how that identity relates to locators and display names

### 7.2 Provisional Locator Trust

Some companion specifications or implementations may not yet define one stable cryptographic remote service identity.

When no stable remote service identity is available:

- the auth agent MAY operate in a provisional locator-trust mode
- the auth agent MUST surface that reduced trust quality clearly
- reusable policy MUST be limited to the exact locator and exact scope approved
- the auth agent MUST NOT silently widen such provisional trust to a broader service identity

### 7.3 First Contact

On first contact with a previously unknown remote service identity, the auth agent MAY allow:

- explicit user verification
- or trust-on-first-use

When trust-on-first-use is used, the auth agent MUST:

- record the learned service identity
- bind it to the approved locator context
- make clear that the service identity has been pinned for future approvals

### 7.4 Pinned Service Identity Mismatch

If a later request presents a different remote service identity for a previously pinned locator or trust record:

- the auth agent MUST reject by default
- the auth agent MUST surface a clear identity-change warning
- the auth agent MUST require explicit re-approval before trusting the new identity

The auth agent MUST NOT silently replace a pinned service identity merely because the hostname or URL matches.

## 8. Approval and Policy Model

### 8.1 Structured Request Context

An auth-agent request MUST provide enough structured context for the agent to evaluate and explain the requested action.

At minimum, that context MUST include:

- the requesting program identity
- the local identity being requested or the identity-selection context
- the remote service identity or provisional locator context
- one or more locators
- the requested scope
- the requested action type
- any challenge data required by the companion specification
- any requested delegation or session parameters required by the companion specification

### 8.2 Human-Readable Approval

When approval is required, the auth agent MUST present enough information for an informed user decision.

At minimum, approval UX MUST show:

- the requesting program or bridge identity
- the local identity being used
- the remote service identity when known
- the locator or host information
- the requested scope
- the action type
- the requested duration or expiry when applicable

An auth agent SHOULD avoid exposing only raw protocol fields when a clearer explanation can be generated.

### 8.3 Reusable Policy Unit

Reusable approval policy MUST be keyed narrowly enough to avoid accidental trust widening.

At minimum, a reusable policy record MUST bind:

- one local identity
- one requesting program or bridge identity
- one remote service identity, or one provisional exact locator trust record
- one scope
- one action type

An implementation MAY bind policy more narrowly, but it MUST NOT bind policy more broadly than these baseline dimensions.

### 8.4 Headless Behavior

If no approval UI or TTY is available and no existing reusable policy authorizes the request:

- the auth agent MUST fail closed
- the auth agent MUST NOT silently auto-approve merely because the requesting program is local

### 8.5 Approval Reuse

If an incoming request matches an existing reusable policy exactly under section 8.3:

- the auth agent MAY approve it automatically

If any relevant dimension differs:

- the auth agent MUST treat it as a new approval decision or reject it

## 9. Session Model

### 9.1 Short-Lived Sessions

The auth-agent model is session-oriented.

A successful auth flow SHOULD normally result in one short-lived session or session artifact rather than one permanent reusable credential.

### 9.2 Session Binding

A session MUST be bound to:

- one local identity
- one requesting program or bridge identity
- one remote service identity or provisional exact locator trust record
- one scope
- one approved action context
- one expiry

### 9.3 Session Renewal

The auth agent MAY automatically renew a session only when:

- the renewal request matches existing policy
- the local identity is the same
- the remote service identity or exact provisional locator context is the same
- the scope is the same
- the action type is the same or explicitly compatible under the companion specification

Otherwise the auth agent MUST prompt again or fail closed.

### 9.4 Session Revocation and Expiry

The auth agent MUST stop using a session after expiry.

The auth agent SHOULD support explicit session revocation or forgetting of cached non-secret session state.

This document does not require one universal remote revocation mechanism, because remote revocation behavior is companion-spec-specific.

## 10. Auth-Agent Protocol

### 10.1 Baseline Transport

The required baseline transport is one local per-user IPC endpoint.

On systems that support Unix domain sockets suitably, the auth-agent endpoint MUST be one local Unix domain socket.

On systems where Unix domain sockets are unavailable or unsuitable, an implementation MUST provide one semantically equivalent local per-user IPC endpoint.

The auth-agent endpoint MUST be accessible only within the local trust boundary for the current user account.

### 10.2 Socket Discovery

An auth-agent client SHOULD discover the local auth-agent endpoint via environment variable:

- `OVERNET_AUTH_SOCK`

When the auth-agent endpoint is one Unix domain socket, `OVERNET_AUTH_SOCK` MUST identify the socket path.

Implementations MAY additionally support:

- `OVERNET_AUTH_ENDPOINT`

for platform-specific endpoint discovery on systems where a Unix-socket path is not the natural representation.

Implementations MAY also define one default per-user endpoint location.

### 10.3 Framing and Envelope

The baseline framing and JSON request/response envelope MUST be the same as the Overnet Program Protocol specification, except:

- the transport is the auth-agent local IPC endpoint rather than program stdin/stdout
- no runtime/program initialization handshake is required by this document

This means the auth-agent protocol reuses:

- UTF-8 JSON object payloads
- length-prefixed framing
- `request`, `response`, and `notification` message types
- structured `error` objects

### 10.4 Baseline Methods

This version defines the following baseline auth-agent methods:

- `agent.info`
- `identities.list`
- `policies.list`
- `policies.grant`
- `policies.revoke`
- `service_pins.list`
- `service_pins.set`
- `service_pins.forget`
- `sessions.list`
- `sessions.authorize`
- `sessions.renew`
- `sessions.revoke`

Implementations MAY define additional methods, but they MUST NOT weaken the baseline trust rules defined by this document.

### 10.5 `agent.info`

Purpose:

- discover agent version and capabilities

Successful result MAY include:

| Field | Type | Required | Description |
|---|---|---|---|
| `protocol_version` | string | yes | Auth-agent protocol version |
| `agent_implementation` | string | no | Implementation identifier |
| `capabilities` | array | no | Supported optional capability tokens |
| `backend_types` | array | no | Supported secret-backend type identifiers |

### 10.6 `identities.list`

Purpose:

- list local identities available to the current user and policy context

Successful result:

| Field | Type | Required | Description |
|---|---|---|---|
| `identities` | array | yes | Available local identity descriptors |

Each identity descriptor MUST include:

| Field | Type | Required | Description |
|---|---|---|---|
| `identity_id` | string | yes | Stable local identity identifier |
| `public_identity` | object | yes | Non-secret public identity descriptor |

The `public_identity` object SHOULD include:

| Field | Type | Required | Description |
|---|---|---|---|
| `scheme` | string | yes | Public identity scheme identifier |
| `value` | string | yes | Public identity value |
| `display` | string | no | User-facing label |

The agent MAY additionally include:

- `is_default`
- `backend_type`
- other non-secret metadata

### 10.7 `policies.list`

Purpose:

- inspect reusable approval policy currently known to the auth agent

Successful result:

| Field | Type | Required | Description |
|---|---|---|---|
| `policies` | array | yes | Reusable approval policy descriptors |

Each policy descriptor MUST include:

| Field | Type | Required | Description |
|---|---|---|---|
| `policy_id` | string | yes | Stable local policy identifier |
| `identity_id` | string | yes | Bound local identity |
| `program_id` | string | yes | Bound program or bridge identity |
| `scope` | string | yes | Bound scope |
| `action` | string | yes | Bound action type |

Each policy descriptor MAY additionally include:

- `locators`
- `service_identity`

### 10.8 `policies.grant`

Purpose:

- create one reusable approval policy in the local auth agent

Request parameters MUST include:

| Field | Type | Required | Description |
|---|---|---|---|
| `policy` | object | yes | Requested reusable approval policy |

The `policy` object MUST include:

| Field | Type | Required | Description |
|---|---|---|---|
| `identity_id` | string | yes | Bound local identity |
| `program_id` | string | yes | Bound program or bridge identity |
| `scope` | string | yes | Bound scope |
| `action` | string | yes | Bound action type |

The `policy` object MUST include at least one of:

- `locators`
- `service_identity`

The `policy` object MAY instead use one `service` object carrying those same service constraints.

Successful result MUST include:

| Field | Type | Required | Description |
|---|---|---|---|
| `policy` | object | yes | Stored policy descriptor including `policy_id` |

### 10.9 `policies.revoke`

Purpose:

- remove one reusable approval policy from the local auth agent

Request parameters MUST include:

| Field | Type | Required | Description |
|---|---|---|---|
| `policy_id` | string | yes | Stable local policy identifier |

Successful result MAY include:

| Field | Type | Required | Description |
|---|---|---|---|
| `policy_id` | string | no | Revoked policy identifier |

### 10.10 `service_pins.list`

Purpose:

- inspect currently pinned remote service identities

Successful result:

| Field | Type | Required | Description |
|---|---|---|---|
| `service_pins` | array | yes | Locator-to-service-identity pin descriptors |

Each service-pin descriptor MUST include:

| Field | Type | Required | Description |
|---|---|---|---|
| `locator` | string | yes | Bound locator |
| `service_identity` | object | yes | Pinned service identity descriptor |

### 10.11 `service_pins.set`

Purpose:

- pin one remote service identity to one locator explicitly

Request parameters MUST include:

| Field | Type | Required | Description |
|---|---|---|---|
| `locator` | string | yes | Locator being pinned |
| `service_identity` | object | yes | Stable service identity descriptor |

Successful result MAY include:

| Field | Type | Required | Description |
|---|---|---|---|
| `locator` | string | no | Locator that was pinned |
| `service_identity` | object | no | Stored pinned service identity |

### 10.12 `service_pins.forget`

Purpose:

- remove one pinned remote service identity by locator

Request parameters MUST include:

| Field | Type | Required | Description |
|---|---|---|---|
| `locator` | string | yes | Locator whose pin is being removed |

Successful result MAY include:

| Field | Type | Required | Description |
|---|---|---|---|
| `locator` | string | no | Locator that was forgotten |

### 10.13 `sessions.list`

Purpose:

- inspect locally tracked session state currently known to the auth agent

Successful result:

| Field | Type | Required | Description |
|---|---|---|---|
| `sessions` | array | yes | Local session descriptors |

Each session descriptor MUST include:

| Field | Type | Required | Description |
|---|---|---|---|
| `session_handle` | object | yes | Stable local session handle |
| `identity_id` | string | yes | Bound local identity |
| `program_id` | string | yes | Bound program or bridge identity |
| `service` | object | yes | Bound service context |
| `scope` | string | yes | Bound scope |
| `action` | string | yes | Bound action type |
| `renewable` | boolean | yes | Whether renewal is currently permitted |

The session descriptor MAY additionally include:

- `expires_at`

### 10.14 `sessions.authorize`

Purpose:

- evaluate one current auth request
- obtain approval if required
- return one or more signed artifacts or session artifacts

Request parameters MUST include:

| Field | Type | Required | Description |
|---|---|---|---|
| `program_id` | string | yes | Stable requesting program or bridge identifier |
| `service` | object | yes | Remote service trust context |
| `scope` | string | yes | Requested scope |
| `action` | string | yes | Requested action type |
| `artifacts` | array | yes | Requested artifact descriptions |

The request parameters MAY include:

| Field | Type | Required | Description |
|---|---|---|---|
| `identity_id` | string | no | Requested local identity |
| `challenge` | object | no | Companion-spec-defined challenge context |
| `interactive` | boolean | no | Whether prompting is permitted; default `true` |
| `bridge_context` | object | no | Additional non-secret bridge context |

The `service` object MUST include:

| Field | Type | Required | Description |
|---|---|---|---|
| `locators` | array | yes | Non-empty array of locators |

The `service` object SHOULD include:

| Field | Type | Required | Description |
|---|---|---|---|
| `service_identity` | object | no | Stable cryptographic service identity when defined |
| `display` | string | no | User-facing service label |

If `service_identity` is absent:

- the auth agent MUST treat the request as provisional locator trust under section 7.2

Each requested artifact description MUST include:

| Field | Type | Required | Description |
|---|---|---|---|
| `type` | string | yes | Requested artifact type |
| `params` | object | no | Type-specific parameters |

The auth agent MUST reject:

- unknown action types
- unknown artifact types
- semantically incomplete requests for the recognized action and artifact combination

Successful result MUST include:

| Field | Type | Required | Description |
|---|---|---|---|
| `identity_id` | string | yes | Local identity used |
| `artifacts` | array | yes | Approved artifacts |

The result MAY include:

| Field | Type | Required | Description |
|---|---|---|---|
| `session_handle` | object | no | Opaque local handle for later renewal or revocation |
| `service_pin_state` | string | no | `known`, `first_contact`, or `provisional` |

Each returned artifact MUST include:

| Field | Type | Required | Description |
|---|---|---|---|
| `type` | string | yes | Artifact type |
| `format` | string | yes | Artifact value format |
| `value` | object or string | yes | Artifact payload |

Baseline artifact types defined by this document are:

- `nostr.event`
- `session.token`

For `nostr.event`:

- `format` MUST be `nostr.event`
- `value` MUST be one signed Nostr event object

For `session.token`:

- `format` MUST identify one companion-spec-defined token representation
- `value` MUST be one opaque token string or one companion-spec-defined structured token object

An auth agent MAY support additional artifact types defined by a companion specification.

#### 10.14.1 Informative IRC Example

The following is an informative example of one IRC bridge asking for one signed auth event for `OVERNETAUTH AUTH` using provisional locator trust because no stable IRC service identity has yet been established by the companion specification:

```json
{
  "type": "request",
  "id": "irc-auth-1",
  "method": "sessions.authorize",
  "params": {
    "program_id": "irc.bridge",
    "identity_id": "default",
    "service": {
      "locators": [
        "irc://irc.example.test/overnet"
      ],
      "display": "irc.example.test overnet"
    },
    "scope": "irc://irc.example.test/overnet",
    "action": "session.authenticate",
    "challenge": {
      "type": "opaque",
      "value": "6cf8a952df516a8e691c6138496516abe84ccfefa9678f518bb52f70b1ca966f"
    },
    "artifacts": [
      {
        "type": "nostr.event",
        "params": {
          "kind": 22242,
          "tags": [
            ["relay", "irc://irc.example.test/overnet"],
            ["challenge", "6cf8a952df516a8e691c6138496516abe84ccfefa9678f518bb52f70b1ca966f"]
          ]
        }
      }
    ]
  }
}
```

An informative successful response could then include:

```json
{
  "type": "response",
  "id": "irc-auth-1",
  "ok": true,
  "result": {
    "identity_id": "default",
    "service_pin_state": "provisional",
    "artifacts": [
      {
        "type": "nostr.event",
        "format": "nostr.event",
        "value": {
          "id": "190806b6e219eb629d5ea42ea726000b842c83d5ba834510aa238449a94cc5fb",
          "pubkey": "274722f14ff06e2a790322ae1cee2d28c9cb0ffcd18d78d3bc7cca3f19e9764d",
          "created_at": 1744301000,
          "kind": 22242,
          "tags": [
            ["relay", "irc://irc.example.test/overnet"],
            ["challenge", "6cf8a952df516a8e691c6138496516abe84ccfefa9678f518bb52f70b1ca966f"]
          ],
          "content": "",
          "sig": "0d8210fabb59170534aa947572fcbb1f4bc7867afebce8c05e571cbdcfe775191735cd37cae300fecfe92c210b171bb2b36e3b0f5568bad1295c742df10732c4"
        }
      }
    ]
  }
}
```

An IRC bridge MAY then base64-encode the returned `nostr.event` artifact into the exact `OVERNETAUTH AUTH` wire form required by the IRC companion specification.

### 10.15 `sessions.renew`

Purpose:

- renew one still-recognized session context

Request parameters MUST include:

| Field | Type | Required | Description |
|---|---|---|---|
| `session_handle` | object | yes | Opaque local session handle |

The request MAY additionally include:

| Field | Type | Required | Description |
|---|---|---|---|
| `challenge` | object | no | New challenge material for renewal |
| `interactive` | boolean | no | Whether prompting is permitted; default `true` |

The auth agent MUST reject renewal when:

- the session handle is unknown
- the session context no longer matches current policy
- the remote service identity or pinned trust context has changed
- the session is no longer renewable under section 9.3

The successful result shape is the same as `sessions.authorize`.

### 10.16 `sessions.revoke`

Purpose:

- drop one locally cached session context

Request parameters MUST include:

| Field | Type | Required | Description |
|---|---|---|---|
| `session_handle` | object | yes | Opaque local session handle |

Successful result MAY be empty.

This method revokes or forgets local auth-agent session state. It does not imply one universal remote logout semantics.

### 10.17 Baseline Error Codes

Auth-agent error responses use the shared error object and baseline error code
conventions defined in the Overnet Program Protocol specification, section 8.
Error codes are namespaced: envelope-level failures use the shared `protocol.`
codes, and auth-domain failures use the `auth.` namespace defined by this
document.

For envelope-level failures the auth-agent protocol MUST use the applicable
baseline `protocol.` codes rather than auth-specific codes:

| Code | Meaning |
|---|---|
| `protocol.invalid_message` | Request envelope is malformed (not an object, wrong `type`, missing `method`) |
| `protocol.unknown_method` | `method` is not recognized in this context |
| `protocol.invalid_params` | `params` is missing required structure |

At minimum, the auth-agent protocol MUST additionally distinguish the
following auth-domain codes:

- `auth.unknown_identity`
- `auth.identity_required`
- `auth.unsupported_action`
- `auth.unsupported_artifact`
- `auth.approval_required`
- `auth.policy_denied`
- `auth.service_identity_mismatch`
- `auth.headless_unavailable`
- `auth.backend_unavailable`
- `auth.internal_failure`

`auth.internal_failure` is the fallback code: an agent that encounters an
unexpected internal failure while handling an otherwise well-formed request
MUST still answer that request with an `auth.internal_failure` error response
rather than leaving the request unanswered.

Companion specifications MAY define narrower codes within the `auth.`
namespace.

## 11. Bridge Model

### 11.1 General Bridge Requirements

A bridge using the auth agent:

- MUST preserve the underlying companion-spec auth semantics exactly
- MUST NOT widen approved scope, service identity, action type, or identity binding
- MUST NOT receive raw private key material
- MAY cache opaque local session handles
- MAY automate remote-protocol auth exchanges when the resulting remote behavior is semantically identical to the underlying companion specification

### 11.2 Legacy Client UX

For legacy protocols and clients, the auth agent and bridge SHOULD hide raw event construction and opaque challenge handling from the user.

The intended user experience is:

- ordinary login or connect behavior
- rare human-readable approval prompts when trust or policy requires it
- automatic renewal when policy allows it

The intended user experience is not:

- repeated manual construction of raw signed events
- repeated manual copy-and-paste of opaque challenge responses

### 11.3 IRC Compatibility

For IRC companion surfaces that use:

- `OVERNETAUTH`
- SASL `NOSTR`
- relay-backed session delegation

an IRC bridge MAY use the auth agent to produce the required signed artifacts.

When it does so:

- the resulting IRC auth semantics MUST remain exactly equivalent to the IRC companion specification
- the bridge MUST NOT change the bound pubkey, auth scope, relay URL, session identifier, or expiry semantics
- the bridge MUST NOT expose raw private key material to the IRC client, ZNC, or IRC server
- a returned `nostr.event` artifact MAY be encoded into the bridge's required wire form, such as base64-encoded JSON, so long as the underlying event object is unchanged

## 12. Security Requirements

### 12.1 No Silent Trust Widening

An auth agent MUST NOT silently widen trust across:

- identities
- programs or bridges
- services
- locators
- scopes
- action types

### 12.2 Replay Protection

Where the companion specification uses one challenge or one session-bound request context:

- the auth agent and the consuming program or bridge MUST preserve that challenge or request binding
- the auth agent MUST NOT intentionally strip or loosen replay-relevant fields

Replay prevention remains companion-spec-specific, but the auth agent MUST preserve the information needed for the companion specification to enforce it.

### 12.3 Auditability

An auth agent SHOULD keep a local audit trail of:

- approvals
- denials
- first-contact trust decisions
- service-identity changes
- session issuance and renewal decisions

This document does not require one specific storage format for audit records.

## 13. Out of Scope for This Version

This version does not define:

- one universal remote service-identity discovery mechanism
- one universal UI model for approvals
- one universal token format for every remote session type
- one universal cross-platform endpoint naming scheme beyond the baseline local IPC requirements above
- one hardware-token integration model
- one global service-identity registry

Companion specifications MAY refine these areas later, but they MUST preserve the trust and approval model defined here.
