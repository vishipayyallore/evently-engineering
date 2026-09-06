# Architecture Decision Records

An **ADR** captures one significant architecture or design decision for our Evently build —
the context that forced it, what we chose, and what we trade away. ADRs are the **"why"**;
[`../architecture/evently-deep-dive.md`](../architecture/evently-deep-dive.md) is the "what"
(the current target and the patterns to follow).

## When to write one

Write an ADR when a choice is **structural and hard to reverse**, or when future-you would
ask *"why is it done this way?"*:

- a new module / bounded context, or a change to a module boundary;
- anything added to `Common.*`;
- a cross-cutting concern (auth, caching, messaging transport, observability, migration
  strategy);
- a library swap or a new external dependency;
- a deliberate departure from the *Modular Monolith Architecture* course
  (also add a row to [`../deviations-from-author.md`](../deviations-from-author.md) and link
  the ADR from it);
- picking one option when a credible alternative existed.

Routine slices that fit an existing pattern do **not** need an ADR.

## How

1. Copy [`template.md`](template.md) to `NNNN-kebab-case-title.md` — `NNNN` is the next free
   number, zero-padded, **starting at `0001`** (never `0000`).
2. Fill it in. Keep it short — one screen. Prose, not bullet soup.
3. Open it as **`Proposed`**. The **Architect** role owns getting it to **`Accepted`**
   (see [`../../.claude/agents/architect.md`](../../.claude/agents/architect.md)).
4. An Accepted ADR is **immutable**. To change a decision, write a new ADR and set the old
   one's status to `Superseded by ADR-NNNN`; the new one links back with `Supersedes ADR-NNNN`.
5. Add the row to the index below.

## Status lifecycle

`Proposed` → `Accepted` → (`Superseded by ADR-NNNN` | `Deprecated`). Never delete an ADR.

## Index

| ADR | Title | Status | Date |
|---|---|---|---|
| [0001](0001-record-architecture-decisions.md) | Record architecture decisions | Accepted | 2026-09-06 |
| [0002](0002-monolith-first-then-modular.md) | Build monolith first, then modularize | Accepted | 2026-09-06 |
| [0003](0003-cqrs-with-mediatr.md) | CQRS with MediatR and a thin pipeline | Accepted | 2026-09-06 |
| [0004](0004-result-pattern-over-exceptions.md) | Result pattern for business-rule failures | Accepted | 2026-09-06 |
| [0005](0005-clean-layering-per-module.md) | Clean layering per module (dependencies point inward) | Accepted | 2026-09-06 |
| [0006](0006-outbox-inbox-for-cross-module-messaging.md) | Outbox/inbox for cross-module messaging | Accepted | 2026-09-06 |
| [0007](0007-schema-per-module-data-isolation.md) | Schema-per-module data isolation | Accepted | 2026-09-06 |
| [0008](0008-in-memory-message-transport.md) | In-memory message transport for now | Accepted | 2026-09-06 |
| [0009](0009-keycloak-permission-based-authorization.md) | Keycloak + permission-based authorization | Accepted | 2026-09-06 |
| [0010](0010-target-dotnet-10.md) | Target .NET 10 (course is on .NET 8) | Accepted | 2026-09-06 |
| [0011](0011-classic-sln-format.md) | Keep the classic `.sln` format | Accepted | 2026-09-06 |
| [0012](0012-architecture-tests-as-boundary-enforcement.md) | NetArchTest architecture tests enforce the rules | Accepted | 2026-09-06 |

## Related

- [`../architecture/evently-deep-dive.md`](../architecture/evently-deep-dive.md) — the target architecture and patterns (incl. the C4-level diagram map).
- [`../deviations-from-author.md`](../deviations-from-author.md) — the course-diff view; each row links its ADR.
- [`../../.claude/rules/evently-engineering-rules.md`](../../.claude/rules/evently-engineering-rules.md) — R1–R10, the coding contract the ADRs justify.
