# Problem Statement

**Project:** Business Central PTE — Customer BBB Grade Tracking
**Phase:** DEFINE, Step PRE-01
**Status:** Resolved — all PRE-01 open questions closed by AJ Ansari on 2026-09-16. One item
(Deployment Target) deferred to Step 01 intake per its own note below; does not block PRE-02.

## Purpose

Track each customer's Better Business Bureau (BBB) rating information within Business Central so
Sales, Credit & Risk, and Reporting/BI can factor a customer's public trust/reliability signal
into day-to-day decisions, without staff having to leave BC to look it up.

## Business Outcome Required

Give BC users and BI a BBB Grade (and supporting BBB data) per customer, refreshed from BBB's
public profile pages, surfaced on the customer record and available to Power BI.

## Target Consumers

- **Sales / Account reps** — view grade on the customer card while working accounts.
- **Credit & Risk management** — use grade as an input to credit decisions or holds.
- **Reporting / BI (Power BI)** — grade feeds dashboards and analytics.

*Not selected as a named consumer:* Customer Service. They are not a primary target for this
release; nothing prevents them from seeing the same fields if BC security grants access.

## Countries and Languages

- **Countries:** United States **and Canada**. Scope was revised during PRE-02 (see ChangeLog
  DEFINE-002) — originally US-only, expanded once country-scoping for the fetch action was
  discussed.
- **Working language:** English.
- **Target languages:** English-only, confirmed for Canada too (Canada is bilingual, but AJ
  Ansari decided against fr-CA translation support for v1 — see ChangeLog DEFINE-002). Expected
  source wording: *US wording, no translation files* — confirmed formally at Step 01 §1.9.
  **Localization parameter is `US`** (Project Parameters §1.1) — a deliberate Step 01 choice,
  not `NA`: Localization governs which *standard BC fields/tables* this extension may reference
  (Standards Part 3), which is a separate concern from which countries the extension's own
  business logic supports. This extension never references a US- or CA-specific standard field,
  so a single Localization value works; the US/CA business scope is enforced entirely by this
  extension's own Country/Region validation (see PRE-02 below), independent of this parameter.
  An earlier draft of this section incorrectly said Localization would become `NA` — corrected
  here at Step 02 (FRD) once the FRD's own review caught the inconsistency; see ChangeLog
  DEFINE-005.

## Data Source & Integration Approach — ACCEPTED RISK

**Chosen approach:** automated retrieval by scraping BBB's public business-profile web pages.
No official BBB API or contracted data-feed relationship is in place.

**Explicitly flagged to AJ Ansari and accepted on 2026-09-16:**
- Violates BBB's website Terms of Service for automated/bulk access.
- No SLA or support path — BBB can change page markup, add anti-bot measures, or block access
  at any time without notice, silently breaking the integration.
- If this extension is ever submitted to Microsoft AppSource, dependency on ToS-violating
  scraping is a plausible rejection reason.
- No legal indemnification from BBB; the business running this extension bears the risk of a
  cease-and-desist or IP block.

This decision is recorded in `docs/ChangeLog.md`, **Issue DEFINE-001**. The TDD (Step 03) will
isolate the fetch mechanism behind its own module so a real API or data-feed relationship can
replace it later without touching the customer-facing fields.

## Scope

- Per-customer BBB fields, all on the Customer table (Table Extension), current-value-only
  (no history table — see Resolved Decisions):
  - **BBB Grade** (A+, A, A-, B+, B, B-, C+, C, C-, D+, D, D-, F, NR)
  - **Accreditation Status** (Yes/No)
  - **Complaint Count**
  - **BBB Profile URL** — entered manually by staff once per customer; this is the URL the
    fetch mechanism reads on every refresh.
  - **Last Fetched Date/Time** — stamped on every fetch attempt, success or failure.
  - **Fetch Status** — e.g., OK / Failed / Stale, so a failed refresh doesn't silently masquerade
    as current data.
- A manual, on-demand fetch mechanism (a page action — "Refresh BBB Data") that reads the stored
  Profile URL and scrapes the current Grade, Accreditation, and Complaint Count from it. No
  scheduled/background job in this release.
- On fetch failure (blocked request, changed page structure, unreachable URL), the prior field
  values are left untouched and **Fetch Status** is set to a failure state — never silently
  overwritten with blank/wrong data.
- Surfacing the fields on the Customer Card (or a FactBox extension of it) for Sales and
  Credit & Risk visibility.
- Making the fields available for Power BI / reporting consumption (via the standard API
  surface every OCPF-built extension exposes).

## Resolved Decisions (PRE-01, 2026-09-16, AJ Ansari)

| Question | Decision |
|---|---|
| Grade history vs. current-only | **Current value + Last Fetched Date only.** No history table in this release. |
| How the BBB Profile URL is identified | **Manually entered per customer** — no automated search/lookup. |
| Refresh cadence | **On-demand only**, via a page action. No scheduled job. |
| Fetch-failure behavior | **Keep the last known value**, and set **Fetch Status** to flag it as failed/stale — never overwrite silently. |

## Explicitly Out of Scope (this release)

- Countries other than the US and Canada.
- French Canadian (fr-CA) translation — English-only, even for Canadian customers (ChangeLog DEFINE-002).
- Customer Service as a directly named consumer.
- Historical grade-trend tracking or charting (current value only, per Resolved Decisions).
- A scheduled/background refresh job (on-demand only, per Resolved Decisions).
- Automated BBB profile lookup/search by name or address (manual URL entry only).
- Automated remediation or alerting on grade changes (e.g., workflow notifications).
- Any official/contracted BBB or BBB-reseller data integration — may replace scraping in a
  future version per the accepted-risk note above.

## Domain Vocabulary

| Term | Meaning |
|---|---|
| **BBB** | Better Business Bureau — a US/Canada nonprofit that rates and accredits businesses on trustworthiness. |
| **BBB Grade / Rating** | Letter grade BBB assigns a business: A+, A, A-, B+, B, B-, C+, C, C-, D+, D, D-, F, or NR (Not Rated). |
| **Accreditation** | Whether a business has paid for and met BBB's accreditation standards — distinct from, and not implied by, the letter grade. |
| **Complaint Count** | Number of complaints logged against the business in BBB's system. |
| **BBB Profile URL** | The public bbb.org page for the business; the source page for the fetched data. |

## Initial Entity List

| Candidate Entity | Type | Notes |
|---|---|---|
| Customer (extend) | Table Extension | New fields: BBB Grade, Accreditation Status, Complaint Count, Profile URL, Last Fetched Date/Time, Fetch Status. |
| BBB Fetch Log | Table | Records each fetch attempt (timestamp, success/failure, HTTP status/error detail) — an audit trail this framework's Operating Rules effectively require for an unofficial, fragile data source. To be confirmed at PRE-02/TDD as in-scope rather than folded into the Customer fields alone. |

No duplicate or legacy/outdated terminology identified yet — this is a new domain area for the
existing BC install (no prior "BBB"-adjacent objects expected in standard BC or prior
customizations). This will be re-checked in PRE-02's gap analysis against standard BC modules.

## Consumer Use Cases (initial)

- A sales rep opens a Customer Card and sees the BBB Grade before finalizing a deal.
- A credit analyst reviews BBB Grade + Complaint Count as one input into a credit-hold decision.
- A Power BI dashboard aggregates BBB Grade across the customer portfolio for portfolio-risk
  reporting.

## Remaining Open Item (does not block PRE-02)

- **Deployment Target** (SaaS PTE / OnPrem PTE / AppSource) — not required for DEFINE; asked
  formally at Step 01 intake.

---

# PRE-02 — Structured Gap Analysis

Run against Standards Guide Part 6 (Gap Analysis Checklist), 2026-09-16.

| Checklist category | Finding |
|---|---|
| 6.1 Analytical detail tables | N/A — no new financial/transactional ledger entity is introduced. The one new table (BBB Fetch Log) is itself an audit-trail table, not a sub-ledger of something else. |
| 6.2 Posted/archived versions | N/A — no document type (no "open" document is created that would need a posted equivalent). |
| 6.3 Reference/lookup tables | Reviewed. BBB Grade is a fixed, small value set (A+ … F, NR) — modeled as an `Enum`, not a new lookup table, so no BC reference-table gap. **Gap found and resolved:** the fetch action is restricted to customers whose Country/Region is US or Canada (see Resolved Decisions below) — surfaced the country-scope question that led to expanding this release's country scope (ChangeLog DEFINE-002). |
| 6.4 Secondary document types | N/A — no document type is in scope. |
| 6.5 Modern vs. legacy tables | N/A — no Job, Price, or other flagged legacy table is touched. |
| 6.6 Tax framework tables | N/A — confirmed not to apply; no tax data is involved in BBB grade tracking. |

## Expanded, De-duplicated Entity List

| Entity | Type/Tag | R/W Intent | Global vs. Localized |
|---|---|---|---|
| Customer (extend) | Master (Table Extension) | Read/Write — BBB Grade, Accreditation Status, Complaint Count, Profile URL are staff-editable; Last Fetched Date/Time and Fetch Status are system-written only. | Global table; the refresh action is validated to Country/Region = US or Canada only (Resolved Decisions). |
| BBB Fetch Log | Analytical (audit trail, new Table) | System-written (Insert only); Read-only to users. | Global (mechanism works the same regardless of country; in practice exercised for US/Canada customers only). |

**Gap added and why:** BBB Fetch Log was not in the original initial entity list as a firm
inclusion (it was tentative). Per Standards §5.3, the moment this project owns any table,
Permission Sets are required — carried forward as a Step 01 Parameter 1.2 input. Confirmed here
as in-scope: an unofficial, fragile scraping mechanism needs its own audit trail so failures are
diagnosable (Standards Part 6 intent: catch missing entities before the FRD is finalized — an
audit log is the "missing entity" a fetch-based integration would otherwise lack).

## Resolved Decisions (PRE-02, 2026-09-16, AJ Ansari)

| Question | Decision |
|---|---|
| Country scoping | **Restrict the refresh action to Country/Region = US or Canada.** Attempting it on any other country's customer is blocked with a clear error. This decision is what surfaced the scope question resolved in ChangeLog DEFINE-002 (Canada added to project scope). |
| Setup table | **No Setup table for v1.** No API key/credential to store and no configurable behavior requested yet. |

**PRE-02 exit gate met:** all gaps closed or explicitly deferred with reasoning. No blocking
issues remain. Sign-off below covers PRE-01 and PRE-02 together (Approvers = one person, AJ
Ansari).
