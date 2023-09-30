CREATE PROCEDURE dbo.spSDK_QueryTransPropSpecs
 	 @TransId 	  	  	  	  	 INT
AS
SELECT 	 PropertyName = pp.Prop_Desc,
 	  	  	 CharacteristicName = c.Char_Desc,
 	  	  	 SpecificationName = s.Spec_Desc
 	 FROM 	 Trans_Properties tp 	  	 JOIN
 	  	  	 Characteristics c 	  	  	 ON tp.Char_Id = c.Char_Id 	 JOIN
 	  	  	 Product_Properties pp 	 ON 	 c.Prop_Id = pp.Prop_Id 	 JOIN
 	  	  	 Specifications s 	  	  	 ON tp.Spec_Id = s.Spec_Id
 	 WHERE 	 tp.Trans_Id = @TransId
