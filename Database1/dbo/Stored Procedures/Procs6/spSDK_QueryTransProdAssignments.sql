CREATE PROCEDURE dbo.spSDK_QueryTransProdAssignments
 	 @TransId 	  	  	  	  	 INT
AS
SELECT 	 LineName = pl.PL_Desc,
 	  	  	 UnitName = pu.PU_Desc,
 	  	  	 ProductCode = p.Prod_Code
 	 FROM 	 Trans_Products tp 	 JOIN
 	  	  	 Prod_Units pu 	  	 ON tp.PU_Id = pu.PU_Id 	 JOIN
 	  	  	 Prod_Lines pl 	  	 ON pu.PL_Id = pl.PL_Id 	 JOIN
 	  	  	 Products p 	  	  	 ON 	 tp.Prod_Id = p.Prod_Id
 	 WHERE 	 tp.Trans_Id = @TransId
