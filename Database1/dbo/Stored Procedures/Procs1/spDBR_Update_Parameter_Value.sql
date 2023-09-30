Create Procedure dbo.spDBR_Update_Parameter_Value
@reportid int,
@id int,
@row int,
@column int,
@value varchar(4000)
AS
 	 
 	 
 	 
 	  	 insert into dashboard_parameter_values (dashboard_report_id, dashboard_template_parameter_id, dashboard_parameter_row, dashboard_parameter_column, dashboard_parameter_value)
 	  	 values(@reportid, @id, @row, @column, @value)
 	  	 
