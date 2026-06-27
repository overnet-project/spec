# Overnet Specification — Project Instructions

The spec is architecturally complete but deliberately abstract in many areas. The current priority is making it concrete: wire formats, JSON schemas, tag conventions, protocol flows, examples, and conformance fixtures.

## Spec Writing Principles

### Concreteness Over Abstraction
- Every normative requirement should be implementable by someone reading only this spec family.
- Prefer concrete formats, field names, and examples over abstract descriptions of what "must exist."
- When a section says something MUST be done, it should be clear *how* — or explicitly marked as deferred to a named companion spec.

### One Normative Home
- Each requirement should have exactly one authoritative location in the spec.
- Do not restate the same requirement in multiple sections with slightly different wording.
- Cross-reference instead of restating. If provenance requirements are defined in §13.3, other sections should point there, not paraphrase.

### Show, Don't Just Tell
- Include non-normative JSON examples for every data structure and protocol message.
- Examples go immediately after the normative definition they illustrate.
- Mark examples clearly as informative.

### Grounded in Nostr
- Always specify which Nostr primitives are used: kind numbers, tag names, content format.
- When Overnet imposes stricter requirements than generic Nostr usage, state the delta explicitly.
- Reference specific NIPs where relevant (e.g., NIP-01, NIP-42).

### Testable Requirements
- Every normative MUST or MUST NOT requires at least one fixture that tests it.
- A requirement without a fixture is considered incomplete. Add the fixture before considering the requirement done.
- When changing a normative requirement, update fixtures first. If no existing fixture breaks, the change probably isn't tested.
- Fixtures are the binding contract between the spec and implementations. If the spec says one thing and the fixtures say another, that's a bug in one of them — resolve it, don't ignore it.

## Spec Writing Style

### Language
- Use RFC 2119 keywords (MUST, SHOULD, MAY, etc.) only in normative sections, only in uppercase.
- Keep sentences short and declarative.
- Avoid hedging ("it is generally expected that..."). Either require it, recommend it, or don't mention it.
- Do not use "baseline" as a vague qualifier. If something is required, define what it requires concretely.

### Structure
- Each section should do one thing. If a section defines a format *and* specifies validation rules *and* gives examples, consider splitting it.
- Informative rationale goes in clearly marked subsections or appendices, not inline with normative text.

### Terminology
- Use terms exactly as defined in §3. Do not introduce synonyms.
- "event" means a Nostr event conforming to the Overnet core profile. "object" means a derived stable resource. Do not use them interchangeably.

## Decision Records

When making a significant design decision (format choices, kind number allocation, tag conventions, what to defer), record it in `docs/decisions.md` with:

- The decision
- The alternatives considered
- The rationale
- The date

This prevents re-litigating resolved questions.

## Working with Companion Specs

### Adapters
- Adapter specs live in `docs/adapters/<protocol>.md`.
- An adapter spec must define: identity mapping, object/event mapping, provenance format, known lossy translations, and capability implications.
- Writing adapter specs will expose gaps in the core. When that happens, fix the core first, then continue the adapter spec.

### Profiles
- Profile specs live in `docs/profiles/<name>.md`.
- A profile spec must define: required capabilities, additional event types or object types, additional validation rules, and any refinements to core behavior.

### Fixtures
- Fixture files live in `fixtures/<area>/` (e.g., `fixtures/core/`, `fixtures/irc/`).
- Each fixture is a JSON file with: `description` (what's being tested), `input` (event or query), and `expected` (outcome including `overnet_valid` and optionally `reason`).
- Cover both valid and invalid cases. For each check the spec requires, there should be a fixture that passes because the check succeeds, and a fixture that fails because it doesn't.
- Invalid fixtures should test one thing at a time. An event missing three fields needs three separate fixtures, not one fixture that's wrong in three ways.
- Fixture descriptions should state the normative rule being tested, not just "invalid event."
- The implementation generates its test fixtures from these files. Spec fixtures are the source of truth.

## Known Gaps (as of 2026-04-10)

These are the most important areas where the spec needs to become concrete. Prioritize roughly in this order:

1. **Nostr event format** — kind number(s), content JSON schema, tag conventions for core events
2. **Protocol flows** — publish, query, subscribe sequences with actual message examples
3. **Error/outcome format** — structured error categories with concrete representations
4. **Capability discovery format** — how capabilities are advertised and queried
5. **Object identity scheme** — concrete namespace and identifier format
6. **Reference tag conventions** — which Nostr tags represent which reference types
7. **IRC adapter** — first concrete adapter to pressure-test the core model
8. **Conformance fixtures** — valid/invalid event examples, expected validation outcomes
9. **Appendices** — Security Considerations, Privacy Considerations, Rationale
10. **status.md and decisions.md** — currently empty, should be populated as work proceeds

## What Not to Do

- Do not expand the core spec with abstract sections that defer all concrete details. If you can't define it concretely yet, leave it in §15 (Open Issues) rather than writing a vague normative section.
- Do not add requirements that are obligations on the spec authors rather than on implementations (e.g., "the core MUST define..."). Rephrase as implementation requirements.
- Do not duplicate content across sections. One normative home per requirement.
- Do not add features, profiles, or adapter support speculatively. Each addition should be motivated by a concrete use case or implementation need.
