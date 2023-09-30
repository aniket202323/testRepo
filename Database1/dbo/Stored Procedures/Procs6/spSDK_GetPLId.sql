CREATE PROCEDURE dbo.spSDK_GetPLId
 	 @PLDesc 	  	  	 nvarchar(100),
 	 @PLId 	  	  	  	 INT 	  	  	  	 OUTPUT
AS
SELECT 	 @PLId = NULL
SELECT 	 @PLId = PL_Id
 	 FROM 	 Prod_Lines
 	 WHERE 	 PL_Desc = @PLDesc
IF @PLId IS NULL
BEGIN
 	 RETURN(1)
END
RETURN(0)
