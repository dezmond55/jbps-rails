# Module 1: Project Management

**Status:** Drafting (Pass 1 — scope and boundaries)
**Date:** 2026-05-13

## What this module is

The canonical store for project schedules: tasks, dependencies, milestones, and the calendar they live on. Replaces the role currently played by the Python script `build_works_programme_rev2.py` in the JBPS Production workspace.

The Excel workbook and PDF that the script currently produces are *renders* of the schedule, not the schedule itself. Module 1 owns the schedule data; rendering (Gantt UI, PDF export, CSV export) is downstream.

## Design target

Construction-domain-native scheduling. MS Project and Smartsheet are references for generic project scheduling patterns; they are not feature targets. The platform's distinctive value comes from being construction-domain-native — first-class understanding of SWMS, CoC, subcontractor sequencing, variation linkage, and the realities of how a small construction business actually runs jobs. Anything Smartsheet and MS Project do that doesn't serve a construction-specific use case is out of scope.

For the single-project view, the user experience pairs a spreadsheet-like grid with a Gantt rendering of the same data — both editable, both kept in sync. Multi-view (kanban, calendar) is deferred to v2.

## Deployment and integration context

Module 1 is not a standalone application. It is an addition to the live `jbps.com.au` Rails app, which has been in production since 2025 and serves a marketing site, an enquiry form, and a hidden Services page. The platform modules (1, 2, 3, eventually 4) extend this same app.

This has consequences for design and delivery:

- **Auth-gated.** Module 1 is internal-only. All routes are behind authentication. The public marketing site (home, contact, enquiry) remains unauthenticated.
- **Route-namespaced under `/app/`.** All Module 1 routes live under `/app/`. Example: `/app/projects`, `/app/projects/q382`, `/app/tasks/123/edit`. The marketing site continues to live at the root. This namespace is a pragmatic v1 choice; subdomain-based separation (`app.jbps.com.au`) is a Phase 2/3 architectural concern when productisation requires per-tenant isolation. The `/app/` namespace migrates cleanly to subdomain routing when that time comes.
- **Cannot break the marketing site.** Errors in Module 1 must not propagate to the public site. The homepage continues to serve, the enquiry form continues to submit, regardless of Module 1's state.
- **Backwards-compatible migrations.** Heroku deploys via slug swap — for several seconds during deploy, old code briefly runs against new schema and vice versa. Every migration must be safe in both directions.
- **Production-grade error handling.** Module 1 errors should be caught and shown to the logged-in user clearly, not propagated as 500 errors visible to anonymous visitors.
- **Public site uptime is the highest priority.** When the spec talks about "shipping Module 1," shipping means "Module 1 works for logged-in users and the public site is unaffected." The latter is non-negotiable.

## Prerequisites

Two things must exist in the codebase before Module 1 proper can begin. They are built first, in this order:

1. **User authentication.** A User model, a way to log in, sessions, password handling. Rails 8's built-in authentication generator (`bin/rails generate authentication`) provides a sensible default. No self-signup; accounts are created by an admin (initially seeded directly). Password recovery is out of scope for v1; password resets happen via direct admin intervention.

2. **Organisation model and multi-tenancy plumbing.** Per ADR 0001. Every User belongs to an Organisation. JBPS is Organisation #1, seeded. `Current.organisation` is established in `ApplicationController` via a before_action from the authenticated User. Tenant scoping (homegrown `Tenanted` concern with default scope keyed off `Current.organisation_id`) is in place.

These are preconditions, not Module 1 deliverables. Module 1's data model (Project, Task, etc.) is built on top of them, scoped through Organisation from day one.

## What it owns

- **Project** — a single contracted body of work, scoped to one Organisation. For JBPS, Q382 Freeling Street is one Project; Tintinara is another.
- **Task** — a unit of scheduled work belonging to a Project. Carries a name, start date, finish date, derived duration, an optional phase code (categorical), and flags for `is_summary` and `is_milestone`.
  - **Hierarchical:** Task has a self-referential optional `parent_id`. Summary tasks are Tasks with children whose dates are derived from those children. Leaf tasks have no children. The data model supports arbitrary depth. The v1 UI caps rendering at three levels (Project → Summary → Leaf), matching the current Excel pattern. v2 may extend.
  - This same hierarchy supports both the current Excel summary-row pattern ("3 Unit 1" rolling up "3.1, 3.2..." etc) and future finer-grained sub-task decomposition.
- **Dependency** — a directed link from one Task to another. Finish-to-start with zero lag is sufficient for v1; richer relationship types (SS, FF, lag/lead) are non-goals for v1.
- **Milestone** — a Task variant with zero duration, used as a date marker. Modelled as `Task.is_milestone = true` rather than a separate model.
- **Calendar** — working days (default Mon–Fri) and public holidays. Used to derive `duration_workdays`. Per-Organisation with a regional default (SA holidays for JBPS); see Open Questions for whether calendar moves per-Project.

## What it does NOT own

These belong to other modules or are deferred:

- **Subcontractor assignments per task** → Module 3 (Subcontractor Portal). Module 1 stores tasks; subcontractor links are added by Module 3 once that exists. For now, "who's doing this task" is captured informally in the task name string (matching current Excel practice).
- **Compliance certificates, SWMS, induction records** → Module 2 (Site Safety).
- **Variation linkage, RFIs, instructions** → future module (possibly Module 1.5 — variation management). Not in scope for v1.
- **Document/photo/email attachments** → future cross-cutting concern. Tasks should be designed to be *attachable to* eventually, but no attachment model exists in Module 1 v1.
- **Cost data, PO tracking, invoicing** → remains in SimPro. Module 1 does not duplicate.
- **Communication threads** → remains in Basecamp. Module 1 does not duplicate.
- **Daily site logs** → noted as a future capability, possibly part of Module 2 or its own micro-module. Not in scope for v1.
- **Actuals tracking** (`% complete`, `actual_start`, `actual_finish`) → deferred. v1 stores planned dates only.
- **Baseline / revision history** → deferred. v1 stores the current schedule. Proper baselining is a future feature.
- **Full portfolio Gantt view** → v2. v1 provides only a minimal Organisation-level project list (see below).

## Multi-project / Organisation rollup (v1 scope)

The data model is multi-project-aware from day one — Project belongs to Organisation, queries can roll up across projects within an Organisation. This is the architectural commitment per ADR 0001.

**v1 UI delivers a minimal proof of this** and nothing more:

- An Organisation-level page at `/app/` (the platform's logged-in home) listing all Projects, with key dates and status, and a link into each project's Gantt
- No portfolio-level Gantt
- No cross-project resource conflict detection (deferred — depends on Module 3 anyway)
- No cross-project dependencies

**v2 will design the real portfolio view** once JBPS has used v1 for daily Q382 work and surfaced actual cross-project information needs. Building portfolio polish before lived experience is premature.

## What it adds over the Python script

The script encodes the schedule as a flat list of tuples with manually-typed dates. The Rails module should do what the script can't:

1. **Predecessor graph is enforced, not advisory.** If Task A is a predecessor of Task B, the system knows it. UI can warn when dates contradict the graph.
2. **Hierarchical tasks with computed rollups.** Summary task dates derive from their children, not from manual entry.
3. **Partial re-baselining.** The script's `SHIFT_DAYS=7` shifts everything uniformly. The platform should support shifting a subset of tasks (e.g. "Units 2–4 only — Unit 1 has already mobilised").
4. **Edit-via-UI.** No "Save As Rev 2" file forking. The schedule is a database record; revisions are first-class.
5. **Grid + Gantt dual view.** Edit either, both update.
6. **Multi-tenant from the start, per ADR 0001.** Every Project belongs to an Organisation. JBPS is Organisation #1.
7. **Foundation for cross-project visibility.** Even if v1 only delivers a project list at the Organisation level, the data is shaped for the real portfolio view that comes in v2.

## Acceptance criteria

Module 1 v1 is done when:

1. The Q382 schedule (currently in `q382-programme.csv` / `q382-tasks.csv`) can be loaded into the Rails app as a Project with its full Task list, dependencies, summary tasks (rendered to three levels), and milestones.
2. A new Project can also be created from scratch in the UI — without importing — with tasks, summary tasks, dependencies, and milestones added via the platform itself. The platform is not import-only.
3. The schedule renders as a Gantt view that resembles the Excel/PDF output structurally — same tasks, same dates, same phase colouring, same milestone markers. Pixel-identical is not required.
4. The same schedule renders as a grid view, with the Gantt and grid kept in sync (edit in one, see in the other).
5. The schedule can be exported as a PDF of issuable quality — good enough to send to Ventia (or any client) as the project programme. This replaces the current Excel-COM PDF path.
6. A second Project (e.g. Tintinara, even with minimal data) can be created in the same Organisation and is visible alongside Q382 on the Organisation page, with tenant scoping intact.
7. A second Organisation can be seeded (e.g. a fake "AcmeBuilders" with one fake project) and its data is invisible to JBPS users, per ADR 0001.
8. The schedule can be edited via UI — adding a task, changing a date, marking a milestone, adding a child task to a summary — and the changes persist.
9. Tasks can be exported back to CSV in a format compatible with the original `q382-programme.csv` structure (round-trip integrity).
10. The public marketing site (`jbps.com.au` root, contact, enquiry form) continues to work normally and is unaffected by Module 1's presence. Logged-out visitors cannot see any platform routes; attempting `/app/anything` redirects to login.

### Implicit usability test

The criteria above are checkable. The real test is unwritten: **the pilot user (initially Derek for Q382) uses Module 1 for daily project scheduling work rather than rolling back to the Python script or Excel.** If the platform exists but the script is still being run, v1 is not actually done — regardless of which criteria pass. Acceptance is ultimately measured by adoption, not by feature checklist.

## Productisation considerations

Module 1's data layer is designed to support multiple Organisations from day one. For productisation through DWJ Studio (Phase 2 onward), two patterns are anticipated:

- **Done-for-you, separate deployments (Phase 2).** DWJ Studio forks the codebase per client (e.g. AcmeBuilders). Each builder runs their own Heroku app, their own database, their own marketing site customisation. Module 1 ships as a working `/app/` section within their codebase. The multi-tenancy is preserved (each fork starts with Organisation #1 = that builder) so the architecture doesn't require unwinding if the client later wants to host additional sub-organisations.

- **Self-serve SaaS (Phase 3).** Single codebase, single deployment, multiple Organisations sharing the same database. Marketing sites per-tenant rendered by the same Rails app based on the requesting domain. This is when subdomain-based or domain-based tenant resolution becomes necessary. Phase 3 is explicitly deferred until Phase 2 has proven the product.

Module 1 v1 does not need to address either pattern in code. It needs only to **not preclude either**. The multi-tenant data model and `/app/` namespace satisfy this.

Marketing site content (home page, services, contact, enquiry form) is currently hardcoded JBPS. Per-Organisation marketing customisation is a Phase 2 concern, addressed when the first DWJ Studio fork happens. Module 1 does not address it.

## Open questions (flagged for later passes)

These are real questions, not implementation details. They need answers before Pass 2 (data model) or Pass 3 (operations):

- **Project vs Job:** Q382 is one Ventia quote that spawned 4 work orders → 4 SimPro jobs. Is the Rails "Project" the quote (Q382) or the job (each unit's WO)? Probably the quote, with units modelled via the hierarchy (Project → "Unit 1" summary Task → leaf tasks) — but this needs settling.
- **Progress claims:** Does Ventia AGFMA pay on milestones, monthly, or completion? Determines what views the platform needs to surface. Not blocking Module 1's data model but affects the eventual Module 1 + invoicing-touchpoint design.
- **Calendar scope:** Calendar is per-Organisation with a regional default, but is the calendar overrideable per-Project (e.g. an interstate job)? Lean toward per-Organisation in v1; resolve in Pass 2.
- **Subcontractor sequencing as Module 1 data?** The 1-week stagger pattern is a project structural decision (the planner's choice), not just a subcontractor assignment. Should Task carry a `stagger_offset_days` or similar, or is this purely a Module 3 emergent property?
- **PDF rendering approach:** WickedPDF, Prawn, headless Chrome, or another path? Three credible options each with different trade-offs (template fidelity, performance, dependency cost). Resolve in Pass 3 (operations).

## Non-goals (Module 1 v1)

Explicitly *not* doing in v1:

- Critical path computation (CPM solver). v1 stores the graph; computing critical path is a v2 enhancement.
- Resource levelling. Out of scope; this is enterprise scheduling software territory.
- Drag-and-drop Gantt editing. v1 edits via forms or grid cells; drag-drop is UI polish for v2.
- Real-time collaborative editing. Single-user-at-a-time is fine for v1.
- Mobile Gantt UI. Desktop-first; mobile is a Module 2 concern.
- Import from MS Project (.mpp) or Primavera. CSV import is sufficient.
- Notifications/reminders on task dates. Deferred.
- Multi-view (kanban, calendar). Grid + Gantt only in v1.
- Full portfolio Gantt across projects. Minimal Organisation project list only in v1.
- Cross-project dependencies.
- Custom formulas in cells.
- Workflow automations and approvals.
- Hierarchy beyond three levels in the v1 UI (data model supports arbitrary depth; UI cap is a v1 deliberate constraint).
- Self-signup. Accounts are admin-created in v1.
- Password recovery flows. v1 handles password resets via admin intervention.
- Subdomain-based tenant separation. Path-based `/app/` namespace in v1; subdomain separation is a Phase 2/3 architectural concern.
- Per-Organisation marketing site customisation. Phase 2 concern; v1 marketing site stays hardcoded JBPS.
