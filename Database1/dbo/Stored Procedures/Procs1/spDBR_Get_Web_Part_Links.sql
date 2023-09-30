Create Procedure dbo.spDBR_Get_Web_Part_Links
@ReportID int
AS
select t.dashboard_template_name, r.dashboard_report_to_id, r.dashboard_Report_from_id, t.dashboard_template_id, i.dashboard_icon_name, t.dashboard_template_launch_Type, i.dashboard_icon_id, i.dashboard_icon 
 	 from dashboard_templates t, dashboard_report_links r, dashboard_template_links tl, dashboard_icons i 
 	  	 where i.dashboard_icon_id = t.dashboard_icon_id and r.dashboard_report_from_id = @ReportID 
 	  	  	 and r.dashboard_template_link_id = tl.dashboard_template_link_id
 	  	  	 and  t.dashboard_template_id = tl.dashboard_template_link_to 
 	 
 	  	  	 
