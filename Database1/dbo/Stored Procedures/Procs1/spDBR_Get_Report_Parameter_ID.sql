Create Procedure dbo.spDBR_Get_Report_Parameter_ID
@ReportID int,
@ParameterName varchar(100)
AS
declare @TemplateID int
set @TemplateID = (select dashboard_Template_id from dashboard_reports where dashboard_report_id = @reportid)
select dashboard_template_parameter_id from dashboard_template_parameters where dashboard_template_id = @templateid and dashboard_template_parameter_name = @parametername
