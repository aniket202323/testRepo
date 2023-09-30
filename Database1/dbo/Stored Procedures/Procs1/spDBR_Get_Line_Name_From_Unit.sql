Create Procedure dbo.spDBR_Get_Line_Name_From_Unit
@Unit_id int
as
 	 insert into #sp_name_results select l.PL_Desc from prod_lines l, prod_units u where l.pl_id = u.pl_id and u.pu_id = @Unit_id
