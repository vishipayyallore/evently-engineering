# AGENTS.md

This repository is where we **build Evently** while working through the *Modular Monolith
Architecture* material. It is the implementation and the **single source of truth** — all
code, tests, docs, and progress notes live here. Target framework: **.NET 10**.

Right now it is greenfield: `src/` and `test/` hold only `.gitkeep`. Early tasks scaffold
the solution.

## How we work

- We follow the course lesson by lesson and implement each step **here**, on **.NET 10**.
- We may diverge from the course's approach as we go — **deliberate deviations are expected**
  and get recorded in [`docs/deviations-from-author.md`](docs/deviations-from-author.md)
  (what changed, why).
- Prefer small, explicit, testable changes that match the shape of what we've already built.
- A read-only local reference implementation may be configured as an extra directory in
  `.claude/settings.local.json`. When present, consult it for implementation patterns — **never
  modify it, never build or run migrations in it.**

## Decisions still open (default assumption in brackets)

Settled as the course progresses; until then, assume the default:

- **Project/solution layout** — [`src/API/Evently.Api`,
  `src/Common/Evently.Common.{Domain,Application,Infrastructure,Presentation}`,
  `src/Modules/<Module>/{Domain,Application,Infrastructure,IntegrationEvents,Presentation}`,
  `test/…`, `Evently.sln`].
- **Product / namespace root** — [`Evently`].
- **Fidelity to the course** — [faithful port to .NET 10; flag and log deviations].
- **Library stack** — [MediatR, FluentValidation, MassTransit, Dapper, Quartz, Serilog,
  Newtonsoft — noting MediatR needs a commercial license for non-personal use]. Raise a swap
  when the tradeoff looks worth it; the user decides.

If a task depends on one of these and it hasn't been decided, ask.

## Architecture we're building toward

Modular monolith: one deployable API hosting isolated modules (**Events, Users, Ticketing,
Attendance**), each split **Domain → Application → Infrastructure → Presentation** with an
`IntegrationEvents` contract project. Modules never reference each other except through
`*.IntegrationEvents`; cross-module effects flow through domain events → outbox → integration
events → inbox. Full design reference:
[`docs/architecture/evently-deep-dive.md`](docs/architecture/evently-deep-dive.md).

## Working conventions

- Enforced coding rules: [`.claude/rules/evently-engineering-rules.md`](.claude/rules/evently-engineering-rules.md) (R1–R10).
- **Decisions** — significant/structural choices are captured as ADRs in
  [`docs/ADRs/`](docs/ADRs/README.md) (the "why"); the deep-dive is the "what";
  [`docs/deviations-from-author.md`](docs/deviations-from-author.md) is the course-diff view
  and links each row's ADR.
- **Diagrams** — architecture diagrams live in `docs/mermaid-diagrams/` (rendered to
  `docs/images/`), organised in C4 levels; see the deep-dive "Diagrams" table. Regenerate
  with `pwsh scripts/export-mermaid.ps1`.
- Repeatable tasks have skills: `.claude/skills/evently-vertical-slice`,
  `evently-integration-event`, `evently-new-module`.
- Roles: `.claude/agents/architect.md` (design/boundary decisions before code — **owns the
  ADRs and the diagram set**), `.claude/agents/principal-engineer.md` (implementation +
  review).
- Validate from this repo's solution root: `dotnet build`, `dotnet test`. A build **warning
  is an error** once analyzers are configured — fix the cause.
- Do not edit `bin/`, `obj/`, EF `*Designer.cs`, or `*ModelSnapshot.cs` by hand.
