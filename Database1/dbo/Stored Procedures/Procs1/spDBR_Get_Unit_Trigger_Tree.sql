Create Procedure dbo.spDBR_Get_Unit_Trigger_Tree
AS
select u.PU_ID, u.PU_Desc, u.master_unit, l.PL_ID, l.PL_Desc from prod_units u, prod_lines l
where l.pl_id = u.pl_id and not u.pl_id = 0 and not u.pu_id = 0 order by l.pl_desc, u.master_Unit, u.pu_desc
