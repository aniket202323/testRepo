Create Procedure dbo.spDBR_Get_Line_Unit
@Unit_id int
as
 	 select l.PL_Desc, l.PL_ID, u.PU_Desc from prod_lines l, prod_units u where l.pl_id = u.pl_id and u.pu_id = @Unit_id
