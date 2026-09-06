# ADR-0004 — Result pattern for business-rule failures

- **Status:** Accepted
- **Date:** 2026-09-06
- **Deciders:** Evently team
- **Related:** ADR-0003, deep-dive §3 ("The Result / Error model"), rules R3.5, R4.3, R6.2

## Context

Business-rule violations ("event already started", "category not found") are expected
outcomes, not exceptional conditions. Throwing for them makes control flow implicit, couples
callers to `try/catch`, is easy to forget, and turns a 404 into a 500 if a handler is missed.

## Decision

Every use case returns **`Result` or `Result<T>`**. A failure carries a typed
`Error(Code, Description, ErrorType)` where `ErrorType ∈ {Failure, Validation, Problem,
NotFound, Conflict}`. Errors are defined once as `static` members / factories in
`Domain/<Aggregate>/<Aggregate>Errors.cs`. The domain **never throws** for a rule violation;
aggregate factories and state-transition methods return `Result`. `ApiResults.Problem` maps
`ErrorType` to the HTTP status (400/404/409/500) and an RFC-7231 `type`. Exceptions are
reserved for programmer error and infrastructure faults, and are wrapped in `EventlyException`
by the pipeline.

## Consequences

### Good

- Failure paths are explicit in the signature and the compiler helps.
- One place per aggregate defines its errors; HTTP mapping is centralized and consistent.
- Handlers are pure and trivially unit-testable — no exception plumbing.

### Trade-offs

- Verbose: every call site checks `IsFailure` and threads `result.Error`.
- Two failure channels to understand (typed `Result` vs thrown exceptions) and a rule about
  which is which.
- `Result<T>.Value` still throws if misused on a failure — a guard-rail, not a guarantee.

### Follow-ups

- Keep the `ErrorType` → HTTP map and the `ValidationError` `errors` array in sync with
  `ApiResults`.

## Alternatives considered

- **Exceptions for business rules.** Rejected: implicit flow, 500s on missed catches,
  couples layers.
- **Nullable returns / sentinel values.** Rejected: loses the reason for failure.
- **A third-party result library (e.g. `ErrorOr`, `FluentResults`).** Rejected for now: the
  course's hand-rolled `Result` is small, owned, and matches the material.
