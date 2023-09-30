CREATE RULE [dbo].[Rule_Int_TCP_Port]
    AS @value >= 0 AND @value <= 65536;

