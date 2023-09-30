Create Procedure dbo.spDBR_Get_Line_From_Unit
@Unit_id int
as
 	 insert into #sp_name_results select PL_ID from prod_units where pu_id = @Unit_id
