Create Procedure dbo.spDBR_Get_Schedule_Calendar_Day_Of_Week
@host varchar(50)
AS
select Dashboard_Day_Of_Week_ID,dw.Dashboard_Calendar_ID,dw.Dashboard_Day_Of_Week  from dashboard_day_of_week dw, dashboard_calendar dc, dashboard_schedule s, dashboard_reports r
where dw.dashboard_calendar_id = dc.dashboard_calendar_id
and dc.dashboard_schedule_id = s.dashboard_schedule_id
and s.dashboard_report_id = r.dashboard_report_id
 	 and r.dashboard_report_server = @Host
 order by dw.dashboard_calendar_id
