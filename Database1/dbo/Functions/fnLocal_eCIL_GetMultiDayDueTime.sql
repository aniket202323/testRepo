CREATE FUNCTION [dbo].[fnLocal_eCIL_GetMultiDayDueTime]
(@CurrentTime DATETIME NULL, @SpecTF VARCHAR (7) NULL, @PreviousDueTime DATETIME NULL, @PreviousEntryOn DATETIME NULL, @FixedFrequency VARCHAR (50) NULL, @PreviousResult VARCHAR (25) NULL, @StartDate DATETIME NULL, @MissedText VARCHAR (30) NULL, @TestTime VARCHAR (5) NULL, @MasterPUID INT NULL)
RETURNS DATETIME
WITH ENCRYPTION
AS
BEGIN
--The script body was encrypted and cannot be reproduced here.
    RETURN NULL
END

