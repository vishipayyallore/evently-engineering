# Evently

[![Architecture](https://img.shields.io/badge/architecture-modular%20monolith-4B0082?style=flat)](README.md)
[![Domain](https://img.shields.io/badge/domain-driven%20design-00C853?style=flat)](README.md)
[![Platform](https://img.shields.io/badge/platform-.NET%2010-512BD4?style=flat)](README.md)
[![Events](https://img.shields.io/badge/events-async%20integration-FF6D00?style=flat)](README.md)
[![CQRS](https://img.shields.io/badge/pattern-CQRS-1565C0?style=flat)](README.md)
[![Database](https://img.shields.io/badge/database-PostgreSQL-336791?style=flat)](README.md)
[![Status](https://img.shields.io/badge/status-in%20progress-F9A825?style=flat)](README.md)

**Evently** — an event ticketing platform built as a modular monolith, developed while
working through the *Modular Monolith Architecture* course. This repository is the
implementation and the **single source of truth**. Target framework: **.NET 10**.

> Status: greenfield. `src/` and `test/` are empty; the first tasks scaffold the solution.

## Start here

| Doc | What it is |
|---|---|
| [`AGENTS.md`](AGENTS.md) | How we work — course workflow, decisions still open |
| [`docs/architecture/evently-deep-dive.md`](docs/architecture/evently-deep-dive.md) | Architecture reference (the "what") — layering, CQRS, outbox/inbox, sagas, testing, style, C4 diagram map |
| [`docs/ADRs/`](docs/ADRs/README.md) | Architecture Decision Records (the "why") — monolith-first, CQRS, Result, outbox/inbox, … |
| [`.claude/rules/evently-engineering-rules.md`](.claude/rules/evently-engineering-rules.md) | R1–R10 — the coding contract |
| [`docs/deviations-from-author.md`](docs/deviations-from-author.md) | Course-diff view — where we differ from the course, and the ADR for each |
| [`.claude/skills/`](.claude/skills) · [`.claude/agents/`](.claude/agents) | Task playbooks (vertical slice, integration event, new module) and roles (architect, principal-engineer) |

## Target architecture

Modular monolith: one deployable API hosting isolated modules — **Events, Users, Ticketing,
Attendance**. Each module is split **Domain → Application → Infrastructure → Presentation**
with an `IntegrationEvents` contract project.

- Modules never reference each other except through `*.IntegrationEvents`.
- Cross-module effects flow async: domain event → outbox → integration event → inbox → command.
- Write path: EF Core + repository + `IUnitOfWork`. Read path: Dapper + `IDbConnectionFactory`.
- Every use case returns `Result` / `Result<T>`; business-rule failures are typed `Error`s.
- Infrastructure: PostgreSQL (schema per module), Redis, Keycloak, MassTransit, Quartz,
  Serilog, OpenTelemetry.
- Architecture tests (NetArchTest) enforce the layering, module isolation, and naming rules.

## Build & validate

Once the solution is scaffolded, from the repo root:

```bash
dotnet build Evently.sln
dotnet test Evently.sln
docker compose up --build     # local infra: Postgres, Redis, Keycloak, Seq, Jaeger
```

Quality gates (via `Directory.Build.props`): nullable enabled, **warnings as errors**,
code-style enforced in build, `AnalysisMode=All`, Sonar analyzer. A build warning is a real
defect.

## Open decisions

Settled as the course progresses — see `AGENTS.md`. Defaults for now: the solution layout and
`Evently` naming described there, faithful .NET 10 port (flag/log deviations), library stack
of MediatR, FluentValidation, MassTransit, Dapper, Quartz, Serilog.
