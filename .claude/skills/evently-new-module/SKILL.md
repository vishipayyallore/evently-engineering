---
name: evently-new-module
description: Scaffold a brand-new module in the Evently modular monolith in this repo (C:\GitHub\evently-learning-tracker) with the full Domain/Application/Infrastructure/Presentation/IntegrationEvents project set, DbContext, schema, outbox+inbox, DI entry point, and test projects. Use only when the task explicitly asks to add a new bounded context / module to Evently.
---

# Scaffold a new Evently module

Work in `C:\GitHub\evently-learning-tracker`. This is a large, architecture-level change — confirm
scope and the module's responsibility with the user (or the `architect` agent) **before**
starting. Rules R1, R2, R5 in [`.claude/rules/evently-engineering-rules.md`](../../rules/evently-engineering-rules.md).
Use `docs/architecture/evently-deep-dive.md` as a reference when the author's pattern helps clarify the design.

Use an existing module as the template. **`Users` is the smallest**; `Events` is the most
representative of a full CRUD+events module. Copy its structure, don't invent one.

## 1. Projects (under `src/Modules/<NewModule>/`)

Create these, matching the target-framework and analyzer setup that `Directory.Build.props`
already supplies (the `.csproj` files are tiny — just `<Project Sdk="Microsoft.NET.Sdk">` +
references):

| Project | References |
|---|---|
| `Evently.Modules.<NewModule>.Domain` | `Common.Domain` |
| `Evently.Modules.<NewModule>.Application` | `Common.Application`, `.Domain` |
| `Evently.Modules.<NewModule>.IntegrationEvents` | `Common.Application` |
| `Evently.Modules.<NewModule>.Infrastructure` | `Common.Infrastructure`, `.Application`, `.Presentation` |
| `Evently.Modules.<NewModule>.Presentation` | `Common.Presentation`, `.Application` |
| `Evently.Modules.<NewModule>.UnitTests` | `.Domain`, `.Application` + xUnit/FluentAssertions/Bogus |
| `Evently.Modules.<NewModule>.IntegrationTests` | whole module + `Evently.Api` + Testcontainers |
| `Evently.Modules.<NewModule>.ArchitectureTests` | whole module + NetArchTest |

Add all of them to `Evently.sln` (`dotnet sln add`), inside a solution folder
`src/Modules/<NewModule>`.

## 2. Required boilerplate (copy + rename from `Events`)

- `Application/AssemblyReference.cs` and `Presentation/AssemblyReference.cs` (`public static Assembly`).
- `Application/Abstractions/Data/IUnitOfWork.cs`.
- `Infrastructure/Database/<NewModule>DbContext.cs` — `sealed : DbContext, IUnitOfWork`,
  `HasDefaultSchema(Schemas.<NewModule>)`, `UseSnakeCaseNamingConvention`, applies the four
  outbox/inbox configs.
- `Infrastructure/Database/Schemas.cs` — `internal const string <NewModule> = "<newmodule>";`
- `Infrastructure/Outbox/` + `Infrastructure/Inbox/` — copy `ConfigureProcessOutboxJob`,
  `ProcessOutboxJob`, `OutboxOptions`, `IdempotentDomainEventHandler`, and the inbox
  equivalents; change the `ModuleName` const and the schema in the SQL.
- `Infrastructure/<NewModule>Module.cs` — `Add<NewModule>Module(IConfiguration)` +
  `ConfigureConsumers`, following `EventsModule` exactly (domain-event handler scan +
  `.Decorate`, integration-event handler scan + `.Decorate`, `AddDbContext` with the
  `InsertOutboxMessagesInterceptor`, repos, `IUnitOfWork` → `DbContext`, options from
  `<NewModule>:Outbox` / `<NewModule>:Inbox`, `AddEndpoints`).
- `Presentation/Permissions.cs`, `Presentation/Tags.cs`.

## 3. Wire into the host

In `src/API/Evently.Api/Program.cs`:
- add `Evently.Modules.<NewModule>.Application.AssemblyReference.Assembly` to
  `moduleApplicationAssemblies`;
- add `<NewModule>Module.ConfigureConsumers` to the `AddInfrastructure` consumer list;
- add `"<newmodule>"` to `AddModuleConfiguration([...])`;
- add `builder.Services.Add<NewModule>Module(builder.Configuration);`.

Create `src/API/Evently.Api/modules.<newmodule>.json` (+ `.Development.json`) with
`Outbox`/`Inbox` `IntervalInSeconds` + `BatchSize` (copy `modules.events.json`).

Add `Evently.Api.csproj` project reference to `Evently.Modules.<NewModule>.Infrastructure`.

## 4. Initial migration

```
dotnet ef migrations add Create_Database --project src/Modules/<NewModule>/Evently.Modules.<NewModule>.Infrastructure --startup-project src/API/Evently.Api
```

## 5. Architecture tests

Copy the `Events.ArchitectureTests` `Abstractions/BaseTest.cs` + `Layers`/`Domain`/
`Application`/`Presentation` test classes, re-point the assembly references. Add the new
module to `test/Evently.ArchitectureTests/Layers/ModuleTests.cs` (isolation assertions both
ways).

## 6. Validate

```
dotnet build Evently.sln
dotnet test Evently.sln
```
