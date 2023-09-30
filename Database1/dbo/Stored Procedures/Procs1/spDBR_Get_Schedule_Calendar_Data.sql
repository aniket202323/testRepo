Create Procedure dbo.spDBR_Get_Schedule_Calendar_Data
@host varchar(50)
AS
select Dashboard_Calendar_ID,dc.Dashboard_Schedule_ID,Dashboard_First_of_Month,Dashboard_Last_of_Month,Dashboard_First_Of_Quarter,Dashboard_Last_Of_Quarter,Dashboard_First_Of_Year,Dashboard_Last_Of_Year,Dashboard_Day_Of_Week,Dashboard_Custom_Date from dashboard_calendar dc, dashboard_schedule s, dashboard_reports r
where dc.dashboard_schedule_id = s.dashboard_schedule_id
and s.dashboard_report_id = r.dashboard_report_id
 	 and r.dashboard_report_server = @Host
 order by dc.dashboard_schedule_id
