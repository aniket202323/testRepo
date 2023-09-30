Create Procedure dbo.spDBR_Get_Parameter_Value_Type
@templateparamid int,
@reportid int = 0
AS
declare @paramtype int
declare @prevalue varchar(100)
select t.Value_Type from Dashboard_Parameter_Types t, Dashboard_Template_Parameters p 
 	 where p.Dashboard_Template_Parameter_ID = @templateparamid and t.dashboard_parameter_type_id = p.dashboard_parameter_type_id
 	 
