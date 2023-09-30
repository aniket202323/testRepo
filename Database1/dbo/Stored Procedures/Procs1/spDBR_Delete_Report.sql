Create Procedure dbo.spDBR_Delete_Report
@report_id int
AS 	 
 	 delete from dashboard_parameter_values where dashboard_report_id = @report_id
 	 delete from dashboard_content_generator_statistics where dashboard_report_id = @report_id
 	 delete from dashboard_report_links where dashboard_report_from_id = @report_id
 	 delete from dashboard_report_links where dashboard_report_to_id = @report_id
 	 delete from dashboard_schedule_frequency where dashboard_schedule_id in (select dashboard_schedule_id from dashboard_schedule where dashboard_report_id = @report_id)
 	 delete from dashboard_schedule_events where dashboard_schedule_id in (select dashboard_schedule_id from dashboard_schedule where dashboard_report_id = @report_id)
 	 delete from dashboard_day_of_week where dashboard_calendar_id in (select dashboard_calendar_id from dashboard_calendar where dashboard_schedule_id in (select dashboard_schedule_id from dashboard_schedule where dashboard_report_id = @report_id))
 	 delete from dashboard_custom_dates where dashboard_calendar_id in (select dashboard_calendar_id from dashboard_calendar where dashboard_schedule_id in (select dashboard_schedule_id from dashboard_schedule where dashboard_report_id = @report_id))
 	 delete from dashboard_calendar where dashboard_schedule_id in (select dashboard_schedule_id from dashboard_schedule where dashboard_report_id = @report_id)
 	 delete from dashboard_schedule where dashboard_report_id = @report_id
 	 delete from dashboard_report_data where dashboard_report_id = @report_id
 	 delete from dashboard_reports where dashboard_report_id = @report_id
 	 
 	 
 	 
