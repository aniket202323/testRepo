CREATE PROCEDURE dbo.spSDK_QueryCharacteristics
 	 @PropertyMask 	  	 nvarchar(50) = NULL,
 	 @CharMask 	  	  	 nvarchar(50) = NULL,
 	 @UserId 	  	  	  	 nvarchar(50) = NULL
AS
SET 	 @PropertyMask = REPLACE(COALESCE(@PropertyMask, '*'), '*', '%')
SET 	 @PropertyMask = REPLACE(REPLACE(@PropertyMask, '?', '_'), '[', '[[]')
SET 	 @CharMask = REPLACE(COALESCE(@CharMask, '*'), '*', '%')
SET 	 @CharMask = REPLACE(REPLACE(@CharMask, '?', '_'), '[', '[[]')
--Mask For Name Has Been Specified
SELECT 	 DISTINCT
 	  	  	 CharacteristicId = c1.Char_Id,
 	  	  	 PropertyName = pp.Prop_Desc, 
 	  	  	 CharacteristicName = c1.Char_Desc,
 	  	  	 ParentCharacteristic = COALESCE(c2.Char_Desc, ''),
 	  	  	 CommentId = c1.Comment_Id,
 	  	  	 ExtendedInfo = c1.Extended_Info
 	 FROM 	  	  	 Product_Properties pp
 	 JOIN 	  	  	 Characteristics c1 	  	 ON 	  	 pp.Prop_Id = c1.Prop_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pp.Prop_Desc LIKE @PropertyMask
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 c1.Char_Desc LIKE @CharMask
 	 LEFT JOIN 	 Characteristics c2 	  	 ON 	  	 c2.Char_Id = c1.Derived_From_Parent
 	 LEFT JOIN 	 User_Security pps 	  	  	 ON 	  	 pp.Group_Id = pps.Group_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pps.User_Id = @UserId
 	 LEFT JOIN 	 User_Security c1s 	  	  	 ON 	  	 c1.Group_Id = c1s.Group_Id 
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 c1s.User_Id = @UserId
 	 ORDER BY CharacteristicName
