Create Procedure dbo.spDBR_Update_Parameter
@parameter_id int,
@parameter_desc varchar (100),
@parameter_data_type int,
/*@icon_id int,*/
@version int,
@value_type int = 4
AS
 	 declare @count int
 	 set @count =  (select count(dashboard_parameter_type_id) from dashboard_parameter_types where dashboard_parameter_type_desc = @parameter_desc and not dashboard_parameter_type_id = @parameter_id)
 	 if (@count > 0)
 	 begin
 	  	 set @version = (select max(version) from dashboard_parameter_types where dashboard_parameter_type_desc = @parameter_desc) + 1
 	 end
 	 update dashboard_parameter_types set dashboard_parameter_type_desc = @parameter_desc, dashboard_parameter_data_type_id = @parameter_data_type, /*dashboard_icon_id = @icon_id,*/ version = @version, value_type = @value_type
 	 where dashboard_parameter_type_id = @parameter_id
