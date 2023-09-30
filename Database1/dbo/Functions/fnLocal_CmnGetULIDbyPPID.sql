CREATE FUNCTION [dbo].[fnLocal_CmnGetULIDbyPPID]
(@strPPIDList NVARCHAR (4000) NULL)
RETURNS 
    @GeneratedTableName TABLE (
        [EventID]  INT            NULL,
        [EventNum] NVARCHAR (400) NULL)
WITH ENCRYPTION
AS
BEGIN
--The script body was encrypted and cannot be reproduced here.
    RETURN
END

