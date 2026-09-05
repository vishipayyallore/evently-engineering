# Copilot Instructions — Evently

## Workspace purpose

This repository is the Evently implementation and the single source of truth. We build it
here, on **.NET 10**, working through the *Modular Monolith Architecture* course. It is
currently greenfield — `src/` and `test/` are empty; early tasks scaffold the solution.

`AGENTS.md` is the authoritative workspace guide, including the decisions still open. A
read-only reference implementation may be configured as an extra directory in
`.claude/settings.local.json` — consult it for patterns, never modify it.

## Canonical guidance (read these first)

| File | What it is |
|---|---|
| `AGENTS.md` | How we work; decisions still open |
| `docs/architecture/evently-deep-dive.md` | Architecture reference — the design patterns to follow |
| `docs/deviations-from-author.md` | Running log of deliberate departures from the course |
| `.claude/rules/evently-engineering-rules.md` | R1–R10, the coding contract |
| `.claude/skills/evently-vertical-slice/SKILL.md` | Add a command/query use case end-to-end |
| `.claude/skills/evently-integration-event/SKILL.md` | Wire cross-module messaging |
| `.claude/skills/evently-new-module/SKILL.md` | Scaffold a new module |
| `.github/agents/architect.agent.md` | Architect role — design/boundary decisions before code |
| `.github/agents/principal-engineer.agent.md` | Sr. Principal Engineer role — implementation + review |

These `.github/*` files mirror the `.claude/*` versions; the `.claude/*` copies are canonical.

## Architecture baseline

Modular monolith, one deployable (`src/API/Evently.Api`), four modules — **Events, Users,
Ticketing, Attendance** — isolated at the assembly and DB-schema level.

Hard rules (to be enforced by NetArchTest + `TreatWarningsAsErrors`):
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
- Domain aggregates: `sealed`, private constructors only, created via a `static` factory
  (`Result<T>` when creation can fail, else the entity), mutated via methods that raise domain
  events.
- Default every new type to `internal` + `sealed`. Handlers/validators/event handlers follow
  strict naming (`*CommandHandler`, `*QueryHandler`, `*Validator`, `*DomainEventHandler`,
  `*IntegrationEventHandler`).

## Build & validation

Target **.NET 10**. Once the solution exists, validate from the repo root:

```
dotnet build Evently.sln
dotnet test Evently.sln
```

A build **warning is an error** (SonarAnalyzer + .NET analyzers, `AnalysisMode=All`). Fix the
cause, never suppress.
