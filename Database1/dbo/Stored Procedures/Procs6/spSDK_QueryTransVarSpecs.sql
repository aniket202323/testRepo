CREATE PROCEDURE dbo.spSDK_QueryTransVarSpecs
 	 @TransId 	  	  	  	  	 INT
AS
SELECT 	 LineName = pl.PL_Desc,
 	  	  	 UnitName = pu.PU_Desc,
 	  	  	 VariableName = v.Var_Desc,
 	  	  	 ProductCode = p.Prod_Code
 	 FROM 	 Trans_Variables tv 	 JOIN
 	  	  	 Variables v 	  	  	  	 ON tv.Var_Id = v.Var_Id 	 JOIN
 	  	  	 Prod_Units pu 	  	  	 ON v.PU_Id = pu.PU_Id  	 JOIN
 	  	  	 Prod_Lines pl 	  	  	 ON pu.PL_Id = pl.PL_Id 	 JOIN
 	  	  	 Products p 	  	  	  	 ON tv.Prod_Id = p.Prod_Id
 	 WHERE 	 tv.Trans_Id = @TransId
