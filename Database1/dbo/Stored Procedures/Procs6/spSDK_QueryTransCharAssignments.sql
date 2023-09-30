CREATE PROCEDURE dbo.spSDK_QueryTransCharAssignments
 	 @TransId 	  	  	  	  	 INT
AS
SELECT 	 LineName = pl.PL_Desc, 
 	  	  	 UnitName =pu.PU_Desc, 
 	  	  	 ProductCode = p.Prod_Code,
 	  	  	 PropertyName = pp.Prop_Desc,
 	  	  	 CharacteristicName = COALESCE(c.Char_Desc, '')
 	 FROM 	 Trans_Characteristics tc 	 JOIN
 	  	  	 Products p 	  	  	  	  	  	 ON tc.Prod_Id = p.Prod_Id 	 JOIN
 	  	  	 Prod_Units pu 	  	  	  	  	 ON tc.PU_Id = pu.PU_Id 	  	 JOIN
 	  	  	 Prod_Lines pl 	  	  	  	  	 ON pu.PL_Id = pl.PL_Id 	  	 JOIN
 	  	  	 Product_Properties pp 	  	 ON tc.Prop_Id = pp.Prop_Id 	 LEFT JOIN
 	  	  	 Characteristics c 	  	  	  	 ON tc.Char_Id = c.Char_Id
 	 WHERE 	 tc.Trans_Id = @TransId
