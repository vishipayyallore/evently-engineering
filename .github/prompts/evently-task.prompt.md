---
name: Evently Task
description: "Plan and implement a focused Evently .NET 10 course task with architecture, tests, and validation."
argument-hint: "Describe the lesson, feature, fix, or refactor to complete."
---

# Evently Task

You are implementing a focused task in the Evently repository, a .NET 10 implementation
of the Modular Monolith Architecture course.

## Task

${input:task:Describe the task, including the relevant lesson or acceptance criteria.}

## Required Context

1. Read `AGENTS.md` and the applicable rules in `.claude/rules/evently-engineering-rules.md`.
2. Read the nearest existing implementation before deciding on a shape.
3. For a non-trivial vertical slice, read `docs/architecture/evently-deep-dive.md` and use
   the relevant repository skill under `.claude/skills/`.
4. A read-only reference repository may be configured in `.claude/settings.local.json`.
   Consult the equivalent slice only for patterns; never edit, build, test, or migrate it.

## Architecture Constraints

- The current implementation phase is monolith first. Apply Phase 1 rules now; do not
  prematurely create module projects, schemas, or async integration messaging unless the
  task explicitly begins Phase 2 modularization.
- Keep dependencies inward: Domain -> Application -> Infrastructure / Presentation.
- Model business failures as typed `Error` values and return `Result` or `Result<T>`.
  Do not throw for expected business-rule failures.
- Commands write through repository interfaces and one `IUnitOfWork.SaveChangesAsync` call.
  Queries use Dapper and `IDbConnectionFactory`, never EF or repositories.
- Keep aggregates sealed with private constructors and setters, use a validating static
  `Create` factory, and raise domain events for significant state changes.
- Follow the repository's visibility, naming, nullability, and collection-expression rules.
- Do not hand-edit generated output, migrations designer files, snapshots, `bin/`, or `obj/`.

## Delivery Process

1. State a brief, falsifiable local hypothesis and the cheapest check that could disprove it.
2. Make the smallest coherent change that satisfies the task and matches the nearest slice.
3. Add focused tests for new aggregate behavior or use cases as required by R8.
4. When intentionally departing from the course, document the rationale in
   `docs/deviations-from-author.md`.
5. Validate in this order: the narrowest affected check, `dotnet build Evently.sln`, then
   `dotnet test Evently.sln` when the solution and tests make those commands applicable.

## Completion Report

Report the implementation outcome concisely:

- Changed files and the behavior they provide.
- Validation commands run and their result.
- Any deliberate deviation, deferred decision, or blocked validation.