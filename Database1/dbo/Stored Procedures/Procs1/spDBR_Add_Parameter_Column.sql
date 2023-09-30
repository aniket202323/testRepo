Create Procedure dbo.spDBR_Add_Parameter_Column
@dashboard_parameter_datatype_id int,
@dashboard_parameter_datatable_header varchar(100)
AS
 	 declare @returnid int
 	 declare @column int
 	 
 	 set @column = (select max(dashboard_datatable_column) from dashboard_datatable_headers where dashboard_parameter_type_id = @dashboard_parameter_datatype_id)
 	 if (@column > 0)
 	 begin
 	  	 set @column = (@column + 1)
 	 end
 	 else
 	 begin
 	  	 set @column = 1
 	 end
 	 
 	 
 	 insert into dashboard_datatable_headers (Dashboard_Parameter_Type_ID,Dashboard_DataTable_Column,Dashboard_DataTable_Header,Dashboard_DataTable_Presentation,Dashboard_DataTable_Column_SP) 
 	  	 values (@dashboard_parameter_datatype_id,@column, @dashboard_parameter_datatable_header, 0, NULL)
 	 
 	 set @returnid = (select scope_identity())
 	 
 	 select @returnid as id
 	 
