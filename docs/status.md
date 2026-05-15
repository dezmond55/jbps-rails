# Status

_Last updated: 2026-05-15_

## Current focus

Multi-tenancy foundation spec (Spec 00) landed at `/docs/specs/00-multi-tenancy-foundation.md`. This is the prerequisite work for Module 1 Pass 2. Next move is to execute the foundation work in a fresh Claude Code session.

## In flight

Nothing in code.

## Blocked

Nothing.

## Next

Build the multi-tenancy foundation per Spec 00 — Organisation model, user linkage, Tenanted concern, three tests. Then Module 1 Pass 2 (data model in field-level detail).

## Known debt

- Six unreferenced JS files in `app/javascript/` (`counter.js`, `enquiry_form.js`, `nav.js`, `reveal.js`, `services.js`, `smooth_scroll.js`) — investigated this session, see `docs/status-js-cleanup.md`. Deletion deferred to a future session.
- Layout inline JS (~90 lines in `app/views/layouts/application.html.erb`, lines 79–165) should be ported to Stimulus controllers before Module 2 begins. Use that as the Stimulus learning ramp before the platform's mobile UI work depends on it.
- GitHub Actions Node 20 runtime deprecation — deprecation warnings are already firing on CI runs. Hard deadline 2026-06-02, when GitHub stops running Node 20-based actions by default. Bump action versions in `.github/workflows/ci.yml` (`actions/checkout`, `actions/setup-node`, `ruby/setup-ruby`, `actions/upload-artifact`) to Node 24-based releases before that date.
- CI feedback wasn't being checked between sessions — established that lint job runs on every push, watch the GitHub Actions output as part of session close.
