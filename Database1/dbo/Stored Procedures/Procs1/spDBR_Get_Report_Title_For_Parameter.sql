Create Procedure dbo.spDBR_Get_Report_Title_For_Parameter
@ReportID int,
@TemplateID int
AS
if (@ReportID = -1)
begin
 	 insert into #sp_name_results select
 	  	 case when isnumeric(dashboard_template_name) = 1 then ('*' + dbo.fnDBTranslate(N'0', dashboard_template_name, dashboard_template_name) + ' v.' + Convert(varchar(7), version)) 
 	  	 else ('*' + dashboard_template_name + ' v.' + Convert(varchar(7), version))
 	  	 end
 	  	 from dashboard_templates where dashboard_template_id = @templateid 
end
else
begin
 	 insert into #sp_name_results select dashboard_report_name from dashboard_reports where dashboard_report_id = @reportid 
end 	  	 
