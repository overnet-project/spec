# Overnet Private Messaging Specification

## Status of This Document

This document defines Overnet private direct messaging as a companion specification to the Overnet core, the Overnet Relay Specification, and applicable application or adapter companion specifications.

It is a working draft.

Unless stated otherwise, the main body of this document is normative.

## 1. Purpose

This specification defines the first encrypted relay-carried private direct-message transport for Overnet.

The Overnet core defines:

- Overnet event and object semantics
- provenance rules
- the relay role and trust boundary

The Overnet Relay Specification defines:

- baseline relay metadata
- baseline event publication, query, and subscription behavior
- the narrow generic derived-object read surface

This document defines:

- how one-to-one private direct messages are carried across relays
- the required encrypted transport for relay-carried private direct messages
- the decrypted payload shape for relay-carried private direct messages
- how relay-carried private direct messages relate to logical Overnet `chat.dm` semantics

This version is intentionally narrow. It does not define group messaging, attachments, read receipts, typing indicators, encrypted object queries, or archive semantics for private direct messages.

## 2. Relationship to the Overnet Core, Relay Specification, and to Nostr

This specification is a companion specification to the Overnet core and the Overnet Relay Specification.

The Overnet core remains authoritative for:

- logical event and object semantics
- provenance requirements
- identity and signature validity

The Overnet Relay Specification remains authoritative for:

- generic relay capabilities
- the baseline public event query and subscription surface
- generic relay metadata

This specification is authoritative for the encrypted transport of relay-carried one-to-one private direct messages.

Relay-carried private direct messages under this specification MUST use `NIP-17`.

For this version, that means:

- the logical private message is represented as a kind `14` rumor
- the rumor is sealed and gift-wrapped according to `NIP-17`
- the relay-visible event is the resulting kind `1059` gift wrap event

`NIP-04` is not part of this specification.

This specification does not redefine generic relay event queries or generic relay object reads for encrypted private-message contents.

The Overnet Program Services specification defines the baseline runtime-visible service method and notification shape used when a trusted runtime accepts and redistributes encrypted private direct messages between programs.

## 3. Scope of This Version

This version defines only one-to-one private direct messaging.

This version supports two logical private item types:

- `chat.dm_message`
- `chat.dm_notice`

This version does not define:

- private group chat
- private file transfer
- encrypted search
- relay-side derivation of decrypted private-message objects
- relay-assisted private-message archive guarantees
- message history replay beyond what a participant can decrypt from stored wrapped events

## 4. Transport Model

### 4.1 Relay-Carried Private Direct Messages

When the sender intends a direct message or direct notice to remain private from generic relay operators, the implementation MUST carry that message using the encrypted transport defined in this specification rather than publishing the plaintext body as an ordinary public Overnet core event.

For this version, a relay-carried private direct message MUST use:

- one kind `14` rumor containing the decrypted Overnet private-message payload
- one or more kind `1059` gift wraps derived from that rumor according to `NIP-17`

### 4.2 One-to-One Recipient Rule

A relay-carried one-to-one private direct message under this specification MUST identify exactly one intended recipient in the decrypted rumor through exactly one `p` tag.

An implementation MAY additionally create a sender-readable self-wrap copy, but that does not change the one-recipient rule for the rumor itself.

### 4.3 Sender and Timestamp

The sender identity for a relay-carried private direct message is the rumor `pubkey`.

The message timestamp is the rumor `created_at`.

The decrypted payload defined by this specification MUST NOT duplicate either of those values.

### 4.4 Runtime-Visible Candidate and Accepted Shapes

When a trusted Overnet runtime accepts an encrypted private direct message through a baseline program service method, the program-supplied candidate object MUST include:

- `transport`, containing the candidate relay-visible wrapped event object

This specification defines two runtime-visible candidate forms:

- trusted-decrypted candidate form
- opaque endpoint-blind candidate form

#### 4.4.1 Trusted-Decrypted Candidate Form

In the trusted-decrypted form, the candidate object MUST also include:

- `transport.decrypted_rumor`, containing the paired decrypted rumor object used for trusted validation

This form is appropriate only when the program or runtime component is intentionally part of the plaintext trust boundary.

#### 4.4.2 Opaque Endpoint-Blind Candidate Form

In the opaque endpoint-blind form, the candidate object MUST omit `transport.decrypted_rumor`.

Instead, the candidate object MUST include the following logical routing metadata outside the ciphertext:

- `private_type`
- `object_type`
- `object_id`

The candidate object MAY additionally include:

- `sender_identity`, containing a cleartext presentational sender identity string used by a boundary component such as an IRC server to render or route the item without decrypting the message body

The opaque endpoint-blind form is intended for transports where the sending endpoint performs encryption locally and the runtime or gateway routes the resulting wrapped event without access to the decrypted payload.

The accepted runtime notification or stored-item shape MUST expose:

- `transport`, containing only the visible wrapped event object
- `private_type`
- `object_type`
- `object_id`

The accepted runtime notification or stored-item shape MAY additionally expose:

- `decrypted_rumor`, containing the runtime-validated decrypted rumor object when the trusted-decrypted form was used
- `sender_identity`, containing cleartext routing or presentation metadata supplied by the trusted ingress boundary

The program services specification MAY define additional runtime-visible convenience fields derived from the decrypted payload when the runtime has access to that payload.

## 5. Decrypted Payload Format

### 5.1 Overview

The decrypted rumor `content` MUST be a UTF-8 JSON object with the following structure:

```json
{
  "overnet_v": "0.1.0",
  "private_type": "chat.dm_message",
  "object_type": "chat.dm",
  "object_id": "example:dm:alice:bob",
  "provenance": {
    "type": "native"
  },
  "body": {
    "text": "hello"
  }
}
```

### 5.2 Required Payload Fields

The decrypted JSON object MUST include:

| Field | Type | Required | Description |
|---|---|---|---|
| `overnet_v` | string | yes | Overnet core version string |
| `private_type` | string | yes | One of the private item types defined by this specification |
| `object_type` | string | yes | For this version, MUST be `chat.dm` |
| `object_id` | string | yes | Non-empty object identifier for the direct-message scope |
| `provenance` | object | yes | Provenance object following the Overnet core provenance rules |
| `body` | object | yes | Type-specific payload |

For this version:

- `private_type` MUST be either `chat.dm_message` or `chat.dm_notice`
- `object_type` MUST be `chat.dm`

The `provenance` field MUST follow the same rules defined by the Overnet core for `provenance`.

### 5.3 Type-Specific Body Rules

For both `chat.dm_message` and `chat.dm_notice`, the `body` object MUST include:

| Field | Type | Required | Description |
|---|---|---|---|
| `text` | string | yes | Direct-message text |

The `body` object MAY include additional adapter-defined or profile-defined fields so long as they do not change the required meaning of `text`.

### 5.4 Example Rumor

The following example is informative.

```json
{
  "kind": 14,
  "pubkey": "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
  "tags": [
    ["p", "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"]
  ],
  "content": "{\"overnet_v\":\"0.1.0\",\"private_type\":\"chat.dm_message\",\"object_type\":\"chat.dm\",\"object_id\":\"example:dm:alice:bob\",\"provenance\":{\"type\":\"native\"},\"body\":{\"text\":\"hello\"}}"
}
```

## 6. Relay and Query Behavior

### 6.1 Generic Relay Expectations

A generic relay is not required to inspect or derive the decrypted payload defined by this specification.

The public event query filters and the generic derived-object read endpoint defined by the Overnet Relay Specification do not apply to decrypted private-message contents under this specification.

### 6.2 Opaque Storage and Forwarding

A relay claiming support for relay-carried private direct messages MAY store and forward the visible kind `1059` gift wrap events as opaque encrypted data.

This specification does not require a generic relay to expose relay-side search, derivation, or visibility into decrypted private direct messages.

## 7. Relationship to Logical `chat.dm` Semantics

This specification defines encrypted transport for logical direct-message semantics. It does not replace the logical event names themselves.

For this version:

- `chat.dm_message` is the logical semantic item for a private direct-message body
- `chat.dm_notice` is the logical semantic item for a private direct notice body

An implementation MAY represent those same logical items internally using implementation-local structures for local-only delivery.

If the implementation carries them across relays as private direct messages, it MUST use the encrypted transport defined here.

## 8. IRC Adapter Binding

An implementation claiming support for relay-carried private IRC direct messaging MUST apply the following binding rules:

- an IRC non-channel `PRIVMSG` carried across relays as a private direct message MUST use `private_type` value `chat.dm_message`
- an IRC non-channel `NOTICE` carried across relays as a private direct message MUST use `private_type` value `chat.dm_notice`
- the decrypted payload `object_type` MUST be `chat.dm`
- the decrypted payload `object_id` MUST be `irc:<network>:dm:<target_nick>`
- the decrypted payload `provenance` MUST follow the IRC adapter provenance rules

This binding does not require a local-only IRC server implementation to use relay-carried encrypted transport for direct messages that never leave the local trust boundary.

### 8.1 Opaque IRC Endpoint-Blind Binding

An implementation MAY also support an endpoint-blind IRC private-message profile in which an E2E-aware IRC client sends the visible wrapped `NIP-17` transport directly and the IRC server or gateway does not decrypt it.

When an implementation uses that endpoint-blind IRC profile:

- the runtime-visible candidate MUST use the opaque endpoint-blind form defined in section 4.4.2
- `private_type` MUST still be `chat.dm_message` for IRC `PRIVMSG` and `chat.dm_notice` for IRC `NOTICE`
- `object_type` MUST still be `chat.dm`
- `object_id` MUST still be `irc:<network>:dm:<target_nick>`
- `sender_identity`, when exposed, MUST be the IRC nick presented by the gateway for the sending IRC client
- the implementation MUST NOT require decryption of the message body in order to derive the logical direct-message routing metadata above
- the implementation MUST treat `sender_identity` and the IRC target nick as observable metadata, not as encrypted body content

## 9. Conformance

An implementation claiming support for this specification MUST, at minimum:

- use `NIP-17` for relay-carried one-to-one private direct messages
- represent the logical message as a kind `14` rumor and relay-visible kind `1059` gift wraps
- include exactly one rumor `p` tag for the intended recipient
- use the decrypted JSON payload structure defined in section 5
- use `private_type` value `chat.dm_message` or `chat.dm_notice`
- use `object_type` value `chat.dm`
- preserve Overnet provenance in the decrypted payload
- avoid publishing the plaintext direct-message body as an ordinary public Overnet core event when the intent is a relay-carried private direct message

If an implementation claims support for the opaque endpoint-blind runtime form defined in section 4.4.2, it MUST also:

- accept `private_type`, `object_type`, and `object_id` as the logical metadata for that wrapped message without requiring `decrypted_rumor`
- preserve the relay-visible kind `1059` transport object
- avoid exposing plaintext body content to components that are intended to remain outside the plaintext trust boundary

## 10. Open Issues

This section is informative.

The following topics remain open for later private-messaging work:

- group private messaging
- attachment transfer
- read receipts and typing indicators
- use of kind `10050` relay lists and related relay-discovery rules
- better private-message object identity schemes beyond the first binding rules
- stronger archive or history semantics for encrypted private messages
