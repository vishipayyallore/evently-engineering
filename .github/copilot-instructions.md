# Copilot Instructions for Evently

## Workspace purpose

This repo is the learning tracker for the Evently project. The canonical implementation lives in the sibling repository at `../evently_source_code`.

Use this repo for:
- tracking learning progress
- capturing task checklists and implementation notes
- recording architecture observations and constraints

Do not put production code here unless the task explicitly says to work in the tracker.

## Primary source of truth

When a task involves code, use the source repo at `../evently_source_code`.

## Architecture baseline

The Evently source is a modular monolith shaped around business capabilities:
- `src/API/Evently.Api`
- `src/Common/Evently.Common.{Domain,Application,Infrastructure,Presentation}`
- `src/Modules/{Events,Users,Ticketing,Attendance}`
- `test/*` and module-level architecture/integration tests

Follow these rules:
- Domain -> Application -> Infrastructure -> Presentation
- each module owns its domain model and application logic
- no direct module-to-module dependencies outside explicit integration contracts
- use domain events for in-module transitions and integration events for cross-module communication
- keep outbox/inbox patterns intact for reliable messaging

## Quality bar

- Treat warnings as errors.
- Keep code style consistent with the repo conventions.
- Preserve architecture tests and analyzer enforcement.
- Validate with the smallest relevant command that checks the changed behavior.

## Local validation

This tracker follows the .NET 10 workstream for Evently planning and validation. Confirm the SDK in use before building or testing:

- `dotnet --version` (expect .NET 10)
- `dotnet restore Evently.sln`
- `dotnet build Evently.sln`
- `dotnet test Evently.sln`
- `docker compose up --build` for app stack startup

If the canonical source repo has a different active target in its project files, verify the actual configuration before changing project settings or forcing a framework update.
