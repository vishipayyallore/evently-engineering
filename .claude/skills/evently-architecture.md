# Evently Architecture Skill

Use this skill when you need to reason about Evently's structure, module boundaries, or delivery quality.

## What to look for

- Module ownership and dependency inversion
- Domain/Application/Infrastructure/Presentation separation
- Outbox/inbox and event-driven letter patterns
- Architecture tests and solution-level validation
- Shared infrastructure versus module-specific code

## Workflow

1. Identify the owning module.
2. Trace the request through the boundary layers.
3. Check whether the concern is domain logic, orchestration, persistence, or HTTP adaptation.
4. Verify whether the design introduces hidden coupling or an invalid dependency.
5. Confirm the small relevant validation path before finalizing the solution.

## Evently-specific heuristics

- Prefer domain-first design and explicit commands/queries.
- Keep integration events in integration event projects rather than spreading contracts across modules.
- Prefer existing common infrastructure hooks over new abstractions.
- Ensure tests match the change: unit, integration, or architecture tests as appropriate.

## Exit criteria

A design is ready when it respects ownership, minimizes cross-module coupling, and can be defended by the architecture test suite and developer conventions.
