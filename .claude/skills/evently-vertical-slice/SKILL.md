---
name: evently-vertical-slice
description: Add ONE use case (a command or a query) to an existing Evently module, end to end — Domain → Application → Presentation → tests. Use when the task is "add an endpoint / feature / command / query" to Events, Users, Ticketing, or Attendance. Not for creating a new module (use evently-new-module) or cross-module messaging (use evently-integration-event).
---

# Add a vertical slice to an Evently module

Work in this repo. Follow [`.claude/rules/evently-engineering-rules.md`](../../rules/evently-engineering-rules.md)
(rules R3–R6, R8, R9). Reference: `docs/architecture/evently-deep-dive.md` §12 for the slice anatomy.

> **Build phase.** This slice pattern applies from **Phase 1** (monolith). In Phase 1 a module
> is a **folder**, not a project — use the same Domain/Application/Presentation layout under
> `src/…` folders, and skip the cross-module integration-event step (the `*.IntegrationEvents`
> project in §9), which is **[Phase 2]**. Numbered steps below start at 1, never 0.

## Not this skill

- **New module / bounded context** → `evently-new-module`.
- **An effect in another module** (publish/consume an integration event) → `evently-integration-event`.
- **The target module or aggregate doesn't exist yet** → stop; that's an architecture
  decision — ask for the `architect` agent.
- **A still-open decision applies** (project layout, `Evently` naming, a library swap — see
  `AGENTS.md`) → ask before proceeding.
- This skill adds exactly one use case. Multiple related use cases = run it once per slice.

## 1. Decide command vs query

- **Command** — changes state. Returns `Result` or `Result<T>` (usually the new id). Goes
  through EF + repository + `IUnitOfWork`.
- **Query** — reads. Returns `Result<TResponse>`. Goes through `IDbConnectionFactory` + Dapper.
  No EF.

## 2. Locate the module and aggregate

`src/Modules/<Module>/`. Find the aggregate folder under `*.Domain/<Aggregate>/` and the
existing sibling use cases under `*.Application/<Aggregate>/` — copy the closest one's shape.

## 3. Command slice — files to create

| File | Location | Template |
|---|---|---|
| `<UseCase>Command.cs` | `*.Application/<Aggregate>/<UseCase>/` | `public sealed record <UseCase>Command(...) : ICommand<Guid>;` |
| `<UseCase>CommandValidator.cs` | same folder | `internal sealed class <UseCase>CommandValidator : AbstractValidator<<UseCase>Command>` — structural rules only |
| `<UseCase>CommandHandler.cs` | same folder | `internal sealed class <UseCase>CommandHandler(<deps>) : ICommandHandler<<UseCase>Command, Guid>` |
| aggregate method / factory | `*.Domain/<Aggregate>/<Aggregate>.cs` | returns `Result` / `Result<T>`, `Raise(new <X>DomainEvent(...))` |
| `<X>DomainEvent.cs` | `*.Domain/<Aggregate>/` | `public sealed class <X>DomainEvent(Guid <Agg>Id) : DomainEvent { public Guid <Agg>Id { get; init; } = <agg>Id; }` |
| new errors | `*.Domain/<Aggregate>/<Aggregate>Errors.cs` | `public static readonly Error <Name> = Error.Problem("<Agg>.<Name>", "...");` |
| `<UseCase>.cs` endpoint | `*.Presentation/<Aggregate>/` | `internal sealed class <UseCase> : IEndpoint` (see §5) |

Pick the `ErrorType` that fits each failure (R3.5) — `Error.Validation` / `Error.NotFound` /
`Error.Conflict` / `Error.Failure`, not `Error.Problem` for everything; it drives the HTTP
status `ApiResults.Problem` returns.

Handler body pattern:
```csharp
public async Task<Result<Guid>> Handle(<UseCase>Command request, CancellationToken cancellationToken)
{
    <Aggregate>? entity = await <agg>Repository.GetAsync(request.Id, cancellationToken);
    if (entity is null)
        return Result.Failure<Guid>(<Aggregate>Errors.NotFound(request.Id));

    Result result = entity.<Behavior>(...);        // aggregate enforces the invariant
    if (result.IsFailure)
        return Result.Failure<Guid>(result.Error);

    await unitOfWork.SaveChangesAsync(cancellationToken);
    return entity.Id;
}
```
For "create" use cases: `<Aggregate>.Create(...)` → `repository.Insert(result.Value)` → `SaveChangesAsync`
(if the factory can't fail it returns the entity directly, not a `Result` — skip the `.IsFailure` check).

## 4. Query slice — files to create

| File | Location | Template |
|---|---|---|
| `<UseCase>Query.cs` | `*.Application/<Aggregate>/<UseCase>/` | `public sealed record <UseCase>Query(Guid Id) : IQuery<<X>Response>;` |
| `<X>Response.cs` | same folder | `public sealed record <X>Response(...);` (nested collections as `{ get; } = [];` on the record body) |
| `<UseCase>QueryHandler.cs` | same folder | `internal sealed class <UseCase>QueryHandler(IDbConnectionFactory dbConnectionFactory) : IQueryHandler<<UseCase>Query, <X>Response>` |
| `<UseCase>.cs` endpoint | `*.Presentation/<Aggregate>/` | see §5 |

Handler body: open connection, `const string sql = $"""... {nameof(<X>Response.Prop)} ..."""`,
`connection.QueryAsync/QueryFirstOrDefaultAsync`, return `Result.Failure<<X>Response>(<Aggregate>Errors.NotFound(id))` when missing.

## 5. Endpoint template

```csharp
internal sealed class <UseCase> : IEndpoint
{
    public void MapEndpoint(IEndpointRouteBuilder app)
    {
        app.MapPost("<resource>", async (Request request, ISender sender) =>
        {
            Result<Guid> result = await sender.Send(new <UseCase>Command(request.Field));
            return result.Match(Results.Ok, ApiResults.Problem);
        })
        .RequireAuthorization(Permissions.<Perm>)
        .WithTags(Tags.<Tag>);
    }

    internal sealed class Request { public string Field { get; init; } }
}
```
Add `Permissions.<Perm>` (`"<resource>:<action>"`) and `Tags.<Tag>` if they don't exist.

## 6. Tests

- Aggregate behavior → `*.UnitTests/<Aggregate>/<Aggregate>Tests.cs`:
  `Should_<Outcome>_When<Condition>`, `Faker`, `AssertDomainEventWasPublished<T>`.
- Slice → `*.IntegrationTests/<Aggregate>/<UseCase>Tests.cs` extending `BaseIntegrationTest`,
  driven via `Sender.Send(...)`; call `CleanDatabaseAsync()` in the happy-path test.

## 7. Migration (only if an entity config or `DbSet` changed)

```
dotnet ef migrations add <Name> --project src/Modules/<Module>/Evently.Modules.<Module>.Infrastructure --startup-project src/API/Evently.Api
```

## Done when

- [ ] Command/query, handler, validator (command only), endpoint created in the folders above,
      matching a sibling slice's shape.
- [ ] Invariants + domain events live on the aggregate; failures are `Error`s from
      `<Aggregate>Errors.cs`; handler returns `Result` and never throws for expected failures.
- [ ] Endpoint ends with `result.Match(...)`, has `.RequireAuthorization` + `.WithTags`.
- [ ] Unit test for new aggregate behavior; integration test through `ISender`.
- [ ] Migration added iff an entity config / `DbSet` changed.
- [ ] `dotnet build Evently.sln` — 0 warnings.
- [ ] `dotnet test Evently.sln` green, **including** the architecture tests (naming, sealed,
      `internal`, layering).
- [ ] Report: files added, rule numbers satisfied, migration y/n, test output.
