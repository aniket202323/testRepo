Create Procedure dbo.spDBR_Update_Report_Link
@linkid int,
@linkto int,
@linkfrom int
AS
 	 update dashboard_report_links set dashboard_report_to_id = @linkto, dashboard_report_from_id = @linkfrom where dashboard_report_link_id = @linkid
 	 
