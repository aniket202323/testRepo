Create Procedure dbo.spDBR_Get_Report_Schedule_Types
@reportid int
AS
 	 select dashboard_schedule_id, dashboard_frequency_based, dashboard_calendar_based, dashboard_event_based, dashboard_on_demand_based from dashboard_schedule where dashboard_report_id = @reportid 	  
