Create Procedure dbo.spDBR_Update_Template_Link
@link_id int,
@from_id int,
@to_id int
AS
 	 update dashboard_report_links set dashboard_report_to_id = null where dashboard_template_link_id = @link_id
 	 update dashboard_template_links set dashboard_template_link_from = @from_id, dashboard_template_link_to = @to_id where dashboard_template_link_id = @link_id
 	 
