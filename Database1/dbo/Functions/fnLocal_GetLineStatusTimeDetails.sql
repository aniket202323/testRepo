CREATE FUNCTION [dbo].[fnLocal_GetLineStatusTimeDetails]
(@dtmStartDateTime DATETIME NULL, @dtmEndDateTime DATETIME NULL, @intPUId INT NULL)
RETURNS 
    @GeneratedTableName TABLE (
        [StatusType] NVARCHAR (200) NULL,
        [Duration]   FLOAT (53)     NULL)
WITH ENCRYPTION
AS
BEGIN
--The script body was encrypted and cannot be reproduced here.
    RETURN
END

