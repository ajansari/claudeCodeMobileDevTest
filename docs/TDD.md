# Technical Design Document — BBB Rating Insights

**Project:** BBB Rating Insights (Business Central SaaS Per-Tenant Extension)
**Publisher:** onlyCopilotFans
**Phase / Step:** DESIGN — Runbook Step 03
**Drafted:** 2026-09-16, by the reasoning role, from `docs/FRD.md` (signed off 2026-09-16),
`docs/ProjectParameters.md` (Step 01, confirmed), `docs/ChangeLog.md` (DEFINE-001 – DEFINE-005), and
the OCPF AL Development Standards Guide v1.9.0.0.
**Status:** Draft — awaiting Technical Lead sign-off (AJ Ansari, who holds all three approver roles;
Project Parameters §1.1). Under **Approvers = one person**, this sign-off is given once, together
with Step 04's `SanityCheck.md` (runbook Step 03 exit gate).

---

## 0. How to read this document

> **0.1 Self-sufficiency.** This TDD is written so that a developer or agent who has never seen this
> project can build every object correctly from this document alone. Every rule it applies is stated
> here; nothing requires knowledge that lives only in another document. Where it cites `FRD.md`,
> `ProjectParameters.md`, or the Standards Guide, the citation is provenance — the rule itself is
> restated here.

> **0.2 Authoritative-source rule.** Every name, ID, prefix, namespace, version, and localization
> value is read from `docs/ProjectParameters.md`. If the two ever disagree, Project Parameters wins
> and this document is corrected. Nothing in AL hardcodes a value that belongs in that sheet.

> **0.3 THE UNVERIFIED RULE — read this before writing a single line of AL.**
> This session has **no AL Language extension, no compiler, and no symbol files**, and cannot reach
> Microsoft Learn (ChangeLog **DEFINE-004**; FRD NFR-21, DR-14). Operating Rule 2 (verify against BC
> symbol files, never memory) therefore **cannot be executed here**.
>
> Consequently **every standard Business Central identifier in this document — every table number,
> page number, field name, event name, namespace, and System Application codeunit — is written with
> an inline `UNVERIFIED — confirm against local symbols` marker, every single time it appears.**
> None of them is a confirmed fact. They are *believed correct from general familiarity with BC*,
> which Operating Rule 2 explicitly states is not reliable.
>
> **Before Step 06 generates any code, AJ Ansari (or any agent with symbols available) must work
> §16's verification worksheet in the local VS Code + AL environment** and replace each marker with
> a verified value. A marker that survives into generated AL is a defect.
>
> Objects, fields, enums, and permission sets **this extension owns** are *not* marked — they are
> defined by this document and are true by construction.

---

## 1. System Identity

Every value in this table comes from `docs/ProjectParameters.md`. Derive all names from it; never
hardcode any of it anywhere else.

| Parameter | Value | Where it is used |
|---|---|---|
| Extension Name | `BBB Rating Insights` | `app.json "name"`; permission set captions; package file name |
| Publisher | `onlyCopilotFans` | `app.json "publisher"` |
| Deployment Target | `SaaS PTE` | Analyzer set (CodeCop + UICop + **PerTenantExtensionCop**, never AppSourceCop); object range rule (§5.5 of the Standards Guide) |
| Use Namespace | `Yes` | Every AL file carries exactly one `namespace` line, first in the file |
| Namespace | `OnlyCopilotFans.BBBInsights` | `namespace OnlyCopilotFans.BBBInsights;` — flat, no sub-namespaces |
| Localization | `US` | Field inclusion/exclusion (§6.6 below) |
| AL Object Prefix | `ocpfBbb` | Every object name; every field this extension adds to a standard table |
| APIPublisher | `'onlyCopilotFans'` | Both API pages (single quotes in AL) |
| APIGroup prefix | `ocpfBbb` | This project uses exactly one group: `'ocpfBbbRatings'` |
| APIVersion | `'v1.0'` | Both API pages |
| ODataKeyFields | `SystemId` | Both API pages — always, no exceptions |
| AL Runtime | `16.0` | `app.json "runtime"` |
| BC Application Minimum | `27.0.0.0` — *unverified against a live source; confirm on the target sandbox* | `app.json` dependency |
| Recommended BC Version | `27.5+` | Validation target |
| Symbol Source | **Blank** — filled in locally once symbols are downloaded (ChangeLog DEFINE-004) | §16 verification worksheet |
| Object ID range | **50601–50620** (20 IDs, single primary allocation) | §3 module allocation. No object outside it, ever (FRD DR-12). |
| Permission Set App Code | `BBBRI` | `OCPFBBB BBBRI, VIEW` / `OCPFBBB BBBRI, EDIT` |
| Feature flags | `"features": ["NoImplicitWith", "TranslationFile"]` | `app.json`. `NoImplicitWith` is framework-fixed; `TranslationFile` stays on even though this project ships no `.xlf` (§10.1). |

### 1.1 Quoting reference (applies to every file in the project)

| Context | Quote style | Example from this project |
|---|---|---|
| `app.json` / `launch.json` values | JSON strings | `"publisher": "onlyCopilotFans"` |
| AL string property values | Single quotes | `APIPublisher = 'onlyCopilotFans';` |
| AL object names | Double quotes | `page 50613 "ocpfBbbCustomerRatings"` |
| BC source field names containing spaces or dots | Double quotes on the field name | `Rec."Country/Region Code"` |

### 1.2 Object-naming convention used throughout this document

- **Object names:** `ocpfBbb` + PascalCase descriptor, no spaces — `ocpfBbbFetchLog`,
  `ocpfBbbRatingMgt`, `ocpfBbbCustomerRatings`. This carries the FRD §9 indicative names forward
  unchanged, so FRD ↔ TDD ↔ Object Register traceability is one-to-one.
- **Permission set names** are the exception, fixed by Standards §5.4 and Project Parameters §1.3:
  `OCPFBBB BBBRI, VIEW` / `OCPFBBB BBBRI, EDIT` (prefix uppercase, App Code, role word).
- **Fields this extension adds to a standard BC table** are prefixed in their *technical* name
  (`"ocpfBbb Grade"`) and plain in their *caption* (`Caption = 'BBB Grade';`). The prefix is what
  keeps this extension from colliding with another extension that also extends the customer record
  (FRD §4.2); the caption is what the user reads.
- **Fields in tables this extension owns** carry **no** prefix (`"Entry No."`, `"Customer No."`) —
  the table name already carries it, and BC's own convention for owned tables is unprefixed fields.
- **API identifiers** (`APIPublisher`, `APIGroup`, `EntityName`, `EntitySetName`, every field
  identifier on an API page) are camelCase — letters and digits only, first letter lowercase, each
  later word capitalized, no underscores (Standards §2.7; CodeCop **AA0101**).
- **File names** follow Standards §1.8 exactly: object name stripped to `A–Za–z0–9`, a dot, the
  object type, `.al` (CodeCop **AA0215**). The full list is §14.

---

## 2. What is being built, in one page

A user on the customer card presses **Refresh BBB Data**. The extension checks three preconditions,
reads the customer's own BBB profile page, and writes back a grade, an accreditation flag, and a
complaint count — or, on any failure, leaves those three values exactly as they were and records
what went wrong. Every attempt stamps the customer record and inserts one audit-log row. Two API
pages expose the same data to Power BI. Two permission sets separate "can see it" (Sales) from
"can maintain and refresh it" (Credit & Risk).

**The five design rules that shape almost every technical decision below** (restated from FRD §5 so
this document stands alone):

| Rule | What it forces in this design |
|---|---|
| **DR-1** — a failed refresh never overwrites good data | The three retrieved values are written **only** inside the success branch (§7.2 step 7). A failure path that touches them is a defect. |
| **DR-2** — every attempt is stamped and logged | `ocpfBbb Last Fetched` + `ocpfBbb Fetch Status` are written on **both** branches, and one `ocpfBbbFetchLog` row is inserted on both. |
| **DR-3 / NFR-2** — the retrieval mechanism is swappable | An **interface** (`ocpfBbbRatingProvider`) sits between orchestration and retrieval. Exactly one line in the whole extension names the concrete provider (§7.1). |
| **DR-4 / FR-5** — refresh is US/CA only, blank refused | Precondition 3, §7.2 step 2c, resolved against the Country/Region record's ISO code, not a raw string guess. |
| **DR-6** — retrieved values are system-owned; the URL is user-owned | `Editable = false` on five fields at **both** table and page level; the URL alone is writable. |

---

## 3. Module Grouping and Object ID Allocation

### 3.1 Modules (Standards §5.1 — group first, allocate second)

Five cohesive modules. Each gets a **contiguous** sub-block. Nothing is scattered.

| Module | What belongs in it | Why it is its own module |
|---|---|---|
| **M1 — Core Data** | The two enums, the audit table, the customer table extension | The persistent shape of the feature. Everything else depends on it and it depends on nothing of ours. |
| **M2 — Retrieval & Logic** | Orchestration codeunit, provider codeunit, subscriber codeunit, the provider interface | Where the DR-3 isolation boundary lives. Contained here so a source swap never reaches outside this block. |
| **M3 — User Interface** | Customer Card page extension, Fetch Log list page | The BC-client surface. Separated so a UI change never touches logic IDs. |
| **M4 — Integration (API)** | The two API pages | The published contract (endpoint URLs derive from these names). Isolated because renaming anything here breaks consumers. |
| **M5 — Security** | The two permission sets | Deliverables, not afterthoughts (Standards §5.3). |

### 3.2 ID allocation — 50601–50620

| Block | IDs | Size | Allocated | Reserved (growth) | Buffer |
|---|---|---|---|---|---|
| **M1 — Core Data** | 50601–50605 | 5 | 4 | **50605** | 20% |
| **M2 — Retrieval & Logic** | 50606–50609 | 4 | 3 | **50609** | 25% |
| **M3 — User Interface** | 50610–50612 | 3 | 2 | **50612** | 33% |
| **M4 — Integration (API)** | 50613–50615 | 3 | 2 | **50615** | 33% |
| **M5 — Security** | 50616–50617 | 2 | 2 | — (draws on the tail) | 0% — see §3.4 |
| **Tail block — cross-module** | **50618–50620** | 3 | 0 | **50618, 50619, 50620** | 100% |
| **Total** | 50601–50620 | 20 | **13** | **7** | **35%** |

### 3.3 The assignments

| ID | Type | Object name | Module | Entity (FRD §9) |
|---|---|---|---|---|
| 50601 | enum | `ocpfBbbGrade` | M1 | E-3 |
| 50602 | enum | `ocpfBbbFetchStatus` | M1 | E-4 |
| 50603 | table | `ocpfBbbFetchLog` | M1 | E-2 |
| 50604 | tableextension | `ocpfBbbCustomerExt` | M1 | E-1 |
| 50605 | *(reserved)* | — | M1 | — |
| 50606 | codeunit | `ocpfBbbRatingMgt` | M2 | E-8 |
| 50607 | codeunit | `ocpfBbbProfileReader` | M2 | E-9 |
| 50608 | codeunit | `ocpfBbbCustomerSubscribers` | M2 | *new — see §3.5* |
| 50609 | *(reserved)* | — | M2 | — |
| 50610 | pageextension | `ocpfBbbCustomerCardExt` | M3 | E-5 |
| 50611 | page (List) | `ocpfBbbFetchLogList` | M3 | E-7 |
| 50612 | *(reserved — the ID E-6 would have used)* | — | M3 | E-6, not built (§3.6) |
| 50613 | page (API) | `ocpfBbbCustomerRatings` | M4 | E-10 |
| 50614 | page (API) | `ocpfBbbFetchLogEntries` | M4 | E-11 |
| 50615 | *(reserved)* | — | M4 | — |
| 50616 | permissionset | `OCPFBBB BBBRI, VIEW` | M5 | E-12 |
| 50617 | permissionset | `OCPFBBB BBBRI, EDIT` | M5 | E-13 |
| 50618–50620 | *(tail block, reserved)* | — | cross-module | — |

**`interface "ocpfBbbRatingProvider"`** (M2) is also built. **AL interfaces carry no object ID**, so
it consumes none of the range. It is registered in the Object Register with `—` as its ID.

### 3.4 Two honest notes on the buffer

1. **M5 has no in-block buffer.** Two permission sets fill a two-ID block exactly. A third set (a
   future `OCPFBBB BBBRI, ADMIN`) draws from the **tail block**, not from a neighbouring module.
   This is deliberate: permission sets are the least likely objects in this extension to multiply.
2. **Standards §5.2's "up to 50 objects → 10 IDs reserved" is not fully met, and cannot be.** The
   allocated range is 20 IDs; 13 objects leaves 7. The runbook's own per-module rule (≥20%
   unallocated) **is** met for M1–M4, and the overall buffer is 35%. **Flagged for Step 04:** a v2
   that adds more than 7 objects (for example a Customer List extension, a setup table, an upgrade
   codeunit, a job-queue refresh) needs an *additional* allocation recorded in Project Parameters
   §1.2 — it must not borrow IDs from outside 50601–50620.

### 3.5 Why there is a codeunit the FRD did not list (`ocpfBbbCustomerSubscribers`, 50608)

FRD NFR-15 / ChangeLog **OQ-6** require Fetch Log entries to **cascade-delete when their customer is
deleted**. A table this extension owns cannot get that behavior from a `TableRelation` — BC's
cascade-delete is a property of the *parent* table's relations, and we do not modify standard tables
(DR-13). The supported mechanism is an **event subscriber on the Customer table's delete trigger**,
and Standards §10.1 requires subscribers to live in a codeunit that exists for that purpose, never
scattered through business logic. Hence one more codeunit than FRD §9 listed. **This is a delivery
mechanic for an existing FRD requirement, not new scope** — no ChangeLog deviation entry is owed,
but the Object Register records it and Step 08's gap-fit will see it as *built but not in the FRD →
gap fill, accounted for here*.

### 3.6 E-6 (the FactBox): **not built** — decided here

FRD E-6 was explicitly conditional ("the TDD picks one"). **Decision: no FactBox page. FR-6 is
satisfied by an inline group on the Customer Card page extension (50610).**

Reasoning:
- **FR-6a needs an editable field.** The BBB Profile URL must be maintainable on the customer record
  by a Credit & Risk user. A FactBox (`PageType = CardPart`) is a display surface; putting the one
  editable field of the feature into it, while the read-only fields sit beside it, splits one
  coherent group across two objects for no gain.
- **FR-6's actual requirement is "visible together, with the freshness stamp beside the values."** A
  single named group on the card delivers exactly that, in one object, with the refresh action
  adjacent.
- **A FactBox is collapsible and frequently collapsed by users**, which works against BO-4 (never
  let stale data masquerade as current) — the fetch status must be hard to miss, not one click away.
- **DR-9 keeps the surface minimal**, and one fewer object is one fewer object to permission,
  document, and test.
- **The ID is not spent.** 50612 stays reserved in M3. If AJ Ansari later prefers a FactBox, it is
  built at 50612 with no renumbering anywhere.

---

## 4. Batch / Phase Plan

Smallest and simplest first (Operating Rule 3). Each batch is independently correct and reviewable.
**No batch is compiled on its own** — the whole extension compiles once at Step 07 (Operating Rule
4); each batch gets the Step 05 pre-flight (both passes) before the next begins.

| Batch | Contents | Why this order |
|---|---|---|
| **B1 — Core Data** | `app.json` scaffold check, 50601 `ocpfBbbGrade`, 50602 `ocpfBbbFetchStatus`, 50603 `ocpfBbbFetchLog`, 50604 `ocpfBbbCustomerExt`, **plus the two permission sets created with their `tabledata` grants** | Enums are the simplest objects in the project and everything else references them. **Standards §5.3: every table's `tabledata` grant ships in the same batch that introduces the table** — so the permission sets are *created* here, carrying only their `tabledata` lines, and are amended in B2–B4 as objects appear. |
| **B2 — Retrieval & Logic** | `interface "ocpfBbbRatingProvider"`, 50606 `ocpfBbbRatingMgt`, 50607 `ocpfBbbProfileReader`, 50608 `ocpfBbbCustomerSubscribers`; permission sets amended with codeunit `X` | Depends on B1's enums and table. Contains every UNVERIFIED standard-BC reference in the project except the two page anchors, so it is the batch §16's worksheet gates most tightly. |
| **B3 — User Interface** | 50610 `ocpfBbbCustomerCardExt`, 50611 `ocpfBbbFetchLogList`; permission sets amended with page `X` | Depends on B1 (fields) and B2 (the action calls `ocpfBbbRatingMgt`). |
| **B4 — Integration (API)** | 50613 `ocpfBbbCustomerRatings`, 50614 `ocpfBbbFetchLogEntries`; permission sets **finalized** | Last because the API pages are the published contract: their field list should be settled only after the data shape has survived the UI batch. |

**Batch exit condition (all four):** the Step 05 post-generation pass is clean — including the
symbol verification of every UNVERIFIED marker that batch touches — before the next batch starts.

---

## 5. The Standard Object Template (Standards §1.3), instantiated for this project

Every API page in this project is generated from this template, substituting only values from §1.
No property, trigger, or code block is added that this template does not show unless this document's
per-object spec says so.

```al
namespace OnlyCopilotFans.BBBInsights;

using Microsoft.Sales.Customer;   // UNVERIFIED — confirm the exact namespace against local symbols

page <ObjectID> "<EntitySetName>"
{
    PageType = API;
    Caption = '<Complete sentence describing what this entity represents.>';
    APIPublisher = 'onlyCopilotFans';
    APIGroup = 'ocpfBbbRatings';
    APIVersion = 'v1.0';
    EntityName = '<entityNameSingular>';
    EntitySetName = '<entitySetNamePlural>';
    EntityCaption = '<Human-readable singular name>';    // translatable objects only (§8.6) — see §11
    EntitySetCaption = '<Human-readable plural name>';   // translatable objects only (§8.6) — see §11
    SourceTable = <SourceTableName>;
    ODataKeyFields = SystemId;
    DelayedInsert = true;    // editable pages ONLY. Read-only pages use "Editable = false;" instead.

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(systemId; Rec.SystemId)
                {
                    Caption = 'System ID';
                    ToolTip = 'Unique system-assigned identifier for this record. Used as the OData key.';
                    ApplicationArea = All;
                }
                field(<camelCaseIdentifier>; Rec."<Source Field Name>")
                {
                    Caption = '<Human-readable label>';
                    ToolTip = '<Specifies the ... sentence.>';
                    ApplicationArea = All;
                }
            }
        }
    }
}
```

**Non-negotiables this template encodes** (each is also a Step 05 pre-flight check):

1. **Exactly one** of `DelayedInsert = true` / `Editable = false` per page. Never both, never
   neither (Standards §2.2, Part 7).
2. `ODataKeyFields = SystemId` on every API page. Never a business key.
3. `Caption`, `ToolTip`, and `ApplicationArea = All` on **every** field. No exceptions (Standards
   §1.4).
4. The page `Caption` is a **complete sentence** — it becomes the entity description in `$metadata`
   (Standards §2.5). `Caption = 'BBB Ratings';` is a defect; see §7.5 and §7.6 for the real ones.
5. ToolTips are written for an API consumer reading the schema, not just a UI user (Standards §2.6).
6. Every field source reference is `Rec.`-qualified — `NoImplicitWith` is enforced (Standards §1.2).
7. 4-space indentation per level, spaces only, never tabs (Standards §1.6).
8. `namespace OnlyCopilotFans.BBBInsights;` first line of every file; one flat namespace, no
   sub-namespaces.

---

## 6. Per-Object Specification

Read §6 with §7 (field specs) and §8 (`using` directives). Object names, IDs, and file names are
fixed here and must match `docs/ObjectRegister.md` exactly.

### 6.1 `enum 50601 "ocpfBbbGrade"` — M1, Batch B1

| Property | Value |
|---|---|
| Caption | `'BBB Grade'` |
| Extensible | `false` |
| File | `ocpfBbbGrade.Enum.al` |

**Why `Extensible = false`:** the value set is BBB's, not ours. A subscriber adding a grade BBB does
not issue would put a value in the field that the provider can never legitimately produce and that
no report could interpret. Recorded decision, not a default.

| Ordinal | Value name | Caption | Notes |
|---|---|---|---|
| 0 | `NotFetched` | `'Not Fetched'` | **FR-1's distinct "no value yet" state.** Ordinal 0 is the default for every existing and new customer, which is why this design needs no upgrade/backfill code (§12). |
| 1 | `APlus` | `'A+'` | Value names carry no `+`/`-` (invalid AL identifier characters); the caption carries the real grade. |
| 2 | `A` | `'A'` | |
| 3 | `AMinus` | `'A-'` | |
| 4 | `BPlus` | `'B+'` | |
| 5 | `B` | `'B'` | |
| 6 | `BMinus` | `'B-'` | |
| 7 | `CPlus` | `'C+'` | |
| 8 | `C` | `'C'` | |
| 9 | `CMinus` | `'C-'` | |
| 10 | `DPlus` | `'D+'` | |
| 11 | `D` | `'D'` | |
| 12 | `DMinus` | `'D-'` | |
| 13 | `F` | `'F'` | |
| 14 | `NR` | `'NR (Not Rated)'` | **BBB's own "Not Rated"** — a *fetched* fact, deliberately distinct from ordinal 0 (FR-1, NFR-11). |

**There is deliberately no `Unknown` / `Unrecognized` member.** If the provider reads a grade string
it cannot map, that is a **parse failure**, not a grade — DR-1 then applies and the stored grade is
left untouched. A catch-all member would silently overwrite good data with "we don't know", which is
exactly the failure mode DR-1 exists to prevent.

> **API serialization note (recorded decision, carried to Step 11).** OData serializes an enum by
> its **value name**, so `$select=ocpfBbbGrade` returns `"APlus"`, not `"A+"`. v1 exposes no second
> "display grade" field: it would be stored, denormalized data whose only job is presentation, and
> DR-8 keeps this extension to current values only. **`Documentation.md` (Step 11) must publish the
> ordinal → name → display-grade mapping table** so a Power BI author can map it once. See OD-2.

### 6.2 `enum 50602 "ocpfBbbFetchStatus"` — M1, Batch B1

| Property | Value |
|---|---|
| Caption | `'BBB Fetch Status'` |
| Extensible | `false` |
| File | `ocpfBbbFetchStatus.Enum.al` |

| Ordinal | Value name | Caption | Notes |
|---|---|---|---|
| 0 | `NeverFetched` | `'Never Fetched'` | Default for every customer. Never appears on a log row (§6.3). |
| 1 | `Succeeded` | `'Succeeded'` | FR-3. |
| 2 | `Failed` | `'Failed'` | FR-4 — the values displayed beside it are **last known good**, not current. |

**`Stale` is deliberately not a member, although FR-1 listed it as an example.** Nothing in this
extension could ever set it: there is no scheduled job, no background session, and NFR-7 forbids any
work at display time. A stored status that no code path can ever write is dead metadata that makes
the enum lie. **Staleness is derived, not stored** — by the reader, from `ocpfBbb Last Fetched`
(the card shows the stamp beside the status; a Power BI model computes age from the same field).
Recorded decision for Step 04's review; FR-1's list was explicitly an "e.g.", so this is a
resolution, not a deviation.

### 6.3 `table 50603 "ocpfBbbFetchLog"` — M1, Batch B1

| Property | Value |
|---|---|
| Caption | `'BBB Fetch Log'` |
| DataClassification (object) | `CustomerContent` |
| DrillDownPageId / LookupPageId | `"ocpfBbbFetchLogList"` (50611) |
| File | `ocpfBbbFetchLog.Table.al` |

**Mutability (Standards §2.2): audit / system table → read-only to users.** Rows are inserted by
`ocpfBbbRatingMgt` and are never edited (DR-6, FR-8). The list page and the API page both set
`Editable = false`.

| Field ID | Field name | Type | Properties | Notes |
|---|---|---|---|---|
| 1 | `"Entry No."` | Integer | `AutoIncrement = true`; `DataClassification = SystemMetadata`; primary key | |
| 2 | `"Customer No."` | Code[20] | `TableRelation = Customer` *(table 18 — **UNVERIFIED, confirm against local symbols**)*; `DataClassification = CustomerContent` | Human-filterable link (FR-9). Kept in step with a customer rename by the subscriber in §6.8. |
| 3 | `"Customer SystemId"` | Guid | `DataClassification = SystemMetadata` | The **stable** link: survives a customer number rename, and is what an API consumer joins on (Standards §2.1's reasoning applied to a foreign key). |
| 4 | `"Attempted At"` | DateTime | `DataClassification = SystemMetadata` | Set explicitly by the orchestrator. Not the same thing as the platform's `SystemCreatedAt`: this one is part of the published API contract and is filterable by design. |
| 5 | `"Outcome"` | Enum `ocpfBbbFetchStatus` | `DataClassification = SystemMetadata` | Only `Succeeded` (1) or `Failed` (2) is ever written here. `NeverFetched` (0) is meaningless on a log row and never occurs — documented rather than modelled as a third enum, which would have cost an object ID for no behavior. |
| 6 | `"Failure Reason"` | Text[250] | `DataClassification = SystemMetadata` | Business-readable reason (the same label text the user was shown — §10.2), truncated to 250 with `CopyStr`. Blank on success. |
| 7 | `"HTTP Status Code"` | Integer | `DataClassification = SystemMetadata` | Diagnostic only. **Never shown to a user** (NFR-9) — it lives here so UC-6 can tell a 404 from a 403 from a timeout. `0` when no response was received. |
| 8 | `"Profile URL Used"` | Text[250] | `DataClassification = CustomerContent` | Which page was actually read, at the time it was read (DR-5 traceability — the URL on the customer may have changed since). |
| 9 | `"Duration (ms)"` | Integer | `DataClassification = SystemMetadata` | Round-trip duration. The evidence that distinguishes "BBB is slow" from "BBB is blocking us" (NFR-6 timeouts). |

**Keys**
- Primary: `"Entry No."`
- Secondary: `key(CustomerAttempt; "Customer No.", "Attempted At")` — FR-9's "filtered to a customer,
  newest first". Add `"Outcome"` to this key only if Step 12 testing shows failure-only filtering is
  slow; do not pre-optimize.

**Deliberately NOT stored on the log — this is load-bearing, not an omission.** The retrieved grade,
accreditation flag, and complaint count are **not** written to log rows. Storing them per attempt
would make this table a grade history, which **DR-8 forbids** ("the audit log records *attempts*,
not a time series of grades, and must never be presented or documented as one"). A reviewer who
"helpfully" adds a `Grade Retrieved` field has changed the FRD and needs its own approval.

**Also not stored:** any explicit user-id field. The platform's `SystemCreatedBy` already records
who ran the attempt, and NFR-12 says log nothing beyond what diagnosis needs.

**Deletion behavior (FRD NFR-15 / OQ-6): cascade with the customer** — implemented in §6.8.
**Retention (FR-10 / OQ-5): none. No purge, no cap, ever, in v1.** See §13.3 for the volume note.

### 6.4 `tableextension 50604 "ocpfBbbCustomerExt" extends Customer` — M1, Batch B1

Extends **Customer — table 18 — UNVERIFIED, confirm against local symbols.**

| Property | Value |
|---|---|
| File | `ocpfBbbCustomerExt.TableExt.al` |
| `using` | `Microsoft.Sales.Customer;` — **UNVERIFIED, confirm against local symbols** |

**Field IDs come from this extension's own object range** — AL requires extension fields on a
standard table to use IDs inside the allocated range, and 50601–50620 is exclusively ours, so no
collision with another extension is possible.

| Field ID | Field name | Type | Editable | DataClassification | Owner |
|---|---|---|---|---|---|
| 50601 | `"ocpfBbb Grade"` | Enum `ocpfBbbGrade` | **`false`** | `CustomerContent` | System (DR-6) |
| 50602 | `"ocpfBbb Accredited"` | Boolean | **`false`** | `CustomerContent` | System (DR-6) |
| 50603 | `"ocpfBbb Complaint Count"` | Integer | **`false`** | `CustomerContent` | System (DR-6) |
| 50604 | `"ocpfBbb Profile URL"` | Text[250] | `true` (default) | `CustomerContent` | **Staff (DR-5, FR-6a)** |
| 50605 | `"ocpfBbb Last Fetched"` | DateTime | **`false`** | `CustomerContent` | System (DR-2) |
| 50606 | `"ocpfBbb Fetch Status"` | Enum `ocpfBbbFetchStatus` | **`false`** | `CustomerContent` | System (DR-2) |

**`Editable = false` and what it does and does not do.** It blocks edits from the UI and from OData,
which is exactly DR-6's intent. It does **not** block AL code: `ocpfBbbRatingMgt` still writes these
fields normally. The same `Editable = false` is repeated on the API page fields (§7.5) — belt and
braces, because the page-level property is what an OData client actually meets.

**`"ocpfBbb Profile URL"` extra properties**
- `ExtendedDatatype = URL;` — makes the card render it as a clickable link (FR-6a: "presented so it
  can be opened in a browser").
- `OnValidate` — one rule only:
  ```al
  trigger OnValidate()
  begin
      if (Rec."ocpfBbb Profile URL" <> '') and
         (StrPos(LowerCase(Rec."ocpfBbb Profile URL"), HttpsPrefixTok) <> 1) then
          Error(ProfileUrlNotHttpsErr);
  end;
  ```
  **Why only this rule.** A scheme check is a security rule — this extension must never make a
  plaintext call. The *host* is deliberately not validated: **DR-5 says the URL is staff-entered and
  staff-owned**, and a hardcoded `bbb.org` host check would be this extension quietly deciding what
  a valid BBB page is. Labels: §10.2.
- **No `OnValidate` that clears the retrieved values when the URL changes.** Tempting, and wrong:
  clearing them is an overwrite of good data by something that is not a successful fetch, which
  DR-1 forbids. The stale-but-stamped values stay until a refresh replaces them; `ocpfBbb Last
  Fetched` tells the reader how old they are.

**Data classification (NFR-12):** all six are `CustomerContent`. The values are publicly published
information *about a business*, not personal data — but they are business-customer data held in BC,
and `CustomerContent` is the honest classification. No field here is `EndUserIdentifiableInformation`.

### 6.5 `pageextension 50610 "ocpfBbbCustomerCardExt" extends "Customer Card"` — M3, Batch B3

Extends **Customer Card — page 21 — UNVERIFIED, confirm against local symbols.**

| Property | Value |
|---|---|
| File | `ocpfBbbCustomerCardExt.PageExt.al` |
| `using` | `Microsoft.Sales.Customer;` — **UNVERIFIED, confirm against local symbols** |

**Layout.** One new group, added last in the content area:

```al
layout
{
    addlast(content)          // anchor UNVERIFIED — confirm the Customer Card's control tree against local symbols
    {
        group(ocpfBbbRatingGroup)
        {
            Caption = 'BBB Rating Insights';
            field(ocpfBbbGrade; Rec."ocpfBbb Grade")            { Editable = false; ApplicationArea = All; ToolTip = '...'; }
            field(ocpfBbbAccredited; Rec."ocpfBbb Accredited")  { Editable = false; ApplicationArea = All; ToolTip = '...'; }
            field(ocpfBbbComplaintCount; Rec."ocpfBbb Complaint Count") { Editable = false; ApplicationArea = All; ToolTip = '...'; }
            field(ocpfBbbProfileUrl; Rec."ocpfBbb Profile URL") { ApplicationArea = All; ToolTip = '...'; }
            field(ocpfBbbLastFetched; Rec."ocpfBbb Last Fetched") { Editable = false; ApplicationArea = All; ToolTip = '...'; }
            field(ocpfBbbFetchStatus; Rec."ocpfBbb Fetch Status") { Editable = false; ApplicationArea = All; ToolTip = '...'; }
        }
    }
}
```

- **Field order is the requirement, not decoration:** grade, accreditation, and complaint count
  first (the decision inputs — UC-1, UC-2), then the URL, then **the freshness pair last and
  together** — FR-6 requires the stamp beside the values, and BO-4 depends on the reader seeing
  `Failed` without hunting for it.
- ToolTips are the full self-describing sentences in §7.4 — **NFR-10 specifically calls out that
  "grade" vs. "accreditation" must be clear from the tooltip alone.**
- `Caption` on the group is `'BBB Rating Insights'`, matching the extension name so a user can
  connect what they see to what an admin installed.

**Actions.**

| Action | Caption | Behavior |
|---|---|---|
| `ocpfBbbRefreshRating` | `'Refresh BBB Data'` | `Image = Refresh;` `ApplicationArea = All;` promoted (`Promoted = true; PromotedCategory = Process; PromotedOnly = true;` — *promotion property shape UNVERIFIED for this BC version's page-extension syntax; confirm against local symbols*). `OnAction` calls `RatingMgt.RefreshRating(Rec);` and nothing else — no logic in the page. |
| `ocpfBbbShowFetchLog` | `'BBB Fetch Log'` | Opens page 50611 filtered to `Rec."No."` *(field `"No."` on Customer — **UNVERIFIED, confirm against local symbols**)`. `Image = Log;` `ApplicationArea = All;` Supports UC-6 from where the problem is noticed. Available to VIEW holders too — it is read-only. |

**Permission gating of the refresh action (resolves OQ-4 at the UI).**

```al
var
    RefreshAllowed: Boolean;

trigger OnOpenPage()
var
    FetchLog: Record "ocpfBbbFetchLog";
begin
    RefreshAllowed := FetchLog.WritePermission();
end;
```
…with `Enabled = RefreshAllowed;` on the refresh action.

**Why this test and not something cleverer.** Every successful *and* failed refresh must insert a
Fetch Log row (DR-2), so write permission on `ocpfBbbFetchLog` is precisely the permission a
refresh needs. `OCPFBBB BBBRI, VIEW` grants `R`; `OCPFBBB BBBRI, EDIT` grants `RIMD` (§9). A Sales
user therefore sees the data and a greyed-out action instead of a permission error — NFR-9. The
orchestrator **re-checks the same condition server-side** (§7.2 step 1) so the rule holds for any
caller, not just this page.

### 6.6 `page 50611 "ocpfBbbFetchLogList"` — M3, Batch B3

| Property | Value |
|---|---|
| PageType | `List` |
| SourceTable | `"ocpfBbbFetchLog"` (50603) |
| Caption | `'BBB Fetch Log'` |
| Editable | `false` |
| InsertAllowed / ModifyAllowed / DeleteAllowed | `false` / `false` / `false` |
| SourceTableView | `sorting("Entry No.") order(descending)` — newest attempt first, which is the only order a diagnostician wants |
| UsageCategory / ApplicationArea (page level) | **deliberately omitted** |
| File | `ocpfBbbFetchLogList.Page.al` |

**Why no `UsageCategory`:** setting it publishes the page into Tell Me / role-explorer search, and
**DR-9 forbids any Departments or Tell Me placement in v1**. The page is reached from the Customer
Card action (§6.5) and by drill-down from the table. Every *field* on it still carries
`ApplicationArea = All` (Standards §1.4).

Columns, in order: `"Attempted At"`, `"Customer No."`, `"Outcome"`, `"Failure Reason"`,
`"HTTP Status Code"`, `"Duration (ms)"`, `"Profile URL Used"`. All read-only; each with `Caption`,
`ToolTip`, `ApplicationArea = All`.

### 6.7 `codeunit 50606 "ocpfBbbRatingMgt"` — M2, Batch B2

The orchestrator. **It contains no knowledge whatsoever of how BBB data is obtained** (DR-3) — it
talks only to the interface. Full flow in §7.2.

| Property | Value |
|---|---|
| Caption | `'BBB Rating Management'` |
| File | `ocpfBbbRatingMgt.Codeunit.al` |
| `using` | `Microsoft.Sales.Customer;` and `Microsoft.Foundation.Address;` — **both UNVERIFIED, confirm against local symbols.** See §8.1 on the two-`using` note. |

**Public surface (the contract other objects may call):**

| Procedure | Signature | Purpose |
|---|---|---|
| `RefreshRating` | `procedure RefreshRating(var Cust: Record Customer)` *(Customer — **UNVERIFIED**)* | FR-2. The single entry point. Called by the card action and by nothing else in v1. |
| `IsRefreshAllowedForCountry` | `procedure IsRefreshAllowedForCountry(Cust: Record Customer): Boolean` *(Customer — **UNVERIFIED**)* | DR-4's rule, exposed so the UI (or a future list page) can pre-test without triggering an attempt. |
| `OnAfterRefreshRatingAttempt` | integration event — §13.2 | The extension's single published extension point. |

Internal helpers are `local procedure`: `CheckPreconditions`, `ResolveCountryIso`,
`ApplySuccess`, `ApplyFailure`, `WriteLogEntry`.

### 6.8 `codeunit 50608 "ocpfBbbCustomerSubscribers"` — M2, Batch B2

| Property | Value |
|---|---|
| Caption | `'BBB Customer Subscribers'` |
| `Permissions` | `tabledata "ocpfBbbFetchLog" = RIMD;` |
| File | `ocpfBbbCustomerSubscribers.Codeunit.al` |
| `using` | `Microsoft.Sales.Customer;` — **UNVERIFIED, confirm against local symbols** |

Named for what it listens to, per Standards §10.1. Two subscribers, both `local procedure`, both
doing one thing and returning, neither raising UI.

| Subscriber | Attribute | What it does |
|---|---|---|
| Cascade delete (OQ-6) | `[EventSubscriber(ObjectType::Table, Database::Customer, 'OnAfterDeleteEvent', '', false, false)]` — **event name, object, and parameter list all UNVERIFIED; confirm against local symbols** | `FetchLog.SetRange("Customer No.", Rec."No.");` *(field `"No."` — **UNVERIFIED**)* then `FetchLog.DeleteAll(false);` |
| Rename follow-through | `[EventSubscriber(ObjectType::Table, Database::Customer, 'OnAfterRenameEvent', '', false, false)]` — **UNVERIFIED, confirm against local symbols** | Re-points existing log rows from `xRec."No."` to `Rec."No."` so FR-9's "filtered to a customer" keeps working after a customer number change. `"Customer SystemId"` needs no maintenance — it never changes, which is why it exists (§6.3 field 3). |

**Standards §10.1 details that must not be lost in generation:**
- For a **table** event the object is `Database::Customer`, **never** `Table::Customer`.
- The fourth argument (`ElementName`) is `''` here — it is required only for validate-trigger events.
  A wrong value there makes the subscriber **silently never run**, and the compiler does not catch
  it, so §16 verifies these two attributes character by character.
- No `Message`, `Confirm`, or page call inside either subscriber — a customer delete can happen in a
  web-service or background session.

**The `Permissions` property is why a Sales user can still delete a customer.** `OCPFBBB BBBRI,
VIEW` grants only `R` on `ocpfBbbFetchLog`; without the codeunit-level grant the cascade would fail
with a permission error on an operation the user is otherwise entitled to perform. **Step 12 must
test customer deletion under *both* permission sets** (§9.4).

### 6.9 `interface "ocpfBbbRatingProvider"` — M2, Batch B2 — **no object ID**

**This is DR-3 / NFR-2 made structural rather than aspirational.** See §7.1 for the full contract
and the swap procedure.

| Property | Value |
|---|---|
| File | `ocpfBbbRatingProvider.Interface.al` |
| `using` | none |

```al
namespace OnlyCopilotFans.BBBInsights;

interface "ocpfBbbRatingProvider"
{
    /// <summary>
    /// Attempts to obtain BBB rating data for one business profile.
    /// Returns true only when every out-parameter below holds a value actually read from the source.
    /// An implementation must never raise an Error: a failure is a false return plus a reason.
    /// </summary>
    procedure TryGetRating(ProfileUrl: Text; var Grade: Enum "ocpfBbbGrade"; var Accredited: Boolean; var ComplaintCount: Integer; var FailureReason: Text; var HttpStatusCode: Integer; var DurationMs: Integer): Boolean
}
```

### 6.10 `codeunit 50607 "ocpfBbbProfileReader"` — M2, Batch B2

**The replaceable component. The only object in this extension that knows BBB exists as a website.**

| Property | Value |
|---|---|
| Caption | `'BBB Profile Reader'` |
| Implements | `"ocpfBbbRatingProvider"` |
| File | `ocpfBbbProfileReader.Codeunit.al` |
| `using` | `System.Utilities;` for `HttpClient`/`HttpResponseMessage` handling helpers **if required** — **UNVERIFIED; `HttpClient` may be a platform type needing no `using`. Confirm against local symbols.** |

**Responsibilities — all of them, and nothing else:**
1. Issue exactly **one** HTTPS GET to `ProfileUrl`. No retry, no follow-on request, no bulk loop
   (NFR-3 — considerate retrieval, and the behavior a reasonable operator can defend).
2. Bound the call with a timeout (NFR-6). `HttpClient.Timeout := 20000;` (20 s) — a timeout is an
   ordinary failure under FR-4, not an exception.
3. Set a truthful, identifying `User-Agent` from `UserAgentTok` (§10.2).
4. Map the response to the interface's out-parameters (§7.3's parse contract).
5. Return `false` with a business-readable `FailureReason` for **everything** that is not a clean,
   fully-parsed success — including a response that arrives but cannot be interpreted.

**Responsibilities it must never take on:** writing to any table, showing any message, deciding
whether a refresh is allowed, or knowing what a Customer is. Its only input is a URL string. If a
future change makes it touch `Record Customer`, DR-3 has been broken.

**Two platform constraints that shape the implementation (both UNVERIFIED — confirm on the sandbox
before B2 is generated):**
- **AL has no HTML DOM parser** (FRD PA-4). Interpretation is text/pattern matching over the
  response body, optionally via the System Application's `Regex` codeunit *(namespace believed
  `System.Text` — **UNVERIFIED, confirm against local symbols**)*. This is the most brittle part of
  the extension and the reason FR-4 and the log exist.
- **Business Central does not permit an outbound HTTP call after a write in the same transaction.**
  The orchestration in §7.2 therefore performs the whole fetch **before** its first database write,
  and never issues a `Commit` inside the action. *(Behavior — **UNVERIFIED**; confirm on the sandbox.
  If it proves wrong, the ordering in §7.2 is still correct and costs nothing.)*
- **Outbound calls must be enabled for this extension on the tenant** ("Allow HttpClient Requests"
  in Extension Management — FRD PA-3 / **OQ-7, still open**). When calls are blocked, the provider
  must return `false` with `CallNotAllowedReasonTxt`, not an unhandled error (§10.2), and
  `Deployment.md` must tell the administrator to switch it on. *Whether a manifest property can
  declare this is **UNVERIFIED** — do not assume one exists.*

### 6.11 `page 50613 "ocpfBbbCustomerRatings"` — API — M4, Batch B4

| Property | Value | Source of the rule |
|---|---|---|
| PageType | `API` | |
| SourceTable | `Customer` — **table 18 — UNVERIFIED, confirm against local symbols** | FRD E-10 |
| APIPublisher | `'onlyCopilotFans'` | Parameters §1.3 |
| APIGroup | `'ocpfBbbRatings'` | prefix + PascalCase group name, camelCase (Standards §2.7) |
| APIVersion | `'v1.0'` | Parameters §1.3 |
| EntityName | `'ocpfBbbCustomerRating'` (21 chars ≤ 30) | Standards §2.7, §4.4 |
| EntitySetName | `'ocpfBbbCustomerRatings'` (22 chars ≤ 30) | Standards §2.7, §4.4 |
| ODataKeyFields | `SystemId` | Standards §2.1 — always |
| **DelayedInsert** | **`true`** | Standards §2.2: **master data → editable.** Mutability decides, not preference. |
| InsertAllowed / DeleteAllowed | **`false`** / **`false`** | See the note below |
| Caption | `'Represents the Better Business Bureau rating information held against a customer, together with the time and outcome of the last retrieval attempt.'` | Standards §2.5 — a complete sentence; it becomes the entity description in `$metadata` |
| EntityCaption / EntitySetCaption | `'BBB Customer Rating'` / `'BBB Customer Ratings'` — **translatable, decided by AJ Ansari (§11)** | Standards §8.6 |
| File | `ocpfBbbCustomerRatings.Page.al` |

**Why `DelayedInsert = true` on a page whose business purpose is read-only reporting.** Standards
§2.2 sets this by *data mutability*, not by intent: a page over **master data** is editable, full
stop, and the anti-pattern table explicitly lists `Editable = false` on an editable page as a
defect. Read-only access for reporting consumers is enforced where it belongs — in the `OCPFBBB
BBBRI, VIEW` permission set (§9). Five of the six BBB fields are additionally `Editable = false` at
field level (DR-6), so the **only** writable field on this endpoint is the profile URL.

**Why `InsertAllowed = false` and `DeleteAllowed = false` alongside it.** This endpoint must not
become a way to create or delete *customers* — DR-13 ("the extension adds; it never alters") and the
plain fact that a BBB endpoint has no business owning customer lifecycle. `DelayedInsert = true` is
kept because Standards §2.2 mandates it on an editable page; with `InsertAllowed = false` it is
simply inert. **Flagged for Step 04:** this pair looks contradictory at a glance and is deliberate.

Fields: §7.5.

### 6.12 `page 50614 "ocpfBbbFetchLogEntries"` — API — M4, Batch B4

| Property | Value | Source of the rule |
|---|---|---|
| PageType | `API` | |
| SourceTable | `"ocpfBbbFetchLog"` (50603) | FRD E-11 |
| APIPublisher / APIGroup / APIVersion | `'onlyCopilotFans'` / `'ocpfBbbRatings'` / `'v1.0'` | same group as §6.11, so both sets appear in one service document |
| EntityName | `'ocpfBbbFetchLogEntry'` (20 chars ≤ 30) | Standards §2.7, §4.4 |
| EntitySetName | `'ocpfBbbFetchLogEntries'` (22 chars ≤ 30) | Standards §2.7, §4.4 |
| ODataKeyFields | `SystemId` | Standards §2.1 |
| **Editable** | **`false`** — and **no** `DelayedInsert` | Standards §2.2: **audit / system table → read-only.** Setting both would be the Part 7 anti-pattern. |
| Caption | `'Represents one attempt to retrieve Better Business Bureau rating data for a customer, including its outcome and any failure detail.'` | Standards §2.5 |
| EntityCaption / EntitySetCaption | `'BBB Fetch Log Entry'` / `'BBB Fetch Log Entries'` — **translatable, decided by AJ Ansari (§11)** | Standards §8.6 |
| File | `ocpfBbbFetchLogEntries.Page.al` |

**The caption sentence deliberately says "one attempt".** DR-8: this endpoint is an attempt log, and
`Documentation.md` must never describe it as grade history.

Fields: §7.6.

---

## 7. Logic and Per-Field Specification

### 7.1 The DR-3 isolation boundary — how the source gets swapped

```
  ocpfBbbCustomerCardExt (50610)        ocpfBbbCustomerRatings (50613)
                │                                     │
                │ RefreshRating(Cust)                 │ (reads stored fields only — NFR-7)
                ▼                                     ▼
       ┌─────────────────────────────────────────────────────┐
       │  ocpfBbbRatingMgt (50606)                            │
       │  preconditions · DR-1 apply · DR-2 stamp · log write │
       └───────────────────────┬─────────────────────────────┘
                               │  Provider.TryGetRating(Url, ...)   ← the ONLY coupling
                               ▼
                 interface "ocpfBbbRatingProvider"      (no object ID)
                               ▲
                               │ implements
                 ┌─────────────┴──────────────┐
                 │ ocpfBbbProfileReader (50607)│  today: HTTPS GET + text parsing
                 └────────────────────────────┘  tomorrow: an official BBB API client
```

**The one line that changes when the data source changes**, inside `RefreshRating`:

```al
var
    Provider: Interface "ocpfBbbRatingProvider";
    ProfileReader: Codeunit "ocpfBbbProfileReader";
begin
    Provider := ProfileReader;          // ← the single binding point in the entire extension
```

**The swap procedure, written down now so the promise in ChangeLog DEFINE-001 is testable later:**
1. Add a new codeunit implementing `"ocpfBbbRatingProvider"` (an ID from M2's reserve, 50609).
2. Change that one assignment.
3. Nothing else moves: not a field, not a page, not an endpoint URL, not a permission set, not a
   caption, not a document.

**No setup table decides which provider is used** — DR-9 forbids a configuration surface in v1, so
the binding is a code decision, deliberately, and is recorded here as such.

**The interface contract's two hard rules** (a provider that breaks either one breaks DR-1):
- **A provider never raises an `Error`.** Failure is `false` + a reason. An `Error` would roll back
  the log write and the stamp, destroying the audit trail DR-2 requires.
- **A provider returns `true` only when it read *every* value.** Partial success is failure — a
  half-parsed page that returned `true` would write a real grade beside a defaulted complaint count,
  and nothing downstream could tell.

### 7.2 `RefreshRating` — the exact flow

| # | Step | Rule it enforces |
|---|---|---|
| 1 | **Permission re-check.** `if not FetchLog.WritePermission() then Error(NoRefreshPermissionErr);` | OQ-4 server-side, not just a greyed-out button (§6.5). Safe to `Error` here: nothing has been written and no call has been made. |
| 2 | **Preconditions, in this order, each ending in an `Error` with its own label** (FR-5): (a) `Rec."ocpfBbb Profile URL" = ''` → `NoProfileUrlErr`; (b) country/region blank → `CountryBlankErr`; (c) country/region resolves to neither US nor CA → `CountryNotSupportedErr` naming the actual code | FR-5, DR-4, OQ-2. |
| 3 | **A precondition refusal is *not* a fetch attempt: nothing is stamped and nothing is logged.** | DR-2 says every *attempt* is logged. No external call was made, the user got an immediate, specific message, and there is nothing to diagnose later. **The technical reason this matters:** `Error` rolls the transaction back, so a log row written before it would vanish anyway — writing one would be a lie about durability. Recorded decision. |
| 4 | **Capture `AttemptedAt := CurrentDateTime();` and the URL, then call the provider** — before any database write in this transaction | §6.10's HTTP-after-write constraint; DR-2's stamp uses a single consistent timestamp. |
| 5 | `Succeeded := Provider.TryGetRating(Url, Grade, Accredited, ComplaintCount, FailureReason, HttpStatusCode, DurationMs);` | The whole of DR-3's coupling. |
| 6 | **On success:** write `"ocpfBbb Grade"`, `"ocpfBbb Accredited"`, `"ocpfBbb Complaint Count"` from the out-parameters | FR-3 |
| 7 | **On failure: do not touch those three fields.** Not to blank them, not to zero the count, not to set a "stale" grade. | **DR-1 — the single most important line in this document.** |
| 8 | **On both branches:** `"ocpfBbb Last Fetched" := AttemptedAt;` and `"ocpfBbb Fetch Status" := Succeeded ? Succeeded : Failed;` then `Cust.Modify(true);` | DR-2, FR-4 |
| 9 | **On both branches:** insert one `ocpfBbbFetchLog` row (all nine fields, §6.3) | DR-2, FR-8 |
| 10 | **Raise `OnAfterRefreshRatingAttempt(Cust, Succeeded)`** | §13.2 |
| 11 | **Report to the user with a `Message`, never an `Error`:** success → `RefreshSucceededMsg`; failure → `RefreshFailedMsg` carrying the business-readable reason and stating that the previous values were left unchanged | FR-4, NFR-9 — **and a hard technical constraint: an `Error` here would roll back steps 8 and 9**, destroying exactly the stamp and log entry DR-2 demands. Any generated code that ends a *failed fetch* in `Error` is a defect, no matter how well-worded the message. |

**`Modify(true)` on the customer, not `Modify(false)`:** running the table's `OnModify` trigger keeps
standard behavior and every other extension's subscribers intact — DR-13 ("the extension adds; it
never alters").

### 7.2.1 `IsRefreshAllowedForCountry` — DR-4 resolved properly (FRD PA-5)

FRD PA-5 rates the *mechanism* High and the *data* Medium: `US` and `CA` are conventional
Country/Region **codes**, not platform constants, and a tenant may use `USA`, `840`, or anything
else. So the check resolves the code to an ISO value rather than string-matching a guess:

1. Read `Cust."Country/Region Code"` *(field on Customer — **UNVERIFIED, confirm against local
   symbols**)*.
2. Blank → return `false` (OQ-2: blank is refused like any unsupported country).
3. `Get` the Country/Region record *(table `Country/Region` — **number and name UNVERIFIED, confirm
   against local symbols**)* and read its **ISO Code** *(field — **UNVERIFIED**)*.
4. If the record exists and its ISO Code is non-blank → supported iff ISO Code is `'US'` or `'CA'`.
5. If the record is missing or its ISO Code is blank → fall back to comparing the raw
   Country/Region Code to `'US'` / `'CA'`; anything else → `false`.
6. Never "assume in scope" on ambiguity. Refusal is the safe direction: a refused refresh costs a
   message, an unwarranted one reaches a third party's website on a customer BBB does not cover.

### 7.3 The parse contract (`ocpfBbbProfileReader`) — and what is deliberately still open

The provider must produce, from one HTTPS response body:

| Out-parameter | Success condition | Failure behavior |
|---|---|---|
| `Grade` | The page's letter grade maps to exactly one `ocpfBbbGrade` member 1–14 | **Unmappable → whole call fails** (§6.1). Never `NotFetched`, never a guess. |
| `Accredited` | The page's accreditation state is positively identified as yes **or** no | Absent/ambiguous → whole call fails. **`false` must mean "the page said not accredited", never "we couldn't tell"** — that distinction is the difference between data and noise in a credit decision (UC-2). |
| `ComplaintCount` | A non-negative integer read from the figure BBB displays most prominently | Absent/unparseable → whole call fails |
| `FailureReason` | blank | One of §10.2's reason labels — business-readable, never a raw status code |
| `HttpStatusCode` | the response code | the response code, or `0` if none arrived |
| `DurationMs` | measured | measured |

**HTTP status → user-facing reason mapping** (NFR-9: the code goes to the log, the sentence goes to
the user):

| Condition | Log `HTTP Status Code` | User-facing reason label |
|---|---|---|
| Outbound calls not permitted for this extension | `0` | `CallNotAllowedReasonTxt` |
| No response within 20 s | `0` | `TimeoutReasonTxt` |
| 404 | `404` | `NotFoundReasonTxt` |
| 401 / 403 / 429 | as received | `BlockedReasonTxt` |
| 5xx | as received | `UnavailableReasonTxt` |
| 2xx but not interpretable | as received | `ParseFailedReasonTxt` |
| anything else | as received | `UnexpectedReasonTxt` |

**Still open, and honestly so: the marker strings themselves.** The exact on-page tokens the parser
looks for **cannot be written in this session** — there is no network access to bbb.org here, and
**OQ-3** (what BBB's "complaint count" figure actually counts, commonly a 3-year window) is still
unresolved for the same reason. This TDD therefore fixes the **contract, the failure semantics, and
the isolation boundary**, and leaves a single table to be filled in at the start of Batch B2, from a
real page AJ Ansari opens locally:

| To pin down before B2 generates `ocpfBbbProfileReader` | Owner |
|---|---|
| The anchor text/markup that precedes the letter grade | AJ Ansari (local, from a live profile page) |
| The anchor for accreditation yes/no | AJ Ansari |
| The anchor for the complaint figure **and the exact window it covers (OQ-3)** | AJ Ansari |
| The resulting ToolTip wording for `"ocpfBbb Complaint Count"` (§7.4) | Main role, from the above |

**Everything else in the extension can be built, reviewed, and compiled without those four
answers** — which is precisely the value of the DR-3 boundary.

### 7.4 Per-field spec — the customer extension fields (§6.4)

Captions and ToolTips are written once, in US English, as single-language properties — never
`CaptionML`/`ToolTipML`, never `TextConst` (§10.1).

| Field name | Caption | ToolTip (NFR-10 — self-describing, for UI *and* `$metadata`) |
|---|---|---|
| `"ocpfBbb Grade"` | `'BBB Grade'` | `'Specifies the letter grade the Better Business Bureau has published for this customer, as read from their BBB profile page. "Not Fetched" means BBB data has never been retrieved for this customer; "NR" means BBB retrieved successfully and reports the business as Not Rated.'` |
| `"ocpfBbb Accredited"` | `'BBB Accredited'` | `'Specifies whether this customer is an accredited business with the Better Business Bureau. Accreditation is a separate fact from the BBB grade: an accredited business can hold any grade, and a non-accredited business can be graded.'` |
| `"ocpfBbb Complaint Count"` | `'BBB Complaint Count'` | `'Specifies the number of complaints the Better Business Bureau reports against this customer on their BBB profile page.'` — **the exact window is added once OQ-3 is answered (§7.3)** |
| `"ocpfBbb Profile URL"` | `'BBB Profile URL'` | `'Specifies the address of this customer''s public Better Business Bureau profile page. Enter it manually; the address must start with https://. This is the page every refresh reads, so an incorrect address attaches another business''s rating to this customer.'` |
| `"ocpfBbb Last Fetched"` | `'BBB Last Fetched'` | `'Specifies when BBB data was last requested for this customer. This is stamped on every attempt, successful or not, so compare it with BBB Fetch Status before relying on the values shown.'` |
| `"ocpfBbb Fetch Status"` | `'BBB Fetch Status'` | `'Specifies how the last BBB retrieval attempt ended. When this is Failed, the grade, accreditation, and complaint count shown are the last values successfully retrieved and are not current.'` |

**Note the doubled apostrophes** (`customer''s`) — AL string escaping. A generation pass that emits
a single apostrophe here produces a compile error; a pass that rewrites the sentence to avoid it
produces worse English. Use the escape.

### 7.5 Per-field spec — API page 50613 `ocpfBbbCustomerRatings`

**camelCase identifiers per Standards §4.1 / §2.7; all ≤ 30 characters.** Every field carries
`Caption`, `ToolTip` (as §7.4), and `ApplicationArea = All`.

| Identifier | Source field | Editable | Derivation / note |
|---|---|---|---|
| `systemId` | `Rec.SystemId` | n/a | The OData key. Mandatory on every page from the §5 template. |
| `number` | `Rec."No."` — **UNVERIFIED, confirm against local symbols** | **`false`** | §4.1's mechanical conversion of `"No."` gives `no`, which reads as a boolean and tells an API consumer nothing. `number` is Microsoft's own identifier for this field on API v2.0 `customers`. **Recorded deviation from §4.1, with precedent**, for Step 04's review. |
| `displayName` | `Rec.Name` — **UNVERIFIED** | **`false`** | FR-7: "enough to identify the customer". `name` is on §4.3's watch list and `displayName` is Microsoft's API v2.0 identifier for the same field. |
| `countryRegionCode` | `Rec."Country/Region Code"` — **UNVERIFIED** | **`false`** | §4.1: dots/slashes are word separators. Lets a BI model segment the portfolio by BBB coverage (UC-3, DR-4). |
| `ocpfBbbGrade` | `Rec."ocpfBbb Grade"` | **`false`** | §6.1's serialization note applies. |
| `ocpfBbbAccredited` | `Rec."ocpfBbb Accredited"` | **`false`** | |
| `ocpfBbbComplaintCount` | `Rec."ocpfBbb Complaint Count"` | **`false`** | 21 chars |
| `ocpfBbbProfileUrl` | `Rec."ocpfBbb Profile URL"` | `true` | **The only writable field on this endpoint** (DR-6, FR-6a). `URL` is cased as a word, not an acronym, for AA0101 camelCase consistency. |
| `ocpfBbbLastFetched` | `Rec."ocpfBbb Last Fetched"` | **`false`** | |
| `ocpfBbbFetchStatus` | `Rec."ocpfBbb Fetch Status"` | **`false`** | BO-4: a report can tell fresh from stale without leaving the endpoint. |

**Why the field list is narrow, and why that is compliant.** Standards Part 3 §3.1 ("expose all
applicable fields") governs a page whose job is to *be* the table's API. This page's job is BBB
reporting (FR-7, BO-3); Microsoft's own API v2.0 `customers` endpoint already serves general
customer integration, and duplicating it here would add surface with no requirement behind it.
Recorded decision.

**Localization = `US` exclusions (Standards Part 3, §3.2) — the full check:**
- Every standard field exposed (`"No."`, `Name`, `"Country/Region Code"`) is a core W1 field with an
  ID well below 10,000 — **UNVERIFIED, confirm each field ID against local symbols.** **No field in
  any localization band (10,000–89,999) is exposed by this extension at all**, so `Localization = US`
  adds nothing to exclude here. That is not an accident: it is why Step 01 could safely set
  Localization to `US` while the *business* scope is US + CA (FRD §4.1).
- No `ObsoleteState = Pending` or `Removed` field is exposed — **to be confirmed field by field
  against local symbols (§16); the rule is unconditional, regardless of removal version.**
- No `Blob` field and no `FlowFilter` field is exposed (neither serializes over OData).
- Customer's standard FlowFields (balances and similar) are deliberately **not** exposed: NFR-8
  forbids measurably slowing anything, and a FlowField on a portfolio-wide API read is the classic
  way to do exactly that.

### 7.6 Per-field spec — API page 50614 `ocpfBbbFetchLogEntries`

`Editable = false` at page level, so no field needs its own editability property.

| Identifier | Source field | Derivation note (§4.1) |
|---|---|---|
| `systemId` | `Rec.SystemId` | OData key |
| `entryNo` | `Rec."Entry No."` | dot is a word separator |
| `customerNumber` | `Rec."Customer No."` | `customerNo` would be the mechanical result; `customerNumber` matches `number` on the sibling page (§7.5) so the two endpoints join legibly |
| `customerSystemId` | `Rec."Customer SystemId"` | the stable join key to `ocpfBbbCustomerRatings.systemId` |
| `attemptedAt` | `Rec."Attempted At"` | |
| `outcome` | `Rec."Outcome"` | serializes as `Succeeded` / `Failed` (enum value names) |
| `failureReason` | `Rec."Failure Reason"` | |
| `httpStatusCode` | `Rec."HTTP Status Code"` | acronym cased as a word; 14 chars |
| `profileUrlUsed` | `Rec."Profile URL Used"` | |
| `durationMs` | `Rec."Duration (ms)"` | **§4.1: parentheses are removed** — `"Duration (ms)"` → `durationMs` |

### 7.7 Reserved-keyword and length audit (Standards §4.3, §4.4)

| Check | Result |
|---|---|
| Any identifier matching an AL/layout keyword (`area`, `group`, `key`, `label`, `type`, `value`, `name`, `trigger`) | **None.** `name` was avoided on purpose in favour of `displayName` (§7.5). |
| Longest field identifier | `ocpfBbbComplaintCount` (21) — well inside 30 |
| Longest `EntitySetName` | `ocpfBbbCustomerRatings` (22) and `ocpfBbbFetchLogEntries` (22) — inside 30 |
| Longest `EntityName` | `ocpfBbbCustomerRating` (21) — inside 30 |
| `%`, `$`, parentheses, dots, slashes in any identifier | None — all removed per §4.1 (`"Duration (ms)"` → `durationMs`) |
| Abbreviations from §4.2 needed | **None.** No identifier came close to 30 characters, so no abbreviation is applied. Applying one anyway would reduce readability for no benefit. |
| Permission set name lengths | `OCPFBBB BBBRI, VIEW` / `, EDIT` = **19 chars** each ≤ 20 (Standards §5.4, `AL0305`) |
| Permission set caption lengths | `'BBB Rating Insights - View'` (26) / `'- Edit'` (26) ≤ 30 |

---

## 8. `using` Directives, Per Object

**Every namespace below is UNVERIFIED and must be copied from the symbol file entry for that source
table before generation (Standards §1.1, §3.4, Appendix B).** The values shown are placeholders with
a plausible shape, not answers.

| Object | `using` | Status |
|---|---|---|
| `ocpfBbbGrade` (50601) | *(none)* | Owns nothing external |
| `ocpfBbbFetchStatus` (50602) | *(none)* | |
| `ocpfBbbFetchLog` (50603) | `Microsoft.Sales.Customer;` — for the `TableRelation = Customer` | **UNVERIFIED** |
| `ocpfBbbCustomerExt` (50604) | `Microsoft.Sales.Customer;` | **UNVERIFIED** |
| `ocpfBbbRatingMgt` (50606) | `Microsoft.Sales.Customer;` **and** `Microsoft.Foundation.Address;` (Country/Region) | **both UNVERIFIED** — see §8.1 |
| `ocpfBbbProfileReader` (50607) | possibly `System.Utilities;` / `System.Text;` for HTTP and regex helpers | **UNVERIFIED — `HttpClient` may be a platform type requiring no `using` at all** |
| `ocpfBbbCustomerSubscribers` (50608) | `Microsoft.Sales.Customer;` | **UNVERIFIED** |
| `ocpfBbbRatingProvider` (interface) | *(none)* | Takes a `Text` and this extension's own enum — deliberately free of any BC namespace, which is itself evidence the DR-3 boundary is clean |
| `ocpfBbbCustomerCardExt` (50610) | `Microsoft.Sales.Customer;` | **UNVERIFIED** |
| `ocpfBbbFetchLogList` (50611) | *(none)* | Sources this extension's own table |
| `ocpfBbbCustomerRatings` (50613) | `Microsoft.Sales.Customer;` | **UNVERIFIED** |
| `ocpfBbbFetchLogEntries` (50614) | *(none)* | Sources this extension's own table |
| Both permission sets | *(none)* | |

### 8.1 A recorded, minimal deviation from Standards §1.1's "one `using` per file"

§1.1's one-`using` shape describes the API-page header pattern, and **every API page in this project
obeys it exactly**. `ocpfBbbRatingMgt` genuinely needs two namespaces: it reads a field on Customer
and resolves a Country/Region record (§7.2.1). The alternatives — fully qualifying one type inline,
or splitting country resolution into a third codeunit to keep each file at one `using` — trade
readability or an object ID for a formatting rule. **Recorded here for Step 04's review** rather
than done quietly. No file exceeds two.

---

## 9. Permission Sets (Standards §5.3–§5.4)

Two sets, named from Project Parameters §1.3, IDs from the primary range, **created in Batch B1 with
their `tabledata` grants and amended as each later batch adds objects** (Standards §5.3: a table's
grant ships in the batch that introduces the table; `PTE0004` fails the Step 07 compile otherwise).

### 9.1 `permissionset 50616 "OCPFBBB BBBRI, VIEW"`

| Property | Value |
|---|---|
| Assignable | `true` |
| Caption | `'BBB Rating Insights - View'` (26 chars) |
| File | `OCPFBBBBBBRIVIEW.PermissionSet.al` |

```al
Permissions =
    tabledata "ocpfBbbFetchLog" = R,
    table "ocpfBbbFetchLog" = X,
    page "ocpfBbbFetchLogList" = X,
    page "ocpfBbbCustomerRatings" = X,
    page "ocpfBbbFetchLogEntries" = X,
    codeunit "ocpfBbbCustomerSubscribers" = X;
```

**What is deliberately absent, and why:** no execute permission on `ocpfBbbRatingMgt` or
`ocpfBbbProfileReader`. **OQ-4: Sales reps may see BBB data but may not run a refresh.** Combined
with `tabledata … = R`, the card's refresh action is disabled for these users by the
`WritePermission()` test in §6.5, so they meet a greyed-out button rather than an error (NFR-9).

`ocpfBbbCustomerSubscribers` is granted `X` because its subscribers must still run for these users —
a Sales user who deletes a customer must still cascade the log rows (§6.8).

**No grant on any standard BC table.** Extension permission sets grant extension objects only;
consumers also need `D365 READ` (Standards §5.3). `Deployment.md` must state the pairing.

### 9.2 `permissionset 50617 "OCPFBBB BBBRI, EDIT"`

| Property | Value |
|---|---|
| Assignable | `true` |
| Caption | `'BBB Rating Insights - Edit'` (26 chars) |
| IncludedPermissionSets | `"OCPFBBB BBBRI, VIEW"` |
| File | `OCPFBBBBBBRIEDIT.PermissionSet.al` |

```al
IncludedPermissionSets = "OCPFBBB BBBRI, VIEW";

Permissions =
    tabledata "ocpfBbbFetchLog" = RIMD,
    codeunit "ocpfBbbRatingMgt" = X,
    codeunit "ocpfBbbProfileReader" = X;
```

This is the Credit & Risk set (FR-11, OQ-4): it can edit the profile URL, run the refresh, and
therefore insert log rows. Pairs with `D365 BUS FULL ACCESS` or equivalent (Standards §5.3).

**Why `RIMD` and not `RI`.** `I` covers the log write; `D` is what makes the cascade delete work for
a Credit & Risk user; `M` is granted for completeness of the `RIMD` idiom — **no code path in this
extension ever modifies a log row**, and the read-only list and API pages prevent a user from doing
so (DR-6). Narrowing this to `RID` is a defensible Step 04 amendment.

### 9.3 `tabledata` coverage check (Standards §5.3, `PTE0004`)

| Table this extension owns | In VIEW | In EDIT |
|---|---|---|
| `ocpfBbbFetchLog` (50603) | `R` ✔ | `RIMD` ✔ |

One owned table, granted in both sets. `ocpfBbbCustomerExt` is a **table extension**, not a table —
its fields are covered by the base Customer `tabledata` permission the consumer already needs, which
is exactly why `Deployment.md` must name the `D365 READ` / `D365 BUS FULL ACCESS` pairing.

### 9.4 What Step 12 must actually test here

1. A VIEW-only user sees all six BBB fields and a **disabled** refresh action.
2. A VIEW-only user **cannot** write the profile URL through the API (a PATCH is refused).
3. An EDIT user can edit the URL and run a refresh, and a log row appears.
4. **A VIEW-only user can delete a customer and the log rows go with it** — this exercises the
   `Permissions` property on `ocpfBbbCustomerSubscribers` (§6.8) and is the one permission
   interaction in this design most likely to be wrong.
5. Both API pages are readable with VIEW + `D365 READ`.

---

## 10. Translatable Text

### 10.1 Scope, stated exactly

This project has **no target languages and ships no translation files** (Project Parameters §1.9;
FRD DR-10, §8). Standards Part 8's machinery — glossary, per-language drafting, reviewer approval,
the `.xlf` state gate — **does not apply**.

**Everything below applies anyway, and is not negotiable:**
- **`app.json` keeps `"TranslationFile"` in `features`** (Standards §8.2). It costs nothing and it
  switches on compiler warning **AL0424**, which is what mechanically proves the codebase carries no
  deprecated multilanguage syntax.
- **Never `CaptionML`, `ToolTipML`, `OptionCaptionML`, `InstructionalTextML`, any other ML property,
  or the `TextConst` data type** — anywhere, for any reason (Standards §1.7).
- **Every user-facing string is a `Label`** with a CodeCop **AA0074** suffix. No string literal ever
  appears inside `Error`, `Message`, `Confirm`, or a notification.
- **Every label with a placeholder carries a `Comment`** naming each placeholder (Standards §8.3).
- **`Locked = true`** on technical tokens.

### 10.2 The complete label inventory

Every user-facing string this extension will ever produce. If Step 06 needs a string that is not in
this table, that is a TDD gap to log, not a literal to type.

**In `ocpfBbbRatingMgt` (50606):**

| Label name | Suffix | Text | Attributes |
|---|---|---|---|
| `NoRefreshPermissionErr` | Err | `'You do not have permission to refresh BBB data. Ask your administrator for the BBB Rating Insights - Edit permission set.'` | — |
| `NoProfileUrlErr` | Err | `'Enter a BBB profile URL for customer %1 before refreshing BBB data.'` | `Comment = '%1 = Customer No.'` |
| `CountryBlankErr` | Err | `'Customer %1 has no country/region. BBB covers the United States and Canada only, so enter the customer''s country/region before refreshing BBB data.'` | `Comment = '%1 = Customer No.'` |
| `CountryNotSupportedErr` | Err | `'BBB covers the United States and Canada only. Customer %1 has country/region %2, so BBB data cannot be refreshed for this customer.'` | `Comment = '%1 = Customer No., %2 = Country/Region Code'` |
| `RefreshSucceededMsg` | Msg | `'BBB data for customer %1 was refreshed successfully.'` | `Comment = '%1 = Customer No.'` |
| `RefreshFailedMsg` | Msg | `'The BBB refresh for customer %1 did not succeed: %2 The BBB values shown are the ones last retrieved successfully and have not been changed.'` | `Comment = '%1 = Customer No., %2 = failure reason sentence'` |

**In `ocpfBbbCustomerExt` (50604):**

| Label name | Suffix | Text | Attributes |
|---|---|---|---|
| `ProfileUrlNotHttpsErr` | Err | `'The BBB profile URL must start with https://.'` | — |
| `HttpsPrefixTok` | Tok | `'https://'` | **`Locked = true`** — a technical token (Standards §8.3) |

**In `ocpfBbbProfileReader` (50607)** — the reason sentences that reach both the user (via
`RefreshFailedMsg`) and the log's `"Failure Reason"` field:

| Label name | Suffix | Text | Attributes |
|---|---|---|---|
| `CallNotAllowedReasonTxt` | Txt | `'Business Central is not allowed to make outbound web requests for this extension. Ask your administrator to allow HttpClient requests for BBB Rating Insights.'` | — |
| `TimeoutReasonTxt` | Txt | `'The BBB website did not respond in time.'` | — |
| `NotFoundReasonTxt` | Txt | `'The BBB profile page was not found at the address recorded for this customer.'` | — |
| `BlockedReasonTxt` | Txt | `'The BBB website refused the request.'` | — |
| `UnavailableReasonTxt` | Txt | `'The BBB website is currently unavailable.'` | — |
| `ParseFailedReasonTxt` | Txt | `'The BBB profile page was reached but could not be read in the expected format. The page layout may have changed.'` | — |
| `UnexpectedReasonTxt` | Txt | `'The BBB profile page could not be read.'` | — |
| `UserAgentTok` | Tok | `'BusinessCentral-BBBRatingInsights/1.0'` | **`Locked = true`** |

**Note what is not in these sentences:** no HTTP status code, no URL, no stack detail (NFR-9). All of
that goes to `ocpfBbbFetchLog` (§6.3), where UC-6 can find it.

### 10.3 Captions and ToolTips

Page, field, enum-value, and permission-set captions are ordinary single-language `Caption` /
`ToolTip` / enum `Caption` properties, listed per object in §6 and §7.4. Enum value captions are
per-value (Standards §8.4) and are never concatenated to build a sentence.

---

## 11. API Caption Locking — **DECIDED by AJ Ansari, 2026-09-16 (ChangeLog DEFINE-006)**

Standards §8.6 requires every `PageType = API` page and `QueryType = API` query to be classified
into exactly one group and its locking decision **recorded per object, with the name of the person
who made it**. Both questions below were put to AJ Ansari through the interactive options
mechanism, in order, per Step 03's procedure.

This project has **two API pages and no API queries**.

### 11.1 Classification — DECIDED

| Object | Group | Decided by |
|---|---|---|
| **50613 `ocpfBbbCustomerRatings`** (E-10) | **Business** | Not in question — it exposes business master data people work with, with a named consumer being a Power BI portfolio-risk report (FR-7, BO-3, UC-3). |
| **50614 `ocpfBbbFetchLogEntries`** (E-11) | **Technical — admin** | **AJ Ansari**, 2026-09-16. Resolved the Unsure call: an administrator deliberately reads this page to diagnose repeated failures (FR-9, BO-5) — a real, named human consumer, not pure internal plumbing. |

### 11.2 Locking decision — DECIDED, with Microsoft's precedent (Standards §8.6)

| Group | Object(s) | Decision | Precedent cited |
|---|---|---|---|
| **Business** | 50613 `ocpfBbbCustomerRatings` | **Translatable** — set `EntityCaption = 'BBB Customer Rating'` and `EntitySetCaption = 'BBB Customer Ratings'` | **AJ Ansari**, 2026-09-16, following the recommendation: Microsoft's API v2.0 leaves all 1,526 captions on its business pages and queries translatable — 0 locked. This is the page Power BI/business consumers read (FR-7). |
| **Technical — admin** | 50614 `ocpfBbbFetchLogEntries` | **Translatable** — set `EntityCaption = 'BBB Fetch Log Entry'` and `EntitySetCaption = 'BBB Fetch Log Entries'` | **AJ Ansari**, 2026-09-16, following the recommendation for the *admin* classification: API v2.0's `automation` pages lock only 1 of 157 captions — an admin-managed object is still read by a named human, not pure plumbing. |

Both pages are therefore translatable, even though this project ships no translation files (§10.1)
— the property is set correctly regardless, since a future language could be added without
revisiting this decision.

### 11.3 What this project does either way

- **ToolTips stay translatable on both pages**, in both outcomes — Microsoft's own locked-caption
  pages do the same, and the ToolTips are this project's `$metadata` schema documentation (NFR-10).
- The decision costs nothing to reverse *before* Step 06 and is a caption change afterwards; it does
  **not** affect endpoint URLs, which derive from `EntityName`/`EntitySetName` (§6.11–§6.12).
- Whatever is decided is recorded back into §6.11 and §6.12 **with AJ Ansari's name**, per §8.6's
  "record the decider, by name" rule — and per the ALL ALONG rule that a decision is attributed to a
  person, never to "the human".
- Any API page or query added later (gap-fill, testing feedback) goes through this same
  classify → show → resolve-unsure → decide-per-group sequence for the new objects only.

---

## 12. Upgrade and Data Migration — **the decision is "none", and here is why**

**Decision: no upgrade codeunit, no install codeunit, and no upgrade tags are built for v1.**
Recorded explicitly, because Standards §9.1 states that "no upgrade code needed" is a decision to
write down, not a silence.

**Reasoning, against Standards §9.1's own table:**

| §9.1 trigger | Applies to v1? |
|---|---|
| Added a table, page, report, codeunit | **Yes — and §9.1 says no upgrade code is needed.** New objects arrive empty and work. |
| Added a field that existing records need a value in | **No.** All six fields on Customer default correctly for existing records: `ocpfBbbGrade::NotFetched` (ordinal 0) and `ocpfBbbFetchStatus::NeverFetched` (ordinal 0) are **exactly the right statement about a customer nobody has fetched yet** — which is why FR-1's "distinct not-yet-fetched state" was placed at ordinal 0 in §6.1 and §6.2. Boolean `false`, Integer `0`, Text `''`, and a blank DateTime are likewise correct. **Nothing needs backfilling, by design, not by luck.** |
| Renamed or replaced a field | **No** — first release, nothing to replace. |
| Changed the meaning of an existing field's values | **No.** |
| Changed or removed an option/enum member | **No.** |
| Added a new table that must be linked to existing records | **No.** `ocpfBbbFetchLog` starts empty and is correct empty: no customer has had an attempt yet. |
| Code-only change | n/a |

**What this obliges the *next* version to do**, so v2 does not discover it late:
- The moment v2 renames, retypes, or retires any field in §6.3 or §6.4, Standards §9.4's
  **two-version obsolete cycle** applies: add the replacement, mark the old field
  `ObsoleteState = Pending` with an `ObsoleteReason` naming the replacement and an `ObsoleteTag`
  carrying the version, ship upgrade code that copies the data, and only remove it a release later.
  **Never delete a shipped field.**
- Introducing any upgrade code means introducing an **install** codeunit in the same release
  (`Subtype = Install`, `SetAllUpgradeTags()` on `OnInstallAppPerCompany`) plus an
  `OnGetPerCompanyUpgradeTags` subscriber, so a fresh install and a newly created company skip
  upgrade logic meant for legacy data (Standards §9.3). Both draw IDs from M2's reserve (50609) or
  the tail block.
- Tag values live in `GetXxxTag()` methods, never as literals at the call site, and follow
  `ocpfBbb-<ID>-<Description>-<YYYYMMDD>` (Standards §9.3, reusing this project's prefix).
- **Step 12's upgrade-path test (Standards §9.6) does not apply to this release** — it is a first
  release. It applies from v2 onward, and `ReleaseTestResults.md` records that reason rather than
  leaving the test silently unrun.

---

## 13. Events, Extensibility, and Special Design Notes

### 13.1 Events this extension **subscribes** to

Both live in `ocpfBbbCustomerSubscribers` (§6.8). Standards §10.1 requires each to be verified in the
symbol file before use — **neither has been, in this session.**

| Event | Object | Purpose | Status |
|---|---|---|---|
| `OnAfterDeleteEvent` | `Database::Customer` — **UNVERIFIED, confirm against local symbols** | Cascade-delete log rows (OQ-6, NFR-15) | **UNVERIFIED** |
| `OnAfterRenameEvent` | `Database::Customer` — **UNVERIFIED, confirm against local symbols** | Keep `"Customer No."` on log rows in step with a renamed customer | **UNVERIFIED** |

These are system-published table trigger events, so nothing needs to be written to make them exist —
but `Database::` (never `Table::`), the empty `ElementName`, and the exact parameter list are all
things the compiler will not fully protect, so §16 checks them explicitly.

**No subscription to any obsolete event** (Standards §3.3) — to be confirmed against symbols.

### 13.2 Events this extension **publishes**

One, on `ocpfBbbRatingMgt` (50606):

```al
[IntegrationEvent(false, false)]
local procedure OnAfterRefreshRatingAttempt(Customer: Record Customer; Succeeded: Boolean)   // Customer — UNVERIFIED
begin
end;
```

**Why exactly one, and why this one** (Standards §10.4 requires the reasoning, not just the list):
- It is the single moment in this extension where another app plausibly needs a hook: "BBB data for
  this customer was just refreshed, and here is whether it worked." A customer wanting a notification
  on repeated failures, or their own reporting side-effect, can subscribe without a source change.
- `[IntegrationEvent(false, false)]` — no sender, no global var access, per Standards §10.2's
  default.
- **Publisher is a signature only, no body**, and is raised explicitly at §7.2 step 10.
- **It carries no `Handled` parameter.** A `Handled` hook would let a subscriber replace the refresh
  itself, which would put a second, unknown retrieval mechanism inside an extension whose whole
  design premise (DR-3) is one swappable provider behind one interface.
- **DR-7 binds this extension, not its subscribers** — this extension never drives a credit hold,
  block, or workflow from a BBB grade. `Documentation.md` (Step 11) must restate that caution beside
  this event, since publishing it is precisely what makes such automation possible for someone else.

**Once v1 ships, this signature is a promise** (Standards §10.3): never renamed, never
re-parameterized. Changing it means publishing a new event alongside, obsoleting the old one, and
raising both for a release.

### 13.3 Special design notes

| Note | Status for this project |
|---|---|
| **Singletons** (`EntityName = EntitySetName`) | **N/A.** No setup or singleton table exists — DR-9 forbids a configuration surface in v1. |
| **Header / line pairs** | **N/A.** No document structure here. Standards §2.4 does not engage. |
| **`SourceTableView` document-type filters** (§2.3's `const()` quoting) | **N/A.** Neither API page filters by document type; neither has a `SourceTableView`. The only `SourceTableView` in the project is the list page's sort order (§6.6), which contains no `const()`. |
| **High-volume tables** | **`ocpfBbbFetchLog` grows without bound** — one row per refresh attempt, forever, with no purge (FR-10, OQ-5, a deliberate decision). One attempt per customer per user action keeps that slow, but it is monotonic. Mitigations built in now: the `(Customer No., Attempted At)` secondary key (§6.3); no retrieved values stored per row (§6.3), keeping rows narrow; a read-only API page consumers can filter server-side. **A retention/purge capability is a `Roadmap.md` candidate for v2, not a v1 gap.** |
| **Naming conflicts** | None found. "BBB" names no standard BC concept, so no caption in this extension collides with standard terminology. Every field added to Customer is prefixed (§1.2), so another extension adding "BBB Grade" cannot collide. App Code `BBBRI` is unique among OCPF extensions using this prefix (Standards §5.4). |
| **Customer rename** | Handled explicitly (§6.8) — the one "obvious later" defect this design goes out of its way to close now. |
| **Uninstall behavior** (NFR-14) | Standard PTE behavior: this extension's fields and its own table are removed with it; **no standard customer data is touched, because nothing standard is ever written by this extension.** `Deployment.md` states this. |

---

## 14. File and Folder Layout

Standards §1.8 (CodeCop **AA0215** — a wrongly named file fails the zero-warnings gate).

```
src/
  CoreData/
    ocpfBbbGrade.Enum.al                     enum 50601
    ocpfBbbFetchStatus.Enum.al               enum 50602
    ocpfBbbFetchLog.Table.al                 table 50603
    ocpfBbbCustomerExt.TableExt.al           tableextension 50604
  Logic/
    ocpfBbbRatingProvider.Interface.al       interface (no ID)
    ocpfBbbRatingMgt.Codeunit.al             codeunit 50606
    ocpfBbbProfileReader.Codeunit.al         codeunit 50607
    ocpfBbbCustomerSubscribers.Codeunit.al   codeunit 50608
  UI/
    ocpfBbbCustomerCardExt.PageExt.al        pageextension 50610
    ocpfBbbFetchLogList.Page.al              page 50611
  API/
    ocpfBbbCustomerRatings.Page.al           page 50613
    ocpfBbbFetchLogEntries.Page.al           page 50614
  Security/
    OCPFBBBBBBRIVIEW.PermissionSet.al        permissionset 50616
    OCPFBBBBBBRIEDIT.PermissionSet.al        permissionset 50617
Translations/                                 (folder created; no .xlf shipped — §10.1)
outputAppPackage/                             (every built .app; git-tracked, never deleted)
```

One object per file, each named for its object. Folders mirror the modules in §3.1.

---

## 15. Decisions and Verification Tasks for AJ Ansari

### 15.1 Decisions — resolved

| # | Decision | Resolution |
|---|---|---|
| **OD-1** | API caption locking (§11), decided interactively per Standards §8.6. | **Resolved by AJ Ansari, 2026-09-16** (ChangeLog DEFINE-006). 50614 classified *Technical — admin*. Both API pages set **Translatable** captions. Recorded in §6.11, §6.12, §11. No longer blocks Step 06 Batch B4. |
| **OD-2** | Optional, low priority: should the API expose a two-character display grade (`'A+'`) alongside the enum, since OData serializes `ocpfBbbGrade` as `"APlus"` (§6.1)? | **Accepted as proposed — no extra field.** It would be stored presentation data, and DR-8 keeps this extension to current values only. `Documentation.md` publishes the mapping table instead. Non-blocking; raised only so its absence is a recorded decision rather than an oversight. |

### 15.2 Verification tasks — not decisions, but they gate Step 06

| # | Task | Gates |
|---|---|---|
| **VT-1** | **Work §16's symbol-verification worksheet locally** and replace every UNVERIFIED marker. | **All of BUILD.** |
| **VT-2** | **OQ-7 / PA-3, still open from Step 02:** confirm on the target sandbox whether outbound HTTP is permitted for a PTE by default, and what an administrator must switch on. | Batch B2's error handling and `Deployment.md`. Does **not** block B1. |
| **VT-3** | **OQ-3 and the parse markers (§7.3):** open a real BBB profile page locally and pin down the four items in §7.3's table, including what the complaint figure actually counts. | Batch B2's `ocpfBbbProfileReader` only — every other object can be built without it. |
| **VT-4** | Confirm on the sandbox whether BC really refuses an outbound call after a write in the same transaction (§6.10). | Nothing — §7.2's ordering is correct either way. Confirm so the reason is recorded, not assumed. |

---

## 16. Symbol Verification Worksheet (Operating Rule 2 / Standards Appendix B)

**This is the checklist VT-1 works, locally, before Step 06 generates anything.** Procedure:
`al_symbolsearch` / `al_symbolrelations` against the packages in `.alpackages/`, or open the symbol
package directly. **Microsoft Learn's Base Application reference is the fallback when symbols do not
answer; downloaded symbols win if the two disagree.** Do not rely on memory or on this document's
placeholders.

| # | To verify | Written here as | Used by |
|---|---|---|---|
| 1 | Customer table number | **18 — UNVERIFIED** | §6.3, §6.4, §6.11, §6.7, §6.8 |
| 2 | Customer Card page number | **21 — UNVERIFIED** | §6.5 |
| 3 | `using` namespace for Customer | `Microsoft.Sales.Customer` — **UNVERIFIED** | §8 |
| 4 | Customer field `"No."` — exact name, ID, type, `ObsoleteState` | **UNVERIFIED** | §6.5, §6.8, §7.5 |
| 5 | Customer field `Name` — exact name, ID, type, `ObsoleteState` | **UNVERIFIED** | §7.5 |
| 6 | Customer field `"Country/Region Code"` — exact name, ID, type, `ObsoleteState` | **UNVERIFIED** | §7.2.1, §7.5 |
| 7 | Country/Region **table number and object name** | **UNVERIFIED** | §7.2.1 |
| 8 | Country/Region **ISO Code field** — exact name and type | **UNVERIFIED** | §7.2.1 |
| 9 | `using` namespace for Country/Region | `Microsoft.Foundation.Address` — **UNVERIFIED** | §8 |
| 10 | `OnAfterDeleteEvent` on `Database::Customer` — exact name and parameter list | **UNVERIFIED** | §6.8, §13.1 |
| 11 | `OnAfterRenameEvent` on `Database::Customer` — exact name and parameter list | **UNVERIFIED** | §6.8, §13.1 |
| 12 | Customer Card control-tree anchor for `addlast(content)` and the action area name | **UNVERIFIED** | §6.5 |
| 13 | Promoted-action property shape valid for this runtime in a page extension | **UNVERIFIED** | §6.5 |
| 14 | `HttpClient` / `HttpResponseMessage` — whether any `using` is required | **UNVERIFIED** | §6.10, §8 |
| 15 | System Application `Regex` codeunit and its namespace, if used | `System.Text` — **UNVERIFIED** | §6.10 |
| 16 | That every standard field exposed at §7.5 is `ObsoleteState = Active` and outside 10,000–89,999 | **UNVERIFIED** | §7.5, Part 3 |
| 17 | AL runtime `16.0` and BC minimum `27.0.0.0` against the actual sandbox | **UNVERIFIED** (Parameters §1.4) | `app.json` |
| 18 | Record the **Symbol Source** in Project Parameters §1.4 once symbols are downloaded | blank today | §1 |

**A marker that survives into generated AL is a defect, not a caveat.**

---

## 17. Self-Sufficiency Check (Step 03 exit gate)

| Question | Answer |
|---|---|
| Can a developer who has never seen this project build every object from this document alone? | **Yes, with one bounded exception:** `ocpfBbbProfileReader`'s parse markers (§7.3, VT-3) cannot be written without a live BBB page, which no document could supply. The contract, the failure semantics, and the isolation boundary around them **are** fully specified, so the other twelve objects are unblocked. |
| Does any rule here require knowledge outside the document? | **No.** Every Standards rule applied is restated where it is applied. |
| Is every object ID inside 50601–50620? | **Yes** — §3.3, with 7 IDs reserved. |
| Does every API page carry exactly one of `DelayedInsert = true` / `Editable = false`? | **Yes** — 50613 `DelayedInsert = true` (master data), 50614 `Editable = false` (audit). §6.11, §6.12. |
| Is every standard-BC identifier marked UNVERIFIED at every occurrence? | **Yes**, and §16 collects them into one worksheet. |
| Is every FRD entity E-1…E-13 accounted for? | **Yes** — E-1…E-5 and E-7…E-13 built; **E-6 deliberately not built** with reasoning (§3.6), its ID reserved; one object added beyond the FRD list (§3.5) with reasoning. |
| Are the FRD's non-negotiables traceable to concrete mechanisms? | DR-1 → §7.2 step 7; DR-2 → §7.2 steps 8–9 and the `Message`-not-`Error` rule at step 11; DR-3 → §6.9, §7.1; DR-4 → §7.2.1; DR-5/DR-6 → §6.4; DR-7 → §13.2; DR-8 → §6.3, §6.12; DR-9 → §6.6, §7.1; DR-10 → §10.1; DR-11 → §9; DR-12 → §3; DR-13 → §6.11, §13.3; DR-14 → §0.3, §16. |

---

## 18. Sign-Off

| Role | Name | Decision | Date |
|---|---|---|---|
| Technical Lead (also Functional Consultant and Dev Manager — Approvers = one person, Project Parameters §1.1) | AJ Ansari | *pending* | — |

**Step 03 exit gate:** self-sufficiency check passes (§17); **OD-1 and OD-2 are both resolved**
(§15.1). Under **Approvers = one person**, the Technical Lead sign-off moves to Step 04 and is
given once, on `TDD.md` and `SanityCheck.md` together.
