---
name: evently-integration-event
description: Wire cross-module communication in Evently (C:\GitHub\evently-learning-tracker) — publish an integration event from one module and consume it in another via the outbox/inbox. Use when a change in one module (Events, Users, Ticketing, Attendance) must cause an effect in another module, or the task mentions integration events, module-to-module messaging, or "keep a local copy".
---

# Wire an integration event between Evently modules

Work in `C:\GitHub\evently-learning-tracker`. Rules R1, R7 in
[`.claude/rules/evently-engineering-rules.md`](../../rules/evently-engineering-rules.md).
Use `docs/architecture/evently-deep-dive.md` as a comparison reference when the author's pattern helps explain the design.

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

## Validate

```
dotnet build Evently.sln
dotnet test --filter "FullyQualifiedName~Evently.ArchitectureTests"          # module isolation + naming
dotnet test --filter "FullyQualifiedName~Evently.Modules.<Consumer>.IntegrationTests"
```
Write an integration test that publishes the event (or triggers the producer use case) and
uses the `Poller` to assert the consumer's state converged.
