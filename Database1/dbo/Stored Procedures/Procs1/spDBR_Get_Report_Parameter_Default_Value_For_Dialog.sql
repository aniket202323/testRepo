Create Procedure dbo.spDBR_Get_Report_Parameter_Default_Value_For_Dialog
@templateparamid int
AS
declare @paramtype int
declare @prevalue varchar(100)
set @paramtype = (select distinct t.Value_Type from Dashboard_Parameter_Types t, dashboard_template_parameters p 
 	 where p.Dashboard_Template_Parameter_ID = @templateparamid and t.dashboard_parameter_type_id = p.dashboard_parameter_type_id)
if (@paramtype = 1)
begin
 	 declare @querycode int
 	 declare @startendcode int
 	 set @querycode = (select dashboard_parameter_value from dashboard_parameter_default_values where dashboard_template_parameter_id = @templateparamid and dashboard_parameter_row=1 and dashboard_parameter_column = 3)
 	 set @startendcode = (select dashboard_parameter_value from dashboard_parameter_default_values where dashboard_template_parameter_id = @templateparamid and dashboard_parameter_row=1 and dashboard_parameter_column = 4)
 	 if (@querycode = -1)
 	 begin
 	  	 select dashboard_parameter_value from dashboard_parameter_default_values where dashboard_template_parameter_id = @templateparamid and dashboard_parameter_row=1 and dashboard_parameter_column = 5
 	 end
 	 else
 	 begin
 	  	 declare @sqlstmt  nvarchar(50)
 	  	 set @sqlstmt = N'spdbr_gettimeoptions ' + Convert(nvarchar, @querycode)
 	  	 
 	  	 create table #Date
 	  	 ( 	 
 	  	  	 Option_ID int,
 	  	  	 Description varchar(50),
 	  	  	 Start_Time varchar(50),
 	  	  	 End_Time varchar(50)
 	  	 )
 	  	 insert into #Date execute sp_executesql @sqlstmt
 	  	 if (@startendcode = 1)
 	  	 begin
 	  	  	 select Start_Time from #Date
 	  	 end
 	  	 else
 	  	 begin
 	  	  	 select End_Time from #Date
 	  	 end
 	  	 drop table #Date
 	 end
 	 
/*
 	 declare @query nvarchar(4000)
 	 
 	 
 	 set @query = (select Dashboard_Parameter_Value from Dashboard_Parameter_Default_Values where Dashboard_Template_Parameter_ID = @templateparamid and dashboard_parameter_column = 3)
 	 
 	 create table #Date
 	 (
 	  	 thedate varchar(100)
 	 )       
 	 EXECUTE sp_executesql @query
 	 declare @date varchar(100)
 	 set @date = (select thedate from #Date) 
 	 drop table #Date
 	 select @date
 	 */
end
else if (@paramtype = 2)
begin
 	 select Dashboard_Parameter_Value from Dashboard_Parameter_Default_Values where Dashboard_Template_Parameter_ID = @templateparamid
end
else if (@paramtype =4 or @paramtype = 3)
begin
 	 create table #ParamValue
 	 (
 	  	 Row int,
 	  	 Col int,
 	  	 Presentation bit,
 	  	 SPName varchar(50),
 	  	 Value varchar(7000),
 	  	 Header varchar(50)
 	 )
 	 create table #DisplayColumns
 	 (
 	  	 Col int,
 	  	 Presentation bit,
 	  	 SPName varchar(50)
 	 )
 	 create table #Headers
 	 (
 	  	 dashboard_parameter_default_value_id varchar(50),
 	  	 dashboard_parameter_row int,
 	  	 dashboard_parameter_column int,
 	  	 dashboard_parameter_value varchar(7000),
 	  	 dashboard_datatable_header varchar(50)
 	 )
 	 
 	 insert into #ParamValue (Value, col, row) select dashboard_parameter_value, dashboard_parameter_column, dashboard_parameter_row
 	 from dashboard_parameter_default_values 
 	 where dashboard_template_parameter_id =@templateparamid 
 	 insert into #DisplayColumns (col, presentation, spname) select dt.dashboard_Datatable_column,dt.dashboard_datatable_presentation, dt.dashboard_datatable_column_sp 
 	 from dashboard_datatable_headers dt, dashboard_template_parameters tp
 	 where tp.dashboard_template_parameter_id = @templateparamid
 	 and dt.dashboard_parameter_type_id = tp.dashboard_parameter_type_id
 	 
 	 
 	 
 	 update #ParamValue set Presentation = C.Presentation from #DisplayColumns C, #ParamValue P where C.Col = P.Col
 	 update #ParamValue set SPName  = C.SPName from #DisplayColumns C, #ParamValue P where C.Col = P.Col
 	  
 	 delete from #DisplayColumns where Col in (select Col from #ParamValue)
     	 
 	 insert into #ParamValue (Row, Col, Presentation, SPName) select distinct(P.Row), C.Col, C.Presentation, C.SPName from #ParamValue P, #DisplayColumns C 
 	 where C.Col not in (select Col from #ParamValue)
 	 
 	 
 	 set @sqlstmt =  N'spDBR_Get_Template_Parameter_Default_Value ' + Convert(varchar(7), @templateparamid)
 	  	  	 
 	 insert into #headers (dashboard_parameter_default_value_id, dashboard_parameter_row, dashboard_parameter_column, dashboard_parameter_value, dashboard_datatable_header) EXECUTE sp_executesql @sqlstmt
 	 update #ParamValue set value = h.dashboard_parameter_value, header = h.dashboard_datatable_header from #headers h, #paramvalue p
 	  	 where h.dashboard_parameter_row = p.row and h.dashboard_parameter_column = p.col
 	  	 
 	 select * from #paramvalue order by row, col for xml auto
end
