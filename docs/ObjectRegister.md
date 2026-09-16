# Object Register

**Project:** BBB Rating Insights · **Prefix:** `ocpfBbb` · **Namespace:** `OnlyCopilotFans.BBBInsights`
**Allocated ID range:** 50601–50620 (20 IDs, primary allocation, no additional ranges — Project
Parameters §1.2). **No object may ever use an ID outside this range** (FRD DR-12).
**Populated at Step 03 (TDD) — 2026-09-16.** Source of truth for the design behind each row:
`docs/TDD.md` §3 (modules and allocation), §6 (per-object spec).

> **Every standard BC source object below is marked UNVERIFIED — confirm against local symbols**
> before Step 06 generates code (ChangeLog DEFINE-004, FRD DR-14/NFR-21; TDD §0.3 and §16).

## 1. Module blocks (TDD §3.2)

| Block | IDs | Size | Allocated | Reserved | Buffer |
|---|---|---|---|---|---|
| M1 — Core Data | 50601–50605 | 5 | 4 | 50605 | 20% |
| M2 — Retrieval & Logic | 50606–50609 | 4 | 3 | 50609 | 25% |
| M3 — User Interface | 50610–50612 | 3 | 2 | 50612 | 33% |
| M4 — Integration (API) | 50613–50615 | 3 | 2 | 50615 | 33% |
| M5 — Security | 50616–50617 | 2 | 2 | — (uses tail) | 0% |
| Tail block — cross-module | 50618–50620 | 3 | 0 | 50618, 50619, 50620 | 100% |
| **Total** | **50601–50620** | **20** | **13** | **7** | **35%** |

## 2. Objects

| ID | Object Type | Object Name | Source Table / Object | Module | Batch | R vs R/W | Notes |
|---|---|---|---|---|---|---|---|
| 50601 | enum | `ocpfBbbGrade` | — (new) | M1 | B1 | n/a | `Extensible = false`. Ordinal 0 = `NotFetched` (FR-1's distinct never-fetched state); 14 = `NR` (BBB's Not Rated). No catch-all member — an unmappable grade is a parse failure (DR-1). |
| 50602 | enum | `ocpfBbbFetchStatus` | — (new) | M1 | B1 | n/a | `Extensible = false`. `NeverFetched` / `Succeeded` / `Failed`. **No `Stale` member** — nothing could ever set it; staleness is derived from Last Fetched (TDD §6.2). |
| 50603 | table | `ocpfBbbFetchLog` | — (new) | M1 | B1 | **System-write, read-only to users** | Audit table (Standards §2.2). 9 fields. Cascade-deletes with the customer via 50608 (OQ-6). No purge (FR-10/OQ-5). Stores **no** retrieved grade values — DR-8. |
| 50604 | tableextension | `ocpfBbbCustomerExt` | **Customer — table 18 — UNVERIFIED, confirm against local symbols** | M1 | B1 | Read/Write | Adds 6 fields, IDs 50601–50606. Five are `Editable = false` (system-owned, DR-6); `"ocpfBbb Profile URL"` is staff-owned (DR-5). |
| 50605 | *(reserved)* | — | — | M1 | — | — | Growth buffer. |
| 50606 | codeunit | `ocpfBbbRatingMgt` | — | M2 | B2 | n/a | Orchestration: preconditions (FR-5/DR-4), DR-1 apply, DR-2 stamp, log write. **Knows nothing of how data is obtained** (DR-3). Publishes `OnAfterRefreshRatingAttempt`. |
| 50607 | codeunit | `ocpfBbbProfileReader` | — | M2 | B2 | n/a | **The replaceable component** (DR-3/NFR-2). Implements `ocpfBbbRatingProvider`. Sole owner of the outbound call and of interpreting the response. Never raises an `Error`. |
| 50608 | codeunit | `ocpfBbbCustomerSubscribers` | — | M2 | B2 | n/a | Event subscribers only (Standards §10.1). Cascade delete (OQ-6) + rename follow-through. Carries `Permissions = tabledata "ocpfBbbFetchLog" = RIMD;`. **Not in FRD §9** — a delivery mechanic for NFR-15 (TDD §3.5). |
| 50609 | *(reserved)* | — | — | M2 | — | — | Growth buffer. First call on a replacement provider codeunit (TDD §7.1) or a future upgrade/install codeunit. |
| 50610 | pageextension | `ocpfBbbCustomerCardExt` | **Customer Card — page 21 — UNVERIFIED, confirm against local symbols** | M3 | B3 | Read/Write | Inline group `ocpfBbbRatingGroup` (FR-6) + `Refresh BBB Data` action (FR-2), enabled only with write permission on 50603 (OQ-4) + `BBB Fetch Log` action. |
| 50611 | page (List) | `ocpfBbbFetchLogList` | `ocpfBbbFetchLog` (50603) | M3 | B3 | **Read-only** (`Editable = false`) | FR-9 review surface. **No `UsageCategory`** — DR-9 forbids Tell Me / Departments placement. |
| 50612 | *(reserved)* | — | — | M3 | — | — | The ID FRD E-6 (FactBox) would have used. **E-6 deliberately not built** (TDD §3.6); ID returned to the buffer and held in case that call is reversed. |
| 50613 | page (API) | `ocpfBbbCustomerRatings` | **Customer — table 18 — UNVERIFIED, confirm against local symbols** | M4 | B4 | **Editable** (`DelayedInsert = true`) + `InsertAllowed = false`, `DeleteAllowed = false` | Master data → editable per Standards §2.2 (mutability, not preference). Only `ocpfBbbProfileUrl` is writable; read-only access is enforced by the VIEW permission set. `EntityName 'ocpfBbbCustomerRating'` / `EntitySetName 'ocpfBbbCustomerRatings'`. |
| 50614 | page (API) | `ocpfBbbFetchLogEntries` | `ocpfBbbFetchLog` (50603) | M4 | B4 | **Read-only** (`Editable = false`) | Audit table → read-only per Standards §2.2. `EntityName 'ocpfBbbFetchLogEntry'` / `EntitySetName 'ocpfBbbFetchLogEntries'`. |
| 50615 | *(reserved)* | — | — | M4 | — | — | Growth buffer. |
| 50616 | permissionset | `OCPFBBB BBBRI, VIEW` | — | M5 | B1 (created), amended B2–B4 | Read | `Assignable = true`, Caption `'BBB Rating Insights - View'`. `tabledata "ocpfBbbFetchLog" = R`. **No execute on 50606/50607** — Sales cannot refresh (OQ-4). Pairs with `D365 READ`. |
| 50617 | permissionset | `OCPFBBB BBBRI, EDIT` | — | M5 | B1 (created), amended B2–B4 | Read/Write | `Assignable = true`, Caption `'BBB Rating Insights - Edit'`, `IncludedPermissionSets = "OCPFBBB BBBRI, VIEW"`. `tabledata "ocpfBbbFetchLog" = RIMD` + execute on 50606/50607. Credit & Risk only (FR-11/OQ-4). Pairs with `D365 BUS FULL ACCESS`. |
| 50618–50620 | *(tail block, reserved)* | — | — | cross-module | — | — | Cross-module additions, and the source for a third permission set if one is ever needed (M5 has no in-block buffer). |
| **—** | interface | `ocpfBbbRatingProvider` | — | M2 | B2 | n/a | **AL interfaces carry no object ID.** The DR-3/NFR-2 isolation boundary: `TryGetRating(...)`. Implemented today by 50607; a future official BBB feed implements the same contract and one assignment line changes (TDD §7.1). |

## 3. Fields added to standard BC tables

All on **Customer — table 18 — UNVERIFIED, confirm against local symbols**, via `ocpfBbbCustomerExt`
(50604). Field IDs are drawn from this extension's own object range, so no collision with another
extension is possible.

| Field ID | Field name | Type | Editable | DataClassification | Owner |
|---|---|---|---|---|---|
| 50601 | `"ocpfBbb Grade"` | Enum `ocpfBbbGrade` | `false` | CustomerContent | System (DR-6) |
| 50602 | `"ocpfBbb Accredited"` | Boolean | `false` | CustomerContent | System (DR-6) |
| 50603 | `"ocpfBbb Complaint Count"` | Integer | `false` | CustomerContent | System (DR-6) |
| 50604 | `"ocpfBbb Profile URL"` | Text[250] | `true` | CustomerContent | **Staff (DR-5, FR-6a)** |
| 50605 | `"ocpfBbb Last Fetched"` | DateTime | `false` | CustomerContent | System (DR-2) |
| 50606 | `"ocpfBbb Fetch Status"` | Enum `ocpfBbbFetchStatus` | `false` | CustomerContent | System (DR-2) |

## 4. Events (Standards §10.4 — recorded with the objects)

### 4.1 Published by this extension

| Event | Publishing object | Attribute | Why |
|---|---|---|---|
| `OnAfterRefreshRatingAttempt(Customer; Succeeded)` | `ocpfBbbRatingMgt` (50606) | `[IntegrationEvent(false, false)]` | The one moment another app plausibly needs a hook. No `Handled` parameter — a subscriber must not be able to replace the retrieval mechanism (TDD §13.2). Signature is a promise from v1 onward (Standards §10.3). |

### 4.2 Subscribed to by this extension

| Event | Object | Subscriber codeunit | Purpose | Status |
|---|---|---|---|---|
| `OnAfterDeleteEvent` | `Database::Customer` — **UNVERIFIED, confirm against local symbols** | `ocpfBbbCustomerSubscribers` (50608) | Cascade-delete Fetch Log rows (OQ-6, NFR-15) | **UNVERIFIED** |
| `OnAfterRenameEvent` | `Database::Customer` — **UNVERIFIED, confirm against local symbols** | `ocpfBbbCustomerSubscribers` (50608) | Keep `"Customer No."` in step with a renamed customer | **UNVERIFIED** |

## 5. Permission set reservation (Standards §5.3)

Satisfied: 2 IDs reserved and assigned inside the primary range — **50616** `OCPFBBB BBBRI, VIEW`
and **50617** `OCPFBBB BBBRI, EDIT`. One owned table (`ocpfBbbFetchLog`, 50603) with a `tabledata`
grant in both sets (`PTE0004` / TDD §9.3).

## 6. Open against this register

- **OD-1 (TDD §11/§15.1):** API caption locking for 50613 and 50614 — awaiting AJ Ansari's
  interactive decision. Recorded per object, by name, once given.
- **VT-1 (TDD §16):** every UNVERIFIED marker above must be replaced with a symbol-verified value
  before Step 06 generates code.
