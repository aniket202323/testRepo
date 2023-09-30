Create Procedure dbo.spDBR_Get_Report_Parameter_Default_Value_For_DialogDS
@templateparamid int = 1570,
@languageid int = 0
AS
declare @paramtype int
declare @prevalue varchar(100)
set @paramtype = (select distinct t.Value_Type from Dashboard_Parameter_Types t, dashboard_template_parameters p 
 	 where p.Dashboard_Template_Parameter_ID = @templateparamid and t.dashboard_parameter_type_id = p.dashboard_parameter_type_id)
if (@paramtype = 1)
begin
 	 create table #T1Value
 	 (
 	  	 [Query Code] int,
 	  	 [Start/End Code] int,
 	  	 [Time Formula] varchar(50)
 	 )
 	 declare @querycode int
 	 declare @startendcode int
 	 declare @TimeFormula varchar(50)
 	 set @querycode = (select dashboard_parameter_value from dashboard_parameter_default_values where dashboard_template_parameter_id = @templateparamid and dashboard_parameter_row=1 and dashboard_parameter_column = 3)
 	 set @startendcode = (select dashboard_parameter_value from dashboard_parameter_default_values where dashboard_template_parameter_id = @templateparamid and dashboard_parameter_row=1 and dashboard_parameter_column = 4)
 	 set @TimeFormula = (select dashboard_parameter_value from dashboard_parameter_default_values where dashboard_template_parameter_id = @templateparamid and dashboard_parameter_row=1 and dashboard_parameter_column = 5)
 	 insert into #T1Value values(@querycode, @startendcode, @TimeFormula)
 	 select * from #T1Value
 	 drop table #T1Value
end
else if (@paramtype = 2)
begin
 	 create table #T2Value
 	 (
 	  	 value varchar(4000)
 	 )
 	 insert into #T2Value select Dashboard_Parameter_Value from Dashboard_Parameter_Default_Values where Dashboard_Template_Parameter_ID = @templateparamid
 	 select * from #T2Value
 	 drop table #T2Value
end
else if (@paramtype = 3)
begin
create table #T3Value
(
  [Time Formula] varchar(50)
)
insert into #T3Value select Dashboard_Parameter_Value from Dashboard_Parameter_Default_Values where Dashboard_Template_Parameter_ID = @templateparamid
select * from #T3Value
drop table #T3Value
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
 	  	 SPName varchar(50),
 	  	 Header varchar(50)
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
 	 insert into #DisplayColumns (col, presentation, spname, header) 
 	  	 select dt.dashboard_Datatable_column,dt.dashboard_datatable_presentation, dt.dashboard_datatable_column_sp, 
 	 case when isnumeric(dt.dashboard_datatable_header) = 1 then (dbo.fnDBTranslate(@languageid, dt.dashboard_datatable_header, dt.dashboard_datatable_header)) 
 	  	 else (dt.dashboard_datatable_header)
 	  	 end as dashboard_datatable_header
--dt.dashboard_datatable_header 
 	 from dashboard_datatable_headers dt, dashboard_template_parameters tp
 	 where tp.dashboard_template_parameter_id = @templateparamid
 	 and dt.dashboard_parameter_type_id = tp.dashboard_parameter_type_id
 	 
 	 declare @currentRow int,@col int,@row int,@value varchar(100), @header varchar(100)
 	 declare @createtable nvarchar(3000)
 	 set @createtable = 'create table #T4Value ('
 	 Declare Table_Cursor INSENSITIVE CURSOR
 	  	 For Select col, header from #DisplayColumns order by col
 	  	 For Read Only
 	  	 Open Table_Cursor  
 	 Table_Loop:
 	  	 Fetch Next From Table_Cursor Into @col, @header
 	  	 If (@@Fetch_Status = 0)
 	  	 Begin
 	  	  	 if (@col > 1)
 	  	  	 begin
 	  	  	  	 set @createtable = @createtable + ','
 	  	  	 end
 	  	  	 set @createtable = @createtable + '[' + @header + ']' + ' varchar(100)' 
 	  	  	 Goto Table_Loop
 	  	 End
 	 Close Table_Cursor 
 	 Deallocate Table_Cursor
 	 set @createtable = @createtable + ')'
-- 	 EXECUTE sp_executesql @createtable
 	 
 	 
 	 update #ParamValue set Presentation = C.Presentation from #DisplayColumns C, #ParamValue P where C.Col = P.Col
 	 update #ParamValue set SPName  = C.SPName from #DisplayColumns C, #ParamValue P where C.Col = P.Col
 	  
 	 delete from #DisplayColumns where Col in (select Col from #ParamValue)
     	 
 	 insert into #ParamValue (Row, Col, Presentation, SPName) select distinct(P.Row), C.Col, C.Presentation, C.SPName from #ParamValue P, #DisplayColumns C 
 	 where C.Col not in (select Col from #ParamValue)
 	 
 	 declare @sqlstmt nvarchar(4000)
 	 set @sqlstmt =  N'spDBR_Get_Template_Parameter_Default_Value ' + Convert(varchar(7), @templateparamid)
 	  	  	 
 	 insert into #headers (dashboard_parameter_default_value_id, dashboard_parameter_row, dashboard_parameter_column, dashboard_parameter_value, dashboard_datatable_header) EXECUTE sp_executesql @sqlstmt
 	 update #ParamValue set value = h.dashboard_parameter_value, header = h.dashboard_datatable_header from #headers h, #paramvalue p
 	  	 where h.dashboard_parameter_row = p.row and h.dashboard_parameter_column = p.col
 	  	 
 	  	 set @currentRow = (Select min(row) from #ParamValue)
 	 declare @ContinueCount int
 	 set @ContinueCount = (select count(row) from #ParamValue)
 	 if (@ContinueCount > 0)
 	 begin 	 
 	  	 
 	  	 declare @tablerow nvarchar(3000)
 	  	 set @tablerow = ''
 	  	 Declare Row_Cursor INSENSITIVE CURSOR
 	  	  	 For Select row,col, value from #ParamValue order by row, col
 	  	  	 For Read Only
 	  	  	 Open Row_Cursor    
 	  	 Row_Loop:
 	  	  	 Fetch Next From Row_Cursor Into @row, @col, @value
 	  	  	 If (@@Fetch_Status = 0)
 	  	  	 Begin
 	  	  	  	 if (@row = @currentRow)
 	  	  	  	 begin
 	  	  	  	  	 if (@col = 1)
 	  	  	  	  	 begin
 	  	  	  	  	  	 set @tablerow = 'insert into #T4Value values('
 	  	  	  	  	 end
 	  	  	  	  	 if (@col > 1)
 	  	  	  	  	 begin 	 
 	  	  	  	  	  	 set @tablerow = @tablerow + ','
 	  	  	  	  	 end
 	  	  	  	  	 set @tablerow = @tablerow + '"' + @value + '"' 
 	  	  	  	 end
 	  	  	  	 else
 	  	  	  	 begin
 	  	  	  	  	 set @currentRow = @row
 	  	  	  	  	 if not @tablerow = ''
 	  	  	  	  	 begin
 	  	  	  	  	  	 set @tablerow = @tablerow + ')'
 	 
 	  	  	  	  	  	 set @createtable = @createtable + ' ' + @tablerow
-- 	  	  	  	  	  	 EXECUTE sp_executesql @tablerow
 	  	  	  	  	 end
 	  	  	  	  	 set @tablerow = 'insert into #T4Value values('
 	  	  	  	  	 set @tablerow = @tablerow + '"' + @value + '"' 
 	  	  	  	 end
 	  	  	  	 Goto Row_Loop
 	  	  	 End
 	 
 	  	 Close Row_Cursor 
 	  	 Deallocate Row_Cursor
 	  	 if (not @tablerow = '')
 	  	 begin
 	  	  	 set @tablerow = @tablerow + ')'
 	  	  	 set @createtable = @createtable + ' ' + @tablerow
-- 	  	  	 EXECUTE sp_executesql @tablerow
 	  	 end
 	 end 	 
 	 
 	 set @createtable = @createtable + '  	 select * from #T4Value'
 	 EXECUTE sp_executesql @createtable
 	 
end
