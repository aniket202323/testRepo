Create Procedure dbo.spDBR_Get_Schedule_Event_Data
@host varchar(50)
AS
select Dashboard_Schedule_Event_ID,de.Dashboard_Schedule_ID,Dashboard_Event_Scope_ID,Dashboard_Event_Type_ID,PU_ID,Var_ID, r.dashboard_report_version_count, r.dashboard_report_id from dashboard_schedule_events de, dashboard_schedule s, dashboard_reports r
where de.dashboard_schedule_id = s.dashboard_schedule_id
and s.dashboard_report_id = r.dashboard_report_id
 	 and r.dashboard_report_server = @Host
