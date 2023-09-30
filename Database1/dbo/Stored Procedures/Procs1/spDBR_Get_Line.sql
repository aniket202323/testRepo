Create Procedure dbo.spDBR_Get_Line
@Line_id int
as
 	 select l.PL_Desc from prod_lines l where l.pl_id =  @Line_id
