namespace OnlyCopilotFans.BBBInsights;

using Microsoft.Sales.Customer; // UNVERIFIED — confirm the exact namespace against local symbols (see TDD §16 row 3)

codeunit 50608 "ocpfBbbCustomerSubscribers"
{
    // BBB Customer Subscribers — codeunits have no Caption property (AL object model); this
    // name is carried by the object name itself. Removed during Step 07 troubleshooting: an
    // invalid property the TDD's own per-object table incorrectly listed for every codeunit.
    Permissions = tabledata "ocpfBbbFetchLog" = RMD;
    // Narrowed from RIMD to RMD (CR-09, ChangeLog DEFINE-017): I is never used by either
    // subscriber below — neither one inserts a log row. R is required for the SetRange/ModifyAll
    // below; D is required for the cascade delete; M is required for the rename follow-through
    // (pending CR-04's verification of whether that subscriber is even needed).
    //
    // The Permissions property is intended to be why a Sales user can still delete a customer:
    // "OCPFBBB BBBRI, VIEW" grants only R on ocpfBbbFetchLog; without this codeunit-level grant
    // the cascade would otherwise fail with a permission error on an operation the user is
    // entitled to perform (TDD §6.8). Two claims this rests on are REVIEWER-UNVERIFIED (F-B-3,
    // TDD §16 rows 20-21): (i) that a codeunit's Permissions property elevates permissions for
    // code running as an event subscriber, and (ii) that execute permission on a subscriber
    // codeunit is required for it to fire at all. Step 12 must test customer deletion under both
    // permission sets AND under neither (TDD §9.4 tests 4-5).
    //
    // CR-23 (ChangeLog DEFINE-017): no user-facing surface (UI or API) can modify a log row; the
    // only code path that does is the rename-tracking subscriber below, which runs under this
    // codeunit-level Permissions grant, pending CR-04's verification of whether that subscriber
    // is even needed.

    // Named for what it listens to, per Standards §10.1. Two subscribers, both local procedure,
    // both doing one thing and returning, neither raising UI — a customer delete or rename can
    // happen in a web-service or background session.

    /// <summary>
    /// Cascade delete (OQ-6, NFR-15): a table this extension owns cannot get cascade-delete
    /// behavior from a TableRelation, because BC's cascade-delete is a property of the parent
    /// table's relations, and this extension does not modify standard tables (DR-13) — so the
    /// supported mechanism is an event subscriber on the Customer table's delete trigger.
    /// Keyed on the STABLE "Customer SystemId" link, not "Customer No." (F-S-9, ChangeLog
    /// DEFINE-014), so the cascade no longer depends on the rename subscriber below having run
    /// for every past rename.
    /// </summary>
    [EventSubscriber(ObjectType::Table, Database::Customer, 'OnAfterDeleteEvent', '', false, false)] // UNVERIFIED — event name, object, and parameter list all unverified; confirm against local symbols (see TDD §16 row 10)
    local procedure OnAfterDeleteCustomer(var Rec: Record Customer) // UNVERIFIED — Customer, see TDD §16 row 1
    var
        FetchLog: Record "ocpfBbbFetchLog";
    begin
        FetchLog.SetRange("Customer SystemId", Rec.SystemId);
        FetchLog.DeleteAll(false);
    end;

    /// <summary>
    /// Rename follow-through: re-points existing log rows from the old customer number to the
    /// new one, so FR-9's "filtered to a customer" keeps working after a customer number change.
    /// "Customer SystemId" needs no maintenance here — it never changes, which is why it exists
    /// (TDD §6.3 field 3).
    /// </summary>
    [EventSubscriber(ObjectType::Table, Database::Customer, 'OnAfterRenameEvent', '', false, false)] // UNVERIFIED — confirm event name, object, and parameter list against local symbols (see TDD §16 row 11)
    local procedure OnAfterRenameCustomer(var Rec: Record Customer; var xRec: Record Customer) // UNVERIFIED — Customer, see TDD §16 row 1; parameter list (Rec/xRec) unverified against the actual OnAfterRenameEvent signature
    var
        FetchLog: Record "ocpfBbbFetchLog";
    begin
        // CR-04 (ChangeLog DEFINE-017): converted from a FindSet/repeat/Modify loop to ModifyAll —
        // a per-row Modify with no validation is the exact anti-pattern ModifyAll exists to avoid.
        // Whether this whole subscriber is even needed is a separate, still-open question: BC may
        // already propagate a customer rename to this field automatically via its TableRelation
        // (this table sets no ValidateTableRelation = false), which would make this subscriber a
        // no-op costing a database round-trip on every rename. Pending AJ Ansari's local
        // verification (TDD §6.8) — not removed here, only its performance shape fixed.
        FetchLog.SetRange("Customer No.", xRec."No."); // UNVERIFIED — "No.", see TDD §16 row 4
        FetchLog.ModifyAll("Customer No.", Rec."No.");
    end;
}
