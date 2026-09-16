namespace OnlyCopilotFans.BBBInsights;

permissionset 50616 "OCPFBBB BBBRI, VIEW"
{
    Assignable = true;
    Caption = 'BBB Rating Insights - View';

    Permissions =
        tabledata "ocpfBbbFetchLog" = R,
        table "ocpfBbbFetchLog" = X,
        page "ocpfBbbFetchLogList" = X,
        page "ocpfBbbCustomerRatings" = X,
        page "ocpfBbbFetchLogEntries" = X,
        codeunit "ocpfBbbCustomerSubscribers" = X;

    // What is deliberately absent, and why (TDD §9.1): no execute permission on
    // "ocpfBbbRatingMgt" or "ocpfBbbProfileReader". OQ-4: Sales reps may see BBB data but may not
    // run a refresh. Combined with tabledata ... = R, the card's refresh action is disabled for
    // these users by the WritePermission() test on ocpfBbbCustomerCardExt (50610), so they meet a
    // greyed-out button rather than an error (NFR-9).
    //
    // "ocpfBbbCustomerSubscribers" is granted X because its subscribers must still run for these
    // users — a Sales user who deletes a customer must still cascade the log rows (TDD §6.8).
    //
    // No grant on any standard BC table. Extension permission sets grant extension objects only;
    // consumers also need "D365 READ" (Standards §5.3) — Deployment.md states the pairing.
}
