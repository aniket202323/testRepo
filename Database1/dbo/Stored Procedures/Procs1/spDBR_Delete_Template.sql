Create Procedure dbo.spDBR_Delete_Template
@template_id int
AS 	 
 	 
 	 delete from Dashboard_Report_Data where dashboard_report_id in (select r.dashboard_report_id from dashboard_reports r where r.dashboard_template_id = @template_id) 
/* 	 delete from Dashboard_Parameter_Values where dashboard_report_id in (select r.dashboard_report_id from dashboard_reports r where r.dashboard_template_id = @template_id)
*/ 	 delete from Dashboard_Parameter_Values where dashboard_template_parameter_id in (select t.dashboard_template_parameter_id from dashboard_template_parameters t where t.dashboard_template_id = @template_id)
 	 delete from dashboard_schedule_frequency where dashboard_schedule_id in (select s.dashboard_schedule_id from dashboard_schedule s where s.dashboard_report_id in (select r.dashboard_report_id from dashboard_reports r where r.dashboard_template_id = @template_id) )
 	 delete from dashboard_schedule_events where dashboard_schedule_id in (select s.dashboard_schedule_id from dashboard_schedule s where s.dashboard_report_id in (select r.dashboard_report_id from dashboard_reports r where r.dashboard_template_id = @template_id) )
 	 delete from dashboard_calendar where dashboard_schedule_id in (select s.dashboard_schedule_id from dashboard_schedule s where s.dashboard_report_id in (select r.dashboard_report_id from dashboard_reports r where r.dashboard_template_id = @template_id) )
 	 delete from dashboard_schedule where dashboard_report_id in (select r.dashboard_report_id from dashboard_reports r where r.dashboard_template_id = @template_id) 
 	 
 	 
 	 delete from dashboard_report_links where dashboard_template_link_id in (select dashboard_template_link_id from dashboard_template_links where dashboard_template_link_from = @template_id or dashboard_template_link_to = @template_id)
 	 delete from dashboard_template_links where dashboard_template_link_from = @template_id or dashboard_template_link_to = @template_id 	 
 	 
 	 
 	 delete from dashboard_content_generator_statistics where dashboard_report_id in (select r.dashboard_report_id from dashboard_reports r where r.dashboard_template_id = @template_id) 
 	 delete from dashboard_reports where dashboard_template_id = @template_id
 	 
 	  	 
 	 delete from dashboard_template_dialogue_parameters where dashboard_template_parameter_id in (select p.dashboard_template_parameter_id from dashboard_template_parameters p where p.dashboard_template_id = @template_id)
 	 delete from dashboard_parameter_default_values where dashboard_template_parameter_id in (select p.dashboard_template_parameter_id from dashboard_template_parameters p where p.dashboard_template_id = @template_id) 
 	 delete from dashboard_template_parameters where dashboard_template_id = @template_id 	  	 
 	 delete from dashboard_templates where dashboard_template_id = @template_id
 	 
