CREATE FUNCTION [dbo].[fnLocal_CmnGetPOfromPath]
(@strPathList NVARCHAR (200) NULL, @dtmStartTime DATETIME NULL, @dtmEndTime DATETIME NULL, @strOrderBy NVARCHAR (200) NULL)
RETURNS 
    @GeneratedTableName TABLE (
        [PO]    INT            NULL,
        [Label] NVARCHAR (400) NULL)
WITH ENCRYPTION
AS
BEGIN
--The script body was encrypted and cannot be reproduced here.
    RETURN
END

