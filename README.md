# Evently Learning Tracker

[![Status](https://img.shields.io/badge/status-learning--tracker-blue?style=for-the-badge)](README.md)
[![Architecture](https://img.shields.io/badge/architecture-modular%20monolith-4B0082?style=for-the-badge)](README.md)
[![Domain](https://img.shields.io/badge/domain-driven%20design-00C853?style=for-the-badge)](README.md)
[![Platform](https://img.shields.io/badge/platform-.NET%2010-512BD4?style=for-the-badge)](README.md)
[![Events](https://img.shields.io/badge/events-async%20integration-FF6D00?style=for-the-badge)](README.md)
[![Testing](https://img.shields.io/badge/testing-architecture%20enforced-D50000?style=for-the-badge)](README.md)
[![Source](https://img.shields.io/badge/source-working%20repo-00897B?style=for-the-badge)](README.md)
[![Focus](https://img.shields.io/badge/focus-learning%20tracker-F9A825?style=for-the-badge)](README.md)

This repository is the working Evently implementation and the single source of truth for our project work. We are building it here in `C:\GitHub\evently-learning-tracker` using the .NET 10 workstream.

The sibling repository at `C:\GitHub\evently_source_code` belongs to the author of the video course. It remains available as a reference implementation for comparison and pattern study, but it is not the active repository for our work.

The purpose of this tracker is to capture architecture notes, learning checkpoints, implementation observations, and task tracking while keeping our actual project work in the working repo.

## Source of truth

Our active application code, builds, and validation live here in this repo:

- `C:\GitHub\evently-learning-tracker`

The author's repo remains useful as a reference only:

- `C:\GitHub\evently_source_code`

This repo should remain focused on:

- notes
- task tracking
- architecture observations
- learning summaries
- references back to our working implementation and to course patterns

## Architecture summary of Evently

The Evently source code is a modular monolith organized around business capabilities. The clearest pattern in the implementation is a strict layer model within each module:

- Domain -> Application -> Infrastructure -> Presentation

The app boots through the API entry point and then wires in each module separately:

- `src/API/Evently.Api/Program.cs`
- `src/Common/Evently.Common.Application/ApplicationConfiguration.cs`
- `src/Common/Evently.Common.Infrastructure/InfrastructureConfiguration.cs`
- `src/Common/Evently.Common.Presentation/Endpoints/EndpointExtensions.cs`

## Module structure

The solution is split into capability-oriented modules:

- Events
- Users
- Ticketing
- Attendance

Each module owns its own domain, application, infrastructure, and presentation concerns. This is reinforced by architecture tests that explicitly assert that modules do not depend on one another directly:

- `test/Evently.ArchitectureTests/Layers/ModuleTests.cs`

The design intentionally keeps cross-module communication via integration contracts rather than direct module-to-module references.

## Core patterns seen in the codebase

### 1. Domain-first modeling

The domain layer contains business entities, aggregate rules, and domain events. For example, the Event aggregate in `src/Modules/Events/Evently.Modules.Events.Domain/Events/Event.cs` encapsulates lifecycle rules such as publish, reschedule, and cancel.

This shows the app follows a rich-domain-model style, with state transitions and business rules centered on the aggregate.

### 2. Command/query orchestration in Application

The application layer uses MediatR and validation pipelines. Shared configuration is centralized in `ApplicationConfiguration`, where exception handling, request logging, and validation behaviors are registered.

This gives a consistent execution model for commands and queries across modules without scattering business flow across the infrastructure layer.

### 3. Infrastructure responsibilities are isolated

Infrastructure is responsible for:

- EF Core DbContext setup
- PostgreSQL configuration
- Redis and cache wiring
- MassTransit configuration
- outbox/inbox jobs
- health checks and telemetry

The shared infrastructure setup in `InfrastructureConfiguration` wires tracing, Redis, MassTransit, authentication, and Quartz-backed job processing.

### 4. Outbox and inbox patterns are part of the design

The module registration code shows explicit outbox and inbox job configuration for each module. This is a strong reliability pattern for event-driven systems and protects against message processing gaps and duplicate handling.

### 5. Presentation is endpoint-based, not controller-heavy

Endpoint discovery is reflection-based and happens through `EndpointExtensions`. Each module registers its endpoints via assembly scanning instead of building a monolithic API composition layer.

This keeps the API surface modular and aligned with the module ownership model.

### 6. Architecture tests enforce boundaries

The source repo is not just convention-based; it has real checks enforcing architectural constraints. The architecture tests use NetArchTest to verify that modules do not depend on one another directly and that each module respects the expected boundaries.

## Validation and build workflow

These are the solution-level commands to use from the source repo root:

```bash
dotnet --version
dotnet restore Evently.sln
dotnet build Evently.sln
dotnet test Evently.sln
docker compose up --build
```

When a task is narrowly scoped, a single project or module test set may be used instead of the whole solution, but broader changes should validate at the solution level.

## Quality gates in the repo

The project enforces strict quality conventions in `Directory.Build.props`:

- nullable reference types enabled
- warnings treated as errors
- code style enforcement enabled
- analysis mode enabled
- Sonar analyzer included

This means build failures from warnings or analyzer issues are expected and should be treated as real quality defects.

## Important version note

The source repo is currently being tracked as a .NET 10 workstream for this learning effort, and the project setup in this tracker is aligned to that target.

Before making project-level changes in the canonical source repo, verify the actual target framework in `Directory.Build.props` and follow the repo’s active configuration if a mismatch is present.

## Learning focus

This tracker should be used to study:

- modular monolith boundaries
- domain-driven business rules
- event-driven integration patterns
- module ownership and contract design
- reliability via outbox/inbox and idempotent handlers
- testing and architecture enforcement in a real-world .NET solution

## Recommended study order

1. Start at `Program.cs` and follow module registration.
2. Study one module end-to-end: Domain -> Application -> Infrastructure -> Presentation.
3. Review how domain events become integration events and how they are handled.
4. Inspect the architecture tests to understand the enforced rules.
5. Run solution tests and then narrow in on a specific module.

## Working rule for this tracker

- Production code belongs in `C:\GitHub\evently_source_code`.
- This repo is for learning, notes, tasks, and architecture capture.
- Summaries should point back to the source files rather than duplicating their implementation details here.
