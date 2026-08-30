# Evently — Architecture Deep Dive

> Analysis of `C:\GitHub\evently_source_code` — the **author's reference implementation**
> (.NET 8) from Milan Jovanović's *Modular Monolith Architecture* course.
>
> **We build our version in this repo on .NET 10.** This document describes the target
> design and the patterns to follow; adapt framework-version details and log deliberate
> departures in [`../deviations-from-author.md`](../deviations-from-author.md). The
> architecture itself (layering, module isolation, CQRS, outbox/inbox, Result pattern) is
> framework-agnostic and carries over unchanged.
>
> Written 2026-08-30. Verify specifics against the reference source before relying on them.

---

## How this analysis was done (ReAct trace)

| Step | Thought | Action | Observation |
|---|---|---|---|
| 1 | Need the shape before the detail | Listed all 660 source files | 4 modules (Users, Events, Ticketing, Attendance), each with 6+ projects; a `Common` set; one `API` host; module + solution-level test projects |
| 2 | The building blocks define everything downstream | Read `Common.Domain` (`Entity`, `Result`, `Error`, `DomainEvent`) | Result pattern, not exceptions; entities own domain events; errors are typed values |
| 3 | How is a request handled end to end? | Read `Common.Application` (messaging interfaces, 3 pipeline behaviors, `ApplicationConfiguration`) | MediatR CQRS; every handler returns `Result`; behaviors = Exception → Logging → Validation |
| 4 | What are the hard rules? | Read every `*.ArchitectureTests` project + top-level `Evently.ArchitectureTests` | Layering, module isolation, naming, sealing, visibility, ctor rules — all executable tests |
| 5 | Trace one vertical slice | Read Events `CreateEvent` (command/handler/validator/endpoint) + `Event` aggregate + `GetEvent` (Dapper) | Write path = EF + repo + UoW; read path = raw SQL via `IDbConnectionFactory`; endpoint = minimal API + `Result.Match` |
| 6 | How do modules talk? | Read outbox interceptor + `ProcessOutboxJob` + `IdempotentDomainEventHandler` + `EventBus` + inbox consumer/job + an integration-event handler + `CancelEventSaga` | Outbox → domain event handler → `IEventBus` (MassTransit in-memory) → inbox → integration-event handler → command. Idempotency via consumer tables. Saga orchestrates multi-module workflows. |
| 7 | Infra wiring & ops | Read `InfrastructureConfiguration`, `EventsModule`, `Program.cs`, `docker-compose.yml`, `modules.*.json` | Postgres (schema per module), Redis, Keycloak, Quartz, Serilog/Seq, OpenTelemetry/Jaeger; per-module `AddXModule` + `ConfigureConsumers` |
| 8 | Confirm conventions | Read `.editorconfig`, `Directory.Build.props`, sample `.csproj`, unit + integration test bases | Warnings-as-errors, Sonar, file-scoped namespaces, expression-bodied, sealed-by-default; Testcontainers-backed integration tests |

---

## 1. System shape

**One deployable** — `src/API/Evently.Api` — hosting **four modules** that are isolated at the assembly and database-schema level but run in one process and one database.

```
Evently.Api (composition root: Program.cs)
├── Users        — registration, profile, roles/permissions, Keycloak sync
├── Events        — events, categories, ticket types (the "catalog")
├── Ticketing     — customers, carts, orders, payments, tickets
└── Attendance    — attendees, check-in, event statistics
        each module ↓
   Domain → Application → Infrastructure → Presentation   (+ IntegrationEvents contract)
```

### Per-module project layout (Events shown; all four are identical in shape)

| Project | References | Contains |
|---|---|---|
| `*.Domain` | `Common.Domain` only | Aggregates (`Entity`), domain events, `*Errors` static classes, repository **interfaces**, enums/value objects |
| `*.Application` | `Common.Application`, own `Domain` | Commands, queries, handlers (`internal sealed`), validators, domain-event handlers, response DTOs, abstraction interfaces (`IUnitOfWork`, `ICustomerContext`, `IPaymentService`, `IIdentityProviderService`) |
| `*.Infrastructure` | `Common.Infrastructure`, own `Application` + `Presentation` | `DbContext`, EF `IEntityTypeConfiguration`s, repository **implementations**, `XModule.cs` (DI), outbox/inbox jobs + idempotent decorators, external clients (Keycloak, Stripe-style payment) |
| `*.Presentation` | `Common.Presentation`, own `Application` | Minimal-API endpoints (`IEndpoint`), integration-event handlers, `Permissions`, `Tags`, sagas |
| `*.IntegrationEvents` | `Common.Application` | **The only assembly other modules may reference.** Plain event records + models. |
| `*.UnitTests` | Domain + Application | Domain behavior, handler logic |
| `*.IntegrationTests` | whole module + API | Testcontainers, real DB, `ISender`-driven |
| `*.ArchitectureTests` | whole module | NetArchTest rules |

`AssemblyReference.cs` (a `public static Assembly` marker) exists in Application and Presentation so the host and tests can scan those assemblies by type reference instead of string.

---

## 2. The enforced rules (from the architecture tests)

These are **executable** — they run in CI as xUnit tests using NetArchTest. Treat them as the contract.

### Layering (per module — `LayerTests`)
- Domain **must not** depend on Application, Infrastructure, or Presentation.
- Application **must not** depend on Infrastructure or Presentation.
- Presentation **must not** depend on Infrastructure.
- (Infrastructure is the composition layer and may see everything in its own module.)

### Module isolation (solution-level — `Evently.ArchitectureTests/ModuleTests`)
- A module's four assemblies (`Domain`, `Application`, `Presentation`, `Infrastructure`) **must not** depend on any **other** module's namespace…
- …**except** that assembly may depend on another module's `*.IntegrationEvents` namespace. That is the *only* sanctioned cross-module reference.

### Domain (`DomainTests`)
- Types implementing `IDomainEvent` / inheriting `DomainEvent` → **sealed**, name ends `DomainEvent`.
- Types inheriting `Entity` → have a **private parameterless** constructor, and **only private** constructors.

### Application (`ApplicationTests`)
- `ICommand` / `ICommand<T>` → sealed, name ends `Command`.
- `IQuery<T>` → sealed, name ends `Query`.
- Command/query handlers → **not public** (`internal`), **sealed**, name ends `CommandHandler` / `QueryHandler`.
- `AbstractValidator<T>` → not public, sealed, name ends `Validator`.
- Domain-event handlers → not public, sealed, name ends `DomainEventHandler`.

### Presentation (`PresentationTests`)
- Integration-event handlers → not public, sealed, name ends `IntegrationEventHandler`.

---

## 3. Request handling — the CQRS pipeline

Every use case is a MediatR request that returns a `Result` or `Result<T>`.

```
HTTP endpoint (minimal API)
  → ISender.Send(command/query)
    → ExceptionHandlingPipelineBehavior   (wraps unhandled exceptions in EventlyException)
    → RequestLoggingPipelineBehavior      (structured logs + OpenTelemetry tags, per module)
    → ValidationPipelineBehavior          (FluentValidation; failures → Result.Failure(ValidationError), no throw)
    → Handler
  → Result<T>
→ result.Match(Results.Ok, ApiResults.Problem)   → 200 or RFC 7231 ProblemDetails
```

**Registration** (`ApplicationConfiguration.AddApplication`): MediatR scans all module Application assemblies; the 3 behaviors are registered as open generics in that exact order; FluentValidation validators (including internal) are scanned from the same assemblies.

### Commands (write side)
`internal sealed class XCommandHandler(deps…) : ICommandHandler<XCommand, TResult>`
- Load aggregate(s) via **repository interface** (`IEventRepository.GetAsync`).
- Guard preconditions → return `Result.Failure<T>(SomeErrors.Xyz)` early.
- Call the aggregate's **factory or behavior method**, which itself returns `Result` and raises domain events.
- `repository.Insert(entity)` then `await unitOfWork.SaveChangesAsync(ct)`.
- `IUnitOfWork` is the module's `DbContext` (registered as `services.AddScoped<IUnitOfWork>(sp => sp.GetRequiredService<XDbContext>())`).

### Queries (read side)
`internal sealed class XQueryHandler(IDbConnectionFactory f) : IQueryHandler<XQuery, TResponse>`
- Opens a `DbConnection` and runs **hand-written SQL with Dapper**. No EF on the read path.
- Column aliases use `nameof(Response.Prop)` in raw string literals so renames stay compiler-checked.
- Returns `Result.Failure<T>(XErrors.NotFound(id))` when the row is absent (implicit conversion from `T?` → `Result<T>` handles the happy path).

### The Result / Error model
- `Result` / `Result<T>` — `IsSuccess`, `Error`. Accessing `.Value` on a failure throws (programmer error).
- `Error(Code, Description, ErrorType)` where `ErrorType ∈ {Failure, Validation, Problem, NotFound, Conflict}`.
- Errors are **defined once** as `static` members / factory methods in `Domain/<Aggregate>/<Aggregate>Errors.cs` (e.g. `EventErrors.NotFound(id)`, `EventErrors.NotDraft`).
- `ApiResults.Problem` maps `ErrorType` → HTTP status (400/404/409/500) + problem `type` URI; `ValidationError` carries a nested `errors` array.

---

## 4. Domain modeling conventions

`Event` aggregate is the canonical example:

- `public sealed class Event : Entity` with a **`private Event()`** constructor.
- All properties `{ get; private set; }`.
- Creation: `public static Result<Event> Create(...)` — validates invariants, `new Event { … }` via object initializer, `@event.Raise(new EventCreatedDomainEvent(@event.Id))`, returns the entity (implicit conversion to `Result<Event>`).
- State changes: instance methods (`Publish()`, `Reschedule(...)`, `Cancel(utcNow)`) that check current state, return `Result` on rule violations, mutate, and `Raise(...)` a domain event.
- Time is passed **in** (`Cancel(DateTime utcNow)`) or comes from `IDateTimeProvider` in the handler — never `DateTime.UtcNow` inside domain logic that needs testing.
- `Entity` keeps `_domainEvents`; `Raise` adds, `DomainEvents` exposes a copy, `ClearDomainEvents` empties (called by the outbox interceptor).

---

## 5. Persistence

- **PostgreSQL 17**, single database `evently`, **one schema per module** (`events`, `users`, `ticketing`, `attendance`).
- Each module: its own `DbContext : DbContext, IUnitOfWork`, `modelBuilder.HasDefaultSchema(Schemas.X)`, `UseSnakeCaseNamingConvention()`, per-schema `__EFMigrationsHistory` (`MigrationsHistoryTable(HistoryRepository.DefaultTableName, Schemas.X)`).
- Every module `DbContext.OnModelCreating` applies `OutboxMessageConfiguration`, `OutboxMessageConsumerConfiguration`, `InboxMessageConfiguration`, `InboxMessageConsumerConfiguration` plus its own entity configs.
- The `InsertOutboxMessagesInterceptor` (singleton) is added to every module's `DbContext` options.
- `DbSet`s are `internal`. EF configs and repositories are `internal sealed`.
- Migrations applied automatically in Development (`app.ApplyMigrations()`), which resolves every module `DbContext` and calls `Migrate()`.
- Read side gets connections from `IDbConnectionFactory` (over a shared `NpgsqlDataSource` singleton).
- **Carts** are the exception: stored only in Redis via `CartService` + `ICacheService`, 20-minute sliding expiration, key `carts:{customerId}`. No cart table.

---

## 6. Cross-module communication (the heart of the design)

Modules never call each other directly. Two async mechanisms, both backed by transactional in/outbox tables **per module**.

### 6a. Domain events (in-module, but the launchpad for integration events)

```
Handler saves aggregate
  → InsertOutboxMessagesInterceptor (SaveChangesAsync): pulls entity.DomainEvents,
    ClearDomainEvents(), serializes each to `<schema>.outbox_messages` IN THE SAME TRANSACTION
  → ProcessOutboxJob (Quartz, [DisallowConcurrentExecution], every 5s, batch 50,
    SELECT … WHERE processed_on_utc IS NULL ORDER BY occurred_on_utc LIMIT n FOR UPDATE)
      → deserialize → DomainEventHandlersFactory resolves IDomainEventHandler(s) from Application assembly
      → IdempotentDomainEventHandler<T> decorator: checks `outbox_message_consumers`
        (outbox_message_id, handler name); skips if present; runs decorated handler; records consumer
      → writes processed_on_utc / error back
```

Domain-event handlers (`Application/<Aggregate>/<UseCase>/<Event>DomainEventHandler.cs`, `internal sealed`) do one of:
- **Update a projection / read model** (e.g. Attendance `EventStatistics`).
- **Publish an integration event** via `IEventBus` (e.g. `EventPublishedDomainEventHandler` → builds `EventPublishedIntegrationEvent` from a `GetEventQuery` and publishes it).

### 6b. Integration events (module → module)

```
IEventBus.PublishAsync(integrationEvent)   → MassTransit IBus.Publish
   MassTransit transport = IN-MEMORY (course default; RabbitMQ is a later swap)
      → consuming module's IntegrationEventConsumer<T> (MassTransit IConsumer):
        writes raw event to <schema>.inbox_messages
      → ProcessInboxJob (Quartz, same batch/FOR UPDATE pattern):
          → IntegrationEventHandlersFactory resolves IIntegrationEventHandler(s) from Presentation assembly
          → IdempotentIntegrationEventHandler<T> decorator: `inbox_message_consumers` guard
          → handler typically does ISender.Send(new SomeCommand(...))
```

Integration-event handlers live in **`*.Presentation`** (`internal sealed`, `*IntegrationEventHandler`). Example: Attendance's `EventPublishedIntegrationEventHandler` receives `Events.IntegrationEvents.EventPublishedIntegrationEvent` and sends Attendance's own `CreateEventCommand` — so each module keeps its own local copy of the data it needs.

Consumer registration: `XModule.ConfigureConsumers` (a `static Action<IRegistrationConfigurator>`) is passed into `AddInfrastructure` from `Program.cs`.

### 6c. Sagas (orchestrated multi-module workflows)

`CancelEventSaga` (`Events.Presentation`, a `MassTransitStateMachine<CancelEventState>`) coordinates event cancellation:
`EventCanceledIntegrationEvent` → publish `EventCancellationStartedIntegrationEvent` → wait for **both** `EventPaymentsRefundedIntegrationEvent` (Ticketing) and `EventTicketsArchivedIntegrationEvent` (Ticketing) via a `CompositeEvent` → publish `EventCancellationCompletedIntegrationEvent` → `Finalize()`.
Saga state persisted in **Redis** (`.RedisRepository(redisConnectionString)`).

---

## 7. Composition root (`Program.cs`)

Order matters:
1. Serilog from config.
2. `AddExceptionHandler<GlobalExceptionHandler>` + ProblemDetails.
3. Swagger.
4. `AddApplication(moduleApplicationAssemblies)` — MediatR + validators + behaviors.
5. `AddInfrastructure(serviceName, [module ConfigureConsumers…], dbConn, redisConn)` — auth, MassTransit, Quartz, Redis cache, OpenTelemetry, `NpgsqlDataSource`, `IEventBus`, outbox interceptor.
6. Health checks (Npgsql, Redis, Keycloak).
7. `AddModuleConfiguration(["users","events","ticketing","attendance"])` — loads `modules.<name>.json` (+ `.Development`).
8. `AddEventsModule` / `AddUsersModule` / `AddTicketingModule` / `AddAttendanceModule` — each registers its domain-event handlers (with idempotent decorator via Scrutor `.Decorate`), integration-event handlers, `DbContext` + repos + options, and endpoints.
9. Pipeline: migrations (dev) → health → trace-logging middleware → Serilog request logging → exception handler → authentication → authorization → `MapEndpoints()`.

---

## 8. Security

- **Keycloak** (`Evently.Identity`, realm imported from `.files/evently-realm-export.json`), OIDC + JWT bearer.
- `Common.Infrastructure/Authentication` — `JwtBearerConfigureOptions`, `CustomClaims`, `ClaimsPrincipalExtensions`.
- `Common.Infrastructure/Authorization` — **permission-based**: `PermissionAuthorizationPolicyProvider` + `PermissionAuthorizationHandler` + `PermissionRequirement`, `CustomClaimsTransformation` loads the user's permissions (from the Users module via `IPermissionService`, cached).
- Endpoints declare `.RequireAuthorization(Permissions.ModifyEvents)` where `Permissions` is an `internal static class` of string constants like `"events:update"`, `"ticket-types:read"`.
- Users module owns `User`/`Role`/`Permission` and syncs to Keycloak through `IIdentityProviderService` → `KeyCloakClient` (with `KeyCloakAuthDelegatingHandler`).

---

## 9. Observability & scheduling

- **Serilog** → console + **Seq** (`localhost:5341` / UI `:8081`). `LogContextTraceLoggingMiddleware` pushes trace/span IDs; `RequestLoggingPipelineBehavior` pushes `Module` + request name.
- **OpenTelemetry** — ASP.NET Core, HttpClient, EF Core, Redis, Npgsql, MassTransit instrumentation; **OTLP exporter** → **Jaeger** (`:4317`, UI `:16686`).
- **Quartz** hosted service runs the outbox and inbox jobs for every module (interval + batch from `modules.<name>.json`).

---

## 10. Testing strategy

| Layer | Project(s) | Tooling | What's covered |
|---|---|---|---|
| Architecture | `*/…ArchitectureTests`, `test/Evently.ArchitectureTests` | NetArchTest + xUnit + FluentAssertions | Layering, module isolation, naming/sealing/visibility/ctor rules (§2) |
| Unit | `*/…UnitTests` | xUnit, FluentAssertions, Bogus `Faker` | Aggregate invariants, factory results, `AssertDomainEventWasPublished<T>` helper |
| Integration | `*/…IntegrationTests`, `test/Evently.IntegrationTests` | xUnit collection fixture, **Testcontainers** (Postgres, Redis, Keycloak), `WebApplicationFactory` | Full slice via `ISender`; `BaseIntegrationTest` exposes `Sender` + module `DbContext`; `CleanDatabaseAsync` truncates in FK order; `Poller` for eventual-consistency assertions |

Test method naming: `Should_<Outcome>_When<Condition>` (unit + integration); AAA comments (`// Arrange` / `// Act` / `// Assert`).

---

## 11. Build, style & tooling constraints

- The **reference repo** pins **`net8.0`** in `Directory.Build.props`. **Our build targets `net10.0`** — a deliberate, logged deviation (`docs/deviations-from-author.md`); the architecture is framework-agnostic, so everything else in this section carries over.
- `Nullable` enabled, `ImplicitUsings` enabled.
- **`TreatWarningsAsErrors` + `CodeAnalysisTreatWarningsAsErrors` + `EnforceCodeStyleInBuild` + `AnalysisMode=All` + `SonarAnalyzer.CSharp`** — a warning fails the build.
- `.editorconfig` (severity `error` on most): file-scoped namespaces; `using` outside namespace; System usings first; braces always; language keywords over BCL types; expression-bodied properties/accessors/operators/lambdas; `readonly` fields; no `this.`; no unused parameters; collection expressions (`[]`); `CA1515` (make public internal) disabled — public API surface is deliberately minimal, most types are `internal`.
- Primary constructors used pervasively for handlers/services (DI).
- JSON serialization for in/outbox uses **Newtonsoft** with `SerializerSettings.Instance` (`TypeNameHandling` for polymorphic `IDomainEvent`/`IIntegrationEvent`).

---

## 12. Anatomy of one vertical slice (copy this shape)

Feature: "Create Event" (a command). Files, in order of the dependency flow:

| # | File | Project | Rules |
|---|---|---|---|
| 1 | `Domain/Events/Event.cs` — `static Result<Event> Create(...)` + `Raise(new EventCreatedDomainEvent(Id))` | Domain | sealed, private ctor, invariants return `Result` |
| 2 | `Domain/Events/EventCreatedDomainEvent.cs` — `sealed record …(Guid EventId) : DomainEvent` | Domain | sealed, `DomainEvent` suffix |
| 3 | `Domain/Events/EventErrors.cs` — `static Error StartDateInPast …` | Domain | one place for error definitions |
| 4 | `Application/Events/CreateEvent/CreateEventCommand.cs` — `sealed record CreateEventCommand(...) : ICommand<Guid>` | Application | sealed, `Command` suffix |
| 5 | `…/CreateEventCommandValidator.cs` — `internal sealed : AbstractValidator<CreateEventCommand>` | Application | internal, sealed, `Validator` suffix |
| 6 | `…/CreateEventCommandHandler.cs` — `internal sealed : ICommandHandler<CreateEventCommand, Guid>` | Application | internal, sealed; repo + `IUnitOfWork`; returns `Result<Guid>` |
| 7 | (optional) `…/<Event>DomainEventHandler.cs` — projection or `IEventBus.PublishAsync` | Application | internal, sealed, `DomainEventHandler` suffix |
| 8 | `Presentation/Events/CreateEvent.cs` — `internal sealed : IEndpoint`, `MapPost("events", …)`, `result.Match(Results.Ok, ApiResults.Problem)`, `.RequireAuthorization(Permissions.ModifyEvents)`, `.WithTags(Tags.Events)` | Presentation | internal, sealed; nested `Request` type |
| 9 | If other modules care: add `<Event>IntegrationEvent.cs` to `*.IntegrationEvents`; publish from the domain-event handler | IntegrationEvents | plain record : `IntegrationEvent` |
| 10 | Tests: `UnitTests/Events/EventTests.cs` (aggregate), `IntegrationTests/Events/CreateEventTests.cs` (`ISender`) | tests | `Should_…_When…` |

A **query** slice is smaller: `Application/<Aggregate>/<UseCase>/<UseCase>Query.cs` (`sealed record : IQuery<T>`), `<UseCase>QueryHandler.cs` (`internal sealed`, Dapper via `IDbConnectionFactory`), `<X>Response.cs`, `Presentation/<UseCase>.cs`.

---

## 13. Glossary of the key abstractions

| Type | Project | Role |
|---|---|---|
| `Entity` | Common.Domain | Base for aggregates; owns domain events |
| `DomainEvent` / `IDomainEvent` | Common.Domain | In-module event; sealed subclasses |
| `Result` / `Result<T>` / `Error` / `ErrorType` / `ValidationError` | Common.Domain | Railway-oriented flow control |
| `ICommand` / `ICommand<T>` / `IQuery<T>` + handlers | Common.Application | CQRS contracts (MediatR) |
| `IDomainEventHandler<T>` / `DomainEventHandler<T>` | Common.Application | Reacts to domain events (in Application) |
| `IIntegrationEvent` / `IntegrationEvent` / `IIntegrationEventHandler<T>` | Common.Application | Cross-module contract + reaction (handlers in Presentation) |
| `IEventBus` | Common.Application (impl in Infrastructure) | Thin wrapper over MassTransit `IBus.Publish` |
| `IUnitOfWork` | per-module Application | The module `DbContext`, for `SaveChangesAsync` |
| `IDbConnectionFactory` | Common.Application | Read-side raw connections (Dapper) |
| `ICacheService` | Common.Application | Redis / distributed cache |
| `IDateTimeProvider` | Common.Application | Testable clock |
| `IEndpoint` | Common.Presentation | One minimal-API endpoint; auto-discovered |
| `ApiResults.Problem` / `ResultExtensions.Match` | Common.Presentation | `Result` → `IResult` |
| `InsertOutboxMessagesInterceptor` | Common.Infrastructure | Domain events → outbox, same transaction |
| `ProcessOutboxJob` / `ProcessInboxJob` | per-module Infrastructure | Quartz dispatchers |
| `IdempotentDomainEventHandler<T>` / `IdempotentIntegrationEventHandler<T>` | per-module Infrastructure | Once-only delivery via consumer tables |
| `XModule` (`AddXModule`, `ConfigureConsumers`) | per-module Infrastructure | Module DI entry point |
