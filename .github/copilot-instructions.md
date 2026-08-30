# Copilot Instructions — Evently Learning Tracker

## Workspace purpose

This repo is a **learning tracker**: notes, task checklists, architecture analysis, and
AI-assist configuration for building Evently. It has no application code. The canonical
Evently implementation is the sibling repo at `../evently_source_code` (Milan Jovanović's
*Modular Monolith Architecture* course codebase).

**All production code work happens in `../evently_source_code`**, not here — unless a task
explicitly says to work in the tracker. Summaries here point back to source files rather than
duplicating implementation code.

## Canonical guidance (read these first)

| File | What it is |
|---|---|
| `docs/architecture/evently-deep-dive.md` | Full architecture analysis of the source repo — layering, CQRS pipeline, outbox/inbox, sagas, testing, style |
| `.claude/rules/evently-engineering-rules.md` | R1–R10, the enforced coding contract (each rule maps to an architecture test or a compiler setting) |
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

## Build & validation (run in `../evently_source_code`)

```
dotnet build Evently.sln
dotnet test Evently.sln          # includes architecture + integration tests — must be green
```

⚠️ **Target framework:** the source repo's `Directory.Build.props` currently pins
`net8.0`, while the installed SDK is 10.x and `AGENTS.md` refers to a ".NET 10 workstream".
Confirm the actual project configuration before changing any `TargetFramework` or SDK setting.

A build **warning is an error** (SonarAnalyzer + .NET analyzers, `AnalysisMode=All`). Fix the
cause, never suppress.
