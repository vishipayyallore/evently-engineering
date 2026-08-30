# Evently Engineering Rules

Authoritative coding rules for work in `C:\GitHub\evently_source_code`. Derived from the
codebase's own architecture tests, `.editorconfig`, and `Directory.Build.props`. Full
rationale and examples: [`../../docs/architecture/evently-deep-dive.md`](../../docs/architecture/evently-deep-dive.md).

Every rule below is either **enforced by a test** (a violation fails `dotnet test`) or
**enforced by the compiler** (`TreatWarningsAsErrors`). Do not ask to relax them; match them.

---

## R1 — Module boundaries

1. The four modules (`Users`, `Events`, `Ticketing`, `Attendance`) never reference each other's
   `Domain`, `Application`, `Infrastructure`, or `Presentation` assemblies.
2. The **only** permitted cross-module reference is another module's `*.IntegrationEvents` assembly.
3. Cross-module data flow is **async only**: publish an integration event; the other module
   consumes it and keeps its own local copy. No shared tables, no cross-schema queries, no
   direct service calls.
4. New shared behavior goes in `Common.*`, not a new top-level folder. Confirm with the
   Architect role before adding anything to `Common`.

## R2 — Layer dependencies (per module)

| Layer | May reference | Must NOT reference |
|---|---|---|
| Domain | `Common.Domain` | Application, Infrastructure, Presentation, EF, MediatR, ASP.NET |
| Application | `Common.Application`, own Domain | Infrastructure, Presentation |
| Presentation | `Common.Presentation`, own Application | Infrastructure |
| Infrastructure | everything in its own module | other modules (see R1) |

- Dependencies point **inward**. Domain is the centre and depends on nothing but `Common.Domain`.
- Application depends on **interfaces** it declares (`IUnitOfWork`, `IPaymentService`,
  `IIdentityProviderService`, `ICustomerContext`, repository interfaces from Domain);
  Infrastructure implements them.

## R3 — Domain layer

1. Aggregates inherit `Entity`, are `sealed`, have a **`private` parameterless constructor**
   and **only `private` constructors**. All setters are `private`.
2. Construct via a `public static Result<T> Create(...)` factory that validates invariants and
   `Raise(...)`s a creation domain event.
3. State transitions are instance methods that return `Result` (or `void` when they cannot
   fail), enforce the invariant, mutate, and `Raise(...)` a domain event.
4. Domain events: `sealed record`, inherit `DomainEvent`, name ends `DomainEvent`, carry
   primitives/ids only.
5. Every failure is an `Error` defined as a `static` member or factory in
   `Domain/<Aggregate>/<Aggregate>Errors.cs`. Pick the right `ErrorType`
   (`Validation` / `Problem` / `NotFound` / `Conflict` / `Failure`). Never `throw` for a
   business-rule violation.
6. No `DateTime.UtcNow`, no I/O, no framework types in Domain. Time is a parameter.

## R4 — Application layer

1. One folder per use case: `Application/<Aggregate>/<UseCase>/`.
2. `<UseCase>Command` / `<UseCase>Query`: `public sealed record`, implements
   `ICommand` / `ICommand<T>` / `IQuery<T>`. Name ends `Command` / `Query`.
3. `<UseCase>CommandHandler` / `QueryHandler`: **`internal sealed`**, primary constructor for
   deps, implements `ICommandHandler<,>` / `IQueryHandler<,>`. Name ends `CommandHandler` /
   `QueryHandler`. Returns `Result` / `Result<T>` — never throws for expected failures.
4. `<UseCase>CommandValidator`: `internal sealed : AbstractValidator<TCommand>`, name ends
   `Validator`. Structural validation only (not null, ranges, cross-field). Business rules
   live in the aggregate/handler.
5. **Write path**: load aggregates through repository interfaces → call aggregate methods →
   `repository.Insert(...)` → `await unitOfWork.SaveChangesAsync(ct)`. One `SaveChangesAsync`
   per handler.
6. **Read path**: `IQueryHandler` uses `IDbConnectionFactory` + Dapper + hand-written SQL.
   **No EF, no `DbContext`, no repository on the read side.** Alias columns with
   `nameof(TResponse.Prop)`.
7. Domain-event handlers: `internal sealed`, inherit `DomainEventHandler<T>`, name ends
   `DomainEventHandler`, in the relevant `Application/<Aggregate>/<UseCase>/` folder. They
   update a projection **or** publish an integration event via `IEventBus` — not both.
8. Response DTOs: `<X>Response.cs` records in the use-case folder. Never return a Domain entity.

## R5 — Infrastructure layer

1. `DbContext`: `sealed`, implements `IUnitOfWork`, `HasDefaultSchema(Schemas.X)`,
   `UseSnakeCaseNamingConvention()`, per-schema migrations history table. `DbSet`s `internal`.
   `OnModelCreating` applies the four outbox/inbox configs + the module's entity configs.
2. EF `IEntityTypeConfiguration<T>` and repository implementations: `internal sealed`.
   Repositories expose only what the Application needs (`GetAsync`, `Insert`) — no `IQueryable`
   leaks.
3. Register everything through `XModule.AddXModule(IConfiguration)`: domain-event handlers
   (decorated with `IdempotentDomainEventHandler<>` via Scrutor `.Decorate`), integration-event
   handlers (decorated with `IdempotentIntegrationEventHandler<>`), `DbContext`, repositories,
   `IUnitOfWork` → `DbContext`, options bound from `modules.<name>.json`, endpoints.
4. MassTransit consumers/sagas are registered in `XModule.ConfigureConsumers`.
5. External systems (payment, identity/Keycloak) sit behind an Application interface and are
   implemented here.

## R6 — Presentation layer

1. One endpoint per file: `internal sealed class <UseCase> : IEndpoint`, `MapEndpoint` maps a
   single route. Nested `internal sealed class Request` for the body when needed.
2. End with `return result.Match(Results.Ok /* or Results.NoContent, etc. */, ApiResults.Problem);`
3. Always `.RequireAuthorization(Permissions.<X>)` and `.WithTags(Tags.<X>)`. Add the constant
   to `Permissions.cs` (`"<resource>:<action>"`) / `Tags.cs`.
4. Integration-event handlers: `internal sealed`, inherit `IntegrationEventHandler<T>`, name
   ends `IntegrationEventHandler`. They translate the event into a command via `ISender` and
   throw `EventlyException` on failure (so the inbox job retries).
5. Presentation must not touch a `DbContext` or repository — only `ISender`.

## R7 — Cross-module messaging

1. Integration event contracts: `public sealed record : IntegrationEvent` in
   `*.IntegrationEvents`, primitives only, versioned by addition (never break an existing
   contract).
2. Publish integration events **only** from a domain-event handler via `IEventBus.PublishAsync`
   — never from a command handler directly, so the outbox guarantees delivery.
3. Consumers are idempotent by construction (the `Idempotent*` decorators + `*_message_consumers`
   tables). Handlers must also be **logically** idempotent (upsert, check-existence-first).
4. Multi-module workflows (something must happen in ≥2 other modules and be coordinated) →
   a MassTransit saga in the initiating module's Presentation, state in Redis. Discuss with
   the Architect first.

## R8 — Testing

1. New aggregate behavior → a unit test in `*.UnitTests` (`Faker`, FluentAssertions,
   `AssertDomainEventWasPublished<T>`).
2. New use case → an integration test in `*.IntegrationTests` driven through `ISender`, using
   `BaseIntegrationTest` + `CleanDatabaseAsync()`; assert eventual-consistency outcomes with
   the `Poller`.
3. New type in any layer → it must satisfy the existing `*.ArchitectureTests`. If you add a
   new *category* of type, add the corresponding architecture test.
4. Test names: `Should_<Outcome>_When<Condition>`; body uses `// Arrange` / `// Act` / `// Assert`.
5. `dotnet test Evently.sln` must be green before a change is "done".

## R9 — Code style (compiler-enforced)

- File-scoped namespaces; `using` directives **outside** the namespace; `System.*` first.
- Braces on every block. Language keywords over BCL types (`string` not `String`).
- Expression-bodied properties/accessors/operators/lambdas; `readonly` on fields that can be.
- Explicit accessibility on every member. **Default to `internal` + `sealed`.** Only
  `Common.*` public contracts, Domain aggregates/events/errors, commands/queries, and
  integration events are `public`.
- Collection expressions (`[]`), primary constructors for DI, no `this.` qualification,
  no unused parameters.
- `nullable` is on — annotate and handle nullability; do not `!` your way past it without cause.
- A build **warning is an error** (Sonar + .NET analyzers, `AnalysisMode=All`). Fix the cause.

## R10 — Change discipline

1. Match the shape of the nearest existing slice — the codebase is highly uniform; consistency
   beats cleverness.
2. Smallest validation command for the changed area first, then `dotnet build Evently.sln`,
   then the relevant module's test projects, then `dotnet test Evently.sln`.
3. A migration is required whenever an entity config or `DbSet` changes:
   `dotnet ef migrations add <Name> --project <Module>.Infrastructure --startup-project src/API/Evently.Api`.
4. Never edit `bin/`, `obj/`, `*Designer.cs`, or `*ModelSnapshot.cs` by hand.
5. `Directory.Build.props` currently targets `net8.0` despite an SDK 10 install and AGENTS.md's
   ".NET 10" language — do not change `TargetFramework` without an explicit decision from the
   user or Architect.
