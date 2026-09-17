namespace OnlyCopilotFans.BBBInsights;

using Microsoft.Sales.Customer; // UNVERIFIED — confirm the exact namespace against local symbols (see TDD §16 row 3)

tableextension 50604 "ocpfBbbCustomerExt" extends Customer // UNVERIFIED — confirm table 18 "Customer" against local symbols (see TDD §16 row 1)
{
    // Field IDs come from this extension's own object range - AL requires extension fields on a
    // standard table to use IDs inside the allocated range, and 50601-50620 is exclusively ours,
    // so no collision with another extension is possible (TDD §6.4).

    fields
    {
        field(50601; "ocpfBbb Grade"; Enum "ocpfBbbGrade")
        {
            Caption = 'BBB Grade';
            ToolTip = 'Specifies the letter grade the Better Business Bureau has published for this customer, as read from their BBB profile page. "Not Fetched" means BBB data has never been retrieved for this customer; "NR" means BBB retrieved successfully and reports the business as Not Rated.';
            Editable = false;
            DataClassification = CustomerContent;
            // System-owned (DR-6). Editable = false blocks edits from the UI and from OData
            // (TDD §6.4); it does not block AL code, which is how ocpfBbbRatingMgt writes it.
        }
        field(50602; "ocpfBbb Accredited"; Boolean)
        {
            Caption = 'BBB Accredited';
            ToolTip = 'Specifies whether this customer is an accredited business with the Better Business Bureau. Accreditation is a separate fact from the BBB grade: an accredited business can hold any grade, and a non-accredited business can be graded.';
            Editable = false;
            DataClassification = CustomerContent;
        }
        field(50603; "ocpfBbb Complaint Count"; Integer)
        {
            Caption = 'BBB Complaint Count';
            ToolTip = 'Specifies the number of complaints the Better Business Bureau reports against this customer on their BBB profile page.';
            Editable = false;
            DataClassification = CustomerContent;
        }
        field(50604; "ocpfBbb Profile URL"; Text[250])
        {
            Caption = 'BBB Profile URL';
            ToolTip = 'Specifies the address of this customer''s public Better Business Bureau profile page. Enter it manually; the address must start with https://. This is the page every refresh reads, so an incorrect address attaches another business''s rating to this customer.';
            ExtendedDatatype = Url; // UNVERIFIED — confirm ExtendedDatatype = URL renders a clickable link on the card against local symbols (see TDD §16 row 25)
            DataClassification = CustomerContent;
            // Staff-owned (DR-5, FR-6a). Editable defaults to true — the only writable field of
            // the six this extension adds.

            trigger OnValidate()
            var
                FetchLog: Record "ocpfBbbFetchLog";
            begin
                // Precondition (permission) checked first (F-B-1, ChangeLog DEFINE-007). Standard
                // Customer write permission is not this extension's access model - a Sales rep
                // with ordinary tabledata Customer = M can edit any field on the Customer Card,
                // including this one, through permissioning this extension does not control.
                // FetchLog.WritePermission() is the same test the refresh action uses (§6.5) to
                // mean "holds OCPFBBB BBBRI, EDIT".
                if not FetchLog.WritePermission() then
                    Error(NoUrlEditPermissionErr);

                if (Rec."ocpfBbb Profile URL" <> '') and
                   (StrPos(LowerCase(Rec."ocpfBbb Profile URL"), HttpsPrefixTok) <> 1) then
                    Error(ProfileUrlNotHttpsErr);

                // No OnValidate that clears the retrieved values when the URL changes. Tempting,
                // and wrong: clearing them is an overwrite of good data by something that is not
                // a successful fetch, which DR-1 forbids. The stale-but-stamped values stay until
                // a refresh replaces them; "ocpfBbb Last Fetched" tells the reader how old they
                // are. The host is deliberately not validated either: DR-5 says the URL is
                // staff-entered and staff-owned, and a hardcoded bbb.org host check would be this
                // extension quietly deciding what a valid BBB page is.
            end;
        }
        field(50605; "ocpfBbb Last Fetched"; DateTime)
        {
            Caption = 'BBB Last Fetched';
            ToolTip = 'Specifies when BBB data was last requested for this customer. This is stamped on every attempt, successful or not, so compare it with BBB Fetch Status before relying on the values shown.';
            Editable = false;
            DataClassification = CustomerContent;
        }
        field(50606; "ocpfBbb Fetch Status"; Enum "ocpfBbbFetchStatus")
        {
            Caption = 'BBB Fetch Status';
            ToolTip = 'Specifies how the last BBB retrieval attempt ended. When this is Failed, the grade, accreditation, and complaint count shown are the last values successfully retrieved and are not current.';
            Editable = false;
            DataClassification = CustomerContent;
        }
    }

    var
        NoUrlEditPermissionErr: Label 'You do not have permission to edit the BBB Profile URL. Ask your administrator for the BBB Rating Insights - Edit permission set.';
        ProfileUrlNotHttpsErr: Label 'The BBB profile URL must start with https://.';
        HttpsPrefixTok: Label 'https://', Locked = true;
}
