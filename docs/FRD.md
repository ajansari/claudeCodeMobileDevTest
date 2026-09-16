# Functional Requirements Document — BBB Rating Insights

**Project:** BBB Rating Insights (Business Central SaaS Per-Tenant Extension)
**Publisher:** onlyCopilotFans
**Phase / Step:** DESIGN — Runbook Step 02
**Drafted:** 2026-09-16, by the reasoning role, from `docs/ProblemStatement.md` (PRE-01 + PRE-02),
`docs/ProjectParameters.md` (Step 01, confirmed), and `docs/ChangeLog.md` (DEFINE-001 – DEFINE-004).
**Status:** Draft — awaiting Dev Manager sign-off (AJ Ansari, who holds all three approver roles per
Project Parameters §1.1).

> **Authoritative-source rule.** Every name, ID range, prefix, namespace, version, and localization
> value referenced in this document is read from `docs/ProjectParameters.md`. Where this document
> names one, it is quoting that file, not establishing it. If the two ever disagree, Project
> Parameters wins and this document is corrected.

> **Two things this document does not do.** It does not say *how* anything is built — that is the
> TDD (Step 03). And it does not assert any Business Central table number, page number, field ID, or
> namespace as verified fact: this session has no AL compiler and no symbol files (ChangeLog
> DEFINE-004), so every standard-BC identifier below is marked **UNVERIFIED** and must be confirmed
> against local symbols before the TDD commits to it. See §4.3 and §9.

---

## 1. Purpose and Scope

### 1.1 Purpose

Business Central users making customer-facing commercial decisions — selling, extending credit,
reporting on portfolio risk — currently have no view of a customer's public trust signal without
leaving BC and searching bbb.org by hand. That lookup is manual, inconsistently performed, never
recorded, and invisible to reporting.

**BBB Rating Insights** brings a customer's Better Business Bureau (BBB) rating information into the
customer record itself: the BBB letter grade, whether the customer is BBB-accredited, and how many
complaints BBB has logged against them. The data is refreshed on demand, by a user, from the
customer's own public BBB profile page, and is stamped with when it was last retrieved and whether
that retrieval succeeded.

### 1.2 Scope of this release (v1)

1. **BBB rating data held per customer**, as an extension of the existing customer record — current
   value only, with no history.
2. **A manual, on-demand refresh**, initiated by a user from the customer record, that reads the
   customer's stored BBB profile page and updates the grade, accreditation status, and complaint
   count from it.
3. **Honest staleness and failure reporting** — every refresh attempt, successful or not, records
   when it ran and what happened. A failed refresh never silently replaces good data with blank or
   wrong data.
4. **An audit trail of refresh attempts**, so that a data source with no support path and no SLA
   (§4.1, §7.1) remains diagnosable after the fact.
5. **Visibility on the customer record** for Sales and Credit & Risk users.
6. **Availability to reporting** — the same data readable by Power BI and other OData consumers
   through this extension's own API surface.
7. **Geographic guardrail** — the refresh action is available only for customers in the United
   States and Canada, the two countries BBB covers. Attempting it elsewhere is refused with a clear,
   actionable message rather than silently producing nothing.
8. **Role-appropriate access**, delivered as two permission sets: one that can read BBB data and one
   that can also maintain it and run the refresh.

### 1.3 Explicitly out of scope (v1)

Carried forward unchanged from `ProblemStatement.md`, with the reason each was excluded:

| Out of scope | Why |
|---|---|
| Countries other than the US and Canada | BBB's coverage is US + Canada; PRE-02 resolved the refresh action is country-scoped (ChangeLog DEFINE-002). |
| French-Canadian (fr-CA) translation, and any non-English language | AJ Ansari decided English-only for v1, Canada included (ChangeLog DEFINE-002). See §8. |
| Customer Service as a named consumer | Not a primary target for this release. Nothing blocks them if BC security grants access. |
| Historical grade trending, change tracking, or charting | Current value only, per PRE-01 Resolved Decisions. The Fetch Log (§6) is an audit trail of *attempts*, not a grade-history table, and must not be presented as one. |
| Scheduled or background refresh | On-demand only, per PRE-01 Resolved Decisions. |
| Automated discovery of a customer's BBB profile page by name or address | The profile URL is entered by staff, once per customer. |
| Alerts, workflow notifications, or automated action on a grade change | Not requested for v1. |
| Credit-limit or credit-hold automation driven by BBB grade | The grade is an *input a human weighs*, never an automatic control. See design rule DR-7. |
| Any official or contracted BBB / BBB-reseller data feed | None exists today. §4.1 and §7.1 record why, and the design keeps the door open. |
| A setup/configuration table | PRE-02 resolved: nothing to configure and no credential to store in v1. |

---

## 2. Business Objectives and Value

| # | Objective | Value delivered | How success is judged |
|---|---|---|---|
| BO-1 | Put a customer's public trust signal where the decision is already being made | A rep or analyst sees the BBB grade on the customer record instead of leaving BC | BBB grade is visible on the customer record without navigating away |
| BO-2 | Make the signal usable in credit decisioning | Credit & Risk weighs grade and complaint count alongside existing credit inputs | A credit analyst can see grade + complaint count + accreditation together on one screen |
| BO-3 | Make the signal reportable across the portfolio | Portfolio-level risk reporting in Power BI, not one customer at a time | Power BI can read BBB grade for all customers through a documented endpoint |
| BO-4 | Never let stale or failed data masquerade as current | Decisions are made on data whose age and validity are visible | Every record shows when it was last refreshed and whether that attempt succeeded |
| BO-5 | Keep an unofficial data source diagnosable | When the source breaks — and it will (§7.1) — the failure is visible and traceable, not silent | Each refresh attempt is logged with its outcome |
| BO-6 | Keep the data source replaceable | A future official BBB API or data feed can replace scraping without disturbing users, fields, or reports | The retrieval mechanism is a separable component (a TDD-level obligation, DR-3) |

---

## 3. Target Consumers

| Consumer | What they need | Primary surface | Access |
|---|---|---|---|
| **Sales / Account reps** | See the grade while working an account, before finalizing a deal | Customer record, in the BC client | **Read only.** Sales does not hold refresh/maintenance rights (ChangeLog DEFINE-005, OQ-4 — kept to Credit & Risk to limit who can trigger an unofficial, ToS-risk data pull). |
| **Credit & Risk management** | Grade, accreditation, and complaint count together as one input to a credit decision or hold | Customer record, in the BC client | Read, plus the ability to maintain the profile URL and run a refresh |
| **Reporting / BI (Power BI and other OData consumers)** | Read BBB data for the whole customer portfolio, with the freshness stamp attached | This extension's API endpoints | Read |
| **BC administrator** (supporting consumer, not a named business consumer) | Diagnose why refreshes are failing | The refresh audit log | Read |

**Not a named consumer for v1:** Customer Service. Excluded deliberately (§1.3); nothing prevents
them from being granted the same read access later.

### 3.1 Consumer use cases this release must satisfy

| # | Use case | Source | Satisfied by |
|---|---|---|---|
| UC-1 | A sales rep opens a customer record and sees the BBB grade before finalizing a deal | PRE-01 | FR-6, FR-1 |
| UC-2 | A credit analyst reviews BBB grade + complaint count as one input into a credit-hold decision | PRE-01 | FR-1, FR-6, DR-7 |
| UC-3 | A Power BI dashboard aggregates BBB grade across the customer portfolio for portfolio-risk reporting | PRE-01 | FR-7 |
| UC-4 | A user refreshes one customer's BBB data on demand and sees the result of that attempt | PRE-01 Scope + Resolved Decisions | FR-2, FR-3, FR-4 |
| UC-5 | A user records the BBB profile page for a customer that doesn't have one yet | PRE-01 Resolved Decisions ("manually entered per customer") | FR-1, FR-5 |
| UC-6 | An administrator investigates why refreshes stopped working for every customer | PRE-02 entity list (BBB Fetch Log rationale) | FR-8, FR-9 |
| UC-7 | A user tries to refresh a customer outside the US and Canada and is told clearly why it isn't available | PRE-02 Resolved Decisions (country scoping) | FR-5 |

---

## 4. Platform Requirements

### 4.1 Deployment and platform

| Requirement | Value | Source |
|---|---|---|
| Deployment model | Business Central **SaaS Per-Tenant Extension (PTE)** | Project Parameters §1.1 |
| AL runtime | 16.0 | Project Parameters §1.4 |
| Minimum BC application | 27.0.0.0 — *recorded as unverified in Project Parameters §1.4; confirm against the actual sandbox* | Project Parameters §1.4 |
| Recommended BC version | 27.5+ (validation target) | Project Parameters §1.4 |
| Localization | **`US`** — confirmed at Step 01, deliberately, since this extension never references a US- or CA-specific standard field. The US/CA *business* scope (DR-4) is enforced separately, by this extension's own Country/Region validation, not by the Localization parameter. (ProblemStatement/ChangeLog previously said `NA` in error — corrected, see ChangeLog DEFINE-005.) | Project Parameters §1.1 |
| Object ID range | 50601–50620 (20 IDs, single primary allocation) | Project Parameters §1.2 |
| Namespace | `OnlyCopilotFans.BBBInsights` | Project Parameters §1.1 / §1.3 |
| AL object prefix | `ocpfBbb` | Project Parameters §1.3 |
| Permission sets | Required (this extension owns a table) — `OCPFBBB BBBRI, VIEW` and `OCPFBBB BBBRI, EDIT` | Project Parameters §1.2 / §1.3 |
| External dependency | **None on another extension.** One external dependency on a *website*: bbb.org (§7.1) | This document |

### 4.2 Compatibility and coexistence

- The extension must not modify standard Business Central behavior. It adds fields and a user
  action; it changes nothing that already works.
- It must not interfere with, block, or alter existing credit-limit, credit-hold, blocking, or
  posting behavior (DR-7).
- It must coexist with other extensions on the same tenant, including other extensions that also
  extend the customer record.
- It must not require any Business Central localization app, country-specific app, or language app
  to function.

### 4.3 Platform capabilities this document assumes — and how confident we are in each

Runbook Step 02 requires that no requirement rests on an assumed platform behavior without saying
so. This session has no symbol files and no compiler (ChangeLog DEFINE-004), and Microsoft Learn is
unreachable from it, so nothing below has been machine-verified. Each assumption is stated with its
confidence and how to verify it.

| # | Assumed capability | Confidence | Basis, and what must be verified locally |
|---|---|---|---|
| PA-1 | Business Central lets an extension add fields to the standard customer table (`tableextension`) | **High** | Core, long-standing AL extensibility. No reasonable doubt the capability exists. **Unverified:** that the customer table is table **18** and that the specific new field IDs chosen at Step 03 are free. |
| PA-2 | An extension can add fields and an action to the standard Customer Card page (`pageextension`) | **High** | Core AL extensibility. **Unverified:** that the Customer Card is page **21**, and whether a FactBox or an inline field group is the better placement (a TDD decision). |
| PA-3 | An AL codeunit in a **SaaS PTE** can make outbound HTTP(S) calls to an arbitrary public website | **Medium–High — verify before the TDD commits** | AL provides an HTTP client type for sandboxed extensions, so the capability exists. **The real risk is the gate, not the API:** Business Central governs outbound calls per-extension through an "Allow HttpClient Requests"-style switch in Extension Management, and the default for a per-tenant extension must be confirmed on the actual tenant. If it defaults off, an administrator must turn it on and `Deployment.md` (Step 11) must say so. **Action: confirm on the target sandbox before Step 03 closes.** |
| PA-4 | AL can extract the grade, accreditation status, and complaint count from a fetched HTML page | **Medium — this is the weakest assumption in the design** | AL has **no HTML DOM parser**. Retrieval returns text; interpreting it means text/pattern matching (or treating fragments as XML/JSON where the page happens to embed structured data). That is workable but inherently brittle and is the mechanism DEFINE-001's accepted risk actually lands on. It is a *how*, so the TDD owns the technique — but the FRD must not pretend the platform hands this over for free. |
| PA-5 | The refresh action can be restricted to customers in the US and Canada | **High for the mechanism, Medium for the data** | Reading a customer's country/region and refusing the action is ordinary application logic — no platform doubt. **But the country codes themselves are tenant data, not platform constants:** "US" and "CA" are conventional, not guaranteed, and a customer's country/region can be **blank**. See open item OQ-2. |
| PA-6 | A fixed value set (the BBB letter grades) can be modeled as an AL enum rather than a lookup table | **High** | Standard AL. PRE-02 §6.3 already resolved this. **Unverified:** nothing platform-level; the enum's own value list is a TDD detail. |
| PA-7 | Custom API pages published by a PTE are readable by Power BI and other OData clients | **High** | This is the standard BC API mechanism, and the pattern every OCPF-built extension already uses. **Unverified:** the exact endpoint URL shape for this tenant and version — Standards Appendix A is the reference, confirm at Step 11. |
| PA-8 | Every BC table exposes a stable `SystemId` usable as the OData key | **High** | Present on every table since BC v15; Standards §2.1 mandates its use. |
| PA-9 | An extension can own its own table and grant access to it through its own permission sets | **High** | Standard AL, and Standards §5.3 requires exactly this. |
| PA-10 | Extension fields added to the customer table are automatically available through an API page over that table | **High** | Standard behavior of extending a table that an API page sources from. **Unverified:** nothing platform-level. |
| PA-11 | The BBB profile page for a given customer remains reachable and parseable over time | **Not a platform capability at all — an external assumption, and an explicitly accepted risk** | bbb.org is a third party with no agreement with us. See §7.1 and ChangeLog DEFINE-001. |

**Rule for the TDD (Step 03):** none of PA-1 … PA-10 may be written into the TDD as fact until it is
confirmed against downloaded symbols in AJ Ansari's local environment (Operating Rule 2, ChangeLog
DEFINE-004). PA-3 and PA-4 additionally need a live sandbox test, not just symbol verification.

---

## 5. Design Rules — Non-Negotiable Constraints

These govern every object built for this extension. A change to any of them is a change to this
document and needs its own approval (Operating Rule 6).

| # | Rule | Rationale |
|---|---|---|
| **DR-1** | **A failed refresh never overwrites good data.** On any failure — unreachable page, blocked request, changed page structure, unrecognized content — the previously stored grade, accreditation status, and complaint count are left exactly as they were, and only the status and timestamp change. | PRE-01 Resolved Decisions. Silent replacement of good data with blank data is the single worst failure mode for a decision-support field. |
| **DR-2** | **Every refresh attempt is stamped and logged, success or failure.** The customer record always shows when the last attempt ran and how it ended; the audit log always gains an entry. **"Attempt" means a retrieval was actually initiated — i.e., its preconditions passed.** A precondition refusal (no profile URL, an unsupported or blank country/region) is not an attempt: no external call was made, so it is shown to the user immediately and is not logged. | BO-4, BO-5. An unofficial source with no SLA is only trustworthy if its failures are loud. **Clarified 2026-09-16, ChangeLog DEFINE-009, resolving Sanity Check finding F-S-2** — writing a log row for a refusal would misrepresent durability anyway, since `Error` rolls back any row written before it. |
| **DR-3** | **The retrieval mechanism is a separable component.** Nothing user-facing — no field, no page, no API endpoint, no permission set — may depend on *how* the data was obtained. Replacing scraping with an official API must not change any of them. | ChangeLog DEFINE-001's explicit commitment; BO-6. |
| **DR-4** | **The refresh action is available only for customers whose country/region is the United States or Canada.** Any other value — including blank — is refused with a clear, actionable message naming the reason — never a silent no-op and never a technical error. | PRE-02 Resolved Decisions; ChangeLog DEFINE-002 and DEFINE-005 (OQ-2). BBB does not cover other countries, so a "successful" fetch there would be meaningless, and a blank country/region is treated the same as an unsupported one rather than assumed to be in-scope. |
| **DR-5** | **The BBB profile URL is staff-entered and staff-owned.** The extension never guesses, searches for, or derives it, and never silently substitutes a different one. | PRE-01 Resolved Decisions. Attaching the wrong company's rating to a customer is a serious data-integrity failure. |
| **DR-6** | **Retrieved values are system-owned; the profile URL is user-owned — specifically, owned by the maintenance (EDIT) permission set, not by Customer-modify rights generally.** Grade, accreditation status, complaint count, last-fetched stamp, and fetch status are written by the refresh; the profile URL is maintained only by a user holding `OCPFBBB BBBRI, EDIT`, enforced in code (the field's own `OnValidate`), both through the UI and the API. The audit log is system-written and never user-editable. | Keeps ownership of each field unambiguous, which is what makes DR-1 and DR-2 enforceable. **Clarified 2026-09-16, ChangeLog DEFINE-007, resolving Sanity Check finding F-B-1** — the original wording did not state *which* users own the URL, which this extension's own permission sets could not otherwise enforce on a standard-table field. |
| **DR-7** | **BBB data is advisory only.** No automatic credit hold, block, posting restriction, pricing change, or workflow may be driven by the grade. It informs a human decision; it never makes one. | The source is unofficial, unguaranteed, and out of our control (§7.1). Automating a control on it would convert a disclosed data-quality risk into an operational one. |
| **DR-8** | **Current value only — this extension keeps no grade history.** The audit log records *attempts*, not a time series of grades, and must never be presented or documented as grade history. | PRE-01 Resolved Decisions; §1.3. |
| **DR-9** | **No configuration surface in v1.** No setup table, no assisted-setup wizard, no activity cues, no Departments/Tell Me placement. | PRE-02 Resolved Decisions; Project Parameters §1.6. |
| **DR-10** | **English only, with US wording, and no translation files.** | ChangeLog DEFINE-002; Project Parameters §1.9. See §8. |
| **DR-11** | **Two permission sets, per Standards §5.3–§5.4:** a read-only set and a read/write set that includes it, named `OCPFBBB BBBRI, VIEW` and `OCPFBBB BBBRI, EDIT`, with a `tabledata` grant in both for every table this extension owns. | Project Parameters §1.2/§1.3; Standards §5.3. |
| **DR-12** | **Every object lives inside 50601–50620**, with a growth buffer preserved (Standards §5.2). | Project Parameters §1.2. |
| **DR-13** | **The extension adds; it never alters.** No standard BC behavior, field, or process is changed, and no standard object is modified — only extended (Standards §10.1). | §4.2. |
| **DR-14** | **No standard-BC identifier is treated as known.** Every table number, page number, field ID, and namespace is verified against local symbols before use (Operating Rule 2), and until then is written down as unverified. | ChangeLog DEFINE-004. |

---

## 6. Functional Requirements

### 6.1 Data held per customer

**FR-1 — BBB rating fields on the customer record.** Each customer carries the following, all
current-value-only (DR-8):

| Field (business name) | Meaning | Who writes it | Notes |
|---|---|---|---|
| **BBB Grade** | The BBB letter grade: A+, A, A-, B+, B, B-, C+, C, C-, D+, D, D-, F, or NR (Not Rated) | System (refresh) | Must also be able to represent "no value yet" distinctly from "NR", since *not rated by BBB* and *never fetched* are different facts |
| **BBB Accredited** | Whether the customer is a BBB-accredited business | System (refresh) | Distinct from the grade and not implied by it (Domain Vocabulary) |
| **BBB Complaint Count** | The number of complaints BBB has logged against the customer | System (refresh) | Captures whatever complaint figure BBB's profile page displays most prominently (commonly a 3-year window); the TDD states the exact on-page figure captured once real page structure is examined (ChangeLog DEFINE-005, OQ-3). |
| **BBB Profile URL** | The public bbb.org page for this customer's business | Staff (DR-5) | The source page every refresh reads |
| **BBB Last Fetched** | When the last refresh attempt ran | System | Stamped on *every* attempt, success or failure (DR-2) |
| **BBB Fetch Status** | How the last attempt ended — e.g. Never Fetched / OK / Failed / Stale | System | Makes a failed refresh visible rather than letting old data look current (DR-1, BO-4) |

**FR-1a.** A customer with no BBB profile URL is a normal, valid state — the extension must not
treat it as an error or nag about it. It simply has no BBB data yet.

### 6.2 Refreshing the data

**FR-2 — On-demand refresh.** A user with the appropriate permission can refresh one customer's BBB
data from the customer record, at a moment of their choosing. There is no scheduled or automatic
refresh in v1 (§1.3).

**FR-3 — Successful refresh.** On success, the grade, accreditation status, and complaint count are
replaced with the values read from the customer's BBB profile page; the last-fetched stamp is set to
now; the fetch status is set to a success state; and the user is told the refresh succeeded.

**FR-4 — Failed refresh.** On any failure, the previously stored grade, accreditation status, and
complaint count are left untouched (DR-1); the last-fetched stamp is still set to now (DR-2); the
fetch status is set to a failure state; and the user is shown a clear message saying the refresh
failed and, as far as can be determined, why — not a raw technical error.

**FR-5 — Preconditions, refused clearly.** The refresh is refused, with a specific and actionable
message, when:

| Precondition not met | The user must be told |
|---|---|
| The customer has no BBB profile URL recorded | That a BBB profile URL must be entered first (DR-5) |
| The customer's country/region is not the United States or Canada | That BBB coverage is limited to the US and Canada, naming the customer's actual country/region (DR-4) |
| The customer's country/region is blank | Refused, same as any unsupported country — the message tells staff to set the country/region first (ChangeLog DEFINE-005, OQ-2) |

Each refusal is a clean, understandable message, never a silent no-op and never an unhandled error
(§7.3).

### 6.3 Seeing the data

**FR-6 — Visibility on the customer record.** BBB Grade, BBB Accredited, BBB Complaint Count, BBB
Profile URL, BBB Last Fetched, and BBB Fetch Status are visible together on the customer record in
the BC client, alongside the refresh action, for Sales and Credit & Risk users. Whether they appear
as an inline group on the card or in a FactBox is a presentation decision for the TDD; *that they are
visible together, with the freshness stamp beside the values*, is the requirement.

**FR-6a.** The profile URL is editable directly on the customer record by a user with maintenance
permission, and is presented so it can be opened in a browser.

**FR-7 — Availability to reporting.** BBB data is readable for the whole customer portfolio through
this extension's own API surface, so Power BI and other OData consumers can report on it. Each
record carries enough to identify the customer, plus the grade, accreditation status, complaint
count, last-fetched stamp, and fetch status — so a report can distinguish fresh data from stale
(BO-4).

### 6.4 Audit trail

**FR-8 — Every refresh attempt is recorded.** Each attempt produces a log entry capturing at minimum
which customer, when, the outcome, and enough detail about a failure to diagnose it after the fact.
Log entries are written by the system and are never edited by users (DR-6).

**FR-9 — The log is reviewable.** An administrator or support user can review refresh attempts in the
BC client and through the API surface, filtered to a customer or to failures, to answer "why did this
stop working, and when did it start failing?" (UC-6). **"Filtered to failures" is satisfied by
standard column filtering on the log's `Outcome`/`outcome` field**, in both the BC client list page
and the API — no dedicated saved view or `FilterGroup` is built for v1; this is FR-9's explicit
resolution (ChangeLog **DEFINE-014**, Sanity Check finding F-S-11), not an open gap.

**FR-10 — Log retention.** Every Fetch Log entry is kept indefinitely; there is no purge or
retention cap in v1 (ChangeLog DEFINE-005, OQ-5 — a deliberate decision, not a default).

### 6.5 Access control

**FR-11 — Two access levels.** A read-only level can see BBB data on the customer record, in the log,
and through the API — this is what Sales/Account reps hold. A maintenance level can additionally
edit the BBB profile URL and run a refresh — held by Credit & Risk only (ChangeLog DEFINE-005,
OQ-4). Delivered as the two permission sets in DR-11, each accompanied in `Deployment.md` by the
base BC permissions a consumer also needs (Standards §5.3). **The BBB Profile URL is writable —
through the customer record and through the API alike — only by a user holding the maintenance
permission set.** This is enforced by the field's own `OnValidate` trigger, which refuses the change
unless the caller holds `OCPFBBB BBBRI, EDIT` (the same write-permission test the refresh action
uses); it does not depend on, and is not satisfiable by, ordinary standard Customer-modify rights
alone (ChangeLog **DEFINE-007**, resolving Sanity Check finding F-B-1).

---

## 7. Non-Functional Requirements

### 7.1 Data-source risk — disclosed, accepted, and carried into the design

**This is the defining constraint of the project and is stated here in full rather than buried.**

BBB rating data is obtained by **retrieving and interpreting BBB's public business-profile web
pages**. There is no official BBB API and no contracted data-feed relationship with BBB or any
aggregator. AJ Ansari was informed of the following risks on 2026-09-16 and **explicitly accepted
them** (ChangeLog **DEFINE-001**):

- **Terms of Service.** Automated/bulk retrieval of BBB's website violates BBB's website terms.
- **No SLA, no support path.** BBB owes us nothing. There is no one to escalate to.
- **Silent, unannounced breakage.** BBB can change page markup, add anti-bot measures, rate-limit, or
  block access at any time without notice. The integration can stop working correctly on any given
  day, through no change of ours. PA-4 (no HTML parser in AL; pattern-matched interpretation) makes
  this the most likely failure mode, not the least.
- **AppSource.** This release is a SaaS PTE, so AppSource validation is not in play today. If this
  extension is ever submitted to AppSource, dependence on ToS-violating retrieval is a plausible
  rejection reason.
- **No indemnification.** The business running this extension bears the risk of a cease-and-desist or
  an IP block.

**Requirements this places on the build:**

| # | Requirement |
|---|---|
| NFR-1 | Breakage must be **visible, never silent** — DR-1, DR-2, FR-4 exist for this reason and are not negotiable. |
| NFR-2 | The retrieval mechanism must be **replaceable without touching anything user-facing** (DR-3), so an official feed can be adopted later as a contained change. |
| NFR-3 | Retrieval must be **considerate**: one customer at a time, user-initiated, no bulk or automated crawling, no retry storm on failure. This both limits exposure and is the behavior a reasonable operator can defend. |
| NFR-4 | `UserGuide.md` and `Deployment.md` (Step 11) must state plainly that the data comes from an unofficial source that can break without warning, and that a "Failed" status means *do not trust the displayed values as current*. |
| NFR-5 | BBB data must never drive an automatic control (DR-7). |

### 7.2 Performance and responsiveness

- **NFR-6** — A refresh acts on **one customer at a time**, initiated by a user, and must return
  control with a clear outcome rather than leaving the client waiting indefinitely. The retrieval
  must be bounded by a timeout, with a timeout treated as an ordinary failure under FR-4.
- **NFR-7** — Displaying BBB data on the customer record, in lists, and through the API must not
  trigger any external call. Reading is always from stored values; only the explicit refresh action
  reaches outside BC.
- **NFR-8** — The extension must not measurably slow the opening of the customer record, the customer
  list, or any standard BC process.

### 7.3 Usability and error behavior

- **NFR-9** — Every refusal and failure message is written for a business user: what happened, why,
  and what to do next. No raw HTTP status codes, stack traces, or unhandled runtime errors surfaced
  to the user (the underlying detail belongs in the log, FR-8).
- **NFR-10** — Field captions and tooltips are written to be self-describing, including for API
  consumers reading the schema (Standards §2.5–§2.6) — BBB terminology is not universally known and
  the difference between *grade* and *accreditation* must be clear from the tooltip alone.
- **NFR-11** — "Never fetched" must be visually distinguishable from "fetched and BBB says Not
  Rated" (FR-1).

### 7.4 Data, privacy, and compliance

- **NFR-12** — All BBB data stored is **publicly published information about a business**, not
  personal data. Every new field and table is nonetheless classified explicitly for BC's data
  classification, and the log must not record anything beyond what is needed to diagnose a failure.
- **NFR-13** — The extension stores no credentials, secrets, API keys, or authentication material.
  There is nothing to configure and nothing to protect (DR-9).
- **NFR-14** — Uninstalling the extension must not damage standard customer data. Removal behavior
  for this extension's own fields and log data is documented in `Deployment.md` (Step 11).
- **NFR-15** — Deletion behavior is decided explicitly for every entity this extension owns, per the
  Step 04 sanity-check requirement. **BBB Fetch Log entries cascade-delete when their customer is
  deleted** (ChangeLog DEFINE-005, OQ-6) — the log is an operational audit trail for a live
  customer, not a permanent record required to survive the customer's own deletion.

### 7.5 Build quality and compliance with the framework

- **NFR-16** — The extension compiles with **0 errors and 0 warnings**, with CodeCop, UICop, and
  PerTenantExtensionCop engaged and nothing suppressed (Operating Rule 5; Standards/Ops → Analyzers).
- **NFR-17** — Every object conforms to the OCPF AL Development Standards Guide: `NoImplicitWith`
  enforced, no dead code, label-based text only (never `CaptionML`/`ToolTipML`/`TextConst`), 4-space
  indentation, one object per file named for its object.
- **NFR-18** — No object ID outside 50601–50620, and the Object Register is kept current (DR-12).
- **NFR-19** — Every reference to a standard BC object, field, or namespace is verified against
  downloaded symbols before it is relied upon (Operating Rule 2, DR-14).
- **NFR-20** — This is v1; no upgrade or data-migration code is required for a first release. From v2
  onward, Standards Part 9 applies. *This is a recorded decision, not a silence.*

### 7.6 Where the work happens — a workflow constraint on this project

**NFR-21 — Symbol verification and compilation happen locally, not in the agent session**
(ChangeLog **DEFINE-004**). The session drafting these documents has no AL Language extension, no
compiler, and no symbol files, and cannot reach Microsoft Learn. Consequently:

- Every standard-BC identifier in this FRD, and in the TDD that follows, is written as **UNVERIFIED**
  and must be confirmed in AJ Ansari's local VS Code + AL environment before it is trusted (DR-14).
- Project Parameters §1.4 **Symbol Source** stays blank until symbols are downloaded locally.
- The Step 07 compile-and-package cycle, the sandbox publish, and all live testing are performed
  locally. Nothing in this document may be read as claiming code has been compiled or verified.
- Assumptions PA-3 (outbound HTTP permitted for this PTE on this tenant) and PA-4 (interpreting the
  fetched page) additionally require a **live sandbox test**, not merely symbol verification, and
  should be proven before the TDD's retrieval design is finalized.

---

## 8. Languages and Markets

From Project Parameters §1.9 and ChangeLog DEFINE-002.

| Aspect | Requirement |
|---|---|
| **Markets served** | **United States and Canada.** Canada was added during PRE-02 (ChangeLog DEFINE-002); this is the same country pair the refresh action is scoped to (DR-4). |
| **Working language** | English. |
| **Source language** | `en-US`. |
| **Source wording** | **US wording, written directly in source.** |
| **Target languages** | **None beyond source.** English-only, confirmed for Canada as well — AJ Ansari decided against fr-CA support for v1 despite Canada being bilingual (ChangeLog DEFINE-002). |
| **Translation files** | **None produced for v1.** Standards Part 8's translation machinery — glossary, per-language drafting, reviewer approval, `.xlf` state gate — does not apply to this project. |
| **Customer-language documents** | None. This extension produces no customer-facing documents (no invoices, statements, or emails). |
| **Translatable business data** | None. Grade, accreditation status, and complaint count are structured reference values, not user-authored text. |
| **Requirement, stated as a requirement** | *All users, in both the United States and Canada, work with this extension in US English.* Canadian users see the same English wording as US users. |

**Consequences deliberately accepted:** a Canadian user running a French BC client will see this
extension's fields and messages in English while the rest of their client is in French. This is the
accepted outcome of DEFINE-002, not an oversight. Adding fr-CA later is a v2 change that would bring
Standards Part 8 into scope in full.

**Still required despite English-only** (Standards §1.7, §8.2): every user-facing string is a proper
AL label — never a bare literal, never a multilanguage property, never `TextConst` — and the
`TranslationFile` feature stays enabled in `app.json` so the compiler keeps enforcing that.

---

## 9. Entity and Object Inventory

Every object this extension is expected to deliver, with its source table, type, and read vs.
read/write designation. **Read/write designations follow Standards §2.2's mutability rules, not
preference.** Object IDs are *not* assigned here — that is Step 03 (TDD), drawing from 50601–50620.
Names below follow prefix `ocpfBbb` and namespace `OnlyCopilotFans.BBBInsights` (Project Parameters
§1.3) and are indicative; the TDD fixes them.

> **Every standard BC table and page number below is marked UNVERIFIED** — believed correct from
> public BC documentation and general familiarity, **not** confirmed against a live symbol file.
> Confirm each locally before the TDD relies on it (DR-14, NFR-21, ChangeLog DEFINE-004).

### 9.1 Data objects

| # | Object (indicative name) | Type | Source / underlying table | R vs R/W | Mutability rationale (Standards §2.2) |
|---|---|---|---|---|---|
| E-1 | `ocpfBbbCustomerExt` | Table extension | **Customer — table 18 (number believed correct from public BC documentation, UNVERIFIED against a live symbol file — confirm locally)** | **Read/Write** | Extends master data. BBB Profile URL is user-maintained; the five retrieved/system fields are system-written (DR-6) and must be non-editable to users. |
| E-2 | `ocpfBbbFetchLog` | Table (owned by this extension) | New — none | **System-write, read-only to users** | Audit/system table. Standards §2.2 classifies audit tables as read-only; entries are inserted by the refresh and never edited (DR-6, FR-8). |
| E-3 | `ocpfBbbGrade` | Enum | New — none | N/A (value set) | Fixed, small value set (A+ … F, NR, plus a distinct "no value yet" state per FR-1). PRE-02 §6.3 resolved this as an enum, not a lookup table. |
| E-4 | `ocpfBbbFetchStatus` | Enum | New — none | N/A (value set) | Fixed outcome set for FR-1's Fetch Status (e.g. Never Fetched / OK / Failed / Stale). |

### 9.2 User-interface objects

| # | Object (indicative name) | Type | Source / underlying object | R vs R/W | Notes |
|---|---|---|---|---|---|
| E-5 | `ocpfBbbCustomerCardExt` | Page extension | **Customer Card — page 21 (number believed correct from public BC documentation, UNVERIFIED against a live symbol file — confirm locally)** | Read/Write (URL editable; retrieved fields display-only) | Surfaces FR-6's fields and hosts the "Refresh BBB Data" action (FR-2). |
| E-6 | `ocpfBbbCustomerFactBox` | Page (CardPart / FactBox) | Customer (see E-1's UNVERIFIED note) | Read-only display | **Conditional.** PRE-01 allows "Customer Card **or** a FactBox extension of it". The TDD picks one; if the inline group on E-5 satisfies FR-6, this object is not built and its ID returns to the growth buffer. |
| E-7 | `ocpfBbbFetchLogList` | Page (List) | `ocpfBbbFetchLog` (E-2) | **Read-only** (`Editable = false`) | FR-9's review surface. Audit data — read-only per Standards §2.2. |

### 9.3 Logic objects

| # | Object (indicative name) | Type | Source / underlying | R vs R/W | Notes |
|---|---|---|---|---|---|
| E-8 | `ocpfBbbRatingMgt` | Codeunit | — | N/A | Orchestration: preconditions (FR-5), invoking retrieval, applying DR-1's keep-last-known-value rule, stamping status, writing the log (FR-8). Contains no knowledge of *how* the data is obtained (DR-3). |
| E-9 | `ocpfBbbProfileReader` | Codeunit | — | N/A | **The replaceable component (DR-3, NFR-2).** Sole owner of the external call and of interpreting the response (PA-3, PA-4). Everything else in the extension is indifferent to how it works. The TDD may split retrieval from interpretation; that split is a TDD decision, but the isolation boundary itself is an FRD requirement. |

### 9.4 Integration objects

| # | Object (indicative name) | Type | Source / underlying table | R vs R/W | Mutability rationale (Standards §2.2) |
|---|---|---|---|---|---|
| E-10 | `ocpfBbbCustomerRatings` (`EntityName` `ocpfBbbCustomerRating` / `EntitySetName` `ocpfBbbCustomerRatings`) | API page | **Customer — table 18 (UNVERIFIED, as E-1)** | **Editable** (`DelayedInsert = true`) | Standards §2.2: a page over **master data** is editable — mutability, not preference, decides. The *business* need is read-only reporting (FR-7, UC-3); read-only access is enforced by the VIEW permission set (DR-11), not by making the page non-editable against the standard. **The five system-written fields are non-editable at field level (DR-6), so only the profile URL is writable through the API.** Flagged for the TDD as a deliberate, standards-driven choice. |
| E-11 | `ocpfBbbFetchLogEntries` (`EntityName` `ocpfBbbFetchLogEntry` / `EntitySetName` `ocpfBbbFetchLogEntries`) | API page | `ocpfBbbFetchLog` (E-2) | **Read-only** (`Editable = false`) | Standards §2.2: audit/system table → read-only. Supports FR-9 and external monitoring of failure rates. |

All API objects use `APIPublisher = 'onlyCopilotFans'`, `APIGroup` prefixed `ocpfBbb`,
`APIVersion = 'v1.0'`, and `ODataKeyFields = SystemId` (Project Parameters §1.3; Standards §2.1,
§2.7).

### 9.5 Security objects

| # | Object | Type | R vs R/W | Notes |
|---|---|---|---|---|
| E-12 | `OCPFBBB BBBRI, VIEW` | Permission set | Read | Read on all pages/objects, including `tabledata` read on `ocpfBbbFetchLog` (Standards §5.3). Pairs with `D365 READ`. |
| E-13 | `OCPFBBB BBBRI, EDIT` | Permission set | Read/Write | Includes VIEW, plus write on the editable surfaces and the right to run the refresh. `tabledata` insert on `ocpfBbbFetchLog`. Pairs with `D365 BUS FULL ACCESS` or equivalent. |

### 9.6 ID budget

13 objects (12 if E-6 is not built) against an allocation of 20 IDs (50601–50620) — roughly a 35–40%
growth buffer, comfortably above the 20% minimum (Standards §5.2). Module grouping and the
per-module sub-blocks are a Step 03 concern.

### 9.7 Considered and deliberately not included in v1

| Candidate | Decision | Reason |
|---|---|---|
| BBB Setup table | **Not built** | PRE-02 Resolved Decisions — nothing to configure, no credential to store (DR-9). |
| Customer List page extension (BBB Grade as a list column) | **Not built in v1** | PRE-01 scopes visibility to the customer card. A portfolio view is served by FR-7 (Power BI). Recorded here so its absence is a decision, not an omission — a plausible v2 candidate for `Roadmap.md`. |
| Grade history table | **Not built** | DR-8 / §1.3 — current value only. |
| Job queue / scheduled refresh objects | **Not built** | §1.3 — on-demand only. |
| Assisted setup wizard, activity cues, Departments placement | **Not built** | Project Parameters §1.6 — all three answered No. |
| Upgrade codeunit | **Not built for v1** | NFR-20 — first release. Standards Part 9 applies from v2. |

---

## 10. Step 02 Review and Validation

Runbook Step 02 requires this document to be validated against the DEFINE artifacts before sign-off.

### 10.1 Every entity in the PRE-02 expanded list appears here

| PRE-02 expanded entity | In this FRD? | Where |
|---|---|---|
| Customer (extend) — Master, Table Extension, R/W, global with US/CA-scoped refresh | **Yes** | E-1; FR-1; DR-4 |
| BBB Fetch Log — Analytical/audit, new table, system-written, read-only to users | **Yes** | E-2; FR-8, FR-9, FR-10 |

Both PRE-02 entities are present, with matching type and scoping. **The Customer row's R/W intent
needed reconciliation, not a match:** PRE-02 recorded BBB Grade, Accreditation Status, and Complaint
Count as staff-editable, which DR-6 above corrects — those three are system-owned, and only the
Profile URL is staff-editable (and, per F-B-1 above, only by the maintenance permission set).
`ProblemStatement.md` is corrected accordingly and the reconciliation is logged (ChangeLog
**DEFINE-013**, Sanity Check finding F-S-12); DR-6 is right and the stale PRE-02 wording, not this
build, was the error. **No entity from the expanded list is deferred or dropped.** The additional
objects in §9 (enums, UI, logic, API, permission sets) are the delivery mechanics those two entities
imply, not new scope.

### 10.2 Every PRE-01 consumer use case is addressed

| Use case | Addressed | By |
|---|---|---|
| UC-1 Sales rep sees grade on the customer record before finalizing a deal | Yes | FR-6, FR-1, E-5 |
| UC-2 Credit analyst uses grade + complaint count in a credit-hold decision | Yes | FR-1, FR-6, DR-7 (advisory only) |
| UC-3 Power BI aggregates grade across the portfolio | Yes | FR-7, E-10 |
| UC-4 On-demand refresh with a visible outcome | Yes | FR-2, FR-3, FR-4 |
| UC-5 Staff record a customer's BBB profile URL | Yes | FR-1, FR-6a, DR-5 |
| UC-6 Administrator diagnoses repeated failures | Yes | FR-8, FR-9, E-7, E-11 |
| UC-7 Refresh refused clearly outside the US/Canada | Yes | FR-5, DR-4 |

Every PRE-01 named consumer (Sales, Credit & Risk, Reporting/BI) has at least one satisfied use case
(§3).

### 10.3 Platform assumptions

All eleven are enumerated in §4.3 with an explicit confidence rating and a verification route. **No
requirement in this document rests on an unstated assumption about what Business Central can do.**
Two assumptions are below "High" and are called out as needing proof before the TDD's retrieval
design is finalized: **PA-3** (outbound HTTP permitted for this PTE on this tenant) and **PA-4** (no
HTML parser exists in AL; interpretation is pattern-matching and is inherently brittle).

### 10.4 Traceability back to the ChangeLog

| ChangeLog issue | Carried into this FRD |
|---|---|
| **DEFINE-001** — scraping risk accepted | §7.1 in full, plus DR-3, NFR-1–NFR-5, PA-4, PA-11, E-9 |
| **DEFINE-002** — US + Canada, English-only | §8, DR-4, DR-10, §1.3 |
| **DEFINE-003** — `.gitignore` hygiene fix | No FRD impact (repository hygiene, not design) — recorded here so its absence is deliberate |
| **DEFINE-004** — no AL tooling in this session | NFR-21, DR-14, §4.3's blanket UNVERIFIED marking, every table/page number in §9 |
| **DEFINE-005** — Step 02 review findings resolved | Localization correction (§4.1), DR-4/FR-5 blank-country handling, FR-1 complaint-count note, FR-11/DR-11 refresh permission, FR-10 retention, NFR-15 deletion behavior — all six resolved decisions plus the OQ-1 documentation-bug correction |

---

## 11. Open Items — Resolved

The reasoning role's Step 02 review surfaced seven open items. All are now closed
(ChangeLog **DEFINE-005**, 2026-09-16, AJ Ansari unless noted):

| # | Open item | Resolution |
|---|---|---|
| **OQ-1** | Localization `US` vs `NA` | Not a decision — a documentation bug. `docs/ProjectParameters.md` §1.1's `US` was correct all along (a deliberate Step 01 choice); `ProblemStatement.md` and this ChangeLog's DEFINE-002 entry incorrectly said `NA` from an earlier draft and have been corrected. See §4.1. |
| **OQ-2** | Blank Country/Region | **Refused**, same as any unsupported country. See DR-4, FR-5. |
| **OQ-3** | What "Complaint Count" counts | **Whatever figure BBB's page shows most prominently** (commonly a 3-year window); the TDD states the exact on-page figure once real page structure is examined. See FR-1. |
| **OQ-4** | Who may run the refresh | **Credit & Risk only.** Sales reps are read-only. See §3, FR-11, DR-11. |
| **OQ-5** | Log retention | **Keep everything forever** — no purge logic in v1. See FR-10. |
| **OQ-6** | Deletion behavior for Fetch Log entries | **Cascade delete** with the customer. See NFR-15. |
| **OQ-7** | Outbound HTTP permission on the target tenant (PA-3) | Not a decision — a **verification task** for AJ Ansari's local sandbox, to complete before Step 03's retrieval design is finalized. Still open as a to-do, tracked in `docs/ProjectMemory.md`, not a Step 02 sign-off blocker. |

---

## 12. Sign-Off

| Role | Name | Decision | Date |
|---|---|---|---|
| Dev Manager (also Functional Consultant and Technical Lead — Approvers = one person, Project Parameters §1.1) | AJ Ansari | **Approved** | 2026-09-16 |

**Exit gate for Step 02 (runbook): MET.** FRD written and signed off; every DEFINE-phase entity
accounted for (§10.1); no unverified platform assumptions left unstated (§4.3, §10.3, two rated
below High); all seven §11 open items resolved or, for OQ-7, explicitly carried forward as a
verification task rather than a sign-off blocker. Proceeding to Step 03 — Technical Design
Document.
