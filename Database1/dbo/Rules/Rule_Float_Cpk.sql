CREATE RULE [dbo].[Rule_Float_Cpk]
    AS (@value >= 0.0) AND (@value <= 2.0);

