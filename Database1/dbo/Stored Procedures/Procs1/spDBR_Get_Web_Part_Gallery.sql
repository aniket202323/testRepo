Create Procedure dbo.spDBR_Get_Web_Part_Gallery
AS
select r.dashboard_report_id, 
 	    r.dashboard_report_name + ' v.' + Convert(varchar(100),r.version) as dashboard_report_name, 
 	    r.dashboard_report_server, 
 	    r.dashboard_report_description,
 	    r.dashboard_report_column,
 	    r.dashboard_report_column_position,
 	    r.dashboard_report_has_frame,
 	    r.dashboard_report_expanded,
 	    r.dashboard_report_allow_remove,
 	    r.dashboard_report_allow_minimize, 
 	    r.dashboard_report_cache_code,
 	    r.dashboard_report_cache_timeout,
 	    r.dashboard_report_detail_link,
 	    r.dashboard_report_help_link,
 	    t.height, 
 	    t.width, 
 	    tsu.dashboard_template_size_unit_code, 
 	    t.dashboard_template_fixed_height,
 	    t.dashboard_template_fixed_width
from dashboard_reports r, dashboard_Templates t, dashboard_template_size_units tsu
where dashboard_report_ad_hoc_flag = 0
and r.dashboard_Template_id = t.dashboard_template_id
and t.dashboard_template_size_unit = tsu.dashboard_template_size_unit_id
 	  
