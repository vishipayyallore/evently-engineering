# ADR-0006 — Outbox/inbox for cross-module messaging

- **Status:** Accepted
- **Date:** 2026-09-06
- **Deciders:** Evently team
- **Related:** ADR-0002 (Phase 2), ADR-0007 (schema per module), ADR-0008 (transport), deep-dive §6, rules R1, R7; outbox-inbox and saga diagrams

## Context

**[Phase 2].** Once modules are isolated they must not call each other directly — that would
recreate the coupling we are trying to remove. Cross-module effects still need to be reliable:
if "event published" must create a local copy in Attendance, we cannot lose that on a crash
or a transient bus failure, and we cannot leave the producer's transaction hostage to the
consumer.

## Decision

Modules communicate **only** via another module's `*.IntegrationEvents` assembly, **async**.
The flow: an aggregate raises a **domain event** → the `InsertOutboxMessagesInterceptor`
writes it to `<schema>.outbox_messages` **in the same transaction** as the aggregate →
`ProcessOutboxJob` (Quartz) dispatches it to a domain-event handler → the handler publishes an
**integration event** via `IEventBus` → the consuming module's `IntegrationEventConsumer<T>`
writes it to `<schema>.inbox_messages` → `ProcessInboxJob` dispatches it to an
`IntegrationEventHandler` in Presentation, which translates it into a local command.
`Idempotent*` decorators + `*_message_consumers` tables give exactly-once *processing*;
handlers must also be logically idempotent. Multi-module coordinated workflows use a
MassTransit **saga** (state in Redis).

## Consequences

### Good

- The producer commits atomically; delivery is guaranteed by the outbox, independent of the
  bus being up.
- Redelivery is safe by construction; each module keeps its own local copy of what it needs.
- No shared tables, no cross-schema queries, no synchronous fan-out.

### Trade-offs

- **Eventual consistency** — the consumer converges after a poll interval, not immediately.
  Tests assert outcomes with a `Poller`.
- More infrastructure: two jobs, two tables, and consumer-dedup tables per module.
- Debugging spans producer transaction → job → bus → consumer transaction → job.

### Follow-ups

- Tune poll interval / batch size per module via `modules.<name>.json`.
- Decide a real broker before any non-local deployment (ADR-0008).

## Alternatives considered

- **Direct in-process calls between modules.** This *is* Phase 1; rejected for Phase 2 —
  reintroduces compile-time coupling.
- **Publish straight to the bus from the command handler.** Rejected: a bus failure after
  commit loses the event; the outbox exists precisely to avoid that.
- **Shared database, read across schemas.** Rejected: couples modules through the schema and
  defeats isolation.
