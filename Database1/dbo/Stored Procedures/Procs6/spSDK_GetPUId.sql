CREATE PROCEDURE dbo.spSDK_GetPUId
 	 @PLId 	  	  	  	 INT,
 	 @PUDesc 	  	  	 VarChar_Desc,
 	 @PUId 	  	  	  	 INT 	  	  	  	 OUTPUT
AS
IF (SELECT COUNT(*) FROM Prod_Lines WHERE PL_Id = @PLId) = 0
BEGIN
 	 RETURN(1)
END
SELECT 	 @PUId = NULL
SELECT 	 @PUId = PU_Id
 	 FROM 	 Prod_Units
 	 WHERE 	 PL_Id = @PLId AND
 	  	  	 PU_Desc = @PUDesc
IF @PUId IS NULL
BEGIN
 	 RETURN(2)
END
RETURN(0)
