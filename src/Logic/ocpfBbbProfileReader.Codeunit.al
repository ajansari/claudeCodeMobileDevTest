namespace OnlyCopilotFans.BBBInsights;

using System.Utilities; // UNVERIFIED — HttpClient/HttpResponseMessage may be platform types needing no `using` at all; confirm against local symbols (see TDD §16 rows 14-15)

codeunit 50607 "ocpfBbbProfileReader" implements "ocpfBbbRatingProvider"
{
    // BBB Profile Reader — codeunits have no Caption property (AL object model); this name is
    // carried by the object name itself. Removed during Step 07 troubleshooting: an invalid
    // property the TDD's own per-object table incorrectly listed for every codeunit.

    // The replaceable component (DR-3/NFR-2). The only object in this extension that knows BBB
    // exists as a website. Responsibilities it must never take on: writing to any table, showing
    // any message, deciding whether a refresh is allowed, or knowing what a Customer is. Its only
    // input is a URL string.

    // ============================================================================================
    // PLATFORM CONSTRAINTS (both UNVERIFIED — confirm on the sandbox before this batch is relied
    // on; see TDD §6.10 and §16):
    //   - AL has no HTML DOM parser (FRD PA-4). Interpretation below is text/pattern matching over
    //     the response body.
    //   - BC does not permit an outbound HTTP call after a write in the same transaction — this
    //     codeunit never writes to any table, so that constraint cannot be violated here.
    // ============================================================================================

    /// <summary>
    /// Implements "ocpfBbbRatingProvider".TryGetRating. Issues exactly one HTTPS GET (NFR-3 — no
    /// retry, no follow-on request, no bulk loop), bounded by a 20-second timeout (NFR-6), and
    /// returns true only when every out-parameter was actually read from the response.
    /// The outbound call and all response parsing happen inside the [TryFunction] local procedure
    /// below (F-B-2, ChangeLog DEFINE-014) — an uncaught runtime error there is converted into an
    /// ordinary parse failure and never escapes this procedure.
    /// </summary>
    procedure TryGetRating(ProfileUrl: Text; var Grade: Enum "ocpfBbbGrade"; var Accredited: Boolean; var ComplaintCount: Integer; var FailureReason: Text; var SourceStatusCode: Integer; var DurationMs: Integer; var DiagnosticDetail: Text): Boolean
    var
        StartTime: DateTime;
        EndTime: DateTime;
        Success: Boolean;
    begin
        StartTime := CurrentDateTime();
        FailureReason := '';
        SourceStatusCode := 0;
        DiagnosticDetail := '';
        Success := false;

        if not TryFetchAndParse(ProfileUrl, Grade, Accredited, ComplaintCount, FailureReason, SourceStatusCode, Success) then begin
            // F-B-2 (ChangeLog DEFINE-014): an unexpected runtime error was caught by the
            // [TryFunction] wrapper. Convert it into an ordinary parse failure — never let it
            // propagate and roll back the caller's stamp and log write. REVIEWER-UNVERIFIED
            // (TDD §16 row 19): the exact scope of what [TryFunction] does and does not catch
            // must be confirmed locally before this batch is relied on.
            //
            // CR-07 (ChangeLog DEFINE-017): capture the platform's own diagnosis for the log —
            // and ONLY here, on this caught-error path, never on an ordinary business-reason
            // failure below. GetLastErrorText() must be read immediately after the failed call,
            // since the session error buffer can be overwritten by a later one. This text goes to
            // the log field only (via WriteLogEntry in ocpfBbbRatingMgt) — never to the user
            // (NFR-9); FailureReason (below) is what the Message() to the user actually shows.
            Success := false;
            FailureReason := UnexpectedReasonTxt;
            SourceStatusCode := 0;
            DiagnosticDetail := CopyStr(GetLastErrorText(), 1, 250);
        end;

        EndTime := CurrentDateTime();
        DurationMs := EndTime - StartTime;

        exit(Success);
    end;

    [TryFunction]
    local procedure TryFetchAndParse(ProfileUrl: Text; var Grade: Enum "ocpfBbbGrade"; var Accredited: Boolean; var ComplaintCount: Integer; var FailureReason: Text; var SourceStatusCode: Integer; var Success: Boolean)
    var
        HttpClient: HttpClient; // UNVERIFIED — confirm type name/namespace requirement against local symbols (see TDD §16 row 14)
        HttpResponseMessage: HttpResponseMessage; // UNVERIFIED — see TDD §16 row 14
        Uri: Codeunit Uri; // UNVERIFIED — confirm the "Uri" data type/codeunit name and IsValidUriPattern's exact method name and signature against local symbols (CR-05, new TDD §16 row; see also TDD §6.10, §7.3)
        ResponseBody: Text;
    begin
        Success := false;

        // Host validation (CR-05, ChangeLog DEFINE-017): the field's own OnValidate
        // (ocpfBbbCustomerExt.TableExt.al) checks only the scheme at data-entry time — DR-5 keeps
        // *which* BBB page a staff-owned decision. This check is the fetch-time guardrail: it
        // refuses to place the outbound call at all unless the URL's host is a bbb.org address,
        // closing the SSRF exposure of calling an arbitrary attacker-supplied host. UNVERIFIED —
        // confirm Uri.IsValidUriPattern's exact name/signature locally before this batch is relied
        // on (see the Uri variable's UNVERIFIED note above).
        if not Uri.IsValidUriPattern(ProfileUrl, BbbHostPatternTok) then begin
            FailureReason := InvalidHostReasonTxt;
            SourceStatusCode := 0;
            exit;
        end;

        HttpClient.Timeout := 20000; // UNVERIFIED — confirm HttpClient.Timeout property against local symbols (TDD §16 row 14). NFR-6: a timeout is an ordinary failure under FR-4, not an exception.
        HttpClient.DefaultRequestHeaders.Add('User-Agent', UserAgentTok); // UNVERIFIED — confirm DefaultRequestHeaders API shape against local symbols (TDD §16 row 14)

        // CR-02 (ChangeLog DEFINE-017): HttpClient.Get returning false covers a blocked outbound
        // call, DNS failure, connection refused, TLS failure, and an actual timeout alike — AL
        // exposes no way from this session to tell them apart (the former CallWasBlockedByEnvironment
        // stub always returned false, which made the "not allowed" branch and its label dead code,
        // CR-02). One neutral, honest reason covers all of them until VT-2 proves otherwise.
        if not HttpClient.Get(ProfileUrl, HttpResponseMessage) then begin // UNVERIFIED — confirm HttpClient.Get signature against local symbols (TDD §16 row 14). NFR-3: exactly one GET, no retry, no follow-on request, no bulk loop.
            FailureReason := ConnectionFailedReasonTxt;
            SourceStatusCode := 0;
            exit;
        end;

        SourceStatusCode := HttpResponseMessage.HttpStatusCode(); // UNVERIFIED — confirm property/method name against local symbols (TDD §16 row 14)

        if not HttpResponseMessage.IsSuccessStatusCode() then begin // UNVERIFIED — see TDD §16 row 14
            FailureReason := MapStatusCodeToReason(SourceStatusCode);
            exit;
        end;

        if not HttpResponseMessage.Content().ReadAs(ResponseBody) then begin // UNVERIFIED — confirm HttpContent.ReadAs signature against local symbols (TDD §16 row 14)
            FailureReason := ParseFailedReasonTxt;
            exit;
        end;

        // A provider returns true only when it read EVERY value (TDD §7.1) — partial success is
        // failure. Each parse step below fails the whole attempt on its own.
        if not ParseGrade(ResponseBody, Grade) then begin
            FailureReason := ParseFailedReasonTxt;
            exit;
        end;

        if not ParseAccredited(ResponseBody, Accredited) then begin
            FailureReason := ParseFailedReasonTxt;
            exit;
        end;

        if not ParseComplaintCount(ResponseBody, ComplaintCount) then begin
            FailureReason := ParseFailedReasonTxt;
            exit;
        end;

        Success := true;
    end;

    local procedure MapStatusCodeToReason(StatusCode: Integer): Text
    begin
        // TDD §7.3's HTTP status → user-facing reason mapping. "2xx but not interpretable" is
        // handled separately, by the Parse* failure branches above (ParseFailedReasonTxt) — this
        // map only covers non-success status codes.
        case StatusCode of
            404:
                exit(NotFoundReasonTxt);
            401, 403, 429:
                exit(BlockedReasonTxt);
            else
                if (StatusCode >= 500) and (StatusCode <= 599) then
                    exit(UnavailableReasonTxt);
        end;
        exit(UnexpectedReasonTxt); // "anything else" (TDD §7.3's final row)
    end;

    // ============================================================================================
    // PLACEHOLDER PARSE MARKERS — DO NOT SHIP AS-IS.
    // VT-3 (TDD §7.3, §15.2) could not be resolved in this session: there is no network access to
    // bbb.org here, so the exact anchor text/markup BBB uses for the letter grade, the
    // accreditation state, and the complaint count — and the exact window the complaint count
    // covers (OQ-3) — are all unknown. The three tokens below and the three Parse* procedures that
    // use them are PLACEHOLDERS with a plausible shape, not verified markers.
    //
    // AJ ANSARI MUST, BEFORE THIS CODEUNIT IS RELIED ON:
    //   1. Open a real BBB business profile page and find the actual surrounding text/markup for
    //      the letter grade, the accreditation state, and the complaint count (TDD §7.3's table).
    //   2. Confirm what the complaint count figure actually counts (OQ-3 — commonly a 3-year
    //      window), and update the ToolTip on "ocpfBbb Complaint Count" (TDD §7.4) accordingly.
    //   3. Replace the three placeholder tokens and the parsing logic in ParseGrade,
    //      ParseAccredited, and ParseComplaintCount below with real markers and real extraction.
    //
    // Until that is done, every call through this codeunit will fail to find the placeholder
    // tokens in a real response and will therefore return a parse failure (Succeeded = false),
    // which is the safe, DR-1-compliant behavior for an untuned parser: it will never write a
    // wrong value to a customer record.
    // ============================================================================================

    local procedure ParseGrade(ResponseBody: Text; var Grade: Enum "ocpfBbbGrade"): Boolean
    var
        GradeText: Text;
    begin
        if StrPos(ResponseBody, GradeAnchorPlaceholderTok) = 0 then
            exit(false);

        GradeText := ''; // PLACEHOLDER — real implementation extracts the grade substring here.
        exit(MapGradeText(GradeText, Grade));
    end;

    local procedure MapGradeText(GradeText: Text; var Grade: Enum "ocpfBbbGrade"): Boolean
    begin
        // An unmappable grade is a parse failure, never a guess (DR-1, TDD §6.1) — there is
        // deliberately no catch-all enum member to fall back to.
        case GradeText of
            'A+':
                Grade := Enum::"ocpfBbbGrade"::APlus;
            'A':
                Grade := Enum::"ocpfBbbGrade"::A;
            'A-':
                Grade := Enum::"ocpfBbbGrade"::AMinus;
            'B+':
                Grade := Enum::"ocpfBbbGrade"::BPlus;
            'B':
                Grade := Enum::"ocpfBbbGrade"::B;
            'B-':
                Grade := Enum::"ocpfBbbGrade"::BMinus;
            'C+':
                Grade := Enum::"ocpfBbbGrade"::CPlus;
            'C':
                Grade := Enum::"ocpfBbbGrade"::C;
            'C-':
                Grade := Enum::"ocpfBbbGrade"::CMinus;
            'D+':
                Grade := Enum::"ocpfBbbGrade"::DPlus;
            'D':
                Grade := Enum::"ocpfBbbGrade"::D;
            'D-':
                Grade := Enum::"ocpfBbbGrade"::DMinus;
            'F':
                Grade := Enum::"ocpfBbbGrade"::F;
            'NR':
                Grade := Enum::"ocpfBbbGrade"::NR;
            else
                exit(false);
        end;
        exit(true);
    end;

    local procedure ParseAccredited(ResponseBody: Text; var Accredited: Boolean): Boolean
    begin
        // PLACEHOLDER LOGIC. `false` must mean "the page said not accredited", never "we
        // couldn't tell" (TDD §7.3, UC-2) — absent/ambiguous is a parse failure, never a default.
        if StrPos(ResponseBody, AccreditedAnchorPlaceholderTok) = 0 then
            exit(false);

        Accredited := false; // PLACEHOLDER — real implementation sets this from the actual page.
        exit(true);
    end;

    local procedure ParseComplaintCount(ResponseBody: Text; var ComplaintCount: Integer): Boolean
    begin
        // PLACEHOLDER LOGIC. Real implementation reads a non-negative integer from the figure
        // BBB displays most prominently (OQ-3 — see the prominent comment block above).
        if StrPos(ResponseBody, ComplaintCountAnchorPlaceholderTok) = 0 then
            exit(false);

        ComplaintCount := 0; // PLACEHOLDER — real implementation parses the actual figure here.
        exit(true);
    end;

    var
        // CR-02 (ChangeLog DEFINE-017): CallNotAllowedReasonTxt and TimeoutReasonTxt were replaced
        // with one neutral, honest reason — ConnectionFailedReasonTxt — since the former
        // CallWasBlockedByEnvironment() stub always returned false, making the "not allowed"
        // branch and its label unreachable dead code (Standards §1.5), and every genuine
        // connection-level failure (blocked call, DNS failure, connection refused, TLS failure,
        // or an actual timeout) was being reported to the user as "did not respond in time" —
        // which sends an administrator to the wrong place when the real cause is a blocked
        // outbound call. Provisional pending VT-2's local verification: if VT-2 shows outbound
        // calls really are blocked with a distinguishable signal, the messages can be split again.
        ConnectionFailedReasonTxt: Label 'Business Central could not reach the BBB website. If this is the first refresh on this environment, ask your administrator to confirm that outbound web requests are allowed for BBB Rating Insights.';
        NotFoundReasonTxt: Label 'The BBB profile page was not found at the address recorded for this customer.';
        BlockedReasonTxt: Label 'The BBB website refused the request.';
        UnavailableReasonTxt: Label 'The BBB website is currently unavailable.';
        ParseFailedReasonTxt: Label 'The BBB profile page was reached but could not be read in the expected format. The page layout may have changed.';
        UnexpectedReasonTxt: Label 'The BBB profile page could not be read.';
        // CR-05 (ChangeLog DEFINE-017): the fetch-time host guardrail's reason and its pattern.
        InvalidHostReasonTxt: Label 'The BBB profile URL must point to a bbb.org address.';
        BbbHostPatternTok: Label 'https://*.bbb.org/*', Locked = true;
        UserAgentTok: Label 'BusinessCentral-BBBRatingInsights/1.0', Locked = true;
        GradeAnchorPlaceholderTok: Label 'PLACEHOLDER_GRADE_ANCHOR — REPLACE BEFORE USE', Locked = true;
        AccreditedAnchorPlaceholderTok: Label 'PLACEHOLDER_ACCREDITED_ANCHOR — REPLACE BEFORE USE', Locked = true;
        ComplaintCountAnchorPlaceholderTok: Label 'PLACEHOLDER_COMPLAINT_COUNT_ANCHOR — REPLACE BEFORE USE', Locked = true;
}
