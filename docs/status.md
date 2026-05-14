# Status

_Last updated: 2026-05-13_

## Current focus

Repo relocated this session from `C:\Users\borbu\OneDrive\Documents\jbps\jbps-rails` to `C:\dev\jbps-rails`. Old location archived as `jbps-rails-ARCHIVED-2026-05-13` in the OneDrive parent folder. Git remains the source of truth across machines.

Module 1 Pass 1 spec landed. Build sequence for Module 1 is now: (1) User authentication, (2) Organisation model and multi-tenancy plumbing per ADR 0001, (3) Module 1 Pass 2 (data model in field-level detail), then later passes for operations and acceptance tests.

## In flight

Nothing in code.

## Blocked

Nothing.

## Next

First move in the next strategic session: audit what's actually in the existing User/auth setup. Migrations `20260218133054_create_users.rb` and `20260218133102_create_sessions.rb` already exist on disk — the Pass 1 spec lists auth as a prerequisite to be built, but it may already be done. Update Module 1 prerequisite status accordingly before scheduling further auth work.

Then: Module 1 Pass 2 — data model in field-level detail. To happen in a future session in the strategy Project (not Claude Code), once Derek is fresh. Any remaining prerequisite Organisation work follows.

## Known debt

- Six unreferenced JS files in `app/javascript/` (`counter.js`, `enquiry_form.js`, `nav.js`, `reveal.js`, `services.js`, `smooth_scroll.js`) — investigated this session, see `docs/status-js-cleanup.md`. Deletion deferred to a future session.
- Layout inline JS (~90 lines in `app/views/layouts/application.html.erb`, lines 79–165) should be ported to Stimulus controllers before Module 2 begins. Use that as the Stimulus learning ramp before the platform's mobile UI work depends on it.
- GitHub Actions Node 20 runtime deprecation — deprecation warnings are already firing on CI runs. Hard deadline 2026-06-02, when GitHub stops running Node 20-based actions by default. Bump action versions in `.github/workflows/ci.yml` (`actions/checkout`, `actions/setup-node`, `ruby/setup-ruby`, `actions/upload-artifact`) to Node 24-based releases before that date.
- CI feedback wasn't being checked between sessions — established that lint job runs on every push, watch the GitHub Actions output as part of session close.
