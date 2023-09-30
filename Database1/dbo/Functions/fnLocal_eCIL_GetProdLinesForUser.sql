CREATE FUNCTION [dbo].[fnLocal_eCIL_GetProdLinesForUser]
(@UserId INT NULL, @MinimumAccessLevel INT NULL)
RETURNS 
    @GeneratedTableName TABLE (
        [PL_Id] INT NULL)
WITH ENCRYPTION
AS
BEGIN
--The script body was encrypted and cannot be reproduced here.
    RETURN
END

