namespace OnlyCopilotFans.BBBInsights;

/// <summary>
/// This is DR-3 / NFR-2 made structural rather than aspirational (TDD §6.9, §7.1). It is the
/// single coupling point between orchestration (ocpfBbbRatingMgt) and retrieval
/// (ocpfBbbProfileReader, or any future replacement). No BC namespace is referenced here,
/// deliberately - that absence is itself evidence the DR-3 boundary is clean (TDD §8).
/// </summary>
interface "ocpfBbbRatingProvider"
{
    /// <summary>
    /// Attempts to obtain BBB rating data for one business profile.
    /// Returns true only when every out-parameter below holds a value actually read from the source.
    /// An implementation must never raise an Error: a failure is a false return plus a reason.
    /// An implementation MUST perform its outbound call and response parsing inside a [TryFunction]
    /// local procedure, and convert any caught failure into false + UnexpectedReasonTxt +
    /// SourceStatusCode = 0 (F-B-2, ChangeLog DEFINE-014) — an uncaught runtime error here must
    /// never be allowed to propagate and roll back the caller's stamp and log write.
    /// DiagnosticDetail (CR-07, ChangeLog DEFINE-017) is populated ONLY on that same caught-error
    /// path, from GetLastErrorText() — left blank on every other path, including an ordinary
    /// business-reason failure (unreachable page, bad status code, unparseable content). It is a
    /// platform diagnostic for the log only; it must never be shown to the user (FRD NFR-9).
    /// </summary>
    procedure TryGetRating(ProfileUrl: Text; var Grade: Enum "ocpfBbbGrade"; var Accredited: Boolean; var ComplaintCount: Integer; var FailureReason: Text; var SourceStatusCode: Integer; var DurationMs: Integer; var DiagnosticDetail: Text): Boolean
}
