CREATE PROCEDURE dbo.spSDK_GetProductFamilyById
 	 @ProductFamilyId 	  	  	  	 INT
AS
SELECT 	 DISTINCT
 	  	  	 ProductFamilyId = Product_Family_Id,
 	  	  	 FamilyName = Product_Family_Desc,
 	  	  	 CommentId = Comment_Id
 	 FROM 	 Product_Family pf
 	 WHERE 	 Product_Family_Id = @ProductFamilyId
