# ADR-0010 — Target .NET 10 (course is on .NET 8)

- **Status:** Accepted
- **Date:** 2026-09-06
- **Deciders:** Evently team
- **Related:** ADR-0003 (MediatR licensing consequence), [`../deviations-from-author.md`](../deviations-from-author.md) (2026-08-30 row), rules R10.6

## Context

The *Modular Monolith Architecture* course is built on .NET 8. We want to build on the
current .NET so the code, tooling, and package versions are ones we'd actually ship, and so
the exercise stays relevant.

## Decision

Target **`net10.0`** across the solution (`Directory.Build.props`). The architecture —
layering, module isolation, CQRS, outbox/inbox, the Result pattern — is framework-agnostic
and applies unchanged. Where a course step relies on a .NET 8-specific API or package
version, we use the .NET 10 equivalent and note it in `deviations-from-author.md`.

## Consequences

### Good

- Current runtime, analyzers, and language features; skills transfer to real work.
- Forces us to find current package versions rather than copying pinned .NET 8 ones.

### Trade-offs

- Package versions diverge from the course throughout — every `PackageReference` is a small
  lookup.
- **MediatR 12.2.0 (course) does not target .NET 10.** We must move to 12.4+ (commercially
  licensed) or a hand-rolled dispatcher — see ADR-0003; decision pending.
- Occasional API drift (EF Core, ASP.NET minimal APIs, OpenTelemetry) to reconcile against
  the course's code.

### Follow-ups

- Maintain a `deviations-from-author.md` row per .NET 8→10 substitution that isn't obvious.
- Resolve MediatR (ADR-0003).

## Alternatives considered

- **Follow the course on .NET 8.** Rejected: we'd be learning to build something already a
  version behind, and the tooling story is less interesting.
- **.NET 9 (STS).** Rejected: .NET 10 is LTS and current; no reason to target a short-term
  release.
