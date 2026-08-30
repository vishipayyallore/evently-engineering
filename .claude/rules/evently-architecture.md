# Evently Architecture Rules

## 1. Boundary rules

- Keep Domain free of infrastructure and presentation concerns.
- Keep Application focused on orchestration, validation, and use case logic.
- Keep Infrastructure focused on persistence, message bus, integrations, and background jobs.
- Keep Presentation focused on endpoints and adapters.

## 2. Module rules

- Treat each module as owning its domain model, application layer, infrastructure, and presentation surface.
- Do not allow module-to-module dependencies except through explicit integration contracts.
- Prefer one module owning one business capability; do not create cross-cutting feature folders.

## 3. Eventing and messaging rules

- Use domain events for in-module state transitions.
- Use integration events for cross-module communication.
- Preserve outbox/inbox patterns for reliability.
- Ensure event handlers are idempotent and safe for retries.

## 4. Quality gates

- Follow the repository build and analyzer settings.
- Treat warnings as errors.
- Keep code style consistent with repository conventions.
- Preserve architecture test enforcement.

## 5. Validation rules

- Validate with the smallest relevant command that checks the changed behavior.
- Prefer solution-level validation for cross-module work.
- If a change impacts multiple modules or shared infrastructure, run the broader relevant test set.

## 6. Learning-tracker rule

- The tracker repo stores notes, ideas, and progress.
- All production code work belongs in the sibling Evently source repo.
- Summaries should point back to the canonical source files instead of duplicating implementation details into the tracker.
