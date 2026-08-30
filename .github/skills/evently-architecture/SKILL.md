# Evently Architecture Skill

Use this skill when you need to reason about Evently's architecture, module boundaries, delivery quality, or system design trade-offs.

## What to inspect

- module ownership and dependency flow
- Domain/Application/Infrastructure/Presentation separation
- event-driven workflows and outbox/inbox strategies
- architecture tests and validation patterns
- risky coupling or hidden cross-module dependencies

## Workflow

1. Identify the owning module and the layer of the change.
2. Trace the request through the dependency layers.
3. Ask whether the concern is domain logic, orchestration, persistence, or presentation adaptation.
4. Check for hidden coupling, integration-event misuse, or architecture violations.
5. Validate the smallest relevant path before concluding the design.
6. Treat .NET 10 as the default target for this tracker’s planning and validation context, while confirming the source repo’s actual project configuration before changing project files.

## Evently heuristics

- Keep business rules in Domain.
- Keep coordination and validation in Application.
- Keep infrastructure concerns in Infrastructure.
- Keep endpoint registration in Presentation.
- Preserve module autonomy and explicit integration contracts.
- Prefer the Evently .NET 10 workstream unless the canonical source repo explicitly requires a different target.

## Exit criteria

A design is ready when it respects ownership, minimizes cross-module coupling, and is defensible under the architecture and validation rules of the project.
