# S.M.A.R.T. Prompt Framework for Evently Coding Agents

Use this guide to write focused GitHub Copilot prompts for Evently, the .NET 10 implementation
of the Modular Monolith Architecture course.

## S.M.A.R.T.

```text
S - Specific role: architect, principal engineer, reviewer, or documentation editor.
M - Mission: observable behavior, scope, acceptance criteria, and validation.
A - Architecture-aware context: phase, bounded context, layer, flow, and nearest slice.
R - Response format: plan, implementation summary, review findings, or decision record.
T - Task constraints: .NET 10, R1-R10, CQRS, tests, and prohibited changes.
```

## Required Prompt Context

Every implementation prompt should establish:

- **Phase**: Phase 1 monolith first, unless the task explicitly begins Phase 2 modularization.
- **Location**: bounded context and layer: Domain, Application, Infrastructure, Presentation,
  or tests.
- **Flow**: command/write, query/read, domain event, integration event, endpoint, or migration.
- **Evidence**: the controlling type, observed behavior, failing command, or failing test.
- **Pattern**: the nearest equivalent Evently slice to match.

Read `AGENTS.md` first. Use `.claude/rules/evently-engineering-rules.md` as the full coding
contract, and `docs/architecture/evently-deep-dive.md` for non-trivial architecture work. A
reference implementation, if configured in `.claude/settings.local.json`, is read-only.

## Prompt Template

```markdown
## Role

You are a [principal engineer / architect / reviewer] working on Evently, a .NET 10
implementation of the Modular Monolith Architecture course.

## Mission

[State the behavior to implement, fix, or assess and its observable acceptance criteria.]

## Context

- Phase: [Phase 1 monolith / explicit Phase 2 modularization]
- Bounded context and layer: [for example, Events / Application]
- Controlling code or test: [path and type]
- Nearest pattern to follow: [path and type]

## Constraints

- Read `AGENTS.md` and the applicable R1-R10 rules before editing.
- Preserve inward dependencies: Domain -> Application -> Infrastructure / Presentation.
- Model expected business failures with `Error` and `Result`; do not throw.
- Commands use repositories and exactly one `IUnitOfWork.SaveChangesAsync`.
- Queries use Dapper plus `IDbConnectionFactory`; no EF or repository on the read side.
- Do not hand-edit `bin/`, `obj/`, EF `*Designer.cs`, or `*ModelSnapshot.cs`.
- [Add task-specific constraints.]

## Process

1. State one falsifiable local hypothesis and the cheapest validation that could disprove it.
2. Make the smallest complete change that matches the nearest existing slice.
3. Add focused test coverage required by R8.
4. Record any deliberate course deviation in `docs/deviations-from-author.md`.

## Validation

Run the narrowest relevant check first, followed by:

```powershell
dotnet build Evently.sln
dotnet test Evently.sln
```

Run the solution commands when the solution and affected tests make them applicable. Report the
commands run, their results, changed files, and any remaining blocker or open decision.
```

## Role Selection

Use the **architect** role before choosing a new module boundary, changing `Common.*`, adding
cross-module messaging, introducing a saga, or resolving a project-layout decision. Use the
**principal engineer** role for an established use case, focused bug fix, or local refactor.

## Evently Quality Gates

- Target `net10.0`; warnings are errors and must be fixed, not suppressed.
- Domain aggregates are sealed, have private constructors and setters, validate through static
  factories or state-transition methods, and raise domain events for meaningful transitions.
- Application handlers are `internal sealed`; commands and queries are `public sealed record`s.
- New aggregate behavior has a focused unit test. New use cases have an integration test through
  `ISender` when the test infrastructure exists.
- New type categories must satisfy the existing architecture tests.

## Avoid These Prompt Shapes

- Broad repository-audit requests when the task has a concrete behavior or failing test.
- Generic "make it work" instructions without a layer, acceptance criterion, or validation.
- Phase 2 requirements when the work is still within Phase 1 monolith-first construction.
- Requests to copy the reference implementation rather than consulting its pattern and adapting
  it to this repository's .NET 10 decisions.

## Example

```markdown
## Role

You are a principal engineer implementing a focused Evently vertical slice.

## Mission

Add the Events create-event command so a valid request creates an Event aggregate, persists it,
and returns a `Result<Guid>`; invalid titles return the aggregate's typed validation error.

## Context

- Phase: Phase 1 monolith
- Bounded context and layer: Events / Domain and Application
- Pattern: Follow the nearest command and aggregate test already present.

## Acceptance Criteria

- The aggregate factory enforces the title invariant and raises its creation domain event.
- The command handler inserts the aggregate and calls `SaveChangesAsync` once.
- Unit and integration coverage follows R8 naming and assertion conventions.
- `dotnet build Evently.sln` and the affected tests pass without warnings.
```