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
| Batch run-through: run B1→B4 continuously, stop only on pre-flight failure or TDD deviation | 2026-09-16 | AJ Ansari |

## Open Decisions

| Decision | Awaiting | Notes |
|---|---|---|
| Symbol Source (§1.4) | AJ Ansari, locally | Cannot download symbols in this session (no AL tooling) — filled in once AJ Ansari downloads symbols locally, per ChangeLog DEFINE-004. |
| Actual compile-and-package (Step 07) | AJ Ansari, locally | This session writes AL source; AJ Ansari compiles/tests it in local VS Code + AL extension (ChangeLog DEFINE-004). |
| **OQ-7 / VT-2 — outbound HTTP permission check (PA-3)** | AJ Ansari, locally | Verify whether this SaaS PTE's outbound HTTP calls are permitted by default on the target tenant, or need an administrator to enable them in Extension Management. Gates Batch B2's error handling and `Deployment.md`; does not block B1. |
| **VT-1 — full symbol verification worksheet** | AJ Ansari, locally | `docs/TDD.md` §16 now lists 29 items (expanded from 18 by the Sanity Check's F-S-8: table/page numbers, field names, event signatures, `using` namespaces, plus 8 platform-behavior assertions the cascade-delete and permission design depend on) to confirm before Step 06 generates any code. |
| **F-B-3 fallback — cascade-delete permission model** | AJ Ansari, only if VT-1 shows the assumption wrong | If local verification shows a subscriber codeunit genuinely needs execute permission from every caller (not just VIEW/EDIT holders) to fire on `OnAfterDeleteEvent`, decide the fallback: grant the subscriber codeunit execute permission somewhere every user already has it, or re-scope the cascade. Documented as a contingency in TDD §6.8; not a live decision unless verification triggers it. |
| **VT-3 — BBB page parse markers (OQ-3)** | AJ Ansari, locally | Open a real BBB profile page and pin down the anchor text for grade/accreditation/complaint count, and exactly what window the complaint figure covers. Gates Batch B2's `ocpfBbbProfileReader` only. |
| **VT-4 — HTTP-after-write transaction behavior** | AJ Ansari, locally | Confirm whether BC actually refuses an outbound call after a write in the same transaction (TDD §6.10). Doesn't block anything — §7.2's ordering is correct either way — but the reason should be confirmed, not assumed. |

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
- **2026-09-16** — Step 03 (TDD) drafted by the reasoning role (Opus 5): 13 objects assigned
  concrete IDs across 50601–50620 (5 modules, 35% overall growth buffer), full per-object and
  per-field specs, the DR-3 swappable-provider design (an `interface` + two codeunits), complete
  label inventory, permission set contents with `tabledata` grants, a "no upgrade code needed"
  decision recorded with reasoning, and an 18-item symbol-verification worksheet (§16). Added one
  object beyond the FRD list (`ocpfBbbCustomerSubscribers`, cascade-delete/rename subscribers —
  a delivery mechanic for OQ-6, not new scope) and decided not to build FRD's conditional E-6
  FactBox (inline card group instead; ID held in reserve). OD-1 (API caption locking, Standards
  §8.6) resolved interactively: `ocpfBbbFetchLogEntries` classified Technical–admin, both API
  pages set Translatable (ChangeLog DEFINE-006). OD-2 (no extra display-grade field) accepted as
  proposed. Four verification tasks (VT-1–VT-4) carried to local environment — see Open
  Decisions. TDD sign-off deferred to Step 04's close per Approvers = one person. Proceeding to
  Step 04 — Sanity Check.
- **2026-09-16** — Step 04 (Sanity Check) run by a fresh-eyes reasoning-role instance (Opus 5)
  that had not seen the FRD/TDD before. Adversarial structured review, not a read-through: 23
  findings (4 blocking, 12 should-fix, 7 minor). Blocking: FR-11's URL-maintenance permission was
  unenforceable by this extension's own permission sets (the field lives on standard Customer);
  no containment for an unexpected runtime error in the BBB page reader, which would silently
  break the DR-1/DR-2 audit trail; the cascade-delete design rested on two unverified platform
  assumptions and was untested for users holding neither BBB permission set; an HTTP-specific
  field (`HTTP Status Code`) leaked into the permanent published API in violation of DR-3's
  swappable-source guarantee. All 4 resolved by AJ Ansari plus 4 should-fix items needing
  FRD/design-rule changes (F-S-2 DR-2 wording, F-S-4 ID-range capacity, F-S-5/F-S-6 Standards
  deviation approvals). Remaining should-fix and minor findings batch-approved and applied by the
  main role (Sonnet 5) across FRD, TDD, Project Parameters, Object Register, and Problem
  Statement, with 8 new ChangeLog entries (DEFINE-007 through DEFINE-014). Key outcomes: BBB
  Profile URL edits now gated by an `OnValidate` permission check (closes FR-11 fully); the
  leaked field renamed to `Source Status Code`/`sourceStatusCode`; a second object ID range
  (50621–50650) added for v2 headroom; provider retrieval now mandated to run inside a
  `[TryFunction]`; cascade-delete re-keyed on the stable `Customer SystemId`; one line of
  invalid AL pseudo-syntax fixed; a stale PRE-02 note (contradicting DR-6) corrected.
  **AJ Ansari reviewed both documents directly (files sent) and signed off Steps 03 + 04
  together, 2026-09-16.** DESIGN phase complete. Proceeding to Step 05 — Plan the Code.
- **2026-09-16** — Step 05 (Plan the Code) complete. Scaffold built: `src/{CoreData,Logic,UI,
  API,Security}/` folders per TDD §14's module layout, `Translations/` (empty, no `.xlf` shipped
  per DEFINE-002), `outputAppPackage/`. `app.json` updated with both ID ranges (50601–50620,
  50621–50650). `.vscode/settings.json` written with the SaaS PTE analyzer set (CodeCop + UICop
  + PerTenantExtensionCop — never AppSourceCop). `.vscode/launch.json` scaffolded with
  placeholder sandbox/tenant values for AJ Ansari to fill in locally. Fetched the AL MCP
  launcher + `al-analyze.sh`/`.cmd` compile scripts into `scripts/` (gitignored) — this session
  has no AL tooling to run them, but they're ready for AJ Ansari's local environment. Fetched
  both optional knowledge companions (told AJ Ansari first, per Ops § Fetched Companions):
  BCQuality to a sibling folder `../claudeCodeMobileDevTest.bcquality/` (outside the project
  root, per its own compile-safety requirement) and the OCPF BC AL Patterns library into
  `patterns/` (gitignored) — both with `SNAPSHOT.json` recording source/commit/fetch time.
  `docs/PreflightChecklist.md` written (both passes, batch-specific notes, explicit about which
  checks this session can satisfy vs. defer to local VT-1 verification). **Batch run-through
  agreed: run B1→B4 continuously, stopping only on a pre-flight failure or TDD deviation.**
  Proceeding to Step 06 — Code Generation.
- **2026-09-16** — Step 06 (Code Generation) complete. Main role (Sonnet 5) generated all 14 AL
  files across B1–B4 in dependency order, following TDD §6–§13 exactly (field IDs, labels,
  DR-1/DR-2/DR-3 mechanisms, the corrected `[TryFunction]` containment, `OnValidate` permission
  check, `Customer SystemId`-keyed cascade delete, translatable API captions). Light role
  (Haiku 4.5) ran the Pass 2 post-generation checklist against all 14 files: **CLEAN, 0
  findings.** BBB page parse markers in `ocpfBbbProfileReader.Codeunit.al` are clearly-flagged
  placeholders (VT-3 — no network access to bbb.org from this session); every call will safely
  fail closed (DR-1-compliant) until AJ Ansari replaces them locally. Step 07 (mandatory
  compile-and-package) cannot run in this session — no AL tooling exists here (ChangeLog
  DEFINE-004). Handing off to AJ Ansari for local compilation.
- **2026-09-17** — Step 07, first troubleshooting round. AJ Ansari opened the code locally and
  reported two red-underline classes: `ApplicationArea` on table/table-extension fields, `Caption`
  on codeunits. Both confirmed as real invalid-AL defects (checked `patterns/` first — no match,
  diagnosed from scratch): `ApplicationArea` doesn't exist on table-level field definitions
  (page-only property); codeunits have no `Caption` property at all. Root cause: this session's
  UNVERIFIED discipline covered standard-BC *object* references but not AL *property-legality*
  facts — a gap now closed in `docs/TDD.md` §5/§6.7/§6.8/§6.10 and `docs/PreflightChecklist.md`
  (ChangeLog DEFINE-016). Fixed in all 5 affected files. Awaiting AJ Ansari's next local compile
  attempt.
