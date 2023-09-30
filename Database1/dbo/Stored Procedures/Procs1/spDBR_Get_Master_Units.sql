Create Procedure dbo.spDBR_Get_Master_Units
AS 	 
 	 select PU_ID, PU_Desc from Prod_Units where master_unit is null and pu_id > 0 order by pu_desc
