CREATE PROCEDURE dbo.spSDK_GetVarId
 	 @PUId 	  	  	  	 INT,
 	 @VarDesc 	  	  	 nvarchar(100),
 	 @VarId 	  	  	 INT 	  	  	  	 OUTPUT
AS
-- Return Codes:
-- 0: Success
-- 1: Invalid PU_Id
-- 2: Invalid Variable
IF (SELECT COUNT(*) FROM Prod_Units WHERE PU_Id = @PUId AND PU_Id > 0) = 0
BEGIN
 	 RETURN(1)
END
SELECT 	 @VarId = NULL
SELECT 	 @VarId = Var_Id
 	 FROM 	 Variables
 	 WHERE 	 PU_Id = @PUId AND
 	  	  	 Var_Desc = @VarDesc
IF @VarId IS NULL
BEGIN
 	 RETURN(2)
END
RETURN(0)
