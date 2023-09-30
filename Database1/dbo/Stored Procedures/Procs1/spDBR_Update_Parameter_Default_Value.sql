Create Procedure dbo.spDBR_Update_Parameter_Default_Value
@id int,
@row int,
@column int,
@value varchar(4000)
AS
 	  	 
 	  	 
 	  	 
 	  	 insert into dashboard_parameter_default_values (Dashboard_Template_Parameter_ID, Dashboard_Parameter_Row, Dashboard_Parameter_Column, Dashboard_Parameter_Value) values(@id, @row, @column, @value)
 	  	 update dashboard_template_parameters set has_default_value = 1 where dashboard_template_parameter_id = @id
