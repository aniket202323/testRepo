Create Procedure dbo.spDBR_Get_Unit_Vars
@unit_id int
as 	 
 	 select var_id, var_desc from variables where pu_id = @unit_id and var_id > 0
