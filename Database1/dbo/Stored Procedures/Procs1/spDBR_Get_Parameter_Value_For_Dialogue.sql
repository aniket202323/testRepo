Create Procedure dbo.spDBR_Get_Parameter_Value_For_Dialogue
@template_parameter_id int,
@ReportID int
AS
 	 if (@ReportID = 0)
 	 begin
 	 
 	  	 declare @has_default bit
 	  	 
 	  	 set @has_default = (select has_default_value from dashboard_template_parameters where dashboard_template_parameter_id = @template_parameter_id)
 	  	 
 	  	 if (@has_default = 1) 
 	  	 begin
 	  	  	 select  d.dashboard_parameter_row, 
 	  	  	  	  	 d.dashboard_parameter_column, 
 	  	  	  	  	 d.dashboard_parameter_value, 
 	  	  	  	  	 h.dashboard_datatable_header,
 	  	  	  	  	 pt.value_type,
 	  	  	  	  	 tp.dashboard_template_parameter_name 
 	  	  	 
 	  	  	 from dashboard_parameter_default_values d, 
 	  	  	  	 dashboard_datatable_headers h,  
 	  	  	  	 dashboard_parameter_types pt, 
 	  	  	  	 dashboard_template_parameters tp 
 	  	  	 
 	  	  	 where h.dashboard_parameter_type_id = pt.dashboard_parameter_type_id  
 	  	  	 and tp.dashboard_parameter_type_id = pt.dashboard_parameter_type_id 
 	  	  	 and d.dashboard_template_parameter_id = tp.dashboard_template_parameter_id 
 	  	  	 and d.dashboard_parameter_column = h.dashboard_datatable_column
 	  	  	 and d.dashboard_template_parameter_id = @template_parameter_id 
 	  	  	 order by d.dashboard_parameter_column
 	  	  	 
 	  	 end
 	  	 else
 	  	 begin
 	  	  	 select  1 as dashboard_parameter_row, h.dashboard_datatable_column as dashboard_parameter_column, '<None>' as dashboard_parameter_value, h.dashboard_datatable_header,
 	  	  	 tp.dashboard_template_parameter_name,  1 as dashboard_parameter_raw_value 
 	  	  	 from dashboard_template_parameters tp, 
 	  	  	 dashboard_datatable_headers h, 
 	  	  	 dashboard_parameter_types pt
 	  	  	 where tp.dashboard_template_parameter_id = @template_parameter_id
 	  	  	 and tp.dashboard_parameter_type_id = pt.dashboard_parameter_type_id
 	  	  	 and h.dashboard_parameter_type_id = pt.dashboard_parameter_type_id
 	  	  	  
 	  	  	 
 	  	 end
 	 end
 	 else
 	 begin
 	  	 select  d.dashboard_parameter_row, 
 	  	  	  	  	 d.dashboard_parameter_column, 
 	  	  	  	  	 d.dashboard_parameter_value, 
 	  	  	  	  	 h.dashboard_datatable_header,
 	  	  	  	  	 pt.value_type,
 	  	  	  	  	 tp.dashboard_template_parameter_name
 	  	  	 
 	  	  	 from dashboard_parameter_values d, 
 	  	  	  	 dashboard_datatable_headers h, 
 	  	  	  	 dashboard_parameter_types pt, 
 	  	  	  	 dashboard_template_parameters tp 
 	  	  	 
 	  	  	 where h.dashboard_parameter_type_id  =pt.dashboard_parameter_type_id 
 	  	  	 and tp.dashboard_parameter_type_id = pt.dashboard_parameter_type_id 
 	  	  	 and d.dashboard_template_parameter_id = tp.dashboard_template_parameter_id 
 	  	  	 and d.dashboard_parameter_column = h.dashboard_datatable_column
 	  	  	 and d.dashboard_template_parameter_id = @template_parameter_id
 	  	  	 and d.dashboard_report_id = @ReportID 
 	  	  	 order by d.dashboard_parameter_column
 	  	 
 	 end
 	 
