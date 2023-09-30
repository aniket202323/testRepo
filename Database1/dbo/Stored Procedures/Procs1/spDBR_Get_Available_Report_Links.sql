Create Procedure dbo.spDBR_Get_Available_Report_Links
@templateid int,
@reportid int
AS
 	 select r.dashboard_report_id, r.dashboard_report_name from dashboard_reports r
 	  	 where r.dashboard_template_id = @templateid
 	  	 and not r.dashboard_report_id = @reportid
 	  	 and r.dashboard_report_ad_hoc_flag = 0
