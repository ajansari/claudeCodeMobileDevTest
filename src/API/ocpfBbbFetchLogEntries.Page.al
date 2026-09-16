namespace OnlyCopilotFans.BBBInsights;

page 50614 "ocpfBbbFetchLogEntries"
{
    PageType = API;
    Caption = 'Represents one attempt to retrieve Better Business Bureau rating data for a customer, including its outcome and any failure detail.';
    // The caption sentence deliberately says "one attempt" (TDD §6.12): DR-8 — this endpoint is
    // an attempt log, never a grade time series.
    APIPublisher = 'onlyCopilotFans';
    APIGroup = 'ocpfBbbRatings';
    APIVersion = 'v1.0';
    EntityName = 'ocpfBbbFetchLogEntry';
    EntitySetName = 'ocpfBbbFetchLogEntries';
    EntityCaption = 'BBB Fetch Log Entry';
    EntitySetCaption = 'BBB Fetch Log Entries';
    // Translatable — decided by AJ Ansari, 2026-09-16 (ChangeLog DEFINE-006; TDD §11.2).
    // Technical — admin classification: Microsoft's API v2.0 "automation" pages lock only 1 of
    // 157 captions — an admin-managed object is still read by a named human, not pure plumbing.
    SourceTable = "ocpfBbbFetchLog";
    ODataKeyFields = SystemId;
    Editable = false;
    // Standards §2.2: audit / system table → read-only. Setting both Editable = false and
    // DelayedInsert would be the Part 7 anti-pattern (TDD §6.12).
    InsertAllowed = false;
    DeleteAllowed = false;
    // Explicit, not just implied by Editable = false (F-S-7, ChangeLog DEFINE-014). Fetch Log rows
    // are deleted only by the cascade-delete subscriber (50608), on the customer's own deletion —
    // there is no user-facing delete path, via the UI or the API (TDD §6.12).

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
                field(entryNo; Rec."Entry No.")
                {
                    Caption = 'Entry No.';
                    ToolTip = 'Specifies the sequential number of this Fetch Log entry.';
                    ApplicationArea = All;
                }
                field(customerNumber; Rec."Customer No.")
                {
                    Caption = 'Customer No.';
                    ToolTip = 'Specifies the number of the customer this BBB retrieval attempt was made for.';
                    ApplicationArea = All;
                    // "customerNumber" matches "number" on the sibling page (50613) so the two
                    // endpoints join legibly (TDD §7.6).
                }
                field(customerSystemId; Rec."Customer SystemId")
                {
                    Caption = 'Customer System ID';
                    ToolTip = 'Specifies the stable system identifier of the customer this BBB retrieval attempt was made for. This value never changes, even if the customer number is renamed.';
                    ApplicationArea = All;
                    // The stable join key to ocpfBbbCustomerRatings.systemId (TDD §7.6).
                }
                field(attemptedAt; Rec."Attempted At")
                {
                    Caption = 'Attempted At';
                    ToolTip = 'Specifies the date and time this BBB retrieval attempt was made.';
                    ApplicationArea = All;
                }
                field(outcome; Rec."Outcome")
                {
                    Caption = 'Outcome';
                    ToolTip = 'Specifies whether this BBB retrieval attempt succeeded or failed.';
                    ApplicationArea = All;
                }
                field(failureReason; Rec."Failure Reason")
                {
                    Caption = 'Failure Reason';
                    ToolTip = 'Specifies why this BBB retrieval attempt failed. Blank when the attempt succeeded.';
                    ApplicationArea = All;
                }
                field(sourceStatusCode; Rec."Source Status Code")
                {
                    Caption = 'Source Status Code';
                    ToolTip = 'Specifies the status code returned by the BBB data source for this retrieval attempt. Zero means no response was received. This is diagnostic information and is not shown elsewhere in the product.';
                    ApplicationArea = All;
                }
                field(profileUrlUsed; Rec."Profile URL Used")
                {
                    Caption = 'Profile URL Used';
                    ToolTip = 'Specifies the BBB profile page address that was actually read for this retrieval attempt, at the time it was read.';
                    ApplicationArea = All;
                }
                field(durationMs; Rec."Duration (ms)")
                {
                    Caption = 'Duration (ms)';
                    ToolTip = 'Specifies how many milliseconds this BBB retrieval attempt took, from request to response.';
                    ApplicationArea = All;
                }
            }
        }
    }
}
