Create Procedure dbo.spDBR_Clear_Calendar_Custom_Dates
@CalendarID int
AS
 	 delete from dashboard_custom_dates where dashboard_calendar_id = @calendarid
