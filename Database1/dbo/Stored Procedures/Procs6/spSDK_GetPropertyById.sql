CREATE PROCEDURE dbo.spSDK_GetPropertyById
 	 @PropertyId 	  	  	  	 INT
AS
SELECT 	 DISTINCT
 	  	  	 PropertyId = pp.Prop_Id,
 	  	  	 PropertyName = pp.Prop_Desc,
 	  	  	 CommentId = pp.Comment_Id
 	 FROM 	 Product_Properties pp
 	 WHERE 	 pp.Prop_Id = @PropertyId
