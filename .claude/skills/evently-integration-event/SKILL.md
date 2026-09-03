---
name: evently-integration-event
description: Publish an integration event from one Evently module and consume it in another via the outbox/inbox. Use when a change in one module (Events, Users, Ticketing, Attendance) must cause an effect in another, or the task mentions integration events, module-to-module messaging, or "keep a local copy". Not for in-module domain events or adding the use case itself (use evently-vertical-slice).
---

# Wire an integration event between Evently modules

Work in this repo. Rules R1, R7 in
[`.claude/rules/evently-engineering-rules.md`](../../rules/evently-engineering-rules.md).
See `docs/architecture/evently-deep-dive.md` §6 for the full cross-module messaging design.

> **Build phase.** This whole skill is **[Phase 2]** (cross-module messaging). While we're
> still a monolith (Phase 1), a cross-module effect is a direct in-process call — do **not**
> wire the outbox/integration-event path until we begin modularizing. Numbered steps below
> start at 1, never 0.

## Not this skill

- **The producing or consuming use case doesn't exist yet** → build it first with
  `evently-vertical-slice`; this skill only wires the event between them.
- **An in-module reaction** (a projection, a follow-up in the same module) → that's a plain
  domain-event handler, part of `evently-vertical-slice`, not an integration event.
- **A workflow that must coordinate ≥2 other modules and wait for all of them** → that's a
  saga; stop and ask for the `architect` agent.
- **Changing an existing integration-event contract** (remove/retype a property) → not
  allowed (R7); ask the `architect` agent.

## Mental model

```
Producer module                                   Consumer module
──────────────                                    ───────────────
aggregate.Raise(XDomainEvent)                      IntegrationEventConsumer<T>  → inbox_messages
  → outbox_messages (same txn)                     ProcessInboxJob (Quartz)
ProcessOutboxJob (Quartz)                            → IdempotentIntegrationEventHandler<T>
  → XDomainEventHandler (Application)                → XIntegrationEventHandler (Presentation)
     → IEventBus.PublishAsync(XIntegrationEvent)       → ISender.Send(SomeCommand)
        → MassTransit (in-memory bus)
```

## Producer side

1. **Contract** — in `src/Modules/<Producer>/Evently.Modules.<Producer>.IntegrationEvents/`:
   ```csharp
   public sealed class <Name>IntegrationEvent : IntegrationEvent
   {
       public <Name>IntegrationEvent(Guid id, DateTime occurredOnUtc, /* payload */ Guid entityId)
           : base(id, occurredOnUtc)
       {
           EntityId = entityId;
       }
       public Guid EntityId { get; init; }
   }
   ```
   Primitives only. Additive changes only — never remove/retype an existing property.

2. **Domain event** exists on the aggregate (add one via the `evently-vertical-slice` skill if
   not).

3. **Domain-event handler** — in `*.Application/<Aggregate>/<UseCase>/<X>DomainEventHandler.cs`:
   ```csharp
   internal sealed class <X>DomainEventHandler(IEventBus eventBus)
       : DomainEventHandler<<X>DomainEvent>
   {
       public override async Task Handle(<X>DomainEvent domainEvent, CancellationToken cancellationToken = default) =>
           await eventBus.PublishAsync(
               new <Name>IntegrationEvent(domainEvent.Id, domainEvent.OccurredOnUtc, domainEvent.EntityId),
               cancellationToken);
   }
   ```
   If the event needs a fuller payload, `ISender.Send(new GetXQuery(...))` first and map the
   response (see `EventPublishedDomainEventHandler`).
   Registered automatically by `AddXModule` → `AddDomainEventHandlers` (scans the assembly).

## Consumer side

4. **Reference** the producer's `*.IntegrationEvents` project from the consumer's
   `*.Presentation` (and/or `*.Infrastructure`) `.csproj`. This is the only allowed
   cross-module reference.

5. **Register the MassTransit consumer** in the consumer module's
   `*.Infrastructure/<Module>Module.cs` → `ConfigureConsumers`:
   ```csharp
   registration.AddConsumer<IntegrationEventConsumer<<Name>IntegrationEvent>>();
   ```
   (match how sibling events are registered in that module).

6. **Integration-event handler** — in `*.Presentation/<Aggregate>/<Name>IntegrationEventHandler.cs`:
   ```csharp
   internal sealed class <Name>IntegrationEventHandler(ISender sender)
       : IntegrationEventHandler<<Name>IntegrationEvent>
   {
       public override async Task Handle(<Name>IntegrationEvent integrationEvent, CancellationToken cancellationToken = default)
       {
           Result result = await sender.Send(new <SomeCommand>(integrationEvent.EntityId, ...), cancellationToken);
           if (result.IsFailure)
               throw new EventlyException(nameof(<SomeCommand>), result.Error);
       }
   }
   ```
   `internal sealed`, name ends `IntegrationEventHandler`. Registered automatically by
   `AddXModule` → `AddIntegrationEventHandlers`.

7. The target command must be **idempotent** (the event may be delivered more than once):
   check-then-act, or upsert, keyed by the producer's id.

## Done when

- [ ] Contract is a `sealed record : IntegrationEvent` in the producer's `*.IntegrationEvents`,
      primitives only.
- [ ] Published only from a domain-event handler via `IEventBus.PublishAsync` — never from a
      command handler.
- [ ] Consumer references **only** the producer's `*.IntegrationEvents` project (R1).
- [ ] `IntegrationEventConsumer<T>` registered in the consumer's `ConfigureConsumers`;
      `<Name>IntegrationEventHandler` (`internal sealed`) added in the consumer's `*.Presentation`.
- [ ] The command the handler sends is logically idempotent (check-then-act / upsert, keyed
      by the producer's id).
- [ ] Integration test: trigger the producer use case, use `Poller` to assert the consumer's
      state converged.
- [ ] `dotnet build Evently.sln` — 0 warnings.
- [ ] `dotnet test --filter "FullyQualifiedName~Evently.ArchitectureTests"` green (module
      isolation + naming), then `dotnet test Evently.sln` green.
- [ ] Report: producer + consumer files, rule numbers, test output.
