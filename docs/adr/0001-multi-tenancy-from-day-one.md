# ADR 0001: Multi-tenancy from day one

**Date:** 2026-05-07
**Status:** Proposed

## Context

JBPS is the pilot tenant of a platform we want to productise. The commercial vehicle (DWJ Technical Studio) will eventually onboard other construction principals — competitors and complements alike — onto the same Rails codebase. That second organisation may be a year away or it may be next quarter; the discipline question is "does today's code work if a second organisation signs up tomorrow?"

Retrofitting multi-tenancy later is expensive. Every query needs scoping, every fixture needs an organisation, every URL and form needs to know which tenant it belongs to. The cost of doing it now — one column, one scope, one before_action — is small. The cost of doing it later — backfilling every row in production, finding every unscoped query before the second tenant sees the first tenant's data — is large.

The platform handles compliance-sensitive data: induction records, SWMS, CM3 status, attendance logs. A cross-tenant data leak is not just embarrassing; in this domain it's the kind of mistake that loses clients.

## Decision

The platform is multi-tenant from the first migration that creates a domain table.

- Every domain table has an `organisation_id bigint NOT NULL` column with a foreign key to `organisations.id`.
- The current organisation lives on `ActiveSupport::CurrentAttributes` (`Current.organisation`), set from the authenticated user in an `ApplicationController` `before_action`.
- Tenant scoping is homegrown — `belongs_to :organisation` plus a default scope keyed off `Current.organisation_id` on each model. We are not adopting `acts_as_tenant` or similar; one fewer dependency, behaviour stays in this codebase.
- Cross-tenant access returns 404, not 403. The existence of another organisation's records is itself privileged information.

## Consequences

Every domain model gets `belongs_to :organisation` and a default scope keyed off `Current.organisation_id`. Every test that touches persistence creates two organisations and asserts they don't see each other. Background jobs take `organisation_id` as an argument. Composite indexes lead with `organisation_id`. Bypasses use `unscoped` explicitly with a comment.

## Non-goals

- **No Postgres row-level security policies.** RLS is powerful and out of proportion to the threat model at this scale. Application-layer scoping is sufficient.
- **No schema-per-tenant.** A separate schema per organisation would force every migration to be applied N times, complicate joins, and make the cross-tenant reporting we'll eventually want for product analytics painful.
- **No database-per-tenant.** Same problems as schema-per-tenant, plus operational cost. We are running on Heroku Postgres; multiplying databases multiplies bills.
- **No subdomain routing yet.** The data model is designed not to preclude it; the controller layer will gain a subdomain-based tenant resolver when there's a second tenant to point at.
- **No self-serve signup or billing.** Onboarding a new organisation will be a manual operator task (rake/console) until the commercial pathway justifies the build.
- **No cross-tenant features.** White-labelling, parent-org hierarchies, shared subcontractor pools — all out of scope. If they become needed, they will be a new ADR.
- **No bypass framework.** Cross-tenant operations use `unscoped` with a comment, not a "platform admin" role or audited-access wrapper. We'll build that abstraction when there's concrete demand, not before.
