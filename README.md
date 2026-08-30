# Evently

[![Architecture](https://img.shields.io/badge/architecture-modular%20monolith-4B0082?style=for-the-badge)](README.md)
[![Domain](https://img.shields.io/badge/domain-driven%20design-00C853?style=for-the-badge)](README.md)
[![Platform](https://img.shields.io/badge/platform-.NET%2010-512BD4?style=for-the-badge)](README.md)
[![Events](https://img.shields.io/badge/events-async%20integration-FF6D00?style=for-the-badge)](README.md)
[![Status](https://img.shields.io/badge/status-in%20progress-F9A825?style=for-the-badge)](README.md)

Our implementation of **Evently**, built while following the *Modular Monolith Architecture*
video course. This repository is the implementation and the **single source of truth** — all
code, tests, and docs live here. Target framework: **.NET 10**.

The course author's implementation lives at `C:\GitHub\evently_source_code` (.NET 8). We keep
it **read-only**, as a reference for how a given slice is built. Deliberate departures from it
are logged in [`docs/deviations-from-author.md`](docs/deviations-from-author.md).

> Status: greenfield. `src/` and `tests/` are empty; the first tasks scaffold the solution.

## Start here

| Doc | What it is |
|---|---|
| [`AGENTS.md`](AGENTS.md) | How we work — the two-repo setup, course workflow, decisions still open |
| [`docs/architecture/evently-deep-dive.md`](docs/architecture/evently-deep-dive.md) | Full analysis of the reference design — layering, CQRS, outbox/inbox, sagas, testing, style |
| [`.claude/rules/evently-engineering-rules.md`](.claude/rules/evently-engineering-rules.md) | R1–R10 — the coding contract |
| [`docs/deviations-from-author.md`](docs/deviations-from-author.md) | Running log of where our build differs from the course |
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

Quality gates (via `Directory.Build.props`, mirrored from the reference repo): nullable
enabled, **warnings as errors**, code-style enforced in build, `AnalysisMode=All`, Sonar
analyzer. A build warning is a real defect.

## Open decisions

Settled as the course progresses — see `AGENTS.md`. Defaults for now: mirror the author's
solution layout and `Evently` naming, faithful .NET 10 port (flag/log deviations), same
library stack (MediatR, FluentValidation, MassTransit, Dapper, Quartz, Serilog).
