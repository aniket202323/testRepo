Create Procedure dbo.spDBR_Delete_Schedule
@scheduleID int
AS
 	 delete from dashboard_schedule_frequency where dashboard_schedule_id = @scheduleid
 	 delete from dashboard_schedule_events where dashboard_schedule_id = @scheduleid
 	 delete from dashboard_custom_dates where dashboard_calendar_id in (select dashboard_calendar_id from dashboard_calendar where dashboard_schedule_id = @scheduleid)
 	 delete from dashboard_day_of_Week where dashboard_calendar_id in (select dashboard_calendar_id from dashboard_calendar where dashboard_schedule_id = @scheduleid)
 	 delete from dashboard_calendar where dashboard_schedule_id = @scheduleid
 	 delete from dashboard_schedule where dashboard_schedule_id = @scheduleid 
