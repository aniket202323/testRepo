Create Procedure dbo.spDBR_Get_Schedule_Time
@scheduleid int
AS
 	 select dashboard_first_of_month, dashboard_last_of_month, dashboard_first_of_quarter, dashboard_last_of_quarter, dashboard_first_of_year, dashboard_last_of_year, dashboard_day_of_week, dashboard_custom_date
 	  	 from dashboard_calendar where dashboard_schedule_id = @scheduleid
