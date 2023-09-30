Create Procedure dbo.spDBR_Create_Ad_Hoc_Report
@reportfromid int,
@templateid int
AS
 	 declare @reportid int
 	 declare @reportname varchar(100)
 	 declare @server varchar(100)
 	 declare @templatedesc varchar(4000)
 	 declare @column int
 	 declare @columnposition int
 	 declare @hasframe int
 	 declare @expanded int
 	 declare @allowremove int
 	 declare @allowminimize int
 	 declare @cachecode int
 	 declare @cachetimeout int
 	 declare @detaillink varchar(500)
 	 declare @helplink varchar(500)
 	 declare @securitygroup int
 	 
 	 set @reportname = (select case when isnumeric(dashboard_template_name) = 1 then (dbo.fnDBTranslate(N'0', dashboard_template_name, dashboard_template_name)) 
 	  	  	  	  	 else (dashboard_template_name)
 	  	  	  	  	 end as dashboard_template_name
 	  	   	  	 from dashboard_templates where dashboard_template_id = @templateid)
 	 set @server =(select dashboard_report_server from dashboard_Reports where dashboard_Report_id = @reportfromid)
 	 set @securitygroup =(select dashboard_report_security_group_id from dashboard_Reports where dashboard_Report_id = @reportfromid)
 	 set @column = (select dashboard_template_column from dashboard_templates where dashboard_template_id = @templateid)
 	 set @columnposition = (select dashboard_template_column_position from dashboard_templates where dashboard_template_id = @templateid)
 	 set @hasframe = (select dashboard_template_has_frame from dashboard_templates where dashboard_template_id = @templateid)
 	 set @expanded = (select dashboard_template_expanded from dashboard_templates where dashboard_template_id = @templateid)
 	 set @allowremove = (select dashboard_template_allow_remove from dashboard_templates where dashboard_template_id = @templateid)
 	 set @allowminimize = (select dashboard_template_allow_minimize from dashboard_templates where dashboard_template_id = @templateid)
 	 set @cachecode = (select dashboard_template_cache_code from dashboard_templates where dashboard_template_id = @templateid)
 	 set @cachetimeout = (select dashboard_template_cache_timeout from dashboard_templates where dashboard_template_id = @templateid)
 	 set @detaillink = (select dashboard_template_detail_link from dashboard_templates where dashboard_template_id = @templateid)
 	 set @helplink = (select dashboard_template_help_link from dashboard_templates where dashboard_template_id = @templateid)
 	 set @templatedesc = (select dashboard_template_description from dashboard_Templates where dashboard_template_id = @templateid)
 	 insert into Dashboard_Reports (Dashboard_Report_Name, Dashboard_Template_ID, Dashboard_Report_Version_Count, Dashboard_Report_Ad_Hoc_Flag, Dashboard_Report_Server, Dashboard_Report_Number_Hits, Dashboard_Report_Create_Date, Dashboard_Report_Description, dashboard_report_column, dashboard_report_column_position, dashboard_report_has_frame, dashboard_report_expanded, dashboard_report_allow_remove, dashboard_report_allow_minimize, dashboard_report_cache_code, dashboard_report_cache_timeout, dashboard_report_detail_link, dashboard_report_help_link, dashboard_report_security_group_id) 
 	 values (@reportname,@templateid, 1, 1, @server, 0, dbo.fnServer_CmnGetDate(getutcdate()),@templatedesc, @column, @columnposition, @hasframe, @expanded, @allowremove, @allowminimize, @cachecode, @cachetimeout, @detaillink, @helplink, @securitygroup )
 	 
 	 
 	 set @reportid =  (select scope_identity())
 	 insert into dashboard_parameter_values (dashboard_report_id, dashboard_template_parameter_id, dashboard_parameter_value, dashboard_parameter_column, dashboard_parameter_row)
 	 select @reportid, dv.dashboard_template_parameter_id, dv.dashboard_parameter_value, dv.dashboard_parameter_column, dv.dashboard_parameter_row
 	 from Dashboard_Parameter_Default_Values dv, dashboard_template_parameters tp
 	 where dv.dashboard_template_parameter_id = tp.dashboard_template_parameter_id
 	 and tp.dashboard_template_id = @templateid
create table #TempValue
(
 	 row int,
 	 col int,
 	 value varchar(4000)
)
declare @@pvid int, @@pvtype int, @@pvname varchar(100), @@pvFinder int, @@vtype int
Declare PV_Cursor INSENSITIVE CURSOR
  For Select distinct(dpv.dashboard_template_parameter_id) from dashboard_parameter_values dpv, dashboard_template_parameters dtp, dashboard_parameter_types dpt where dpv.dashboard_report_id = @reportfromid and dpv.dashboard_template_parameter_id = dtp.dashboard_template_parameter_id and dtp.dashboard_parameter_type_id = dpt.dashboard_parameter_type_id and not dpt.dashboard_parameter_type_desc = '38180' order by dpv.dashboard_template_parameter_id 
  For Read Only
  Open PV_Cursor  
PV_Loop:
  Fetch Next From PV_Cursor Into @@pvid
  If (@@Fetch_Status = 0)
    Begin
 	  	 set @@pvtype = (select dashboard_parameter_type_id from dashboard_template_parameters where dashboard_template_parameter_id = @@pvid)
 	  	 set @@pvname = (select dashboard_template_parameter_name from dashboard_template_parameters where dashboard_template_parameter_id = @@pvid)
 	  	 
 	  	 insert into #TempValue (value, col, row) 
 	  	 select a.dashboard_parameter_value, a.dashboard_parameter_column,a.dashboard_parameter_row  
 	  	  	 from dashboard_parameter_values a, dashboard_template_parameters b
 	  	  	  	 where a.dashboard_report_id = @reportfromid 
 	  	  	 and a.dashboard_template_parameter_id = b.dashboard_template_parameter_id
 	  	  	 and b.dashboard_parameter_type_id = @@pvtype and b.dashboard_template_parameter_name = @@pvname
 	  	  	  	 
set @@pvFinder = null
declare @@pvDesc varchar(50)
set @@pvDesc = (select distinct(tpt.dashboard_parameter_type_desc) from dashboard_parameter_values pv, dashboard_template_parameters tp, dashboard_parameter_types tpt
 	  	  	  	 where pv.dashboard_report_id = @reportid and pv.dashboard_template_parameter_id = tp.dashboard_template_parameter_id 
 	  	  	  	 and tp.dashboard_parameter_type_id = 
(select btp.dashboard_parameter_type_id from dashboard_template_parameters btp where btp.dashboard_template_parameter_id = @@pvid ) and tp.dashboard_template_parameter_name = 
(select btp.dashboard_template_parameteR_name from dashboard_template_parameters btp where btp.dashboard_template_parameter_id = @@pvid)
and tpt.dashboard_parameter_type_id = tp.dashboard_parameter_type_id
)
set @@pvFinder = (select distinct(pv.dashboard_template_parameter_id) from dashboard_parameter_values pv, dashboard_template_parameters tp
 	  	  	  	 where pv.dashboard_report_id = @reportid and pv.dashboard_template_parameter_id = tp.dashboard_template_parameter_id 
 	  	  	  	 and tp.dashboard_parameter_type_id = 
(select btp.dashboard_parameter_type_id from dashboard_template_parameters btp where btp.dashboard_template_parameter_id = @@pvid ) and tp.dashboard_template_parameter_name = 
(select btp.dashboard_template_parameteR_name from dashboard_template_parameters btp where btp.dashboard_template_parameter_id = @@pvid))
/*(select distinct(dashboard_template_parameter_id) from dashboard_parameter_values
 	  	  	  	 where dashboard_report_id = @reportid
 	  	  	  	  	 and dashboard_template_parameter_id = @@pvid)*/
if (not @@pvFinder is null and not @@pvDesc like '%Column Visibility%')
begin
 	 delete from dashboard_parameter_values where dashboard_report_id = @reportid and dashboard_template_parameter_id = @@pvFinder
end
 	 declare @@npvid int
 	 
select @@npvid = (select distinct(tp.dashboard_template_parameter_id) from dashboard_template_parameters tp
 	  	  	  	 where tp.dashboard_template_id = @templateid 
 	  	  	  	 and tp.dashboard_parameter_type_id = 
(select btp.dashboard_parameter_type_id from dashboard_template_parameters btp where btp.dashboard_template_parameter_id = @@pvid ) and tp.dashboard_template_parameter_name = 
(select btp.dashboard_template_parameteR_name from dashboard_template_parameters btp where btp.dashboard_template_parameter_id = @@pvid))
if (not @@npvid is null and (not @@pvDesc like '%Column Visibility%' or @@pvDesc is null))
begin
 	 insert into dashboard_parameter_values (Dashboard_Report_ID, Dashboard_Template_Parameter_ID, Dashboard_Parameter_Row, Dashboard_Parameter_Column, Dashboard_Parameter_Value)  	  	  	  	  	  	  	  	  	  	 
 	 select 	 @reportid, @@npvid,tv.row,tv.col, tv.value
 	 from #tempvalue tv 
end
 	 delete from #tempvalue     
 	 Goto PV_Loop
    End
Close PV_Cursor 
Deallocate PV_Cursor
 	 insert into dashboard_report_links (dashboard_template_link_id, dashboard_report_from_id)
 	 select dtl.dashboard_template_link_id, @reportID from dashboard_template_links dtl where dashboard_template_link_from = @templateid
return @ReportID
