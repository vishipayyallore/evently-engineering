---
applyTo: "**/*.{cs,csproj,sln}"
description: "Evently engineering rules — apply to all C#/project work in this repo (our .NET 10 Evently build)."
---

# Evently Engineering Rules (summary)

We build Evently here, on **.NET 10**.

Canonical, full version with rationale: `.claude/rules/evently-engineering-rules.md`.
Architecture reference: `docs/architecture/evently-deep-dive.md`.
Each rule below is meant to be enforced by an architecture test or by
`TreatWarningsAsErrors` (added as we build).

**Numbering convention:** ordered lists, numbered steps, phases, and identifiers start at
**1**, never **0** — in code and docs. The rule series runs R1–R10; the phased approach is a
preamble, not a numbered rule.

## Phased approach — monolith first, then modular
We build Evently **monolith first, then modular**. **Phase 1 — Monolith:** one deployable
(`Evently.Api`); the four contexts (Users, Events, Ticketing, Attendance) are **folders**, not
projects; shared database/tables; in-process method calls. Binding now: R2 (folder/namespace
layering), R3, R4, R6, R8, R9, R10. **Phase 2 — Modular Monolith:** refactor into isolated
modules — (1) code organization (separate projects + `Common.*`), (2) communication (sync
public API, then async messaging), (3) schema per module, (4) NetArchTest boundaries;
activates R1, R7, and the per-module `DbContext`/schema/`XModule` clauses of R5. Rules tagged
**[Phase 2]** apply only once modularizing; unmarked = **[Phase 1]**, binding now. See the
[build roadmap](../../docs/images/phase-roadmap.png).

## R1 — Module boundaries [Phase 2]
Modules (`Users`, `Events`, `Ticketing`, `Attendance`) never reference each other's
`Domain`/`Application`/`Infrastructure`/`Presentation`. The only allowed cross-module
reference is another module's `*.IntegrationEvents`. Cross-module data flow is async
(integration events); each module keeps its own local copy. Shared behavior goes in `Common.*`.

## R2 — Layer dependencies
Domain → (only `Common.Domain`). Application → own Domain + `Common.Application`, never
Infrastructure/Presentation. Presentation → own Application + `Common.Presentation`, never
Infrastructure. Infrastructure composes everything in its own module.

## R3 — Domain
Aggregates: `sealed : Entity`, private parameterless + only-private constructors, private
setters. Create via a `public static` factory — returns `Result<T>` when construction can
fail, else the entity directly (e.g. `Category.Create`). State changes are methods that return
`Result` (or `void` when they cannot fail) and `Raise(...)` a
`public sealed class …DomainEvent : DomainEvent` (primary ctor + `{ get; init; }` props). All
failures are `Error`s from `<Aggregate>Errors.cs` with the right `ErrorType`. No
`DateTime.UtcNow`, no I/O, no framework types in Domain.

## R4 — Application
One folder per use case: `Application/<Aggregate>/<UseCase>/`. `…Command`/`…Query` =
`public sealed record` implementing `ICommand`/`ICommand<T>`/`IQuery<T>`. Handlers =
`internal sealed`, primary ctor, name ends `CommandHandler`/`QueryHandler`, return
`Result`/`Result<T>`. Validators = `internal sealed : AbstractValidator<T>`, structural checks
only. Write path: repository + one `unitOfWork.SaveChangesAsync`. Read path: `IDbConnectionFactory`
+ Dapper + hand-written SQL, columns aliased with `nameof(TResponse.Prop)`; no EF. Domain-event
handlers = `internal sealed : DomainEventHandler<T>`, name ends `DomainEventHandler`; either
update a projection or publish an integration event, not both. Never return a Domain entity.

## R5 — Infrastructure
**[Phase 2] for the per-module shape** (per-module `DbContext`, `HasDefaultSchema`, `XModule`);
in Phase 1 a single composition root + single `DbContext`, no per-schema split.
`DbContext` = `sealed : DbContext, IUnitOfWork`, `HasDefaultSchema`, snake_case, per-schema
migrations history, applies the four outbox/inbox configs. EF configs + repositories =
`internal sealed`; no `IQueryable` leaks. Register everything via `XModule.AddXModule` (with
`Idempotent*` decorators) and `XModule.ConfigureConsumers`. External systems sit behind an
Application interface.

## R6 — Presentation
One `internal sealed class <UseCase> : IEndpoint` per file. End with
`result.Match(Results.Ok, ApiResults.Problem)`. Always `.RequireAuthorization(Permissions.X)`
+ `.WithTags(Tags.X)`. Integration-event handlers = `internal sealed : IntegrationEventHandler<T>`,
name ends `IntegrationEventHandler`, translate to a command via `ISender`, throw
`EventlyException` on failure. No `DbContext`/repository in Presentation — only `ISender`.

## R7 — Cross-module messaging [Phase 2]
Integration events = `public sealed class : IntegrationEvent` in `*.IntegrationEvents`
(ctor chains `: base(id, occurredOnUtc)`, `{ get; init; }` props), primitives only, additive
changes only. Publish only from a domain-event handler via
`IEventBus.PublishAsync`. Handlers must be logically idempotent. Multi-module coordinated
workflows → a MassTransit saga in the initiating module's Presentation (state in Redis).

## R8 — Testing
New aggregate behavior → unit test (`Faker`, FluentAssertions, `AssertDomainEventWasPublished<T>`).
New use case → integration test through `ISender` with `BaseIntegrationTest` +
`CleanDatabaseAsync()` + `Poller`. New type category → an architecture test. Names:
`Should_<Outcome>_When<Condition>`. `dotnet test Evently.sln` green = done.

## R9 — Style (compiler-enforced)
File-scoped namespaces; `using` outside namespace; braces always; language keywords over BCL
types; expression-bodied members; `readonly` fields; explicit accessibility; default
`internal` + `sealed`; collection expressions `[]`; primary ctors; no `this.`; no unused
params; nullable on. A warning is a build error.

## R10 — Change discipline
Match the nearest existing slice. Validate smallest-first, then `dotnet build Evently.sln`,
then the module's tests, then `dotnet test Evently.sln`. Entity-config/`DbSet` change → add an
EF migration. Never hand-edit `bin/`, `obj/`, `*Designer.cs`, `*ModelSnapshot.cs`. We target
`net10.0` (the course is on .NET 8 — a logged deviation); use the .NET 10 equivalent when a
step relies on an .NET 8-specific API and note it in `docs/deviations-from-author.md`.
