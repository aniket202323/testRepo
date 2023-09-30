Create Procedure dbo.spDBR_Get_Parameter_Value2
@templateparamid int,
@reportid int,
@relativedate datetime = null,
@InTimeZone 	  	 varchar(200) = ''  ---23/08/2010 - Ex: 'India Standard Time','Central Stardard Time' 
AS
declare @paramtype int
declare @prevalue varchar(100)
declare @dbTimeZone varchar(200)
select @dbTimeZone = Value From site_parameters where parm_id=192
 	 ---24/08/2010 - Conversion of datetime into UTC e.g. India Standard Time','Central Stardard Time'
 	  	 IF (@InTimeZone='')
 	  	  	 BEGIN
 	  	  	  	  	 
 	  	  	  	  	  	  	  	  	  	  	 
 	  	  	  	 select  @InTimeZone = dashboard_parameter_value from dashboard_parameter_values 
 	  	  	  	  	  	  	 where dashboard_template_parameter_id =
 	  	  	  	  	  	  	 (SELECT Dashboard_template_parameter_id FROM dashboard_template_Parameters WHERE dashboard_Template_id=
 	  	  	  	  	  	  	 (SELECT Dashboard_Template_ID FROM dashboard_reports where Dashboard_report_Id = @reportid)
 	  	  	  	  	  	  	 and dashboard_Template_parameter_Name='38517')
 	  	  	  	  	  	  	 and dashboard_report_id=@reportid
 	  	  	 END
 	  	 PRINT @reportid
 	 PRINT @InTimeZone
 	  	 SELECT @relativedate = dbo.fnServer_CmnConvertTime(@relativedate,@dbTimezone,@InTimeZone)
 	 
if (@relativedate is null)
begin
set @relativedate = dbo.fnServer_cmnConvertTime(dbo.fnServer_CmnGetDate(getutcdate()),@dbTimezone,@InTimeZone)
end
set @paramtype = (select t.Value_Type from Dashboard_Parameter_Types t, dashboard_template_parameters p 
 	 where p.Dashboard_Template_Parameter_ID = @templateparamid and t.dashboard_parameter_type_id = p.dashboard_parameter_type_id)
if (@paramtype = 1)
begin
create table #TimeTable
 	 (
 	  	 value datetime
 	 )
 	 
 	 declare @querycode int
 	 declare @startendcode int
 	 declare @TimeFormula varchar(50)
 	 set @querycode = (select dashboard_parameter_value from dashboard_parameter_values where dashboard_template_parameter_id = @templateparamid and dashboard_parameter_row=1 and dashboard_parameter_column = 3 and dashboard_report_id = @reportid)
 	 set @startendcode = (select dashboard_parameter_value from dashboard_parameter_values where dashboard_template_parameter_id = @templateparamid and dashboard_parameter_row=1 and dashboard_parameter_column = 4 and dashboard_report_id = @reportid)
 	 set @TimeFormula= (select dashboard_parameter_value from dashboard_parameter_values where dashboard_template_parameter_id = @templateparamid and dashboard_parameter_row=1 and dashboard_parameter_column = 5 and dashboard_report_id = @reportid)
 	 PRINT @querycode
 	 if (@querycode = 0)
 	 begin
 	  	 if (@startendcode = 1)
 	  	 begin
 	  	 PRINT @TimeFormula
 	  	 PRINT @RelativeDate
 	  	 PRINT @InTimeZone 
 	  	  	 insert into #TimeTable execute spDBR_Shortcut_To_Time @TimeFormula, @RelativeDate,@InTimeZone
 	  	  	 select value from #TimeTable as Start_Time
 	  	 end
 	  	 else
 	  	 begin
 	  	  	 insert into #TimeTable execute spDBR_Shortcut_To_Time @TimeFormula, @RelativeDate,@InTimeZone
 	  	  	 select value from #TimeTable as End_Time
 	  	 end
 	 end
 	 else if (@querycode > 1)
 	 begin
 	  	 declare @sqlstmt  nvarchar(255)
 	  	 set @sqlstmt = N'spdbr_gettimeoptions ' + Convert(nvarchar, @querycode)+ ','+char(39)+ @InTimeZone + char(39)
 	  	 
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
 	  	  	 select Start_Time as Start_Time from #Date
 	  	 end
 	  	 else if (@startendcode = 2)
 	  	 begin
 	  	  	 select End_Time as End_Time from #Date
 	  	 end
 	  	 else
 	  	 begin
 	  	  	 select NULL as value
 	  	 end
 	  	 drop table #Date
 	 end
 	 else
 	 begin
 	  	 select NULL as value
 	 end
end
else if (@paramtype = 2)
begin
 	 declare @DPV varchar(4000)
 	 set @DPV = (select Dashboard_Parameter_Value from Dashboard_Parameter_Values where Dashboard_Report_ID = @reportid and Dashboard_Template_Parameter_ID = @templateparamid)
 	 if (@DPV = '' or @DPV is null)
 	 begin
 	  	 set @DPV = null
 	 end
 	 select @DPV as Dashboard_Parameter_Value
end
else if (@paramtype = 3)
begin
 	 declare @TimeStampFormula varchar(50)
 	 create table #TimeStampTable
 	 (
 	  	 value datetime
 	 )
 	 set @TimeStampFormula= (select dashboard_parameter_value from dashboard_parameter_values where dashboard_template_parameter_id = @templateparamid and dashboard_parameter_row=1 and dashboard_parameter_column = 2 and dashboard_report_id = @reportid)
 	 insert into #TimeStampTable execute spDBR_Shortcut_To_Time @TimeStampFormula, @RelativeDate
 	 select Convert(varchar(100),value ) from #TimeStampTable as dashboard_parameter_value
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
/* 	 create table #DisplayColumns
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
*/
 	 insert into #ParamValue (Value, row,col) select dashboard_parameter_value, dashboard_parameter_row, dashboard_parameter_column 
 	 from dashboard_parameter_values 
 	 where dashboard_template_parameter_id =@templateparamid 
 	 and dashboard_report_id = @reportid
declare @finalval varchar(7000)
select @finalval = ''
declare @@row int, @@col int, @@value varchar(7000), @@lastrow int
select @@lastrow = 0
Declare V_Cursor INSENSITIVE CURSOR
  For Select row, col, value from #paramvalue order by row, col
  For Read Only
  Open V_Cursor  
V_Loop:
  Fetch Next From V_Cursor Into @@row, @@col, @@value
  If (@@Fetch_Status = 0)
    Begin
       if (@@lastrow = 0)
       begin
         select @finalval = @finalval + @@value
         select @@lastrow = @@row
       end
       else if (@@lastrow = @@row)
       begin
         select @finalval = @finalval + ',' + @@value
       end
       else
       begin
         select @finalval = @finalval + ';' + @@value
         select @@lastrow = @@row
       end
       Goto V_Loop
    End
Close V_Cursor 
Deallocate V_Cursor
if (len(@finalval) > 0)
  select @finalval
else 
  select null
/* 	 insert into #DisplayColumns (col, presentation, spname) select dt.dashboard_Datatable_column,dt.dashboard_datatable_presentation, dt.dashboard_datatable_column_sp 
 	 from dashboard_datatable_headers dt, dashboard_template_parameters tp
 	 where tp.dashboard_template_parameter_id = @templateparamid
 	 and dt.dashboard_parameter_type_id = tp.dashboard_parameter_type_id
 	 
 	 
 	 
 	 update #ParamValue set Presentation = C.Presentation from #DisplayColumns C, #ParamValue P where C.Col = P.Col
 	 update #ParamValue set SPName  = C.SPName from #DisplayColumns C, #ParamValue P where C.Col = P.Col
 	  
 	 
 	  
 	 delete from #DisplayColumns where Col in (select Col from #ParamValue)
 	 insert into #ParamValue (Row, Col, Presentation, SPName) select distinct(P.Row), C.Col, C.Presentation, C.SPName from #ParamValue P, #DisplayColumns C where C.Col not in (select Col from #ParamValue)
 	 
 	 
 	 set @sqlstmt =  N'spDBR_Get_Report_Parameter_Value ' + Convert(varchar(4), @templateparamid) + ',' + Convert(varchar(4), @reportid)
 	  	  	 
 	 insert into #headers (dashboard_parameter_default_value_id, dashboard_parameter_row, dashboard_parameter_column, dashboard_parameter_value, dashboard_datatable_header) EXECUTE sp_executesql @sqlstmt
 	 update #ParamValue set value = h.dashboard_parameter_value, header = h.dashboard_datatable_header from #headers h, #paramvalue p
 	  	 where h.dashboard_parameter_row = p.row and h.dashboard_parameter_column = p.col
 	 
 	 declare @count int
select @count = (select count(row) from #paramvalue) 	 
 	 if (@count = 0)
 	 begin
 	  	 select null
 	 end
 	 else
 	 begin
 	  	 select * from #paramvalue order by row, col for xml auto
 	 end*/
end
else
begin
 	 select null
end
