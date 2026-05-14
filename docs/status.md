# Status

_Last updated: 2026-05-14_

## Current focus

User auth audit complete — see `docs/notes/user-auth-audit.md`. Finding: auth is stock `bin/rails generate authentication` output, wired into `ApplicationController`, fully functional (login, logout, password reset, IP rate limiting). Self-signup, roles, email confirmation, and tests are absent. **Critical gap:** `User` has no `organisation_id`, which conflicts with the CLAUDE.md non-negotiable that every User belongs to an Organisation. The auth generator ran before that rule was committed.

Build sequence for Module 1 is now: (1) User authentication — done as scaffold, no further work scheduled, (2) Multi-tenancy foundation (Organisation model, `Current.organisation`, `Tenanted` concern, backfill User with `organisation_id`), (3) Module 1 Pass 2 (data model in field-level detail), then later passes for operations and acceptance tests.

## In flight

Nothing in code.

## Blocked

Nothing.

## Next

Spec the multi-tenancy foundation at `/docs/specs/00-multi-tenancy-foundation.md` before any Module 1 Pass 2 work. Then build the foundation, then Pass 2.

## Known debt

- Six unreferenced JS files in `app/javascript/` (`counter.js`, `enquiry_form.js`, `nav.js`, `reveal.js`, `services.js`, `smooth_scroll.js`) — investigated this session, see `docs/status-js-cleanup.md`. Deletion deferred to a future session.
- Layout inline JS (~90 lines in `app/views/layouts/application.html.erb`, lines 79–165) should be ported to Stimulus controllers before Module 2 begins. Use that as the Stimulus learning ramp before the platform's mobile UI work depends on it.
- GitHub Actions Node 20 runtime deprecation — deprecation warnings are already firing on CI runs. Hard deadline 2026-06-02, when GitHub stops running Node 20-based actions by default. Bump action versions in `.github/workflows/ci.yml` (`actions/checkout`, `actions/setup-node`, `ruby/setup-ruby`, `actions/upload-artifact`) to Node 24-based releases before that date.
- CI feedback wasn't being checked between sessions — established that lint job runs on every push, watch the GitHub Actions output as part of session close.
