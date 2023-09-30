Create Procedure dbo.spDBR_Get_Templates
@filter varchar(100) = '',
@baseonly bit = 0
AS
 	 declare @sqlfilter varchar(100)
 	 set @sqlfilter = '%' + @filter + '%'
 	 if (@baseonly = 1)
 	 begin
 	 if (@filter = '')
 	 begin
 	  	 select t.dashboard_template_id,
 	  	  	  	 t.height, 
 	  	  	  	 t.width, 
 	  	  	  	 case when isnumeric(t.dashboard_template_name) = 1 then (dbo.fnDBTranslate(N'0', t.dashboard_template_name, t.dashboard_template_name)) 
 	  	  	  	 else (t.dashboard_template_name)
 	  	  	  	 end as dashboard_template_name, 
 	  	  	  	 t.dashboard_template_name as raw_name, 
 	  	  	  	 t.Dashboard_Template_XSL_Filename, 
 	  	  	  	 t.dashboard_template_preview_filename,
 	  	  	  	 t.Dashboard_Template_Procedure, 
 	  	  	  	 t.dashboard_template_locked,
 	  	  	  	 t.dashboard_template_fixed_height,
 	  	  	  	 t.dashboard_template_fixed_width,
 	  	  	  	 su.dashboard_template_size_unit_description,  	  	  	 
 	  	  	  	 l.dashboard_template_launch_type, 
 	  	  	  	 t.Version,t.type, t.basetemplate,
 	  	  	  	 (select count(dashboard_template_parameter_id) from dashboard_template_parameters where dashboard_template_id = t.dashboard_template_id) as numparams 	  	  	 
 	  	  	 from dashboard_templates t, 
 	  	  	  	  	 dashboard_template_size_units su, 
 	  	  	  	  	 dashboard_template_launch_type l
 	  	  	 where  
 	  	  	  	 t.dashboard_template_size_unit = su.dashboard_template_size_unit_id 
 	  	  	  	 and t.dashboard_template_launch_type = l.Dashboard_Template_Launch_Type_ID and basetemplate = 1
 	  	 order by dashboard_template_name, version
 	 end
 	 else
 	 begin
 	  	  	  	 select t.dashboard_template_id, 
 	  	  	  	  	  	 case when isnumeric(t.dashboard_template_name) = 1 then (dbo.fnDBTranslate(N'0', t.dashboard_template_name, t.dashboard_template_name)) 
 	  	  	  	  	  	 else (t.dashboard_template_name)
 	  	  	  	  	  	 end as dashboard_template_name, 
 	  	  	  	  	  	 t.dashboard_template_name as raw_name, 
 	  	  	  	  	  	 t.Dashboard_Template_XSL_Filename, 
 	  	  	  	  	  	 t.dashboard_template_preview_filename,
 	  	  	  	  	  	 t.Dashboard_Template_Procedure, 
 	  	  	  	  	  	 t.dashboard_template_locked,
 	  	  	  	  	 
 	  	  	  	  	  	 su.dashboard_template_size_unit_description, 
 	  	  	  	 t.dashboard_template_fixed_height,
 	  	  	  	 t.dashboard_template_fixed_width,
 	  	  	  	  	  	 t.height, t.width,
 	  	  	  	  	  	  l.dashboard_template_launch_type, 
 	  	  	  	  	  	  t.Version,t.type,t.basetemplate,
 	  	  	  	  	  	  (select count(dashboard_template_parameter_id) from dashboard_template_parameters where dashboard_template_id = t.dashboard_template_id) as numparams 
 	  	  	  	 from dashboard_templates t, 
 	  	  	  	  	 dashboard_template_size_units su, 
 	  	  	  	  	 dashboard_template_launch_type l
 	  	  	  	 where  
 	  	  	  	  	 t.dashboard_template_size_unit = su.dashboard_template_size_unit_id 
 	  	  	  	  	 and t.dashboard_template_launch_type = l.Dashboard_Template_Launch_Type_ID 
 	  	  	  	  	 and t.Dashboard_Template_Name like @sqlfilter and basetemplate = 1
 	  	  	  	 order by dashboard_template_name, version
 	 end
 	 end
 	 else
 	 begin
 	 if (@filter = '')
 	 begin
 	  	 select t.dashboard_template_id,
 	  	  	  	 t.height, 
 	  	  	  	 t.width, 
 	  	  	  	 case when isnumeric(t.dashboard_template_name) = 1 then (dbo.fnDBTranslate(N'0', t.dashboard_template_name, t.dashboard_template_name)) 
 	  	  	  	 else (t.dashboard_template_name)
 	  	  	  	 end as dashboard_template_name, 
 	  	  	  	 t.dashboard_template_name as raw_name, 
 	  	  	  	 t.Dashboard_Template_XSL_Filename, 
 	  	  	  	 t.dashboard_template_preview_filename,
 	  	  	  	 t.Dashboard_Template_Procedure, 
 	  	  	  	 t.dashboard_template_locked,
 	  	  	  	 t.dashboard_template_fixed_height,
 	  	  	  	 t.dashboard_template_fixed_width,
 	  	  	  	 su.dashboard_template_size_unit_description,  	  	  	 
 	  	  	  	 l.dashboard_template_launch_type, 
 	  	  	  	 t.Version,t.type, t.basetemplate,
 	  	  	  	 (select count(dashboard_template_parameter_id) from dashboard_template_parameters where dashboard_template_id = t.dashboard_template_id) as numparams 	  	  	 
 	  	  	 from dashboard_templates t, 
 	  	  	  	  	 dashboard_template_size_units su, 
 	  	  	  	  	 dashboard_template_launch_type l
 	  	  	 where  
 	  	  	  	 t.dashboard_template_size_unit = su.dashboard_template_size_unit_id 
 	  	  	  	 and t.dashboard_template_launch_type = l.Dashboard_Template_Launch_Type_ID
 	  	 order by dashboard_template_name, version
 	 end
 	 else
 	 begin
 	  	  	  	 select t.dashboard_template_id, 
 	  	  	  	  	  	 case when isnumeric(t.dashboard_template_name) = 1 then (dbo.fnDBTranslate(N'0', t.dashboard_template_name, t.dashboard_template_name)) 
 	  	  	  	  	  	 else (t.dashboard_template_name)
 	  	  	  	  	  	 end as dashboard_template_name, 
 	  	  	  	  	  	 t.dashboard_template_name as raw_name, 
 	  	  	  	  	  	 t.Dashboard_Template_XSL_Filename, 
 	  	  	  	  	  	 t.dashboard_template_preview_filename,
 	  	  	  	  	  	 t.Dashboard_Template_Procedure, 
 	  	  	  	  	  	 t.dashboard_template_locked,
 	  	  	  	  	 
 	  	  	  	  	  	 su.dashboard_template_size_unit_description, 
 	  	  	  	 t.dashboard_template_fixed_height,
 	  	  	  	 t.dashboard_template_fixed_width,
 	  	  	  	  	  	 t.height, t.width,
 	  	  	  	  	  	  l.dashboard_template_launch_type, 
 	  	  	  	  	  	  t.Version,t.type,t.basetemplate,
 	  	  	  	  	  	  (select count(dashboard_template_parameter_id) from dashboard_template_parameters where dashboard_template_id = t.dashboard_template_id) as numparams 
 	  	  	  	 from dashboard_templates t, 
 	  	  	  	  	 dashboard_template_size_units su, 
 	  	  	  	  	 dashboard_template_launch_type l
 	  	  	  	 where  
 	  	  	  	  	 t.dashboard_template_size_unit = su.dashboard_template_size_unit_id 
 	  	  	  	  	 and t.dashboard_template_launch_type = l.Dashboard_Template_Launch_Type_ID 
 	  	  	  	  	 and t.Dashboard_Template_Name like @sqlfilter
 	  	  	  	 order by dashboard_template_name, version
 	 end
 	 end
