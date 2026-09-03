# Deviations from the course

Running log of where our Evently build (.NET 10) deliberately differs from the *Modular
Monolith Architecture* course material.

Add a row whenever we make a deliberate, non-trivial choice that departs from the course.
Keep it short: what changed, the course's approach vs ours, and why.

| Date | Area | Course approach | Our approach | Why |
|---|---|---|---|---|
| 2026-08-30 | Target framework | .NET 8 | .NET 10 | We build on the current .NET; the architecture is framework-agnostic. |
| 2026-08-31 | Build approach | Modular monolith scaffolded up front | **Monolith first, then modular** — Phase 1 a single-project monolith (contexts as folders, CQRS + `Result`), Phase 2 refactor into isolated modules (code org → communication → schema isolation → NetArchTest) | *Monolith First* (Fowler) + the course's *Modularize Your Monolith* bonus path; simpler to code along and to get boundaries right by evolving them. Module-isolation rules (R1, R7, per-schema R5) are tagged **[Phase 2]**. |
| 2026-08-31 | Solution file format | classic `.sln` | classic `.sln` (forced via `dotnet new sln --format sln`) | .NET 10's `dotnet new sln` defaults to the newer `.slnx`; we keep `.sln` so the documented `dotnet build Evently.sln` commands and tooling work unchanged. |

## Notes / candidates to revisit

- **MediatR license** — MediatR is commercially licensed from v12.4+. Fine for personal
  learning; decide before any commercial use whether to keep it or swap for a small
  hand-rolled command/query dispatcher. (No decision yet — default is keep.)
- (add more as they come up)
