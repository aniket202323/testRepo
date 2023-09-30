CREATE FUNCTION [dbo].[fnLocal_eCIL_GetLineLevelAccess]
(@User_Id INT NULL)
RETURNS 
    @GeneratedTableName TABLE (
        [Pl_Id]           INT          NULL,
        [PL_Desc]         VARCHAR (50) NULL,
        [LineAccessLevel] INT          NULL)
WITH ENCRYPTION
AS
BEGIN
--The script body was encrypted and cannot be reproduced here.
    RETURN
END

