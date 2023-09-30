Create Procedure dbo.spDBR_Get_Unit_Name
@Unit_id int
as
 	 insert into #sp_name_results select PU_Desc from prod_units where pu_id = @Unit_id
