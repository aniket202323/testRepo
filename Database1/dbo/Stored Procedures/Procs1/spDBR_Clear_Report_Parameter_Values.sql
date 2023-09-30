Create Procedure dbo.spDBR_Clear_Report_Parameter_Values
@report_id int
AS 	 
 	 delete from dashboard_parameter_values where dashboard_report_id = @report_id
