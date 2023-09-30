Create Procedure dbo.spDBR_Get_Template_Links
@template_id int
AS
 	 select dtl.dashboard_template_link_id,
 	  	  	 dtl.dashboard_template_link_to, 
 	  	  	 case when isnumeric(t.dashboard_template_name) = 1 then (dbo.fnDBTranslate(N'0', t.dashboard_template_name, t.dashboard_template_name) + ' v.' + Convert(varchar(7), t.version)) 
 	  	  	 else (t.dashboard_template_name + ' v.' + Convert(varchar(7), t.version))
 	  	  	 end as dashboard_template_name,
 	  	  	 t.dashboard_template_procedure, 
 	  	  	 (select count(p.dashboard_template_parameter_id) from dashboard_template_parameters p where p.dashboard_template_id = dtl.dashboard_template_link_to) as numparameters
 	  	  	 from dashboard_templates t,
 	  	  	  	 dashboard_template_links dtl
 	  	  	  	 where t.dashboard_template_id = dtl.dashboard_template_link_to
 	  	  	  	 and dtl.dashboard_template_link_from = @template_id
 	  	  	  	 order by t.dashboard_template_name
 	 
