Create Procedure dbo.spDBR_Copy_Template
@template_id int,
@template_desc varchar(100)
AS 	 
 	 
 	 declare @count int
 	 declare @version int
 	 set @version = 1
 	 set @count = 0
 	 set @count = (select count(dashboard_template_id) from dashboard_templates where dashboard_template_name = @template_desc)
 	 if (@count > 0)
 	 begin
 	  	 set @version = (select max(version) from dashboard_templates where dashboard_template_name = @template_desc) + 1
 	 end 	 
 	 
 	 insert into dashboard_templates (dashboard_template_name, dashboard_template_xsl, dashboard_template_xsl_filename, dashboard_template_preview,
 	  	  	  	  	  	  	  	  	 dashboard_template_preview_filename, dashboard_template_build, dashboard_template_launch_type,
 	  	  	  	  	  	  	  	  	 dashboard_template_procedure, dashboard_icon_id, dashboard_template_size_unit, dashboard_template_description, dashboard_template_fixed_height,dashboard_template_fixed_width,
 	  	  	  	  	  	  	  	  	 dashboarD_template_column, dashboard_template_column_position, dashboard_template_has_frame, dashboard_template_expanded, 
 	  	  	  	  	  	  	  	  	 dashboard_template_allow_remove, dashboard_template_allow_minimize, dashboard_template_cache_code, dashboard_template_cache_timeout,
 	  	  	  	  	  	  	  	  	 dashboard_template_detail_link, dashboard_template_help_link, Height, Width,dashboard_template_locked, version, type)
 	  	 select @template_Desc, dashboard_template_xsl, dashboard_template_xsl_filename, dashboard_template_preview,
 	  	  	  	  	  	  	  	  	 dashboard_template_preview_filename, dashboard_template_build, dashboard_template_launch_type,
 	  	  	  	  	  	  	  	  	 dashboard_template_procedure, dashboard_icon_id, dashboard_template_size_unit, dashboard_template_description, dashboard_template_fixed_height,dashboard_template_fixed_width,
 	  	  	  	  	  	  	  	  	 dashboarD_template_column, dashboard_template_column_position, dashboard_template_has_frame, dashboard_template_expanded, 
 	  	  	  	  	  	  	  	  	 dashboard_template_allow_remove, dashboard_template_allow_minimize, dashboard_template_cache_code, dashboard_template_cache_timeout,
 	  	  	  	  	  	  	  	  	 dashboard_template_detail_link, dashboard_template_help_link, Height, Width,0, @version, type
 	  	  	  	 from dashboard_templates where dashboard_template_id = @template_id
 	  	  	 
 	 declare @newtemplateid int
 	 set @newtemplateid = (select scope_identity())
 	 
 	 
 	 insert into dashboard_template_parameters (dashboard_template_id, dashboard_template_parameter_order, dashboard_parameter_type_id,
 	  	  	  	  	  	  	  	  	  	  	  	 dashboard_template_parameter_name, has_default_value, allow_nulls)
 	  	 select @newtemplateid, dashboard_template_parameter_order, dashboard_parameter_type_id, dashboard_template_parameter_name, has_default_value, allow_nulls 	 
 	  	  	 from dashboard_template_parameters where dashboard_template_id = @template_id
 	  	 
 	 insert into dashboard_template_links (dashboard_template_link_from, dashboard_template_link_to)
 	  	 select @newtemplateid, dashboard_template_link_to
 	  	  	 from dashboard_template_links
 	  	  	  	 where dashboard_template_link_from = @template_id
 	  	  	  	  	  	 
 	  	  declare @@new_p_id int
   	  	 
   	  	 
  Declare PV_Cursor INSENSITIVE CURSOR
  For Select dashboard_template_parameter_id from dashboard_template_parameters where dashboard_template_id = @newtemplateid order by dashboard_template_parameter_id
  For Read Only
  Open PV_Cursor  
PV_Loop:
  Fetch Next From PV_Cursor Into @@new_p_id
  If (@@Fetch_Status = 0)
    Begin
 	  	 declare @order int
 	  	 set @order = (select dashboard_template_parameter_order from dashboard_template_parameters where dashboard_template_parameter_id = @@new_p_id)
 	  	 
 	  	 
 	  	 
 	  	 insert into dashboard_parameter_default_values (dashboard_template_parameter_id, dashboard_parameter_row, 
 	  	  	 dashboard_parameter_column, dashboard_parameter_value)
 	  	 select @@new_p_id, pv.dashboard_parameter_row, pv.dashboard_parameter_column, pv.dashboard_parameter_value
 	  	  	 from dashboard_parameter_default_values pv, dashboard_template_parameters t
 	  	  	  	 where t.dashboard_template_parameter_id = pv.dashboard_template_parameter_id
 	  	  	  	  	 and t.dashboard_template_parameter_order = @order 	 
 	  	  	  	  	 and t.dashboard_template_id = @template_id 	  	 
 	  	  	  	  	 
 	  	  	  	  	 
 	  	  	  	  	 insert into dashboard_template_dialogue_parameters (dashboard_dialogue_id, dashboard_template_parameter_id)
 	  	  	 select tpd.dashboard_dialogue_id, @@new_p_id 
 	  	  	  	 from dashboard_template_dialogue_parameters tpd, dashboard_template_parameters t
 	  	  	  	  	 where tpd.dashboard_template_parameter_id =  t.dashboard_template_parameter_id
 	  	  	  	  	  	 and t.dashboard_template_parameter_order = @order
 	  	  	  	  	  	 and t.dashboard_template_id = @template_id
 	  	  	  	  	  	  	  	  	 
 	       Goto PV_Loop
 	 end
Close PV_Cursor 
Deallocate PV_Cursor
select @newtemplateid as id 	 
