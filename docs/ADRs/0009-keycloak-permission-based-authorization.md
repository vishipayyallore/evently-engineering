# ADR-0009 — Keycloak + permission-based authorization

- **Status:** Accepted
- **Date:** 2026-09-06
- **Deciders:** Evently team
- **Related:** deep-dive §8, rules R6.3; `Common.Infrastructure/Authentication` + `Authorization`

## Context

Evently needs authenticated users, and endpoints need fine-grained authorization
("events:update", "ticket-types:read") rather than coarse roles. We also want identity to be
an external concern the Users module owns and syncs to, not something hand-rolled.

## Decision

Identity is **Keycloak** (`Evently.Identity`, realm imported from
`.files/evently-realm-export.json`), OIDC + JWT bearer. Authorization is
**permission-based**, via `PermissionAuthorizationPolicyProvider`,
`PermissionAuthorizationHandler`, and `PermissionRequirement`, with `CustomClaimsTransformation`
loading a user's permissions from the Users module via `IPermissionService` (cached). Endpoints
declare
`.RequireAuthorization(Permissions.<X>)` where `Permissions` is an `internal static class` of
`"<resource>:<action>"` string constants. The Users module owns `User`/`Role`/`Permission`
and syncs to Keycloak through `IIdentityProviderService` → `KeyCloakClient`.

## Consequences

### Good

- Standard OIDC/JWT; no credential handling in Evently.
- Endpoint authorization is declarative and greppable; permissions are data, editable per
  role without redeploy.
- Users module is the single source of truth for who-can-do-what.

### Trade-offs

- Keycloak is another container and another thing to configure (realm, clients, health URL).
- Integration tests that hit secured endpoints need a Keycloak Testcontainer (only the
  solution-level `test/Evently.IntegrationTests` pays this cost).
- Permission strings are stringly-typed; the `Permissions` constants and the realm must
  agree.

### Follow-ups

- Keep `Permissions.cs` and the realm export in sync as endpoints are added.

## Alternatives considered

- **Role-based `[Authorize(Roles=...)]`.** Rejected: too coarse; every permission change is a
  code change.
- **A different IdP (Auth0, Azure AD B2C, hand-rolled).** Rejected: Keycloak is the course
  choice, self-hostable, and free for local dev.
