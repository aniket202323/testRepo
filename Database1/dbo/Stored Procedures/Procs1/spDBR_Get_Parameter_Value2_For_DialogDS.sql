Create Procedure dbo.spDBR_Get_Parameter_Value2_For_DialogDS
@templateparamid int = 194,
@reportid int = 189,
@languageid int = 0
AS
declare @paramtype int
declare @prevalue varchar(100)
set @paramtype = (select distinct t.Value_Type from Dashboard_Parameter_Types t, Dashboard_Template_Parameters p
 	 where p.dashboard_Template_Parameter_ID = @templateparamid and t.dashboard_parameter_type_id = p.dashboard_parameter_type_id)
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
 	 set @querycode = (select dashboard_parameter_value from dashboard_parameter_values where dashboard_template_parameter_id = @templateparamid and dashboard_parameter_row=1 and dashboard_parameter_column = 3 and dashboard_report_id = @reportid)
 	 set @startendcode = (select dashboard_parameter_value from dashboard_parameter_values where dashboard_template_parameter_id = @templateparamid and dashboard_parameter_row=1 and dashboard_parameter_column = 4 and dashboard_report_id = @reportid)
 	 set @TimeFormula = (select dashboard_parameter_value from dashboard_parameter_values where dashboard_template_parameter_id = @templateparamid and dashboard_parameter_row=1 and dashboard_parameter_column = 5 and dashboard_report_id = @reportid)
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
 	 insert into #T2Value select Dashboard_Parameter_Value from Dashboard_Parameter_Values where Dashboard_Report_ID = @reportid and Dashboard_Template_Parameter_ID = @templateparamid
 	 select * from #T2Value
 	 drop table #T2Value
end
else if (@paramtype = 3)
begin
create table #T3Value
(
  [Time Formula] varchar(50)
)
insert into #T3Value select Dashboard_Parameter_Value from Dashboard_Parameter_Values where Dashboard_Report_ID = @reportid and Dashboard_Template_Parameter_ID = @templateparamid
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
 	 create table #T4_Values
 	 (
 	  	 RowHeader int default 1
/* 	  	 v1 varchar(100) default null,
 	  	 v2 varchar(100) default null,
 	  	 v3 varchar(100) default null,
 	  	 v4 varchar(100) default null,
 	  	 v5 varchar(100) default null,
 	  	 v6 varchar(100) default null,
 	  	 v7 varchar(100) default null,
 	  	 v8 varchar(100) default null,
 	  	 v9 varchar(100) default null,
 	  	 v10 varchar(100) default null*/
 	 )
 	 insert into #ParamValue (Value, row,col) select dashboard_parameter_value, dashboard_parameter_row, dashboard_parameter_column 
 	 from dashboard_parameter_values 
 	 where dashboard_template_parameter_id =@templateparamid 
 	 and dashboard_report_id = @reportid
 	 insert into #DisplayColumns (col, presentation, spname, header) 
 	 select dt.dashboard_Datatable_column,dt.dashboard_datatable_presentation, dt.dashboard_datatable_column_sp, 
 	  	 case when isnumeric(dt.dashboard_datatable_header) = 1 then (dbo.fnDBTranslate(@languageid, dt.dashboard_datatable_header, dt.dashboard_datatable_header)) 
 	  	 else (dt.dashboard_datatable_header)
 	  	 end as dashboard_datatable_header 	 
 	 from dashboard_datatable_headers dt, dashboard_template_parameters tp
 	 where tp.dashboard_template_parameter_id = @templateparamid
 	 and dt.dashboard_parameter_type_id = tp.dashboard_parameter_type_id
 	 
 	 
 	 
 	 update #ParamValue set Presentation = C.Presentation from #DisplayColumns C, #ParamValue P where C.Col = P.Col
 	 update #ParamValue set SPName  = C.SPName from #DisplayColumns C, #ParamValue P where C.Col = P.Col
 	   
 	 declare @currentRow int,@col int,@row int,@value varchar(100), @header varchar(100)
 	 declare @SelectCommand nvarchar(3000)
 	 declare @AlterCommand nvarchar(3000)
 	 declare @InsertCommand nvarchar(3000)
 	 set @SelectCommand = 'select '
 	 set @InsertCommand = 'insert into #T4_Values ('
 	 
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
 	  	  	  	 set @selectcommand = @selectcommand + ','
 	  	  	  	 set @insertcommand = @insertcommand + ','
 	  	  	 end
 	  	  	 set @AlterCommand = 'Alter table #T4_Values Add [' + @header + '] varchar(100)'
 	  	  	 set @SelectCommand = @SelectCommand + '[' + @header + ']'
 	  	  	 set @InsertCommand = @InsertCommand + '[' + @header + ']'
 	  	  	 execute sp_executesql @AlterCommand
 	  	  	 Goto Table_Loop
 	  	 End
 	 Close Table_Cursor 
 	 Deallocate Table_Cursor
  set @insertcommand = @insertcommand + ') values ('
 	 set @selectcommand = @selectcommand + ' from #T4_Values'
 	 
 	  
 	 delete from #DisplayColumns where Col in (select Col from #ParamValue)
 	 insert into #ParamValue (Row, Col, Presentation, SPName) select distinct(P.Row), C.Col, C.Presentation, C.SPName from #ParamValue P, #DisplayColumns C where C.Col not in (select Col from #ParamValue)
 	 
 	 declare @sqlstmt nvarchar(4000)
 	 set @sqlstmt =  N'spDBR_Get_Report_Parameter_Value ' + Convert(varchar(7), @templateparamid) + ',' + Convert(varchar(7), @reportid)
 	 
 	 insert into #headers (dashboard_parameter_default_value_id, dashboard_parameter_row, dashboard_parameter_column, dashboard_parameter_value, dashboard_datatable_header) EXECUTE sp_executesql @sqlstmt
 	 update #ParamValue set value = h.dashboard_parameter_value, header = h.dashboard_datatable_header from #headers h, #paramvalue p
 	  	 where h.dashboard_parameter_row = p.row and h.dashboard_parameter_column = p.col
 	  	 set @currentRow = (Select min(row) from #ParamValue)
 	  	 
 	  	 
 	 declare @ContinueCount int
 	 set @ContinueCount = (select count(row) from #ParamValue)
 	 if (@ContinueCount > 0)
 	 begin 	 
 	  	 declare @insertrow nvarchar(3000)
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
 	  	  	  	  	  	 set @insertrow = @insertcommand
 	  	  	  	  	 end
 	  	  	  	  	 if (@col > 1)
 	  	  	  	  	 begin 	 
 	  	  	  	  	  	 set @insertrow = @insertrow + ','
 	  	  	  	  	 end
 	  	  	  	  	 set @insertrow = @insertrow + '"' + @value + '"'
 	  	  	  	 end
 	  	  	  	 else
 	  	  	  	 begin
 	  	  	  	  	 set @currentRow = @row
 	  	  	  	  	 if not @insertrow = ''
 	  	  	  	  	 begin
 	  	  	  	  	  	 set @insertrow = @insertrow + ')'
 	  	  	  	  	  	 execute sp_executesql @insertrow
 	  	  	  	  	 end
 	  	  	  	  	 set @insertrow = @insertcommand + '"' + @value + '"'
 	  	  	  	 end
 	  	  	  	 Goto Row_Loop
 	  	  	 End
 	 
 	  	 Close Row_Cursor 
 	  	 Deallocate Row_Cursor
 	  	 if (not @insertrow = '')
 	  	 begin
 	  	  	 set @insertrow = @insertrow + ')'
 	  	 execute sp_executesql @insertrow
 	  	 end
 	 end
exec (@SelectCommand)
end
