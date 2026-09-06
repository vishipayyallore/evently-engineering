# evently-integration-event

Wire cross-module communication in Evently (`C:\GitHub\evently-engineering`): publish an integration
event from one module and consume it in another via the outbox/inbox.

**Canonical, full instructions:** [`.claude/skills/evently-integration-event/SKILL.md`](../../../.claude/skills/evently-integration-event/SKILL.md)

> **Build phase.** This whole skill is **[Phase 2]**. While we're a monolith (Phase 1), a
> cross-module effect is a direct in-process call — don't wire this yet. Steps start at 1, never 0.

Flow: `aggregate.Raise(XDomainEvent)` → outbox → `XDomainEventHandler` (Application) →
`IEventBus.PublishAsync(XIntegrationEvent)` → MassTransit (in-memory) →
`IntegrationEventConsumer<T>` → inbox → `XIntegrationEventHandler` (Presentation) →
`ISender.Send(SomeCommand)`.

Producer: add `public sealed class : IntegrationEvent` to `*.IntegrationEvents` (ctor chains
`: base(id, occurredOnUtc)`, `{ get; init; }` props, primitives only, additive only); publish
from a domain-event handler via `IEventBus` (never from a command handler). Consumer: reference
the producer's `*.IntegrationEvents` project (the only allowed
cross-module reference); register `IntegrationEventConsumer<T>` in `XModule.ConfigureConsumers`;
add `internal sealed class …IntegrationEventHandler : IntegrationEventHandler<T>` in
`*.Presentation` that sends a command and throws `EventlyException` on failure. The target
command must be logically idempotent. Validate with the architecture tests + a consumer
integration test using `Poller`.

A **saga** (coordinate ≥2 other modules) or a **new consumer→producer direction** is a
structural decision — ask the `architect` for a ruling + an ADR, and add/adjust the edge in
`docs/mermaid-diagrams/system-context.mmd`.
