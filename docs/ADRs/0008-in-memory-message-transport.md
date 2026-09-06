# ADR-0008 — In-memory message transport for now

- **Status:** Accepted
- **Date:** 2026-09-06
- **Deciders:** Evently team
- **Related:** ADR-0006 (outbox/inbox), deep-dive §6b, §9

## Context

**[Phase 2].** Cross-module messaging (ADR-0006) needs a transport under `IEventBus` /
MassTransit. A real broker (RabbitMQ, Azure Service Bus) means another container to run,
learn, and operate — and while Evently is a single deployable there is no cross-process
delivery to do.

## Decision

Use **MassTransit's in-memory transport** (`UsingInMemory`) while Evently is one deployable,
matching the course default. The durability guarantee comes from the **outbox/inbox tables**,
not the transport — so the bus can be swapped without touching producers or consumers. Saga
state persists in **Redis**, not in the bus.

## Consequences

### Good

- One fewer container; faster local loop and CI.
- The outbox/inbox design is exercised end-to-end regardless of transport.
- Swapping to RabbitMQ later is a composition-root change (`UsingRabbitMq(...)`).

### Trade-offs

- The in-memory bus is **not durable and not cross-process** — if the process dies between
  "outbox row processed" and "consumer inbox row written", that hop relies on the outbox
  retry, and there is no delivery across instances. Acceptable only while single-process.
- Some broker behaviors (competing consumers, dead-letter queues, real backpressure) aren't
  represented, so integration tests can be optimistic.

### Follow-ups

- Choose and ADR a real broker **before** running more than one instance or splitting the
  deployable. Revisit this ADR then.

## Alternatives considered

- **RabbitMQ from the start.** Rejected: operational weight with no cross-process delivery to
  justify it yet.
- **No bus — call inbox writers directly.** Rejected: couples modules and loses the
  transport seam we want for Phase 2's later steps.
