Create Procedure dbo.spDBR_Add_Calendar_Day_Of_Week
@CalendarID int,
@weekday int
AS
 	 insert into dashboard_day_of_week (Dashboard_Calendar_ID, Dashboard_Day_Of_Week )values (@calendarid, @weekday)
