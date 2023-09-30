CREATE PROCEDURE dbo.spSDK_QueryProductFamilies
 	 @FamilyMask 	  	 nvarchar(50) = NULL,
 	 @UserId 	  	  	 INT 	  	  	 = NULL
AS
SET 	 @FamilyMask = REPLACE(COALESCE(@FamilyMask, '*'), '*', '%')
SET 	 @FamilyMask = REPLACE(REPLACE(@FamilyMask, '?', '_'), '[', '[[]')
--Mask For Name Has Been Specified
SELECT 	 DISTINCT
 	  	  	 ProductFamilyId = Product_Family_Id,
 	  	  	 FamilyName = Product_Family_Desc,
 	  	  	 CommentId = Comment_Id
 	 FROM 	 Product_Family pf
 	  	  	 LEFT JOIN 	 User_Security pfs 	 ON  	 pf.Group_Id = pfs.Group_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pfs.User_Id = @UserId
 	 WHERE 	 Product_Family_Desc LIKE @FamilyMask AND
 	  	  	 COALESCE(pfs.Access_Level, 3) >= 2
