Create Procedure dbo.spDBR_Get_Schedule_Calendar_Custom_Dates
@host varchar(50)
AS
select Dashboard_Custom_Date_ID,dcd.Dashboard_Calendar_ID,Dashboard_Completed, Dashboard_Day_To_Run from dashboard_custom_Dates dcd, dashboard_calendar dc, dashboard_schedule s, dashboard_reports r 
where dcd.dashboard_calendar_id = dc.dashboard_calendar_id
and dc.dashboard_schedule_id = s.dashboard_schedule_id
and s.dashboard_report_id = r.dashboard_report_id
 	 and r.dashboard_report_server = @Host
order by dcd.dashboard_calendar_id, dcd.dashboard_day_to_run
