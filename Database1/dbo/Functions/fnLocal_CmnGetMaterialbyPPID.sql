CREATE FUNCTION [dbo].[fnLocal_CmnGetMaterialbyPPID]
(@strPPIDList NVARCHAR (4000) NULL)
RETURNS 
    @GeneratedTableName TABLE (
        [ProdId]   INT            NULL,
        [ProdCode] NVARCHAR (50)  NULL,
        [ProdDesc] NVARCHAR (100) NULL)
WITH ENCRYPTION
AS
BEGIN
--The script body was encrypted and cannot be reproduced here.
    RETURN
END

