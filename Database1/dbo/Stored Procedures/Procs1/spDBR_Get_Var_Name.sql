Create Procedure dbo.spDBR_Get_Var_Name
@var_id int
as
 	  select var_id, Var_desc from variables where var_id = @var_id
