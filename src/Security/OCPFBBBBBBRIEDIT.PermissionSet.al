namespace OnlyCopilotFans.BBBInsights;

permissionset 50617 "OCPFBBB BBBRI, EDIT"
{
    Assignable = true;
    Caption = 'BBB Rating Insights - Edit';
    IncludedPermissionSets = "OCPFBBB BBBRI, VIEW";

    Permissions =
        tabledata "ocpfBbbFetchLog" = RID,
        codeunit "ocpfBbbRatingMgt" = X,
        codeunit "ocpfBbbProfileReader" = X;

    // This is the Credit & Risk set (FR-11, OQ-4): it can edit the profile URL, run the refresh,
    // and therefore insert log rows. Pairs with "D365 BUS FULL ACCESS" or equivalent
    // (Standards §5.3).
    //
    // Why RID, narrowed from the full RIMD idiom (F-M-1, ChangeLog DEFINE-014). I covers the log
    // write; D is what makes the cascade delete work for a Credit & Risk user. M is deliberately
    // NOT granted here: no USER-FACING surface (UI or API) can modify a log row; the only code
    // path that does is the rename-tracking subscriber (ocpfBbbCustomerSubscribers, 50608), which
    // runs under its own codeunit-level Permissions grant (RMD), pending CR-04's verification of
    // whether that subscriber is even needed (CR-23, ChangeLog DEFINE-017, correcting an earlier,
    // broader claim here that no code path anywhere ever modifies a log row). The read-only list
    // and API pages prevent a user from modifying a row through them (DR-6) — least privilege
    // says don't grant what this permission set's own consumers don't need (TDD §9.2).
}
