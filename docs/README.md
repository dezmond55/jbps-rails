# /docs

The record of what's been decided, what's being built, and where we are. Audience: future-Derek picking this up on another machine or after a gap.

`CLAUDE.md` at the repo root is the **playbook** — rules every session reads. This folder is the **record** — decisions made, specs written, current state.

## Layout

- `adr/` — Architecture Decision Records, numbered `NNNN-title.md`. Each captures one decision and its reasoning. **Immutable once Accepted** — to change a decision, write a new ADR that supersedes the old one. Don't edit history.

- `specs/` — Module and feature specs, written *before* implementation. Write a spec when the work touches the data model, crosses module boundaries, or you'd struggle to explain it in a paragraph. Module-level specs are `NN-module.md` (e.g. `01-project-management.md`); feature specs nest under a module as `NN-module/feature.md` (e.g. `01-project-management/gantt.md`) when needed.

- `status.md` — Current build state: focus, in flight, blocked, next. Updated at the end of every session — even mid-feature. Ending a session without updating it is half-finished work.
