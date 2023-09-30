Create Procedure dbo.spDBR_Get_Schedule_Data
@Host varchar(50)
AS
select Dashboard_Schedule_ID,dashboard_on_demand_based,Dashboard_Frequency_Based,Dashboard_Calendar_Based,Dashboard_Event_Based,dateadd(s,60,Dashboard_Last_Run_Time) as dashboard_last_run_time,s.Dashboard_Report_ID, r.Dashboard_Report_Name from dashboard_schedule s, dashboard_reports r where s.dashboard_report_ID = r.dashboard_report_ID
and r.dashboard_report_server = @host
