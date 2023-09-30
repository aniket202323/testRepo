Create Procedure dbo.spDBR_Get_Ad_Hoc_Reports
AS
 	  	 select dashboard_report_id, dashboard_report_create_Date
 	  	  	 from dashboard_reports 
 	  	  	 where dashboard_report_ad_hoc_flag = 1
 	  	  	  	 
