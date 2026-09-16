namespace OnlyCopilotFans.BBBInsights;

enum 50602 "ocpfBbbFetchStatus"
{
    Caption = 'BBB Fetch Status';
    Extensible = false;

    value(0; NeverFetched)
    {
        Caption = 'Never Fetched';
        // Default for every customer. Never appears on a log row (TDD §6.3).
    }
    value(1; Succeeded)
    {
        Caption = 'Succeeded';
        // FR-3.
    }
    value(2; Failed)
    {
        Caption = 'Failed';
        // FR-4 - the values displayed beside it are last known good, not current.
    }

    // "Stale" is deliberately not a member, although FR-1 listed it as an example. Nothing in
    // this extension could ever set it: there is no scheduled job, no background session, and
    // NFR-7 forbids any work at display time. A stored status that no code path can ever write is
    // dead metadata that makes the enum lie. Staleness is derived, not stored - by the reader,
    // from "ocpfBbb Last Fetched" (TDD §6.2).
}
