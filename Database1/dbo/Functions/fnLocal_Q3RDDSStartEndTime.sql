CREATE FUNCTION [dbo].[fnLocal_Q3RDDSStartEndTime]
(@strRptTimeOption NVARCHAR (100) NULL)
RETURNS 
    @GeneratedTableName TABLE (
        [dtmStartTime] DATETIME NULL,
        [dtmEndTime]   DATETIME NULL)
WITH ENCRYPTION
AS
BEGIN
--The script body was encrypted and cannot be reproduced here.
    RETURN
END

