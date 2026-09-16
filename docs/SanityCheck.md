# Sanity Check and Validation — BBB Rating Insights

**Project:** BBB Rating Insights (Business Central SaaS Per-Tenant Extension)
**Publisher:** onlyCopilotFans
**Phase / Step:** DESIGN — Runbook Step 04
**Performed:** 2026-09-16, by the **reasoning role**, as an independent fresh-eyes review. The
reviewer had not seen this project before and did not draft `FRD.md` or `TDD.md`.
**Inputs reviewed in full:** `docs/FRD.md` (signed off 2026-09-16), `docs/TDD.md` (draft, not yet
signed off), `docs/ObjectRegister.md`, `docs/ChangeLog.md` (DEFINE-001 – DEFINE-006),
`docs/ProjectParameters.md`, `docs/ProblemStatement.md`, and the OCPF AL Development Standards
Guide v1.9.0.0 (Parts 1–10, Appendices A–E).
**Status:** Complete — **4 blocking findings, all resolved** (see the resolution note below and
§7a). **Signed off by AJ Ansari, 2026-09-16**, together with `docs/TDD.md` (one sign-off,
Approvers = one person).

> **Resolution status (added 2026-09-16, main role, after AJ Ansari's decisions):** all 4 blocking
> and all 12 should-fix findings, plus all 7 minor findings, are now resolved. This document is left
> as the historical record of the review and is not edited further for content — see **§7a
> Resolution Log** at the end of this file for what changed and where, and `docs/TDD.md` §15.1a for
> the same cross-reference from the design-document side. Every resolution is also logged in
> `docs/ChangeLog.md` (DEFINE-007 through DEFINE-014).

---

## 0. How this review was run, and its own limits

- **This is a structured review, not a read-through.** Part A (§2) re-tests every platform
  assumption the FRD makes. Part B (§3) traces every FRD requirement and design rule to a concrete
  TDD mechanism. §4 works the runbook's canonical Step 04 checklist, item by item. §5 is the
  findings register. §6 records what was checked and found correct, so the clean areas are not
  re-litigated later.
- **The TDD's own citations were not taken at face value.** Every Standards § the TDD cites was
  opened and read against what the TDD actually does. Two places were found where the TDD cites a
  rule correctly and then applies something different (F-S-5, F-S-6).
- **The TDD's own §17 self-sufficiency check was treated as the author's opinion, not evidence.**
  §17 answers "yes" to questions this review answers differently — see F-B-1, F-S-3, F-S-8.
- **This reviewer also has no symbol file and no compiler** (ChangeLog DEFINE-004). Every
  `UNVERIFIED` marker in the TDD was therefore assessed for *whether it is correctly flagged*, not
  for whether the value is right. Where **this review** asserts something about the AL platform, it
  is marked `REVIEWER-UNVERIFIED` and added to the §16 worksheet as a new row rather than treated
  as fact. This review never replaces one unverified claim with another unverified claim presented
  as certainty.

**Severity definitions used below**

| Severity | Meaning |
|---|---|
| **Blocking** | Must be resolved or explicitly accepted, with reasoning, before the Step 03/04 sign-off and before Step 06 generates the affected batch. Either the design does not do what a signed-off FRD requirement says it does, or the TDD asserts as fact something that is not established. |
| **Should-fix** | A real defect, gap, or unapproved deviation. Cheap now, expensive after BUILD. Not a sign-off blocker on its own, but each needs a recorded decision. |
| **Minor** | Wording, consistency, or documentation-hygiene items. Fix opportunistically. |

---

## 1. Summary

| Severity | Count | IDs |
|---|---|---|
| **Blocking** | **4** | F-B-1 … F-B-4 |
| **Should-fix** | **12** | F-S-1 … F-S-12 |
| **Minor** | **7** | F-M-1 … F-M-7 |
| **Total** | **23** | |

**The four blocking findings, in one line each:**

| # | Blocking finding |
|---|---|
| **F-B-1** | **OQ-4 / FR-11 is only half-enforced.** The refresh half works; the *"only Credit & Risk may edit the BBB Profile URL"* half cannot be enforced by this extension's permission sets at all, because the field lives on the standard Customer table. TDD §9.4 test 2 asserts the opposite as fact. |
| **F-B-2** | **Nothing contains an unexpected runtime error inside the provider.** The interface contract says "a provider never raises an `Error`", but no mechanism enforces it. One uncaught AL runtime error rolls back the stamp *and* the log row — breaking DR-1 and DR-2 on precisely the path they exist for. |
| **F-B-3** | **The cascade-delete design is asserted, not established, and is untested for users holding neither permission set.** If execute permission on a subscriber codeunit does matter, a warehouse or accounting user with no BBB permission set who deletes a customer breaks a standard BC operation — which DR-13 / FRD §4.2 forbid outright. |
| **F-B-4** | **DR-3 is leaked into the permanent published API contract.** `HTTP Status Code` — a fact about *how* the data was fetched — is a field on the log table and a field named `httpStatusCode` on API page 50614. DR-3 says no field, page, or endpoint may depend on how the data was obtained. After v1 ships, renaming it is a breaking change (TDD §3.1, M4's own rationale). |

---

## 2. Part A — Can Business Central actually do everything the FRD asks?

Each FRD §4.3 assumption re-tested adversarially. "Agree" means the reviewer reached the same
conclusion independently; it does **not** mean verified.

| # | Assumption | Independent assessment | Action |
|---|---|---|---|
| PA-1 | `tableextension` on Customer | **Agree — High.** Core AL. TDD §6.4's *additional* claim — that extension field IDs must fall inside the allocated object range — is a platform rule stated as fact and **not** marked UNVERIFIED and **not** in §16. | Add to §16 (F-S-8). |
| PA-2 | `pageextension` on Customer Card | **Agree — High**, with three unmarked sub-claims: that a `pageextension` may declare `trigger OnOpenPage()`, that `Enabled = <page global>` is legal on an action added by a page extension, and that `addlast(content)` resolves on this page's control tree. Only the third is in §16 (#12). | Add the first two to §16 (F-S-8). |
| PA-3 | Outbound HTTPS from a SaaS PTE | **Agree — Medium-High, and this is the project's single largest unretired risk.** VT-2 correctly carries it, but the TDD schedules it as "does not block B1", which is true and beside the point: if outbound calls cannot be enabled on this tenant, **the feature has no value at all** and the correct response is a scope conversation, not a Batch B2 error branch. TDD §6.10 also specifies *how* a blocked call is detected only by inference. `REVIEWER-UNVERIFIED:` AL's `HttpResponseMessage` is believed to expose a dedicated "blocked by environment" indicator — detection should be read from symbols, not inferred from a status code of `0`. | Raise VT-2's priority to *before Step 05 closes*; add the detection method to §16. (F-S-8, F-M-6) |
| PA-4 | Extract grade / accreditation / complaint count from HTML | **Agree — Medium, and the FRD is right that this is the weakest link.** The TDD's all-or-nothing parse contract (§7.3) is the correct, honest design. Worth stating plainly for AJ Ansari: combined with modern, script-rendered profile pages, the realistic outcome may be that a *single* server-rendered GET never yields all three values, i.e. the feature fails closed in the field rather than occasionally. VT-3 is the right gate; it should be worked **before** B2 is scheduled, not at its start. | Confirm VT-3 timing. (F-M-6) |
| PA-5 | Restrict the action to US/CA | **Agree — and TDD §7.2.1 improves on the FRD**, resolving via the Country/Region record's ISO code with a raw-code fallback and refusing on ambiguity. This is the strongest single piece of design in the document. | None. |
| PA-6 | Grades as an enum | **Agree — High.** `Extensible = false` is correctly reasoned (§6.1). | None. |
| PA-7 | PTE API pages readable by Power BI | **Agree — High.** Note the endpoint is company-scoped (Standards Appendix A); `Documentation.md` must carry the `companies(<id>)` segment or BI authors will fail their first call. | Step 11 note. |
| PA-8 | `SystemId` on every table | **Agree — High.** | None. |
| PA-9 | Own table + own permission sets | **Agree — High**, but see F-B-1: what permission sets *cannot* cover is fields on a standard table. | F-B-1. |
| PA-10 | Extension fields flow through an API page over the extended table | **Agree — High.** | None. |
| PA-11 | bbb.org stays reachable and parseable | **Not a platform question.** Accepted risk, DEFINE-001. The design's response (DR-1/DR-2/log) is proportionate and correctly built. | None. |

**Part A conclusion:** nothing the FRD asks is beyond Business Central. Two assumptions (PA-3,
PA-4) gate whether the feature *works in practice* rather than whether it *compiles*, and both
should be retired before Step 05 closes rather than inside Batch B2.

---

## 3. Part B — Does the TDD fully and correctly implement the FRD?

### 3.1 Design rules DR-1 … DR-14 — mechanism, not citation

The TDD's §17 supplies a citation map. This table re-derives it independently and asks whether a
*mechanism* actually exists.

| Rule | TDD mechanism | Verdict |
|---|---|---|
| **DR-1** failed refresh never overwrites good data | §7.2 step 7; all-or-nothing parse contract §7.3; no catch-all enum member §6.1; no clear-on-URL-change §6.4 | **Sound in design, undermined in practice by F-B-2.** The four mechanisms are excellent; none of them survives an uncaught runtime error. |
| **DR-2** every attempt stamped and logged | §7.2 steps 8–9; `Message` never `Error` at step 11 | **Sound, with two caveats:** F-B-2 (rollback), and F-S-2 (precondition refusals are excluded from "attempt" by a TDD-level reinterpretation of a signed-off rule). |
| **DR-3** retrieval mechanism separable | interface §6.9; single binding line §7.1 | **Structurally excellent, then leaked.** See **F-B-4** — `HttpStatusCode` crosses the boundary into the log table *and* the published API. |
| **DR-4 / FR-5** US/CA only, blank refused | §7.2 step 2, §7.2.1 | **Fully met.** Best-in-document. |
| **DR-5** URL staff-entered and staff-owned | §6.4 `Editable = true`, no host validation, reasoned | **Met.** |
| **DR-6** retrieved values system-owned, URL user-owned | §6.4 `Editable = false` ×5 at table and page level | **Met for the five system fields.** The complementary half — that the URL is *only* editable by the maintenance role — is **not** met: F-B-1. |
| **DR-7** advisory only, never an automatic control | §13.2 (no `Handled` parameter; caution restated for subscribers) | **Met**, and the reasoning about why publishing the event makes third-party automation possible is a good catch by the author. |
| **DR-8** current value only, no history | §6.3's explicit "do not store retrieved values on the log row"; §6.12's caption sentence | **Met**, and defended better than the FRD asked for. |
| **DR-9** no configuration surface | §6.6 (no `UsageCategory`), §7.1 (provider bound in code, not by setup) | **Met.** |
| **DR-10** English only, US wording, no translation files | §10.1 | **Met.** See §4 row 12 for the one nuance (Canada + US source wording). |
| **DR-11** two permission sets, `tabledata` in both | §9.1–§9.3 | **Met as written**, but the sets do not deliver the *access model* FR-11 describes: F-B-1. |
| **DR-12** every object inside 50601–50620 | §3.2–§3.3 | **Met.** |
| **DR-13** the extension adds, never alters | `Modify(true)` §7.2; `InsertAllowed`/`DeleteAllowed = false` §6.11 | **Met in intent**, but F-B-3 is a live route by which this extension could break a standard operation. |
| **DR-14** no standard-BC identifier treated as known | §0.3, §16 | **Substantially met and unusually disciplined** — the markers are thorough for *BC objects*. It is **not** met for *platform behaviors*, which are asserted freely: F-S-8. |

### 3.2 Functional requirements FR-1 … FR-11

| FR | TDD mechanism | Verdict |
|---|---|---|
| FR-1 six fields, never-fetched distinct from NR | §6.4 fields; §6.1 ordinal 0 vs. ordinal 14 | **Met, elegantly.** Ordinal 0 doubling as the "no upgrade code needed" argument (§12) is genuinely good design. Dropping `Stale` is a justified resolution, not a deviation — FR-1 said "e.g." (see §4 row 16). |
| FR-1a no URL is a normal state | No nag anywhere; refusal only on explicit action | **Met.** |
| FR-2 on-demand refresh | §6.5 action → §6.7 `RefreshRating` | **Met.** |
| FR-3 successful refresh | §7.2 step 6 | **Met.** |
| FR-4 failed refresh | §7.2 steps 7–9, 11 | **Met in design; see F-B-2.** |
| FR-5 preconditions refused clearly | §7.2 step 2 (a)(b)(c) + labels §10.2 | **Met** — three distinct labels, one per cause, each naming the customer. One missing precondition: F-S-1. |
| FR-6 visibility together with the freshness stamp | §6.5 inline group, ordered deliberately | **Met**, and the field-order reasoning is correct. |
| FR-6a URL editable, openable in a browser | §6.4 `ExtendedDatatype = URL` | **Met** (`ExtendedDatatype` is asserted, unmarked — F-S-8). |
| FR-7 reporting via the API | §6.11, §7.5 | **Met**, with F-S-5 (narrow field list vs. Standards §3.1) and F-B-4 outstanding. |
| FR-8 every attempt recorded | §6.3 nine fields; §7.2 step 9 | **Met**, subject to F-S-2's definition of "attempt". |
| FR-9 log reviewable, filtered to a customer or to failures | §6.6 list page (sort only), §6.5 drill-in action, §6.12 API page | **Partially met** — "filtered to failures" has no provided view. F-S-11. |
| FR-10 retention forever | §6.3, §13.3 with the unbounded-growth note | **Met and honestly flagged.** |
| FR-11 two access levels | §9 | **Refresh half met; URL-maintenance half not enforceable — F-B-1.** |

### 3.3 What the object structure will look like when built

14 AL files (13 ID-bearing objects + 1 interface), in 5 module folders, from 4 batches. The shape
is coherent: enums → owned table → table extension → interface → orchestrator → provider →
subscribers → UI → API → permission sets. Nothing is scattered; every ID is inside range; every
file name derives mechanically from its object name per Standards §1.8. **Structurally this design
is sound and above average.** The blocking findings are all about *behavior and authority*, not
about shape.

---

## 4. The canonical Step 04 checklist

| # | Check | Finding | Resolution |
|---|---|---|---|
| 1 | Every FRD entity maps to at least one TDD object | **Pass, with a caveat.** E-1 → 50604, E-2 → 50603, E-3 → 50601, E-4 → 50602, E-5 → 50610, E-7 → 50611, E-8 → 50606, E-9 → 50607, E-10 → 50613, E-11 → 50614, E-12 → 50616, E-13 → 50617. **E-6 (FactBox) deliberately not built** — the FRD made it explicitly conditional and handed the choice to the TDD, so this is a permitted resolution, not a gap; §3.6's reasoning is adequate (though one of its four arguments is overstated — F-M-2). **Two objects exist that the FRD does not list:** codeunit 50608 and the interface. | E-6: accept as resolved. New objects: **F-S-3** — needs a ChangeLog entry and an FRD re-baseline item, which the TDD explicitly declines to open. |
| 2 | Every TDD object has a valid ID inside 50601–50620 | **Pass.** 50601-04, 50606-08, 50610-11, 50613-14, 50616-17 = 13 objects; 50605, 50609, 50612, 50615, 50618-20 reserved = 7. Interface correctly carries no ID. No object outside range. | None. |
| 3 | Every source table number verified against a symbol file | **Correctly flagged, not verified — as required.** Every BC identifier carries an inline `UNVERIFIED` marker at every occurrence, and §16 collects 18 of them into a worksheet. This is exactly what DEFINE-004 requires and the discipline is genuinely thorough for *objects*. **But the discipline stops at BC objects and does not extend to platform behavior**, which is asserted freely as fact. | **F-S-8** — at least seven platform assertions need markers and worksheet rows. |
| 4 | Every field complies with the Localization parameter and Standards Part 3 | **Pass on exclusion, fail on inclusion.** §7.5 correctly shows nothing in the 10,000–89,999 band is exposed, no `Blob`, no `FlowFilter`, no FlowFields. But §3.1's "expose **all** applicable fields" is knowingly departed from, with a rationale the Standards Guide does not contain. | **F-S-5.** Also verify the target sandbox's own localization matches `US` when symbols are downloaded (**F-M-7**). |
| 5 | Every obsolete / pending field excluded | **Correctly deferred and unconditional.** §7.5 states the rule applies "regardless of removal version" — matching §3.2's strict rule — and §16 #16 carries it. No obsolete event subscribed (§13.1), also correctly deferred. | None. |
| 6 | Every `using` namespace sourced from the symbol file | **Correctly flagged** — §8 lists a `using` per object, every Microsoft namespace marked UNVERIFIED, and §8 states plainly that the values shown are "placeholders with a plausible shape, not answers". | **F-S-6** on the one-`using`-per-file deviation. |
| 7 | Document-type-filtered pages use correct `const()` quoting | **N/A, correctly.** No page in the project filters by document type; the only `SourceTableView` (§6.6) is a sort order with no `const()`. §13.3 states this explicitly rather than silently. | None. |
| 8 | Entity names ≤ 30 chars, camelCase; `APIPublisher`/`APIGroup` camelCase; field identifiers ≤ 30 | **Pass — re-counted independently.** `ocpfBbbCustomerRating` 21, `ocpfBbbCustomerRatings` 22, `ocpfBbbFetchLogEntry` 20, `ocpfBbbFetchLogEntries` 22. Longest field identifier `ocpfBbbComplaintCount` 21. `'onlyCopilotFans'`, `'ocpfBbbRatings'` camelCase. Two identifiers deviate from §4.1's mechanical conversion (`number`, `displayName`) with Microsoft API v2.0 precedent cited — acceptable and recorded. | None. |
| 9 | Read vs. read/write matches Standards §2.2 mutability | **Pass.** 50613 master data → `DelayedInsert = true`; 50614 audit → `Editable = false`; neither sets both (Part 7 anti-pattern avoided). `InsertAllowed`/`DeleteAllowed = false` on 50613 is not the anti-pattern and is correctly reasoned. **But 50614 sets neither explicitly** — F-S-7. | **F-S-7.** |
| 10 | Growth buffers planned within each module block | **Partially met — and the TDD's own account of the shortfall is incomplete.** §3.4 flags that §5.2's "up to 50 objects → 10 IDs reserved" cannot be met (7 reserved). It does **not** mention §5.2's *other* sentence: *"For each module block, leave at least 5–6 IDs unallocated at the end."* M1 reserves 1, M2 reserves 1, M3 reserves 1, M4 reserves 1, M5 reserves 0. **No module meets it.** The 20%-per-module figure the TDD reports against is the runbook's minimum, not §5.2's. | **F-S-4** — decide now whether to request a second allocation, rather than at v2. |
| 11 | Permission sets planned, `tabledata` per set, assigned to the introducing batch | **Pass on mechanics.** One owned table, `R` in VIEW and `RIMD` in EDIT (§9.3), both sets created in B1 with their `tabledata` lines and amended per batch — exactly Standards §5.3's "ship the grant in the batch that introduces the table". Names 19 chars, captions 26 chars (re-counted), App Code `BBBRI` = 5 ≤ 6 (Standards §5.4's `20 − 7 − prefix`). **Fail on the access model those sets are supposed to deliver** — see check 19 and F-B-1. | **F-B-1**, **F-M-1**. |
| 12 | Every target language supported, reviewer named, terminology source | **N/A, correctly.** Parameters §1.9 records *US wording, no translation files*; no target language exists, so no reviewer and no terminology source is owed. `TranslationFile` stays in `app.json` features (§10.1) — correct per Standards §8.2, and the AL0424 reasoning is right. One nuance worth stating: Standards §8.1's single-market exception is written for "en-US only", and this project serves **Canada** under it. Checked term by term: no caption, label, or message in §7.4/§10.2 names a standard BC concept with US-regional wording (`Country/Region` is used, not `State`; no `Tax`/`VAT`/`Credit Memo` anywhere). The exception therefore holds in substance, not just on paper. | None. |
| 13 | Every regional term from PRE-02 in the translation glossary | **N/A, correctly.** PRE-02 listed no regional terms; DEFINE-002 removed the glossary requirement. Confirmed no glossary is owed. | None. |
| 14 | Every API page/query has a recorded group and caption-locking decision, decider named | **Pass.** §11 classifies both pages, resolves the genuinely-arguable one (50614) first, cites the §8.6 precedent counts correctly (1,526 business / 157 automation), records **AJ Ansari** by name with a date, and ChangeLog DEFINE-006 corroborates it. Both translatable → `EntityCaption` / `EntitySetCaption` set, no `Locked` — consistent with §8.6's "translatable objects" row. No API queries exist. **`ObjectRegister.md` §6 still lists OD-1 as "awaiting AJ Ansari's interactive decision"** — stale. | **F-M-3.** |
| 15 | Every message/error/confirmation is a `Label` with an AA0074 suffix and a `Comment` on placeholders | **Pass, and unusually complete.** §10.2 inventories all 15 labels. Suffixes correct (`Err`/`Msg`/`Txt`/`Tok`). Every placeholder label carries a `Comment` naming each placeholder — checked one by one, including `RefreshFailedMsg`'s two. `Locked = true` on both technical tokens (`HttpsPrefixTok`, `UserAgentTok`) per §8.3. No string literal reaches `Error`/`Message`. If F-S-1 is accepted, one further label is owed. | **F-S-1** adds a label. |
| 16 | Every entity's deletion behavior explicitly decided, **including standard-table fields that `TableRelation`-reference this extension's tables** | **Partially met.** `ocpfBbbFetchLog` → cascade with the customer, decided (OQ-6) and mechanised (§6.8). **Three parts of this check are not answered:** (a) whether a *user* may delete a log row — EDIT grants `D`, list page blocks it, API page 50614 does not explicitly block it; (b) the Customer entity's own deletion behavior from this extension's side is never stated as a decision ("this extension never blocks customer deletion") even though §6.8 implies it; (c) the reverse direction — no standard-table field `TableRelation`-references anything this extension owns, which is true and should be *recorded* as checked, not left silent. Also: the cascade is keyed on `"Customer No."`, not the stable key the TDD itself introduced for exactly this reason. | **F-S-7**, **F-S-9**, **F-M-4**. |
| 17 | *(Extra — FRD/TDD internal consistency)* Every FRD design rule and functional requirement has a concrete mechanism | See §3.1 and §3.2. DR-3, DR-6/FR-11, and FR-9 are the three with a gap between citation and mechanism. | F-B-1, F-B-4, F-S-11. |
| 18 | *(Extra — novel TDD additions justified and non-contradictory)* | **Three checked.** (a) Codeunit 50608: technically correct — cascade delete on a *parent* standard table cannot be declared without modifying it, so a subscriber is the supported route; but the TDD's conclusion that "no ChangeLog deviation entry is owed" is the author granting themselves an exemption from Operating Rule 7. (b) E-6 not built: permitted by the FRD, reasoning adequate. (c) No `Stale` enum member: a correct resolution of an FRD "e.g." list, and the argument ("a status no code path can write is dead metadata that makes the enum lie") is right. **No contradiction with any other FRD clause was found for (b) or (c)** — checked against §1.2.3, BO-4, NFR-11, FR-7, DR-8. | **F-S-3** for (a). |
| 19 | *(Extra — OQ-4 traced end-to-end rather than trusted)* | **Fails.** Traced in full below. | **F-B-1**, **F-S-1**, **F-B-3**. |
| 20 | *(Extra — confidence vs. evidence)* | **Fails.** BC *objects* are rigorously marked; BC *platform behavior* is asserted freely, including the single assertion the whole cascade design rests on. | **F-S-8**. |

### 4.1 Check 19 in full — tracing OQ-4 end to end

FR-11 / OQ-4: *"A read-only level can see BBB data … A maintenance level can additionally **edit the
BBB profile URL** and **run a refresh** — held by Credit & Risk only."* Two authorities, traced
separately:

**(a) "Run a refresh" — enforced. Three layers, and they hold.**
1. UI: `Enabled = RefreshAllowed`, from `FetchLog.WritePermission()` (§6.5). VIEW grants `R` → the
   action greys out rather than erroring (NFR-9 respected).
2. Server: `RefreshRating` re-checks the same condition (§7.2 step 1).
3. Execute: VIEW grants no `X` on 50606/50607 (§9.1), so the codeunit is unreachable anyway.

   *One wrinkle:* because layer 3 bites before layer 2, a VIEW user who reached `RefreshRating` by
   any route would meet a **platform permission error on the codeunit**, not `NoRefreshPermissionErr`.
   Harmless today (layer 1 prevents it), but the TDD's claim that step 1 makes "the rule hold for
   any caller, not just this page" is not quite what the design does.

**(b) "Edit the BBB profile URL" — not enforced, and cannot be by these permission sets.**
`"ocpfBbb Profile URL"` is a field on **Customer**, a standard table this extension does not own.
Write authority over it comes from the user's `tabledata Customer = M` permission, which is granted
by `D365 BUS FULL ACCESS`, `D365 SALES DOC, EDIT`, and every ordinary sales role — **not** by
`OCPFBBB BBBRI, EDIT`, and **not** withheld by `OCPFBBB BBBRI, VIEW`. A Sales rep who can edit a
customer at all can therefore type into the BBB Profile URL field on the Customer Card, and can
`PATCH` it through API page 50613 (VIEW grants `X` on that page). The extension's own sets are
simply not in that path.

TDD §9.4 test 2 — *"A VIEW-only user **cannot** write the profile URL through the API (a PATCH is
refused)"* — is true only for a user paired with `D365 READ`, which is the pairing the TDD documents
but not the pairing a working Sales rep has. **This is an assertion that will pass its own Step 12
test and still be false in production.** See F-B-1 for the three resolution options.

---

## 5. Findings register

### F-B-1 — **Blocking** — FR-11/OQ-4's URL-maintenance authority is unenforceable, and asserted as enforced

**Where:** TDD §9.1, §9.2, §9.4 (tests 2 and 3); FRD FR-11, DR-6, DR-11; ChangeLog DEFINE-005 OQ-4.
**Evidence:** §4.1(b) above.
**Why it matters:** FR-11 is a signed-off requirement with a named decision behind it (OQ-4, AJ
Ansari). The design delivers one of its two halves while the TDD records both as delivered, and
§9.4 encodes the false half as a Step 12 test that will pass under the documented pairing. DR-6's
"the profile URL is user-owned" is met; "owned by *which* users" is not.
**Proposed resolutions (pick one — this is a decision for AJ Ansari, not a fix the agent should
choose):**
1. **Accept and document.** Amend FR-11: the URL is editable by anyone with Customer-modify rights;
   only *refresh* is restricted. Cheapest, honest, and arguably fine — a wrong URL is caught by DR-1
   (a mis-parse fails, values are kept) and traced by `"Profile URL Used"` on the log.
2. **Enforce in `OnValidate`.** Add to §6.4's `OnValidate`: refuse the change unless
   `FetchLog.WritePermission()` — the same test the refresh action uses, so both halves of FR-11
   then key off one condition. Costs one label and one `if`. Works for both UI and OData.
3. **Make the field system-owned.** `Editable = false` on the URL too, maintained only through an
   action in the EDIT set. Strictest; contradicts FR-6a's "editable directly on the customer
   record" and would need an FRD change.
**Owner:** AJ Ansari (decision), then main role (TDD + FRD update).

### F-B-2 — **Blocking** — no containment for an unexpected runtime error in the provider

**Where:** TDD §6.9 (interface contract), §6.10, §7.1 ("a provider never raises an `Error`"), §7.2.
**Evidence:** The contract states the rule but no mechanism enforces it. `ocpfBbbProfileReader`
constructs a URI from user-entered text and calls out over the network; an unexpected AL runtime
error there (malformed URI, an unhandled type conversion during parsing, a platform-raised
callout failure) propagates out of `TryGetRating`, out of `RefreshRating`, and rolls the
transaction back — taking **step 8's stamp and step 9's log row with it**.
**Why it matters:** This is the exact scenario DR-1 and DR-2 exist for: the source broke in a way
nobody anticipated. The design's response in that case is currently *silence* — no stamp, no log
row, an unhandled error in the user's face (NFR-9), and nothing for UC-6 to diagnose. Everything
else about the failure path is carefully built; this is the hole underneath it.
**Proposed resolution:** State in §6.10 and §6.9 that `TryGetRating` **must** perform its outbound
call and parsing inside a `[TryFunction]` local procedure and convert any caught failure into
`false` + `UnexpectedReasonTxt` + `HttpStatusCode = 0`, and add a Step 05 post-generation check for
it. `REVIEWER-UNVERIFIED:` `[TryFunction]` semantics and what they do and do not catch must be
confirmed against symbols/docs locally — add as a §16 row. Note also that a `TryFunction` cannot
undo database writes, which is a further reason §7.2's "fetch before any write" ordering is right.
**Owner:** main role (TDD), then §16/VT-1.

### F-B-3 — **Blocking** — the cascade-delete permission story is asserted, and one user population is unhandled

**Where:** TDD §6.8 ("**The `Permissions` property is why a Sales user can still delete a
customer**"), §9.1 (`codeunit "ocpfBbbCustomerSubscribers" = X` in VIEW), §9.4 test 4.
**Evidence:** Two unestablished claims are load-bearing here, neither marked UNVERIFIED nor in §16:
(i) that a codeunit's `Permissions` property elevates permissions for code running as an **event
subscriber**; (ii) that execute permission on a subscriber codeunit is required for the subscriber
to fire — which is what the VIEW grant exists to satisfy.
If (ii) is true, then **a user holding neither BBB permission set** — a warehouse clerk, an
accounts-payable user, an integration account — who deletes a customer either fails to cascade or
errors. Either outcome breaks a standard BC operation, which FRD §4.2 and DR-13 forbid outright.
The TDD tests VIEW and EDIT (§9.4 test 4) and never tests "neither", which is the larger population.
**Why it matters:** the failure lands on an operation this extension has no business affecting, for
users who have never heard of it. The TDD itself calls this "the one permission interaction in this
design most likely to be wrong" and then does not follow its own warning to its conclusion.
**Proposed resolution:** (a) add both claims to §16 as rows to verify against symbols/docs;
(b) extend §9.4 with a third case — *a user holding **neither** BBB set deletes a customer* — as a
mandatory Step 12 test; (c) decide the fallback now if (ii) proves true: grant the subscriber
codeunit `X` somewhere every user already has it, or re-scope the cascade (see also F-S-9).
**Owner:** main role (TDD + §16), AJ Ansari (fallback decision if needed).

### F-B-4 — **Blocking** — DR-3 leaks into the permanent published API contract

**Where:** TDD §6.9 (`var HttpStatusCode: Integer` in the interface), §6.3 field 7
(`"HTTP Status Code"`), §7.6 (`httpStatusCode` on API page 50614), §7.3's status-mapping table.
**Evidence:** DR-3 (FRD §5, non-negotiable): *"Nothing user-facing — no field, no page, no API
endpoint, no permission set — may depend on **how** the data was obtained. Replacing scraping with
an official API must not change any of them."* An HTTP status code is a fact about the transport.
It is currently a parameter on the isolation interface, a stored column, and a **published OData
property**. The TDD asserts the opposite — that the interface being free of BC namespaces "is
itself evidence the DR-3 boundary is clean" — which tests the wrong property.
**Why it matters:** TDD §3.1 makes M4's whole rationale "renaming anything here breaks consumers".
So this is the one category of finding that is *cheap now and permanently expensive after v1
ships*. It is also the exact promise DEFINE-001 traded the scraping risk against.
**Proposed resolutions:**
1. **Rename to transport-neutral** across interface, table field, and API identifier — e.g.
   `"Source Status Code"` / `sourceStatusCode`, documented as "the provider's own status code, HTTP
   for the current provider". Preserves every diagnostic use (UC-6 can still tell 404 from 403)
   and satisfies DR-3 literally. Recommended; costs nothing before Step 06.
2. **Record an explicit, reasoned DR-3 exception** in the FRD, signed off, on the grounds that a
   numeric provider status is generic enough. Acceptable, but it is an FRD change and needs its own
   approval (Operating Rule 6).
Whichever is chosen, note that `CallNotAllowedReasonTxt` ("allow HttpClient requests") is also
mechanism-specific, but it is an *actionable admin instruction* rather than a contract — leave it.
**Owner:** AJ Ansari (decision), main role (TDD, Object Register, §7.3/§7.6).

---

### F-S-1 — **Should-fix** — no precondition checks write permission on Customer

**Where:** TDD §7.2 steps 1–2.
Step 8 executes `Cust.Modify(true)`. A Credit & Risk user with read-only rights on the customer
master — a common, defensible configuration for a credit analyst — passes every precondition, makes
a live outbound call to bbb.org, and then hits a raw platform permission error on `Modify`. That is
(a) an unhandled technical error in the user's face (NFR-9), (b) a rolled-back stamp and log row
(DR-2, same shape as F-B-2), and (c) a third-party web request made for nothing (NFR-3's
"considerate retrieval").
**Resolution:** add precondition (d) to §7.2 step 2 — `if not Cust.WritePermission() then Error(...)`
— with a new label (e.g. `NoCustomerWritePermissionErr`) added to §10.2, checked **before** the
outbound call.

### F-S-2 — **Should-fix** — precondition refusals are excluded from DR-2/FR-8 by a TDD-level reinterpretation

**Where:** TDD §7.2 step 3; FRD DR-2, FR-8.
DR-2 reads *"Every refresh attempt is stamped and logged, success or failure … the audit log
**always** gains an entry."* The TDD decides a precondition refusal is not an "attempt", so nothing
is stamped and nothing is logged. **The reasoning is good** (no external call was made; `Error`
rolls back any row written before it, so writing one would be a lie about durability) and FR-5
does treat refusals as a separate category from FR-3/FR-4. **But this is a reinterpretation of a
signed-off, non-negotiable rule, recorded only inside the TDD.**
**Resolution:** either amend DR-2's wording in the FRD to say "attempt" means "a retrieval was
initiated", or log refusals via a mechanism that survives (e.g. return a status and show the message
from the caller instead of `Error`). Whichever — it needs a ChangeLog entry, per Operating Rule 7.
Note the operational cost of the current choice: UC-6's administrator cannot see "37 refusals
because nobody set a country/region", which is a plausible real support question.

### F-S-3 — **Should-fix** — two objects beyond the FRD inventory, with the ChangeLog requirement waived by the TDD itself

**Where:** TDD §3.5 (*"no ChangeLog deviation entry is owed"*), §6.9; FRD §9; Object Register row 50608 and the interface row.
`ocpfBbbCustomerSubscribers` (50608) and `interface "ocpfBbbRatingProvider"` are both absent from
the FRD's §9 object inventory — a section the FRD's own Step 02 exit gate treats as the complete
inventory. Operating Rule 7: *"Any departure from FRD or TDD — human or agent — is logged."* The
technical justification for 50608 is sound; **the exemption from logging it is not the TDD's to
grant.**
**Resolution:** open a `DESIGN-00x` ChangeLog entry covering both objects (problem, root cause,
resolution, files, "Updated: TDD yes / FRD at Step 10"), and add both to the FRD's inventory at
Step 10's re-baseline. Cost: ten minutes. Benefit: Step 08's gap-fit finds a recorded decision
instead of two unexplained objects.

### F-S-4 — **Should-fix** — Standards §5.2's per-module buffer is met by no module, and only half the shortfall is disclosed

**Where:** TDD §3.2, §3.4; Standards §5.2.
§5.2 carries two separate requirements. §3.4 discloses the first ("up to 50 objects → 10 IDs
reserved"; 7 available) and is silent on the second: *"For each module block, leave at least 5–6 IDs
unallocated at the end."* Actual reserves: M1 = 1, M2 = 1, M3 = 1, M4 = 1, M5 = 0. The 20% figure
§3.4 reports against is the runbook's per-module minimum, not §5.2's.
**Why it matters now:** §3.4 already names four plausible v2 objects (Customer List extension, setup
table, upgrade codeunit, job-queue refresh) — and Standards §9.3 means introducing *any* upgrade
code brings an install codeunit and a tag-definitions codeunit with it. That is 6 of the 7 reserved
IDs on a single foreseeable release, with the reserve already committed to a replacement provider
(VT-1/§7.1) and to a possible FactBox (50612).
**Resolution:** decide now — either request a second allocation and record it in Project Parameters
§1.2 (the cheap moment is before any object exists), or record an explicit acceptance that v2 will
require one. Either way it is a Parameters change, and Parameters is the authoritative source.

### F-S-5 — **Should-fix** — the narrow API field list is a Standards Part 3 deviation the guide does not permit

**Where:** TDD §7.5 ("Why the field list is narrow, and why that is compliant"); Standards §3.1.
§3.1 requires *"All applicable fields, regardless of whether they appear on any UI card or list
page."* The TDD reads into it a scope limitation ("governs a page whose job is to *be* the table's
API") that §3.1 does not contain, then self-certifies compliance. The Standards Guide's own
precedence rule: on an AL rule, the guide wins.
**Assessment:** the *decision* is very likely right — nine BBB-relevant fields beside Microsoft's
own `customers` endpoint is a better API than a 200-field duplicate, and NFR-8's FlowField argument
is correct. **It is the self-certification that is wrong.** Record it as a deviation approved by AJ
Ansari (Operating Rule 6/7), not as compliance.
**Resolution:** reword §7.5 as a recorded, approved deviation; ChangeLog entry; keep the design.

### F-S-6 — **Should-fix** — the two-`using` deviation is recorded but self-approved

**Where:** TDD §8.1; Standards §1.1 (*"One `using` directive per file"*).
Same shape as F-S-5: the deviation is disclosed honestly and reasoned well (the alternatives cost an
object ID or readability), which is to the author's credit — but §8.1 marks it "Recorded here for
Step 04's review" and then proceeds as settled. It is now Step 04, so: it needs AJ Ansari's yes.
**Resolution:** put it in the Step 03/04 sign-off as an explicit item. If refused, the cheapest
alternative is fully qualifying the Country/Region type inline rather than spending 50609.

### F-S-7 — **Should-fix** — API page 50614 sets neither `InsertAllowed = false` nor `DeleteAllowed = false`, and log-row deletion is never decided

**Where:** TDD §6.12, §6.6, §9.2; Step 04 checklist's deletion-behavior item.
50613 explicitly blocks insert and delete with a clear rationale. 50614 relies on `Editable = false`
alone. `REVIEWER-UNVERIFIED:` whether `Editable = false` on an API page also refuses an OData
`DELETE` should be confirmed rather than assumed, especially since the EDIT set grants `D` on
`tabledata "ocpfBbbFetchLog"` precisely so the cascade works — so the permission to delete a log row
**does** exist for Credit & Risk users.
**Why it matters:** DR-6 says the audit log is "system-written and never user-editable". An audit
trail a user can `DELETE` through the API is not an audit trail, and FR-10's "kept indefinitely"
becomes advisory.
**Resolution:** set `InsertAllowed = false; DeleteAllowed = false;` explicitly on 50614, state the
deletion decision for the entity in words ("log rows are deleted only by the cascade; no user-facing
delete path exists"), and add both to §16 as a verification row.

### F-S-8 — **Should-fix** — the UNVERIFIED discipline covers BC objects but not platform behavior

**Where:** TDD §0.3, §16; various.
§0.3's rule is scoped to *"every table number, page number, field name, event name, namespace, and
System Application codeunit"*. Platform *behaviors* are then asserted as fact throughout. Collected:

| # | Asserted as fact | Where | Load-bearing for |
|---|---|---|---|
| 1 | A codeunit's `Permissions` property elevates permissions for an **event subscriber** | §6.8 | The entire cascade design (**F-B-3**) |
| 2 | Execute permission on a subscriber codeunit is required for it to fire | §9.1 | Who can delete a customer (**F-B-3**) |
| 3 | `Record.WritePermission()` semantics as a refresh-authority proxy | §6.5, §7.2 | OQ-4's UI and server gates |
| 4 | A `pageextension` may declare `trigger OnOpenPage()` and use a page global in `Enabled` | §6.5 | The greyed-out action (NFR-9) |
| 5 | `ExtendedDatatype = URL` renders a clickable link on the card | §6.4 | FR-6a |
| 6 | Table-field `Editable = false` blocks OData writes but not AL writes | §6.4 | DR-6 |
| 7 | Extension field IDs on a standard table must be inside the allocated range | §6.4 | The field-ID plan |
| 8 | `SystemCreatedBy` on a custom table records who ran the attempt | §6.3 | The decision *not* to store a user field (NFR-12) |

Several are very likely correct. That is not the point: Operating Rule 2 exists because "very likely
correct from familiarity" is what it forbids, and #1 and #2 are the ones an entire blocking finding
rests on.
**Resolution:** add all eight to §16 as rows 19–26, plus the two `REVIEWER-UNVERIFIED` items raised
in F-B-2 and F-S-7 and the PA-3 detection method from §2. VT-1 then retires them with everything else.

### F-S-9 — **Should-fix** — the cascade is keyed on the volatile key, not the stable one

**Where:** TDD §6.8 (`FetchLog.SetRange("Customer No.", Rec."No.")`), §6.3 field 3.
§6.3 introduces `"Customer SystemId"` expressly because it *"survives a customer number rename"*,
and §6.8 then keys both subscribers off `"Customer No."` and adds a second subscriber to keep that
volatile key in step. The result: correctness of the cascade depends on the rename subscriber having
run for every past rename. Any window where it did not (extension disabled during a rename, a
data-tool rename, a rename that occurred before install) leaves orphan rows that the cascade will
then never collect — rows referencing a customer that no longer exists, still readable through API
page 50614.
**Resolution:** key the delete subscriber on `"Customer SystemId"` (`SetRange("Customer SystemId",
Rec.SystemId)`), keep the rename subscriber for `"Customer No."` display/filter value only, and add
a secondary key on `"Customer SystemId"` if Step 12 shows the delete is slow. This also removes the
cascade's dependency on a second subscriber having worked.

### F-S-10 — **Should-fix** — §7.2 step 8 is written in syntax AL does not have

**Where:** TDD §7.2 step 8: `"ocpfBbb Fetch Status" := Succeeded ? Succeeded : Failed;`
AL has no ternary conditional operator. In a document whose stated purpose (§0.1) is that a
developer or agent builds from it alone, non-AL pseudo-syntax at the single line that implements
DR-2's stamp is a generation hazard — and the expression is also self-referential as written
(`Succeeded` is both the Boolean and the enum member).
**Resolution:** replace with explicit `if Succeeded then … else …` over
`Enum::"ocpfBbbFetchStatus"::Succeeded` / `::Failed`.

### F-S-11 — **Should-fix** — FR-9's "filtered to failures" has no mechanism

**Where:** FRD FR-9, UC-6; TDD §6.6, §6.5.
FR-9 requires the log be reviewable *"filtered to a customer **or to failures**"*. The customer
filter is delivered (the Customer Card action). The failure filter is not: page 50611 offers a
descending sort and nothing else, and §6.3 explicitly defers adding `"Outcome"` to the secondary key
("do not pre-optimize" — correct as a key decision, but it is not what FR-9 asked for).
**Resolution:** cheapest sufficient answer is a filter/view on 50611 or a documented saved view —
decide which, and record it. If the answer is "standard column filtering is enough", say so
explicitly against FR-9 so Step 08's gap-fit sees a decision rather than a gap.

### F-S-12 — **Should-fix** — a stale DEFINE artifact contradicts DR-6, and the FRD asserts they match

**Where:** `ProblemStatement.md` PRE-02 expanded entity list; FRD §10.1.
PRE-02 records the Customer entity's R/W intent as *"BBB Grade, Accreditation Status, Complaint
Count, Profile URL are **staff-editable**"*. FRD DR-6 and TDD §6.4 make the first three
system-owned and `Editable = false` — the opposite. FRD §10.1 nevertheless states both PRE-02
entities are present *"with matching type, R/W intent, and scoping"*.
**Assessment:** DR-6 is right and PRE-02 is stale; nothing in the build is wrong. But the
reconciliation was never recorded, and §10.1 asserts a match that does not exist.
**Resolution:** note it in the ChangeLog and correct `ProblemStatement.md`'s R/W column (or mark it
superseded by DR-6). Carry into Step 10's FRD re-baseline.

---

### Minor findings

| # | Finding | Where | Resolution |
|---|---|---|---|
| **F-M-1** | EDIT grants `tabledata … = RIMD` with `M` included "for completeness of the `RIMD` idiom", while §9.2 itself states no code path ever modifies a log row. Least-privilege says narrow it. | TDD §9.2 | Narrow to `RID` — the TDD already calls this "a defensible Step 04 amendment". Agreed: do it. |
| **F-M-2** | §3.6's claim that *"a FactBox is a display surface"* overstates the platform — a `CardPart` can host editable fields. The E-6 decision stands on its other three arguments (collapsibility vs. BO-4, one coherent group, DR-9 minimalism). | TDD §3.6 | Reword; keep the decision. |
| **F-M-3** | `ObjectRegister.md` §6 still lists **OD-1** as *"awaiting AJ Ansari's interactive decision"*, contradicting TDD §11/§15.1 and ChangeLog DEFINE-006, which closed it. | ObjectRegister.md §6 | Update to "Resolved, DEFINE-006"; keep VT-1 open. |
| **F-M-4** | No standard-table field `TableRelation`-references anything this extension owns — true, and the Step 04 checklist wants it *recorded as checked*, not silent. Likewise, "this extension never blocks customer deletion" is implied but never stated as a decision. | TDD §13.3 | Add two lines to §13.3's special-design-notes table. |
| **F-M-5** | Field IDs 50601–50606 are spent on Customer, tracked only in Object Register §3. Field-ID consumption is a separate namespace from object IDs (so no collision), but it is also unbudgeted — worth one line so a v2 field plan does not have to re-derive it. | ObjectRegister.md §3 | Add a "next free extension field ID: 50607" note. |
| **F-M-6** | VT-2 (PA-3, outbound HTTP) and VT-3 (PA-4/OQ-3, parse markers) are both scheduled at or inside Batch B2. Both determine whether the feature can work at all; VT-2 determines whether it can work *on this tenant*. | TDD §15.2 | Move both to "before Step 05 closes". Nothing else in the plan changes. |
| **F-M-7** | Standards §9.5 (keep side effects out of an upgrade session; matters most for *shipped subscribers*) is not addressed in §12. Harmless today — both subscribers only delete or re-point rows — but it is the kind of thing that is cheap to record and expensive to rediscover. Separately: confirm the target sandbox's own localization when symbols are downloaded, so `Localization = US` is checked against reality, not just against §7.5's field analysis. | TDD §12, §16 | One line in §12; one row in §16. |

---

## 6. Checked and found correct — not re-opened later

Recorded so BUILD and Step 09 do not re-litigate settled ground. Each was independently verified
during this review, not accepted from the TDD's own assertion:

- **ID allocation and range discipline** — all 13 IDs in range, contiguous per module, no scatter;
  the interface correctly carries none; Object Register matches the TDD row for row.
- **Name and caption lengths** — re-counted by hand: entity/set names 20–22 chars, longest field
  identifier 21, permission set names 19 (≤ 20, `AL0305`), captions 26 (≤ 30), App Code `BBBRI` 5
  (≤ 6 for a 7-char prefix, Standards §5.4).
- **Mutability per Standards §2.2** — master data → `DelayedInsert`, audit → `Editable = false`,
  never both, on both API pages and the list page.
- **`ODataKeyFields = SystemId`** on both API pages; no business key used as the OData key.
- **`const()` quoting** — genuinely N/A, and stated as N/A rather than omitted.
- **Label discipline** — all 15 labels inventoried, correct AA0074 suffixes, `Comment` on every
  placeholder label, `Locked = true` on both tokens, no literal in any `Error`/`Message`.
- **API caption locking** — classified, the arguable object resolved first, Microsoft's precedent
  counts cited accurately, decision recorded per object with **AJ Ansari** named, corroborated by
  ChangeLog DEFINE-006.
- **Translation scope** — correctly N/A; `TranslationFile` correctly retained for AL0424; no
  glossary owed; **and** no US-regional wording for any standard BC concept anywhere in the source
  text, checked term by term.
- **Upgrade decision** — "none for v1" recorded with per-trigger reasoning against Standards §9.1,
  and the ordinal-0 design that makes it true by construction rather than by luck. §9.6's upgrade
  test correctly recorded as N/A-with-a-reason for a first release.
- **Events** — one published integration event with `[IntegrationEvent(false, false)]`, a
  signature-only `local procedure` raised explicitly, no `Handled` parameter, reasoning recorded;
  both subscriptions registered in the Object Register with `Database::` (never `Table::`) and the
  empty `ElementName` trap called out explicitly per Standards §10.1.
- **File naming** — every file name derives mechanically from its object per Standards §1.8,
  including both permission sets.
- **Batch plan** — simplest first; permission sets created in B1 with their `tabledata` grants and
  amended per batch, exactly as Standards §5.3 requires.
- **DR-4 country resolution (§7.2.1)** — the strongest piece of design in the TDD; ISO-code
  resolution with a raw-code fallback and refusal on ambiguity, correctly refusing rather than
  assuming in scope.
- **DR-8 defence (§6.3)** — refusing to store retrieved values on log rows, and naming the
  "helpful" future change that would break it, is exactly the right way to write a rule down.

---

## 7. Exit gate assessment (runbook Step 04)

| Gate condition | Status |
|---|---|
| **0 blocking issues** | **Met, as of 2026-09-16.** All 4 blocking findings (F-B-1 … F-B-4) resolved by AJ Ansari through the interactive options mechanism — see §7a below. |
| Every gap resolved or explicitly deferred with reasoning | **Met.** All 12 should-fix findings and all 7 minor findings have a recorded decision each (§7a). |
| Technical Lead sign-off (one sign-off covering `TDD.md` + `SanityCheck.md`, Approvers = one person) | **Due now** — the blocking condition above is what this sign-off was withheld for. |

**Recommendation to AJ Ansari.** This is a strong TDD — more rigorous than most, with genuinely
good work on DR-1/DR-4/DR-8 and an honest UNVERIFIED discipline for BC objects. None of the four
blocking findings requires re-architecting anything; all four are resolvable inside a single round:

1. **F-B-1** — one decision (accept / `OnValidate` check / system-owned field).
2. **F-B-2** — one paragraph in §6.9/§6.10 mandating `[TryFunction]` containment.
3. **F-B-3** — two §16 rows and one extra Step 12 test case (plus a fallback decision if the
   verification goes the wrong way).
4. **F-B-4** — one rename, before any code exists, or one recorded FRD exception.

The 12 should-fix findings split into three groups that can each be handled together: **documented
decisions owed** (F-S-2, F-S-3, F-S-5, F-S-6, F-S-12), **spec corrections before Step 06** (F-S-1,
F-S-7, F-S-9, F-S-10, F-S-11), and **verification-worksheet completeness** (F-S-4, F-S-8).

Per Operating Rule 6, the fixes that change only the TDD should be presented for one batched
approval; **F-B-1, F-B-4, F-S-2, and F-S-5 change the FRD or a design rule and each need their own
separate approval.**

---

## 7a. Resolution Log (added 2026-09-16, main role — this document's content above is otherwise left
untouched as the historical record of the independent review)

All decisions below were made by **AJ Ansari, 2026-09-16**, through the interactive options
mechanism, and applied by the main role. Full cross-reference is `docs/TDD.md` §15.1a; each
resolution's design-document detail is cited there.

| # | Finding | Decision | Applied in | ChangeLog |
|---|---|---|---|---|
| F-B-1 | URL-maintenance authority unenforceable | Option 2 — "Enforce in `OnValidate`" | TDD §6.4, §9.4, §10.2; FRD FR-11, DR-6, §10.1 | DEFINE-007 |
| F-B-2 | No containment for an unexpected provider error | `TryGetRating` required inside a `[TryFunction]` | TDD §6.9, §6.10, §16 | DEFINE-014 |
| F-B-3 | Cascade-delete permission story asserted, untested for "neither set" | Two §16 rows + §9.4 test 5 + fallback contingency | TDD §6.8, §9.4, §16 | DEFINE-014 |
| F-B-4 | DR-3 leaked via `HTTP Status Code` | Option 1 — "Rename to transport-neutral" | TDD §6.3, §6.9, §6.10, §7.2, §7.3, §7.6 | DEFINE-008 |
| F-S-1 | No precondition checks Customer write permission | Precondition (d) + new label | TDD §7.2, §10.2 | DEFINE-014 |
| F-S-2 | Precondition refusals excluded from DR-2 by TDD reinterpretation | Amend DR-2's wording | FRD DR-2; TDD §7.2 step 3 | DEFINE-009 |
| F-S-3 | Two objects beyond FRD inventory, logging waived | Logged; FRD re-baseline noted for Step 10 | TDD §3.5 | DEFINE-012 |
| F-S-4 | Standards §5.2 per-module buffer met by no module | Second allocation, 50621–50650 | Parameters §1.2; TDD §3.4; ObjectRegister §1 | DEFINE-010 |
| F-S-5 | Narrow API field list self-certified as compliant | "Approve as a recorded deviation" | TDD §7.5 | DEFINE-011 |
| F-S-6 | Two-`using` deviation self-approved | "Approve the exception" | TDD §8.1 | DEFINE-011 |
| F-S-7 | 50614 sets neither `InsertAllowed`/`DeleteAllowed`; deletion undecided | Both set `false`; deletion decision stated | TDD §6.12, §16 | DEFINE-014 |
| F-S-8 | UNVERIFIED discipline stops at BC objects | 8 rows added to §16 | TDD §16 | DEFINE-014 |
| F-S-9 | Cascade keyed on the volatile `"Customer No."` | Re-keyed on `"Customer SystemId"` | TDD §6.8 | DEFINE-014 |
| F-S-10 | §7.2 step 8 uses non-AL ternary syntax | Explicit `if`/`else` | TDD §7.2 | DEFINE-014 |
| F-S-11 | FR-9's "filtered to failures" has no mechanism | Standard column filtering, recorded as resolution | TDD §6.6; FRD FR-9 | DEFINE-014 |
| F-S-12 | Stale `ProblemStatement.md` contradicts DR-6 | Corrected `ProblemStatement.md` and FRD §10.1 | ProblemStatement.md; FRD §10.1 | DEFINE-013 |
| F-M-1 | EDIT grant `RIMD` wider than needed | Narrowed to `RID` | TDD §9.2, §9.3; ObjectRegister §2 | DEFINE-014 |
| F-M-2 | "A FactBox is a display surface" overstated | Reworded; E-6 decision unchanged | TDD §3.6 | DEFINE-014 |
| F-M-3 | ObjectRegister OD-1 stale | Corrected to "Resolved, DEFINE-006" | ObjectRegister §6 | DEFINE-014 |
| F-M-4 | Reverse `TableRelation` check and customer-deletion stance unrecorded | Two lines added | TDD §13.3 | DEFINE-014 |
| F-M-5 | Next free Customer extension field ID unrecorded | Note added: 50607 | ObjectRegister §3 | DEFINE-014 |
| F-M-6 | VT-2/VT-3 scheduled at/inside Batch B2 | Moved to "before Step 05 closes" | TDD §15.2 | DEFINE-014 |
| F-M-7 | Standards §9.5 and sandbox localization unrecorded | One line + one §16 row added | TDD §12, §16 | DEFINE-014 |

**Exit gate re-assessment:** with all 23 findings resolved, the Step 04 exit gate (§7 above) is met.
Technical Lead sign-off on `TDD.md` + `SanityCheck.md` together (Approvers = one person) is due.

---

*Prepared by the reasoning role (independent reviewer) under the OnlyCopilotFans Agentic Dev
Framework v3.3.0.0, runbook Step 04. No design document was edited by this reviewer: findings only.
`FRD.md` and `TDD.md` are untouched by the review itself — §7a above records the main role's later
resolution pass.*
