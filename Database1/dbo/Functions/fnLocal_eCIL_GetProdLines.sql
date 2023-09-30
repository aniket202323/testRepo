CREATE FUNCTION [dbo].[fnLocal_eCIL_GetProdLines]
(@Granularity INT NULL, @IDs VARCHAR (8000) NULL)
RETURNS 
    @GeneratedTableName TABLE (
        [Pl_Id]   INT          NULL,
        [PL_Desc] VARCHAR (50) NULL)
WITH ENCRYPTION
AS
BEGIN
--The script body was encrypted and cannot be reproduced here.
    RETURN
END

