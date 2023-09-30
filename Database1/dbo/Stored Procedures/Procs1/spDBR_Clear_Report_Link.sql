Create Procedure dbo.spDBR_Clear_Report_Link
@report_link_id int
AS 	 
 	 update dashboard_report_links set dashboard_report_to_id = null where dashboard_report_link_id = @report_link_id
