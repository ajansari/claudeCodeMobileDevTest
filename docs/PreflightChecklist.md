# Pre-Flight Validation Checklist

**Project:** BBB Rating Insights
**Phase / Step:** BUILD — Runbook Step 05 (canonical checklist; cited by Steps 06 and 07 rather
than restated there).

Run **both passes on every batch** before moving to the next (Operating Rule 4). Batches are
defined in `docs/TDD.md` §4: B1 (Core Data), B2 (Retrieval & Logic), B3 (User Interface), B4
(Integration/API).

## Pass 1 — Pre-Generation (on planned names/fields, before any file exists — main role)

- [ ] Every object/entity/field identifier ≤ 30 characters (Standards §4.4).
- [ ] Every `EntitySetName`/`EntityName` ≤ 30 characters, camelCase (Standards §2.7).
- [ ] API identifiers (`APIPublisher`, `APIGroup`, every field identifier on an API page) are
      camelCase, letters/digits only (Standards §2.7, CodeCop AA0101).
- [ ] Reserved-keyword scan: no identifier matches an AL/layout keyword (Standards §4.3).
- [ ] Localization field-range filter: nothing in the 10,000–89,999 band is referenced or exposed
      (Standards Part 3; Localization = `US`, Project Parameters §1.1).
- [ ] `ObsoleteState` filter: no field/table/procedure/event marked `Pending` or `Removed` is
      referenced (Standards §3.2–§3.3) — **cannot be confirmed in this session; defer to VT-1**.

## Pass 2 — Post-Generation (on actual generated files — light role)

- [ ] Required properties present per TDD §6 per-object spec.
- [ ] File named after its object exactly (Standards §1.8, CodeCop AA0215) — see TDD §14's layout.
- [ ] **No multilanguage (ML) properties and no `TextConst`** anywhere (Standards §1.7).
- [ ] **Translatable text:** no string literal in any `Error`/`Message`/`Confirm`/notification;
      every user-facing string is a `Label` with an AA0074 suffix; every placeholder label carries
      a `Comment` (Standards §8.3–§8.4). Full inventory: TDD §10.2.
- [ ] **API caption locking** matches the per-object decision recorded in TDD §11 (both pages
      Translatable, decided by AJ Ansari — ChangeLog DEFINE-006).
- [ ] `Rec.`-qualification everywhere (`NoImplicitWith` enforced, Standards §1.2).
- [ ] No empty triggers, no `// TODO`, no commented-out fields (Standards §1.5).
- [ ] 4-space indentation, spaces only, never tabs (Standards §1.6).
- [ ] Permission set names from Project Parameters §1.3, ≤ 20 characters, captions ≤ 30 chars
      (Standards §5.4) — `OCPFBBB BBBRI, VIEW` / `, EDIT`, both 19 chars.
- [ ] `tabledata` coverage: every table this batch introduces has a matching grant in both
      permission sets, added in the same batch that introduces the table (Standards §5.3,
      `PTE0004`). B1 introduces `ocpfBbbFetchLog` — both sets must carry its `tabledata` grant
      from B1 onward (TDD §9).
- [ ] **Symbol verification** (Operating Rule 2, Standards Appendix B): every reference to a
      standard object, method, property, or enum value is confirmed against the local symbol
      file. **This session has no symbol file (ChangeLog DEFINE-004) — every such reference is
      instead marked UNVERIFIED inline and collected in TDD §16's worksheet (29 items). This
      pass's symbol-verification item is satisfied here by "correctly flagged as unverified,"
      not by "confirmed correct." AJ Ansari completes actual verification locally before Step 06
      relies on any of them.**
- [ ] Exactly one of `DelayedInsert = true` / `Editable = false` on every API page (Standards
      §2.2, Part 7 anti-pattern) — 50613 `DelayedInsert = true`, 50614 `Editable = false`.
- [ ] `ODataKeyFields = SystemId` on every API page, never a business key (Standards §2.1).
- [ ] `Caption`, `ToolTip`, `ApplicationArea = All` on every **page/page-extension/API-page**
      field, no exceptions (Standards §1.4). **`ApplicationArea` does not exist on
      `table`/`tableextension` field definitions** — a table-owning field gets `Caption`/
      `ToolTip` only; `ApplicationArea` applies where that field is later placed on a page. Also:
      **codeunits have no `Caption` property at all** — don't add one. (Both corrected during
      Step 07 troubleshooting, ChangeLog DEFINE-016 — a real gap in this checklist's own wording
      that let an invalid property pass a "CLEAN" Light-role review.)

## Batch-Specific Notes

| Batch | Extra checks |
|---|---|
| **B1** | Both permission sets created here with their `ocpfBbbFetchLog` `tabledata` grant (`R` in VIEW, `RID` in EDIT — TDD §9, narrowed per ChangeLog DEFINE-014). |
| **B2** | Contains nearly every UNVERIFIED marker in the project (Customer field names, Country/Region table, event signatures) — gate most tightly against VT-1. `[TryFunction]` containment (ChangeLog DEFINE-014 / F-B-2) is mandatory in `ocpfBbbProfileReader`. VT-3 (BBB page parse markers) must be resolved locally before this batch's provider logic can be finalized. |
| **B3** | The `OnValidate` permission check on `"ocpfBbb Profile URL"` (ChangeLog DEFINE-007 / F-B-1) must be present. |
| **B4** | Both API pages set `EntityCaption`/`EntitySetCaption` (translatable, TDD §11). A read-only API page (50614) sets **all three** CRUD guards explicit — `InsertAllowed = false; ModifyAllowed = false; DeleteAllowed = false;` — never just two (CR-03, ChangeLog DEFINE-018, correcting this row's earlier two-property wording, which let 50614 ship without `ModifyAllowed`). An editable page (50613) sets only `InsertAllowed = false; DeleteAllowed = false;` per its own mutability (TDD §6.11). |

## What This Checklist Does Not Replace

The Step 07 analyzer-enabled compile (`scripts/al-analyze.sh`) proves several of these again
mechanically (`PTE0004`, `AA0074`, `AA0101`, `AA0215`, `AL0424`) — this checklist exists so the
*next* batch isn't built on a gap the compile would only catch later, not as a substitute for
compiling.
