# Project Memory

**Project:** Business Central PTE — Customer BBB Grade Tracking

## Where to Look

- Current step: `ProjectProgress.md` (project root) — always the source of truth for "where are we."
- Reasoning behind decisions: `docs/ChangeLog.md`.
- Scope, entities, open questions: `docs/ProblemStatement.md`.

## Standing Preferences

| Preference | Date | Given by |
|---|---|---|
| Working language: English | 2026-09-16 | AJ Ansari |
| Notifications: Claude app | 2026-09-16 | AJ Ansari |
| Approvers: One person for every role (Functional Consultant / Technical Lead / Dev Manager all AJ Ansari) | 2026-09-16 | AJ Ansari |

## Open Decisions

| Decision | Awaiting | Notes |
|---|---|---|
| Symbol Source (§1.4) | AJ Ansari, locally | Cannot download symbols in this session (no AL tooling) — filled in once AJ Ansari downloads symbols locally, per ChangeLog DEFINE-004. |
| Actual compile-and-package (Step 07) | AJ Ansari, locally | This session writes AL source; AJ Ansari compiles/tests it in local VS Code + AL extension (ChangeLog DEFINE-004). |

## Milestones

- **2026-09-16** — PRE-01 started and closed out. Working language, notification method, and
  approver model set. Both companion guides (`standardsGuide/`, `opsGuide/`) fetched and
  gitignored. Business need scoped via intake questions. BBB web-scraping data-source risk
  disclosed and accepted by AJ Ansari (ChangeLog DEFINE-001). `ProblemStatement.md` drafted;
  all open questions resolved (current-value-only fields, manual Profile URL entry, on-demand
  refresh, keep-last-value-and-flag on fetch failure). Only Deployment Target remains open,
  deferred to Step 01 intake.
- **2026-09-16** — PRE-02 (Structured Gap Analysis) run against Standards Part 6. Confirmed BBB
  Fetch Log as a firm entity (was tentative); confirmed BBB Grade is an `Enum`, not a lookup
  table; no tax/legacy/document-type gaps apply. Country-scoping question surfaced a scope
  conflict with PRE-01 (US-only vs. "US or Canada") — flagged back to AJ Ansari rather than
  silently resolved either way. **Scope formally expanded to US + Canada, English-only, no
  fr-CA translation** (ChangeLog DEFINE-002). Fetch action will validate Country/Region ∈
  {US, CA}. No Setup table for v1. PRE-01 + PRE-02 sign-off requested together (one approver).
- **2026-09-16** — Step 01 (Project Parameters) completed. Full intake run: Extension Name "BBB
  Rating Insights", Publisher "onlyCopilotFans", SaaS PTE, namespace
  `OnlyCopilotFans.BBBInsights`, Localization US (deliberate choice — governs standard-field
  access only, not the US/CA business-rule scoping), prefix `ocpfBbb`, ID range expanded to
  50601–50620 after a capacity flag (was 50611–50620 with zero buffer), App Code `BBBRI`, model
  role split (Main=Sonnet 5, Light=Haiku 4.5, Reasoning=Opus 5, all High), source wording = US
  wording, no translation files. `docs/ProjectParameters.md`, `docs/ObjectRegister.md`, and
  `app.json` written. **Environment gap discovered and resolved:** no AL tooling in this
  session's container — symbol verification and real compilation are deferred to AJ Ansari's
  local VS Code + AL extension (ChangeLog DEFINE-004); this session writes fully-formed,
  standards-compliant AL source with unverified standard-object references explicitly flagged.
  Fixed a pre-existing `.gitignore` conflict with Packaging/Repository Hygiene rules (DEFINE-003).
  Proceeding to Step 02 — FRD.
