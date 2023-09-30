Create Procedure dbo.spDBR_Update_Report_Dashboard_Help_Link
@dashboard_report_id int,
@dashboard_report_help_link varchar(500)
AS
 	 if (@dashboard_report_help_link = '')
 	 begin
 	  	 update dashboard_reports set dashboard_report_help_link = null
 	  	  	  	  	  	  	  	  	 where dashboard_report_id = @dashboard_report_id
 	 end
 	 else
 	 begin
 	  	 update dashboard_reports set dashboard_report_help_link = @dashboard_report_help_link
 	  	  	  	  	  	  	  	  	 where dashboard_report_id = @dashboard_report_id
 	 end
 	 
 	   
