CREATE FUNCTION [dbo].[fnLocal_GetStartEndTime]
(@strTimeOption NVARCHAR (20) NULL, @strPUId NVARCHAR (10) NULL, @dtmDatePicker DATETIME NULL)
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

