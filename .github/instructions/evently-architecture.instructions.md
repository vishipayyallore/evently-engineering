---
applyTo: "**/*.{cs,csproj,sln,md}"
description: "Use when working on Evently architecture, module boundaries, domain design, or cross-cutting reliability concerns."
---

# Evently Architecture Instructions

## Architectural rules

- Keep Domain free of infrastructure and presentation concerns.
- Keep Application focused on orchestration, validation, and use case logic.
- Keep Infrastructure focused on persistence, message bus, integrations, and background jobs.
- Keep Presentation focused on endpoints and adapters.

## Module rules

- Treat each module as owning its domain model, application logic, infrastructure, and presentation surface.
- Do not allow module-to-module dependencies except through explicit integration contracts.
- Prefer one module to own one business capability.
- Do not create cross-cutting feature folders when the existing module boundaries already fit the change.

## Eventing rules

- Use domain events for in-module transitions.
- Use integration events for cross-module communication.
- Preserve outbox/inbox semantics and idempotent handlers for retries.

## Quality and validation

- Check the smallest relevant validation path first.
- Use solution-level checks for cross-module or shared-infrastructure work.
- Keep architecture tests passing.
- Do not bypass warnings-as-errors or style analyzer enforcement.

## Repository rule

This learning tracker is for notes and progress. Production work belongs in the sibling Evently source repo. Summaries should reference canonical source files instead of duplicating implementation details here.
