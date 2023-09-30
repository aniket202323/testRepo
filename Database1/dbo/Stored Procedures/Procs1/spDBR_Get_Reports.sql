Create Procedure dbo.spDBR_Get_Reports
@filter varchar(100) = ''
AS
 	 create table #report_data
 	 (
 	  	 report_data_id int IDENTITY (1, 1) NOT NULL,
 	  	 dashboard_report_id int,
 	  	 dashboard_report_name varchar(100),
 	  	 dashboard_template_id int,
 	  	 dashboard_template_name varchar(100),
 	  	 dashboard_schedule_type varchar(100),
 	  	 dashboard_number_parameters int,
 	  	 dashboard_security_group_id int,
 	  	 dashboard_security_group varchar(50),
 	  	 dashboard_version_count int,
 	  	 dashboard_report_server varchar(100),
 	  	 version varchar(50)
 	 )
 	 declare @sqlfilter varchar(100)
 	 set @sqlfilter = '%' + @filter + '%'
 	 if (@filter = '')
 	 begin
 	  	 insert into #report_data (dashboard_report_id, dashboard_report_name, dashboard_report_server, dashboard_template_id, dashboard_template_name, dashboard_number_parameters, dashboard_security_group_id, dashboard_version_count, version)
 	  	  	  	 select r.dashboard_report_id, r.dashboard_report_name, r.dashboard_report_server, t.dashboard_template_id, 
 	  	  	  	 case when isnumeric(t.dashboard_template_name) = 1 then (dbo.fnDBTranslate(N'0', t.dashboard_template_name, t.dashboard_template_name) + ' v.' + Convert(varchar(7), t.version)) 
 	  	  	  	 else (t.dashboard_template_name + ' v.' + Convert(varchar(7), t.version))
 	  	  	  	 end as dashboard_template_name, 
 	  	  	  	 (select count(p.dashboard_template_parameter_id) from dashboard_template_parameters p where p.dashboard_template_id = t.dashboard_template_id), r.dashboard_report_security_group_id, dashboard_report_version_count, r.version
 	  	 from dashboard_reports r, dashboard_templates t
 	  	 where t.dashboard_template_id =  r.dashboard_template_id and dashboard_report_ad_hoc_flag = 0
 	 end
 	 else
 	 begin 	  	 
 	  	 insert into #report_data (dashboard_report_id, dashboard_report_name, dashboard_report_server, dashboard_template_id, dashboard_template_name, dashboard_number_parameters, dashboard_security_group_id, dashboard_version_count, version)
 	  	  	  	 select r.dashboard_report_id, r.dashboard_report_name, r.dashboard_report_server, t.dashboard_template_id, (t.dashboard_template_name + ' v.' + Convert(varchar(7), t.version)), 
 	  	  	  	 (select count(p.dashboard_template_parameter_id) from dashboard_template_parameters p where p.dashboard_template_id = t.dashboard_template_id), r.dashboard_report_security_group_id, dashboard_report_version_count, r.version
 	  	 from dashboard_reports r, dashboard_templates t
 	  	 where t.dashboard_template_id =  r.dashboard_template_id  	  	  	 
 	  	 and r.dashboard_report_name like @sqlfilter and dashboard_report_ad_hoc_flag = 0
 	 end
 	 
 	 declare @FrequencyBased int
 	 declare @EventBased int
 	 declare @CalendarBased int
 	 declare @OnDemand int
 	 declare @scheduletype varchar(100)
 	 declare @reportid int
 	 declare @reporttablecount int
 	 declare @securitygroupid int
 	 declare @securitygroup varchar(100)
 	 
 	 set @reporttablecount = (select count(*) from #report_data)
 	 
 	 declare @i int
 	 set @i = 1
 	 while (@i <= @reporttablecount)
 	 begin
 	  	 set @reportid = (select dashboard_report_id from #report_data where report_data_id = @i)
 	  	 set @i = (@i + 1)
 	  	 
 	  	 set @securitygroupid = (select dashboard_security_group_id from #report_data where dashboard_report_id = @reportid)
 	  	 set @securitygroup = (select group_desc from security_groups where group_id = @securitygroupid)
 	  	 
 	  	 
 	  	 set @EventBased = (select dashboard_event_based from dashboard_schedule where dashboard_report_id = @reportid)
 	  	 set @CalendarBased = (select dashboard_calendar_based from dashboard_schedule where dashboard_report_id = @reportid)
 	  	 set @FrequencyBased = (select dashboard_Frequency_based from dashboard_schedule where dashboard_report_id = @reportid)
 	  	 set @OnDemand = (select dashboard_on_demand_based from dashboard_schedule where dashboard_report_id = @reportid)
 	  	 set @scheduletype = ''
 	  	 
 	  	 if (@FrequencyBased = 1) 
 	  	 begin
 	  	  	 declare @ScheduleID int
 	  	  	 declare @Frequency int
 	  	  	 declare @Rate varchar(100)
 	  	  	 set @ScheduleID = (select dashboard_schedule_id from dashboard_schedule where dashboard_report_id = @reportid)
 	  	  	 
 	  	  	 
 	  	  	 set @Frequency = (select dashboard_frequency from dashboard_schedule_frequency where dashboard_schedule_id = @scheduleid)
 	  	 
 	  	  	 set @Rate = (select t.dashboard_frequency_type from dashboard_frequency_Types t, dashboard_schedule_frequency f where t.dashboard_frequency_type_id = f.dashboard_frequency_type_id and f.dashboard_schedule_id = @scheduleid)
 	  	  	 
 	  	 
 	  	  	 set @scheduletype = @Frequency
 	  	  	 set @scheduletype = (@scheduletype + ' ' + @Rate)
 	  	  	 
 	  	  	 if (@scheduletype is null)
 	  	 begin
 	  	  	 set @scheduletype = 'Frequency Based'
 	  	 end
 	  	 end
 	  	 
 	  	 if (@scheduletype is null)
 	  	 begin
 	  	  	 set @scheduletype = ''
 	  	 end
 	  	 
 	  	 if (@CalendarBased = 1)
 	  	 begin
 	  	  	 if (not(@scheduletype = '')) 
 	  	  	 begin
 	  	  	  	 set @scheduletype = (@scheduletype + ', ')
 	  	  	 end
 	  	  	 set @scheduletype = (@scheduletype + 'Specific Time')
 	  	 end
 	  	 
 	  	 if (@scheduletype is null)
 	  	 begin
 	  	  	 set @scheduletype = ''
 	  	 end
 	  	 
 	  	 if (@EventBased = 1)
 	  	 begin
 	  	  	 if (not(@scheduletype = '')) 
 	  	  	 begin
 	  	  	  	 set @scheduletype = (@scheduletype + ', ')
 	  	  	 end
 	  	  	 set @scheduletype = (@scheduletype + 'Event Based')
 	  	 end
 	  	 if (@OnDemand = 1)
 	  	 begin
 	  	  	 if (not(@scheduletype = '')) 
 	  	  	 begin
 	  	  	  	 set @scheduletype = (@scheduletype + ', ')
 	  	  	 end
 	  	  	 set @scheduletype = (@scheduletype + 'On Demand')
 	  	 end
 	 
 	  	 if (@scheduletype = '')
 	  	 begin
 	  	  	 set @scheduletype = '<None>'
 	  	 end
 	  	 update #report_data set dashboard_schedule_type = @scheduletype, dashboard_security_group = @securitygroup where dashboard_report_id = @reportid
 	  	 
 	 end
 	 select * from #report_data order by dashboard_report_name
 	 
 	 drop table #report_data
 	  
