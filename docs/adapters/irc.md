# Overnet IRC Adapter Specification

## Status of This Document

This document defines the first companion adapter specification for IRC.

It is a working draft. Its purpose is to make the Overnet core adapter model concrete through one real protocol mapping.

Unless stated otherwise, the main body of this document is normative.

## 1. Scope

This specification defines how an IRC adapter exposes IRC data through Overnet semantics.

This first version is intentionally narrow. It defines:

- IRC network and channel identity mapping
- adapted channel message mapping for `PRIVMSG` and `NOTICE`
- adapted direct-message mapping for `PRIVMSG` and `NOTICE`
- adapted channel topic mapping for `TOPIC`
- adapted channel presence mapping for `JOIN`, `PART`, and `QUIT`
- adapted observed channel moderation-action mapping for `KICK`
- adapted network-scoped identity-change mapping for `NICK`
- adapted observed channel mode-change mapping for `MODE`
- an optional derived channel presence state view
- an optional minimal server-side IRC presentation slice for Overnet-backed IRC clients
- an optional endpoint-blind E2E direct-message profile for E2E-aware IRC clients
- provenance and limitation requirements for adapted IRC data
- baseline object identifiers for IRC network and channel objects

This version does not yet define:

- user-scoped mode mapping
- derived channel mode state or channel privilege state
- IRC operator or service authority semantics
- general write-back from Overnet into arbitrary IRC networks
- full IRC-server numerics, listing, and multi-client synchronization semantics

Consistent with the core adapter directionality guidance, an IRC adapter SHOULD aim for bi-directional interoperability where that can be defined honestly and safely.

This version remains intentionally partial in that respect. It defines the IRC-to-Overnet observation mapping in detail and defines only a narrow Overnet-to-IRC presentation slice for IRC clients. It does not yet define general write-back to upstream IRC networks or broader bidirectional synchronization behavior.

Those areas MAY be defined by later revisions of this adapter specification.

## 2. Relationship to the Overnet Core

This specification is a companion adapter specification to the Overnet core.

All core requirements continue to apply unless this document adds more specific requirements.

In particular:

- IRC-adapted events MUST satisfy the Overnet core event format
- IRC-adapted events MUST use `provenance.type` value `"adapted"`
- IRC-adapted events MUST disclose origin and known translation limitations
- IRC-adapted events MUST preserve the distinction between native Overnet authority and adapted IRC authority

## 3. Protocol Baseline

This specification defines a baseline IRC adapter model for traditional RFC-style IRC networks.

The baseline conformance target is channel-oriented IRC messaging as represented by the conventional IRC command model, without requiring IRCv3 support.

An implementation MAY support IRCv3 features, but IRCv3 behavior is out of scope for this version unless a section of this specification explicitly defines it.

Support for IRCv3-specific enhancements MAY be defined by later revisions of this specification.

### 3.1 Runtime Session Configuration

When the IRC adapter is exposed through the Overnet Program Runtime adapter-session service, the adapter is configured through `adapters.open_session`.

The IRC adapter `config` object MAY include non-secret session parameters such as:

- `network`
- `host`
- `port`
- `tls`
- `nick`
- `username`
- `realname`
- `channels`
- `sasl_mechanism`
- `sasl_username`

When this specification refers to `tls` in IRC program or adapter-session configuration, it means the baseline TLS configuration object defined by the Overnet Program Runtime specification.

For an outbound IRC client implementation, `tls.mode` is `client` when present unless a more specific companion specification states otherwise.

For a listening IRC server implementation, `tls.mode` is `server` when present unless a more specific companion specification states otherwise.

This specification MAY require a narrower subset of baseline TLS fields for a particular IRC deployment model, but it SHOULD reuse the baseline field names unchanged.

Secret-bearing connection or authentication material MUST NOT be supplied as plaintext in ordinary adapter `config`.

Instead, the program MUST supply those values through `adapters.open_session.params.secret_handles`.

This specification defines the following IRC adapter secret input slots:

| Slot | Meaning |
|---|---|
| `server_password` | IRC server password or PASS value when required by the network |
| `nickserv_password` | NickServ or similar account-service password used by the adapter session |
| `sasl_password` | SASL password or equivalent shared secret used during authentication |

If the runtime resolves a supplied IRC secret handle successfully, the runtime MAY expose the resolved value only to the adapter implementation inside the runtime or host boundary.

Any component that receives resolved IRC secret plaintext becomes part of the secret trust boundary for that connection or authentication operation.

An IRC adapter implementation that acts only as a semantic mapper and does not perform live connection or authentication work SHOULD declare the supported secret slots for compatibility, but SHOULD NOT persist, echo, or otherwise expose the resolved plaintext beyond the immediate privileged consumer that performs the secret-bearing operation.

The program MUST NOT receive the resolved plaintext value back through:

- `adapters.open_session`
- any adapter session identifier
- adapter result payloads
- runtime-generated notifications

If the adapter session cannot be opened because a required secret handle is invalid, expired, revoked, unauthorized, or missing, the runtime MUST reject `adapters.open_session`.

## 4. Terminology

The key words IRC network, IRC channel, IRC user, nick, and message in this document have their conventional IRC meanings.

For this specification:

- an IRC network is a distinct IRC service namespace such as `libera.chat`
- an IRC channel is a named IRC channel within one IRC network such as `#overnet`
- an IRC channel message is a `PRIVMSG` sent to a channel target
- an IRC channel notice is a `NOTICE` sent to a channel target
- an IRC direct message is a `PRIVMSG` sent to a non-channel target
- an IRC direct notice is a `NOTICE` sent to a non-channel target
- an IRC channel topic update is a `TOPIC` command sent to a channel target
- an IRC channel join is a `JOIN` observed for a channel target
- an IRC channel part is a `PART` observed for a channel target
- an IRC channel quit is a `QUIT` observed in channel context for a channel target
- an IRC channel kick is a `KICK` observed for a channel target
- an IRC nick change is a `NICK` observed on an IRC network
- an IRC channel mode change is a `MODE` observed for a channel target
- an IRC identity is the best adapter-visible external identity available for the IRC sender at the time of observation

## 5. Adapter Identity and Trust Boundary

An IRC adapter publishes adapted Overnet events under the adapter's native Overnet identity.

The Nostr `pubkey` on an adapted IRC event is the adapter identity, not the IRC sender identity.

The IRC sender identity MUST be carried through provenance using `external_identity` when the sender is attributable.

The adapter MUST NOT present IRC-originated content as native Overnet content.

## 6. IRC Identity Mapping

### 6.1 External Identity Form

For IRC-adapted events defined by this specification, `provenance.external_identity` MUST be the IRC nick observed for the sender.

If the adapter can reliably observe additional identity material, it MAY include that information in `body.irc_identity`.

When present, `body.irc_identity` MUST be a JSON object. The following fields are defined by this specification:

| Field | Type | Description |
|---|---|---|
| `account` | string | Authenticated IRC account name for the sender |
| `user` | string | IRC username component from the observed prefix or session metadata |
| `host` | string | IRC host component from the observed prefix or session metadata |

An implementation MUST NOT replace the required `external_identity` nick string with `body.irc_identity` or any implementation-private identity structure.

### 6.2 Identity Stability

IRC nicknames are not stable global identities.

An implementation conforming to this specification MUST treat IRC nick-based identity mapping as potentially unstable and MUST disclose this through provenance limitations when appropriate.

At minimum, an IRC-adapted event defined by this specification MUST include limitation identifier `unsigned`.

An IRC-adapted event defined by this specification MUST include limitation identifier `synthetic_identity` unless the adapter includes a non-empty authenticated IRC account name in `body.irc_identity.account`.

The presence of `user` or `host` information alone does not remove the requirement for `synthetic_identity`.

## 7. Object Mapping

### 7.1 Network Object

An IRC network MAY be represented as an Overnet object of type `irc.network`.

This first version does not require publication of explicit network objects.

When this specification maps a network-scoped IRC event, the object identifier for the IRC network MUST be:

```text
irc:<network>
```

Where `<network>` is the IRC network identifier as used by the adapter.

### 7.2 Channel Object

An IRC channel MUST be represented as a stable Overnet object of type `chat.channel`.

The object identifier for an IRC channel MUST be:

```text
irc:<network>:<channel>
```

Where:

- `<network>` is the IRC network identifier as used by the adapter
- `<channel>` is the exact IRC channel name including its prefix, such as `#overnet`

Examples:

- `irc:libera.chat:#overnet`
- `irc:irc.example.org:&staff`

The adapter MUST preserve channel case exactly as observed by the adapter's IRC environment unless a later revision of this specification defines canonical case-folding rules.

### 7.3 Message Modeling

An IRC channel message MUST be represented as an Overnet event on the corresponding `chat.channel` object.

This specification does not define a separate stable Overnet object type for each IRC message.

### 7.4 Direct-Message Object

An IRC direct-message conversation MUST be represented as a stable Overnet object of type `chat.dm`.

The object identifier for an IRC direct-message conversation MUST be:

```text
irc:<network>:dm:<nick>
```

Where:

- `<network>` is the IRC network identifier as used by the adapter
- `<nick>` is the exact IRC nick used as the direct-message peer identifier

Examples:

- `irc:irc.libera.chat:dm:alice`
- `irc:irc.example.org:dm:ChanServ`

This direct-message object identifier is adapter-local and directional. This specification does not define a canonical shared conversation identifier across both IRC participants.

## 8. Event Mapping

### 8.1 Channel `PRIVMSG`

An IRC `PRIVMSG` sent to a channel target MUST be mapped to an Overnet event with:

- `kind` `7800`
- `overnet_et` value `chat.message`
- `overnet_ot` value `chat.channel`
- `overnet_oid` value equal to the mapped IRC channel object identifier

The event `body` MUST include:

| Field | Type | Description |
|---|---|---|
| `text` | string | The channel message text as observed by the adapter |

The adapter MAY include additional adapter-defined fields in `body` when necessary, but those fields MUST NOT change the required interpretation of `text`.

### 8.2 Channel `NOTICE`

An IRC `NOTICE` sent to a channel target MUST be mapped to an Overnet event with:

- `kind` `7800`
- `overnet_et` value `chat.notice`
- `overnet_ot` value `chat.channel`
- `overnet_oid` value equal to the mapped IRC channel object identifier

The event `body` MUST include:

| Field | Type | Description |
|---|---|---|
| `text` | string | The channel notice text as observed by the adapter |

The event `body` MAY include `irc_identity` as defined in section 6.1.

### 8.3 Direct-Message `PRIVMSG`

An IRC `PRIVMSG` sent to a non-channel target MUST be mapped to an Overnet event with:

- `kind` `7800`
- `overnet_et` value `chat.dm_message`
- `overnet_ot` value `chat.dm`
- `overnet_oid` value equal to the mapped direct-message object identifier

The event `body` MUST include:

| Field | Type | Description |
|---|---|---|
| `text` | string | The direct-message text as observed by the adapter |

The event `body` MAY include `irc_identity` as defined in section 6.1.

### 8.4 Direct-Message `NOTICE`

An IRC `NOTICE` sent to a non-channel target MUST be mapped to an Overnet event with:

- `kind` `7800`
- `overnet_et` value `chat.dm_notice`
- `overnet_ot` value `chat.dm`
- `overnet_oid` value equal to the mapped direct-message object identifier

The event `body` MUST include:

| Field | Type | Description |
|---|---|---|
| `text` | string | The direct-message notice text as observed by the adapter |

The event `body` MAY include `irc_identity` as defined in section 6.1.

### 8.4.1 Relationship to Private Messaging Transport

Sections 8.3 and 8.4 define the logical Overnet semantics of IRC direct messages and notices.

If an implementation carries those direct-message semantics across relays or across any boundary where generic relay operators are not intended to read the message body, the implementation SHOULD use the [Overnet Private Messaging Specification](../private-messaging.md).

An implementation claiming support for relay-carried private IRC direct messaging MUST:

- encode the logical item using the private direct-message transport defined by that companion specification
- use `private_type` value `chat.dm_message` or `chat.dm_notice` as appropriate
- use `object_id` value `irc:<network>:dm:<target_nick>`
- preserve IRC provenance according to this specification

A local-only implementation MAY represent those same logical items internally without using the relay-carried private transport defined by that companion specification.

An implementation MAY additionally support an endpoint-blind E2E IRC client profile in which:

- the sending IRC client performs the `NIP-17` encryption locally
- the server receives only the visible kind `1059` wrapped transport plus cleartext routing metadata
- the server or gateway routes that message without decrypting the body
- the receiving IRC client decrypts the body locally

When an implementation supports that endpoint-blind E2E IRC client profile, the implementation MUST apply the opaque endpoint-blind candidate rules defined by the [Overnet Private Messaging Specification](../private-messaging.md).

### 8.5 Channel `TOPIC`

An IRC `TOPIC` command sent to a channel target MUST be mapped to an Overnet state event with:

- `kind` `37800`
- `overnet_et` value `chat.topic`
- `overnet_ot` value `chat.channel`
- `overnet_oid` value equal to the mapped IRC channel object identifier
- exactly one `d` tag whose value equals `overnet_oid`

The event `body` MUST include:

| Field | Type | Description |
|---|---|---|
| `topic` | string | The current channel topic text as observed by the adapter |

The event `body` MAY include `irc_identity` as defined in section 6.1.

An empty topic string is valid and represents a channel topic that has been cleared.

An IRC `TOPIC` mapping defined by this specification MUST target a channel object. A `TOPIC` command sent to a non-channel target is invalid for this adapter version.

### 8.6 Channel `JOIN`

An IRC `JOIN` observed for a channel target MUST be mapped to an Overnet event with:

- `kind` `7800`
- `overnet_et` value `chat.join`
- `overnet_ot` value `chat.channel`
- `overnet_oid` value equal to the mapped IRC channel object identifier

The event `body` MAY include `irc_identity` as defined in section 6.1.

An IRC `JOIN` mapping defined by this specification MUST target a channel object. A `JOIN` command sent to a non-channel target is invalid for this adapter version.

### 8.7 Channel `PART`

An IRC `PART` observed for a channel target MUST be mapped to an Overnet event with:

- `kind` `7800`
- `overnet_et` value `chat.part`
- `overnet_ot` value `chat.channel`
- `overnet_oid` value equal to the mapped IRC channel object identifier

The event `body` MAY include:

| Field | Type | Description |
|---|---|---|
| `reason` | string | Optional IRC part reason text as observed by the adapter |

The event `body` MAY include `irc_identity` as defined in section 6.1.

An IRC `PART` mapping defined by this specification MUST target a channel object. A `PART` command sent to a non-channel target is invalid for this adapter version.

### 8.8 Channel `QUIT`

An IRC `QUIT` observed in channel context MUST be mapped to an Overnet event with:

- `kind` `7800`
- `overnet_et` value `chat.quit`
- `overnet_ot` value `chat.channel`
- `overnet_oid` value equal to the mapped IRC channel object identifier

The event `body` MAY include:

| Field | Type | Description |
|---|---|---|
| `reason` | string | Optional IRC quit reason text as observed by the adapter |

The event `body` MAY include `irc_identity` as defined in section 6.1.

An IRC `QUIT` mapping defined by this specification MUST include a channel target naming the channel context in which the quit was observed. A `QUIT` command sent without a channel target is invalid for this adapter version.

### 8.9 Channel `KICK`

An IRC `KICK` observed for a channel target MUST be mapped to an Overnet event with:

- `kind` `7800`
- `overnet_et` value `chat.kick`
- `overnet_ot` value `chat.channel`
- `overnet_oid` value equal to the mapped IRC channel object identifier

The event `body` MUST include:

| Field | Type | Description |
|---|---|---|
| `target_nick` | string | The IRC nick that was kicked |

The event `body` MAY include:

| Field | Type | Description |
|---|---|---|
| `reason` | string | Optional IRC kick reason text as observed by the adapter |

The event `body` MAY include `irc_identity` as defined in section 6.1.

An IRC `KICK` mapping defined by this specification MUST target a channel object. A `KICK` command sent to a non-channel target is invalid for this adapter version.

The adapter input for `KICK` MUST provide the kicked IRC nick separately from the channel target. This specification refers to that value as `target_nick`.

### 8.10 Network `NICK`

An IRC `NICK` observed on an IRC network MUST be mapped to an Overnet event with:

- `kind` `7800`
- `overnet_et` value `irc.nick`
- `overnet_ot` value `irc.network`
- `overnet_oid` value equal to the mapped IRC network object identifier

The event `body` MUST include:

| Field | Type | Description |
|---|---|---|
| `old_nick` | string | The actor's pre-change IRC nick |
| `new_nick` | string | The actor's new IRC nick |

The event `body` MAY include `irc_identity` as defined in section 6.1.

The adapter input for `NICK` MUST provide the new IRC nick separately from the network identifier. This specification refers to that value as `new_nick`.

`provenance.external_identity` on a mapped `NICK` event MUST be the actor's pre-change nick and MUST match `body.old_nick`.

`NICK` is network-scoped. A conforming mapping MUST NOT treat a nick change as specific to one channel object.

### 8.11 Channel `MODE`

An IRC `MODE` observed for a channel target MUST be mapped to an Overnet event with:

- `kind` `7800`
- `overnet_et` value `irc.mode`
- `overnet_ot` value `chat.channel`
- `overnet_oid` value equal to the mapped IRC channel object identifier

The event `body` MUST include:

| Field | Type | Description |
|---|---|---|
| `mode` | string | The raw IRC mode change string as observed by the adapter, such as `+o` or `+nt-k` |

The event `body` MAY include:

| Field | Type | Description |
|---|---|---|
| `mode_args` | array of strings | Ordered IRC mode arguments corresponding to the observed mode change |

The event `body` MAY include `irc_identity` as defined in section 6.1.

An IRC `MODE` mapping defined by this specification MUST target a channel object. A `MODE` command sent to a non-channel target is invalid for this adapter version.

The adapter input for `MODE` MUST provide the raw mode string separately from the channel target. This specification refers to that value as `mode`.

This mapping is observational. It records that an IRC mode change was observed. It does not by itself define canonical channel state, channel privilege state, or native Overnet moderation authority.

### 8.12 Derived Channel Presence State

An implementation MAY publish a derived channel presence view for an IRC channel as an Overnet state event with:

- `kind` `37800`
- `overnet_et` value `irc.channel_presence`
- `overnet_ot` value `chat.channel`
- `overnet_oid` value equal to the mapped IRC channel object identifier
- exactly one `d` tag whose value equals `overnet_oid`

This derived state is secondary to the observed IRC event stream defined elsewhere in this specification. It MUST NOT be interpreted as canonical IRC truth beyond the adapter's observed scope.

The event `body` MUST include:

| Field | Type | Description |
|---|---|---|
| `members` | array | Current adapter-observed channel members |
| `partial` | boolean | Whether the derived view is partial |
| `as_of` | integer | Unix timestamp of the newest observed event included in the derivation |

Each `members` entry MUST be a JSON object with:

| Field | Type | Description |
|---|---|---|
| `nick` | string | Current IRC nick for the observed member |

Each `members` entry MAY include:

| Field | Type | Description |
|---|---|---|
| `account` | string | Latest known authenticated IRC account for the member |
| `user` | string | Latest known IRC username for the member |
| `host` | string | Latest known IRC host for the member |
| `last_event_type` | string | Overnet event type of the newest observed event that affected this member's presence state |

The adapted provenance on this derived state MUST:

- use `provenance.type` value `"adapted"`
- use `provenance.protocol` value `"irc"`
- use `provenance.origin` in the `<network>/<channel>` form
- use `provenance.external_scope` value `channel_membership`
- include `unsigned`
- include `irc.ephemeral_presence`
- include `irc.partial_membership` when `body.partial` is `true`

When this derived view is published, the implementation MUST derive it only from observed IRC events. At minimum, `JOIN`, `PART`, `QUIT`, `KICK`, and `NICK` MUST affect the derived membership view in the obvious IRC-semantic direction.

### 8.13 Channel Message Example

The following example is informative:

```json
{
  "kind": 7800,
  "tags": [
    ["overnet_v", "0.1.0"],
    ["overnet_et", "chat.message"],
    ["overnet_ot", "chat.channel"],
    ["overnet_oid", "irc:libera.chat:#overnet"]
  ],
  "content": "{\"provenance\":{\"type\":\"adapted\",\"protocol\":\"irc\",\"origin\":\"irc.libera.chat/#overnet\",\"external_identity\":\"alice\",\"limitations\":[\"unsigned\",\"no_edit_history\",\"synthetic_identity\"]},\"body\":{\"text\":\"Hello from IRC!\"}}"
}
```

### 8.14 Direct-Message Example

The following example is informative:

```json
{
  "kind": 7800,
  "tags": [
    ["overnet_v", "0.1.0"],
    ["overnet_et", "chat.dm_message"],
    ["overnet_ot", "chat.dm"],
    ["overnet_oid", "irc:irc.libera.chat:dm:alice"]
  ],
  "content": "{\"provenance\":{\"type\":\"adapted\",\"protocol\":\"irc\",\"origin\":\"irc.libera.chat/alice\",\"external_identity\":\"alice\",\"limitations\":[\"unsigned\",\"no_edit_history\",\"synthetic_identity\"]},\"body\":{\"text\":\"hello in private\"}}"
}
```

## 9. Provenance Requirements

For every IRC-adapted message, notice, topic update, presence event, network identity-change event, observed mode-change event, or derived channel presence state defined by this specification:

- `provenance.type` MUST be `"adapted"`
- `provenance.protocol` MUST be `"irc"`
- `provenance.origin` MUST identify the IRC source using the event-class-specific form defined by this specification
- `provenance.external_identity` MUST be the IRC nick when the adapted event is attributable to a specific IRC actor
- `provenance.external_scope` MUST be `channel_membership` for derived channel presence state
- `body.irc_identity.account`, when present, MUST be a non-empty string naming the authenticated IRC account
- `body.irc_identity.user`, when present, MUST be a non-empty string
- `body.irc_identity.host`, when present, MUST be a non-empty string
- `body.mode`, when present, MUST be a non-empty string
- `body.mode_args`, when present, MUST be an array of strings
- `provenance.limitations` MUST be present

For channel messages and notices, `provenance.origin` MUST use the form:

```text
<network>/<channel>
```

Example:

```text
irc.libera.chat/#overnet
```

For direct messages and notices, `provenance.origin` MUST use the form:

```text
<network>/<nick>
```

For network-scoped nick changes, `provenance.origin` MUST use the form:

```text
<network>
```

For derived channel presence state, `provenance.origin` MUST use the form:

```text
<network>/<channel>
```

## 10. Required Limitation Disclosure

IRC-adapted messages, notices, topic updates, presence events, network identity-change events, observed mode-change events, and derived channel presence state defined by this specification MUST include:

- `unsigned`
- `no_edit_history`

IRC-adapted messages, notices, topic updates, presence events, network identity-change events, and observed mode-change events defined by this specification SHOULD include:

- `synthetic_identity`

An adapter MAY include additional IRC-specific limitation identifiers using the `irc.` namespace.

This specification defines the following IRC-specific limitation identifier:

| Identifier | Meaning |
|---|---|
| `irc.ephemeral_presence` | Presence or membership state may be partial, transient, or not represented through this adapter mapping |
| `irc.partial_membership` | A derived membership view does not claim complete or authoritative knowledge of all current members |

## 11. Authority and Moderation

In the baseline observational mapping defined by this specification, IRC operator, channel mode, and service authority are not automatically reinterpreted as native Overnet delegation or moderation authority.

Observed IRC moderation actions such as `KICK` and observed channel mode changes such as `MODE` MAY be represented as adapted events, but they MUST NOT be treated as native Overnet authority unless an implementation also claims support for the optional authoritative moderated-channel profile defined in section 11.1.

### 11.1 Optional `NIP-29`-Backed Authoritative Moderated-Channel Profile

This specification also defines an optional profile for implementations that are authoritative for a set of natively hosted IRC channels rather than merely observing an external IRC network.

This profile MUST reuse `NIP-29` group authority as the source of truth for membership, moderation, and channel-flag state. It MUST NOT define a separate generic Overnet-native channel-governance model for those channels.

This profile applies only to channels that the implementation itself hosts authoritatively. It does not apply to IRC channels that are merely adapted from an external IRC network.

### 11.2 Authenticated Actor Binding

For a channel using the profile in section 11.1, each registered IRC client connection participating in authoritative membership, moderation, or channel-mode changes MUST be bound to one authenticated Nostr pubkey.

For this profile:

- IRC nick values remain presentational identifiers for the IRC surface
- authoritative membership, roles, invitations, and moderation permissions are determined by the bound Nostr pubkey rather than by nick alone
- an implementation MUST NOT grant authoritative channel privilege based only on an IRC nick string or on RFC1459-style nick comparison

This section does not define one mandatory IRC-side authentication mechanism for establishing that pubkey binding. The required property is that the implementation can reliably associate each authoritative IRC client connection with one authenticated Nostr identity.

### 11.3 Channel-to-Group Binding

For each IRC channel using the profile in section 11.1, the implementation MUST maintain one stable binding between:

- the IRC-facing channel object identifier `irc:<network>:<channel>`
- one authoritative `NIP-29` group identifier

For this profile:

- the IRC channel object identifier remains the Overnet-side channel identifier used by this specification
- the bound `NIP-29` group identifier is the authoritative group-control identifier used by the underlying `NIP-29` events
- the bound `NIP-29` group identifier MAY equal the IRC channel name, but it is not required to do so
- all `NIP-29` events used as authoritative input for that channel MUST refer to the same bound group identifier

### 11.4 Authoritative Source and Derived State

For a channel using the profile in section 11.1, current channel membership, role assignment, and authoritative channel-mode state MUST be derived from the accepted authoritative `NIP-29` event stream rather than from observed IRC `MODE` or `KICK` lines.

At minimum, an implementation claiming this profile MUST be able to derive current authoritative state from the relevant accepted `NIP-29` control events and relay snapshots, including:

- `9000` put-user
- `9001` remove-user
- `9002` edit-metadata
- `9009` create-invite when invite-mediated admission is in use
- `9021` join-request when request-mediated admission is in use
- `9022` leave-request
- the latest relevant relay-signed `39000`, `39001`, `39002`, and `39003` events when they are available

For this profile:

- relay-signed `39001`, `39002`, and `39003` events are authoritative snapshots of current relay state, but they MUST NOT be interpreted as creating a separate non-`NIP-29` authority model
- if accepted control-event history and relay-signed snapshots disagree, the implementation MUST prefer the authoritative relay state it actually enforces; a stale or partial snapshot MUST NOT silently widen authority
- `39002` membership snapshots MAY be partial and therefore MUST NOT be treated as exhaustive unless the implementation explicitly knows they are exhaustive for that deployment
- the channel-mode mapping defined in section 11.5 MUST be derived from the current authoritative group metadata and role state, not from nick-local heuristics

### 11.5 Canonical IRC Role and Channel-Mode Mapping

To provide interoperable IRC behavior without defining a second generic moderation model, this profile reserves the following `NIP-29` role labels for IRC presentation:

- `irc.operator`
- `irc.voice`

For this profile:

- `irc.operator` maps to IRC channel privilege `+o` and presentational prefix `@`
- `irc.voice` maps to IRC channel privilege `+v` and presentational prefix `+`
- if a user has both roles, `@` takes precedence over `+` in IRC presentational contexts such as `353`
- `irc.operator` grants authority to issue `KICK`, to manage `+o`, `+v`, `+i`, `+m`, and `+t`, and to set the channel topic even when `+t` is active
- `irc.voice` grants authority to speak in a `+m` channel but does not by itself grant moderation authority

The following channel-flag mappings are defined by this profile:

- `NIP-29` group metadata flag `closed` maps to IRC channel mode `+i`
- a profile-defined `39000` metadata tag `["mode", "moderated"]` maps to IRC channel mode `+m`
- a profile-defined `39000` metadata tag `["mode", "topic-restricted"]` maps to IRC channel mode `+t`

For this profile:

- `+n` is treated as an implicit presentational mode for authoritative hosted channels; an implementation MAY include it in `MODE <channel>` replies, but this profile does not define a writable toggle for `+n`
- this profile does not define authoritative mappings for bans, ban exceptions, invite exceptions, keys, user limits, secret/private visibility, or other IRC channel modes beyond `+o`, `+v`, `+i`, `+m`, and `+t`

### 11.6 Authoritative Command Mapping and Enforcement

For a channel using the profile in section 11.1, the following IRC commands are defined authoritatively rather than observationally:

- `KICK <channel> <nick> [:reason]`
- `MODE <channel> +o <nick>`
- `MODE <channel> -o <nick>`
- `MODE <channel> +v <nick>`
- `MODE <channel> -v <nick>`
- `MODE <channel> +i`
- `MODE <channel> -i`
- `MODE <channel> +m`
- `MODE <channel> -m`
- `MODE <channel> +t`
- `MODE <channel> -t`

For this profile:

- an authoritative `KICK` MUST be accepted only from a client whose bound pubkey currently has role `irc.operator`
- an authoritative `KICK` MUST map to the corresponding `NIP-29` remove-user action for the targeted current member
- the target of `MODE +o`, `MODE -o`, `MODE +v`, and `MODE -v` MUST already be a current member of the authoritative channel
- `MODE +o` and `MODE -o` MUST add or remove role `irc.operator` for the targeted current member using the corresponding `NIP-29` user-update surface
- `MODE +v` and `MODE -v` MUST add or remove role `irc.voice` for the targeted current member using the corresponding `NIP-29` user-update surface
- `MODE +i` and `MODE -i` MUST add or remove the authoritative `NIP-29` `closed` metadata flag
- `MODE +m` and `MODE -m` MUST add or remove profile metadata tag `["mode", "moderated"]`
- `MODE +t` and `MODE -t` MUST add or remove profile metadata tag `["mode", "topic-restricted"]`
- unsupported writable mode letters MUST be rejected rather than silently ignored
- when a client lacks the required operator privilege for `KICK`, writable `MODE`, or a topic change blocked by `+t`, the implementation MUST return `482 ERR_CHANOPRIVSNEEDED`
- when a channel is currently `+m` and a client lacking both `irc.operator` and `irc.voice` attempts channel-targeted `PRIVMSG` or `NOTICE`, the implementation MUST reject that send with `404 ERR_CANNOTSENDTOCHAN`
- a `closed` / `+i` channel MUST NOT grant new authoritative membership through ordinary local IRC `JOIN` alone without an invite or other authorized `NIP-29` admission path

This profile does not yet require one exact IRC numeric or request/response sequence for pending join requests, invite-code workflows, or asynchronous moderation review.

### 11.7 Authoritative IRC Presentation Extensions

An implementation claiming support for the profile in section 11.1 MUST extend the minimal IRC presentation slice in section 13 as follows:

- `353` name-list output for an authoritative channel SHOULD prefix nicks with `@` or `+` according to the current authoritative role mapping defined in section 11.5
- `MODE <channel>` query replies for an authoritative channel SHOULD reflect the currently active derived channel flags from section 11.5 in a stable deterministic order
- a successful authoritative change to `+o`, `+v`, `+i`, `+m`, or `+t` MUST be rendered back to joined IRC clients as a corresponding IRC `MODE` line
- an authoritative membership removal caused by moderator action SHOULD be rendered back to joined IRC clients as IRC `KICK`
- an authoritative membership removal that is known to correspond to the target user's own accepted leave request SHOULD be rendered as `PART` rather than `KICK`
- when rendering an authoritative `MODE` or `KICK` line, the prefix nick SHOULD use the current presentational nick of the acting authenticated user when the implementation has one; otherwise the implementation MAY use the server name or another stable implementation-defined authoritative prefix

This profile does not require every authoritative moderation-state transition to be re-emitted as a generic Overnet core event. The authoritative source remains the `NIP-29` group state and its accepted control events.

## 12. Query and Subscription Expectations

An implementation MAY expose IRC-adapted channel messages through ordinary Overnet event query and subscription mechanisms.

This specification does not yet define mandatory backlog depth, replay semantics, or presence synchronization behavior.

If history is partial or live observation begins after the adapter connects, the adapter SHOULD disclose that fact through limitations or deployment-specific capability information rather than implying a complete archive.

## 13. Minimal Server-Side IRC Presentation

This section defines an optional minimal server-side IRC presentation slice for implementations that expose Overnet-backed channel data to IRC clients.

This section is intentionally narrow. It defines only the minimum behavior needed for a channel-oriented IRC presentation surface backed by Overnet data.

This section does not define:

- full IRC server conformance
- complete numeric reply behavior beyond baseline registration
- operator-service behavior beyond the minimal compatibility query behavior defined here
- write-back to an upstream IRC network
- multi-server federation

### 13.1 Registration Baseline

An implementation claiming support for this section MUST accept client registration through:

- `NICK <nick>`
- `USER <username> 0 * :<realname>`

The implementation MUST accept those commands in either order.

#### 13.1.1 Capability Negotiation Compatibility Baseline

Before registration completes, an implementation claiming support for this section MUST accept:

- `CAP LS`
- `CAP LS <version>`
- `CAP REQ :<capabilities>`
- `CAP END`

For the empty-capability baseline, the implementation advertises no optional IRC capabilities.

When the client sends `CAP LS` or `CAP LS <version>`, an implementation with no optional capabilities enabled MUST reply with:

- `:<server_name> CAP * LS :`

When the client sends `CAP REQ :<capabilities>`, an implementation with no matching optional capabilities enabled MUST reject the request with:

- `:<server_name> CAP * NAK :<capabilities>`

When the client sends `CAP END`, the implementation MAY emit no reply.

This section does not require support for `CAP LIST`, `CAP CLEAR`, or capability enablement.

An implementation MAY advertise additional optional capabilities beyond the empty baseline above when another section of this specification defines them.

#### 13.1.1.1 Optional `overnet-e2ee` Capability

An implementation claiming support for the endpoint-blind E2E IRC client profile defined by this specification MUST advertise IRC capability token:

- `overnet-e2ee`

When such an implementation receives:

- `CAP LS`
- `CAP LS <version>`

it MUST include `overnet-e2ee` in the advertised capability list.

When such an implementation receives:

- `CAP REQ :overnet-e2ee`

it MUST reply with:

- `:<server_name> CAP * ACK :overnet-e2ee`

If a `CAP REQ` request mixes `overnet-e2ee` with any unsupported capability token, the implementation MAY reject the entire request with:

- `:<server_name> CAP * NAK :<capabilities>`

#### 13.1.1.2 Optional `OVERNETKEY` Registration and Lookup

An implementation claiming support for the endpoint-blind E2E IRC client profile defined by this specification MUST accept the following registered-client commands after `overnet-e2ee` capability negotiation succeeds:

- `OVERNETKEY SET <pubkey>`
- `OVERNETKEY GET <nick>`

For this profile:

- `<pubkey>` MUST be a 64-character lowercase hex public key string used by the client for `NIP-17` private direct messaging
- `OVERNETKEY SET <pubkey>` associates that public key with the currently registered client nick
- `OVERNETKEY GET <nick>` returns the currently associated public key for that nick when available
- an implementation MAY return the `GET` result using a server `NOTICE` or another implementation-defined non-error reply form
- an implementation MAY allow later `OVERNETKEY SET` commands to rotate the associated public key for the current client

This section does not require persistent long-term key directories, trust-on-first-use policy, or global identity verification beyond the explicit per-client key advertisement described here.

#### 13.1.2 Baseline Command Validation and Error Numerics

An implementation claiming support for this section MUST emit at least the following IRC error numerics in the listed situations:

| Numeric | Name | Required situation |
|---|---|---|
| `421` | `ERR_UNKNOWNCOMMAND` | A command name is not recognized by this section's baseline server behavior. |
| `431` | `ERR_NONICKNAMEGIVEN` | A client sends `NICK` without a nickname parameter. |
| `451` | `ERR_NOTREGISTERED` | A client sends `JOIN`, `PART`, `PRIVMSG`, `NOTICE`, `TOPIC`, `NAMES`, `MODE`, `USERHOST`, `WHO`, `WHOIS`, `LUSERS`, `LIST`, or `OVERNETKEY` before registration completes. |
| `461` | `ERR_NEEDMOREPARAMS` | A client sends `USER`, `JOIN`, `PART`, `PRIVMSG`, `NOTICE`, `TOPIC`, `NAMES`, `MODE`, `USERHOST`, `WHO`, `WHOIS`, `OVERNETKEY`, or `CAP REQ` without the required parameter set for that command. |
| `401` | `ERR_NOSUCHNICK` | A client sends direct-message `PRIVMSG`, direct-message `NOTICE`, or `WHOIS` for a nick target that does not match any currently connected nick under the comparison rules in section 13.1.3. |
| `403` | `ERR_NOSUCHCHANNEL` | A command in this section requires a channel target but the supplied target is not syntactically a valid IRC channel name. |
| `442` | `ERR_NOTONCHANNEL` | A registered client sends channel `PART`, channel-targeted `PRIVMSG`, channel-targeted `NOTICE`, channel `TOPIC`, or channel `MODE` for a channel that the implementation does not currently treat as joined for that client under the comparison rules in section 13.1.3. |

For this baseline:

- `<server_name>` is the same server-presentable name used for numeric `001`
- the target parameter before the command-specific argument SHOULD be the client's current nick when available, or `*` before the client has a registered nick
- `401` uses the form `:<server_name> 401 <target> <nick> :No such nick/channel`
- `403` uses the form `:<server_name> 403 <target> <channel> :No such channel`
- `442` uses the form `:<server_name> 442 <target> <channel> :You're not on that channel`
- `461` uses the form `:<server_name> 461 <target> <command> :Not enough parameters`

An implementation claiming support for the authoritative moderated-channel profile in section 11.1 MUST additionally support:

- `404 ERR_CANNOTSENDTOCHAN` for the `+m` enforcement case defined in section 11.6
- `482 ERR_CHANOPRIVSNEEDED` for the privilege-denial cases defined in section 11.6

#### 13.1.3 RFC1459-Style Comparison Baseline

For this section, implementations MUST compare IRC nick and channel names using the following baseline RFC1459-style case-folding rules:

- ASCII `A-Z` compare equal to `a-z`
- `[` compares equal to `{`
- `]` compares equal to `}`
- `\` compares equal to `|`
- `^` compares equal to `~`

For this baseline:

- nick uniqueness MUST be enforced using that folded comparison
- a nick target used for direct-message delivery or direct-message validation MUST be matched using that folded comparison
- channel membership matching for `JOIN`, `PART`, channel-targeted `PRIVMSG`, channel-targeted `NOTICE`, `TOPIC`, and `NAMES` MUST be performed using that folded comparison
- an implementation MAY preserve a presentational nick spelling or channel spelling for rendered IRC lines, but it MUST NOT treat spellings that compare equal under this section as distinct current IRC identities or distinct current joined channels

For this section, a nick value is unique per current server instance.

An implementation claiming support for this section MUST NOT accept a `NICK` value that is already assigned to another currently connected client connection.

If an unregistered client sends `NICK <nick>` and `<nick>` is already in use, the implementation MUST reject it with:

- `:<server_name> 433 * <nick> :Nickname is already in use`

If a registered client sends `NICK <new_nick>` and `<new_nick>` is already in use, the implementation MUST reject it with:

- `:<server_name> 433 <current_nick> <new_nick> :Nickname is already in use`

For this baseline:

- `<server_name>` is the same server-presentable name used for registration numerics such as `001`
- a failed `433` collision response MUST leave the client's current nick unchanged
- a successful nick change MUST release the client's previous nick for reuse by later clients
- a client disconnect MUST release that client's current nick for reuse by later clients

Once both commands have been accepted for a client connection, the implementation MUST treat that client as registered and MUST emit at least numeric `001` as a welcome reply.

#### 13.1.4 Registration Reply Prelude Compatibility

After registration completes, an implementation claiming support for this section MUST emit at least the following numeric reply prelude in this order:

- `:<server_name> 001 <nick> :Welcome to Overnet IRC`
- `:<server_name> 005 <nick> CASEMAPPING=rfc1459 CHANTYPES=#& NETWORK=<network> :are supported by this server`
- `:<server_name> 422 <nick> :MOTD File is missing`

For this baseline:

- `<server_name>` is the same server-presentable name used elsewhere in this section
- `<nick>` is the client's current registered nick
- `<network>` is the current IRC network identifier presented by the implementation
- this section standardizes only the listed `005` tokens; implementations MAY advertise additional compatible tokens
- this baseline uses `422 ERR_NOMOTD` rather than requiring a full `375` / `372` / `376` MOTD sequence

#### 13.1.5 Minimal Channel MODE Query Compatibility

After registration completes, an implementation claiming support for this section MUST accept the following read-only `MODE` queries:

- `MODE <nick>`
- `MODE <channel>`

For this baseline:

- when the client sends `MODE <nick>`, `<nick>` MUST match the client's current nick under the comparison rules in section 13.1.3
- for a self `MODE <nick>` query, the implementation MUST reply with:
  - `:<server_name> 221 <nick> +`
- `<channel>` MUST be treated as a channel target using the comparison rules in section 13.1.3
- the client MUST already be joined to that channel under the comparison rules in section 13.1.3
- for a joined-channel `MODE <channel>` query, the implementation MUST reply with:
  - `:<server_name> 324 <nick> <channel> +n`
- `<channel>` in that reply SHOULD use the implementation's current presentational channel spelling for the joined channel

This baseline does not require support for:

- any channel mode change command carrying mode arguments
- any additional mode numerics such as topic-lock or creation-time reporting

The authoritative moderated-channel profile in section 11.1 extends this baseline with the writable `MODE` surface defined in section 11.6.

#### 13.1.6 Minimal USERHOST, WHO, and WHOIS Query Compatibility

After registration completes, an implementation claiming support for this section MUST accept:

- `USERHOST <nick> [<nick> ...]`
- `WHO <channel>`
- `WHOIS <nick>`

For this baseline:

- `USERHOST` nick matching MUST use the comparison rules in section 13.1.3
- for each nick in the request that matches a currently connected nick, the implementation MUST include one reply fragment of the form:
  - `<display_nick>=+<username>@<host>`
- the implementation MUST reply to `USERHOST` with:
  - `:<server_name> 302 <requesting_nick> :<fragment> [<fragment> ...]`
- if none of the requested nicks match a currently connected nick, the implementation MAY reply with an empty `302` trailing parameter
- `WHO <channel>` channel matching MUST use the comparison rules in section 13.1.3
- the client MUST already be joined to that channel under the comparison rules in section 13.1.3
- for each currently visible nick on the channel, the implementation MUST emit one `352` reply of the form:
  - `:<server_name> 352 <requesting_nick> <channel> <username> <host> <server_name> <display_nick> H :0 <realname>`
- after the `352` replies, the implementation MUST emit:
  - `:<server_name> 315 <requesting_nick> <channel> :End of /WHO list.`
- `<channel>` in `352` and `315` SHOULD use the implementation's current presentational channel spelling for the joined channel
- when the implementation does not have authoritative IRC-side values for `<username>`, `<host>`, or `<realname>`, it MAY use stable implementation-defined presentational placeholder values
- `WHOIS` nick matching MUST use the comparison rules in section 13.1.3
- for a `WHOIS <nick>` query whose nick matches a currently connected nick, the implementation MUST emit:
  - `:<server_name> 311 <requesting_nick> <display_nick> <username> <host> * :<realname>`
  - `:<server_name> 312 <requesting_nick> <display_nick> <server_name> :<server_description>`
  - `:<server_name> 318 <requesting_nick> <display_nick> :End of /WHOIS list.`
- `<display_nick>` in those replies SHOULD use the implementation's current presentational nick spelling for the matched nick
- when the implementation does not have authoritative IRC-side values for `<username>`, `<host>`, or `<realname>`, it MAY use stable implementation-defined presentational placeholder values for `WHOIS` in the same way as for `WHO`
- `<server_description>` MAY be a stable implementation-defined presentational description string

This baseline does not require support for:

- `WHO` against non-channel masks
- `WHOX`
- multi-target `WHOIS`
- away-state reporting
- hopcount semantics beyond the literal `0` used in this section
- additional `WHOIS` numerics such as channel membership, idle time, account status, secure transport, or operator state

#### 13.1.7 Minimal LUSERS Compatibility

After registration completes, an implementation claiming support for this section MUST accept:

- `LUSERS`

For this baseline, the implementation MUST emit at least the following numeric replies:

- `:<server_name> 251 <nick> :There are <users> users and 0 services on 1 server`
- `:<server_name> 252 <nick> 0 :operator(s) online`
- `:<server_name> 253 <nick> 0 :unknown connection(s)`
- `:<server_name> 254 <nick> <channels> :channels formed`
- `:<server_name> 255 <nick> :I have <clients> clients and 1 server`

For this baseline:

- `<users>` is the number of currently registered IRC clients
- `<clients>` is the number of currently connected IRC clients
- `<channels>` is the number of channels the implementation currently exposes in its server-side presentation state
- this section does not require support for additional LUSERS numerics such as `265` or `266`

#### 13.1.8 Minimal TOPIC Query Compatibility

After registration completes, an implementation claiming support for this section MUST accept:

- `TOPIC <channel>`

For this baseline:

- `<channel>` MUST be treated as a channel target using the comparison rules in section 13.1.3
- the client MUST already be joined to that channel under the comparison rules in section 13.1.3
- if the implementation has a current `chat.topic` state available for that channel, it MUST reply with:
  - `:<server_name> 332 <nick> <channel> :<topic>`
- if the implementation does not have a current topic for that channel, it MUST reply with:
  - `:<server_name> 331 <nick> <channel> :No topic is set`
- `<channel>` in those replies SHOULD use the implementation's current presentational channel spelling for the joined channel

This baseline does not require support for:

- topic-setter metadata numerics such as `333`

#### 13.1.9 Minimal LIST Compatibility

After registration completes, an implementation claiming support for this section MUST accept:

- `LIST`
- `LIST <target>`

For this baseline:

- the implementation MUST emit:
  - `:<server_name> 321 <nick> Channel :Users Name`
- for each currently exposed channel in the server-side IRC presentation state that matches the request, the implementation MUST emit:
  - `:<server_name> 322 <nick> <channel> <visible_users> :<topic>`
- after the `322` replies, the implementation MUST emit:
  - `:<server_name> 323 <nick> :End of /LIST`
- `<visible_users>` is the number of currently visible nicks that the implementation currently presents for that channel
- `<topic>` MAY be empty when the implementation does not have a current topic for that channel
- when `LIST <target>` is used and `<target>` is syntactically a channel name, matching MUST use the comparison rules in section 13.1.3
- when `LIST <target>` is used with a non-channel target or implementation-defined filter syntax, the implementation MAY ignore the filter and behave like bare `LIST`
- `<channel>` in `322` SHOULD use the implementation's current presentational channel spelling

This baseline does not require support for:

- channel masks or numeric filters beyond the optional behavior above
- secret/private channel visibility rules
- channel creation time or topic-setter metadata

### 13.2 Channel Association and Join Bootstrap Baseline

After registration, an implementation claiming support for this section MUST accept:

- `JOIN <channel>`
- `NAMES <channel>`

For the configured IRC network view served by the implementation, the channel name `<channel>` MUST map to Overnet object identifier:

```text
irc:<network>:<channel>
```

using the same object identifier rules defined elsewhere in this specification.

If a registered client joins a channel name that the implementation chooses to expose, the implementation MUST treat that client connection as subscribed to the corresponding `chat.channel` object for the purpose of server-side presentation.

After a successful channel join, an implementation claiming support for this section MUST emit at least the following bootstrap lines to the joining client:

- `:<nick> JOIN <channel>`
- one or more `:<server_name> 353 <nick> = <channel> :<space-separated nicks>` lines
- one terminating `:<server_name> 366 <nick> <channel> :End of /NAMES list.` line

For this baseline:

- `<nick>` is the joining client's current IRC nick
- `<server_name>` is the same server-presentable name used for registration numerics such as `001`
- the `353` nick list MUST include at least the nicks of the client connections that the implementation currently treats as joined to that channel for presentation purposes
- the `353` nick list MUST include the joining client's current nick

For a channel using the authoritative moderated-channel profile in section 11.1, the `353` nick list SHOULD additionally apply the prefix rules defined in section 11.7.

If the implementation has a current `chat.topic` state available for that channel at join time, it MUST replay that topic to the joining client using the `chat.topic` render form defined in section 13.3 before the terminating `366` line.

When a registered client sends `NAMES <channel>` for a valid IRC channel name, the implementation MUST emit one or more `353` lines followed by one terminating `366` line using the same minimal name-list rules defined above.

### 13.3 Outbound Presentation Baseline

For a registered client, an implementation claiming support for this section MUST render the following Overnet data to IRC lines when the corresponding audience conditions in this section are satisfied:

| Overnet semantic item | IRC line form |
|---|---|
| `chat.message` event | `:<nick> PRIVMSG <channel> :<text>` |
| `chat.notice` event | `:<nick> NOTICE <channel> :<text>` |
| `chat.dm_message` event | `:<nick> PRIVMSG <target_nick> :<text>` |
| `chat.dm_notice` event | `:<nick> NOTICE <target_nick> :<text>` |
| `chat.topic` state | `:<nick> TOPIC <channel> :<topic>` |
| `chat.join` event | `:<nick> JOIN <channel>` |
| `chat.part` event | `:<nick> PART <channel>` or `:<nick> PART <channel> :<reason>` |
| `chat.quit` event | `:<nick> QUIT` or `:<nick> QUIT :<reason>` |
| `irc.nick` event | `:<old_nick> NICK :<new_nick>` |

For this baseline:

- `<channel>` MUST be the exact IRC channel name derived from the `irc:<network>:<channel>` object identifier
- `<target_nick>` MUST be the exact IRC nick suffix derived from the `irc:<network>:dm:<target_nick>` object identifier
- `chat.message` rendering uses `body.text`
- `chat.notice` rendering uses `body.text`
- `chat.dm_message` rendering uses `body.text`
- `chat.dm_notice` rendering uses `body.text`
- `chat.topic` rendering uses `body.topic`
- `chat.part` rendering uses `body.reason` as the trailing parameter when it is present and non-empty
- `chat.quit` rendering uses `body.reason` as the trailing parameter when it is present and non-empty
- `irc.nick` rendering uses `body.old_nick` as the prefix nick and `body.new_nick` as the new nick parameter
- for `chat.message`, `chat.notice`, `chat.topic`, `chat.join`, `chat.part`, and `chat.quit`, the implementation MUST emit those lines only to client connections currently joined to that channel
- for `chat.dm_message` and `chat.dm_notice`, the implementation MUST emit those lines only to client connections whose current registered nick exactly equals `<target_nick>`
- for `irc.nick`, the implementation MUST emit the line only to client connections that currently share at least one joined channel with the nick change according to the implementation's current presentation membership view

The authoritative moderated-channel profile in section 11.1 adds the `MODE`, `KICK`, and prefixed-`353` presentation rules defined in section 11.7.

#### 13.3.1 Optional Endpoint-Blind E2E DM Presentation

An implementation claiming support for the endpoint-blind E2E IRC client profile defined by this specification MAY render a relay-carried private direct message without decrypting it.

For this profile:

- the runtime-visible private-message item MUST use the opaque endpoint-blind form defined by the [Overnet Private Messaging Specification](../private-messaging.md)
- the rendered IRC line MUST use the same `PRIVMSG` or `NOTICE` command that corresponds to `private_type`
- the trailing parameter MUST use the form:
  - `+overnet-e2ee-v1 <base64_json_transport>`
- `<base64_json_transport>` MUST decode to the visible wrapped transport event object only
- the sender nick used in the IRC prefix MUST come from cleartext presentational metadata such as `sender_identity`, not from decrypted message content
- the implementation MUST NOT decrypt the message body in order to produce that IRC line

This profile is intended for E2E-aware IRC clients or local proxies that decrypt the wrapped event after receipt.

### 13.4 Sender Presentation Baseline

When rendering `chat.message`, `chat.notice`, `chat.dm_message`, `chat.dm_notice`, `chat.topic`, `chat.join`, `chat.part`, or `chat.quit` through this section, the implementation MUST derive an IRC-presentable nick string for `<nick>`.

If `content.provenance.external_identity` is present and is a non-empty string, the implementation MUST use that value as the rendered IRC nick.

If `content.provenance.external_identity` is not available, this version does not define a canonical nick-synthesis rule. In that case, the implementation MAY:

- suppress the render for that item, or
- use a deployment-defined presentational nick

If the implementation uses a deployment-defined presentational nick, it MUST NOT imply authenticated IRC authority, stable global identity, or native IRC authorship that the Overnet data does not actually establish.

When rendering `irc.nick`, the implementation MUST use `body.old_nick` and `body.new_nick` as the authoritative IRC nick values.

If `content.provenance.external_identity` is present on an `irc.nick` event, it MUST equal `body.old_nick`.

### 13.5 Relationship to Existing Inbound Mapping

This section defines only the minimal server-side presentation of Overnet data to IRC clients.

Inbound IRC client commands such as `PRIVMSG`, `NOTICE`, `TOPIC`, and `JOIN` continue to use the IRC-to-Overnet mapping rules defined earlier in this specification when the implementation chooses to expose that behavior.

For a channel using the authoritative moderated-channel profile in section 11.1, inbound `KICK` and the writable `MODE` commands defined in section 11.6 MUST use the authoritative `NIP-29` mappings from section 11.6 rather than the observational adapted-event mapping defined earlier in this specification.

For this baseline:

- an inbound channel-targeted `PRIVMSG` or `NOTICE` continues to map to the corresponding `chat.channel` object
- an inbound non-channel `PRIVMSG` or `NOTICE` MUST map to the corresponding directional `chat.dm` object
- for an inbound non-channel `PRIVMSG <target_nick> :<text>`, the mapped `overnet_oid` MUST be `irc:<network>:dm:<target_nick>`
- for an inbound non-channel `NOTICE <target_nick> :<text>`, the mapped `overnet_oid` MUST be `irc:<network>:dm:<target_nick>`
- when the target nick matches a currently connected client nick only under the comparison rules in section 13.1.3, the implementation SHOULD use that client's current presentational nick spelling as the mapped direct-message target

If the implementation carries that direct-message item across relays as a private message, it SHOULD apply the [Overnet Private Messaging Specification](../private-messaging.md) rather than publishing the plaintext direct-message body as an ordinary public Overnet core event.

#### 13.5.1 Optional Endpoint-Blind E2E Inbound DM Profile

An implementation claiming support for the endpoint-blind E2E IRC client profile defined by this specification MUST additionally recognize the following IRC direct-message body form:

- `+overnet-e2ee-v1 <base64_json_transport>`

For this profile:

- the command MUST be an inbound non-channel `PRIVMSG` or `NOTICE`
- the sending client and target client MUST both have successfully negotiated `overnet-e2ee`
- the sending client and target client MUST both have an active `OVERNETKEY` association
- `<base64_json_transport>` MUST decode to the visible kind `1059` wrapped transport event object
- the implementation MUST derive `private_type` from the IRC command rather than from decrypted message content
- the implementation MUST derive `object_id` from the IRC target nick using `irc:<network>:dm:<target_nick>`
- the implementation MUST validate the visible wrapped transport against the target client's advertised key and against the sending client's negotiated E2E session state
- the implementation MUST emit the resulting relay-carried private message using the opaque endpoint-blind candidate form defined by the [Overnet Private Messaging Specification](../private-messaging.md)
- the implementation MUST NOT decrypt the wrapped message body in order to accept, route, or relay it

If any of those conditions are not met, the implementation MUST reject or suppress the E2E delivery attempt using an implementation-defined error or notice path rather than silently treating the ciphertext body as ordinary plaintext chat content.

## 14. Conformance Requirements

An implementation claiming conformance with this IRC adapter specification MUST, at minimum:

- map IRC channel `PRIVMSG` to `chat.message` events on `chat.channel` objects
- map IRC channel `NOTICE` to `chat.notice` events on `chat.channel` objects
- map channel `TOPIC` to `chat.topic` state events on `chat.channel` objects
- map direct-message `PRIVMSG` to `chat.dm_message` events on `chat.dm` objects
- map direct-message `NOTICE` to `chat.dm_notice` events on `chat.dm` objects
- map channel `JOIN` to `chat.join` events on `chat.channel` objects
- map channel `PART` to `chat.part` events on `chat.channel` objects
- map channel-context `QUIT` to `chat.quit` events on `chat.channel` objects
- map channel `KICK` to `chat.kick` events on `chat.channel` objects
- map network `NICK` to `irc.nick` events on `irc.network` objects
- map channel `MODE` to `irc.mode` events on `chat.channel` objects
- use object identifiers in the `irc:<network>:<channel>` and `irc:<network>:dm:<nick>` forms
- emit adapted provenance with protocol `irc`
- include the required limitation identifiers defined by this specification
- preserve the distinction between adapter identity and IRC sender identity

An implementation MAY additionally claim support for the optional derived channel presence state defined in section 8.12.

An implementation MAY additionally claim support for the optional minimal server-side IRC presentation slice defined in section 13.

An implementation MAY additionally claim support for the optional `NIP-29`-backed authoritative moderated-channel profile defined in section 11.1.

An implementation claiming that support MUST, at minimum:

- bind each authoritative IRC channel to one stable `NIP-29` group identifier as defined in section 11.3
- bind each authoritative participating IRC client connection to one authenticated Nostr pubkey as defined in section 11.2
- derive authoritative membership, roles, and channel-mode state from the authoritative `NIP-29` group state rather than from nick-local heuristics
- support reserved role labels `irc.operator` and `irc.voice` with the semantics defined in section 11.5
- map authoritative metadata flag `closed` to IRC channel mode `+i`
- support profile metadata tags `["mode", "moderated"]` and `["mode", "topic-restricted"]` for IRC channel modes `+m` and `+t`
- accept authoritative `KICK`
- accept authoritative writable `MODE` for `+o`, `-o`, `+v`, `-v`, `+i`, `-i`, `+m`, `-m`, `+t`, and `-t`
- enforce `+m` against senders lacking both `irc.operator` and `irc.voice`
- enforce `+t` against topic changes from senders lacking `irc.operator`
- emit `404` and `482` in the situations defined in section 11.6
- render authoritative `MODE` and `KICK` changes back out through the IRC presentation surface according to section 11.7

An implementation MAY additionally claim support for relay-carried private direct messaging through the [Overnet Private Messaging Specification](../private-messaging.md).

An implementation claiming that support MUST apply the binding rules defined in section 8.4.1.

An implementation MAY additionally claim support for the optional endpoint-blind E2E IRC client profile defined in sections 13.1.1.1, 13.1.1.2, 13.3.1, and 13.5.1.

An implementation claiming that support MUST, at minimum:

- advertise IRC capability token `overnet-e2ee`
- acknowledge `CAP REQ :overnet-e2ee`
- accept `OVERNETKEY SET <pubkey>`
- accept `OVERNETKEY GET <nick>`
- associate one current `NIP-17` recipient pubkey with each E2E-capable registered client connection
- accept inbound non-channel `PRIVMSG` and `NOTICE` bodies in the `+overnet-e2ee-v1 <base64_json_transport>` form
- validate the visible wrapped transport against the target client's advertised key and the sending client's negotiated E2E session state
- emit relay-carried private direct messages using the opaque endpoint-blind private-message candidate form rather than decrypting them
- render opaque relay-carried private direct messages back to E2E-aware IRC clients using the same `+overnet-e2ee-v1 <base64_json_transport>` trailing parameter form
- avoid decrypting the wrapped message body merely to route or present that message through the IRC server surface

An implementation claiming support for that optional server-side slice MUST, at minimum:

- accept `NICK` and `USER` registration and emit at least numeric `001`
- accept `CAP LS`, `CAP REQ`, and `CAP END` before registration and emit the baseline `CAP` replies defined in section 13.1.1
- enforce unique current nick values per currently connected client connection
- emit `433` `ERR_NICKNAMEINUSE` for initial or post-registration nick collisions
- emit baseline validation numerics `421`, `431`, `451`, `461`, `401`, `403`, and `442` in the situations defined in section 13.1.2
- compare nick and channel names using the baseline RFC1459-style case-folding rules defined in section 13.1.3
- map `JOIN <channel>` into the corresponding `irc:<network>:<channel>` object scope for client presentation
- accept `NAMES <channel>` and emit the minimal `353`/`366` sequence
- emit channel join bootstrap consisting of `JOIN`, `353`, and `366`
- replay a known current `chat.topic` state to the joining client before completing the minimal join bootstrap
- render `chat.message` events as channel `PRIVMSG`
- render `chat.notice` events as channel `NOTICE`
- render `chat.dm_message` events as direct-message `PRIVMSG`
- render `chat.dm_notice` events as direct-message `NOTICE`
- render `chat.topic` state as channel `TOPIC`
- render `chat.join` events as channel `JOIN`
- render `chat.part` events as channel `PART`
- render `chat.quit` events as `QUIT`
- render `irc.nick` events as `NICK`
- use `provenance.external_identity` as the rendered nick when it is available
- use `body.old_nick` and `body.new_nick` when rendering `irc.nick`

## 15. Open Issues

The following IRC adapter topics remain open:

- account-aware identity mapping beyond nicknames
- the exact IRC-side authentication and session-binding mechanism used to associate an authoritative IRC client connection with one authenticated Nostr pubkey
- IRCv3-specific enhancements such as message tags, server-time, and account-aware identity refinement
- broader network-specific case-mapping negotiation beyond the baseline RFC1459-style comparison defined in section 13.1.3
- additional user-scoped mode mapping beyond `+o` and `+v`
- additional authoritative channel-mode mapping beyond `+i`, `+m`, and `+t`
- join-request, invite-code, and invite-list UX and numerics for `NIP-29`-backed authoritative channels
- presentation and visibility mapping for `NIP-29` `private`, `hidden`, and `restricted` semantics
- ban lists, exception lists, keyed channels, user limits, and other richer IRC channel-control surfaces
- richer server numerics, listing, and channel-bootstrap semantics beyond the minimal `JOIN`/topic/`NAMES` bootstrap defined here
- richer direct-message session semantics beyond target-directed `PRIVMSG` and `NOTICE` presentation
- interaction between relay-carried encrypted direct-message transport and richer IRC direct-message session semantics
- write-back and bidirectional synchronization semantics beyond the minimal server-side presentation slice
