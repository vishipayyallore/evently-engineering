# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

This is a **learning tracker**, not an application. It holds notes, task checklists, and
progress artifacts for someone building the Evently project from a video course. It has no
build, no tests, and no application code — `src/` and `tests/` contain only `.gitkeep`.

The canonical Evently implementation lives in the **sibling repo** at
`C:\GitHub\evently_source_code` (already granted as an additional working directory in
`.claude/settings.json`). Any request that involves code changes should be made there, not
here, unless the user explicitly says to work in the tracker.

`AGENTS.md` is the authoritative guide for this workspace — read it. The points below
supplement it.

## Assist artifacts for Evently work

Deep-dive analysis and reusable AI-assist config for building Evently live in this repo:

- `docs/architecture/evently-deep-dive.md` — full architecture analysis of the source repo
  (layering, CQRS pipeline, outbox/inbox, sagas, testing, style). Read this before any
  non-trivial source-repo task.
- `.claude/rules/evently-engineering-rules.md` — R1–R10, the enforced coding contract
  (module boundaries, layer deps, domain/application/infra/presentation rules, messaging,
  testing, style). Every rule maps to an architecture test or a compiler error.
- `.claude/skills/` — `evently-vertical-slice` (add a command/query end-to-end),
  `evently-integration-event` (cross-module messaging), `evently-new-module` (scaffold a
  bounded context).
- `.claude/agents/` — `architect` (design/boundary decisions, plans — read-only, run before
  coding cross-module or `Common.*` changes) and `principal-engineer` (implementation +
  review to the conventions).

## Working rule

- Tracker repo → notes, tasks, learning summaries, links back to source files.
- `../evently_source_code` → all actual code, builds, and tests.
- When summarizing findings, point back to the module and file in the source repo rather
  than copying implementation code into this tracker.

## Source repo (`../evently_source_code`) essentials

Modular monolith. Dependency flow within each module: **Domain → Application → Infrastructure → Presentation**.

- `src/API/Evently.Api` — HTTP API entry point
- `src/Common/Evently.Common.{Domain,Application,Infrastructure,Presentation}` — shared concerns
- `src/Modules/{Events,Users,Ticketing,Attendance}/*` — one project per layer, plus
  `IntegrationEvents` (cross-module contracts) and per-module `UnitTests` /
  `IntegrationTests` / `ArchitectureTests`
- `test/Evently.ArchitectureTests`, `test/Evently.IntegrationTests` — solution-wide tests

Add feature work to the relevant module; don't create cross-cutting folders. Keep tests in
the module-level or shared test projects. Never touch `bin/`/`obj/`.

Build/validate from the source repo root:

```
dotnet restore Evently.sln
dotnet build Evently.sln
dotnet test Evently.sln
dotnet test --filter "FullyQualifiedName~Evently.Modules.Events.UnitTests"   # single project/test
docker compose up --build   # local app stack
```

Prefer solution-level commands; scope to a single project only for narrow tasks.

## Version note

`AGENTS.md` describes a ".NET 10 workstream" and the installed SDK is 10.0.303, but
`../evently_source_code/Directory.Build.props` currently pins `<TargetFramework>net8.0</TargetFramework>`.
Confirm which target a task expects before changing project files. That `Directory.Build.props`
also enables: nullable, `TreatWarningsAsErrors`, `EnforceCodeStyleInBuild`, `AnalysisMode=All`,
and the SonarAnalyzer.CSharp package — expect style/analyzer violations to fail the build.
