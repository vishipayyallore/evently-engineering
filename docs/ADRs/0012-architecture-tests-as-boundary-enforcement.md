# ADR-0012 — NetArchTest architecture tests enforce the rules

- **Status:** Accepted
- **Date:** 2026-09-06
- **Deciders:** Evently team
- **Related:** ADR-0005 (layering), ADR-0006 (module isolation), deep-dive §2, §10, rules R8.3

## Context

R1–R10 only matter if they hold. Code review catches some violations; a new contributor (or
a coding agent) mirroring the wrong file catches none. Layering and module-isolation rules in
particular are invisible until something imports across a boundary.

## Decision

The rules are **executable**. `*.ArchitectureTests` (per module) + `test/Evently.ArchitectureTests`
(solution) use **NetArchTest** + xUnit to assert: layer dependencies (`LayerTests`), module
isolation with the `*.IntegrationEvents`-only exception (`ModuleTests`), and
naming/sealing/visibility/constructor rules for Domain, Application, and Presentation types.
Compiler-enforced style (`.editorconfig` at `error`, `TreatWarningsAsErrors`,
`AnalysisMode=All`, SonarAnalyzer) covers R9. A violation fails `dotnet test` /
`dotnet build`. **[Phase 2]** for module isolation and the project-level layer tests; the
type-shape tests are usable as soon as the types exist.

## Consequences

### Good

- Boundary erosion is a red build, not a review comment.
- New categories of type get a test, so the contract stays complete.
- The tests double as executable documentation of the rules.

### Trade-offs

- Architecture tests are slower than unit tests and can be brittle to refactors (assembly
  scanning, namespace strings).
- Writing a good NetArchTest assertion for a new rule takes thought.
- Phase 1 gives us the type-shape tests but not the isolation tests, so some discipline is
  still manual until Phase 2.

### Follow-ups

- When adding a module: copy the per-module architecture tests and add the module to
  `ModuleTests` (both directions).

## Alternatives considered

- **Review + convention only.** Rejected: does not scale and gives agents nothing to check
  against.
- **A dependency-analysis tool in CI (e.g. NDepend).** Rejected: heavier, less portable, not
  in-repo with the code it guards.
