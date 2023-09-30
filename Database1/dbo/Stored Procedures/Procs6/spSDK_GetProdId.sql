CREATE PROCEDURE dbo.spSDK_GetProdId
 	 @Product 	  	  	 nvarchar(100),
 	 @ProdId 	  	  	 INT 	  	  	 OUTPUT
AS
SELECT 	 @ProdId = NULL
SELECT 	 @ProdId = Prod_Id
 	 FROM 	 Products
 	 WHERE 	 Prod_Code = @Product
IF @ProdId IS NULL
BEGIN
 	 RETURN(1)
END
RETURN(0)
