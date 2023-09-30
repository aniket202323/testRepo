Create Procedure dbo.spDBR_Get_Dashboard_Templates
AS
 	  	 select dashboard_template_id, 
 	  	  	  	 case when isnumeric(dashboard_template_name) = 1 then (dbo.fnDBTranslate(N'0', dashboard_template_name, dashboard_template_name) + ' v.' + Convert(varchar(7), version)) 
 	  	  	  	 else (dashboard_template_name + ' v.' + Convert(varchar(7), version))
 	  	  	  	 end as dashboard_template_name
 	  	 from dashboard_templates 	 order by dashboard_template_name, version 	 
