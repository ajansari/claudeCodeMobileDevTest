namespace OnlyCopilotFans.BBBInsights;

using Microsoft.Sales.Customer; // UNVERIFIED — confirm the exact namespace against local symbols (see TDD §16 row 3)

pageextension 50610 "ocpfBbbCustomerCardExt" extends "Customer Card" // UNVERIFIED — confirm page 21 "Customer Card" against local symbols (see TDD §16 row 2)
{
    layout
    {
        addlast(content) // UNVERIFIED — confirm this anchor against the Customer Card's actual control tree in local symbols (see TDD §16 row 12)
        {
            group(ocpfBbbRatingGroup)
            {
                Caption = 'BBB Rating Insights';
                // Field order is the requirement, not decoration (TDD §6.5): grade, accreditation,
                // and complaint count first (the decision inputs — UC-1, UC-2), then the URL, then
                // the freshness pair last and together — FR-6 requires the stamp beside the
                // values, and BO-4 depends on the reader seeing "Failed" without hunting for it.

                field(ocpfBbbGrade; Rec."ocpfBbb Grade")
                {
                    Caption = 'BBB Grade';
                    ToolTip = 'Specifies the letter grade the Better Business Bureau has published for this customer, as read from their BBB profile page. "Not Fetched" means BBB data has never been retrieved for this customer; "NR" means BBB retrieved successfully and reports the business as Not Rated.';
                    Editable = false;
                    ApplicationArea = All;
                }
                field(ocpfBbbAccredited; Rec."ocpfBbb Accredited")
                {
                    Caption = 'BBB Accredited';
                    ToolTip = 'Specifies whether this customer is an accredited business with the Better Business Bureau. Accreditation is a separate fact from the BBB grade: an accredited business can hold any grade, and a non-accredited business can be graded.';
                    Editable = false;
                    ApplicationArea = All;
                }
                field(ocpfBbbComplaintCount; Rec."ocpfBbb Complaint Count")
                {
                    Caption = 'BBB Complaint Count';
                    ToolTip = 'Specifies the number of complaints the Better Business Bureau reports against this customer on their BBB profile page.';
                    Editable = false;
                    ApplicationArea = All;
                }
                field(ocpfBbbProfileUrl; Rec."ocpfBbb Profile URL")
                {
                    Caption = 'BBB Profile URL';
                    ToolTip = 'Specifies the address of this customer''s public Better Business Bureau profile page. Enter it manually; the address must start with https://. This is the page every refresh reads, so an incorrect address attaches another business''s rating to this customer.';
                    ApplicationArea = All;
                    // The only writable field of the group (DR-5, FR-6a). Its OnValidate
                    // permission check lives on the field itself (ocpfBbbCustomerExt, 50604).
                }
                field(ocpfBbbLastFetched; Rec."ocpfBbb Last Fetched")
                {
                    Caption = 'BBB Last Fetched';
                    ToolTip = 'Specifies when BBB data was last requested for this customer. This is stamped on every attempt, successful or not, so compare it with BBB Fetch Status before relying on the values shown.';
                    Editable = false;
                    ApplicationArea = All;
                }
                field(ocpfBbbFetchStatus; Rec."ocpfBbb Fetch Status")
                {
                    Caption = 'BBB Fetch Status';
                    ToolTip = 'Specifies how the last BBB retrieval attempt ended. When this is Failed, the grade, accreditation, and complaint count shown are the last values successfully retrieved and are not current.';
                    Editable = false;
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
        addlast(processing) // UNVERIFIED — confirm the action area name against local symbols (see TDD §16 row 12)
        {
            action(ocpfBbbRefreshRating)
            {
                Caption = 'Refresh BBB Data';
                ToolTip = 'Retrieves the current BBB grade, accreditation status, and complaint count for this customer from their BBB profile page.';
                ApplicationArea = All;
                Image = Refresh;
                Enabled = RefreshAllowed;
                Promoted = true; // UNVERIFIED — confirm the promoted-action property shape for a page extension on this runtime against local symbols (see TDD §16 row 13)
                PromotedCategory = Process;
                PromotedOnly = true;

                trigger OnAction()
                begin
                    // No logic in the page — the action calls the orchestrator and nothing else
                    // (TDD §6.5).
                    RatingMgt.RefreshRating(Rec);
                end;
            }
            action(ocpfBbbShowFetchLog)
            {
                Caption = 'BBB Fetch Log';
                ToolTip = 'Shows every BBB retrieval attempt recorded for this customer, including failures and the reason for each.';
                ApplicationArea = All;
                Image = Log;
                // Available to VIEW holders too — it is read-only (UC-6).

                trigger OnAction()
                var
                    FetchLogList: Page "ocpfBbbFetchLogList";
                    FetchLog: Record "ocpfBbbFetchLog";
                begin
                    FetchLog.SetRange("Customer No.", Rec."No."); // UNVERIFIED — "No.", see TDD §16 row 4
                    FetchLogList.SetTableView(FetchLog);
                    FetchLogList.Run();
                end;
            }
        }
    }

    var
        RatingMgt: Codeunit "ocpfBbbRatingMgt";
        RefreshAllowed: Boolean;

    trigger OnOpenPage()
    var
        FetchLog: Record "ocpfBbbFetchLog";
    begin
        // Permission gating of the refresh action (resolves OQ-4 at the UI, TDD §6.5). Every
        // successful AND failed refresh must insert a Fetch Log row (DR-2), so write permission
        // on ocpfBbbFetchLog is precisely the permission a refresh needs. A Sales user therefore
        // sees the data and a greyed-out action instead of a permission error (NFR-9). The
        // orchestrator re-checks the same condition server-side (TDD §7.2 step 1), so the rule
        // holds for any caller, not just this page. UNVERIFIED (TDD §16 row 24): whether a page
        // extension may declare OnOpenPage and use a page global in an action's Enabled property.
        RefreshAllowed := FetchLog.WritePermission();
    end;
}
