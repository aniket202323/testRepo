Create Procedure dbo.spDBR_Copy_Parameter
@parameter_id int,
@parameter_desc varchar(50)
AS
 	 declare @datatypeid int, @iconid int
 	 set @datatypeid = (select dashboard_parameter_data_type_id from dashboard_parameter_types where dashboard_parameter_type_id = @parameter_id)
 	 set @iconid = (select dashboard_icon_id from dashboard_parameter_types where dashboard_parameter_type_id = @parameter_id)
 	 
 	 declare @version int, @count int
 	 set @version = 1
 	 set @count = 0
 	 set @count = (select count(dashboard_parameter_type_id) from dashboard_parameter_types where dashboard_parameter_type_desc = @parameter_desc)
 	 if (@count > 0)
 	 begin
 	  	 set @version = (select max(version) from dashboard_parameter_types where dashboard_parameter_type_Desc = @parameter_desc) + 1
 	 end 	 
 	 insert into dashboard_parameter_types (dashboard_parameter_type_desc, dashboard_parameter_data_type_id, dashboard_icon_id, locked,version)
 	 values(@parameter_desc, @datatypeid, @iconid, 0, @version)
 	 declare @newparamid int
 	 set @newparamid = (select scope_identity())
 	  	 
 	 insert into dashboard_dialogue_parameters (dashboard_dialogue_id, dashboard_parameter_type_id, default_dialogue)
 	  	 select dashboard_dialogue_id, @newparamid, default_dialogue from dashboard_dialogue_parameters where dashboard_parameter_type_id = @parameter_id
 	  	 
 	 insert into dashboard_datatable_headers (dashboard_parameter_type_id, dashboard_datatable_column, dashboard_datatable_header,
 	  	  	  	  	  	  	  	  	  	  	 dashboard_datatable_presentation, dashboard_datatable_column_sp)
 	  	 select @newparamid, dashboard_datatable_column, dashboard_datatable_header, dashboard_datatable_presentation, dashboard_datatable_column_sp
 	  	  	 from dashboard_datatable_headers where dashboard_parameter_type_id = @parameter_id
 	  	  	 
 	 
  declare @@new_h_id int
   	  	 
  Declare H_Cursor INSENSITIVE CURSOR
  For Select dashboard_datatable_header_id from dashboard_datatable_headers where dashboard_parameteR_type_id = @newparamid order by dashboard_datatable_header_id
  For Read Only
  Open H_Cursor  
H_Loop:
  Fetch Next From H_Cursor Into @@new_h_id
  If (@@Fetch_Status = 0)
    Begin
 	  	 declare @column int
 	  	 set @column = (select dashboard_datatable_column from dashboard_datatable_headers where dashboard_datatable_header_id = @@new_h_id)
 	  	 
 	  	 insert into dashboard_datatable_presentation_parameters (dashboard_datatable_header_id, 	 dashboard_datatable_presentation_parameter_order, 
 	  	  	 dashboard_datatable_presentation_parameter_input)
 	  	 select @@new_h_id, pp.dashboard_datatable_presentation_parameter_order, pp.dashboard_datatable_presentation_parameter_input
 	  	  	 from dashboard_datatable_presentation_parameters pp, dashboard_datatable_headers h
 	  	  	  	 where h.dashboard_datatable_header_id = pp.dashboard_datatable_header_id
 	  	  	  	  	 and h.dashboard_datatable_column = @column 	 
 	  	  	  	  	 and h.dashboard_parameter_type_id = @parameter_id 	  	  	  	 
 	  	  	  	 
      Goto H_Loop
 	 end
Close H_Cursor 
Deallocate H_Cursor
 	  	 
 	  	  	  	  	  	  	  	  	 
select @newparamid as id
 	 
