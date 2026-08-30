---
name: evently-vertical-slice
description: Add a new use case (command or query) to an Evently module end-to-end in the active repo (C:\GitHub\evently-learning-tracker). Use when the task is "add an endpoint / feature / command / query" to Events, Users, Ticketing, or Attendance, or asks to implement a CQRS slice following Evently conventions.
---

# Add a vertical slice to an Evently module

Work in `C:\GitHub\evently-learning-tracker`. Follow [`.claude/rules/evently-engineering-rules.md`](../../rules/evently-engineering-rules.md)
(rules R3–R6, R8, R9). Reference: `docs/architecture/evently-deep-dive.md` §12 for the slice anatomy.

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
| `<X>DomainEvent.cs` | `*.Domain/<Aggregate>/` | `public sealed record <X>DomainEvent(Guid <Agg>Id) : DomainEvent;` |
| new errors | `*.Domain/<Aggregate>/<Aggregate>Errors.cs` | `public static readonly Error <Name> = Error.Problem("<Agg>.<Name>", "...");` |
| `<UseCase>.cs` endpoint | `*.Presentation/<Aggregate>/` | `internal sealed class <UseCase> : IEndpoint` (see §5) |

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
For "create" use cases: `<Aggregate>.Create(...)` → `repository.Insert(result.Value)` → `SaveChangesAsync`.

## 4. Query slice — files to create

| File | Location | Template |
|---|---|---|
| `<UseCase>Query.cs` | `*.Application/<Aggregate>/<UseCase>/` | `public sealed record <UseCase>Query(Guid Id) : IQuery<<X>Response>;` |
| `<X>Response.cs` | same folder | `public sealed class <X>Response { ... }` (or record) |
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

## 8. Validate

```
dotnet build Evently.sln
dotnet test --filter "FullyQualifiedName~Evently.Modules.<Module>"
dotnet test Evently.sln
```
All green — including the architecture tests (naming, sealed, internal, layering).
