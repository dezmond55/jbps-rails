# Status

_Last updated: 2026-05-13_

## Current focus

Module 1 Pass 1 spec landed. Build sequence for Module 1 is now: (1) User authentication, (2) Organisation model and multi-tenancy plumbing per ADR 0001, (3) Module 1 Pass 2 (data model in field-level detail), then later passes for operations and acceptance tests.

## In flight

Nothing in code.

## Blocked

Nothing.

## Next

Module 1 Pass 2 — data model in field-level detail. To happen in a future session in the strategy Project (not Claude Code), once Derek is fresh. Then prerequisite auth + Organisation work begins.

## Known debt

- Six unreferenced JS files in `app/javascript/` (`counter.js`, `enquiry_form.js`, `nav.js`, `reveal.js`, `services.js`, `smooth_scroll.js`) — investigated this session, see `docs/status-js-cleanup.md`. Deletion deferred to a future session.
- Layout inline JS (~90 lines in `app/views/layouts/application.html.erb`, lines 79–165) should be ported to Stimulus controllers before Module 2 begins. Use that as the Stimulus learning ramp before the platform's mobile UI work depends on it.
- The repo lives in OneDrive (`C:\Users\borbu\OneDrive\Documents\jbps\jbps-rails`). OneDrive Files On-Demand has caused at least one observable problem (`findstr` recursion failed on reparse points). Evaluate relocating to `C:\dev\jbps-rails` before Module 1 code work begins.
- GitHub Actions Node 20 runtime deprecation — deprecation warnings are already firing on CI runs. Hard deadline 2026-06-02, when GitHub stops running Node 20-based actions by default. Bump action versions in `.github/workflows/ci.yml` (`actions/checkout`, `actions/setup-node`, `ruby/setup-ruby`, `actions/upload-artifact`) to Node 24-based releases before that date.
- CI feedback wasn't being checked between sessions — established that lint job runs on every push, watch the GitHub Actions output as part of session close.
