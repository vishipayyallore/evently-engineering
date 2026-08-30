# AGENTS.md

This workspace is the Evently learning tracker. Treat it as the planning and progress repo for the Evently project, while the canonical implementation lives in the sibling repository at `../evently_source_code`.

## Primary goal

Use this repo to:
- track learning progress and notes
- capture implementation ideas and task checklists
- reference the real Evently codebase without mixing tracker files with production code

When a task asks for code changes, prefer the canonical source repo unless the request explicitly says to work here.

## Reference project structure

The source application is a modular monolith and we will work with the .NET 10 SDK in this workspace. The major areas are:
- `src/API/Evently.Api` — entry point and HTTP API
- `src/Common` — shared domain/application/infrastructure/presentation concerns
- `src/Modules/*` — module boundaries for Events, Users, Ticketing, and Attendance
- `test/*` — architecture and integration tests

Use the .NET 10 SDK for local validation and keep the source repo conventions in `../evently_source_code/Directory.Build.props` in mind:
- target framework should be aligned with the .NET 10 workstream
- nullable reference types enabled
- warnings treated as errors
- code style enforcement enabled
- Sonar analyzer enabled

## Build and validation commands

Run these from the source repo root (`../evently_source_code`) using the .NET 10 SDK:

- `dotnet --version` to confirm the SDK is .NET 10
- `dotnet restore Evently.sln`
- `dotnet build Evently.sln`
- `dotnet test Evently.sln`
- `docker compose up --build` when the app stack needs to be started locally

Use the solution-level commands first; avoid running ad hoc builds against individual projects unless the task is narrowly scoped.

## Architecture guidance

Follow the existing Evently module patterns when exploring code:
- keep the dependency flow clean: Domain -> Application -> Infrastructure -> Presentation
- add feature work to the relevant module rather than creating new cross-cutting folders
- keep tests in the module-level test projects or the shared integration/architecture test projects
- do not modify generated `bin/` or `obj/` folders

## Working conventions for this tracker

- keep this repo focused on notes, tasks, and learning artifacts
- link findings back to the real source repo instead of duplicating implementation details here
- prefer short, explicit task descriptions and concrete next steps over long speculative notes
- if a task requires code changes, work in the canonical source repo and use this tracker only for progress tracking

## Good defaults for agents

- Start by checking the source repo structure and relevant module before changing anything.
- Prefer minimal edits that match the existing Evently conventions.
- Validate with the smallest relevant .NET 10 command for the changed area.
- If the request is learning-oriented, summarize findings and point back to the module and source files rather than inventing new patterns.
