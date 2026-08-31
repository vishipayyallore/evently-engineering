# Deviations from the course

Running log of where our Evently build (.NET 10) deliberately differs from the *Modular
Monolith Architecture* course material.

Add a row whenever we make a deliberate, non-trivial choice that departs from the course.
Keep it short: what changed, the course's approach vs ours, and why.

| Date | Area | Course approach | Our approach | Why |
|---|---|---|---|---|
| 2026-08-30 | Target framework | .NET 8 | .NET 10 | We build on the current .NET; the architecture is framework-agnostic. |

## Notes / candidates to revisit

- **MediatR license** — MediatR is commercially licensed from v12.4+. Fine for personal
  learning; decide before any commercial use whether to keep it or swap for a small
  hand-rolled command/query dispatcher. (No decision yet — default is keep.)
- (add more as they come up)
