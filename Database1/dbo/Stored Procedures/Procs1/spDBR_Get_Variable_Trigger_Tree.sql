Create Procedure dbo.spDBR_Get_Variable_Trigger_Tree
AS
select v.Var_ID, v.Var_Desc,u.PU_ID, u.PU_Desc, u.master_unit, l.PL_ID, l.PL_Desc 
from Variables v, prod_units u, prod_lines l
where l.pl_id = u.pl_id and u.pu_id = v.pu_id and not v.var_id = 0 and not l.pl_id = 0 and not u.pu_id = 0
union
select null, null, u.PU_ID, u.PU_Desc, u.master_unit, l.pl_id, l.pl_desc from prod_units u, prod_lines l where l.pl_id = u.pl_id and not l.pl_id = 0 and not u.pu_id = 0
   and not (u.pu_id in (select v.pu_id from variables v where v.pu_id = u.pu_id))
order by l.pl_id, master_unit, u.pu_id, v.var_id
