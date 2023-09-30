Create Procedure dbo.spDBR_Get_Report_Parameter_Value
@template_parameter_id int,
@reportid int
AS
 	 create table #default_Values
 	 (
 	  	 dashboard_parameter_default_value_id varchar(100),
 	  	 dashboard_parameter_row int,
 	  	 dashboard_parameter_column int,
 	  	 dashboard_parameter_value varchar(4000),
 	  	 dashboard_datatable_header varchar(100)
 	 )
 	 
 	 create table #column_parameters
 	 (
 	  	 parameter_number int,
 	  	 column_id int,
 	  	 row_id int,
 	  	 parameter_value varchar(4000)
 	 )
 	 
 	 create table #column_procs
 	 (
 	  	 column_id int,
 	  	 /*row_id int,*/
 	  	 proc_name varchar(4000)
 	 )
 	 
 	 create table #sp_name_results
 	 (
 	  	 value varchar(4000)
 	 )
 	 
 	 
 	  	 /*this query fills in the column procs table with the cell identifier and sp name to run*/
 	  	 
 	  	 insert into #column_procs select h.dashboard_datatable_column,h.dashboard_datatable_column_sp
 	  	 from  	 dashboard_datatable_headers h,
 	  	 dashboard_parameter_types pt, 
 	  	 dashboard_template_parameters tp
 	 
 	  	 where h.dashboard_parameter_type_id  = pt.dashboard_parameter_type_id 
 	  	 and tp.dashboard_parameter_type_id = pt.dashboard_parameter_type_id 
 	  	 and h.dashboard_datatable_presentation = 1
 	  	 and tp.dashboard_template_parameter_id = @template_parameter_id 
 	  	 order by h.dashboard_datatable_column
 	  	 
 	  	 /*this query fills in the parameters table so the procs and parameters table can be matched up and sp's ran*/
 	  	 
 	  	 insert into #column_parameters 
 	  	 select p.Dashboard_DataTable_Presentation_Parameter_Order, h.dashboard_datatable_column, d.dashboard_parameter_row, d.dashboard_parameter_value
 	  	 from 
 	  	  	 Dashboard_datatable_presentation_parameters p,
 	  	  	 dashboard_datatable_headers h,
 	  	  	 dashboard_parameter_types pt,
 	  	  	 dashboard_template_parameters tp,
 	  	  	 dashboard_parameter_values d
 	  	 
 	  	 where p.Dashboard_DataTable_Header_ID = h.Dashboard_DataTable_Header_ID
 	  	  	 and h.dashboard_parameter_type_id  =pt.dashboard_parameter_type_id 
 	  	  	 and tp.dashboard_parameter_type_id = pt.dashboard_parameter_type_id 
 	  	  	 and d.dashboard_template_parameter_id = tp.dashboard_template_parameter_id 
 	  	  	 and d.dashboard_template_parameter_id = @template_parameter_id 
 	  	  	 and d.dashboard_report_id = @reportid
 	  	  	 and d.dashboard_parameter_column = (select z.dashboard_datatable_column from dashboard_datatable_headers z where z.dashboard_datatable_header_id = p.Dashboard_DataTable_Presentation_Parameter_Input)
 	  	  	 order by d.dashboard_parameter_row, h.dashboard_datatable_column, p.Dashboard_DataTable_Presentation_Parameter_Order
 	  	  	 
 	  	 declare @dependent_value varchar(100)
 	  	 declare @sp_name nvarchar(4000)
 	  	 declare @row int
 	  	 declare @column int
 	  	 declare @count bigint
 	  	 declare @paramcount bigint
 	  	 declare @paramnumber int
 	  	 declare @param_value nvarchar(4000)
 	  	 declare @presentation_value varchar(100)
 	  	 declare @default_value_id varchar(100)
 	  	 declare @datatable_header varchar(100)
 	  	 
 	  	 
 	  	 
 	  	 set @count = (select count(*) from #column_parameters where parameter_number = 1)
 	 
 	  	 
 	  	 while (@count > 0)
 	  	 begin 	  	 
 	  	  	 
 	  	  	 set @row = (select min(row_id) from #column_parameters) 
 	  	  	 set @column = (select min(column_id) from #column_parameters where row_id = @row) 	  	 
 	  	  	 set @sp_name = (select proc_name from #column_procs where column_id = @column)
 	  	  	  	  	 
 	  	  	 set @count = (@count - 1)
 	  	  	 set @paramcount = (select count(*) from #column_parameters where row_id = @row and column_id = @column)
 	  	  	 
 	  	  	 while (@paramcount > 0)
 	  	  	 begin
 	  	 
 	  	  	  	 set @paramnumber = (select min(parameter_number) from #column_parameters where row_id = @row and column_id = @column)
 	  	  	  	 set @param_value =  '"' + (select parameter_value from #column_parameters where parameter_number = @paramnumber and row_id = @row and column_id = @column)+ '"'
 	  	  	  	 set @sp_name = (@sp_name + ' ' +  @param_value)
 	  	  	  	 set @paramcount = (@paramcount - 1)
 	  	  	  	 if (@paramcount > 0)
 	  	  	  	 begin
 	  	  	  	  	 set @sp_name = (@sp_name + ',')
 	  	  	  	 end
 	  	  	  	 delete from #column_parameters where row_id = @row and column_id = @column and parameter_number = @paramnumber
 	  	  	 end
 	  	  	 
 	  	  	 
 	  	  	  	  	  	 
 	  	  	 EXECUTE sp_executesql @sp_name
 	  	  	 
 	  	  	 
 	  	  	 set @default_value_id = '<None>'
 	  	  	 set @datatable_header = (select h.dashboard_datatable_header 
 	  	  	 from dashboard_datatable_headers h,
 	  	  	 dashboard_parameter_types pt,
 	  	  	 dashboard_template_parameters tp
 	  	  	 where h.dashboard_parameter_type_id  =pt.dashboard_parameter_type_id 
 	  	  	 and tp.dashboard_parameter_type_id = pt.dashboard_parameter_type_id 
 	  	  	 and tp.dashboard_template_parameter_id = @template_parameter_id
 	  	  	 and h.dashboard_datatable_column = @column)
 	  	  	 
 	  	  	 set @presentation_value = (select value from #sp_name_results)
 	  	  	 insert into #default_values values (@default_value_id, @row, @column, @presentation_value, @datatable_header)
 	  	  	 delete from #sp_name_results
 	  	 end
 	  	 
 	  	 
 	  	 
 	  	 insert into #default_values 
 	  	 select d.dashboard_parameter_value_id, 
 	  	  	  	 d.dashboard_parameter_row, 
 	  	  	  	 d.dashboard_parameter_column, 
 	  	  	  	 d.dashboard_parameter_value, 
 	  	  	  	 h.dashboard_datatable_header 
 	  	 
 	  	 from dashboard_parameter_values d, 
 	  	  	 dashboard_datatable_headers h, 
 	  	  	 dashboard_parameter_types pt, 
 	  	  	 dashboard_template_parameters tp 
 	  	 
 	  	 where h.dashboard_parameter_type_id  =pt.dashboard_parameter_type_id 
 	  	 and tp.dashboard_parameter_type_id = pt.dashboard_parameter_type_id 
 	  	 and d.dashboard_template_parameter_id = tp.dashboard_template_parameter_id 
 	  	 and h.dashboard_datatable_column = d.dashboard_parameter_column
 	  	 and h.dashboard_datatable_presentation = 0
 	  	 and d.dashboard_template_parameter_id = @template_parameter_id 
 	  	 and d.dashboard_report_id = @reportid
 	  	 order by d.dashboard_parameter_column
 	 
 	 
 	 
 	 select * from #default_values order by dashboard_parameter_row, dashboard_parameter_column
 	 drop table #default_Values
 	 drop table #column_procs
 	 drop table #column_parameters
 	 drop table #sp_name_results
 	 
