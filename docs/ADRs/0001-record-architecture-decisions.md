# ADR-0001 — Record architecture decisions

- **Status:** Accepted
- **Date:** 2026-09-06
- **Deciders:** Evently team
- **Related:** [`README.md`](README.md), [`../architecture/evently-deep-dive.md`](../architecture/evently-deep-dive.md)

## Context

We are building Evently by working through the *Modular Monolith Architecture* course and
adapting it to .NET 10. The `evently-deep-dive.md` reference describes **what** the
architecture is, and `deviations-from-author.md` lists where we differ from the course — but
neither captures the **rationale** behind a choice at the moment it was made, or the options
we rejected. When a decision is revisited months later (or by a coding agent), that context
is gone.

## Decision

We keep lightweight **Architecture Decision Records** under `docs/ADRs/`, one Markdown file
per significant decision, numbered from `0001`. Each records context, the decision, its
consequences, and the alternatives considered. An Accepted ADR is immutable; a decision is
changed by writing a new ADR that supersedes it. The **Architect** role owns ADRs. The
process and index live in [`README.md`](README.md).

## Consequences

### Good

- The "why" survives staff and context changes; agents can ground design choices in a
  citable record.
- Forces us to name the alternative and the trade-off before committing.
- Cheap: one screen of prose, no tooling.

### Trade-offs

- Another artifact to keep honest. Mitigated by keeping ADRs short and only for structural
  decisions.
- Overlaps `deviations-from-author.md`; we accept the small duplication and cross-link.

### Follow-ups

- Backfill ADRs for the decisions already baked into the deep-dive and the rules (ADR-0002
  onward).

## Alternatives considered

- **Keep rationale in the deep-dive.** It drifts — the deep-dive is a living "current state"
  doc, so point-in-time reasoning and rejected options get edited away.
- **Git commit messages / PR descriptions.** Not discoverable; not structured; buried.
- **A single `decisions.md` log.** Grows unwieldy and invites editing history; separate
  immutable files are clearer.
