Create Procedure dbo.spDBR_Get_Line_Value_From_Unit
@Unit_id int
as
 	 select PL_ID from prod_units where pu_id = @Unit_id
