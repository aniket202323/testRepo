CREATE FUNCTION [dbo].[fnLocal_CmnGetULINMaterialByLine]
(@LineDesc NVARCHAR (50) NULL)
RETURNS 
    @GeneratedTableName TABLE (
        [Prod_id]   INT            NULL,
        [Prod_Desc] NVARCHAR (400) NULL)
WITH ENCRYPTION
AS
BEGIN
--The script body was encrypted and cannot be reproduced here.
    RETURN
END

