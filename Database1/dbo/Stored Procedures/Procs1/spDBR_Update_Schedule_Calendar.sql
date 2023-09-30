Create Procedure dbo.spDBR_Update_Schedule_Calendar
@ScheduleID int,
@Dashboard_First_Of_Month int,
@Dashboard_Last_Of_Month int,
@Dashboard_First_Of_Quarter int,
@Dashboard_Last_Of_Quarter int,
@Dashboard_First_Of_Year int,
@Dashboard_Last_Of_Year int,
@Dashboard_Day_Of_Week int,
@Dashboard_Custom_Date int
AS
 	 declare @calendarid int
 	 declare @count int
 	 set @count = (select count(*) from dashboard_calendar where dashboard_schedule_id = @scheduleid)
 	 
 	 if (@count = 0)
 	 begin
 	  	 insert into dashboard_calendar (dashboard_schedule_id,dashboard_first_of_month, dashboard_last_of_month, dashboard_first_of_quarter, dashboard_last_of_quarter, dashboard_first_of_year,dashboard_last_of_year,
 	  	  	  	  	  	 dashboard_day_of_week, dashboard_custom_date) 
 	  	 values (@scheduleid, @dashboard_first_of_month, @dashboard_last_of_month, @dashboard_first_of_quarter, @dashboard_last_of_Quarter, @dashboard_first_of_year, @dashboard_last_of_year, 
 	  	 @dashboard_day_of_week,@dashboard_custom_date )
 	  	 set @calendarid = (select scope_identity())
 	 end
 	 else
 	 begin
 	  	 update dashboard_calendar set dashboard_first_of_month = @dashboard_first_of_month, dashboard_last_of_month = @dashboard_last_of_month, dashboard_first_of_quarter = @dashboard_first_of_quarter,
 	  	  	 dashboard_last_of_quarter = @dashboard_last_of_quarter, dashboard_first_of_year = @dashboard_first_of_year, dashboard_last_of_year = @dashboard_last_of_year, 
 	  	  	 dashboard_day_of_week = @dashboard_day_of_week, dashboard_custom_date = @dashboard_custom_date where dashboard_schedule_id = @scheduleid
 	  	 set @calendarid = (select dashboard_calendar_id from dashboard_calendar where dashboard_schedule_id = @scheduleid)
 	 end
 	 
 	 select @calendarid as ID
