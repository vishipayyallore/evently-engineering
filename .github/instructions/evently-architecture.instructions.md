---
applyTo: "**/*.{cs,csproj,sln}"
description: "Evently engineering rules — apply when working in the active Evently repo (C:\GitHub\evently-learning-tracker)."
---

# Evently Engineering Rules (summary)

This repository is the active Evently implementation for our learning project, and we are
working in the .NET 10 workstream here.

Canonical, full version with rationale: `.claude/rules/evently-engineering-rules.md`.
Architecture analysis reference: `docs/architecture/evently-deep-dive.md`.
Every rule below is enforced by an architecture test or by `TreatWarningsAsErrors`.

## R1 — Module boundaries
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
setters. Create via `public static Result<T> Create(...)`. State changes are methods that
return `Result` and `Raise(...)` a `sealed record …DomainEvent : DomainEvent`. All failures
are `Error`s from `<Aggregate>Errors.cs` with the right `ErrorType`. No `DateTime.UtcNow`, no
I/O, no framework types in Domain.

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

## R7 — Cross-module messaging
Integration events = `public sealed record : IntegrationEvent` in `*.IntegrationEvents`,
primitives only, additive changes only. Publish only from a domain-event handler via
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
EF migration. Never hand-edit `bin/`, `obj/`, `*Designer.cs`, `*ModelSnapshot.cs`. Do not
change `TargetFramework` (currently `net8.0` in `Directory.Build.props`) without an explicit
decision.
