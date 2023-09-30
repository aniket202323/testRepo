Create Procedure dbo.spDBR_Get_Available_Template_Links
@template_id int
AS
 	 select t.dashboard_template_id, 
 	  	 case when isnumeric(t.dashboard_template_name) = 1 then (dbo.fnDBTranslate(N'0', t.dashboard_template_name, t.dashboard_template_name) + ' v.' + Convert(varchar(7), t.version)) 
 	  	 else (t.dashboard_template_name + ' v.' + Convert(varchar(7), t.version))
 	  	 end as dashboard_template_name
 	 from dashboard_templates t
 	  	 where t.dashboard_template_id not in (select dtl.dashboard_template_link_to from dashboard_template_links dtl where dtl.dashboard_template_link_from = @template_id)
 	  	 and not t.dashboard_template_id = @template_id 
 	 order by t.dashboard_template_name
