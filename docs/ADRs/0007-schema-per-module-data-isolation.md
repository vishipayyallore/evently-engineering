# ADR-0007 — Schema-per-module data isolation

- **Status:** Accepted
- **Date:** 2026-09-06
- **Deciders:** Evently team
- **Related:** ADR-0002 (Phase 2), ADR-0006 (messaging), deep-dive §5, rules R5

## Context

**[Phase 2].** In Phase 1 all four contexts share one database and tables. To make modules
genuinely isolated we need each to own its data, without paying for four database servers or
losing the single-transaction-per-request simplicity we get from one Postgres instance.

## Decision

One PostgreSQL database, **one schema per module** (`users`, `events`, `ticketing`,
`attendance`). Each module has its own `sealed DbContext : DbContext, IUnitOfWork` with
`HasDefaultSchema(Schemas.X)`, `UseSnakeCaseNamingConvention()`, and a per-schema migrations
history table. A module's tables — including its own `outbox_messages` / `inbox_messages` /
`*_message_consumers` — live only in its schema. No module reads another module's schema;
cross-module data flows as integration events (ADR-0006). Carts are the exception: Redis
only, no table.

## Consequences

### Good

- Logical isolation (course "Level 2+"): a module can only touch its own tables, enforceable
  and obvious.
- Still one connection, one instance, one `docker compose` service; migrations run per
  `DbContext`.
- A future split to separate databases is a connection-string change, not a rewrite.

### Trade-offs

- No cross-schema joins — reporting that spans modules needs a read model fed by events.
- Four `DbContext`s, four migration histories, four sets of outbox/inbox plumbing.
- Referential integrity stops at the schema boundary; consistency across modules is eventual.

### Follow-ups

- Phase 2 step 3: add the per-schema `DbContext` split and the `Create_Database` migrations.

## Alternatives considered

- **Shared schema, discipline only.** This is Phase 1; rejected for Phase 2 — nothing stops
  a cross-context query.
- **Database per module now.** Rejected: operational overhead and distributed-transaction
  concerns before we need them.
- **Separate `__EFMigrationsHistory` per module in the shared schema.** Rejected: schema is
  the natural, visible boundary.
