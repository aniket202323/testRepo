Create Procedure dbo.spDBR_Update_Report_RunTime
@ReportID int,
@RunTime datetime,
@InTimeZone 	  	 varchar(200) = NULL  ---23/08/2010 - Ex: 'India Standard Time','Central Stardard Time' 
AS
 	 ---24/08/2010 - Conversion of datetime into UTC e.g. India Standard Time','Central Stardard Time'
 	  
 	  	 SELECT @RunTime = dbo.fnServer_CmnConvertToDBTime(@RunTime,@InTimeZone)
 	  
 	 
 	 update dashboard_schedule set dashboard_last_run_time = @RunTime where dashboard_report_id = @ReportID and dashboard_last_run_time < @RunTime
 	 declare @ScheduleID int
 	 select @ScheduleID = (select dashboard_schedule_id from dashboard_schedule where dashboard_report_id = @ReportID)
 	 update dashboard_custom_Dates set dashboard_completed = 1 where dashboard_calendar_id = 
 	 (select dashboard_calendar_id from dashboard_calendar where dashboard_schedule_id = @ScheduleID) and datediff(mi, dashboard_day_to_run, @RunTime) = 0
