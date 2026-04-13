# Overnet Specification Status

## Current State

The Overnet specification family is in active draft development.

At the current checkpoint, the project has:

- a materially specified core event model
- a shared core fixture corpus
- a working core validator/reference implementation in the sibling `overnet-code` repository
- a first companion adapter specification for IRC
- a first draft companion specification for the Overnet Program Runtime
- a first draft companion specification for the Overnet Program Protocol
- a first draft companion specification for Overnet Program Services
- a working IRC adapter implementation in the sibling `overnet-adapter-irc` repository

At this checkpoint, the specification also distinguishes between:

- adapter specifications, which define source-system mapping semantics
- Overnet programs, which are runnable implementations of the core and any companion specifications they support

This is still pre-stable work. The documents are useful for implementation and review, but they should not yet be treated as frozen interoperability standards.

## What Is Relatively Solid

The following areas are now comparatively mature for this stage:

- core event envelope structure
- provenance requirements for native and adapted data
- required object tags and duplicate-tag handling
- state-event requirements for kind `37800`
- removal semantics
- baseline delegation semantics for removal
- general adapter fidelity principles
- first-pass IRC mapping semantics for observed IRC events
- first-pass Overnet Program Runtime architecture
- first-pass Overnet Program Protocol framing and envelope rules
- first-pass Overnet Program service method definitions

These areas may still change, but they are now backed by fixtures and implementation pressure rather than only abstract design.

## What Exists Today

### Core

The core currently defines and/or constrains:

- event kinds `7800`, `37800`, and `7801`
- required Overnet tags
- JSON `content` envelope with `provenance` and `body`
- native versus adapted provenance
- removal structure and baseline authorization
- narrow delegation semantics for delegated removal

### IRC Adapter

The IRC adapter specification currently covers:

- channel `PRIVMSG`
- channel `NOTICE`
- direct-message `PRIVMSG`
- direct-message `NOTICE`
- channel `TOPIC`
- channel `JOIN`
- channel `PART`
- channel-context `QUIT`
- channel `KICK`
- network-scoped `NICK`
- channel `MODE` as an observed raw mode-change event
- optional identity enrichment fields

The IRC adapter is deliberately preserving observed IRC semantics rather than defining derived state or native Overnet moderation semantics.

The project now has initial draft runtime, protocol, and services specifications for Overnet programs, but they should still be treated as early design work rather than stable execution standards.

## What Is Not Stable Yet

The following areas should still be treated as open design territory:

- broader application profile semantics
- additional adapter families
- storage/replication profiles
- richer authority and moderation models
- derived state from adapted event streams
- mature and implementation-tested service-level semantics for Overnet program APIs
- relay/query capability details beyond the current baseline
- user-scoped IRC mode mapping
- derived IRC channel privilege or membership state
- IRC write-back and synchronization behavior

## Near-Term Direction

The most likely near-term work is one or more of:

- stabilizing docs and repo boundaries across the current three repositories
- deciding whether IRC should remain observation-focused or start deriving richer state
- extending Overnet core only where the adapter and implementation work expose real gaps
- choosing the next major proof-point after IRC

## Interpretation Guidance

When the core and a companion adapter spec interact, use this priority:

1. the Overnet core remains authoritative for shared protocol rules
2. the adapter specification is authoritative for source-system-specific mapping rules
3. the fixtures define the concrete conformance target under the current draft

If an implementation and a companion specification disagree, the implementation should be corrected rather than silently becoming the de facto specification.
