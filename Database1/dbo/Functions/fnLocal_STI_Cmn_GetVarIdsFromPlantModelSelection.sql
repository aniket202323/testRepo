CREATE FUNCTION [dbo].[fnLocal_STI_Cmn_GetVarIdsFromPlantModelSelection]
(@DeptsList VARCHAR (8000) NULL, @LinesList VARCHAR (8000) NULL, @MastersList VARCHAR (8000) NULL, @SlavesList VARCHAR (8000) NULL, @GroupsList VARCHAR (8000) NULL, @VarsList VARCHAR (8000) NULL)
RETURNS 
    @GeneratedTableName TABLE (
        [Var_Id] INT NULL)
WITH ENCRYPTION
AS
BEGIN
--The script body was encrypted and cannot be reproduced here.
    RETURN
END

