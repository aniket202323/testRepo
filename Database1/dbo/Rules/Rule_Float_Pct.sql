CREATE RULE [dbo].[Rule_Float_Pct]
    AS @value >= 0.0 AND @value <= 100.0;

