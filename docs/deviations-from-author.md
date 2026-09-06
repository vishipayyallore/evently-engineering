# Deviations from the course

Running log of where our Evently build (.NET 10) deliberately differs from the *Modular
Monolith Architecture* course material. This is the **course-diff view**; the full rationale
for each row lives in its ADR ([`ADRs/`](ADRs/README.md)).

Add a row whenever we make a deliberate, non-trivial choice that departs from the course.
Keep it short: what changed, the course's approach vs ours, and the ADR. Write the ADR too.

| Date | Area | Course approach | Our approach | ADR |
|---|---|---|---|---|
| 2026-08-30 | Target framework | .NET 8 | .NET 10 | [ADR-0010](ADRs/0010-target-dotnet-10.md) |
| 2026-08-31 | Build approach | Modular monolith scaffolded up front | **Monolith first, then modular** (Phase 1 single-project; Phase 2 refactor into isolated modules) | [ADR-0002](ADRs/0002-monolith-first-then-modular.md) |
| 2026-08-31 | Solution file format | `.slnx` is the .NET 10 default | classic `.sln` (forced via `dotnet new sln --format sln`) | [ADR-0011](ADRs/0011-classic-sln-format.md) |
| 2026-09-06 | Domain / integration events | `sealed record` (some course lessons) | `public sealed class` with primary ctor + `{ get; init; }` — matches the reference implementation | — (reference-impl alignment, not a course deviation) |

## Notes / candidates to revisit

- **MediatR license** — MediatR is commercially licensed from v12.4+, and 12.2.0 (course)
  does not target .NET 10. Decide before the first real slice whether to move to a licensed
  version or a small hand-rolled dispatcher. See [ADR-0003](ADRs/0003-cqrs-with-mediatr.md)
  and [ADR-0010](ADRs/0010-target-dotnet-10.md). (No decision yet — default is keep.)
- (add more as they come up)
