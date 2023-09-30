CREATE PROCEDURE dbo.spSDK_QueryProducts
 	 @FamilyMask 	  	 nvarchar(50) = NULL,
 	 @ProductMask 	 nvarchar(50) = NULL,
 	 @UserId 	  	  	 nvarchar(50) = NULL
AS
SET 	 @FamilyMask = REPLACE(COALESCE(@FamilyMask, '*'), '*', '%')
SET 	 @FamilyMask = REPLACE(REPLACE(@FamilyMask, '?', '_'), '[', '[[]')
SET 	 @ProductMask = REPLACE(COALESCE(@ProductMask, '*'), '*', '%')
SET 	 @ProductMask = REPLACE(REPLACE(@ProductMask, '?', '_'), '[', '[[]')
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
 	 FROM 	  	  	 Product_Family pf
 	 JOIN 	  	  	 Products p 	  	  	 ON pf.Product_Family_Id = p.Product_Family_Id AND
 	  	  	  	  	  	  	  	  	  	  	  	 p.Prod_Code LIKE @ProductMask
 	 LEFT JOIN 	 User_Security pfs 	 ON pf.Group_Id = pfs.Group_Id AND
 	  	  	  	  	  	  	  	  	  	  	  	 pfs.User_Id = @UserId
 	 WHERE 	 pf.Product_Family_Desc LIKE @FamilyMask
 	 AND 	 COALESCE(pfs.Access_Level, 3) >= 2
