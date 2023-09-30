Create Procedure dbo.spDBR_Update_Report_Dashboard_Detail_Link
@dashboard_report_id int,
@dashboard_report_detail_link varchar(500)
AS
 	 if (@dashboard_report_detail_link = '')
 	 begin
 	  	 update dashboard_reports set dashboard_report_detail_link = null
 	  	  	  	  	  	  	  	  	 where dashboard_report_id = @dashboard_report_id
 	 end
 	 else
 	 begin
 	  	 update dashboard_reports set dashboard_report_detail_link = @dashboard_report_detail_link
 	  	  	  	  	  	  	  	  	 where dashboard_report_id = @dashboard_report_id
 	 end
 	 
 	   
