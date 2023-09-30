Create Procedure dbo.spDBR_Export_Database_Schedule
@InTimeZone 	  	 varchar(200) = NULL  ---23/08/2010 - Ex: 'India Standard Time','Central Stardard Time' 
AS
 	 create table #Dashboard_Calendar
 	 (
 	  	 dashboard_calendar_id int,
 	  	 dashboard_schedule_id int,
 	  	 dashboard_first_of_month bit,
 	  	 dashboard_last_of_month bit,
 	  	 dashboard_first_of_quarter bit,
 	  	 dashboard_last_of_quarter bit,
 	  	 dashboard_first_of_year bit,
 	  	 dashboard_last_of_year bit,
 	  	 dashboard_day_of_week bit,
 	  	 dashboard_custom_date bit
 	 )
 	 
 	 create table #dashboard_custom_dates
 	 (
 	  	 dashboard_custom_date_id int,
 	  	 dashboard_calendar_id int,
 	  	 dashboard_day_to_run datetime,
 	  	 dashboard_completed bit
 	 )
 	 create table #dashboard_day_of_week
 	 ( 	  	 Dashboard_day_of_week_id int,
 	  	 dashboard_calendar_id int,
 	  	 dashboard_day_of_week int
 	 )
 	 create table #Dashboard_Schedule
 	 (
 	  	 Dashboard_schedule_id int,
 	  	 dashboard_report_id int,
 	  	 dashboard_frequency_based bit,
 	  	 dashboard_calendar_based bit,
 	  	 dashboard_event_based bit,
 	  	 dashboard_last_run_time datetime,
 	  	 dashboard_on_demand_based bit
 	 )
 	 create table #dashboard_schedule_events
 	 (
 	  	 dashboard_schedule_event_id int,
 	  	 dashboard_schedule_id int,
 	  	 dashboard_event_scope_id int,
 	  	 dashboard_event_type_id int,
 	  	 pu_id int,
 	  	 var_id int,
 	  	 pu_desc varchar(50),
 	  	 var_desc varchar(50)
 	 )
 	 create table #dashboard_schedule_frequency
 	 (
 	  	 dashboard_schedule_frequency_id int,
 	  	 dashboard_schedule_id int,
 	  	 dashboard_frequency_base_time datetime,
 	  	 dashboard_frequency int,
 	  	 dashboard_frequency_type_id int
 	 )
 	 
 	 insert into #dashboard_schedule_frequency select dashboard_schedule_frequency_id, dashboard_schedule_id, dashboard_frequency_base_time,
 	  	 dashboard_frequency, dashboard_frequency_type_id from dashboard_schedule_frequency
 	 insert into #dashboarD_schedule_events 
 	  	 (dashboard_schedule_event_id, dashboard_schedule_id, dashboard_event_scope_id, dashboard_event_type_id,
 	  	  	 pu_id, var_id)
 	  	 select dashboard_schedule_event_id, dashboard_schedule_id, dashboarD_event_scope_id, dashboarD_event_type_id,
 	  	 pu_id, var_id from dashboard_schedule_events
 	 insert into #dashboard_schedule select dashboard_schedule_id, dashboard_report_id, dashboard_frequency_based, dashboard_calendar_based, dashboard_event_based,
 	  	 dashboard_last_run_time, dashboarD_on_demand_based from dashboard_schedule
 	 insert into #dashboard_day_of_week select dashboard_day_of_week_id, dashboarD_calendar_id, dashboard_day_of_week from dashboard_day_of_week
 	 insert into #dashboard_calendar select dashboard_calendar_id, dashboard_schedule_id, dashboard_first_of_month, 
 	  	 dashboard_last_of_month, dashboard_first_of_quarter,dashboard_last_of_quarter, dashboard_first_of_year,
 	  	 dashboard_last_of_year, dashboard_day_of_week, dashboard_custom_date from dashboard_calendar
 	 insert into #dashboard_custom_Dates select dashboard_custom_date_id, dashboard_calendar_id, dashboard_day_to_run, dashboard_completed from dashboard_custom_dates
 	 update #dashboard_schedule_events set pu_desc = pu.pu_desc from prod_units pu, #dashboard_schedule_events se where pu.pu_id = se.pu_id 	  	 
 	 update #dashboard_schedule_events set var_desc = v.var_desc from variables v, #dashboard_schedule_events se where v.var_id = se.var_id 	  	 
 	 ---23/08/2010 - Update datetime formate in UTC into #Dashboard_Reports table
 	 Update #Dashboard_Schedule_Frequency Set dashboard_frequency_base_time = dbo.fnServer_CmnConvertFromDBTime(dashboard_frequency_base_time,@InTimeZone)
 	 select * from #Dashboard_Schedule_Frequency for xml auto
 	 
 	 select * from #Dashboard_Schedule_Events for xml auto
 	 ---23/08/2010 - Update datetime formate in UTC into #Dashboard_Reports table
 	 Update #Dashboard_Schedule Set dashboard_last_run_time = dbo.fnServer_CmnConvertFromDBTime(dashboard_last_run_time,@InTimeZone)
 	 select * from #Dashboard_Schedule for xml auto
 	 
 	 select * from #Dashboard_Calendar for xml auto
 	 
 	 ---23/08/2010 - Update datetime formate in UTC into #Dashboard_Reports table
 	 Update #Dashboard_Custom_Dates Set dashboard_day_to_run = dbo.fnServer_CmnConvertFromDBTime(dashboard_day_to_run,@InTimeZone)
 	 select * from #Dashboard_Custom_Dates for xml auto
 	 
 	 select * from #Dashboard_Day_Of_Week for xml auto
 	 
