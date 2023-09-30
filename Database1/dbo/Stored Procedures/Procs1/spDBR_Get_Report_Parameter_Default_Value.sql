Create Procedure dbo.spDBR_Get_Report_Parameter_Default_Value
@templateparamid int = 1570
AS
declare @paramtype int
declare @prevalue varchar(100)
set @paramtype = (select distinct t.Value_Type from Dashboard_Parameter_Types t, dashboard_template_parameters p
 	 where p.Dashboard_Template_Parameter_ID = @templateparamid and t.dashboard_parameter_type_id = p.dashboard_parameter_type_id)
if (@paramtype = 1)
begin
 	 declare @querycode int
 	 declare @startendcode int
 	 declare @TimeFormula varchar(50)
 	 create table #TimeTable
 	 (
 	  	 value datetime
 	 )
 	 set @querycode = (select dashboard_parameter_value from dashboard_parameter_default_values where dashboard_template_parameter_id = @templateparamid and dashboard_parameter_row=1 and dashboard_parameter_column = 3)
 	 set @startendcode = (select dashboard_parameter_value from dashboard_parameter_default_values where dashboard_template_parameter_id = @templateparamid and dashboard_parameter_row=1 and dashboard_parameter_column = 4)
 	 set @TimeFormula = (select dashboard_parameter_value from dashboard_parameter_default_values where dashboard_template_parameter_id = @templateparamid and dashboard_parameter_row=1 and dashboard_parameter_column = 5)
 	 if (@querycode = 0)
 	 begin
 	  	 if (@startendcode = 1)
 	  	 begin
 	  	  	 insert into #TimeTable execute spDBR_Shortcut_To_Time @TimeFormula
 	  	  	 select value from #TimeTable as Start_Time
 	  	 end
 	  	 else
 	  	 begin
 	  	  	 insert into #TimeTable execute spDBR_Shortcut_To_Time @TimeFormula
 	  	  	 select value from #TimeTable as End_Time
 	  	 end
 	 end
 	 else
 	 begin
 	  	 declare @sqlstmt  nvarchar(50)
 	  	 set @sqlstmt = N'spdbr_gettimeoptions ' + Convert(nvarchar, @querycode)
 	  	 
 	  	 create table #Date
 	  	 ( 	 
 	  	  	 Option_ID int,
 	  	  	 Description varchar(50),
 	  	  	 Start_Time datetime,
 	  	  	 End_Time datetime
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
end
else if (@paramtype = 2)
begin
 	 select Dashboard_Parameter_Value from Dashboard_Parameter_Default_Values where Dashboard_Template_Parameter_ID = @templateparamid
end
else if (@paramtype = 3)
begin
 	 declare @TimeStampFormula varchar(50)
 	 create table #TimeStampTable
 	 (
 	  	 value datetime
 	 )
 	 set @TimeStampFormula = (select dashboard_parameter_value from dashboard_parameter_default_values where dashboard_template_parameter_id = @templateparamid and dashboard_parameter_row=1 and dashboard_parameter_column = 2)
 	 insert into #TimeStampTable execute spDBR_Shortcut_To_Time @TimeStampFormula
 	 select value from #TimeStampTable as dashboard_parameter_value
end
else if (@paramtype =4)
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
