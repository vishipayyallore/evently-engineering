# ADR-0003 — CQRS with MediatR and a thin pipeline

- **Status:** Accepted
- **Date:** 2026-09-06
- **Deciders:** Evently team
- **Related:** ADR-0004 (Result), deep-dive §3, rules R4; [`../deviations-from-author.md`](../deviations-from-author.md) (MediatR licensing note)

## Context

Each use case needs a consistent shape: input validation, structured logging/tracing,
error handling, and a handler that does one job. We also want the read and write paths to
diverge — writes go through the domain model and a transaction; reads are shaped for the
screen and should not pay for EF change-tracking.

## Decision

Every use case is a **command or a query** — a `public sealed record` implementing
`ICommand`/`ICommand<T>`/`IQuery<T>` — dispatched through **MediatR**. Three open-generic
pipeline behaviors run in a fixed order: `ExceptionHandlingPipelineBehavior` →
`RequestLoggingPipelineBehavior` → `ValidationPipelineBehavior`. Handlers are
`internal sealed`, one folder per use case. **Write path:** EF Core with a repository
interface and a single `IUnitOfWork.SaveChangesAsync`. **Read path:** `IDbConnectionFactory`
with Dapper and hand-written SQL, no EF. FluentValidation validators do structural checks only.

## Consequences

### Good

- Uniform use-case shape; cross-cutting concerns are declared once as behaviors.
- Read/write separation keeps queries fast and the domain model uncompromised by reporting
  needs.
- Handlers stay small and individually testable.

### Trade-offs

- MediatR indirection and reflection; a learning curve for the pipeline.
- **MediatR is commercially licensed from v12.4.** The course pins 12.2.0 (.NET 8 only). On
  .NET 10 we must move to a licensed version or a small hand-rolled dispatcher — tracked in
  `deviations-from-author.md`, decision pending.
- Two persistence styles (EF and Dapper) to know.

### Follow-ups

- Resolve the MediatR version/licensing question before the first real slice.

## Alternatives considered

- **Plain services / no mediator.** Rejected: cross-cutting behavior gets copy-pasted into
  every handler.
- **One persistence stack (EF everywhere).** Rejected: EF on the read path adds tracking
  cost and couples query shape to the entity model.
- **Hand-rolled dispatcher now.** Deferred: viable, but not worth the detour until the
  licensing decision forces it.
