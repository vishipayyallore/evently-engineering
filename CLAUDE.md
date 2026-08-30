# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

`C:\GitHub\evently-learning-tracker` is where **we build Evently** while following the
*Modular Monolith Architecture* video course. It is the implementation and the **single
source of truth** — all code, tests, and docs live here. Target framework: **.NET 10**.

Right now it is greenfield: `src/` and `tests/` hold only `.gitkeep`. Early tasks will
scaffold the solution.

`AGENTS.md` is the authoritative workspace guide — **read it first**. It covers the two-repo
setup, how we work against the course, and the decisions still open. The points below are
Claude-specific detail.

## The reference repo — `C:\GitHub\evently_source_code`

The **author's** implementation, on **.NET 8**. Granted as a read directory in
`.claude/settings.json`. Use it **read-only** to see how the author built a given slice, then
implement our version here on .NET 10.

- Never edit it. Never run `dotnet build` / `dotnet test` / `dotnet ef` inside it.
- Expect to deviate from it (framework, and other choices). Log meaningful deviations in
  `docs/deviations-from-author.md`.

## Assist artifacts

- `docs/architecture/evently-deep-dive.md` — full analysis of the reference design (layering,
  CQRS pipeline, outbox/inbox, sagas, testing, style). Read before implementing a non-trivial
  slice. Describes the author's .NET 8 code; we adapt it to .NET 10 here.
- `docs/deviations-from-author.md` — running log of where our build differs from the course.
- `.claude/rules/evently-engineering-rules.md` — R1–R10, the coding contract. In the
  reference repo every rule is backed by an architecture test; we bring those tests over as
  we build.
- `.claude/skills/` — `evently-vertical-slice` (add a command/query end-to-end),
  `evently-integration-event` (cross-module messaging), `evently-new-module` (scaffold a
  module).
- `.claude/agents/` — `architect` (design/boundary decisions, plans — run before cross-module
  or `Common.*` changes) and `principal-engineer` (implementation + review).
- `.github/` mirrors the above for GitHub Copilot; the `.claude/` copies are canonical.

## Build & validate (in this repo)

Once the solution exists:

```
dotnet build Evently.sln
dotnet test Evently.sln
dotnet test --filter "FullyQualifiedName~Evently.Modules.Events.UnitTests"   # one project
```

Infrastructure for local runs (Postgres, Redis, Keycloak, Seq, Jaeger) will come via
`docker compose` — mirror the reference repo's `docker-compose.yml` when we get there.

## Target architecture (what we're building toward)

Modular monolith, one deployable API, isolated modules (Events, Users, Ticketing,
Attendance), each `Domain → Application → Infrastructure → Presentation` + an
`IntegrationEvents` contract project. Modules communicate only via `*.IntegrationEvents` and
async messaging (domain event → outbox → integration event → inbox). Write path = EF + repo +
`IUnitOfWork`; read path = Dapper + `IDbConnectionFactory`. Every use case returns
`Result` / `Result<T>`. Details: `docs/architecture/evently-deep-dive.md`.

## Open decisions

See `AGENTS.md` → "Decisions still open". Default: mirror the author's layout and `Evently`
naming, faithful .NET 10 port, same library stack (MediatR/FluentValidation/MassTransit/
Dapper/Quartz/Serilog). If a task turns on an undecided point, ask.
