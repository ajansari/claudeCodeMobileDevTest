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
| **OQ-7 — outbound HTTP permission check (PA-3)** | AJ Ansari, locally | Verify whether this SaaS PTE's outbound HTTP calls are permitted by default on the target tenant, or need an administrator to enable them in Extension Management. Not a sign-off blocker (FRD §11), but must be confirmed before Step 03's retrieval design (E-9 `ocpfBbbProfileReader`) is finalized. |

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
- **2026-09-16** — Step 02 (FRD) drafted by the reasoning role (Opus 5) and reviewed. Full
  entity/object inventory (13 objects against the 20-ID range — ~35–40% growth buffer), 14
  design rules, 21 non-functional requirements, 11 platform-capability assumptions each rated
  for confidence (two below High: outbound HTTP permission and AL's lack of an HTML parser).
  Review surfaced 7 open items; all resolved (ChangeLog DEFINE-005): Localization `US` confirmed
  correct (a documentation bug in ProblemStatement/ChangeLog fixed, not a new decision), blank
  Country/Region refused, Complaint Count captures BBB's most prominent on-page figure, refresh
  restricted to Credit & Risk only, Fetch Log kept forever, Fetch Log cascade-deletes with its
  customer, and outbound-HTTP-permission verification carried forward as a local to-do (see
  Open Decisions) rather than a sign-off blocker. **FRD signed off by AJ Ansari, 2026-09-16.**
  Proceeding to Step 03 — Technical Design Document.
