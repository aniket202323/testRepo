Create Procedure dbo.spDBR_Get_MasterSlave_From_Var
@Var_id int
as
 	 select v.PU_ID as Slave_Unit, isnull(u.Master_Unit, v.pu_id) as Master_Unit from variables v, prod_units u where v.var_id = @var_id and v.pu_id = u.pu_id
