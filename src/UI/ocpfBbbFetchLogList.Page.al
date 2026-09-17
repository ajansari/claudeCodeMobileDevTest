namespace OnlyCopilotFans.BBBInsights;

page 50611 "ocpfBbbFetchLogList"
{
    PageType = List;
    SourceTable = "ocpfBbbFetchLog";
    Caption = 'BBB Fetch Log';
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    SourceTableView = sorting("Entry No.") order(descending);
    // Newest attempt first — the only order a diagnostician wants (TDD §6.6).

    // Deliberately no UsageCategory: setting it publishes the page into Tell Me / role-explorer
    // search, and DR-9 forbids any Departments or Tell Me placement in v1. The page is reached
    // from the Customer Card action (50610) and by drill-down from the table. Every field still
    // carries ApplicationArea = All (Standards §1.4).

    // FR-9's "filtered to failures" (F-S-11, ChangeLog DEFINE-014): no saved view or FilterGroup
    // is built for v1 — "Outcome" below is an ordinary filterable column, so a user filters it to
    // Failed the same way as any other column.

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Attempted At"; Rec."Attempted At")
                {
                    Caption = 'Attempted At';
                    ToolTip = 'Specifies the date and time this BBB retrieval attempt was made.';
                    ApplicationArea = All;
                }
                field("Customer No."; Rec."Customer No.")
                {
                    Caption = 'Customer No.';
                    ToolTip = 'Specifies the number of the customer this BBB retrieval attempt was made for.';
                    ApplicationArea = All;
                }
                field(Outcome; Rec."Outcome")
                {
                    Caption = 'Outcome';
                    ToolTip = 'Specifies whether this BBB retrieval attempt succeeded or failed.';
                    ApplicationArea = All;
                }
                field("Failure Reason"; Rec."Failure Reason")
                {
                    Caption = 'Failure Reason';
                    ToolTip = 'Specifies why this BBB retrieval attempt failed. Blank when the attempt succeeded.';
                    ApplicationArea = All;
                }
                field("Source Status Code"; Rec."Source Status Code")
                {
                    Caption = 'Source Status Code';
                    ToolTip = 'Specifies the status code returned by the BBB data source for this retrieval attempt. Zero means no response was received. This is diagnostic information and is not shown elsewhere in the product.';
                    ApplicationArea = All;
                }
                field("Duration (ms)"; Rec."Duration (ms)")
                {
                    Caption = 'Duration (ms)';
                    ToolTip = 'Specifies how many milliseconds this BBB retrieval attempt took, from request to response.';
                    ApplicationArea = All;
                }
                field("Profile URL Used"; Rec."Profile URL Used")
                {
                    Caption = 'Profile URL Used';
                    ToolTip = 'Specifies the BBB profile page address that was actually read for this retrieval attempt, at the time it was read.';
                    ApplicationArea = All;
                }
            }
        }
    }
}
