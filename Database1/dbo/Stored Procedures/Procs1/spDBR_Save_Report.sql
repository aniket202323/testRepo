Create Procedure dbo.spDBR_Save_Report
@reportid int,
@reportname varchar(100)
AS
 	 update dashboard_reports set dashboard_report_ad_hoc_flag = 0, dashboard_report_name = @reportname where dashboard_report_id = @reportid
