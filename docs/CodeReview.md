# Code Review — BBB Rating Insights

> ## ⚠️ EARLY / SOURCE-LEVEL REVIEW — PENDING A CONFIRMED CLEAN LOCAL COMPILE
>
> **This is Runbook Step 09 run out of sequence, at AJ Ansari's explicit request.** Normally Step
> 09 runs after Step 07's analyzer-enabled compile reaches 0 errors / 0 warnings and after Step
> 08's gap-fit test closes. Neither has happened: local compilation is still in progress
> (ChangeLog **DEFINE-015**, **DEFINE-016**), and Step 08 has not run.
>
> **What that means for this document:**
> - Every finding below is derived from **reading the source**, not from compiler or analyzer
>   output. Several findings are explicitly *"verify at the local compile"* items, and they are
>   marked as such rather than asserted as defects.
> - Step 09's own mandate says several checks are *"already proven by the last 0/0 compile"*
>   (`Rec.` qualification, `PTE0004` `tabledata` coverage, `AL0424`/ML syntax). **There is no 0/0
>   compile to lean on**, so this review re-derived each of those by hand and says so per item.
> - **Symbol-dependent checks could not be performed at all** — this session has no AL Language
>   extension, no compiler, and no symbol files (ChangeLog **DEFINE-004**). The "marked for
>   obsoletion" dimension is therefore **deferred**, not cleared (§4 below).
> - **This review must be re-run, or at least re-confirmed, after Step 07 closes 0/0** and after
>   TDD §16's verification worksheet (VT-1) and VT-3's parse markers land, since both change code
>   this review has read.
>
> **Nothing in this document has been applied.** Per the reviewer's mandate, no `.al` file and no
> other document was edited. Findings only; the main role applies fixes after AJ Ansari decides.

**Project:** BBB Rating Insights (Business Central SaaS PTE)
**Phase / Step:** PROVE — Runbook Step 09 (early), run by the **reasoning role**
**Date:** 2026-09-17
**Inputs read in full:** `CLAUDE.md` §09, `docs/FRD.md`, `docs/TDD.md`, `docs/ChangeLog.md`
(DEFINE-001 – DEFINE-016), `docs/SanityCheck.md` cross-references, `docs/ObjectRegister.md`,
`docs/PreflightChecklist.md`, `standardsGuide/ocpfALDevStandardsGuide.md` Parts 1, 2, 4, 7, all
**14 generated AL files**, `app.json`, `.vscode/settings.json`, `.gitignore`, `patterns/`, and the
BCQuality snapshot at `/home/user/claudeCodeMobileDevTest.bcquality/`.

---

## 1. Summary

| Severity | Count | Meaning here |
|---|---|---|
| **Critical** | **1** | Could make the feature unusable for its intended role; must be resolved or verified before Step 12 testing. |
| **Major** | **7** | A real defect, a Standards/BCQuality anti-pattern hit, or a wrong-direction user message. Fix before release. |
| **Minor** | **14** | Least-privilege, robustness, maintainability, or compile-risk items. |
| **Info** | **2** | Documentation accuracy / wording. No code defect. |
| **Total** | **24** | |

**By source:**

| Source | Count | Confidence rule applied |
|---|---|---|
| BCQuality knowledge-backed (cites a knowledge file) | 10 | Up to `high` |
| Reviewer findings (`references: []`) | 14 | **Capped at `medium`** per BCQuality's DO contract |

**Nine findings change a document, a design rule, or a signed-off decision** (CR-01, CR-02, CR-04,
CR-05, CR-07, CR-09, CR-18, CR-19, CR-23). Per Operating Rule 6, those **must be asked separately**
from the bulk "apply all" approval for the mechanical fixes.

**Five findings are purely mechanical and carry no design consequence** (CR-03, CR-08, CR-11,
CR-16, CR-22) — these are the natural "apply all" bundle.

### Dimension roll-up (Step 09's mandate, one row per required check)

| # | Step 09 dimension | Result |
|---|---|---|
| 1 | Code quality / template conformance / cross-batch consistency | **Largely clean**, with one real drift: CR-03. See §2.1. |
| 2 | Dead code (empty triggers, commented-out blocks, `// TODO`) | **One real finding: CR-02** (unreachable label via a stub that always returns false) and **CR-04** (a subscriber that may be dead in practice). No `// TODO`, no commented-out fields, no empty triggers. `ApplyFailure` is the documented intentional no-op — **not flagged; its comment still explains DR-1 correctly** (§2.2). |
| 3 | Redundant code | CR-16 (likely unnecessary `using`), CR-17 (duplicated captions/tooltips — **Standards vs BCQuality conflict, surfaced not fixed**), CR-04 (redundant rename loop). |
| 4 | "Marked for obsoletion" | **DEFERRED — not checked, and this review does not claim it was.** §4. |
| 5 | Standards Part 7 Anti-Patterns (full table, row by row) | **28 of 28 rows walked.** 1 hit (CR-03 by implication), 1 conflict (CR-17), the rest clean. §5. |
| 6 | Deprecated multilanguage syntax | **Clean — verified by search, not by compile.** §6. |
| 7 | Translations (N/A for this project) | **Confirmed still N/A**, with one regional-wording check passed. §7. |
| 8 | Best practices / metadata / mutability / permission sets / `Rec.` / `tabledata` | CR-01, CR-06, CR-09, CR-10, CR-13, CR-24. §8. |
| 9 | **BCQuality knowledge-backed review** | **Executed. `outcome: routed` → `al-code-review` super-skill, 17 leaves + community leaf skipped. 10 knowledge-backed findings.** §9. |
| 10 | AL Guidelines best-practice pass | **SKIPPED — no live internet access to alguidelines.dev in this session. No citation to it is made anywhere in this document.** §10. |

---

## 2. Findings by dimension

### 2.1 Code quality, template conformance, cross-batch consistency

**Verified clean:**

- All 14 files open with `namespace OnlyCopilotFans.BBBInsights;` as line 1, flat, no sub-namespaces
  (Standards §1.1).
- One object per file; every file name matches Standards §1.8's pattern and TDD §14's layout
  (`AA0215` shape checked by hand — 14/14 correct, including the two permission sets'
  `OCPFBBBBBBRIVIEW.PermissionSet.al` / `OCPFBBBBBBRIEDIT.PermissionSet.al`).
- **4-space indentation, spaces only, zero tabs** — confirmed by search across `src/` (Standards §1.6).
- **`Rec.` qualification on every page/page-extension field source** — confirmed by hand across
  50610, 50611, 50613, 50614 (Standards §1.2). *Normally proven by the 0/0 compile; there isn't one
  yet, so this was re-derived manually.*
- Every API page carries `ODataKeyFields = SystemId`, `APIPublisher`, `APIGroup`, `APIVersion`,
  `EntityName`, `EntitySetName`, a complete-sentence `Caption`, and camelCase API identifiers
  (Standards §2.1, §2.5, §2.7). Longest identifier `ocpfBbbComplaintCount` (21) — well inside 30.
- Both permission-set names are 19 characters, captions 26 (Standards §5.4).
- Comment density and cross-reference style (`TDD §x`, `DR-n`, `ChangeLog DEFINE-nnn`) are
  **consistent across all four batches** — no early-batch/late-batch drift of the kind Step 09 warns
  about. B1 and B4 read as if written by the same hand, which is the outcome this check wants.

**One genuine consistency drift → CR-03.** The same table (`ocpfBbbFetchLog`) is locked down
differently by its two read-only surfaces: page 50611 sets `Editable`, `InsertAllowed`,
`ModifyAllowed` **and** `DeleteAllowed` to `false`; API page 50614 sets only `Editable`,
`InsertAllowed` and `DeleteAllowed`. The API surface — the one reachable by an external client — is
the *less* protected of the two.

### 2.2 Dead code

- **No `// TODO`, no `FIXME`, no commented-out fields, no empty triggers** — confirmed by search.
- **`ApplyFailure` is not flagged.** It is the TDD-documented intentional no-op, and per the review
  mandate it is exempt. **Confirmation, as asked:** its comment (`ocpfBbbRatingMgt.Codeunit.al`
  lines 170–175) still states DR-1 in full and still explains that *its existence, not its body, is
  the guarantee*, naming the specific future edit that would break DR-1. The comment is intact,
  accurate and sufficient. (A separate, unrelated concern about its **parameter** is CR-13.)
- **Real dead code found:** CR-02 (`CallNotAllowedReasonTxt` is unreachable because
  `CallWasBlockedByEnvironment()` is a stub that always returns `false`) and, pending verification,
  CR-04 (the rename subscriber's loop may never find a row to modify).

### 2.3 Redundant code

- No duplicate `using` directives in any file. `ocpfBbbRatingMgt`'s two `using` lines are the
  approved F-S-6 deviation (ChangeLog DEFINE-011) — correct as built.
- CR-16: `using System.Utilities;` in `ocpfBbbProfileReader` is likely unnecessary.
- CR-17: `Caption`/`ToolTip` duplicated verbatim from the table fields onto bound page fields —
  **a Standards-Guide-vs-BCQuality conflict, surfaced for AJ Ansari rather than resolved.**
- No duplicate field exposures: 50613 exposes each source field exactly once; 50614 likewise.

---

## 3. Findings register

> **Columns:** ID · Severity · Dimension · Where · What · Root cause · Proposed resolution ·
> Source/confidence · Does it change a document?

---

### CR-01 · **CRITICAL** · Best practices / permissions · *reviewer finding, confidence: medium*

**Where:** `src/Security/OCPFBBBBBBRIEDIT.PermissionSet.al:10`;
`src/Logic/ocpfBbbRatingMgt.Codeunit.al:41`; `src/CoreData/ocpfBbbCustomerExt.TableExt.al:55`.

**What.** The entire authority model of this extension — *both* halves of FR-11 — keys off
`FetchLog.WritePermission()`. The EDIT permission set grants `tabledata "ocpfBbbFetchLog" = RID`,
deliberately **without `M`** (ChangeLog DEFINE-014, finding F-M-1). If AL's
`Record.WritePermission()` is defined as *"the user holds insert **and** modify **and** delete"*
rather than *"any write"*, then a Credit & Risk user holding `OCPFBBB BBBRI, EDIT` gets
`WritePermission() = false` and is refused **both** the refresh action **and** the URL edit — by
this extension's own code, with `NoRefreshPermissionErr` / `NoUrlEditPermissionErr` telling them to
ask their administrator for the very permission set they already hold. The feature would be
unusable for the only role allowed to use it.

**Root cause.** Two individually sound, separately approved decisions interact: DEFINE-007 chose
`WritePermission()` as the authority proxy, and DEFINE-014/F-M-1 later narrowed the grant from
`RIMD` to `RID` for least privilege. Neither decision re-checked the other, and the exact semantics
of `WritePermission()` were already logged as unverified (**TDD §16 row 23**) — this is what that
row is actually protecting against.

**Proposed resolution.** Verify §16 row 23 locally *before* Step 12 (it is a one-line test in a
sandbox). Then either (a) confirm "any write" semantics and record the result in the TDD, closing
this; or (b) restore `M` to the EDIT grant and correct F-M-1's reasoning; or (c) replace the proxy
with an explicit, intention-revealing check. **Do not let Step 12 discover this** — §9.4 tests 1–3
all pass or fail on it.

**Changes a document?** **Yes** if (b) or (c) — TDD §9.2, §6.4, §6.5, §7.2 and `ObjectRegister.md`.
Ask separately.

---

### CR-02 · **MAJOR** · Dead code + error behavior (NFR-9) · *reviewer finding, confidence: medium*

**Where:** `src/Logic/ocpfBbbProfileReader.Codeunit.al:73–82`, `116–125`, `239`.

**What.** `CallWasBlockedByEnvironment()` is a stub whose body is `exit(false)`. Consequently:

1. **`CallNotAllowedReasonTxt` is unreachable** — a label that no code path can ever produce. That
   is dead code by Standards §1.5's own definition, and it is the *one* label written for the
   failure mode that is still an open verification task (**OQ-7 / PA-3 / VT-2**).
2. **Every connection-level failure is reported to the user as `TimeoutReasonTxt`** — *"The BBB
   website did not respond in time."* `HttpClient.Get` returning `false` covers a blocked outbound
   call, DNS failure, connection refused, and TLS failure just as much as a timeout.

On a tenant where "Allow HttpClient Requests" has not been switched on — the *expected* state until
VT-2 is done — the first thing every user sees is a message blaming BBB for being slow. That sends
the administrator to the wrong place and defeats NFR-9 ("what happened, why, and what to do next").

**Root cause.** A placeholder for an unresolved verification item (§16 row 29) was implemented as a
*silently-false* stub rather than as a fail-loud or neutral path, and the label mapping was written
against the ideal design rather than the stub's actual behavior.

**Proposed resolution.** Pick one, at the same time as VT-2:
- **(a) Neutral wording (recommended, smallest).** Replace the `TimeoutReasonTxt` branch with a
  reason that is true for every connection-level failure — *"Business Central could not reach the
  BBB website. If this is the first refresh on this environment, ask your administrator to confirm
  that outbound web requests are allowed for BBB Rating Insights."* — which covers both cases
  honestly and names the most likely remedy. Retire or repurpose `CallNotAllowedReasonTxt`.
- **(b) Finish §16 row 29 first** and implement a real detection, keeping both labels.

Either way, CR-07's `GetLastErrorText()` capture is what puts the *actual* distinction in the log.

**Changes a document?** **Yes** — TDD §7.3's mapping table and §10.2's label inventory. Ask
separately.

---

### CR-03 · **MAJOR** · Standards/API + consistency · *knowledge-backed, confidence: high*

**Reference:** `microsoft/knowledge/web-services/disable-write-operations-on-read-only-api-pages.md`

**Where:** `src/API/ocpfBbbFetchLogEntries.Page.al:21–25`.

**What.** Page 50614 sets `Editable = false`, `InsertAllowed = false`, `DeleteAllowed = false` — but
**not `ModifyAllowed = false`**. The cited article is explicit that a read-only API page needs all
three CRUD guards plus `Editable = false`, because *"the default for an API page is writable, and
the read-only intent has to be encoded as three explicit property settings, not inferred."* Whether
`Editable = false` alone refuses an OData `PATCH` was already flagged as unproven in this project's
own TDD (**§16 row 22**) — so the code currently depends on exactly the assumption the article
says not to depend on. Sibling page 50611 gets this right, which makes it a consistency drift too.

**Root cause.** F-S-7 (ChangeLog DEFINE-014) added `InsertAllowed`/`DeleteAllowed` in response to a
finding phrased around *insert and delete*; `ModifyAllowed` was never in that finding's scope, and
the Step 05 checklist's B4 row inherited the same two-property wording.

**Proposed resolution.** Add `ModifyAllowed = false;` to page 50614. Also correct
`docs/PreflightChecklist.md`'s B4 row to name all three properties, so a regenerated API page
cannot lose it again (root-cause fix, not instance fix).

**Changes a document?** Only the checklist and TDD §6.12's property table — a wording correction,
not a design change. Safe for the bulk approval.

---

### CR-04 · **MAJOR** · Dead code + data modeling + performance · *knowledge-backed, confidence: medium*

**References:** `microsoft/knowledge/data-modeling/validate-table-relation-false-suppresses-rename-propagation.md`
(primary), `microsoft/knowledge/data-modeling/owning-table-must-delete-dependents-in-ondelete.md`,
`microsoft/knowledge/performance/prefer-modifyall-over-per-row-modify.md`

**Where:** `src/Logic/ocpfBbbCustomerSubscribers.Codeunit.al:48–59`;
`src/CoreData/ocpfBbbFetchLog.Table.al:33`.

**What.** The `OnAfterRenameEvent` subscriber exists to re-point `"Customer No."` on log rows after
a customer is renamed. Two independent BCQuality articles state that **the platform already does
this**: *"Renaming a record updates it in all other locations that reference it through a
`TableRelation`, with no code"*, and the only two things that suppress it are (i) no `TableRelation`
and (ii) `ValidateTableRelation = false`. `ocpfBbbFetchLog."Customer No."` declares
`TableRelation = Customer."No."` and does **not** set `ValidateTableRelation = false`. Both
preconditions for automatic propagation are therefore met.

If that holds, then by the time `OnAfterRenameEvent` fires the rows already carry the new number,
`SetRange("Customer No.", xRec."No.")` matches nothing, and the whole subscriber is a no-op that
costs a database round-trip on every customer rename — **dead code in the Step 09 sense**. It is
also the *only* reason the subscriber codeunit needs `M` in its `Permissions` (CR-09), and the
source of a factual error repeated in three documents (CR-23).

Separately, and regardless of the above: the loop assigns a constant with `Modify()` and no
validation — the exact anti-pattern in `prefer-modifyall-over-per-row-modify.md`, where
`ModifyAll("Customer No.", Rec."No.")` is the correct shape. On a table designed to grow without
bound (FR-10, no purge) this is a per-row round trip that scales with a customer's refresh history.

**Steelman (why this is "verify", not "delete now").** The design's own reasoning in TDD §3.5 is
about *cascade delete*, where the articles agree no automatic behavior exists. The rename
subscriber was added defensively alongside it. It is possible — though neither article supports it —
that propagation does not reach an extension-owned table in some edge case. That is exactly what
makes this a **local verification task**, not a blind deletion.

**Proposed resolution.**
1. **Verify locally** (5 minutes, no compile needed beyond a publish): create a log row, rename the
   customer, inspect `"Customer No."` on the row **with the rename subscriber disabled**.
2. If the platform propagated it — **delete the rename subscriber**, drop `M` (and `I`) from the
   codeunit's `Permissions` (CR-09), and record the platform behavior in the TDD so the next
   developer doesn't re-add it.
3. If it did not — **keep it but convert the loop to `ModifyAll`**, and correct the three documents
   named in CR-23.

**Note on `xRec`:** `xrec-is-a-before-image-only-in-some-triggers.md` was checked against this code
and **confirms the usage is correct** — `xRec` *is* a genuine before-image on the rename path, from
code as well as from a page. No finding there.

**Changes a document?** **Yes** — TDD §6.8, §9.2, §13.1, `ObjectRegister.md`. Ask separately.

---

### CR-05 · **MAJOR** · Security (SSRF) · *knowledge-backed, confidence: high* · **contradicts DR-5 — needs its own decision**

**Reference:** `microsoft/knowledge/security/validate-user-configurable-urls.md`

**Where:** `src/Logic/ocpfBbbProfileReader.Codeunit.al:73`;
`src/CoreData/ocpfBbbCustomerExt.TableExt.al:36–70`.

**What.** `HttpClient.Get(ProfileUrl, HttpResponseMessage)` is called with a value that came
straight from a table field a user can write (`"ocpfBbb Profile URL"`, and it is writable through
the API too). The article's anti-pattern is stated almost verbatim for this shape: *"Reviewers
should flag any `HttpClient` call whose first argument is a record field, an `OnValidate`-mutable
field, or a value sourced from a table read, unless a `Uri.AreURIsHaveSameHost` or
`Uri.IsValidURIPattern` check precedes it."* The extension becomes an SSRF primitive: anyone who can
write the field can make the tenant's Business Central issue a request to any host, and BC will
send it.

The current code validates only the **scheme** (`https://`), which stops plaintext but not
redirection to an arbitrary host.

**Root cause — and why this is not simply a bug.** This is a **deliberate, documented design
decision**: TDD §6.4 says *"the host is still deliberately not validated: **DR-5** says the URL is
staff-entered and staff-owned, and a hardcoded `bbb.org` host check would be this extension quietly
deciding what a valid BBB page is."* That reasoning is real. But DR-5 is about *who owns the
value*, and this article is about *what the extension is willing to send a request to* — they are
not the same question, and the security consequence was not weighed when DR-5 was written.

**Proposed resolution — this needs AJ Ansari's decision, not a patch.** Three defensible options:
- **(a) Pattern check (recommended).** `Uri.IsValidURIPattern(ProfileUrl, 'https://*.bbb.org/*')`
  before the call, failing with a business-readable reason. This keeps DR-5's "staff enter the
  URL" intact — staff still choose *which* BBB page — while removing the arbitrary-host capability.
  It does mean the extension asserts that a BBB profile lives on a `bbb.org` host, which is the
  narrow thing DR-5 objected to.
- **(b) Same-host check against a stored expected base**, which is the article's other offered shape.
- **(c) Accept and document the risk**, adding it to FRD §7.1's disclosed-risk list beside the
  scraping risks AJ already accepted (DEFINE-001), so it is an informed acceptance rather than an
  unexamined one. **If this is the choice, FRD §7.1 must say so in words** — an accepted risk that
  is not written down is indistinguishable from an oversight at the next review.

**Changes a document?** **Yes, in every option** — FRD DR-5 and/or §7.1, TDD §6.4/§6.10. Ask
separately, in its own box.

---

### CR-06 · **MAJOR** · Best practices / permissions · *reviewer finding, confidence: medium*

**Where:** `src/UI/ocpfBbbCustomerCardExt.PageExt.al:109–111`, `85`.

**What.** The page extension declares `RatingMgt: Codeunit "ocpfBbbRatingMgt"` as a **page-level
global**, while `OCPFBBB BBBRI, VIEW` deliberately withholds execute permission on that codeunit
(TDD §9.1: *"no execute permission on `ocpfBbbRatingMgt` or `ocpfBbbProfileReader`"*). If AL
instantiates a page's global codeunit variables when the page object is instantiated — rather than
lazily at first call — then **every Sales user opening a Customer Card meets a permission error on
a standard BC page**, which is simultaneously a violation of DR-13 ("the extension adds; it never
alters") and the exact opposite of the greyed-out-button experience NFR-9 and OQ-4 were designed
around.

**Root cause.** The variable was hoisted to page scope for convenience; the permission design
deliberately denies execute on that object to the same users who open that page. The two were never
compared.

**Proposed resolution — mechanical and risk-free either way.** Move the declaration into the
action's own trigger:

```al
trigger OnAction()
var
    RatingMgt: Codeunit "ocpfBbbRatingMgt";
begin
    RatingMgt.RefreshRating(Rec);
end;
```

The action is already `Enabled = RefreshAllowed`, so a VIEW user never reaches it, and the question
of when a page global is instantiated stops mattering. Do this regardless of how the instantiation
question resolves — it costs nothing and removes a whole class of doubt. **Step 12 §9.4 test 1 must
still be run**, since it is the test that would have caught this.

**Changes a document?** TDD §6.5's code sketch. Trivial; can ride with the bulk approval.

---

### CR-07 · **MAJOR** · Error handling / diagnosability · *knowledge-backed, confidence: medium*

**Reference:** `microsoft/knowledge/performance/use-tryfunction-for-error-catching-not-rollback.md`

**Where:** `src/Logic/ocpfBbbProfileReader.Codeunit.al:44–53`.

**What.** When the `[TryFunction]` catches a runtime error, the handler discards the platform's own
diagnosis:

```al
Success := false;
FailureReason := UnexpectedReasonTxt;   // 'The BBB profile page could not be read.'
SourceStatusCode := 0;
```

`GetLastErrorText()` is never read, so the log row for the single most likely failure class in this
whole extension (PA-4: a page-structure change breaking the parser, an unexpected type conversion,
an HTTP stack error) says nothing more than *"could not be read"*. The cited article is explicit:
*"When you do catch, read `GetLastErrorText` immediately after the failed call"* — and notes that
the session error buffer is overwritten by the next catch, so "later" is not an option.

This is not merely a BCQuality preference here — it contradicts this project's own requirements.
**FRD NFR-9** says the user gets a business sentence *"(the underlying detail belongs in the log,
FR-8)"*, and **UC-6 / BO-5** exist specifically so an administrator can answer *"why did this stop
working, and when did it start failing?"*. The underlying detail is currently discarded, not logged.

**Proposed resolution.** Capture the platform error text on the caught path and carry it to the log
only — never to the user (NFR-9). Options: put it in `"Failure Reason"` after the business sentence,
truncated with the existing `CopyStr`; or add a dedicated diagnostic field. **Two consequences to
decide with it:**
1. `"Failure Reason"` is currently `DataClassification = SystemMetadata` on the grounds that it
   holds only this extension's own label text. Raw platform error text can contain customer data, so
   the classification must be revisited (`CustomerContent`) or the text routed to a separate,
   correctly classified field. See `microsoft/knowledge/privacy/data-classification-required-on-pii-fields.md`.
2. Consider `ClearLastError()` before the call, per the same article, so an earlier catch elsewhere
   in the session cannot be misread as this failure.

**Changes a document?** **Yes** — TDD §6.3 (field spec + classification), §7.3, §10.2. Ask
separately.

---

### CR-08 · **MAJOR** · UI / action promotion · *knowledge-backed, confidence: high*

**Reference:** `microsoft/knowledge/ui/prefer-actionref-syntax-for-promoted-actions.md`
(`bc-version: [21..]` — applies; this project targets runtime 16.0 / BC 27)

**Where:** `src/UI/ocpfBbbCustomerCardExt.PageExt.al:77–79`.

**What.** The refresh action uses the legacy promotion properties
(`Promoted = true; PromotedCategory = Process; PromotedOnly = true;`). Since BC 21 the supported
shape for new pages and page extensions is an `area(Promoted)` block with `actionref`. The article's
reviewer signal is *"any `Promoted`-prefixed property on an action in a newly authored page or page
extension"*. Three further points from it that matter here:

- The two syntaxes **cannot be mixed within one object** — so this must be decided per object, once.
- The no-mixing rule is **per-object, not per-dependency-tree**, so it does not matter which syntax
  the standard Customer Card itself uses. TDD §16 row 13's open question is therefore narrower than
  it looks.
- **Once an action is promoted in a published app, removing the promotion is a breaking change**
  (AS0031/AW0013). Getting this right before v1 ships is cheaper than any later correction.

**Proposed resolution.** Convert to `area(Promoted)` + `actionref` (VS Code offers an automated
conversion). Purely mechanical; no behavior change intended.

**Changes a document?** TDD §6.5's action table and §16 row 13. Mechanical — bulk approval.

---

### CR-09 · **MINOR** · Security / least privilege · *knowledge-backed, confidence: medium*

**References:** `microsoft/knowledge/data-modeling/owning-table-must-delete-dependents-in-ondelete.md`
(primary), `microsoft/knowledge/security/indirect-permissions-for-elevated-access.md`

**Where:** `src/Logic/ocpfBbbCustomerSubscribers.Codeunit.al:10`.

**What.** `Permissions = tabledata "ocpfBbbFetchLog" = RIMD;` grants the full set on the object that
elevates permissions for the cascade. For exactly this cascade scenario the primary article
prescribes the minimum: *"Declare `Permissions = tabledata <dependent> = rd` on the owning table"* —
read and delete, and lowercase (indirect) at that. In this codeunit:

- `D` is required (the cascade delete).
- `R` is required (the `SetRange`/`FindSet`).
- **`I` is never used by either subscriber** — nothing in this file inserts.
- **`M` is used only by the rename subscriber**, which CR-04 may retire entirely.

**Proposed resolution.** Narrow to `RD` once CR-04 resolves (or `RMD` if the rename subscriber
stays). Note the irony worth recording: the EDIT *permission set* was narrowed for exactly this
reason in DEFINE-014 (F-M-1), while this codeunit-level grant — which elevates for **every** user,
including those holding no BBB permission set at all — kept the full `RIMD`.

**Changes a document?** TDD §6.8, `ObjectRegister.md`. Bundle with CR-04's decision.

---

### CR-10 · **MINOR** (impact potentially higher — see note) · Security / data integrity · *reviewer finding, confidence: medium*

**Where:** `src/Logic/ocpfBbbCustomerSubscribers.Codeunit.al:34–40`, `49–59`.

**What.** Neither subscriber guards against a **temporary** `Customer` record. Table-trigger event
subscribers fire for temporary record instances as well as real ones, and a temporary record copied
from a real customer carries the same `SystemId`. A delete against someone else's temporary Customer
buffer — an import routine, a wizard, another extension's working set — would therefore run
`FetchLog.DeleteAll(false)` against **real audit rows** for a real customer, silently, with no error
and no trace. Losing audit rows this way is invisible by construction: the table has no other
writer to notice the gap.

**Steelman.** No such caller exists inside this extension, and BC's own base app is careful with
temporary Customer buffers. This is a defense against *other* code, present and future, on a shared
tenant — which is precisely when a SaaS PTE cannot assume anything.

**BCQuality validation.** `security/guard-bulk-operations-with-istemporary.md` covers the adjacent
case (a helper that bulk-operates on *its own* `var Rec` parameter) and does **not** cover a
subscriber that bulk-operates on a *different* table keyed from `Rec`. No article contradicts the
candidate, so per BCQuality's DO contract this is emitted as a **reviewer/agent finding, confidence
capped at `medium` and severity capped at `minor`** — with the note that contract itself requires:
**the real-world impact of this one is data loss, not a style issue, and it is a good candidate for
promotion to a `patterns/` entry** (it is the shape that recurs on every extension that cascades
from a standard table).

**Proposed resolution.** One line at the top of each subscriber:

```al
if Rec.IsTemporary() then
    exit;
```

**Changes a document?** TDD §6.8 gains a line. Otherwise mechanical.

---

### CR-11 · **MINOR** · Performance · *knowledge-backed, confidence: high*

**Reference:** `microsoft/knowledge/performance/dataaccessintent-readonly-on-analytical-objects.md`
(`bc-version: ["16.."]` — applies at runtime 16.0)

**Where:** `src/API/ocpfBbbFetchLogEntries.Page.al`.

**What.** Page 50614 is a `PageType = API` page with `Editable = false` that never writes — the
article's exact profile for `DataAccessIntent = ReadOnly`, which lets it serve from a read replica
instead of competing with posting on the primary. The article notes agents omit it *"because the
default is read-write and the object 'only reads' in AL"* — the replica routing is a metadata
switch, never inferred.

This matters more than usual here: FR-10 keeps every log row forever with no purge (OQ-5), and
TDD §13.3 already names unbounded growth as the accepted risk. A monitoring consumer polling this
endpoint should not be pointed at the primary.

**Not applicable to 50613** — it is `DelayedInsert = true` (writable), so the property would be
wrong there.

**Proposed resolution.** Add `DataAccessIntent = ReadOnly;` to page 50614.

**Changes a document?** TDD §6.12's property table. Mechanical — bulk approval.

---

### CR-12 · **MINOR** · Compile risk / measurement accuracy · *reviewer finding, confidence: medium*

**Where:** `src/Logic/ocpfBbbProfileReader.Codeunit.al:35–36`, `55–56`.

**What.** Two issues in one expression, `DurationMs := EndTime - StartTime;` where `DurationMs` is
`Integer`:

1. **Type.** Subtracting two `DateTime` values yields a `Duration`, not an `Integer`. Whether AL
   converts implicitly here must be confirmed at the compile; if it does not, this is a hard error.
   Safe shape: capture into a `Duration` local and convert explicitly.
2. **Semantics.** The window measured spans the HTTP call **and all parsing**, but TDD §6.3
   documents the field as *"Round-trip duration… the evidence that distinguishes 'BBB is slow' from
   'BBB is blocking us'"*. Once VT-3's real parser lands, parse time will be folded into a number
   whose documented purpose is to characterise the network. Move `EndTime := CurrentDateTime();` to
   immediately after the `HttpClient.Get`/`ReadAs` step, or state in the TDD that the figure is
   total elapsed time.

**Changes a document?** Item 2 changes TDD §6.3's field note. Small — can ride with the bulk
approval, flagged as wording.

---

### CR-13 · **MINOR** · Compile risk (zero-warnings gate) · *reviewer finding, confidence: medium*

**Where:** `src/Logic/ocpfBbbRatingMgt.Codeunit.al:66`, `169–176`.

**What.** `ApplyFailure(var Cust: Record Customer)` never reads or writes its parameter — that is
the entire point of the procedure (DR-1), and **the procedure itself is not being flagged**. The
risk is narrower: CodeCop's unused-variable/parameter diagnostics may emit a warning on it, and
under Operating Rule 5 *a warning is a defect* with nothing suppressible (the framework ships no
ruleset and `#pragma warning disable` is banned). If that warning appears, Step 07 cannot reach 0/0
without a change here.

**Proposed resolution.** Do nothing until the compile speaks. If a warning appears, change the
signature to `local procedure ApplyFailure()` and the call site to `ApplyFailure()`, **keeping the
comment block verbatim** — the comment, not the parameter, is what carries DR-1's guarantee.

**Changes a document?** No.

---

### CR-14 · **MINOR** · Encoding · *reviewer finding, confidence: medium*

**Where:** all 14 files in `src/`; specifically
`src/Logic/ocpfBbbProfileReader.Codeunit.al:247–249`.

**What.** Every AL file is **UTF-8 without a BOM** (verified: first three bytes are `6e 61 6d` —
`nam`, not `EF BB BF`), and every file contains non-ASCII characters (em dashes and arrows), from 2
occurrences in the smallest file to 46 in `ocpfBbbRatingMgt.Codeunit.al`. Most are in comments,
which is cosmetic — but **three are inside `Label` string values**:

```al
GradeAnchorPlaceholderTok: Label 'PLACEHOLDER_GRADE_ANCHOR — REPLACE BEFORE USE', Locked = true;
```

The AL toolchain conventionally expects UTF-8 **with** BOM; without it, non-ASCII characters can be
misread, which corrupts both source comments and — more importantly — string values and the
generated `.g.xlf`.

**Proposed resolution.** Confirm at the local compile (open the files in VS Code and check the
encoding indicator; inspect `.g.xlf` after the first build). If anything is mangled, re-save all 14
files as UTF-8 with BOM. Independently, the three placeholder labels are due for replacement at VT-3
anyway — replacing their em dashes with ASCII hyphens at the same time removes the only *functional*
exposure.

**Changes a document?** No.

---

### CR-15 · **MINOR** · Compile risk (AL member shapes) · *reviewer finding, confidence: medium*

**Where:** `src/Logic/ocpfBbbProfileReader.Codeunit.al:70, 71, 73, 84, 86, 91`.

**What.** Several HTTP members are written as method calls where AL may define them as properties:
`HttpResponseMessage.HttpStatusCode()`, `.IsSuccessStatusCode()`, `.Content()`. Also unconfirmed:
`HttpClient.Timeout` accepting an `Integer` millisecond literal, and the
`DefaultRequestHeaders.Add('User-Agent', …)` shape. All are already collected under **TDD §16 row
14**; this finding exists so they are re-checked as *invocation shapes*, not only as "does the type
exist" — the DEFINE-016 lesson was precisely that "which construct is legal on which object" is a
distinct class of fact from "does the object exist".

**Proposed resolution.** Resolve with VT-1 at the local compile. No speculative edits.

**Changes a document?** No — §16 row 14 already owns it.

---

### CR-16 · **MINOR** · Redundant code · *reviewer finding, confidence: medium*

**Where:** `src/Logic/ocpfBbbProfileReader.Codeunit.al:3`.

**What.** `using System.Utilities;` is carried with its own inline caveat that `HttpClient` and
`HttpResponseMessage` may be platform types needing no `using` at all. If nothing in the file
resolves through that namespace, it is a redundant directive — noise in the one file whose whole
purpose is to be swapped out cleanly (DR-3).

**Proposed resolution.** Remove it if the compile shows it unused; keep it if a member genuinely
resolves through it. Zero risk either way — the compiler is authoritative.

**Changes a document?** TDD §8's row for 50607 (which already says "possibly"). Mechanical.

---

### CR-17 · **MINOR** · **CONFLICT: Standards Guide vs BCQuality — surfaced, not resolved**

**References (BCQuality side):** `microsoft/knowledge/style/caption-required-on-page-fields.md`,
`microsoft/knowledge/ui/bound-page-field-inherits-source-field-tooltip.md`

**Where:** `src/UI/ocpfBbbCustomerCardExt.PageExt.al` (6 fields × 2 properties),
`src/UI/ocpfBbbFetchLogList.Page.al` (7 fields × 2 properties).

**What.** Every bound page field on the two client-facing pages repeats, verbatim, the `Caption` and
`ToolTip` already defined on its source table field — some of them 300-character sentences, stored
three times across the codebase. BCQuality is direct about this: *"The opposite review defect is
flagging a bound field solely because it omits a page-level `Caption`, or inserting a copy of the
table field's caption… That adds redundant text and prevents subsequent table-caption changes from
flowing through to the page."* The tooltip article says the same for `ToolTip`, and confirms
inheritance is available from runtime 13.0 — this project targets 16.0, so inheritance would work.

**But the OCPF Standards Guide §1.4 is unconditional:** *"Every field on every page must have all
three [`Caption`, `ToolTip`, `ApplicationArea`]. No exceptions."* And `docs/PreflightChecklist.md`
encodes it as a per-batch gate.

**Resolution: no change. The Standards Guide wins**, per the runbook's own precedence rule (*"The
Standards Guide wins on any conflict; surface a conflict to the human rather than silently picking a
side"*). **This is that surfacing.** The code as written is correct under the rule this project is
built to.

**For AJ Ansari's awareness only** — the concrete cost BCQuality is warning about is real and will
land on this project: a wording change to any of the six BBB field tooltips now has to be made in
**three** files (`ocpfBbbCustomerExt.TableExt.al`, `ocpfBbbCustomerCardExt.PageExt.al`,
`ocpfBbbCustomerRatings.Page.al`) or the surfaces silently disagree. **Two of those three copies
already exist for fields whose tooltip text TDD §7.4 says will change** once OQ-3 is answered
(the complaint-count window). Worth knowing before VT-3, not after.

**Note:** the caption article explicitly excludes API pages (*"API pages are not human-facing UI; do
not apply this UI-label guidance to their API contract names"*), so 50613/50614 are unaffected by
this conflict in either direction.

**Changes a document?** Only if AJ wants the Standards Guide revisited — which is a framework-level
change, not a project one.

---

### CR-18 · **MINOR** · Error handling / usability · *knowledge-backed, confidence: medium*

**Reference:** `microsoft/knowledge/error-handling/prefer-errorinfo-for-actionable-errors.md`
(`bc-version: [23..]` — applies)

**Where:** `src/Logic/ocpfBbbRatingMgt.Codeunit.al:118–127`, `203–205`.

**What.** Two preconditions fail with a plain `Error` whose message names a specific correction on a
specific record — the article's exact detection signal (*"an `Error` call in a validation or posting
path whose message names a specific correct value or a specific related page, with no surrounding
`ErrorInfo`, `AddAction`, or `AddNavigationAction`"*):

- `NoProfileUrlErr` — *"Enter a BBB profile URL for customer %1…"*
- `CountryBlankErr` — *"…enter the customer's country/region before refreshing BBB data."*

Both could carry a **Show-it** navigation action back to the Customer Card, which is a direct
improvement to FRD NFR-9's *"what happened, why, and what to do next"*.

**Steelman (why Minor, not Major).** The refresh action is *already* raised from the Customer Card,
so the user is standing on the page the navigation action would take them to. The genuine gain is
for the API/OData caller and for any future entry point — real, but not urgent.

**Proposed resolution.** Optional enhancement. If accepted, it changes TDD §10.2's label inventory
(the labels become `ErrorInfo` constructions) — ask with the other document-touching items.

---

### CR-19 · **MINOR** · Privacy · *knowledge-backed, confidence: medium* · **needs a decision, not a patch**

**References:** `microsoft/knowledge/privacy/privacy-notice-consent-for-external-data-transfer.md`,
`microsoft/knowledge/privacy/register-integration-in-privacy-notice-registrations.md`

**Where:** `src/Logic/ocpfBbbProfileReader.Codeunit.al` (the outbound call path), and the absence of
any registration object in `src/`.

**What.** BC ships `Codeunit "Privacy Notice"` precisely for a custom integration that sends data to
an external service: register a notice (`CreatePrivacyNotice` / `OnRegisterPrivacyNotices`), then
gate the transfer with `ConfirmPrivacyNoticeApproval(<custom id>)` **outside a write transaction**,
or `GetPrivacyNoticeApprovalState` where no UI may appear. This extension registers nothing and
checks nothing before contacting a third party.

**Steelman — and it is a strong one.** FRD NFR-12 states the data is *"publicly published
information about a business, not personal data"*, NFR-13 says no credentials are stored, and DR-9
forbids any configuration surface in v1. The outbound payload is a URL a staff member typed. A
reasonable reading is that a privacy notice is not required here.

**Why it is still a finding.** What leaves the tenant is not only a URL — it is *the fact that this
tenant is looking up this specific business*, sent to a third party with no agreement, under an
integration the FRD itself classifies as ToS-violating (§7.1). That is a judgement call about
tenant-visible consent, and this project's discipline is that a judgement call is **recorded**, not
defaulted.

**Proposed resolution — AJ Ansari's decision:**
- **(a)** Register and check a privacy notice. Costs a new install/registration object (an ID from
  M2's reserve, 50609, or the tail block) and brushes against DR-9.
- **(b)** Record an explicit decision in FRD §7.4 that no privacy notice is required, with the
  NFR-12 reasoning above — so the next reviewer finds a decision, not a gap. **Recommended if AJ
  agrees with the steelman**, since it costs nothing and closes the question permanently.

**Changes a document?** **Yes** in both options — FRD §7.4 (and §9 if (a)). Ask separately.

---

### CR-20 · **MINOR** · Security · *knowledge-backed, confidence: medium*

**Reference:** `microsoft/knowledge/security/validate-unauthenticated-response-before-use.md`

**Where:** `src/Logic/ocpfBbbProfileReader.Codeunit.al:91–113`.

**What.** The call to bbb.org is unauthenticated in both directions (no `Authorization` header, no
OAuth, no client certificate), so the response is, in the article's terms, *"fully
attacker-influenceable"*. It prescribes three checks before the payload reaches business logic:

| Check | Status in this code |
|---|---|
| **Response size** — reject when the buffered body exceeds a cap sized to the expected payload | **Missing.** `ReadAs(ResponseBody)` takes whatever arrived, into a `Text`. |
| **Schema compliance** — require the specific values in the expected shape | **Partially present.** All three values must parse or the whole call fails (TDD §7.1's "partial success is failure"). This is the strongest part of the current design. |
| **Content integrity** — require the response to echo the identifiers queried | **Missing.** Nothing ties the returned page to the business it was supposed to be about. |

The integrity gap maps directly onto a risk the FRD already names: DR-5's *"attaching the wrong
company's rating to a customer is a serious data-integrity failure."* Today the only defense
against that is the accuracy of the URL a human typed.

**Note the article's own false-positive guard, which applies here:** do **not** demand a streaming
or bounded read that aborts mid-download, and do not demand a DNS-rebinding check — the platform
buffers the whole body before AL sees it. An in-AL size check after buffering is the correct and
sufficient shape.

**Proposed resolution.** (1) Add a size cap in `TryFetchAndParse` before parsing, failing with
`ParseFailedReasonTxt`. (2) When VT-3 pins the real parse markers, add an echoed-identifier check at
the same time — whatever the page carries that identifies the business — so a redirect or a wrong
URL fails closed instead of writing a plausible-looking wrong grade. VT-3 is the natural moment;
doing it later means re-opening the parser.

**Changes a document?** TDD §7.3's parse contract gains two rows. Bundle with the VT-3 work.

---

### CR-21 · **INFO** · Documentation accuracy · *knowledge-backed, confidence: high*

**Reference:** `microsoft/knowledge/web-services/api-enum-values-are-a-contract-by-name-not-ordinal.md`

**Where:** TDD §6.1's API serialization note and OD-2's resolution; consumed by `Documentation.md`
at Step 11.

**What.** TDD §6.1 states that *"OData serializes an enum by its **value name**, so
`$select=ocpfBbbGrade` returns `"APlus"`, not `"A+"`"*, and OD-2 accepted "no display-grade field"
on that basis, with `Documentation.md` to publish the mapping table instead. The cited article makes
this **schema-version-dependent**: under OData schema **2.0** the member *name* is serialized; under
schema **1.0** the same field is `Edm.String` carrying the **en-US caption**. Custom APIs defaulted
to 1.0 through BC 23 and to 2.0 from BC 24 — so on BC 27 the TDD is right *by default* — **but a
caller can still pin `?$schemaversion=1.0` and will then receive `A+`.**

**Why this is worth recording rather than ignoring.** The whole point of OD-2 was that a Power BI
author maps the values once. A report built against a pinned 1.0 endpoint and a report built against
the default would need *different* mappings. `Documentation.md` must say which schema version its
mapping table is for.

**Proposed resolution.** One sentence in `Documentation.md` at Step 11 and a note on TDD §6.1. No
code change. Also worth carrying forward: under schema 2.0 the enum **member names are the API
contract** — so `APlus`, `AMinus` … can never be renamed after v1 ships, only appended to. That is a
useful constraint to have written down before someone "tidies" the enum.

---

### CR-22 · **INFO** · Code quality / `$metadata` wording · *reviewer finding, confidence: medium*

**Where:** `src/API/ocpfBbbCustomerRatings.Page.al:57`.

**What.** `ToolTip = 'Specifies the name of the customer, enough to identify the customer.'` — the
trailing clause is FRD §6.3's *requirement* phrasing ("enough to identify the customer") copied into
user-facing text. It reads as a fragment and it ships into `$metadata`, where Standards §2.6 says
ToolTips are the schema documentation an API consumer reads.

**Proposed resolution.** Reword to something like *"Specifies the customer's name, as shown on the
customer record."* Cosmetic; bulk approval.

---

### CR-23 · **MINOR** · Documentation accuracy / consistency · *reviewer finding, confidence: high*

**Where:** `src/Security/OCPFBBBBBBRIEDIT.PermissionSet.al:18–22`; `docs/TDD.md` §9.2;
`docs/ObjectRegister.md` §2 (row 50617).

**What.** The same factual claim appears in three places and is contradicted by the code:

> *"`M` is deliberately NOT granted: **no code path in this extension ever modifies a log row**…"*

`ocpfBbbCustomerSubscribers.OnAfterRenameCustomer` calls `FetchLog.Modify()`. A code path exists.
The claim survives today only because the codeunit's own `Permissions` property is expected to
supply `M` — which is itself an unverified assumption (TDD §16 rows 20–21). If that assumption is
wrong, a customer rename fails with a permission error for **every** user.

**Root cause.** F-M-1's reasoning (ChangeLog DEFINE-014) was written about the *API and list page*
surfaces and did not account for the rename subscriber, then was copied verbatim into two more
artifacts. This is the "fix the rule, not the instance" case in miniature: three copies, one wrong
sentence, one source.

**Proposed resolution.** Correct all three at once, with wording that survives CR-04's outcome —
e.g. *"no user-facing surface can modify a log row; the only code path that does is the rename
subscriber, which runs under the codeunit's own `Permissions` grant."* If CR-04 retires the rename
subscriber, the original sentence becomes true and can stay as written — **so resolve CR-04 first
and correct this once.**

**Changes a document?** Yes — TDD §9.2, `ObjectRegister.md`, and a code comment. Bundle with CR-04.

---

### CR-24 · **MINOR** · Testability / architecture · *knowledge-backed, confidence: medium*

**Reference:** `microsoft/knowledge/interfaces/assign-codeunit-to-interface-for-testability.md`

**Where:** `src/Logic/ocpfBbbRatingMgt.Codeunit.al:26–27`, `58`.

**What.** **First, the good news, because it is the more important half:** the DR-3 boundary is
**intact and verified**. `ocpfBbbRatingMgt` references `Codeunit "ocpfBbbProfileReader"` in exactly
two places — the local `var` declaration and the single assignment `Provider := ProfileReader;` on
line 58 — and nowhere else in the file. Every call goes through `Provider.TryGetRating(...)`. That is
what TDD §7.1 promised, built as promised. The interface file itself references no BC namespace at
all, which is the corroborating evidence the TDD predicted.

**The finding is narrower:** because the binding happens *inside* `RefreshRating`, there is **no
seam to inject a different provider**. The cited article's detection signal is *"a `var` of type
`Codeunit "<concrete impl>"` used for a collaborator that has — or could have — an interface,
especially one that performs I/O, posting, or external calls."* An AL test codeunit cannot exercise
`RefreshRating`'s DR-1/DR-2 logic — the single most safety-critical logic in this extension —
without making a real HTTPS call to bbb.org. Step 11 asks whether Automated Test Scripts are wanted;
if AJ says yes, this is the thing that blocks them.

**Proposed resolution — additive, preserves DR-3 exactly.** Add an optional setter used only by
tests:

```al
procedure SetProvider(NewProvider: Interface "ocpfBbbRatingProvider")   // test seam
...
if not ProviderSet then
    Provider := ProfileReader;    // the single default binding point (DR-3, TDD §7.1)
```

The production default binding stays exactly where TDD §7.1 says it is; the swap procedure in §7.1
is unchanged; and DR-1's keep-last-known-value branch becomes testable without a network.

**Changes a document?** Yes — TDD §6.7's public surface and §7.1. Ask separately (it touches the
DR-3 mechanism, even though it does not weaken it).

---

## 4. "Marked for obsoletion" — **DEFERRED, NOT CLEARED**

**This check was not performed and this review does not claim otherwise.**

Standards §3.2–§3.3 require that no field, table, procedure, or event with
`ObsoleteState = Pending` or `Removed` is referenced, and that no obsolete event is subscribed to.
Confirming that requires the BC symbol files, which this session does not have (ChangeLog
**DEFINE-004**; FRD NFR-21; TDD §0.3).

**What must still be verified locally — this is TDD §16's worksheet, not a new list:**

| Reference in code | §16 row |
|---|---|
| `Customer` table, `"No."`, `Name`, `"Country/Region Code"` | 1, 4, 5, 6 |
| `Country/Region` table and its `"ISO Code"` field | 7, 8 |
| `OnAfterDeleteEvent` / `OnAfterRenameEvent` on `Database::Customer` — including that neither is obsolete and that the parameter lists match | 10, 11 |
| Every standard field exposed on API page 50613 is `ObsoleteState = Active` | 16 |
| `HttpClient` / `HttpResponseMessage` members | 14 |

`docs/PreflightChecklist.md` already records this honestly (*"satisfied here by 'correctly flagged
as unverified,' not by 'confirmed correct'"*). **Step 09's exit gate cannot be met on this dimension
until VT-1 is worked.**

---

## 5. Standards Part 7 — full Anti-Patterns table, row by row

All 28 rows walked against all 14 files, not only the ones the TDD pre-flagged.

| # | Anti-pattern | Result |
|---|---|---|
| 1 | `Editable = false` on editable pages | **Clean.** 50613 is editable (`DelayedInsert = true`); 50614 is the read-only one. |
| 2 | Omitting `DelayedInsert` on editable pages | **Clean.** 50613 sets it. |
| 3 | Both `Editable = false` **and** `DelayedInsert` | **Clean.** Exactly one per API page, as TDD §17 claims. |
| 4 | Quoting single-word enum values in `const()` | **N/A.** No `const()` anywhere. |
| 5 | Not quoting multi-word enum values in `const()` | **N/A.** Same. |
| 6 | `%` in field identifiers | **Clean.** |
| 7 | Reserved keywords as identifiers | **Clean.** `name` deliberately avoided in favour of `displayName`; `Outcome`, `number`, `outcome` checked — none is an AL/layout keyword. |
| 8 | Identifier > 30 characters | **Clean.** Longest is `ocpfBbbComplaintCount` (21). |
| 9 | Permission sets named from the prefix alone | **Clean.** `OCPFBBB BBBRI, VIEW` / `, EDIT`, 19 chars, App Code `BBBRI`. |
| 10 | Estimated / guessed table numbers | **Clean in form, deferred in substance.** Every standard reference carries an inline `UNVERIFIED` marker pointing at a §16 row — which is the correct handling for this environment, not a pass. |
| 11 | Including `ObsoleteState = Pending` fields | **Deferred — see §4.** |
| 12 | Fields outside the Localization range | **Clean as designed.** Only `"No."`, `Name`, `"Country/Region Code"` are exposed, all core W1 fields; TDD §7.5 records that nothing in the 10,000–89,999 band is touched. Field IDs still need symbol confirmation (§16 row 16). |
| 13 | Missing `ApplicationArea = All` | **Clean on every page field** across 50610, 50611, 50613, 50614 — and correctly **absent** from table/tableextension fields (ChangeLog DEFINE-016's fix is intact; no regression). |
| 14 | Missing `ODataKeyFields = SystemId` | **Clean.** Both API pages. |
| 15 | Sub-namespaces within one extension | **Clean.** One flat namespace, 14/14 files. |
| 16 | Fixing a file's error without fixing the root cause | **Observed being done correctly** — DEFINE-016 fixed the checklist and the TDD, not just the files. **This review adds two more root-cause items: CR-03 (checklist wording) and CR-23 (one wrong sentence in three artifacts).** |
| 17 | A TDD that depends on outside context | **Clean.** Not re-litigated — Step 04 settled it. |
| 18 | Legacy price tables | **N/A.** |
| 19 | `EntityName` ≠ `EntitySetName` for singletons | **N/A.** No singleton. |
| 20 | Generic ToolTips with no information value | **Clean, and notably good.** Every ToolTip is a full sentence written for `$metadata`, including the grade-vs-accreditation distinction NFR-10 specifically demanded. One wording nit: CR-22. |
| 21 | Hardcoding publisher / prefix / namespace / version in AL | **Clean.** Every value traces to `docs/ProjectParameters.md`; `APIPublisher = 'onlyCopilotFans'`, `APIGroup = 'ocpfBbbRatings'`, `APIVersion = 'v1.0'` all match §1. |
| 22 | Reaching for a `FlowField` where a stored field is wanted | **Clean.** No `FlowField` in the extension; the six Customer fields are stored and system-written by design, which is exactly what this row prescribes. |
| 23 | `CaptionML` / `ToolTipML` / other ML / `TextConst` | **Clean — verified by search.** §6. |
| 24 | Hard-coded text in `Error` / `Message` / `Confirm` / notifications | **Clean.** Every one of the 18 user-facing strings is a `Label`; zero string literals in `Error()` or `Message()`. Verified call-site by call-site. |
| 25 | A placeholder label with no `Comment` | **Clean.** All six placeholder-bearing labels carry a `Comment` naming each `%n`; the seven no-placeholder labels correctly have none. |
| 26 | `OptionCaption` member-count mismatch | **N/A.** Enums used, not options. |
| 27 | Editing `.g.xlf` by hand | **N/A.** No `.xlf` shipped; `*.g.xlf` is gitignored. |
| 28 | Choosing a BC term from model memory / regional wording in source | **Clean.** §7. |

**Plus the three rows that only apply to translated projects** (shipping units in
`needs-translation`, testing translations with incremental build, locking API captions without a
recorded decision): the first two are **N/A**; the third is **satisfied** — both API pages carry
`EntityCaption`/`EntitySetCaption` matching TDD §11's per-object decision, with AJ Ansari named as
the decider in both files' comments.

---

## 6. Deprecated multilanguage syntax — clean

Searched all 14 files for `CaptionML`, `ToolTipML`, `OptionCaptionML`, `InstructionalTextML`,
`AboutTitleML`, `AboutTextML`, `PromotedActionCategoriesML`, `RequestFilterHeadingML`, and
`TextConst`. **Zero occurrences.**

**Caveat this review must state:** Step 09's mandate says a clean 0/0 compile with `TranslationFile`
enabled already proves this mechanically via `AL0424`. `app.json` does carry
`"features": ["NoImplicitWith", "TranslationFile"]` — but **there is no 0/0 compile yet**, so this
result rests on a text search, not on the compiler. Re-confirm at Step 07.

---

## 7. Translations — still correctly N/A, and no regional wording leaked

Parameter §1.9 / FRD DR-10 set this project to English-only, US wording, no translation files.
**Confirmed still true against the generated code:**

- No `Translations/*.xlf` shipped (only `.gitkeep`); `*.g.xlf` gitignored. Correct.
- `TranslationFile` remains enabled in `app.json` — correct per Standards §8.2, and it is what will
  enforce §6 mechanically once the compile runs.
- **Regional-wording check (the one thing that could have leaked):** every user-facing string was
  read for a standard BC concept whose wording differs across markets — `Tax`/`VAT`/`GST`,
  `State`/`County`, `Credit Memo`/`CR/Adj Note`, `Zip Code`/`Post Code`. **None appears anywhere in
  the extension.** The nearest thing is `"Country/Region Code"`, which is Microsoft's own W1 term,
  used verbatim. The BBB domain vocabulary (grade, accreditation, complaints) is a proper noun's
  vocabulary and names no standard BC concept — TDD §13.3 predicted this and it holds.
- Label discipline that will matter if fr-CA is ever added (v2): all 18 labels are proper `Label`
  declarations at object scope with correct AA0074 suffixes (`Err`/`Msg`/`Txt`/`Tok`), and the two
  technical tokens (`HttpsPrefixTok`, `UserAgentTok`) plus the three placeholder tokens are
  `Locked = true`. Nothing would need restructuring.

**One forward-looking note, not a finding:** CR-14's non-ASCII em dashes inside three `Label` values
would land in the `.g.xlf` if this project ever gains a target language. Replacing them at VT-3
closes that too.

---

## 8. Best practices — metadata, mutability, permissions, `tabledata`

**Verified clean:**

- **Mutability per Standards §2.2 is correct on both API pages**, including the deliberate-looking
  contradiction on 50613 (`DelayedInsert = true` alongside `InsertAllowed = false`), which TDD §6.11
  documents and Step 04 already approved. Master data → editable; audit table → read-only. Not
  re-litigated.
- **`tabledata` coverage (`PTE0004`)**: `ocpfBbbFetchLog` is the only table this extension owns, and
  it is granted in **both** sets (`R` in VIEW, `RID` in EDIT). `ocpfBbbCustomerExt` is a table
  *extension*, correctly relying on the consumer's base Customer permission. **Re-derived by hand,
  since there is no compile to lean on.**
- **Permission-set composition** is correct per
  `microsoft/knowledge/security/compose-permission-sets-with-included-sets.md` — EDIT includes VIEW
  rather than restating it, both are `Assignable = true`, and neither uses a wildcard grant.
- **`DataClassification`** is set on **every** field of the table extension — which
  `microsoft/knowledge/privacy/data-classification-required-on-pii-fields.md` confirms is mandatory
  there specifically, because *"a `tableextension` has no table-level value to inherit"*. The log
  table sets it at both object and field level. No `ToBeClassified` anywhere. **Clean.**
- **`Modify(true)` on the customer**, not `Modify(false)` — correct per DR-13, as the TDD argued.
- **HTTP is called before the first database write** — checked explicitly against
  `microsoft/knowledge/performance/httpclient-inside-write-transaction-holds-locks.md`, whose
  detection signal is *"any `HttpClient` use after a write on the same execution path."* There is
  none: `RefreshRating` fetches, then writes. **This is the single most consequential thing the
  design got right, and it is right in the code, not just in the TDD.**
- **`Message`, never `Error`, on the failure path** (`ocpfBbbRatingMgt.Codeunit.al:87–90`) — DR-2's
  stamp and log row survive. Checked against
  `microsoft/knowledge/performance/avoid-user-prompts-inside-transactions.md`, whose scope is
  `Confirm`/`StrMenu`/modal pages; a `Message` is not in that set, so no finding.
- **`[TryFunction]` return value is consumed** (`if not TryFetchAndParse(...) then`) — the exact
  requirement in
  `microsoft/knowledge/error-handling/ignored-tryfunction-return-disables-try-semantics.md`. A bare
  call would have silently disabled try semantics. **Clean.**
- **The interface contract's "never raise an `Error`" rule is honored** — `ocpfBbbProfileReader`
  contains no `Error()` call on any path.
- **Descending default sort on the log list page** — matches
  `microsoft/knowledge/ui/default-descending-sort-on-historical-pages.md` exactly.
- **Event publisher shape** — `[IntegrationEvent(false, false)]`, `local procedure`, empty body,
  typed `Record` parameters, `OnAfter` naming. Consistent with Standards Part 10 and with BCQuality's
  events corpus; no finding.

**Findings in this dimension:** CR-01, CR-06, CR-09, CR-10, CR-13, CR-24.

---

## 9. BCQuality knowledge-backed review — **executed**

**Snapshot:** `/home/user/claudeCodeMobileDevTest.bcquality/` · source `github.com/microsoft/BCQuality`
· ref `main` · commit `8ff2326b61ae667d9ba44471fcb3ba09364bd9b9` · fetched 2026-09-16T23:34:57Z.
Read in full before use: `skills/entry.md`, `docs/agent-consumption.md`, `skills/do.md` (output
contract and *Agent findings* rules), `microsoft/skills/review/al-code-review.md`.

### 9.1 Preparation step — index

Entry's Preparation step calls for `knowledge-index.json` to be regenerated via
`pwsh ./tools/Build-KnowledgeIndex.ps1`. **`knowledge-index.json` is absent and `pwsh` is not
available in this session**, so the index could not be built. Entry's own fallback was used:
*"When no index is present, skills fall back to path-based discovery (collect by domain folder), so
review still works."* Discovery was done by walking `*/knowledge/*/` directly — **307 articles across
19 domains** — reading frontmatter (`title`, `keywords`) for candidate selection and then opening
each worklisted article **in full** before citing it, as DO's reference-integrity gate requires.
Entry is explicit that index preparation *"MUST NOT change Entry's output"*, so this does not affect
the dispatch below.

### 9.2 Dispatch record (Entry output)

```json
{
  "skill": { "id": "entry", "version": 1 },
  "outcome": "routed",
  "outcome-reason": "Goal 'BC AL code quality review of a SaaS PTE' is a broad AL source review; the al-code-review super-skill covers it and supersedes its 17 declared sub-skills.",
  "dispatch": [
    {
      "skill": { "id": "al-code-review", "version": 1, "path": "microsoft/skills/review/al-code-review.md" },
      "rationale": "kind=action-skill; inputs-available [folder-path, file-path] intersects its declared inputs; technologies [al] and countries [w1] match; broad-goal match beats every narrower leaf.",
      "inputs": ["folder-path", "file-path"]
    }
  ],
  "skipped": [
    { "skill": { "id": "al-performance-review",      "path": "microsoft/skills/review/al-performance-review.md" },      "reason": "superseded-by-super-skill", "superseded-by": { "id": "al-code-review", "path": "microsoft/skills/review/al-code-review.md", "version": 1 } },
    { "skill": { "id": "al-security-review",         "path": "microsoft/skills/review/al-security-review.md" },         "reason": "superseded-by-super-skill", "superseded-by": { "id": "al-code-review", "path": "microsoft/skills/review/al-code-review.md", "version": 1 } },
    { "skill": { "id": "al-privacy-review",          "path": "microsoft/skills/review/al-privacy-review.md" },          "reason": "superseded-by-super-skill", "superseded-by": { "id": "al-code-review", "path": "microsoft/skills/review/al-code-review.md", "version": 1 } },
    { "skill": { "id": "al-upgrade-review",          "path": "microsoft/skills/review/al-upgrade-review.md" },          "reason": "superseded-by-super-skill", "superseded-by": { "id": "al-code-review", "path": "microsoft/skills/review/al-code-review.md", "version": 1 } },
    { "skill": { "id": "al-style-review",            "path": "microsoft/skills/review/al-style-review.md" },            "reason": "superseded-by-super-skill", "superseded-by": { "id": "al-code-review", "path": "microsoft/skills/review/al-code-review.md", "version": 1 } },
    { "skill": { "id": "al-ui-review",               "path": "microsoft/skills/review/al-ui-review.md" },               "reason": "superseded-by-super-skill", "superseded-by": { "id": "al-code-review", "path": "microsoft/skills/review/al-code-review.md", "version": 1 } },
    { "skill": { "id": "al-error-handling-review",   "path": "microsoft/skills/review/al-error-handling-review.md" },   "reason": "superseded-by-super-skill", "superseded-by": { "id": "al-code-review", "path": "microsoft/skills/review/al-code-review.md", "version": 1 } },
    { "skill": { "id": "al-events-review",           "path": "microsoft/skills/review/al-events-review.md" },           "reason": "superseded-by-super-skill", "superseded-by": { "id": "al-code-review", "path": "microsoft/skills/review/al-code-review.md", "version": 1 } },
    { "skill": { "id": "al-interfaces-review",       "path": "microsoft/skills/review/al-interfaces-review.md" },       "reason": "superseded-by-super-skill", "superseded-by": { "id": "al-code-review", "path": "microsoft/skills/review/al-code-review.md", "version": 1 } },
    { "skill": { "id": "al-breaking-changes-review", "path": "microsoft/skills/review/al-breaking-changes-review.md" }, "reason": "superseded-by-super-skill", "superseded-by": { "id": "al-code-review", "path": "microsoft/skills/review/al-code-review.md", "version": 1 } },
    { "skill": { "id": "al-web-services-review",     "path": "microsoft/skills/review/al-web-services-review.md" },     "reason": "superseded-by-super-skill", "superseded-by": { "id": "al-code-review", "path": "microsoft/skills/review/al-code-review.md", "version": 1 } },
    { "skill": { "id": "al-testing-review",          "path": "microsoft/skills/review/al-testing-review.md" },          "reason": "superseded-by-super-skill", "superseded-by": { "id": "al-code-review", "path": "microsoft/skills/review/al-code-review.md", "version": 1 } },
    { "skill": { "id": "al-data-modeling-review",    "path": "microsoft/skills/review/al-data-modeling-review.md" },    "reason": "superseded-by-super-skill", "superseded-by": { "id": "al-code-review", "path": "microsoft/skills/review/al-code-review.md", "version": 1 } },
    { "skill": { "id": "al-query-review",            "path": "microsoft/skills/review/al-query-review.md" },            "reason": "superseded-by-super-skill", "superseded-by": { "id": "al-code-review", "path": "microsoft/skills/review/al-code-review.md", "version": 1 } },
    { "skill": { "id": "al-reporting-review",        "path": "microsoft/skills/review/al-reporting-review.md" },        "reason": "superseded-by-super-skill", "superseded-by": { "id": "al-code-review", "path": "microsoft/skills/review/al-code-review.md", "version": 1 } },
    { "skill": { "id": "al-appsource-review",        "path": "microsoft/skills/review/al-appsource-review.md" },        "reason": "superseded-by-super-skill", "superseded-by": { "id": "al-code-review", "path": "microsoft/skills/review/al-code-review.md", "version": 1 } },
    { "skill": { "id": "al-telemetry-review",        "path": "microsoft/skills/review/al-telemetry-review.md" },        "reason": "superseded-by-super-skill", "superseded-by": { "id": "al-code-review", "path": "microsoft/skills/review/al-code-review.md", "version": 1 } },
    { "skill": { "id": "al-agents-review",           "path": "community/skills/review/al-agents-review.md" },           "reason": "goal-mismatch" }
  ]
}
```

`al-agents-review` was dropped on goal match: it covers the BC **Agent** feature (agent metadata
providers, `IAgentFactory`, agent instructions). This extension ships no agent object of any kind.

### 9.3 Execution note — honest about how it ran

`al-code-review`'s Action step prescribes **isolated leaf invocations** (a fresh model call per
sub-skill, private artifact directories). This session has no mechanism to spawn isolated child
contexts for 17 leaves. The leaves were therefore executed **sequentially in one context**, one
domain corpus at a time, with each leaf's worklist and evaluation kept separate and each worklisted
article opened in full before citing — preserving the "do not collapse multiple sub-skills into one
shared reasoning step" requirement as far as this host allows. **This is a deviation from the
skill's execution discipline and is recorded here rather than glossed over.** Its practical risk is
the one the skill names — leaves under-reporting relative to isolated runs — so treat the
knowledge-backed findings below as a **floor, not a ceiling**, and consider re-running BCQuality
with an isolating host after the local compile lands.

### 9.4 Result summary

**Outcome: `completed`.** 10 knowledge-backed findings from 8 leaf domains, plus 4 reviewer/agent
findings validated against the loaded corpus and emitted with `references: []`.

| Leaf | Outcome | Findings |
|---|---|---|
| `al-security-review` | completed | **CR-05** (validate-user-configurable-urls), **CR-20** (validate-unauthenticated-response-before-use), **CR-09** (supporting: indirect-permissions-for-elevated-access) |
| `al-web-services-review` | completed | **CR-03** (disable-write-operations-on-read-only-api-pages), **CR-21** (api-enum-values-are-a-contract-by-name-not-ordinal) |
| `al-data-modeling-review` | completed | **CR-04** (validate-table-relation-false-suppresses-rename-propagation + owning-table-must-delete-dependents-in-ondelete), **CR-09** (primary) |
| `al-ui-review` | completed | **CR-08** (prefer-actionref-syntax-for-promoted-actions), **CR-17** (bound-page-field-inherits-source-field-tooltip — raised as a Standards conflict) |
| `al-performance-review` | completed | **CR-11** (dataaccessintent-readonly-on-analytical-objects), **CR-04** (supporting: prefer-modifyall-over-per-row-modify), **CR-07** (use-tryfunction-for-error-catching-not-rollback) |
| `al-style-review` | completed | **CR-17** (caption-required-on-page-fields — primary for the caption half) |
| `al-error-handling-review` | completed | **CR-18** (prefer-errorinfo-for-actionable-errors) |
| `al-privacy-review` | completed | **CR-19** (privacy-notice-consent-for-external-data-transfer + register-integration-in-privacy-notice-registrations) |
| `al-interfaces-review` | completed | **CR-24** (assign-codeunit-to-interface-for-testability) |
| `al-events-review` | no findings | Publisher and both subscribers conform to the events corpus. |
| `al-upgrade-review` | not-applicable | v1, unreleased baseline; `unreleased-schema-change-needs-no-upgrade-path.md` **positively supports** TDD §12's "no upgrade code" decision. |
| `al-breaking-changes-review` | not-applicable | No released baseline to break. |
| `al-testing-review` | not-applicable | No test codeunits exist (see CR-24 and Step 11's automated-tests question). |
| `al-telemetry-review` | not-applicable | The extension emits no telemetry. Not a violation of any article; see the observation in §11. |
| `al-query-review` · `al-reporting-review` · `al-appsource-review` | not-applicable | No query objects, no report objects; Deployment Target is SaaS PTE, not AppSource. |

**Suppressed / false-positive guards that *prevented* findings** — worth recording, because each is
a finding this review would otherwise have raised wrongly:

| Candidate the reviewer considered | Knowledge file that suppressed it |
|---|---|
| "`xRec` is unreliable outside a page — the rename subscriber is broken" | `data-modeling/xrec-is-a-before-image-only-in-some-triggers.md` — `xRec` **is** a genuine before-image on the rename path, from code as well. Usage is correct. |
| "Bound page fields are missing nothing, but the table-field `ToolTip` looks like an invalid property (the DEFINE-016 class)" | `ui/bound-page-field-inherits-source-field-tooltip.md` — `ToolTip` on **table fields** is supported from runtime 13.0 (BC 24). This project targets 16.0, so it is valid. **Direct reassurance on the exact property class that caused DEFINE-016.** |
| "`Message` after `Modify`/`Insert` holds a lock while waiting for the user" | `performance/avoid-user-prompts-inside-transactions.md` — scoped to `Confirm`/`StrMenu`/modal pages, not `Message`. |
| "Labels should be at object scope" (they already are) | `style/labels-declared-at-object-scope.md` — procedure-local labels are valid too; not a finding either way. |
| "Demand a bounded/streaming read to cap the response" | `security/validate-unauthenticated-response-before-use.md` — explicitly names that as a **false positive**; an in-AL size check after buffering is the correct ask (which is what CR-20 asks for). |

### 9.5 OCPF Patterns library — checked, no match

Per ALL ALONG → OCPF BC AL Patterns Library, `patterns/` was checked **before** diagnosing anything.
Two patterns are present:

- `Pattern-Init-Does-Not-Clear-Primary-Key.md` — **no match.** This extension inserts exactly one
  `ocpfBbbFetchLog` row per attempt from a freshly-declared local variable in `WriteLogEntry`; no
  record variable is reused across inserts anywhere in the codebase.
- `Pattern-SubPageLink-FilterGroup4.md` — **no match.** No `SubPageLink`, no `DataItemLink`, no
  `GetFilter` call anywhere.

**Candidate for a new pattern (flagged, not added — the library is AJ Ansari's to extend):**
**CR-10**, the missing `IsTemporary()` guard in a subscriber that cascades from a standard table.
It generalises beyond this project to every extension that owns a child table hanging off a standard
master table, the failure is silent data loss, and the fix is one line. That is the profile of the
two patterns already in the library.

---

## 10. AL Guidelines best-practice pass — **SKIPPED**

Step 09 calls for a pass against AL Guidelines' current *Best Practices* and *Vibe Coding Rules*.
**This session has no live internet access to alguidelines.dev**, so the pass was not performed and
**no citation to AL Guidelines appears anywhere in this document.** Nothing was answered from memory
of it (ALL ALONG → Reference Sources: *"If the agent has no web access, say so"*).

**To complete this dimension**, someone with web access should read the built code against those two
pages. Given how much of the Standards Guide already restates AL Guidelines, the likely yield is
low — but "likely low" is not "done", and this dimension is **open**, not clean.

---

## 11. Observations — not findings, no action required

These are recorded so their absence is visible as a decision rather than an oversight. None is a
violation of any rule, Standards or BCQuality.

- **No telemetry.** The extension emits no `Session.LogMessage` / `FeatureTelemetry`. Nothing
  requires it, and the Fetch Log covers UC-6 for the *tenant*. But the partner cannot see, across
  customers, that BBB changed their page markup and broke every install at once — which FRD §7.1
  says *will* happen. A `Roadmap.md` candidate for v2, not a v1 gap.
- **No API-side refresh.** The refresh action exists only on the Customer Card; an OData consumer
  cannot trigger one. FR-2 asks for exactly that, so this is correct as built. If it is ever
  requested, `microsoft/knowledge/web-services/expose-operations-as-bound-actions.md` is the shape to
  use ( `[ServiceEnabled] procedure` with `WebServiceActionContext` ) — **not** a writable flag field.
- **`IsRefreshAllowedForCountry` is public but unused.** TDD §6.7 declares it deliberately, *"exposed
  so the UI (or a future list page) can pre-test without triggering an attempt."* Documented intent,
  not dead code — and once v1 ships it is a public signature this extension is committed to.
- **The card action does not pre-test country.** `IsRefreshAllowedForCountry` exists but the action's
  `Enabled` keys only on permission, so a US/CA-only extension still shows an enabled button on a
  German customer and refuses it on click. That is exactly what FR-5/UC-7 specify (a clear refusal
  message), so it is correct — noted only because it looks like an oversight and is not.

---

## 12. Exit gate status — **NOT MET** (expected; this review ran early by design)

Step 09's exit gate: *"All critical findings resolved; dead-code scan 100% clean across every file;
no obsolete references remain; any code fix from this step has been recompiled, repackaged, and
retested."*

| Gate condition | Status |
|---|---|
| All critical findings resolved | **No** — CR-01 open, plus 7 Major. Nothing has been applied. |
| Dead-code scan 100% clean | **No** — CR-02 (unreachable label) and CR-04 (probably-dead subscriber). No `// TODO`/commented-out code, which is the rest of the scan. |
| No obsolete references remain | **Unknown — deferred**, §4. Requires VT-1 and symbols. |
| Fixes recompiled, repackaged, retested | **Not applicable yet** — no fixes applied, and Step 07's first clean compile has not happened. |
| AL Guidelines pass | **Open**, §10. |

### Recommended order of work

1. **AJ Ansari decides** on the 9 document-touching findings (separate boxes per Operating Rule 6),
   and on the mechanical bundle (CR-03, CR-08, CR-11, CR-16, CR-22 — plus CR-06, which is mechanical
   but Major).
2. **Main role applies** the approved fixes, then Step 07's cycle: compile with CodeCop + UICop +
   PerTenantExtensionCop, package to `outputAppPackage/`, publish to a sandbox.
3. **Verify locally, together, in one sitting** — they are all sandbox checks and several are
   one-liners: CR-01 (§16 row 23), CR-04 (rename propagation), CR-06 (VIEW user opens the Customer
   Card), CR-12/CR-13/CR-14/CR-15 (whatever the compiler says), plus §16's outstanding rows and VT-2.
4. **Then re-run Step 08** (gap-fit) and **re-confirm this review** against the post-VT-1, post-VT-3
   code — particularly `ocpfBbbProfileReader`, which will have changed substantially.

---

*Prepared by the reasoning role under the OnlyCopilotFans Agentic Dev Framework v3.3.0.0, Runbook
Step 09 (early). No `.al` file and no other project document was modified in producing it. Every
finding is either cited to a named BCQuality knowledge file or marked as a reviewer finding with its
confidence stated.*
