# ChangeLog

## Issue DEFINE-001 — Accepted Risk: BBB Data Sourced via Web Scraping

**Problem:** No official BBB API or contracted data feed exists for this project; the business
need (Customer BBB Grade tracking) requires an external data source, and BBB does not publicly
offer a general-purpose rating API.

**Root cause:** BBB's grade/accreditation/complaint data is only available via (a) their public
website profile pages, (b) a paid/contracted data-feed relationship with BBB or a third-party
aggregator, or (c) manual staff entry. No contract or aggregator relationship currently exists.

**Resolution:** AJ Ansari was informed of the risks of option (a) — Terms of Service violation,
no SLA, fragility to markup/anti-bot changes, and plausible AppSource rejection if ever
submitted — and, after that disclosure, explicitly chose to proceed with scraping BBB's public
business-profile pages as the v1 data source. The TDD (Step 03) will isolate the fetch mechanism
in its own module/codeunit so it can be swapped for an official API or data-feed relationship
later without changing the customer-facing fields.

**Files affected:** None yet (DEFINE phase). Will apply to the fetch codeunit and any related
setup/log table once designed (Step 03 TDD, Step 06 BUILD).

**Updated:** TDD — not yet written (will carry this decision at first draft). FRD — not yet
written (will carry this decision at first draft).

## Issue DEFINE-002 — Scope Expanded to Include Canada

**Problem:** PRE-01 recorded this release as US-only, with Canada explicitly out of scope. During
PRE-02's gap analysis, while resolving whether the BBB refresh action should be restricted by
Country/Region, AJ Ansari answered "US or Canada customers only" — reopening a decision PRE-01
had already closed the other way.

**Root cause:** A validation-scoping question surfaced a latent scope change that hadn't been
raised explicitly. Rather than silently reconciling the conflict either direction, it was flagged
back to AJ Ansari for an explicit decision (runbook prime directive: ambiguous/contradictory
input is not resolved by inventing a rule).

**Resolution:** AJ Ansari confirmed the intent: expand this release's scope to **US and Canada**.
Follow-up: since Canada is bilingual, whether fr-CA translation support was required was asked
separately — AJ Ansari decided **English-only, no translation files**, even for Canadian
customers, so Standards Part 8's translation machinery (glossary, per-language review, `.xlf`
files) does not apply to this project for v1.

**Files affected:** `docs/ProblemStatement.md` — "Countries and Languages," "Explicitly Out of
Scope," PRE-02 gap-analysis and entity-list sections all updated to reflect US + Canada scope,
English-only.

**Updated:** TDD — not yet written. FRD — not yet written. Both will carry the English-only
decision when first drafted. **Correction (see DEFINE-005): Localization stays `US`**, not `NA`
as originally written here — that was a drafting error, corrected once Step 01 explicitly
confirmed `US` with its own reasoning.

## Issue DEFINE-003 — Pre-existing `.gitignore` Conflicted with Packaging & Repository Hygiene Rules

**Problem:** The repository's `.gitignore` (committed before this framework session started)
contained a blanket `*.app` rule and a blanket `.vscode/` rule. The former directly conflicts
with ALL ALONG → Packaging & Versioning ("Built packages are git-tracked, never gitignored. No
`outputAppPackage/` or blanket `*.app` entry in `.gitignore`."). The latter would prevent Step
05 from ever committing `.vscode/settings.json`, which the framework requires to carry the
project's analyzer configuration.

**Root cause:** The `.gitignore` predates this framework being applied to the project and was
written from a generic AL project template, not this runbook's rules.

**Resolution:** Removed the blanket `*.app` rule entirely (Step 07 onward will produce packages
into `outputAppPackage/`, which stays tracked). Narrowed `.vscode/` to `.vscode/launch.json`
only, since that file can carry tenant/connection details, while `.vscode/settings.json` remains
trackable for Step 05's analyzer scaffold.

**Files affected:** `.gitignore`.

**Updated:** TDD/FRD: N/A — this is a repository-hygiene fix, not a design decision.

## Issue DEFINE-004 — No AL Tooling in This Session's Environment

**Problem:** This session runs in a remote container with no AL Language extension, no `altool`,
and no .NET runtime — Operating Rule 2 (verify against BC symbol files) and Step 07 (mandatory
compile-and-package) cannot be executed here. Microsoft Learn is also unreachable from this
container (egress-blocked), removing the documented fallback reference too.

**Root cause:** Environment limitation, not a project design issue.

**Resolution:** AJ Ansari decided this session will write AL source, the TDD, and every design
document as normal, but **symbol-file verification (Operating Rule 2) and the actual
compile-and-package cycle (Step 07) happen locally**, in AJ Ansari's own VS Code + AL extension
environment, where the tooling exists. Every standard BC table/field reference this session
writes into the TDD or AL code will be explicitly flagged as **UNVERIFIED — confirm against local
symbols** rather than presented as confirmed, since Operating Rule 2 states agent knowledge of
table numbers is not reliable. Step 01 §1.4 **Symbol Source** stays blank here and is filled in
locally once symbols are downloaded.

**Files affected:** `docs/ProjectParameters.md` (§1.4 Symbol Source left pending). Affects every
future step that would normally invoke `al_*` MCP tools (§1.10 onward) — those steps proceed as
document/source generation only in this session.

## Issue DEFINE-005 — Step 02 (FRD) Review Findings: One Documentation Bug, Six Real Decisions

**Problem:** The reasoning role's Step 02 review (`docs/FRD.md` §11) surfaced seven open items.

**Resolution, item by item:**
- **OQ-1 (Localization `US` vs `NA`):** Not a new decision — a documentation bug. Step 01
  explicitly confirmed Localization = `US`, with the reasoning that it governs standard-field
  access only, separate from the US/CA business-scope enforced in this extension's own
  validation logic. `docs/ProblemStatement.md`'s "Countries and Languages" section and this
  ChangeLog's DEFINE-002 entry both still said `NA` from an earlier draft — corrected in place.
  **`docs/ProjectParameters.md` §1.1 (`US`) was correct all along and required no change.**
- **OQ-2 (blank Country/Region):** Refused, same as any unsupported country — AJ Ansari.
- **OQ-3 (Complaint Count definition):** Capture whatever figure BBB's page shows most
  prominently (commonly a 3-year window); the TDD will state the exact on-page figure captured
  once real page structure is examined — AJ Ansari.
- **OQ-4 (who may refresh):** Credit & Risk only. Sales reps get read-only visibility (FR-6) but
  not the maintenance permission set — AJ Ansari.
- **OQ-5 (log retention):** Keep every Fetch Log entry forever; no purge logic in v1 — AJ Ansari.
- **OQ-6 (deletion behavior):** Cascade delete — Fetch Log entries for a customer are removed
  when that customer is deleted — AJ Ansari.
- **OQ-7 (outbound HTTP permission, PA-3):** Not a decision — a verification task. Carried
  forward as a to-do for AJ Ansari's local sandbox before Step 03's retrieval design is
  finalized.

**Files affected:** `docs/ProblemStatement.md` (Localization correction), `docs/FRD.md` (DR-4/
FR-5 blank-country handling, FR-1/complaint count note, FR-11/DR-11 refresh permission,
FR-10/retention, NFR-15/deletion behavior, §11 closed out, §12 sign-off).

**Updated:** FRD updated directly (see above). TDD not yet written — will inherit all six
resolved decisions at first draft.

**Updated:** TDD/FRD will each carry a note on this workflow split when first drafted.
