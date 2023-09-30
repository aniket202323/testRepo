Create Procedure dbo.spDBR_Add_Template_Link
@from_id int,
@to_id int
AS
 	 insert into dashboard_template_links values(@from_id, @to_id)
 	 declare @linkid int
 	 set @linkid = (select scope_identity())
 	 insert into dashboard_Report_links(dashboard_template_link_id, dashboard_report_from_id, dashboard_report_to_id) select @linkid, dashboard_report_id, null from dashboard_reports where dashboard_template_id = @from_id 
 	 
