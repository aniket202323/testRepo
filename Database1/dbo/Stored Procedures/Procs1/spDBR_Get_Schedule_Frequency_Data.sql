Create Procedure dbo.spDBR_Get_Schedule_Frequency_Data
@Host varchar(50)
AS
select f.dashboard_schedule_id, r.dashboard_Report_version_count, f.dashboard_frequency_base_time, f.dashboard_frequency * t.dashboard_frequency_conversion_factor as dashboard_frequency
 	 from dashboard_schedule_frequency f, dashboard_frequency_types t, dashboard_schedule s, dashboard_reports r
 	 where f.dashboard_frequency_type_id = t.dashboard_frequency_type_id
 	 and f.dashboard_schedule_id = s.dashboard_schedule_id
 	 and s.dashboard_report_id = r.dashboard_report_id
 	 and r.dashboard_report_server = @Host
