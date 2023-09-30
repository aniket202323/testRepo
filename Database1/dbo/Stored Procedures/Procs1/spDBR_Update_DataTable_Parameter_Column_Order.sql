Create Procedure dbo.spDBR_Update_DataTable_Parameter_Column_Order
@parameter_id int
AS
 	 create table #DataTable_Column_Order
 	 (
 	  	 Header_ID int,
 	  	 Header_Column int
 	 )
 	 
 	 insert into #DataTable_Column_Order select dashboard_datatable_header_id, dashboard_datatable_column from dashboard_datatable_headers where  dashboard_parameter_type_id = @parameter_id order by dashboard_datatable_column
 	 
 	 declare @NewColumn int
 	 declare @RowCount int
 	 declare @HeaderID int
 	 declare @Column int
 	 set @NewColumn = (1)
 	 set @RowCount = (select count(*) from #DataTable_Column_Order)
 	  	 
 	 while (@RowCount > 0)
 	 begin
 	  	 set @HeaderID = (select Header_ID from #DataTable_Column_Order where Header_Column = (select min(Header_Column) from #DataTable_Column_Order))
 	  	 set @Column = (select Header_Column from #DataTable_Column_Order where Header_Column = (select min(Header_Column) from #DataTable_Column_Order))
 	  	 
 	  	 update dashboard_parameter_values set dashboard_parameter_column = @NewColumn where dashboard_parameter_column = @Column and dashboard_template_parameter_id in 
 	  	 (select tp.dashboard_template_parameter_id from dashboard_template_parameters tp, dashboard_parameter_types pt, dashboard_datatable_headers h
 	  	 where dashboard_template_parameter_id = tp.dashboard_template_parameter_id and tp.dashboard_parameter_type_id = pt.dashboard_parameter_type_id
 	  	 and h.dashboard_parameter_type_id = pt.dashboard_parameter_type_id and h.dashboard_datatable_header_id = @HeaderID)
 	 
 	  	 update dashboard_parameter_default_values set dashboard_parameter_column = @NewColumn where dashboard_parameter_column = @Column and dashboard_template_parameter_id in 
 	  	 (select tp.dashboard_template_parameter_id from dashboard_template_parameters tp, dashboard_parameter_types pt, dashboard_datatable_headers h
 	  	 where dashboard_template_parameter_id = tp.dashboard_template_parameter_id and tp.dashboard_parameter_type_id = pt.dashboard_parameter_type_id
 	  	 and h.dashboard_parameter_type_id = pt.dashboard_parameter_type_id and h.dashboard_datatable_header_id = @HeaderID)
 	 
 	  	 update dashboard_datatable_headers set dashboard_datatable_column = @NewColumn where dashboard_datatable_header_id = @HeaderID
 	  	 
 	  	 
 	  	 delete from #DataTable_Column_Order where Header_ID = @HeaderID
 	  	 
 	  	 set @NewColumn = (@NewColumn + 1)
 	  	 set @RowCount = (@RowCount -1)
 	 end
 	 
 	 
 	 drop table #DataTable_Column_Order
 	 
