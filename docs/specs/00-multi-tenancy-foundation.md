# Spec 00: Multi-tenancy foundation

**Status:** Drafting (Pass 1 — only pass)
**Date:** 2026-05-15

## What this spec covers

Three pieces of foundational code that have to exist before Module 1 Pass 2 begins:

1. An `Organisation` model and table
2. The link from `User` to `Organisation`
3. A `Tenanted` concern that domain models opt into for automatic tenant scoping

This is the work ADR 0001 (multi-tenancy from day one) commits the platform to, made concrete. Until this lands, no Module 1 model can be built without violating the architectural constraint.

## Why this is its own spec

ADR 0001 is the *commitment*. Module 1 Pass 1 is the *first feature spec*. This document sits between them — it's the *implementation foundation* that both Module 1 and every subsequent module depend on. Treating it as a separate spec means:

- The foundation is documented and reviewable on its own terms
- Module 1 Pass 2 can reference "the Tenanted concern from Spec 00" without re-explaining the pattern
- Future modules (Site Safety, Subcontractor Portal) get the same foundation, not re-invented per module

## Relationship to ADR 0001

ADR 0001 sketched the implementation as "`Current.organisation` set in `ApplicationController` via a `before_action`." This spec uses **delegation through the existing `Current.session` → `Current.user` chain** instead. The architectural commitment in ADR 0001 (every domain model belongs to an Organisation; tenant scoping enforced at the model layer via `Current.organisation_id`) is preserved. Only the mechanism for populating `Current.organisation` differs, in order to match the existing Rails 8 auth scaffold pattern. ADR 0001 is not superseded.

## What it owns

### Organisation model

A new `organisations` table with these columns:

- `id` — bigint primary key, Rails default
- `name` — string, NOT NULL — human-readable display name (e.g. "James Building & Property Services")
- `slug` — string, NOT NULL, unique — short URL-safe identifier (e.g. "jbps"), used for seeding, admin lookups, and future subdomain routing
- `created_at`, `updated_at` — timestamps

Indexes:

- Unique index on `slug`

The model file lives at `app/models/organisation.rb`. Validations:

- `name` present
- `slug` present, unique (case-insensitive), format constrained to lowercase letters, digits, and hyphens

Associations:

- `has_many :users, dependent: :restrict_with_exception` (deleting an org with users should fail loudly, not silently orphan users)
- (Future: `has_many :projects`, `has_many :sites`, etc. — added per-module when those models exist)

### User model changes

The existing `User` model gains:

- `organisation_id` column on the users table — bigint, NOT NULL, foreign key to organisations
- `belongs_to :organisation` association
- An index on `(organisation_id, email_address)` — the existing unique index on `email_address` alone may need to become per-organisation, but for the pilot phase one user per email globally is fine. See Open Questions.

Existing User code (`has_secure_password`, `has_many :sessions`, `normalizes :email_address`) is untouched.

### Current model changes

The existing `app/models/current.rb`:

```ruby
class Current < ActiveSupport::CurrentAttributes
  attribute :session
  delegate :user, to: :session, allow_nil: true
end
```

Gains one line:

```ruby
delegate :organisation, to: :user, allow_nil: true
```

`Current.organisation` then resolves through `Current.session.user.organisation`. No before_action required. `allow_nil: true` means it returns `nil` when there's no session, no user, or no organisation — all of which are non-error cases (unauthenticated requests, etc.).

### Tenanted concern

A new file at `app/models/concerns/tenanted.rb`:

```ruby
module Tenanted
  extend ActiveSupport::Concern

  included do
    belongs_to :organisation
    default_scope { where(organisation_id: Current.organisation_id) if Current.organisation_id }
  end
end
```

Domain models opt in: `include Tenanted`. The concern:

- Establishes the `belongs_to :organisation` association
- Applies a default scope that filters by `Current.organisation_id` *only when one is set* — so admin scripts, console sessions, and Sidekiq jobs without a Current context aren't accidentally locked out
- When `Current.organisation_id` is nil, no scope is applied — the burden shifts to the caller to scope explicitly, which is correct for those contexts

### Authentication concern changes

The existing `Authentication` concern has a `find_session_by_cookie` method. Update it to preload the organisation:

```ruby
Session.includes(user: :organisation).find_by(id: cookies.signed[:session_id])
```

This avoids N+1 queries when `Current.organisation` is read during a request — the chain `session → user → organisation` is resolved in one query at session load time, not three queries per call to `Current.organisation`.

## Migration sequence

For the pilot phase (one tenant, no production traffic on these tables yet), a single migration is acceptable. The structure:

```ruby
class CreateOrganisationsAndLinkUsers < ActiveRecord::Migration[8.0]
  def up
    create_table :organisations do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.timestamps
    end
    add_index :organisations, :slug, unique: true

    # Seed JBPS as Organisation #1 (idempotent)
    say_with_time "Seeding JBPS as Organisation #1" do
      execute <<~SQL
        INSERT INTO organisations (name, slug, created_at, updated_at)
        SELECT 'James Building & Property Services', 'jbps', NOW(), NOW()
        WHERE NOT EXISTS (SELECT 1 FROM organisations WHERE slug = 'jbps')
      SQL
    end

    # Add organisation_id to users, nullable initially for backfill
    add_reference :users, :organisation, foreign_key: true

    # Backfill existing users to JBPS
    say_with_time "Backfilling users to JBPS" do
      execute <<~SQL
        UPDATE users SET organisation_id = (SELECT id FROM organisations WHERE slug = 'jbps')
        WHERE organisation_id IS NULL
      SQL
    end

    # Now enforce NOT NULL
    change_column_null :users, :organisation_id, false
  end

  def down
    remove_reference :users, :organisation, foreign_key: true
    drop_table :organisations
  end
end
```

Key points:

- **Single migration is acceptable for the pilot.** When productisation happens and there are real customers on populated tables, the multi-step deploy pattern (add nullable column → deploy → backfill → deploy → add NOT NULL → deploy) becomes necessary. This is a future concern, not now.
- **The JBPS seed uses raw SQL with an idempotency guard.** Running the migration on a database that already has the JBPS row (e.g. a fresh production deploy after the dev database was already migrated) won't fail.
- **The backfill is also idempotent** via the `WHERE organisation_id IS NULL` filter.
- **The down migration removes the column and table** but doesn't try to un-seed JBPS. Reversing a seed is messy; if you really need to roll back, drop the column and table is sufficient.

## Tests required

This is the verification that the foundation actually works. Three mandatory tests:

### Test 1 — Organisation model basics

`test/models/organisation_test.rb`:

- Valid with name and slug
- Invalid without name
- Invalid without slug
- Invalid with duplicate slug (case-insensitive)
- Invalid with slug containing uppercase or special characters
- `dependent: :restrict_with_exception` — destroying an organisation with users raises

### Test 2 — User-to-Organisation linkage

`test/models/user_test.rb` (currently empty):

- A User must have an organisation_id (NOT NULL enforced)
- `user.organisation` returns the right Organisation
- The seeded JBPS user (or test fixtures) is linked to Organisation #1

### Test 3 — Tenanted concern isolates data

A test that creates two organisations, two users (one per org), creates a Tenanted record under org A, and asserts org B's user cannot see it.

This test uses a *minimal Tenanted model created in the test context* — not an actual domain model (Project doesn't exist yet). One option: a dummy `TenantedTestRecord` model defined only in the test, included in the concern, and used to verify scoping behaviour. The Tenanted concern is verified in isolation, independent of any domain model.

Test file: `test/models/concerns/tenanted_test.rb`

Pseudocode:

```ruby
class TenantedTest < ActiveSupport::TestCase
  test "default_scope filters by Current.organisation_id" do
    org_a = Organisation.create!(name: "Org A", slug: "org-a")
    org_b = Organisation.create!(name: "Org B", slug: "org-b")

    # Create a record under org_a
    Current.organisation = org_a
    record_a = TenantedTestRecord.create!(name: "A's record")

    # Switch to org_b
    Current.organisation = org_b
    assert_nil TenantedTestRecord.find_by(id: record_a.id), "Org B should not see Org A's record"

    # Unscope explicitly should see both
    assert_not_nil TenantedTestRecord.unscoped.find_by(id: record_a.id)
  end
end
```

The `TenantedTestRecord` model and its table can be created in test setup or via a dedicated test-only migration. Implementation detail.

### Tests deliberately NOT in scope

- Backfilling existing auth controllers (SessionsController, PasswordsController) with tests. The audit noted these are untested; that's a separate piece of debt. The foundation work doesn't depend on those tests passing, and adding them would balloon this spec.
- Integration tests covering full login → tenant-scoped query → render. Those come naturally when Module 1 has UI to test.

## What this spec does NOT cover

- **Per-Organisation branding, theming, marketing site content** — Phase 2 concern (DWJ Studio done-for-you). v1 marketing site stays hardcoded JBPS.
- **Subdomain routing** — Phase 2/3 concern. v1 uses path-based `/app/` namespace per Module 1 spec.
- **Admin UI for managing Organisations** — there's no admin panel. New organisations are created via `bundle exec rails runner` or `db/seeds.rb` for the pilot phase.
- **Multi-organisation users** — one user belongs to one organisation. A user who needs access to two organisations needs two accounts. Revisit when there's a real requirement.
- **Role/permission system within an organisation** — every authenticated user in an organisation has the same access. RBAC is a future concern, separate spec.
- **Cross-organisation features** — white-labelling, parent-org hierarchies, shared subcontractor pools. All non-goals per ADR 0001.
- **Logout UI / login link in nav** — separate small spec, not blocking foundation.
- **Auth test coverage for the existing scaffold** — separate debt, not blocking foundation.

## Acceptance criteria

The foundation is complete when:

1. `bundle exec rails db:migrate` runs cleanly. `db/schema.rb` shows `organisations` table and `organisation_id` on `users`.
2. JBPS exists as Organisation #1 with slug `jbps`, verifiable via `bundle exec rails runner "puts Organisation.find_by(slug: 'jbps').name"`.
3. The existing dev user is linked to JBPS, verifiable via `bundle exec rails runner "puts User.first.organisation.slug"`.
4. `app/models/current.rb` delegates `organisation` through `user`. `Current.organisation` returns the right object during an authenticated request.
5. `app/models/concerns/tenanted.rb` exists with the documented implementation.
6. The three test files exist and pass: `organisation_test.rb`, `user_test.rb` (with org linkage tests), and `tenanted_test.rb`.
7. `bundle exec rails test` runs clean — all tests pass, including the existing 16 from before.
8. CI on push is green (lint, security scans, tests).
9. The public marketing site (jbps.com.au or local equivalent) still loads and the enquiry form still submits. No regression.

## Open questions (resolve before later phases)

- **Email uniqueness scope:** the existing unique index is on `email_address` alone (globally unique). When productisation happens, the same email might be a user in multiple organisations. Then the unique index needs to become `(organisation_id, email_address)`. Deferred — for the pilot, one email = one user globally is fine.
- **Slug update protection:** can an organisation's slug change after creation? Probably not (it'd break any URL or external reference). Worth being explicit when adding admin UI later — likely add a database-level check or a model-level guard.
- **Seed strategy for productisation:** when DWJ Studio onboards a new builder, how do they get their Organisation row? Via admin command? Via a self-serve form (Phase 3)? Deferred.
- **Sidekiq / background jobs:** when a job runs without a request context, `Current.organisation` is nil. Each job needs to set `Current.organisation = Organisation.find(args[:org_id])` at the start. Pattern to document when the first background job is built; not now.

## Non-goals (foundation v1)

- Multi-step migrations (single migration is fine for pilot phase)
- Postgres row-level security policies (ADR 0001 explicitly excludes this)
- Schema-per-tenant or database-per-tenant (excluded)
- Admin UI for organisations
- Tenant-aware audit logging
- Role/permission system
- Subdomain routing
- Self-serve organisation signup
