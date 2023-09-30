CREATE PROCEDURE [dbo].[spASP_GetSheetUnits]
@Sheet_Id int
AS
SELECT 	 [PU_Id] = Master_Unit
FROM 	 SHEETS
WHERE 	 Master_Unit IS NOT NULL AND Sheet_Id = @Sheet_Id
--SELECT 	 DISTINCT 	 v.pu_id, [Description] = pu_desc
--FROM 	 variables v
--JOIN 	 sheet_variables sv 	 ON 	 sv.var_id = v.var_id
--JOIN 	 sheets s 	  	  	 ON 	 s.sheet_id = sv.sheet_id
--JOIN 	 prod_units pu 	  	 ON 	 pu.pu_id = v.pu_id  
--WHERE 	 s.sheet_id = @Sheet_Id  

