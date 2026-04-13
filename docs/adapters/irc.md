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
- provenance and limitation requirements for adapted IRC data
- baseline object identifiers for IRC network and channel objects

This version does not yet define:

- user-scoped mode mapping
- derived channel mode state or channel privilege state
- IRC operator or service authority semantics
- write-back from Overnet into IRC

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

## 13. Conformance Requirements

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

## 14. Open Issues

The following IRC adapter topics remain open:

- account-aware identity mapping beyond nicknames
- IRCv3-specific enhancements such as message tags, server-time, and account-aware identity refinement
- canonical case-folding rules for IRC network and channel identifiers
- user-scoped mode mapping
- derived channel mode state or privilege state
- representation of moderation and operator authority
- write-back and bidirectional synchronization semantics
