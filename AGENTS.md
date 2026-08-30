# AGENTS.md

This repository — `C:\GitHub\evently-learning-tracker` — is where we **build Evently** while
following the *Modular Monolith Architecture* video course. It is the implementation and the
**single source of truth**. All code, tests, docs, and progress notes live here.

## Two repositories

| Path | Role | Rules |
|---|---|---|
| `C:\GitHub\evently-learning-tracker` (this repo) | **Our implementation.** Targets **.NET 10**. Everything we write goes here. | Read/write. This is the working repo. |
| `C:\GitHub\evently_source_code` | **The author's reference implementation.** .NET 8. Kept only to compare against while learning. | **Read-only. Never edit it. Never run builds or migrations in it.** Cite it for "how the author did X". |

Granted as an additional read directory in `.claude/settings.json`.

## How we work

- We follow the course lesson by lesson and implement each step **here**, on **.NET 10**.
- The author's repo shows the target pattern. We adapt it to .NET 10 and to any choices we
  make along the way — **deviations from the author are expected**. Record every meaningful
  one in [`docs/deviations-from-author.md`](docs/deviations-from-author.md) (what, why,
  author's approach vs ours).
- When implementing a feature: read the equivalent slice in `../evently_source_code` for the
  pattern, then write our version here matching our conventions.
- Prefer small, explicit, testable changes that match the shape of what we've already built.

## Decisions still open (default assumption in brackets)

These are settled as the course progresses; until then, assume the default:

- **Project/solution layout** — [mirror the author's: `src/API/Evently.Api`,
  `src/Common/Evently.Common.{Domain,Application,Infrastructure,Presentation}`,
  `src/Modules/<Module>/{Domain,Application,Infrastructure,IntegrationEvents,Presentation}`,
  `test/…`, `Evently.sln`].
- **Product / namespace root** — [`Evently`].
- **How faithfully we track the author** — [faithful port to .NET 10; flag and log deviations].
- **Library stack** — [same as the author: MediatR, FluentValidation, MassTransit, Dapper,
  Quartz, Serilog, Newtonsoft — noting MediatR needs a commercial license for non-personal
  use]. Raise a swap when the tradeoff looks worth it; the user decides.

If a task depends on one of these and it hasn't been decided, ask.

## Architecture we're building toward

Modular monolith: one deployable API hosting isolated modules (**Events, Users, Ticketing,
Attendance**), each split **Domain → Application → Infrastructure → Presentation** with an
`IntegrationEvents` contract project. Modules never reference each other except through
`*.IntegrationEvents`; cross-module effects flow through domain events → outbox → integration
events → inbox. Full analysis of the reference design:
[`docs/architecture/evently-deep-dive.md`](docs/architecture/evently-deep-dive.md).

## Working conventions

- Enforced coding rules: [`.claude/rules/evently-engineering-rules.md`](.claude/rules/evently-engineering-rules.md) (R1–R10).
- Repeatable tasks have skills: `.claude/skills/evently-vertical-slice`,
  `evently-integration-event`, `evently-new-module`.
- Roles: `.claude/agents/architect.md` (design/boundary decisions before code),
  `.claude/agents/principal-engineer.md` (implementation + review).
- Validate from this repo's solution root: `dotnet build`, `dotnet test`. A build **warning
  is an error** once analyzers are configured — fix the cause.
- Do not edit `bin/`, `obj/`, EF `*Designer.cs`, or `*ModelSnapshot.cs` by hand.
