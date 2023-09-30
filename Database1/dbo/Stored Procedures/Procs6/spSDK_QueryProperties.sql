CREATE PROCEDURE dbo.spSDK_QueryProperties
 	 @PropertyMask 	  	 nvarchar(50) 	 = NULL,
 	 @UserId 	  	  	  	 INT 	  	  	  	 = NULL
AS
SET 	 @PropertyMask = REPLACE(COALESCE(@PropertyMask, '*'), '*', '%')
SET 	 @PropertyMask = REPLACE(REPLACE(@PropertyMask, '?', '_'), '[', '[[]')
--Mask For Name Has Been Specified
SELECT 	 DISTINCT
 	  	  	 PropertyId = pp.Prop_Id,
 	  	  	 PropertyName = pp.Prop_Desc,
 	  	  	 CommentId = pp.Comment_Id
 	 FROM 	  	  	 Product_Properties pp
 	 LEFT JOIN 	 User_Security pps 	  	  	  	 ON 	  	 pp.Group_Id = pps.Group_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pps.User_Id = @UserId
 	 WHERE 	 pp.Prop_Desc LIKE @PropertyMask
 	 AND 	 COALESCE(pps.Access_Level, 3) >= 2
