CREATE PROCEDURE dbo.spSDK_QueryTransCharLinks
 	 @TransId 	  	  	  	  	 INT
AS
SELECT 	 PropertyName = pp.Prop_Desc,
 	  	  	 ChildCharacteristic = cc.Char_Desc,
 	  	  	 ParentCharacteristic = COALESCE(pc.Char_Desc, '')
 	 FROM 	 Trans_Char_Links tcl 	  	  	 JOIN
 	  	  	 Characteristics cc 	  	  	 ON tcl.From_Char_Id = cc.Char_Id 	 LEFT JOIN
 	  	  	 Product_Properties pp 	  	 ON cc.Prop_Id = pp.Prop_Id 	 JOIN
 	  	  	 Characteristics pc 	  	  	 ON tcl.To_Char_Id = pc.Char_Id
 	 WHERE 	 tcl.Trans_Id = @TransId
