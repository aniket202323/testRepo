CREATE FUNCTION [dbo].[fnLocal_CmnGetStorageLotByPath]
(@strPathList NVARCHAR (200) NULL)
RETURNS 
    @GeneratedTableName TABLE (
        [puid]   INT            NULL,
        [puDesc] NVARCHAR (400) NULL)
WITH ENCRYPTION
AS
BEGIN
--The script body was encrypted and cannot be reproduced here.
    RETURN
END

