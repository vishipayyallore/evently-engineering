# ADR-0011 — Keep the classic `.sln` format

- **Status:** Accepted
- **Date:** 2026-09-06
- **Deciders:** Evently team
- **Related:** [`../deviations-from-author.md`](../deviations-from-author.md) (2026-08-31 row), rules R10.3

## Context

.NET 10's `dotnet new sln` defaults to the newer XML-based **`.slnx`** format. The course,
our own docs, CI workflows, and agent instructions all say `dotnet build Evently.sln`, and
tooling support for `.slnx` is still uneven.

## Decision

Keep the **classic `Evently.sln`** format (created with `dotnet new sln --format sln`). All
documented commands and CI stay `Evently.sln`. CI's solution-detection prefers `Evently.slnx`
if it ever appears, so a later switch is low-friction.

## Consequences

### Good

- Every `dotnet build Evently.sln` / `dotnet test Evently.sln` in the docs, skills, agents,
  and CI just works.
- Broadest tooling compatibility (older MSBuild, third-party tools).

### Trade-offs

- The `.sln` GUID/section format is verbose and merge-unfriendly as modules are added.
- We're deliberately not using the current default, so `dotnet new sln` needs the
  `--format sln` flag.

### Follow-ups

- Revisit once `.slnx` tooling is universal and the noise of the classic format (many
  projects) outweighs the compatibility win.

## Alternatives considered

- **Adopt `.slnx` now.** Rejected: would require updating every doc/CI reference and betting
  on tooling that isn't fully there.
