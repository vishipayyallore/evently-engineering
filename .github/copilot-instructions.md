# Copilot Instructions — Evently Learning Tracker

## Workspace purpose

This repo is the active Evently learning implementation. It is the single source of truth for
our work in this project, and we are building it in .NET 10 here.

The sibling repo at `../evently_source_code` is the author's reference implementation. It is kept
for comparison, pattern analysis, and course study. We do not treat it as the active repository
for this project unless a task specifically asks to inspect it.

Summaries here point back to source files in this repo and to the reference repo only where it helps
explain architecture or differences.

## Canonical guidance (read these first)

| File | What it is |
|---|---|
| `docs/architecture/evently-deep-dive.md` | Architecture analysis of the author's repo — useful reference for the design patterns |
| `.claude/rules/evently-engineering-rules.md` | R1–R10, the enforced coding contract we adapt in this repo |
| `.claude/skills/evently-vertical-slice/SKILL.md` | Add a command/query use case end-to-end |
| `.claude/skills/evently-integration-event/SKILL.md` | Wire cross-module messaging |
| `.claude/skills/evently-new-module/SKILL.md` | Scaffold a new module |
| `.github/agents/architect.agent.md` | Architect role — design/boundary decisions before code |
| `.github/agents/principal-engineer.agent.md` | Sr. Principal Engineer role — implementation + review |

These `.github/*` files mirror the `.claude/*` versions; the `.claude/*` copies are canonical.

## Architecture baseline

Modular monolith, one deployable (`src/API/Evently.Api`), four modules — **Users, Events,
Ticketing, Attendance** — isolated at the assembly and DB-schema level.

Hard rules (enforced by NetArchTest + `TreatWarningsAsErrors`):
- Dependency flow per module: **Domain → Application → Infrastructure / Presentation**.
  Domain depends on nothing but `Common.Domain`. Application never references Infrastructure
  or Presentation.
- **No module references another module** except its `*.IntegrationEvents` contract assembly.
- Cross-module effects are async: publish an integration event (from a domain-event handler,
  via the outbox); the other module consumes it (inbox) and keeps its own local copy.
- Write path = EF + repository + `IUnitOfWork`. Read path = Dapper + `IDbConnectionFactory`
  (no EF).
- Every use case returns `Result` / `Result<T>`; business-rule failures are typed `Error`s,
  never exceptions.
- Domain aggregates: `sealed`, private constructors only, created via `static Result<T> Create`,
  mutated via methods that raise domain events.
- Default every new type to `internal` + `sealed`. Handlers/validators/event handlers follow
  strict naming (`*CommandHandler`, `*QueryHandler`, `*Validator`, `*DomainEventHandler`,
  `*IntegrationEventHandler`).

## Build & validation

Use the .NET 10 workstream for this repository, and validate from the working repo root:

```
dotnet restore
dotnet build
dotnet test
```

When comparing with the author's repo, use it as a learning reference only. If the author's repo
shows a different target framework or a different implementation detail, we keep the working repo as
our active system of record unless a deliberate decision is made to diverge.

A build **warning is an error** (SonarAnalyzer + .NET analyzers, `AnalysisMode=All`). Fix the
cause, never suppress.
