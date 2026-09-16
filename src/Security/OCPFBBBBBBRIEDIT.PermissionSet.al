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
    // NOT granted: no code path in this extension ever modifies a log row, and the read-only list
    // and API pages prevent a user from doing so (DR-6) — least privilege says don't grant what
    // nothing uses (TDD §9.2).
}
