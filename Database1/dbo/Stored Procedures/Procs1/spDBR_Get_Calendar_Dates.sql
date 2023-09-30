Create Procedure dbo.spDBR_Get_Calendar_Dates
@scheduleid int
AS
 	 declare @calendarid integer
 	 set @calendarid = (select dashboard_calendar_id from dashboard_calendar where dashboard_schedule_id = @scheduleid)
 	 select dashboard_day_to_run from dashboard_custom_dates where dashboard_calendar_id = @calendarid and dashboard_completed = 0
