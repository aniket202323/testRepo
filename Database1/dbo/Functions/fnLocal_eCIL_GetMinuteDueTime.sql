CREATE FUNCTION [dbo].[fnLocal_eCIL_GetMinuteDueTime]
(@CurrentTime DATETIME NULL, @SpecTF VARCHAR (7) NULL, @PreviousDueTime DATETIME NULL, @PreviousEntryOn DATETIME NULL, @FixedFrequency VARCHAR (50) NULL, @PreviousResult VARCHAR (25) NULL, @ShiftStart DATETIME NULL, @ShiftEnd DATETIME NULL, @MissedText VARCHAR (30) NULL, @ShiftOffset INT NULL)
RETURNS DATETIME
WITH ENCRYPTION
AS
BEGIN
--The script body was encrypted and cannot be reproduced here.
    RETURN NULL
END

