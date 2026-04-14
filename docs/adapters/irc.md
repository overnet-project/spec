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

This version of the IRC adapter specification does not define IRC operator, channel mode, or service authority as Overnet delegation or moderation authority.

Observed IRC moderation actions such as `KICK` and observed channel mode changes such as `MODE` MAY be represented as adapted events, but they MUST NOT be treated as native Overnet authority unless a later revision defines explicit mapping rules.

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
- `WHO`, `LIST`, mode changes, or operator-service behavior beyond the minimal compatibility query behavior defined here
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

For this baseline, the implementation advertises no optional IRC capabilities.

When the client sends `CAP LS` or `CAP LS <version>`, the implementation MUST reply with:

- `:<server_name> CAP * LS :`

When the client sends `CAP REQ :<capabilities>`, the implementation MUST reject the request with:

- `:<server_name> CAP * NAK :<capabilities>`

When the client sends `CAP END`, the implementation MAY emit no reply.

This section does not require support for `CAP LIST`, `CAP CLEAR`, or capability enablement.

#### 13.1.2 Baseline Command Validation and Error Numerics

An implementation claiming support for this section MUST emit at least the following IRC error numerics in the listed situations:

| Numeric | Name | Required situation |
|---|---|---|
| `421` | `ERR_UNKNOWNCOMMAND` | A command name is not recognized by this section's baseline server behavior. |
| `431` | `ERR_NONICKNAMEGIVEN` | A client sends `NICK` without a nickname parameter. |
| `451` | `ERR_NOTREGISTERED` | A client sends `JOIN`, `PART`, `PRIVMSG`, `NOTICE`, `TOPIC`, `NAMES`, or `MODE` before registration completes. |
| `461` | `ERR_NEEDMOREPARAMS` | A client sends `USER`, `JOIN`, `PART`, `PRIVMSG`, `NOTICE`, `TOPIC`, `NAMES`, `MODE`, or `CAP REQ` without the required parameter set for that command. |
| `401` | `ERR_NOSUCHNICK` | A client sends direct-message `PRIVMSG` or `NOTICE` to a nick target that does not match any currently connected nick under the comparison rules in section 13.1.3. |
| `403` | `ERR_NOSUCHCHANNEL` | A command in this section requires a channel target but the supplied target is not syntactically a valid IRC channel name. |
| `442` | `ERR_NOTONCHANNEL` | A registered client sends channel `PART`, channel-targeted `PRIVMSG`, channel-targeted `NOTICE`, channel `TOPIC`, or channel `MODE` for a channel that the implementation does not currently treat as joined for that client under the comparison rules in section 13.1.3. |

For this baseline:

- `<server_name>` is the same server-presentable name used for numeric `001`
- the target parameter before the command-specific argument SHOULD be the client's current nick when available, or `*` before the client has a registered nick
- `401` uses the form `:<server_name> 401 <target> <nick> :No such nick/channel`
- `403` uses the form `:<server_name> 403 <target> <channel> :No such channel`
- `442` uses the form `:<server_name> 442 <target> <channel> :You're not on that channel`
- `461` uses the form `:<server_name> 461 <target> <command> :Not enough parameters`

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

#### 13.1.4 Minimal Channel MODE Query Compatibility

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

For this baseline:

- an inbound channel-targeted `PRIVMSG` or `NOTICE` continues to map to the corresponding `chat.channel` object
- an inbound non-channel `PRIVMSG` or `NOTICE` MUST map to the corresponding directional `chat.dm` object
- for an inbound non-channel `PRIVMSG <target_nick> :<text>`, the mapped `overnet_oid` MUST be `irc:<network>:dm:<target_nick>`
- for an inbound non-channel `NOTICE <target_nick> :<text>`, the mapped `overnet_oid` MUST be `irc:<network>:dm:<target_nick>`
- when the target nick matches a currently connected client nick only under the comparison rules in section 13.1.3, the implementation SHOULD use that client's current presentational nick spelling as the mapped direct-message target

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
- IRCv3-specific enhancements such as message tags, server-time, and account-aware identity refinement
- broader network-specific case-mapping negotiation beyond the baseline RFC1459-style comparison defined in section 13.1.3
- user-scoped mode mapping
- derived channel mode state or privilege state
- representation of moderation and operator authority
- richer server numerics, listing, and channel-bootstrap semantics beyond the minimal `JOIN`/topic/`NAMES` bootstrap defined here
- richer direct-message session semantics beyond target-directed `PRIVMSG` and `NOTICE` presentation
- write-back and bidirectional synchronization semantics beyond the minimal server-side presentation slice
