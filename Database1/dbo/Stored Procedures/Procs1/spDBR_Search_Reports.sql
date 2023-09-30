Create Procedure dbo.spDBR_Search_Reports
@searchstring varchar(100) = '%',
@MyReportId int = 0
AS
SET ANSI_WARNINGS off
 	 create table #ReturnData
 	 (
 	  	 ReportId int,
 	  	 ReportName varchar(200), 
 	  	 TemplateId int,
 	  	 height int,
 	  	 fixed_height bit,
 	  	 width int,
 	  	 fixed_width bit
 	 )
 	 create table #Prompts
 	 (
 	  	 Search  	  	 varchar(50),
 	  	 Search_Results  	 varchar(50),
 	  	 Return_To 	 varchar(50),
 	  	 MyReports 	 varchar(50)
 	 )
 	 insert into #Prompts (Search, Search_Results, Return_To, MyReports) values (
 	  	 dbo.fnDBTranslate(N'0', 38108, 'Search'),
 	  	 dbo.fnDBTranslate(N'0', 38380, 'Search Results'),
 	  	 dbo.fnDBTranslate(N'0', 38381, 'Return To'),
 	  	 dbo.fnDBTranslate(N'0', 38379, 'My Reports'))
if (@searchstring = '')
begin
 	  	 insert into #ReturnData (ReportId, ReportName, TemplateId, height,fixed_height, width,fixed_width)
 	  	  	 select r.dashboard_report_id, r.dashboard_report_name, r.dashboard_template_id, t.height, t.dashboard_template_fixed_height,t.width,t.dashboard_template_fixed_width
 	  	 from dashboard_reports r, dashboard_templates t
 	  	 where dashboard_report_ad_hoc_flag = 0 and r.dashboard_template_id = t.dashboard_template_id
 	  	 
 	  	 insert into #ReturnData(ReportId, ReportName, TemplateId, height, width)
 	  	 select  -1, 
 	  	 case when isnumeric(dashboard_template_name) = 1 then ('*' + dbo.fnDBTranslate(N'0', dashboard_template_name, dashboard_template_name) + ' v.' + Convert(varchar(7), version)) 
 	  	 else ('*' + dashboard_template_name + ' v.' + Convert(varchar(7), version))
 	  	 end, 	 
 	  	 dashboard_template_id, height, width
 	  	 from dashboard_templates
end
else
begin
 	 set @searchstring = '%' + @searchstring + '%'
 	  	 insert into #ReturnData (ReportId, ReportName, TemplateId, height,fixed_height, width,fixed_width)
 	  	  	 select r.dashboard_report_id, r.dashboard_report_name, r.dashboard_template_id, t.height, t.dashboard_template_fixed_height,t.width,t.dashboard_template_fixed_width
 	  	 from dashboard_reports r, dashboard_templates t
 	  	 where dashboard_report_ad_hoc_flag = 0 and r.dashboard_template_id = t.dashboard_template_id
 	  	 and dashboard_report_name like @searchstring
 	  	 
 	  	 insert into #ReturnData(ReportId, ReportName, TemplateId, height, width)
 	  	 select  -1, 
 	  	 case when isnumeric(dashboard_template_name) = 1 then ('*' + dbo.fnDBTranslate(N'0', dashboard_template_name, dashboard_template_name) + ' v.' + Convert(varchar(7), version)) 
 	  	 else ('*' + dashboard_template_name + ' v.' + Convert(varchar(7), version))
 	  	 end, 	 
 	  	  dashboard_template_id, height, width
 	  	 from dashboard_templates
 	  	 where case when isnumeric(dashboard_template_name) = 1 then dbo.fnDBTranslate(N'0', dashboard_template_name, dashboard_template_name) else  dashboard_template_name end like @searchstring
end
update #ReturnData set height = 500 where fixed_height = 0
update #ReturnData set width = 500 where fixed_width = 0
select * from #ReturnData
select * from #Prompts
