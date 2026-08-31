# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

This is where **we build Evently** while working through the *Modular Monolith Architecture*
course. It is the implementation and the **single source of truth** — all code, tests, and
docs live here. Target framework: **.NET 10**.

Right now it is greenfield: `src/` and `tests/` hold only `.gitkeep`. Early tasks will
scaffold the solution.

`AGENTS.md` is the authoritative workspace guide — **read it first**. It covers how we work
against the course and the decisions still open. The points below are Claude-specific detail.

## Local reference implementation

A read-only reference implementation may be configured as an extra directory in
`.claude/settings.local.json`. When present, consult it to see how a given slice is built, then
implement our version here on .NET 10.

- Never edit it. Never run `dotnet build` / `dotnet test` / `dotnet ef` inside it.
- Expect to diverge from it (framework, and other choices). Log meaningful deviations in
  `docs/deviations-from-author.md`.

## Assist artifacts

- `docs/architecture/evently-deep-dive.md` — the architecture reference (layering, CQRS
  pipeline, outbox/inbox, sagas, testing, style). Read before implementing a non-trivial slice.
- `docs/deviations-from-author.md` — running log of deliberate departures from the course.
- `.claude/rules/evently-engineering-rules.md` — R1–R10, the coding contract. Each rule is
  meant to be backed by an architecture test; we add those tests as we build.
- `.claude/skills/` — `evently-vertical-slice` (add a command/query end-to-end),
  `evently-integration-event` (cross-module messaging), `evently-new-module` (scaffold a
  module).
- `.claude/agents/` — `architect` (design/boundary decisions, plans — run before cross-module
  or `Common.*` changes) and `principal-engineer` (implementation + review).
- `.github/` mirrors the above for GitHub Copilot; the `.claude/` copies are canonical.

## Build & validate

Once the solution exists:

```
dotnet build Evently.sln
dotnet test Evently.sln
dotnet test --filter "FullyQualifiedName~Evently.Modules.Events.UnitTests"   # one project
```

Local infra (Postgres, Redis, Keycloak, Seq, Jaeger) will come via `docker compose` when we
get there.

## Target architecture (what we're building toward)

Modular monolith, one deployable API, isolated modules (Events, Users, Ticketing,
Attendance), each `Domain → Application → Infrastructure → Presentation` + an
`IntegrationEvents` contract project. Modules communicate only via `*.IntegrationEvents` and
async messaging (domain event → outbox → integration event → inbox). Write path = EF + repo +
`IUnitOfWork`; read path = Dapper + `IDbConnectionFactory`. Every use case returns
`Result` / `Result<T>`. Details: `docs/architecture/evently-deep-dive.md`.

## Open decisions

See `AGENTS.md` → "Decisions still open". Defaults: the layout and naming there, faithful
.NET 10 port, same library stack (MediatR/FluentValidation/MassTransit/Dapper/Quartz/Serilog).
If a task turns on an undecided point, ask.
