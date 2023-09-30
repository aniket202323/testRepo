Create Procedure dbo.spDBR_Get_Line_Name
@line_id int
as
 	 insert into #sp_name_results select PL_desc from prod_lines where pl_id = @line_id
