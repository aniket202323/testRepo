Create Procedure dbo.spDBR_Delete_Template_Link
@link_id int
AS
 	 delete from dashboard_report_links where dashboard_template_link_id = @link_id
 	 delete from dashboard_template_links where dashboard_template_link_id = @link_id
 	 
