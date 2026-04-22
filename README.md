# Overnet Specification

This repository contains the draft specifications for Overnet.

GitHub: <https://github.com/overnet-project/spec>

Overnet is a higher-level protocol and application platform built on top of Nostr.
It is intended to support systems such as chat, email, code hosting, marketplaces, and websites, while emphasizing freedom, decentralization, self-hostability, and interoperability.

At present, this repository contains the Overnet Core Specification draft plus the first companion adapter specification for IRC, along with shared conformance fixtures used by the reference implementation work.

In this specification family:

- adapter specifications define how external systems map into Overnet semantics
- Overnet programs are runnable implementations that consume or produce Overnet data

## Status

This repository is in active development.

The current specifications should be treated as working drafts.
They are being revised alongside early implementation work in the sibling repositories:

- [core-perl](https://github.com/overnet-project/core-perl)
- [relay-perl](https://github.com/overnet-project/relay-perl)
- [adapter-irc-perl](https://github.com/overnet-project/adapter-irc-perl)
- [irc-server](https://github.com/overnet-project/irc-server)

The current document is useful as:

- a statement of the intended architecture
- a development target for early implementation work
- a basis for review and discussion

It should not yet be treated as a stable interoperability standard.

See [docs/status.md](docs/status.md) for more detail.

## Repository Layout

- [docs/core.md](docs/core.md)
  - the main Overnet Core Specification draft
- [docs/status.md](docs/status.md)
  - current stability, scope, and unresolved areas
- [docs/decisions.md](docs/decisions.md)
  - major design decisions and rationale
- [docs/adapters/](docs/adapters/)
  - companion adapter specifications
- [docs/programs/](docs/programs/)
  - companion Overnet program runtime, protocol, and services specifications
- [docs/profiles/](docs/profiles/)
  - companion application profile specifications
- [docs/registries/](docs/registries/)
  - registries, namespaces, and related reference material
- [fixtures/](fixtures/)
  - conformance fixtures, examples, and test inputs/outputs

## Current Scope

The current focus of this repository is the Overnet core plus the first real adapter pressure test.

The current documents and fixtures cover:

- the Overnet core event and provenance model
- core validation rules and shared core fixtures
- removal and delegation baseline semantics
- generic adapter fidelity requirements
- the first IRC adapter specification and IRC fixture corpus
- the first draft Overnet Program Runtime specification
- the first draft Overnet Program Protocol specification
- the first draft Overnet Program Services specification

Application-specific behavior and additional adapters are still expected to be defined in companion specifications rather than folded into the core.

This repository now contains initial working drafts for both the Overnet Program Runtime and Overnet Program Protocol.

## Planned Companion Specifications

Over time, this repository is expected to grow to include documents such as:

- email adapter specification
- GitLab adapter specification
- chat profile
- email profile
- code hosting profile
- storage and replication profiles

These names are provisional and should not be treated as final.

## Development Approach

This specification family is being developed through a combination of:

- core design work
- early implementation work
- conformance-oriented thinking
- iterative revision based on real adapter and application requirements

The intent is not to freeze the entire design prematurely.
Instead, the goal is to develop a coherent core, pressure-test it through implementation and adapters, and refine it as needed.

## Contributing

Discussion, review, criticism, issue reports, and pull requests are welcome.

If you think something in the spec is ambiguous, inconsistent, too broad, too narrow, or likely to break under implementation pressure, please open an issue.

Small clarifications and focused pull requests are especially helpful while the specification is still evolving.

## Related Repositories

- [core-perl](https://github.com/overnet-project/core-perl)
- [relay-perl](https://github.com/overnet-project/relay-perl)
- [adapter-irc-perl](https://github.com/overnet-project/adapter-irc-perl)
- [irc-server](https://github.com/overnet-project/irc-server)

## License

This repository is licensed under the GNU General Public License, version 3.
See [LICENSE](LICENSE).
