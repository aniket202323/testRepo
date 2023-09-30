Create Procedure dbo.spDBR_Get_Calendar_Days
@scheduleid int
AS
 	 declare @calendarid integer
 	 set @calendarid = (select dashboard_calendar_id from dashboard_calendar where dashboard_schedule_id = @scheduleid)
 	 select dashboard_day_of_week from dashboard_day_of_week where dashboard_calendar_id = @calendarid
