# Status

_Last updated: 2026-05-07_

## Current focus

Documentation foundation complete — `CLAUDE.md`, the `/docs` structure, and ADR 0001 (multi-tenancy from day one) are all committed. Next concrete artefact in this repo is `/docs/specs/01-project-management.md`, blocked on the Q382 Excel Gantt being produced in the Production Claude session.

## In flight

Nothing in code.

## Blocked

Module 1 spec is waiting on the Q382 Excel Gantt. That Gantt is the functional spec.

## Next

- When the Q382 Gantt is done, write `/docs/specs/01-project-management.md` before any migrations.

## Known debt

- Six unreferenced JS files in `app/javascript/` (`counter.js`, `enquiry_form.js`, `nav.js`, `reveal.js`, `services.js`, `smooth_scroll.js`) — investigated this session, see `docs/status-js-cleanup.md`. Deletion deferred to a future session.
- Layout inline JS (~90 lines in `app/views/layouts/application.html.erb`, lines 79–165) should be ported to Stimulus controllers before Module 2 begins. Use that as the Stimulus learning ramp before the platform's mobile UI work depends on it.
- The repo lives in OneDrive (`C:\Users\borbu\OneDrive\Documents\jbps\jbps-rails`). OneDrive Files On-Demand has caused at least one observable problem (`findstr` recursion failed on reparse points). Evaluate relocating to `C:\dev\jbps-rails` before Module 1 code work begins.
