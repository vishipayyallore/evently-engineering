# ADR-0002 — Build monolith first, then modularize

- **Status:** Accepted
- **Date:** 2026-09-06
- **Deciders:** Evently team
- **Related:** [`../deviations-from-author.md`](../deviations-from-author.md) (2026-08-31 row), deep-dive "Build approach", rules preamble ("Phased approach")

## Context

The course scaffolds the full modular monolith up front — separate `Domain`/`Application`/
`Infrastructure`/`Presentation` projects per module plus `Common.*`, schema-per-module, and
NetArchTest boundaries — before the first feature. That is a lot of moving structure to
maintain while still learning the patterns, and it locks in module boundaries before we
understand the domain well enough to draw them.

## Decision

We build Evently in **two phases**. **Phase 1** is a single deployable (`Evently.Api`) with
the four bounded contexts (Users, Events, Ticketing, Attendance) as **folders**, a shared
database, in-process calls, and immediate consistency — but already using CQRS, the `Result`
pattern, and a pure Domain. **Phase 2** refactors the working monolith into isolated modules
in the course's order: code organization → module communication → data isolation → boundary
enforcement. Rules and clauses are tagged **[Phase 2]** where they only apply after we start
modularizing.

## Consequences

### Good

- We evolve boundaries from working code (Fowler's *Monolith First*) instead of guessing them.
- Less structure to carry early; faster to code along with each lesson.
- The refactor to modules is itself a course topic (*Modularize Your Monolith*), so we still
  cover it.

### Trade-offs

- We will do a non-trivial refactor later (moving folders to projects, splitting the
  `DbContext`, wiring the outbox/inbox). Behavior must be preserved through it.
- Two sets of rules to hold in mind (Phase 1 binding now vs Phase 2 deferred).
- Risk of Phase-1 shortcuts hardening into habits — mitigated by keeping Domain/Application
  discipline (R2–R4, R8, R9) binding from the first slice.

### Follow-ups

- Phase 2 kickoff needs its own ADRs per step (code org, sync vs async communication, schema
  isolation).

## Alternatives considered

- **Scaffold the full modular monolith now (course default).** Rejected: premature boundary
  commitment, high maintenance while learning.
- **Stay a monolith permanently.** Rejected: module isolation and async messaging are the
  point of the exercise.
