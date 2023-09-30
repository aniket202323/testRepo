Create Procedure dbo.spDBR_Get_Report_Template
@ReportID int,
@LanguageId int = 0
AS
select t.dashboard_template_id, 
case when isnumeric(t.dashboard_template_name) = 1 then (dbo.fnDBTranslate(@LanguageId, t.dashboard_template_name, t.dashboard_template_name))
else (t.dashboard_template_name)
end as dashboard_report_name,
t.height, t.width from dashboard_reports r, dashboard_templates t 
where r.dashboard_report_id = @reportid and t.dashboard_template_id = r.dashboard_template_id
