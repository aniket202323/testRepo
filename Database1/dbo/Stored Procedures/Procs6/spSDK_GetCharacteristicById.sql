CREATE PROCEDURE dbo.spSDK_GetCharacteristicById
 	 @CharacteristicId 	  	  	  	 INT
AS
SELECT 	 DISTINCT
 	  	  	 CharacteristicId = c1.Char_Id,
 	  	  	 PropertyName = pp.Prop_Desc, 
 	  	  	 CharacteristicName = c1.Char_Desc,
 	  	  	 ParentCharacteristic = COALESCE(c2.Char_Desc, ''),
 	  	  	 CommentId = c1.Comment_Id,
 	  	  	 ExtendedInfo = c1.Extended_Info
 	 FROM 	  	  	 Product_Properties pp
 	 JOIN 	  	  	 Characteristics c1 	  	 ON 	  	 pp.Prop_Id = c1.Prop_Id and c1.Char_Id = @CharacteristicId
 	 LEFT JOIN 	 Characteristics c2 	  	 ON 	  	 c2.Char_Id = c1.Derived_From_Parent
