# evently-integration-event

Wire cross-module communication in Evently (`C:\GitHub\evently-learning-tracker`): publish an integration
event from one module and consume it in another via the outbox/inbox.

**Canonical, full instructions:** [`.claude/skills/evently-integration-event/SKILL.md`](../../../.claude/skills/evently-integration-event/SKILL.md)

Flow: `aggregate.Raise(XDomainEvent)` → outbox → `XDomainEventHandler` (Application) →
`IEventBus.PublishAsync(XIntegrationEvent)` → MassTransit (in-memory) →
`IntegrationEventConsumer<T>` → inbox → `XIntegrationEventHandler` (Presentation) →
`ISender.Send(SomeCommand)`.

Producer: add `sealed record : IntegrationEvent` to `*.IntegrationEvents` (primitives only,
additive only); publish from a domain-event handler via `IEventBus` (never from a command
handler). Consumer: reference the producer's `*.IntegrationEvents` project (the only allowed
cross-module reference); register `IntegrationEventConsumer<T>` in `XModule.ConfigureConsumers`;
add `internal sealed class …IntegrationEventHandler : IntegrationEventHandler<T>` in
`*.Presentation` that sends a command and throws `EventlyException` on failure. The target
command must be logically idempotent. Validate with the architecture tests + a consumer
integration test using `Poller`.
