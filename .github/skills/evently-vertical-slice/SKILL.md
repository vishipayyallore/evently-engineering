# evently-vertical-slice

Add a new use case (command or query) to an Evently module end-to-end in
`C:\GitHub\evently-engineering`, following the CQRS conventions.

**Canonical, full instructions:** [`.claude/skills/evently-vertical-slice/SKILL.md`](../../../.claude/skills/evently-vertical-slice/SKILL.md)

> **Build phase.** Applies from **Phase 1**; in Phase 1 the module is a **folder**, not a
> project, and the `*.IntegrationEvents` step is **[Phase 2]**. Steps start at 1, never 0.

Quick shape (see canonical file for templates and validation steps):
1. Command vs query — command changes state (EF + repo + `IUnitOfWork`); query reads
   (Dapper + `IDbConnectionFactory`, no EF).
2. Create the slice folder `*.Application/<Aggregate>/<UseCase>/` with `…Command`/`…Query`
   (`public sealed record`), `…CommandHandler`/`QueryHandler` (`internal sealed`),
   `…CommandValidator` (`internal sealed`, structural only).
3. Put invariants + domain events on the aggregate (`static Result<T> Create`, methods that
   `Raise(...)`). Errors go in `<Aggregate>Errors.cs`.
4. Endpoint: `internal sealed class <UseCase> : IEndpoint`, `result.Match(Results.Ok,
   ApiResults.Problem)`, `.RequireAuthorization(Permissions.X)`, `.WithTags(Tags.X)`.
5. Tests: unit for aggregate behavior, integration through `ISender`.
6. Migration if an entity config / `DbSet` changed.
7. `dotnet build Evently.sln` && `dotnet test Evently.sln` green.
