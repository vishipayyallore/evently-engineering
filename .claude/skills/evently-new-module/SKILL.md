---
name: evently-new-module
description: Scaffold a brand-new Evently module (bounded context) — the full Domain/Application/Infrastructure/Presentation/IntegrationEvents project set, DbContext, schema, outbox+inbox, DI entry point, host wiring, and test projects. Use only when the task explicitly asks to add a new module / bounded context. Not for adding a use case to an existing module (use evently-vertical-slice).
---

# Scaffold a new Evently module

Work in this repo. Rules R1, R2, R5 in
[`.claude/rules/evently-engineering-rules.md`](../../rules/evently-engineering-rules.md).
See `docs/architecture/evently-deep-dive.md` §1, §5, §7 for the module structure and wiring.

> **Build phase.** Separate module projects are **[Phase 2]** (module code organization). In
> Phase 1 a bounded context is a **folder** inside `Evently.Api`, not a project set — only run
> this skill once we start modularizing. Numbered steps below start at 1, never 0.

Use an existing module as the template. **`Users` is the smallest**; `Events` is the most
representative of a full CRUD+events module. Copy its structure, don't invent one.

## Not this skill — do these first

- **Confirm the module is justified.** A new module is an architecture decision: its
  responsibility statement, its boundary, and its integration surface must be agreed with the
  user or the `architect` agent **before** you scaffold. If that hasn't happened, stop and ask.
- **Adding a feature to an existing module** → `evently-vertical-slice`.
- **Cross-module messaging for the new module** → scaffold here first, then `evently-integration-event`.
- **The `Common.*` layer or solution layout doesn't exist yet** (still greenfield) → the
  solution itself needs scaffolding first; that's a separate, larger task — ask.

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

## Done when

- [ ] All 8 projects created, added to `Evently.sln` under a `src/Modules/<NewModule>` solution
      folder, with the reference graph in §1.
- [ ] Boilerplate copied and renamed from the template module (§2): `AssemblyReference`,
      `IUnitOfWork`, `<NewModule>DbContext`, `Schemas`, outbox/inbox jobs + idempotent
      decorators, `<NewModule>Module`, `Permissions`, `Tags`.
- [ ] Host wired (§3): application assembly, `ConfigureConsumers`, `AddModuleConfiguration`,
      `Add<NewModule>Module`, `modules.<newmodule>.json` (+ `.Development`), `Evently.Api`
      project reference.
- [ ] `Create_Database` migration generated.
- [ ] Architecture tests copied and re-pointed; new module added to
      `test/Evently.ArchitectureTests/Layers/ModuleTests.cs` (isolation both ways).
- [ ] `dotnet build Evently.sln` — 0 warnings.
- [ ] `dotnet test Evently.sln` green, including the new module's architecture tests.
- [ ] Report: projects added, host files changed, migration name, test output.
