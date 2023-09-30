CREATE PROCEDURE dbo.spSDK_GetTransProdAssignment
 	 @UserId 	  	  	 INT,
 	 @TransId 	  	  	 INT,
 	 @ProdId 	  	  	 INT,
 	 @PUId 	  	  	  	 INT,
 	 @NewValue 	  	 BIT 	  	 OUTPUT,
 	 @OldValue 	  	 BIT 	  	 OUTPUT
AS
SELECT 	 @NewValue = CASE
 	  	  	  	 WHEN tp.PU_Id IS NOT NULL 	 AND pp.PU_Id IS NOT NULL 	 AND tp.Is_Delete = 1 THEN 0
 	  	  	  	 WHEN tp.PU_Id IS NOT NULL 	 AND pp.PU_Id IS NOT NULL 	 AND tp.Is_Delete = 0 THEN 1
 	  	  	  	 WHEN tp.PU_Id IS NOT NULL 	 AND pp.PU_Id IS NULL  	  	 AND tp.Is_Delete = 0 THEN 1
 	  	  	  	 WHEN tp.PU_Id IS NOT NULL 	 AND pp.PU_Id IS NULL  	  	 AND tp.Is_Delete = 1 THEN 0
 	  	  	  	 WHEN tp.PU_Id IS NULL 	  	 AND pp.PU_Id IS NOT NULL 	  	  	  	  	  	  	  	 THEN 1
 	  	  	  	 WHEN tp.PU_Id IS NULL  	  	 AND pp.PU_Id IS NULL  	  	  	  	  	  	  	  	  	 THEN 0
 	  	  	 END,
 	  	  	 @OldValue = CASE
 	  	  	  	 WHEN pp.PU_Id IS NOT NULL 	 THEN 1
 	  	  	  	 WHEN pp.PU_Id IS NULL  	  	 THEN 0
 	  	  	 END
 	 FROM 	 Products p 	  	  	 LEFT JOIN
 	  	  	 PU_Products pp 	  	 ON (p.Prod_Id = pp.Prod_Id AND 
 	  	  	  	  	  	  	  	  	  	  pp.PU_Id = @PUId) LEFT JOIN
 	  	  	 Trans_Products tp 	 ON (p.Prod_Id = tp.Prod_Id AND 
 	  	  	  	  	  	  	  	  	  	  tp.PU_Id = @PUId AND 
 	  	  	  	  	  	  	  	  	  	  tp.Trans_Id = @TransId)
 	 WHERE p.Prod_Id = @ProdId
