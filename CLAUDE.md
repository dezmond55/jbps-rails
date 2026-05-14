# CLAUDE.md — JBPS Rails Repository

This file is the first thing every Claude Code session in this repo should read.

## What this repo is

The JBPS Digital Platform — a Rails 8 application initially deployed at https://www.jbps.com.au, architected from day one to support productisation as a SaaS offering through DWJ Technical Studio.

## Tech stack

- Rails 8.0.2.1 / Ruby 3.4.5
- Hotwire (Turbo + Stimulus via ImportMap)
- Propshaft, PostgreSQL
- Deployed to Heroku
- Inline styles, no CSS framework

## Conventions

- Always use `bundle exec rails …`
- Deploy: `git add . && git commit && git push origin main && git push heroku main`
- Services page is hidden in production (redirects to home)
- Use `constraints: ->(req) { ... }` for conditional routes — `unless:` on redirects always fires

## Architectural constraints (non-negotiable)

The platform must work for a second organisation signing up tomorrow. Read `/docs/adr/` for the full reasoning. Summary:

- **Multi-tenant from the first migration.** Every Project, Site, User, SWMS, induction record, work order belongs to an Organisation. JBPS is Organisation #1.
- **No hardcoded client names.** Ventia, Unity, Believe Housing are Client records belonging to JBPS-the-Organisation, not constants in the codebase.
- **Induction content, SWMS templates, compliance flows (CM3, Ariba, COC) are per-Organisation,** configurable, never baked into views or controllers.
- **Subdomain routing and billing are not wired up yet** — but the data model must not preclude them.

The discipline test on every change: *does this still work if a second organisation signs up tomorrow?* If no, the smallest fix is usually `belongs_to :organisation` and a default scope. Not a redesign.

Multi-tenancy here is **a column and a scope**, not a research project. No row-level security via Postgres policies, no schema-per-tenant, no separate databases. Single shared schema, `organisation_id` column, scoped queries.

## Module build order

1. Project Management — Gantt, trade sequencing, daily site logs, progress claims
2. Site Safety & Compliance — QR sign-in/out, first-time induction, attendance log, SWMS, COC tracking
3. Subcontractor Portal — work orders, invoice submission, compliance docs (phase 2)
4. Client Portal — parked unless requested (phase 3)

## What we are not building

- Anything duplicating SimPro (invoicing, job costing)
- Anything duplicating Basecamp (communication)
- Anything duplicating MYOB (accounting)
- Self-serve SaaS billing/onboarding (deferred to Phase 3 of the commercial pathway)

## Working style

Derek is a terminal/Claude power user but still learning Ruby and Rails. The build optimises for learning, not throughput.

**Read carefully** (explain the why alongside the what):
- Models, controllers, views, Stimulus controllers
- Migrations on first encounter with a new pattern
- ADRs and specs

**Skim or trust** (brief summary is enough):
- Test scaffolding for repetitive patterns
- Dependency updates, lockfile changes, config tweaks
- Generated boilerplate

Default to interactive sessions. Use `claude -p` (headless) only for grunt work where reasoning isn't the point: bundle updates, file cleanup, running test suites.

## Multi-machine workflow

Derek works across three Windows machines. Each has its own local clone (typically under `C:\dev\`); **git is the source of truth, not the filesystem**.

- `git pull` at the start of every session
- `git push` at the end of every session, even mid-feature (use a WIP commit if needed)
- Update `/docs/status.md` before pushing if a session ends mid-task
- The local working tree is scratch space — anything not pushed is invisible to the next machine

## Handoff artefacts

Live in `/docs`:
- `/docs/adr/NNNN-title.md` — architecture decisions, immutable once Accepted (superseded, not edited)
- `/docs/specs/NN-module.md` — module-level specs (e.g. `01-project-management.md`). Feature specs nest as `NN-module/feature.md` (e.g. `01-project-management/gantt.md`) when needed. Written before implementation when the work is non-trivial.
- `/docs/status.md` — current state. Updated end of every session.

The rule: ending a session without updating `status.md` is half-finished work.

## Related projects (not in this repo)

- **DWJ Technical Studio** (`C:\dev\dwj-studio`) — separate Rails 8 codebase, the commercial vehicle for productising this platform. Shares patterns, not code.
- **Production folder** — JBPS operational workflow (SimPro, Basecamp, Dropbox integrations). Not in this repo. Integrations will eventually be re-implemented here as Rails code; until then they're manual.
