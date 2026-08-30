# Deviations from the author's implementation

Running log of where our Evently build (this repo, .NET 10) differs from the *Modular
Monolith Architecture* course / `C:\GitHub\evently_source_code` (the author's repo, .NET 8).

Add a row whenever we make a deliberate, non-trivial choice that departs from the course.
Keep it short: what changed, why, author's approach vs ours, where it lives.

| Date | Area | Author's approach | Our approach | Why |
|---|---|---|---|---|
| 2026-08-30 | Target framework | `net8.0` pinned in `Directory.Build.props` | `net10.0` | We're learning on the current .NET; the architecture is framework-agnostic. |

## Notes / candidates to revisit

- **MediatR license** — MediatR is commercially licensed from v12.4+. Fine for personal
  learning; decide before any commercial use whether to keep it or swap for a small
  hand-rolled command/query dispatcher. (No decision yet — default is keep.)
- (add more as they come up)
