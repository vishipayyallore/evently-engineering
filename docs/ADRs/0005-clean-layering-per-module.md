# ADR-0005 — Clean layering per module (dependencies point inward)

- **Status:** Accepted
- **Date:** 2026-09-06
- **Deciders:** Evently team
- **Related:** ADR-0012 (architecture tests), deep-dive §1–§2, rules R2; module-layering diagram

## Context

Each bounded context needs an internal structure that keeps the domain model free of
framework and infrastructure concerns, makes the write/read split enforceable, and lets us
reason about one module without the rest.

## Decision

Every module is layered **Domain → Application → Infrastructure / Presentation**, with
dependencies pointing **inward**:

| Layer | May reference | Must not reference |
|---|---|---|
| Domain | `Common.Domain` (+ small value libs) | Application, Infrastructure, Presentation, EF, MediatR, ASP.NET |
| Application | `Common.Application`, own Domain, own `IntegrationEvents` | Infrastructure, Presentation |
| Presentation | `Common.Presentation`, own Application, other modules' `*.IntegrationEvents` | Infrastructure |
| Infrastructure | everything in its own module | other modules (except `*.IntegrationEvents`) |

Application depends on **interfaces it declares** (`IUnitOfWork`, `IPaymentService`,
`IIdentityProviderService`, `ICustomerContext`, repository interfaces from Domain);
Infrastructure implements them. In **Phase 1** this is folder/namespace discipline; in
**Phase 2** it becomes project references enforced by `LayerTests`.

## Consequences

### Good

- Domain stays pure and fast to unit-test; time and I/O enter as parameters/interfaces.
- The write path (EF + repo + `IUnitOfWork`) and read path (Dapper) are structurally
  separated.
- Infrastructure is the only place that knows about every other part of its module.

### Trade-offs

- More indirection: an interface in Application for every external touch-point, implemented
  in Infrastructure.
- Contributors must know which layer a type belongs in; the architecture tests catch misses
  only once Phase 2 lands.

### Follow-ups

- Phase 2: turn the folder boundaries into project references and switch on `LayerTests`.

## Alternatives considered

- **Transaction-script / anemic services.** Rejected: business rules leak into handlers and
  SQL; no enforceable centre.
- **A shared "core" layer both Domain and Infrastructure use.** Rejected: invites Domain to
  depend on framework types through the back door.
