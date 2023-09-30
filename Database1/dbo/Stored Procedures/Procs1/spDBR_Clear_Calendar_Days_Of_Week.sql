Create Procedure dbo.spDBR_Clear_Calendar_Days_Of_Week
@CalendarID int
AS
 	 delete from dashboard_day_of_week where dashboard_calendar_id = @calendarid
