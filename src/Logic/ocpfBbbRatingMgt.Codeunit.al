namespace OnlyCopilotFans.BBBInsights;

using Microsoft.Sales.Customer; // UNVERIFIED — confirm the exact namespace against local symbols (see TDD §16 row 3)
using Microsoft.Foundation.Address; // UNVERIFIED — confirm the exact namespace against local symbols (see TDD §16 row 9). Two `using` directives here are a recorded, approved deviation from the one-`using` template shape (F-S-6, ChangeLog DEFINE-011, TDD §8.1).

codeunit 50606 "ocpfBbbRatingMgt"
{
    Caption = 'BBB Rating Management';

    // The orchestrator. It contains no knowledge whatsoever of how BBB data is obtained (DR-3) —
    // it talks only to the "ocpfBbbRatingProvider" interface. The ONLY reference to the concrete
    // provider codeunit "ocpfBbbProfileReader" in this entire codeunit is the single binding-point
    // assignment inside RefreshRating below (TDD §7.1) — this is the DR-3 isolation boundary made
    // structural, and a future change referencing ocpfBbbProfileReader anywhere else in this file
    // is a defect.

    /// <summary>
    /// FR-2. The single entry point for a BBB refresh. Called by the Customer Card action
    /// (page extension 50610) and by nothing else in v1.
    /// </summary>
    procedure RefreshRating(var Cust: Record Customer) // UNVERIFIED — confirm table 18 "Customer" against local symbols (see TDD §16 row 1)
    var
        FetchLog: Record "ocpfBbbFetchLog";
        Provider: Interface "ocpfBbbRatingProvider";
        ProfileReader: Codeunit "ocpfBbbProfileReader";
        Grade: Enum "ocpfBbbGrade";
        Accredited: Boolean;
        ComplaintCount: Integer;
        FailureReason: Text;
        SourceStatusCode: Integer;
        DurationMs: Integer;
        AttemptedAt: DateTime;
        ProfileUrl: Text;
        Succeeded: Boolean;
    begin
        // Step 1 — Permission re-check (OQ-4 enforced server-side, not just a greyed-out button
        // on the Customer Card — TDD §6.5). Safe to Error here: nothing has been written yet and
        // no outbound call has been made.
        if not FetchLog.WritePermission() then
            Error(NoRefreshPermissionErr);

        // Step 2 — Preconditions, in order, each ending in its own labeled Error (FR-5, DR-4,
        // OQ-2, F-S-1). Step 3 — a precondition refusal is NOT a fetch attempt: the Error rolls
        // back the transaction, so nothing is stamped and nothing is logged (DR-2, as clarified
        // by FRD DR-2's amended wording — F-S-2, ChangeLog DEFINE-009).
        CheckPreconditions(Cust);

        // Step 4 — Capture a single consistent timestamp and the URL, then call the provider —
        // BEFORE any database write in this transaction (§6.10's HTTP-after-write constraint;
        // DR-2's stamp uses this one timestamp on both branches).
        AttemptedAt := CurrentDateTime();
        ProfileUrl := Cust."ocpfBbb Profile URL";

        // Step 5 — The whole of DR-3's coupling: this extension knows nothing beyond the
        // interface contract from this line onward.
        Provider := ProfileReader; // ← the single binding point in the entire extension (TDD §7.1)
        Succeeded := Provider.TryGetRating(ProfileUrl, Grade, Accredited, ComplaintCount, FailureReason, SourceStatusCode, DurationMs);

        // Steps 6–7 — DR-1, the single most important line in this document: a failed refresh
        // never overwrites good data.
        if Succeeded then
            ApplySuccess(Cust, Grade, Accredited, ComplaintCount)
        else
            ApplyFailure(Cust);

        // Step 8 — On BOTH branches: stamp and persist (DR-2, FR-4). Corrected explicit if/else
        // (F-S-10, ChangeLog DEFINE-014) — AL has no ternary conditional operator.
        Cust."ocpfBbb Last Fetched" := AttemptedAt;
        if Succeeded then
            Cust."ocpfBbb Fetch Status" := Enum::"ocpfBbbFetchStatus"::Succeeded
        else
            Cust."ocpfBbb Fetch Status" := Enum::"ocpfBbbFetchStatus"::Failed;
        Cust.Modify(true); // Modify(true), not Modify(false): running OnModify keeps standard
                            // behavior and every other extension's subscribers intact (DR-13).

        // Step 9 — On BOTH branches: insert one audit row (DR-2, FR-8).
        WriteLogEntry(Cust, AttemptedAt, ProfileUrl, Succeeded, FailureReason, SourceStatusCode, DurationMs);

        // Step 10 — Raise the extension's single published extension point (§13.2).
        OnAfterRefreshRatingAttempt(Cust, Succeeded);

        // Step 11 — Report to the user with a Message, NEVER an Error: an Error here would roll
        // back steps 8 and 9, destroying exactly the stamp and log entry DR-2 demands. Any code
        // that ends a failed fetch in Error is a defect, no matter how well-worded the message.
        if Succeeded then
            Message(RefreshSucceededMsg, Cust."No.") // UNVERIFIED — confirm field "No." against local symbols (see TDD §16 row 4)
        else
            Message(RefreshFailedMsg, Cust."No.", FailureReason);
    end;

    /// <summary>
    /// DR-4's rule, exposed so the UI (or a future list page) can pre-test without triggering an
    /// attempt.
    /// </summary>
    procedure IsRefreshAllowedForCountry(Cust: Record Customer): Boolean // UNVERIFIED — Customer, see TDD §16 row 1
    begin
        exit(ResolveCountryIso(Cust));
    end;

    /// <summary>
    /// The extension's single published extension point (Standards §10.4). No sender, no global
    /// var access (Standards §10.2's default). Carries no Handled parameter — a Handled hook
    /// would let a subscriber replace the refresh itself, reintroducing a second, unknown
    /// retrieval mechanism into an extension whose whole design premise (DR-3) is one swappable
    /// provider behind one interface. Once v1 ships, this signature is a promise (Standards
    /// §10.3): never renamed, never re-parameterized.
    /// </summary>
    [IntegrationEvent(false, false)]
    local procedure OnAfterRefreshRatingAttempt(Customer: Record Customer; Succeeded: Boolean) // UNVERIFIED — Customer, see TDD §16 row 1
    begin
    end;

    local procedure CheckPreconditions(Cust: Record Customer)
    begin
        // (a)
        if Cust."ocpfBbb Profile URL" = '' then
            Error(NoProfileUrlErr, Cust."No."); // UNVERIFIED — "No.", see TDD §16 row 4

        // (b)
        if Cust."Country/Region Code" = '' then // UNVERIFIED — confirm field against local symbols (see TDD §16 row 6)
            Error(CountryBlankErr, Cust."No.");

        // (c)
        if not IsRefreshAllowedForCountry(Cust) then
            Error(CountryNotSupportedErr, Cust."No.", Cust."Country/Region Code");

        // (d) — checked before the outbound call, so a Credit & Risk user with read-only rights
        // on the customer master doesn't trigger a wasted external call and then meet a raw
        // platform error on Modify (F-S-1, ChangeLog DEFINE-014).
        if not Cust.WritePermission() then
            Error(NoCustomerWritePermissionErr, Cust."No.");
    end;

    local procedure ResolveCountryIso(Cust: Record Customer): Boolean
    var
        CountryRegion: Record "Country/Region"; // UNVERIFIED — confirm table number/object name against local symbols (see TDD §16 row 7)
        CountryRegionCode: Code[10]; // UNVERIFIED — confirm the exact type of Customer."Country/Region Code" against local symbols (see TDD §16 row 6)
    begin
        // FRD PA-5 rates the mechanism High and the data Medium: "US" and "CA" are conventional
        // Country/Region codes, not platform constants, and a tenant may use "USA", "840", or
        // anything else. So the check resolves the code to an ISO value rather than
        // string-matching a guess (TDD §7.2.1).
        CountryRegionCode := Cust."Country/Region Code"; // UNVERIFIED — see TDD §16 row 6

        // Step 2 — blank → not supported (OQ-2: blank is refused like any unsupported country).
        if CountryRegionCode = '' then
            exit(false);

        // Step 3–4 — resolve to the Country/Region record's own ISO Code when possible.
        if CountryRegion.Get(CountryRegionCode) then // UNVERIFIED — Get() key and existence of "ISO Code" field, see TDD §16 rows 7-8
            if CountryRegion."ISO Code" <> '' then // UNVERIFIED — see TDD §16 row 8
                exit((CountryRegion."ISO Code" = 'US') or (CountryRegion."ISO Code" = 'CA'));

        // Step 5 — record missing, or ISO Code blank → fall back to the raw Country/Region Code.
        // Step 6 — never "assume in scope" on ambiguity: refusal is the safe direction.
        exit((CountryRegionCode = 'US') or (CountryRegionCode = 'CA'));
    end;

    local procedure ApplySuccess(var Cust: Record Customer; Grade: Enum "ocpfBbbGrade"; Accredited: Boolean; ComplaintCount: Integer)
    begin
        // FR-3 — written ONLY inside the success branch (DR-1).
        Cust."ocpfBbb Grade" := Grade;
        Cust."ocpfBbb Accredited" := Accredited;
        Cust."ocpfBbb Complaint Count" := ComplaintCount;
    end;

    local procedure ApplyFailure(var Cust: Record Customer)
    begin
        // DR-1 — the single most important line in this document: on failure, "ocpfBbb Grade",
        // "ocpfBbb Accredited", and "ocpfBbb Complaint Count" are left exactly as they were. Not
        // blanked, not zeroed, not set to a "stale" placeholder. This procedure is a deliberate,
        // documented no-op — its existence, not its body, is the guarantee: a future edit that
        // adds a field write here has broken DR-1.
    end;

    local procedure WriteLogEntry(Cust: Record Customer; AttemptedAt: DateTime; ProfileUrl: Text; Succeeded: Boolean; FailureReason: Text; SourceStatusCode: Integer; DurationMs: Integer)
    var
        FetchLog: Record "ocpfBbbFetchLog";
    begin
        // DR-2, FR-8 — one row inserted on every attempt, success or failure. Deliberately does
        // NOT store the retrieved grade/accreditation/complaint count (DR-8) — this table is an
        // attempt log, never a grade time series.
        FetchLog.Init();
        FetchLog."Customer No." := Cust."No."; // UNVERIFIED — "No.", see TDD §16 row 4
        FetchLog."Customer SystemId" := Cust.SystemId;
        FetchLog."Attempted At" := AttemptedAt;
        if Succeeded then
            FetchLog."Outcome" := Enum::"ocpfBbbFetchStatus"::Succeeded
        else
            FetchLog."Outcome" := Enum::"ocpfBbbFetchStatus"::Failed;
        FetchLog."Failure Reason" := CopyStr(FailureReason, 1, MaxStrLen(FetchLog."Failure Reason"));
        FetchLog."Source Status Code" := SourceStatusCode;
        FetchLog."Profile URL Used" := CopyStr(ProfileUrl, 1, MaxStrLen(FetchLog."Profile URL Used"));
        FetchLog."Duration (ms)" := DurationMs;
        FetchLog.Insert(true);
    end;

    var
        NoRefreshPermissionErr: Label 'You do not have permission to refresh BBB data. Ask your administrator for the BBB Rating Insights - Edit permission set.';
        NoCustomerWritePermissionErr: Label 'You do not have write permission on customer %1. Ask your administrator for edit rights on the customer, then try refreshing BBB data again.', Comment = '%1 = Customer No.';
        NoProfileUrlErr: Label 'Enter a BBB profile URL for customer %1 before refreshing BBB data.', Comment = '%1 = Customer No.';
        CountryBlankErr: Label 'Customer %1 has no country/region. BBB covers the United States and Canada only, so enter the customer''s country/region before refreshing BBB data.', Comment = '%1 = Customer No.';
        CountryNotSupportedErr: Label 'BBB covers the United States and Canada only. Customer %1 has country/region %2, so BBB data cannot be refreshed for this customer.', Comment = '%1 = Customer No., %2 = Country/Region Code';
        RefreshSucceededMsg: Label 'BBB data for customer %1 was refreshed successfully.', Comment = '%1 = Customer No.';
        RefreshFailedMsg: Label 'The BBB refresh for customer %1 did not succeed: %2 The BBB values shown are the ones last retrieved successfully and have not been changed.', Comment = '%1 = Customer No., %2 = failure reason sentence';
}
