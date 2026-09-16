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

**Updated:** TDD/FRD will each carry a note on this workflow split when first drafted.

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

## Issue DEFINE-006 — Step 03 (TDD) API Caption Locking, Decided Interactively

**Problem:** Standards §8.6 requires every API page/query be classified (Business / Technical —
admin / Technical — internal plumbing) and its caption-locking decision made interactively, per
object, by a human — never asserted by the drafting role. The reasoning role's Step 03 draft
(`docs/TDD.md` §11) proposed a classification but correctly left both API pages' decisions open
as **OD-1**, since `ocpfBbbFetchLogEntries` (50614) was genuinely arguable between Technical —
admin and Technical — internal plumbing.

**Resolution:** Put to AJ Ansari as two ordered questions, per Standards §8.6 and Step 03's
procedure:
- **50614 `ocpfBbbFetchLogEntries` classified as Technical — admin** — an administrator
  deliberately reads it to diagnose repeated failures (FR-9, BO-5); not pure internal plumbing.
- **50613 `ocpfBbbCustomerRatings` (Business): Translatable** — following Standards §8.6's
  recommendation and Microsoft's own precedent (API v2.0: 0 of 1,526 business captions locked).
- **50614 `ocpfBbbFetchLogEntries` (Technical — admin): Translatable** — following the
  recommendation for the admin classification (API v2.0 `automation` pages: only 1 of 157
  locked).

Both API pages therefore set `EntityCaption`/`EntitySetCaption`, even though this project ships
no translation files for v1 — the property is correct regardless, so a future language addition
needs no revisit of this decision.

**Also accepted in the same round: OD-2** (optional, non-blocking) — no separate two-character
display-grade field is added to the API; `Documentation.md` will publish the ordinal → display
mapping instead, per the reasoning role's proposal (DR-8: current values only, no denormalized
presentation data).

**Files affected:** `docs/TDD.md` §11 (decision recorded with AJ Ansari's name, per Standards
§8.6), §6.11/§6.12 (EntityCaption/EntitySetCaption values), §15.1 (both items closed).

**Updated:** TDD updated directly (see above). FRD: no change needed — API caption locking is a
TDD-level (Step 03) decision, not an FRD-level one.

## Issue DEFINE-007 — Step 04 Sanity Check F-B-1: BBB Profile URL Edit Authority Enforced in Code

**Problem:** The reasoning role's independent Step 04 Sanity Check (`docs/SanityCheck.md`, finding
F-B-1) found that FRD FR-11 / DR-6's "only Credit & Risk may edit the BBB Profile URL" was met for
*running a refresh* but not for *editing the URL itself*: the field lives on the standard Customer
table, so ordinary Customer-modify rights (held by any Sales role) could write it through the UI or
`PATCH` it through API page 50613, regardless of which BBB permission set the user held. TDD §9.4
test 2 asserted the opposite as fact.

**Root cause:** This extension's own permission sets can grant or withhold execute/tabledata rights
on its own objects, but a standard-table field's write authority is governed by the *standard*
`tabledata Customer` permission, which the design had not accounted for.

**Resolution:** Put to AJ Ansari as `SanityCheck.md` F-B-1's three proposed options; **AJ Ansari
chose Option 2, "Enforce in `OnValidate`", 2026-09-16.** The field's `OnValidate` trigger now refuses
the change unless `FetchLog.WritePermission()` is true — the same test the refresh action already
uses — so both halves of FR-11 key off one condition, and the rule now holds for the UI and the API
alike. A new label, `NoUrlEditPermissionErr`, was added. FRD FR-11 and DR-6 were amended to state the
URL is writable only by the EDIT permission set, through this enforcement mechanism. TDD §9.4 test 2
was corrected to test the `OnValidate` enforcement rather than the (insufficient) API page
editability.

**Files affected:** `docs/TDD.md` (§6.4, §9.4, §10.2, §15.1a, §17), `docs/FRD.md` (FR-11, DR-6,
§10.1).

**Updated:** TDD — yes. FRD — yes (FR-11, DR-6, §10.1).

## Issue DEFINE-008 — Step 04 Sanity Check F-B-4: `HTTP Status Code` Renamed to `Source Status Code`

**Problem:** `SanityCheck.md` finding F-B-4: DR-3 ("nothing user-facing may depend on *how* the data
was obtained") was leaked into the permanent published API contract. The interface parameter, the
log table field, and API page 50614's field were all named after the transport (`HttpStatusCode` /
`"HTTP Status Code"` / `httpStatusCode`), which would make a future provider swap (DR-3/NFR-2's whole
purpose) a breaking API change.

**Root cause:** The field was named for the mechanism available today (an HTTPS GET) rather than for
the concept it represents (the provider's own outcome code), at the one point in the design meant to
stay mechanism-agnostic.

**Resolution:** **AJ Ansari chose "Rename to transport-neutral", 2026-09-16** — `SanityCheck.md`
F-B-4's recommended option. Renamed throughout: the interface's `HttpStatusCode` parameter →
`SourceStatusCode`; the log table field `"HTTP Status Code"` → `"Source Status Code"`; the API field
`httpStatusCode` → `sourceStatusCode`. Documented as "the provider's own status code, HTTP for the
current provider" so UC-6's diagnostic value (404 vs. 403 vs. timeout) is preserved. No FRD change
needed — DR-3 already forbade this leak; the TDD is brought into compliance, not the rule changed.

**Files affected:** `docs/TDD.md` (§6.3, §6.9, §6.10, §7.2, §7.3, §7.6), `docs/ObjectRegister.md`
(no field-level detail existed there to rename; header/VT-1 note updated for cross-reference).

**Updated:** TDD — yes. FRD — no (see above).

## Issue DEFINE-009 — Step 04 Sanity Check F-S-2: FRD DR-2's "Attempt" Wording Clarified

**Problem:** `SanityCheck.md` finding F-S-2: DR-2 says every refresh *attempt* is stamped and
logged, but the TDD decided — on its own, inside §7.2 step 3 — that a precondition refusal (no
profile URL, unsupported/blank country) is not an "attempt" and is therefore neither stamped nor
logged. The reasoning was sound, but it reinterpreted a signed-off, non-negotiable design rule
without recording it as a change to that rule.

**Root cause:** DR-2's original wording did not define "attempt", leaving the TDD to supply a
definition unilaterally.

**Resolution:** **AJ Ansari amended DR-2's wording, 2026-09-16** (the first of `SanityCheck.md`
F-S-2's two options): "attempt" now explicitly means a retrieval was actually initiated — i.e., its
preconditions passed. A precondition refusal is not an attempt: no external call was made, it is
shown to the user immediately, and an `Error` would roll back any row written before it anyway, so
writing one would misrepresent durability. TDD §7.2 step 3 is noted as now matching the FRD's
clarified wording, not a TDD-level reinterpretation of it.

**Files affected:** `docs/FRD.md` (DR-2), `docs/TDD.md` (§7.2 step 3, §15.1a, §17).

**Updated:** TDD — yes. FRD — yes (DR-2).

## Issue DEFINE-010 — Step 04 Sanity Check F-S-4: Second Object ID Allocation (50621–50650)

**Problem:** `SanityCheck.md` finding F-S-4: Standards §5.2 carries two growth-buffer requirements —
"up to 50 objects → 10 IDs reserved" and, separately, "leave at least 5–6 IDs unallocated per module
block" — and the primary 50601–50620 range met neither in full (7 reserved overall; 0–1 reserved per
module). TDD §3.4 disclosed the first shortfall but not the second, and four plausible v2 objects
were already named against a reserve of only 7 IDs.

**Root cause:** The primary allocation was sized against the runbook's own per-module minimum, not
against both of Standards §5.2's requirements together, and was not revisited once v2 candidates
started accumulating against it.

**Resolution:** **AJ Ansari approved a second allocation, 2026-09-16** — 30 IDs, **50621–50650** —
recorded in `docs/ProjectParameters.md` §1.2 as "Additional allocation 1". It is reserved as
unassigned v2 headroom, not grouped into any module yet; that grouping happens when v2 is actually
scoped. No v1 object uses any ID from it.

**Files affected:** `docs/ProjectParameters.md` (§1.2), `docs/ObjectRegister.md` (header, §1),
`docs/TDD.md` (§3.4, §15.1a, §17).

**Updated:** TDD — yes. FRD — no (Project Parameters is the authoritative source for ID ranges, not
the FRD).

## Issue DEFINE-011 — Step 04 Sanity Check F-S-5 and F-S-6: Two Standards Deviations Approved

**Problem:** `SanityCheck.md` findings F-S-5 and F-S-6 both found the same shape of issue: a
disclosed, well-reasoned deviation from a Standards Guide rule that the TDD then self-certified as
*compliance* rather than recording as an *approved deviation*. F-S-5: TDD §7.5's API field list is
narrower than Standards §3.1's "expose all applicable fields" literally requires. F-S-6: TDD §8.1's
`ocpfBbbRatingMgt` codeunit uses two `using` directives against Standards §1.1's "one `using` per
file".

**Root cause:** In both cases the underlying engineering decision was sound, but the TDD asserted its
own compliance with a rule its text does not actually satisfy, rather than routing the exception
through Operating Rule 6/7's approval-and-log discipline.

**Resolution:** Both put to **AJ Ansari, 2026-09-16**, who **approved both as recorded deviations** —
"Approve as a recorded deviation" for F-S-5, "Approve the exception" for F-S-6. Neither design
changes: §7.5's nine-field API list stays as built (Microsoft's own `customers` endpoint already
covers general fields; NFR-8's FlowField argument holds independently), and §8.1's two-`using`
codeunit stays as built (the alternatives cost an object ID or readability). Only the compliance
framing changes, from self-certified compliance to an approved, reasoned exception.

**Files affected:** `docs/TDD.md` (§7.5, §8.1, §15.1a, §17).

**Updated:** TDD — yes. FRD — no (both are TDD-level, Standards-Guide-level deviations, not FRD
requirements).

## Issue DEFINE-012 — Step 04 Sanity Check F-S-3: Objects Beyond the FRD §9 Inventory, Logged

**Problem:** `SanityCheck.md` finding F-S-3: `codeunit "ocpfBbbCustomerSubscribers"` (50608) and
`interface "ocpfBbbRatingProvider"` are both built in the TDD but absent from FRD §9's object
inventory — a section the FRD's own Step 02 exit gate treats as complete. TDD §3.5 declared "no
ChangeLog deviation entry is owed" for the codeunit, which is not the TDD's call to make: Operating
Rule 7 requires every departure from FRD or TDD, human or agent, to be logged.

**Root cause:** Both objects are technically necessary delivery mechanics for requirements the FRD
already states (NFR-15's cascade-delete needs a Customer-table event subscriber, since BC's
cascade-delete is a property of the parent table and this extension does not modify standard tables;
DR-3/NFR-2's swappable-provider requirement needs an isolation interface) — but "delivery mechanic
for existing scope" is a reason the deviation is *low-risk*, not a reason it is *unlogged*.

**Resolution:** **AJ Ansari confirmed, 2026-09-16:** both objects are technically justified as
described above, are logged here per Operating Rule 7, and will be added to the FRD's object
inventory at Step 10's re-baseline rather than now (Step 02's document is not reopened mid-DESIGN for
this). TDD §3.5 was corrected to remove the incorrect "no ChangeLog entry is owed" claim.

**Files affected:** `docs/TDD.md` (§3.5, §15.1a, §17), `docs/ObjectRegister.md` (already carried both
objects; no change needed there beyond the OD-1 note in DEFINE-014).

**Updated:** TDD — yes. FRD — carried forward to Step 10's re-baseline, not changed now.

## Issue DEFINE-013 — Step 04 Sanity Check F-S-12: ProblemStatement/FRD Reconciled with DR-6

**Problem:** `SanityCheck.md` finding F-S-12: `docs/ProblemStatement.md`'s PRE-02 expanded entity list
records the Customer row's R/W intent as "BBB Grade, Accreditation Status, Complaint Count, Profile
URL are staff-editable" — the opposite of FRD DR-6 and TDD §6.4, which make the first three
system-owned (`Editable = false`) and only the Profile URL staff-editable. FRD §10.1 nevertheless
asserted the two documents matched "with matching type, R/W intent, and scoping."

**Root cause:** `ProblemStatement.md`'s PRE-02 entity list was never revisited once DR-6 resolved the
R/W split during Step 02 drafting, and §10.1's validation check was written before that gap was
noticed.

**Resolution:** **AJ Ansari confirmed, 2026-09-16:** DR-6 is correct and PRE-02's wording is the stale
artifact — nothing in the build is wrong. `docs/ProblemStatement.md`'s Customer row is corrected in
place, marked "superseded by FRD DR-6 — corrected here." FRD §10.1 is reworded to say the R/W intent
was corrected/reconciled, rather than silently asserting a match that did not exist.

**Files affected:** `docs/ProblemStatement.md` (PRE-02 expanded entity list), `docs/FRD.md` (§10.1).

**Updated:** TDD — no (no TDD content was wrong). FRD — yes (§10.1).

## Issue DEFINE-014 — Step 04 Sanity Check: Remaining Should-Fix and Minor Findings Applied

**Problem:** `SanityCheck.md`'s independent Step 04 review (2026-09-16) raised two further blocking
findings and eight further should-fix/minor findings not covered by DEFINE-007 through DEFINE-013,
each requiring a TDD-level spec correction rather than an FRD or Project Parameters change: F-B-2 (no
containment for an unexpected runtime error in the provider), F-B-3 (the cascade-delete permission
story asserted, and untested for users holding neither permission set), F-S-1 (no precondition checks
Customer write permission), F-S-7 (API page 50614 doesn't explicitly block insert/delete; log-row
deletion undecided), F-S-8 (the UNVERIFIED discipline covers BC objects but not platform behavior),
F-S-9 (the cascade keyed on the volatile `"Customer No."` instead of the stable `"Customer SystemId"`
the design introduced for exactly this reason), F-S-10 (TDD §7.2 step 8 written in AL syntax that
does not exist), F-S-11 (FR-9's "filtered to failures" had no mechanism), and F-M-1 through F-M-7
(minor wording, permission-narrowing, and documentation-hygiene items).

**Root cause:** Varies by finding — see `SanityCheck.md` §5 for each finding's own evidence and
reasoning; in every case the underlying design intent was sound and the fix is a spec correction, not
a re-architecture.

**Resolution:** All ten items decided by **AJ Ansari, 2026-09-16**, through the interactive options
mechanism, applying `SanityCheck.md`'s own proposed resolution in each case:
`TryGetRating`'s outbound call and parsing must run inside a `[TryFunction]` (F-B-2); two new §16
verification rows plus a third §9.4 test case and a recorded fallback contingency for the
cascade-delete permission question (F-B-3); a Customer-write-permission precondition added before the
outbound call, with a new label (F-S-1); `InsertAllowed = false` / `DeleteAllowed = false` added
explicitly to page 50614, with the log's deletion behavior stated in words (F-S-7); eight platform
assertions added to the §16 worksheet (F-S-8); the cascade-delete subscriber re-keyed on `"Customer
SystemId"` (F-S-9); §7.2 step 8's invalid ternary replaced with explicit `if`/`else` AL (F-S-10);
FR-9's "filtered to failures" resolved as ordinary column filtering on `"Outcome"` (F-S-11); the EDIT
permission set's `tabledata "ocpfBbbFetchLog"` grant narrowed from `RIMD` to `RID` (F-M-1); the
FactBox-as-pure-display-surface overstatement in §3.6 reworded without changing the E-6 decision
(F-M-2); `ObjectRegister.md`'s stale OD-1 status corrected (F-M-3); two lines added to §13.3 on
standard-table `TableRelation` references and this extension's non-blocking stance on customer
deletion (F-M-4); a "next free extension field ID: 50607" note added to the Object Register (F-M-5);
VT-2 and VT-3 moved up to "before Step 05 closes" (F-M-6); and a line on Standards §9.5 plus a
sandbox-localization verification row added (F-M-7).

**Files affected:** `docs/TDD.md` (§3.6, §6.4 [test cross-ref only], §6.8, §6.9, §6.10, §6.12, §7.2,
§9.2, §9.3, §9.4, §10.2, §12, §13.3, §15.1a, §15.2, §16, §17), `docs/ObjectRegister.md` (§2, §3, §6).

**Updated:** TDD — yes (all items above). FRD — no (none of these ten findings required an FRD
change).
