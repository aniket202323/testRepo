Create Procedure dbo.spDBR_Get_My_Reports
@reportlist text = NULL
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
 	  	 MyReports  	 varchar(50)
 	 )
 	 insert into #Prompts (Search, MyReports) values (dbo.fnDBTranslate(N'0', 38108, 'Search'),dbo.fnDBTranslate(N'0', 38379, 'My Reports'))
 	 create table #MyReports([Report ID] varchar(50), [Template ID] varchar(50), [Report Name] varchar(50)) 	 
if (not @ReportList like '%<Root></Root>%' and not @ReportList is NULL)
  begin
    if (not @ReportList like '%<Root>%')
    begin
      declare @Text nvarchar(4000)
      select @Text = N'Report ID, Template ID;' + Convert(nvarchar(4000), @ReportList)
      Insert Into #MyReports ([Report ID], [Template ID]) EXECUTE spDBR_Prepare_Table @Text
    end
    else
    begin
 	 insert into #MyReports EXECUTE spDBR_Prepare_Table @ReportList
    end
  end
 	 insert into #ReturnData (ReportId, ReportName, TemplateId, height, fixed_height, width, fixed_width)
 	 select [Report ID] as ReportId, 
 	  	 case when [Report ID] = -1 then 
 	  	  	 case when isnumeric(dashboard_template_name) = 1 then ('*' + dbo.fnDBTranslate(N'0', dashboard_template_name, dashboard_template_name) + ' v.' + Convert(varchar(7), version)) 
 	  	  	 else ('*' + dashboard_template_name + ' v.' + Convert(varchar(7), version))
 	  	  	 end 	 
 	  	 else
 	  	  	 [Report Name]
 	  	 end as ReportName,  	  	  
 	  	 [Template ID] as TemplateId, t.height,t.dashboard_template_fixed_height, t.width, t.dashboard_template_fixed_width from #MyReports m, 
 	 Dashboard_Templates t
 	 where m.[Template ID] = t.dashboard_template_id
 	 update #ReturnData set height = 500 where fixed_height = 0
 	 update #ReturnData set width = 500 where fixed_width = 0
        update #ReturnData set ReportName = r.Dashboard_report_name from Dashboard_Reports r where ReportName is NULL and r.dashboard_report_id = ReportID
 	 select * from #ReturnData
 	 select * from #Prompts
