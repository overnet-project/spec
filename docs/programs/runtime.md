# Overnet Program Runtime Specification

## Status of This Document

This document defines the Overnet Program Runtime as a companion specification to the Overnet core.

It is a working draft.

Unless stated otherwise, the main body of this document is normative.

## 1. Purpose

This specification defines a language-agnostic runtime contract for runnable Overnet programs.

The Overnet core defines protocol semantics, data validity rules, and shared architecture. This document defines how a runnable Overnet program interacts with a host runtime so that programs may be implemented in any programming language without requiring in-process APIs or language-specific extension mechanisms.

This specification is intended to support programs such as:

- adapter-backed integration services
- native Overnet application components
- transformers and derivation services
- automation or maintenance services
- indexing, synchronization, or archival components

## 2. Relationship to the Overnet Core

This specification is a companion specification to the Overnet core.

The Overnet core remains authoritative for:

- validity of Overnet data
- event, state, provenance, and capability semantics
- security and conformance requirements on Overnet content

This specification is authoritative for:

- the program/runtime boundary
- program lifecycle
- runtime-managed services exposed to programs
- program permissions and capability declarations
- the responsibilities of a host runtime supervising Overnet programs

Nothing in this specification allows a program to bypass core validation or reinterpret core semantics.

## 3. Design Goals

The Overnet Program Runtime MUST be:

- language-agnostic
- suitable for local supervised execution
- compatible with multiple concurrent program instances
- rich enough to support serious long-running programs
- strict about validation and runtime authority boundaries
- portable across operating systems, including Windows

This specification is designed so that:

- a program may be written in any language
- the runtime remains authoritative for validation and policy enforcement
- programs may rely on standardized runtime services instead of implementation-local glue

## 4. Architectural Model

### 4.1 Runtime and Program

An Overnet program is a runnable process supervised by an Overnet Program Runtime.

The runtime is responsible for:

- launching and supervising program instances
- delivering configuration and permissions
- validating Overnet data emitted by programs
- exposing runtime-managed services
- enforcing runtime policy and access control

The program is responsible for:

- carrying out its application or integration logic
- requesting runtime services through the runtime protocol
- handling its own outbound networking unless a later specification defines otherwise
- emitting candidate Overnet data through the runtime protocol

### 4.2 Multiple Instances

Multiple instances of the same Overnet program are a first-class concept.

Each instance MUST be treated as a separately configured and separately supervised runtime participant, even when multiple instances share the same executable artifact.

### 4.3 Validation Boundary

Programs may emit candidate Overnet events, state, and capability advertisements.

The runtime MUST validate emitted Overnet data against the Overnet core and any applicable companion specifications before accepting, storing, forwarding, or exposing that data as valid runtime output.

Programs MUST NOT be treated as authoritative validators of their own emitted Overnet data.

## 5. Transport and Session Model

### 5.1 Baseline Transport

The required baseline transport between a runtime and a program is framed JSON messaging over the program's standard input and standard output streams.

This specification does not require Unix-specific process semantics. Implementations MUST define transport behavior in a manner compatible with Windows and other non-Unix environments.

### 5.2 Framing

The baseline transport MUST use explicit message framing with a length prefix.

The exact wire framing and message-envelope rules are defined by the Overnet Program Protocol companion specification.

### 5.3 Session

A program/runtime connection is a runtime session for one specific program instance.

Each session MUST have:

- one supervising runtime
- one program instance
- one configuration context
- one permission context

## 6. Runtime Protocol Model

### 6.1 Message Style

The runtime protocol MUST support:

- request/response exchanges
- asynchronous notifications

This is required so that:

- either side may request actions and receive explicit success or failure
- either side may emit status, lifecycle, or event-driven notifications without waiting for a paired request

### 6.2 Versioning

The runtime and program MUST negotiate a compatible protocol version during session establishment.

In the baseline model:

- the program advertises supported protocol versions first
- the runtime selects one compatible version
- the runtime uses that selected version in `runtime.init`

A runtime MUST reject or terminate sessions when no compatible protocol version exists.

### 6.3 Error Handling

The runtime protocol MUST provide structured error reporting.

At minimum, errors MUST distinguish between:

- protocol errors
- permission errors
- validation errors
- service availability errors
- program-internal operation errors

The exact message envelope and structured error object are defined by the Overnet Program Protocol companion specification.

## 7. Lifecycle

### 7.1 Initialization

Before normal operation begins, the session MUST begin with a program-to-runtime hello announcing supported protocol versions.

After version negotiation succeeds, the runtime MUST initialize the program instance with:

- runtime protocol version information
- instance identity or equivalent runtime-assigned instance metadata
- configuration data
- declared permissions
- capability expectations or runtime feature availability as needed

A program MUST NOT assume normal operation before initialization succeeds.

### 7.2 Ready State

A program MUST be able to signal that it is ready for normal operation.

The runtime MUST be able to distinguish:

- process started
- protocol established
- initialization complete
- program ready

### 7.3 Shutdown

The runtime MUST be able to request orderly shutdown of a program instance using an explicit request/response exchange.

A program SHOULD respond to orderly shutdown requests by releasing resources, finishing in-flight work when safe, and reporting completion.

The runtime MAY forcibly terminate a program instance when orderly shutdown fails or when runtime policy requires it.

### 7.4 Health and Status

The protocol MUST include a structured health and status channel.

The runtime MUST be able to receive program-reported health and readiness information distinct from general logs.

## 8. Runtime-Managed Services

The runtime MUST expose a standard service model to programs.

This version defines the following runtime-managed service families:

- configuration
- secrets
- storage
- subscriptions
- timers and scheduled jobs
- event, state, and capability emission
- health and status reporting

Additional service families MAY be defined later.

The exact baseline service methods are defined by the Overnet Program Services companion specification.

### 8.1 Configuration

Configuration is host-managed.

Programs MUST receive configuration through the runtime interface rather than relying on implementation-specific local files as the required baseline behavior.

### 8.2 Secrets

The runtime MUST provide a host-managed secrets service.

Programs SHOULD obtain credentials and other sensitive material through runtime services rather than requiring raw secret material to be embedded directly in ordinary program configuration.

### 8.3 Storage

The runtime MUST provide host-managed storage services.

The first required storage model is:

- document or object storage
- append-only event storage

This specification does not require exposing a full relational or database-style query surface as part of the baseline program runtime contract.

### 8.4 Subscriptions

The runtime MUST provide runtime-managed subscription services so that programs may react to Overnet data and state changes delivered by the host environment.

### 8.5 Timers and Scheduled Jobs

The runtime MUST provide host-managed timers or scheduled job facilities.

These are required for periodic work, retries, delayed actions, maintenance tasks, and similar operational behavior.

## 9. Data Emission Model

### 9.1 Emitted Data Types

In this version, a program MUST be able to emit:

- Overnet events
- Overnet state
- capability advertisements

These outputs remain subject to runtime validation and policy enforcement.

### 9.2 Candidate Output

Program-emitted Overnet data is candidate output until accepted by the runtime.

The runtime MAY reject candidate output that fails:

- core validation
- companion-spec validation
- permission checks
- runtime policy

### 9.3 Capability Advertisements

If a program emits capability advertisements, the runtime MUST treat them as claims subject to validation, policy, and configuration, not as self-authorizing declarations.

## 10. Permissions

### 10.1 Explicit Permissions

The runtime MUST enforce an explicit per-program permission model.

A program instance MUST operate only with the permissions granted to that instance by the runtime.

### 10.2 Permission Scope

Permissions MAY govern access to:

- runtime-managed storage
- subscriptions
- secret material
- timers and scheduled jobs
- emission of specific classes of output
- other runtime services defined by later specifications

### 10.3 Least Privilege

A runtime SHOULD grant programs only the permissions needed for their declared purpose.

## 11. Networking Responsibility

Outbound networking is the responsibility of the program, not the baseline runtime.

This specification does not require the runtime to proxy or mediate all outbound network access on behalf of programs.

Later specifications MAY define optional runtime-managed networking services, but such services are not part of the required baseline.

## 12. Security Considerations

The runtime is a trust and policy boundary.

Therefore:

- a program MUST NOT be trusted to self-validate Overnet output
- secret access MUST be mediated by the runtime
- permissions MUST be enforced by the runtime
- transport framing errors MUST be treated as protocol errors
- a runtime SHOULD impose limits on message size, resource use, and service consumption

## 13. Open Issues

The following areas remain open for later companion documents or later revisions:

- the exact framing wire format
- the exact runtime protocol message envelope
- manifest and program package metadata
- detailed storage operations
- detailed subscription semantics
- secret-reference and rotation semantics
- timers and job scheduling semantics
- capability advertisement semantics at runtime
- compatibility and upgrade strategy across runtime versions
