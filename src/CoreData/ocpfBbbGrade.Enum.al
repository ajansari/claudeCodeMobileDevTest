namespace OnlyCopilotFans.BBBInsights;

enum 50601 "ocpfBbbGrade"
{
    Caption = 'BBB Grade';
    Extensible = false;
    // Extensible = false: the value set is BBB's, not ours. A subscriber adding a grade BBB does
    // not issue would put a value in the field that the provider can never legitimately produce
    // and that no report could interpret (TDD §6.1).

    value(0; NotFetched)
    {
        Caption = 'Not Fetched';
        // FR-1's distinct "no value yet" state. Ordinal 0 is the default for every existing and
        // new customer, which is why this design needs no upgrade/backfill code (TDD §12).
    }
    value(1; APlus)
    {
        Caption = 'A+';
        // Value names carry no '+'/'-' (invalid AL identifier characters); the caption carries
        // the real grade.
    }
    value(2; A)
    {
        Caption = 'A';
    }
    value(3; AMinus)
    {
        Caption = 'A-';
    }
    value(4; BPlus)
    {
        Caption = 'B+';
    }
    value(5; B)
    {
        Caption = 'B';
    }
    value(6; BMinus)
    {
        Caption = 'B-';
    }
    value(7; CPlus)
    {
        Caption = 'C+';
    }
    value(8; C)
    {
        Caption = 'C';
    }
    value(9; CMinus)
    {
        Caption = 'C-';
    }
    value(10; DPlus)
    {
        Caption = 'D+';
    }
    value(11; D)
    {
        Caption = 'D';
    }
    value(12; DMinus)
    {
        Caption = 'D-';
    }
    value(13; F)
    {
        Caption = 'F';
    }
    value(14; NR)
    {
        Caption = 'NR (Not Rated)';
        // BBB's own "Not Rated" - a *fetched* fact, deliberately distinct from ordinal 0
        // (FR-1, NFR-11).
    }

    // There is deliberately no "Unknown"/"Unrecognized" member. If the provider reads a grade
    // string it cannot map, that is a parse failure, not a grade - DR-1 then applies and the
    // stored grade is left untouched. A catch-all member would silently overwrite good data with
    // "we don't know", which is exactly the failure mode DR-1 exists to prevent (TDD §6.1).
}
