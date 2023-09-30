Create Procedure dbo.spDBR_Delete_Old_Reports
@daystosave int = -1
AS 	 
 	 declare @cutoffdate datetime
 	 if (@daystosave = -1)
 	 begin
 	  	 execute spServer_CmnGetParameter 169,27, @@SERVERNAME, @daystosave output
 	 end 	 
 	 set @daystosave = (@daystosave * (-1))
 	 set @cutoffdate = DateAdd(day, @daystosave, dbo.fnServer_CmnGetDate(getutcdate()))
 	 
 	 
 	 
 	 delete from dashboard_parameter_values where dashboard_report_id in (select dashboard_report_id from dashboard_reports where dashboard_report_ad_hoc_flag = 1 and dashboard_report_create_date < @cutoffdate)
 	 delete from dashboard_content_generator_statistics where dashboard_report_id in (select dashboard_report_id from dashboard_reports where dashboard_report_ad_hoc_flag = 1 and dashboard_report_create_date < @cutoffdate)
 	 delete from dashboard_report_links where dashboard_report_from_id in (select dashboard_report_id from dashboard_reports where dashboard_report_ad_hoc_flag = 1 and dashboard_report_create_date < @cutoffdate)
 	 delete from dashboard_report_links where dashboard_report_to_id in (select dashboard_report_id from dashboard_reports where dashboard_report_ad_hoc_flag = 1 and dashboard_report_create_date < @cutoffdate)
 	 delete from dashboard_schedule_frequency where dashboard_schedule_id in (select dashboard_schedule_id from dashboard_schedule where dashboard_report_id in (select dashboard_report_id from dashboard_reports where dashboard_report_ad_hoc_flag = 1 and dashboard_report_create_date < @cutoffdate))
 	 delete from dashboard_schedule_events where dashboard_schedule_id in (select dashboard_schedule_id from dashboard_schedule where dashboard_report_id in (select dashboard_report_id from dashboard_reports where dashboard_report_ad_hoc_flag = 1 and dashboard_report_create_date < @cutoffdate))
 	 delete from dashboard_day_of_week where dashboard_calendar_id in (select dashboard_calendar_id from dashboard_calendar where dashboard_schedule_id in (select dashboard_schedule_id from dashboard_schedule where dashboard_report_id in (select dashboard_report_id from dashboard_reports where dashboard_report_ad_hoc_flag = 1 and dashboard_report_create_date < @cutoffdate)))
 	 delete from dashboard_custom_dates where dashboard_calendar_id in (select dashboard_calendar_id from dashboard_calendar where dashboard_schedule_id in (select dashboard_schedule_id from dashboard_schedule where dashboard_report_id in (select dashboard_report_id from dashboard_reports where dashboard_report_ad_hoc_flag = 1 and dashboard_report_create_date < @cutoffdate)))
 	 delete from dashboard_calendar where dashboard_schedule_id in (select dashboard_schedule_id from dashboard_schedule where dashboard_report_id in (select dashboard_report_id from dashboard_reports where dashboard_report_ad_hoc_flag = 1 and dashboard_report_create_date < @cutoffdate))
 	 delete from dashboard_schedule where dashboard_report_id in (select dashboard_report_id from dashboard_reports where dashboard_report_ad_hoc_flag = 1 and dashboard_report_create_date < @cutoffdate)
 	 delete from dashboard_report_data where dashboard_report_id in (select dashboard_report_id from dashboard_reports where dashboard_report_ad_hoc_flag = 1 and dashboard_report_create_date < @cutoffdate)
 	 delete from dashboard_reports where dashboard_report_id in (select dashboard_report_id from dashboard_reports where dashboard_report_ad_hoc_flag = 1 and dashboard_report_create_date < @cutoffdate)
