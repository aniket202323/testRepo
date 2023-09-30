Create Procedure dbo.spDBR_Get_Web_Part_Size
@reportid int
AS
 	 declare @templateid int
 	 set @templateid = (select dashboard_template_id from dashboard_reports where dashboard_report_id = @reportid)
 	 
 	 select height, width
 	  	 from dashboard_templates 
 	  	  	 where dashboard_template_id = @templateid
