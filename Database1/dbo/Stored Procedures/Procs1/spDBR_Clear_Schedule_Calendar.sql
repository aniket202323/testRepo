Create Procedure dbo.spDBR_Clear_Schedule_Calendar
@ScheduleID int
AS
 	 declare @calendarid int
 	 set @calendarid = (select dashboard_calendar_id from dashboard_calendar where dashboard_schedule_id = @scheduleid)
 	 delete from dashboard_day_of_week where dashboard_calendar_id = @calendarid
 	 delete from dashboard_custom_dates where dashboard_calendar_id = @calendarid
 	 delete from dashboard_calendar where dashboard_schedule_id = @scheduleid
