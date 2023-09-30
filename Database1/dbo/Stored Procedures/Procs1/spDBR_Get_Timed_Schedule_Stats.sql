Create Procedure dbo.spDBR_Get_Timed_Schedule_Stats
@InTimeZone 	  	 varchar(200) = NULL  ---23/08/2010 - Ex: 'India Standard Time','Central Stardard Time' 
AS
 	 create table #schedule_Times
 	 (
 	  	 dashboard_report_name varchar(100),
 	  	 frequencybased bit,
 	  	 firstofyear bit,
 	  	 lastofyear bit,
 	  	 firstofquarter bit,
 	  	 lastofquarter bit,
 	  	 firstofmonth bit,
 	  	 lastofmonth bit,
 	  	 dayofweek bit,
 	  	 customdate bit,
 	  	 dashboard_frequency_base_time datetime,
 	  	 dashboard_frequency int,
 	  	 dashboard_frequency_conversion_Factor int,
 	  	 dashboard_day_of_week int,
 	  	 dashboard_custom_date datetime
 	 )
 	 
 	 
 	 
 	 insert into #schedule_times
 	 select r.dashboard_report_name, 1, 0, 0, 0,0,0,0,0,0,f.dashboard_frequency_base_time, f.dashboard_frequency, t.dashboard_frequency_conversion_factor, null, null 
 	 from dashboard_reports r, dashboard_schedule s, dashboard_Schedule_frequency f, dashboard_frequency_Types t
 	 where f.dashboard_frequency_type_id = t.dashboard_frequency_type_id
 	 and f.dashboard_schedule_id = s.dashboard_schedule_id
 	 and s.dashboard_report_id = r.dashboard_report_id
 	 order by f.dashboard_frequency_base_time
 	 
 	 
 	 
 	 insert into #schedule_times
 	 select r.dashboard_report_name, 0,c.dashboard_first_of_year, c.dashboard_last_of_year, c.dashboard_first_of_Quarter,
 	  	 c.dashboard_last_of_quarter, c.dashboard_first_of_month, c.dashboard_last_of_month, 0, 0, null, null, null, null, null
 	  	 from dashboard_reports r, dashboard_schedule s, dashboard_calendar c 
 	  	 where r.dashboard_report_id = s.dashboard_report_id and s.dashboard_schedule_id = c.dashboard_schedule_id
 	  	 and c.dashboard_day_of_week = 0 and c.dashboard_custom_date = 0
 	  	 
 	 
 	  	 insert into #schedule_times
 	 select r.dashboard_report_name, 0,0,0,0,0,0,0,1,0, null, null, null, d.dashboard_day_of_week, null
 	  	 from dashboard_reports r, dashboard_schedule s, dashboard_calendar c, dashboard_day_of_Week d
 	  	 where r.dashboard_report_id = s.dashboard_report_id 
 	  	 and s.dashboard_schedule_id = c.dashboard_schedule_id
 	  	 and c.dashboard_day_of_week = 1 
 	  	 and d.dashboard_calendar_id = c.dashboard_calendar_id
 	  	 
 	  	 insert into #schedule_times
 	 select r.dashboard_report_name, 0,0,0,0,0,0,0,0,1, null, null, null, null, d.dashboard_day_to_run
 	  	 from dashboard_reports r, dashboard_schedule s, dashboard_calendar c, dashboard_custom_Dates d
 	  	 where r.dashboard_report_id = s.dashboard_report_id 
 	  	 and s.dashboard_schedule_id = c.dashboard_schedule_id
 	  	 and c.dashboard_custom_date = 1 
 	  	 and d.dashboard_calendar_id = c.dashboard_calendar_id
 	 
 	 ---24/08/2010 - Update datetime formate in UTC into #schedule_times table
 	 update #schedule_times set dashboard_frequency_base_time = dbo.fnServer_CmnConvertFromDBTime(dashboard_frequency_base_time,@InTimeZone),
 	  	  	  	  	  	  	    dashboard_custom_date = dbo.fnServer_CmnConvertFromDBTime(dashboard_custom_date,@InTimeZone)
 	  	  	  	  	  	  	    
 	 select * from #schedule_times
 	 drop table #schedule_times
 	 
