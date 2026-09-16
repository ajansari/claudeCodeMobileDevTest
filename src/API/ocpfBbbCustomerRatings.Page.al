namespace OnlyCopilotFans.BBBInsights;

using Microsoft.Sales.Customer; // UNVERIFIED — confirm the exact namespace against local symbols (see TDD §16 row 3)

page 50613 "ocpfBbbCustomerRatings"
{
    PageType = API;
    Caption = 'Represents the Better Business Bureau rating information held against a customer, together with the time and outcome of the last retrieval attempt.';
    APIPublisher = 'onlyCopilotFans';
    APIGroup = 'ocpfBbbRatings';
    APIVersion = 'v1.0';
    EntityName = 'ocpfBbbCustomerRating';
    EntitySetName = 'ocpfBbbCustomerRatings';
    EntityCaption = 'BBB Customer Rating';
    EntitySetCaption = 'BBB Customer Ratings';
    // Translatable — decided by AJ Ansari, 2026-09-16 (ChangeLog DEFINE-006; TDD §11.2). Business
    // classification: Microsoft's API v2.0 leaves all 1,526 captions on its business pages and
    // queries translatable — 0 locked.
    SourceTable = Customer; // UNVERIFIED — confirm table 18 "Customer" against local symbols (see TDD §16 row 1)
    ODataKeyFields = SystemId;
    DelayedInsert = true;
    // Standards §2.2: master data → editable, full stop — mutability decides, not preference.
    // Read-only access for reporting consumers is enforced in the "OCPFBBB BBBRI, VIEW"
    // permission set (TDD §9), not here. Five of the six BBB fields are additionally
    // Editable = false at field level (DR-6), so the only writable field on this endpoint is the
    // profile URL.
    InsertAllowed = false;
    DeleteAllowed = false;
    // This endpoint must not become a way to create or delete customers — DR-13 ("the extension
    // adds; it never alters"). DelayedInsert = true is kept because Standards §2.2 mandates it on
    // an editable page; with InsertAllowed = false it is simply inert (TDD §6.11).

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
                field(number; Rec."No.") // UNVERIFIED — confirm field "No." against local symbols (see TDD §16 row 4)
                {
                    Caption = 'No.';
                    ToolTip = 'Specifies the number of the customer.';
                    Editable = false;
                    ApplicationArea = All;
                    // "number" is Microsoft's own identifier for this field on API v2.0
                    // customers. Recorded deviation from §4.1's mechanical "no" (TDD §7.5).
                }
                field(displayName; Rec.Name) // UNVERIFIED — confirm field "Name" against local symbols (see TDD §16 row 5)
                {
                    Caption = 'Display Name';
                    ToolTip = 'Specifies the name of the customer, enough to identify the customer.';
                    Editable = false;
                    ApplicationArea = All;
                }
                field(countryRegionCode; Rec."Country/Region Code") // UNVERIFIED — confirm field against local symbols (see TDD §16 row 6)
                {
                    Caption = 'Country/Region Code';
                    ToolTip = 'Specifies the country/region code of the customer.';
                    Editable = false;
                    ApplicationArea = All;
                }
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
                    // The only writable field on this endpoint (DR-6, FR-6a).
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
}
