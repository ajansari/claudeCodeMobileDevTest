namespace OnlyCopilotFans.BBBInsights;

using Microsoft.Sales.Customer;   // UNVERIFIED — confirm the exact namespace against local symbols (see TDD §16 row 3)

table 50603 "ocpfBbbFetchLog"
{
    Caption = 'BBB Fetch Log';
    DataClassification = CustomerContent;
    DrillDownPageId = "ocpfBbbFetchLogList";
    LookupPageId = "ocpfBbbFetchLogList";

    // Mutability (Standards §2.2): audit / system table -> read-only to users. Rows are inserted
    // by ocpfBbbRatingMgt and are never edited (DR-6, FR-8). The list page and the API page both
    // set Editable = false.

    // Deliberately NOT stored on the log - this is load-bearing, not an omission (TDD §6.3). The
    // retrieved grade, accreditation flag, and complaint count are not written to log rows.
    // Storing them per attempt would make this table a grade history, which DR-8 forbids.

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            ToolTip = 'Specifies the sequential number of this Fetch Log entry.';
            AutoIncrement = true;
            DataClassification = SystemMetadata;
        }
        field(2; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
            ToolTip = 'Specifies the number of the customer this BBB retrieval attempt was made for.';
            TableRelation = Customer."No."; // UNVERIFIED — confirm table 18 "Customer" and field "No." against local symbols (see TDD §16 rows 1, 4)
            DataClassification = CustomerContent;
            // Human-filterable link (FR-9). Kept in step with a customer rename by the subscriber
            // in ocpfBbbCustomerSubscribers (TDD §6.8).
        }
        field(3; "Customer SystemId"; Guid)
        {
            Caption = 'Customer System ID';
            ToolTip = 'Specifies the stable system identifier of the customer this BBB retrieval attempt was made for. This value never changes, even if the customer number is renamed.';
            DataClassification = SystemMetadata;
            // The stable link: survives a customer number rename, and is what an API consumer
            // joins on (Standards §2.1's reasoning applied to a foreign key).
        }
        field(4; "Attempted At"; DateTime)
        {
            Caption = 'Attempted At';
            ToolTip = 'Specifies the date and time this BBB retrieval attempt was made.';
            DataClassification = SystemMetadata;
            // Set explicitly by the orchestrator. Not the same thing as the platform's
            // SystemCreatedAt: this one is part of the published API contract and is filterable
            // by design.
        }
        field(5; "Outcome"; Enum "ocpfBbbFetchStatus")
        {
            Caption = 'Outcome';
            ToolTip = 'Specifies whether this BBB retrieval attempt succeeded or failed.';
            DataClassification = SystemMetadata;
            // Only Succeeded (1) or Failed (2) is ever written here. NeverFetched (0) is
            // meaningless on a log row and never occurs.
        }
        field(6; "Failure Reason"; Text[250])
        {
            Caption = 'Failure Reason';
            ToolTip = 'Specifies why this BBB retrieval attempt failed. Blank when the attempt succeeded.';
            DataClassification = CustomerContent;
            // Business-readable reason (the same label text the user was shown - TDD §10.2),
            // truncated to 250 with CopyStr. Reclassified from SystemMetadata to CustomerContent
            // (CR-07, ChangeLog DEFINE-017): on an uncaught runtime error this field may now also
            // carry a bracketed, platform-echoed diagnostic detail (GetLastErrorText(), truncated)
            // appended after the business reason - text this extension did not author, so it can
            // no longer be assumed to be pure system metadata. Never shown to the user (NFR-9);
            // the Message() the user sees uses only the business-readable reason, never this
            // field's diagnostic suffix.
        }
        field(7; "Source Status Code"; Integer)
        {
            Caption = 'Source Status Code';
            ToolTip = 'Specifies the status code returned by the BBB data source for this retrieval attempt. Zero means no response was received. This is diagnostic information and is not shown elsewhere in the product.';
            DataClassification = SystemMetadata;
            // Diagnostic only - the provider's own status code; HTTP for the current provider
            // (renamed from "HTTP Status Code", ChangeLog DEFINE-008, resolving F-B-4: DR-3
            // forbids a transport-specific name in the permanent published contract). Never
            // shown to a user (NFR-9). 0 when no response was received.
        }
        field(8; "Profile URL Used"; Text[250])
        {
            Caption = 'Profile URL Used';
            ToolTip = 'Specifies the BBB profile page address that was actually read for this retrieval attempt, at the time it was read.';
            DataClassification = CustomerContent;
            // Which page was actually read, at the time it was read (DR-5 traceability - the URL
            // on the customer may have changed since).
        }
        field(9; "Duration (ms)"; Integer)
        {
            Caption = 'Duration (ms)';
            ToolTip = 'Specifies how many milliseconds this BBB retrieval attempt took, from request to response.';
            DataClassification = SystemMetadata;
            // Round-trip duration. The evidence that distinguishes "BBB is slow" from "BBB is
            // blocking us" (NFR-6 timeouts).
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(CustomerAttempt; "Customer No.", "Attempted At")
        {
            // FR-9's "filtered to a customer, newest first". Add "Outcome" to this key only if
            // Step 12 testing shows failure-only filtering is slow; do not pre-optimize.
        }
    }

    // Deletion behavior (FRD NFR-15 / OQ-6): cascade with the customer - implemented in
    // ocpfBbbCustomerSubscribers (50608), keyed on "Customer SystemId" (TDD §6.8).
    // Retention (FR-10 / OQ-5): none. No purge, no cap, ever, in v1 (TDD §13.3).
}
