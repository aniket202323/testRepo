CREATE PROCEDURE dbo.spSDK_GetProductById
 	 @ProdId 	  	  	  	 INT
AS
--Mask For Name Has Been Specified
SELECT 	 DISTINCT
 	  	  	 ProductId = p.Prod_Id,
 	  	  	 ProductCode = p.Prod_Code, 
 	  	  	 ProductDesc = p.Prod_Desc,
 	  	  	 ProductFamily = pf.Product_Family_Desc,
 	  	  	 IsManufacturingProduct = COALESCE(Is_Manufacturing_Product, 1),
 	  	  	 IsSalesProduct = COALESCE(Is_Sales_Product, 0),
 	  	  	 CommentId = p.Comment_Id,
                        EventESignatureLevel = COALESCE(p.Event_Esignature_Level,0),
                        ProductChangeESignatureLevel = COALESCE(p.Product_Change_ESignature_Level,0)                
 	 FROM 	 Product_Family pf
 	 JOIN 	 Products p 	  	  	 ON p.Product_Family_Id = pf.Product_Family_Id
 	 WHERE 	 p.Prod_Id = @ProdId
