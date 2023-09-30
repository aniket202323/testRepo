Create Procedure dbo.spDBR_Get_My_Report_Dialogue_Data
@filter varchar(100) = ''
AS
 	 create table #report_data
 	 (
 	  	 report_data_id int IDENTITY (1, 1) NOT NULL,
 	  	 dashboard_report_id int,
 	  	 dashboard_report_name varchar(100),
 	  	 dashboard_template_id int,
 	 )
 	 
 	 declare @sqlfilter varchar(100)
 	 set @sqlfilter = '%' + @filter + '%'
 	 if (@filter = '')
 	 begin
 	  	 insert into #report_data (dashboard_report_id, dashboard_report_name, dashboard_template_id)
 	  	  	  	 select dashboard_report_id, dashboard_report_name, dashboard_template_id
 	  	 from dashboard_reports 
 	  	 where dashboard_report_ad_hoc_flag = 0
 	 
 	 
 	  	 insert into #report_data(dashboard_report_id, dashboard_report_name, dashboard_template_id)
 	  	 select  null, 
 	  	 case when isnumeric(dashboard_template_name) = 1 then ('*' + dbo.fnDBTranslate(N'0', dashboard_template_name, dashboard_template_name) + ' v.' + Convert(varchar(7), version)) 
 	  	 else ('*' + dashboard_template_name + ' v.' + Convert(varchar(7), version))
 	  	 end,
 	  	  dashboard_template_id
 	  	 from dashboard_templates
-- (t.dashboard_template_name + ' v.' + Convert(varchar(7), t.version)) 	  	  	 
 	 end
 	 else
 	 begin 	  	 
 	  	 insert into #report_data (dashboard_report_id, dashboard_report_name, dashboard_template_id)
 	  	  	  	 select dashboard_report_id, dashboard_report_name, dashboard_template_id
 	  	 from dashboard_reports 
 	  	 where dashboard_report_ad_hoc_flag = 0
 	  	 and dashboard_report_name like @sqlfilter
 	  	 
 	  	  	  	 insert into #report_data(dashboard_report_id, dashboard_report_name, dashboard_template_id)
 	  	 select  null, 
 	  	 case when isnumeric(dashboard_template_name) = 1 then ('*' + dbo.fnDBTranslate(N'0', dashboard_template_name, dashboard_template_name) + ' v.' + Convert(varchar(7), version)) 
 	  	 else ('*' + dashboard_template_name + ' v.' + Convert(varchar(7), version))
 	  	 end,
 	  	 dashboard_template_id
 	  	 from dashboard_templates
 	  	 where case when isnumeric(dashboard_template_name) = 1 then dbo.fnDBTranslate(N'0', dashboard_template_name, dashboard_template_name) + ' v.' + Convert(varchar(7), version) else dashboard_template_name end like @sqlfilter
 	 end
 	 
 	 select * from #report_data order by dashboard_report_name
 	 
 	 drop table #report_data
 	  
