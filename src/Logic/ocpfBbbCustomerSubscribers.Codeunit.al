namespace OnlyCopilotFans.BBBInsights;

using Microsoft.Sales.Customer; // UNVERIFIED — confirm the exact namespace against local symbols (see TDD §16 row 3)

codeunit 50608 "ocpfBbbCustomerSubscribers"
{
    // BBB Customer Subscribers — codeunits have no Caption property (AL object model); this
    // name is carried by the object name itself. Removed during Step 07 troubleshooting: an
    // invalid property the TDD's own per-object table incorrectly listed for every codeunit.
    Permissions = tabledata "ocpfBbbFetchLog" = RIMD;
    // The Permissions property is intended to be why a Sales user can still delete a customer:
    // "OCPFBBB BBBRI, VIEW" grants only R on ocpfBbbFetchLog; without this codeunit-level grant
    // the cascade would otherwise fail with a permission error on an operation the user is
    // entitled to perform (TDD §6.8). Two claims this rests on are REVIEWER-UNVERIFIED (F-B-3,
    // TDD §16 rows 20-21): (i) that a codeunit's Permissions property elevates permissions for
    // code running as an event subscriber, and (ii) that execute permission on a subscriber
    // codeunit is required for it to fire at all. Step 12 must test customer deletion under both
    // permission sets AND under neither (TDD §9.4 tests 4-5).

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
        FetchLog.SetRange("Customer No.", xRec."No."); // UNVERIFIED — "No.", see TDD §16 row 4
        if FetchLog.FindSet(true) then
            repeat
                FetchLog."Customer No." := Rec."No.";
                FetchLog.Modify();
            until FetchLog.Next() = 0;
    end;
}
