Create Procedure dbo.spDBR_Get_Parameter_StartEndTimeValue
@templateparamid int,
@reportid int,
@relativedate datetime = null
AS
declare @paramtype int
declare @prevalue varchar(100)
if (@relativedate is null)
begin
set @relativedate = dbo.fnServer_CmnGetDate(getutcdate())
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
 	 if (@querycode = 0)
 	 begin
 	  	 
 	  	 if (@startendcode = 1)
 	  	 begin
 	  	  	 insert into #TimeTable execute spDBR_Shortcut_To_Time @TimeFormula, @RelativeDate
 	  	  	 select value as Start_Time,@startendcode as ColValue from #TimeTable
 	  	 end
 	  	 else
 	  	 begin
 	  	  	 insert into #TimeTable execute spDBR_Shortcut_To_Time @TimeFormula, @RelativeDate
 	  	  	 select value as Start_Time,@startendcode as ColValue from #TimeTable
 	  	 end
 	 end
 	 else if (@querycode > 1)
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
 	  	  	 select Start_Time as Start_Time, @startendcode as ColValue from #Date
 	  	 end
 	  	 else if (@startendcode = 2)
 	  	 begin
 	  	  	 select End_Time as End_Time,@startendcode as ColValue from #Date
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
