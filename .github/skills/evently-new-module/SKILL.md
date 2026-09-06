# evently-new-module

Scaffold a brand-new module (bounded context) in the Evently modular monolith
(`C:\GitHub\evently-engineering`) with the full project set, `DbContext`, schema, outbox/inbox, DI
entry point, and test projects.

**Canonical, full instructions:** [`.claude/skills/evently-new-module/SKILL.md`](../../../.claude/skills/evently-new-module/SKILL.md)

> **Build phase.** Separate module projects are **[Phase 2]**. In Phase 1 a bounded context is
> a **folder** in `Evently.Api`, not a project set — only run this once modularizing. Steps
> start at 1, never 0.

Architecture-level change — the module's responsibility, boundary, and integration surface
must be agreed with the user / `architect` agent first **and recorded as an ADR in
`docs/ADRs/`** (the `architect` drafts it). Copy an existing module (`Users` is smallest,
`Events` most representative); don't invent a structure.

Steps: create the 8 projects under `src/Modules/<NewModule>/` (Domain, Application,
IntegrationEvents, Infrastructure, Presentation, UnitTests, IntegrationTests,
ArchitectureTests) and add them to `Evently.sln`; copy + rename the boilerplate
(`AssemblyReference`, `IUnitOfWork`, `DbContext`, `Schemas`, outbox/inbox jobs + idempotent
decorators, `<NewModule>Module` DI entry point, `Permissions`, `Tags`); wire into
`Program.cs` (application assembly, `ConfigureConsumers`, `AddModuleConfiguration`,
`Add<NewModule>Module`) and add `modules.<newmodule>.json`; add the `Evently.Api` project
reference; create the initial `Create_Database` migration; copy the architecture tests and
add the module to `test/Evently.ArchitectureTests/Layers/ModuleTests.cs`; add the module box
+ its integration edges to `docs/mermaid-diagrams/system-context.mmd` and regenerate
(`pwsh scripts/export-mermaid.ps1`). Validate with `dotnet build Evently.sln` &&
`dotnet test Evently.sln`. Report includes the ADR.
