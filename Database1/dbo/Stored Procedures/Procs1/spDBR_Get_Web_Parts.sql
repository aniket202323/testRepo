Create Procedure dbo.spDBR_Get_Web_Parts
@pageid int
AS
 	 select p.dashboard_part_id, p.dashboard_report_id, r.dashboard_report_name, p.dashboard_part_top, 
 	  	 p.dashboard_part_left, s.dashboard_template_height, 
 	  	 s.dashboard_template_width,
 	  	 p.dashboard_part_auto_refresh from dashboard_parts p, dashboard_reports r, dashboard_templates t, 
 	  	 dashboard_template_size_table s 
 	  	 where r.dashboard_report_id = p.dashboard_report_id 
 	  	 and p.dashboard_page_id = @pageid
 	  	 and r.dashboard_template_id = t.dashboard_template_id
 	  	 and t.dashboard_template_size = s.dashboard_template_size_id
 	  	 order by p.dashboard_part_top, p.dashboard_part_left
