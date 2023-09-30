Create Procedure dbo.spDBR_Import_Database
@xml ntext
AS
/*This is a temporary fix until Dave can get the database changes around*/
alter table dashboard_template_parameters alter column allow_nulls int
 	 create table #Dashboard_Parameter_Data_Types
 	 (
 	  	 Dashboard_Parameter_Data_Type_ID int,
 	  	 Dashboard_Parameter_Data_Type varchar(100) 
 	 
 	 )
 	 create table #Dashboard_Parameter_Types
 	 (
 	  	 Dashboard_Parameter_Type_ID int,
 	  	 Dashboard_Parameter_Type_Desc varchar(100),
 	  	 Dashboard_Parameter_Data_Type_ID int,
 	  	 locked bit,
 	  	 Version int,
 	  	 Value_Type int, 
 	  	 Processed int default 0
 	 )
 	 create table #Dashboard_DataTable_Headers
 	 (
 	  	 Dashboard_DataTable_Header_ID int,
 	  	 Dashboard_Parameter_Type_ID int,
 	  	 Dashboard_DataTable_Column int,
 	  	 Dashboard_DataTable_Header varchar(50),
 	  	 Dashboard_DataTable_Presentation bit,
 	  	 Dashboard_DataTable_Column_SP varchar(100),
 	  	 Processed int default 0
 	 )
 	 create table #Dashboard_DataTable_Presentation_Parameters
 	 (
 	  	 Dashboard_DataTable_Presentation_Parameter_ID int,
 	  	 Dashboard_DataTable_Header_ID int,
 	  	 Dashboard_DataTable_Presentation_Parameter_Order int,
 	  	 Dashboard_DataTable_Presentation_Parameter_Input int,
 	  	 Processed int default 0,
 	  	 Processed_Input int default 0
 	 )
 	 create table #Dashboard_Dialogues
 	 (
 	  	 Dashboard_Dialogue_ID int,
 	      	 Dashboard_Dialogue_Name varchar(100),
 	  	 External_Address bit,
 	  	 URL varchar(1000),
 	  	 Parameter_Count int,
 	  	 locked bit,
 	  	 Version int 
 	 )
 	 create table #Dashboard_Dialogue_Parameters
 	 (
 	  	 Dashboard_Dialogue_Parameter_ID int,
 	  	 Dashboard_Dialogue_ID int,
 	  	 Dashboard_Parameter_Type_Id int, 
 	  	 Default_Dialogue bit,
 	  	 Processed int default 0 
 	 )
 	 create table #Dashboard_Template_Parameters
 	 (
 	  	 Dashboard_Template_Parameter_ID int,
 	  	 Dashboard_Template_ID int,
 	  	 Dashboard_Template_Parameter_Order int,
 	  	 Dashboard_Parameter_Type_ID int,
 	  	 Dashboard_Template_Parameter_Name varchar(100),
 	  	 Has_Default_Value bit,
 	  	 Allow_Nulls int,
 	  	 Processed int default 0 
 	 )
 	 create table #Dashboard_Parameter_Default_Values
 	 (
 	  	 Dashboard_Parameter_Default_Value_ID int,
 	  	 Dashboard_Template_Parameter_ID int,
 	  	 Dashboard_Parameter_Row int,
 	  	 Dashboard_Parameter_Column int,
 	  	 Dashboard_Parameter_Value varchar(4000),
 	  	 Processed int default 0,
 	  	 UpdateValue int default 0 
 	 )
 	 create table #Dashboard_Parameter_Values
 	 (
 	  	 Dashboard_Parameter_Value_ID int,
 	  	 Dashboard_Report_ID int,
 	  	 Dashboard_Template_Parameter_ID int,
 	  	 Dashboard_Parameter_Row int,
 	  	 Dashboard_Parameter_Column int,
 	  	 Dashboard_Parameter_Value varchar(4000),
 	  	 Processed int default 0,
 	  	 UpdateValue int default 0 
 	 )
 	 create table #Dashboard_Template_Dialogue_Parameters
 	 (
 	  	 Dashboard_Template_Dialogue_Parameter_ID int,
 	  	 Dashboard_Dialogue_ID int,
 	  	 Dashboard_Template_Parameter_ID int,
 	  	 Processed int default 0 
 	 )
 	 create table #Dashboard_Templates
 	 (
 	  	 Dashboard_Template_ID int,
 	  	 Dashboard_Template_Name varchar(100),
 	  	 Dashboard_Template_XSL text,
 	  	 Dashboard_Template_XSL_Filename varchar(100),
 	  	 Dashboard_Template_Preview image,
 	  	 Dashboard_Template_Preview_Filename varchar(100),
 	  	 Dashboard_Template_Build int,
 	  	 Dashboard_Template_Locked int,
 	  	 Dashboard_Template_Launch_Type int,
 	  	 Dashboard_Template_Procedure varchar(100),
 	  	 Dashboard_Template_Size_Unit int,
 	  	 Dashboard_Template_Description varchar(4000),
 	  	 Dashboard_Template_Column int,
 	  	 Dashboard_Template_Column_Position int,
 	  	 Dashboard_Template_Has_Frame int,
 	  	 Dashboard_Template_Expanded int,
 	  	 Dashboard_Template_Allow_Remove int,
 	  	 Dashboard_Template_Allow_Minimize int,
 	  	 Dashboard_Template_Cache_Code int,
 	  	 Dashboard_Template_Cache_Timeout int,
 	  	 Dashboard_Template_Detail_Link varchar(500),
 	  	 Dashboard_Template_Help_Link varchar(500),
 	  	 version int,
 	  	 Height int,
 	  	 Width int,
 	  	 type int,
 	  	 dashboard_template_fixed_height bit,
 	  	 dashboard_template_fixed_width bit,
 	  	 basetemplate bit
 	 )
 	 create table #Dashboard_Template_Links
 	 (
 	  	 Dashboard_Template_Link_ID int,
 	  	 Dashboard_Template_Link_From int,
 	  	 Dashboard_Template_Link_To int,
 	  	 Processed_a int default 0, 
 	  	 Processed_b int default 0
 	 )
 	 create table #Dashboard_Report_Links
 	 (
 	  	 Dashboard_Report_Link_ID int,
 	  	 Dashboard_Template_Link_ID int,
 	  	 Dashboard_Report_From_ID int,
 	  	 Dashboard_Report_To_ID int,
 	  	 Processed_a int default 0, 
 	  	 Processed_b int default 0,
 	  	 Processed_Template int default 0
 	 )
 	 create table #Dashboard_Reports
 	 (
 	  	 dashboard_report_id int,
 	  	 dashboard_template_id int,
 	  	 dashboard_report_version_count int,
 	  	 dashboard_report_ad_hoc_flag bit,
 	  	 dashboard_session_id int,
 	  	 dashboard_report_security_group_id int,
 	  	 dashboard_report_server varchar(100),
 	  	 dashboard_report_number_hits int,
 	  	 dashboard_report_description varchar(4000),
 	  	 dashboard_report_create_date datetime,
 	  	 dashboard_report_column int,
 	  	 dashboard_report_column_position int,
 	  	 dashboard_report_has_frame int,
 	  	 dashboard_report_expanded int,
 	  	 dashboard_reporT_allow_remove int,
 	  	 dashboard_report_allow_minimize int,
 	  	 dashboard_report_cache_code int,
 	  	 dashboard_report_cache_timeout int,
 	  	 dashboard_report_detail_link varchar(500),
 	  	 dashboard_report_help_link varchar(500),
 	  	 dashboard_report_name varchar(100),
 	  	 version int default 1,
 	  	 Processed int default 0
 	 )
 	 create table #Dashboard_Schedule
 	 (
 	  	 Dashboard_schedule_id int,
 	  	 dashboard_report_id int,
 	  	 dashboard_frequency_based bit,
 	  	 dashboard_calendar_based bit,
 	  	 dashboard_event_based bit,
 	  	 dashboard_last_run_time datetime,
 	  	 dashboard_on_demand_based bit,
 	  	 Processed int default 0
 	 )
 	 create table #Dashboard_Calendar
 	 (
 	  	 dashboard_calendar_id int,
 	  	 dashboard_schedule_id int,
 	  	 dashboard_first_of_month bit,
 	  	 dashboard_last_of_month bit,
 	  	 dashboard_first_of_quarter bit,
 	  	 dashboard_last_of_quarter bit,
 	  	 dashboard_first_of_year bit,
 	  	 dashboard_last_of_year bit,
 	  	 dashboard_day_of_week bit,
 	  	 dashboard_custom_date bit,
 	  	 Processed int default 0
 	 )
 	 create table #dashboard_schedule_events
 	 (
 	  	 dashboard_schedule_event_id int,
 	  	 dashboard_schedule_id int,
 	  	 dashboard_event_scope_id int,
 	  	 dashboard_event_type_id int,
 	  	 pu_id int,
 	  	 var_id int,
 	  	 pu_desc varchar(50),
 	  	 var_desc varchar(50),
 	  	 Processed int default 0
 	 )
 	 create table #dashboard_schedule_frequency
 	 (
 	  	 dashboard_schedule_frequency_id int,
 	  	 dashboard_schedule_id int,
 	  	 dashboard_frequency_base_time datetime,
 	  	 dashboard_frequency int,
 	  	 dashboard_frequency_type_id int,
 	  	 Processed int default 0
 	 )
 	 create table #dashboard_custom_dates
 	 (
 	  	 dashboard_custom_date_id int,
 	  	 dashboard_calendar_id int,
 	  	 dashboard_day_to_run datetime,
 	  	 dashboard_completed bit,
 	  	 Processed int default 0
 	  	  	 
 	 )
 	 create table #dashboard_day_of_week
 	 (
 	  	 Dashboard_day_of_week_id int,
 	  	 dashboard_calendar_id int,
 	  	 dashboard_day_of_week int,
 	  	 Processed int default 0
 	 )
/*--for 4.2 & 4.3 upgrade.  Move Unit Status List to OEE By Units--*/
declare @templatecount int, @TempId1 int, @TempId2 int, @TypeId int, @ParmId int
select @templatecount =  count(dashboard_template_id)  from dashboard_templates where dashboard_template_name = '38481'
if (@templatecount > 0)
begin
select @Tempid1 = dashboard_template_id  from dashboard_templates where dashboard_template_name = '38481'
select @Tempid2 = dashboard_template_id  from dashboard_templates where dashboard_template_name = '38082'
 	 declare @@ReportId int, @@ReportName varchar(500), @@SecurityGroup int, @@VersionCount int, @@Server varchar(500)
 	 Declare FourTwoUpgrade_Cursor INSENSITIVE CURSOR
   	  	 For Select dashboard_report_id, dashboard_report_name, dashboard_report_security_group_id, dashboard_report_version_Count, dashboard_report_server from dashboard_reports where dashboard_template_id = @Tempid2 
   	  	 For Read Only
   	 Open FourTwoUpgrade_Cursor  
 	 FourTwoUpgrade_Loop:
 	  	 Fetch Next From FourTwoUpgrade_Cursor Into @@ReportId, @@ReportName, @@SecurityGroup, @@VersionCount, @@Server
 	  	 If (@@Fetch_Status = 0)
 	  	 Begin
 	  	  	 execute spDBR_Update_Report @@ReportId, @@ReportName, @Tempid1, @@SecurityGroup, @@VersionCount, @@Server
 	  	  	 Goto FourTwoUpgrade_Loop
 	  	 End
 	 Close FourTwoUpgrade_Cursor 
 	 Deallocate FourTwoUpgrade_Cursor
 	 execute spDBR_Delete_Template @Tempid2
end
else
begin
  select @Tempid2 = dashboard_template_id  from dashboard_templates where dashboard_template_name = '38082'
  select @TypeId = dashboard_parameter_type_id from dashboard_parameter_types where dashboard_parameter_type_desc = '38180'
  select @ParmId = dashboard_template_parameter_id from dashboard_template_parameters where dashboard_parameter_type_id = @TypeId and dashboard_template_id = @Tempid2
  delete from dashboard_parameter_values where dashboard_template_parameter_id = @ParmId
  delete from dashboard_parameter_default_values where dashboard_template_parameter_id = @ParmId
  update dashboard_templates set dashboard_template_name = '38481' where dashboard_template_name = '38082'
end
--alarm list by units
select @Tempid1 = dashboard_template_id from dashboard_templates where dashboard_template_name = '38036'
if (not @Tempid1 is null)
begin
select @ParmId = dashboard_template_parameter_id from dashboard_Template_parameters a, dashboard_parameter_types b where a.dashboard_template_id = @Tempid1 
and a.dashboard_parameter_type_id = b.dashboard_parameter_type_id and b.dashboard_parameter_type_desc = '38180'
delete from dashboard_parameter_default_values where dashboard_template_parameter_id = @ParmId
end
--alarm list by variables
select @Tempid1 = dashboard_template_id from dashboard_templates where dashboard_template_name = '38037'
if (not @Tempid1 is null)
begin
select @ParmId = dashboard_template_parameter_id from dashboard_Template_parameters a, dashboard_parameter_types b where a.dashboard_template_id = @Tempid1 
and a.dashboard_parameter_type_id = b.dashboard_parameter_type_id and b.dashboard_parameter_type_desc = '38180'
delete from dashboard_parameter_default_values where dashboard_template_parameter_id = @ParmId
end
--production event status list by units
select @Tempid1 = dashboard_template_id from dashboard_templates where dashboard_template_name = '38094'
if (not @Tempid1 is null)
begin
select @ParmId = dashboard_template_parameter_id from dashboard_Template_parameters a, dashboard_parameter_types b where a.dashboard_template_id = @Tempid1 
and a.dashboard_parameter_type_id = b.dashboard_parameter_type_id and b.dashboard_parameter_type_desc = '38180'
delete from dashboard_parameter_default_values where dashboard_template_parameter_id = @ParmId
end
 	 declare @hDoc int
 	 Exec sp_xml_preparedocument @hDoc OUTPUT, @xml
 	  	 insert into #Dashboard_Parameter_Data_Types select * from OpenXML(@hDoc, N'/Root/_x0023_Dashboard_Parameter_Data_Types')with #Dashboard_Parameter_Data_Types
 	  	 insert into #Dashboard_Parameter_Types select * from OpenXML(@hDoc, N'/Root/_x0023_Dashboard_Parameter_Types')with #Dashboard_Parameter_Types
 	  	 insert into #Dashboard_DataTable_Presentation_Parameters select * from OpenXML(@hDoc, N'/Root/_x0023_Dashboard_Datatable_Presentation_Parameters')with #Dashboard_DataTable_Presentation_Parameters
 	  	 insert into #Dashboard_DataTable_Headers select * from OpenXML(@hDoc, N'/Root/_x0023_Dashboard_Datatable_Headers')with #Dashboard_DataTable_Headers
 	  	 
 	  	 insert into #Dashboard_Dialogue_Parameters select * from OpenXML(@hDoc, N'/Root/_x0023_Dashboard_Dialogue_Parameters')with #Dashboard_Dialogue_Parameters
 	  	 insert into #dashboard_template_parameters select * from OpenXML(@hDoc, N'/Root/_x0023_Dashboard_Template_Parameters')with #dashboard_template_parameters
 	  	 insert into #Dashboard_Dialogues select * from OpenXML(@hDoc, N'/Root/_x0023_Dashboard_Dialogues')with #Dashboard_Dialogues
 	  	 insert into #dashboard_template_dialogue_parameters select * from OpenXML(@hDoc, N'/Root/_x0023_Dashboard_Template_Dialogue_Parameters')with #dashboard_template_dialogue_parameters
 	  	 insert into #dashboard_templates select * from OpenXML(@hDoc, N'/Root/_x0023_Dashboard_Templates')with #dashboard_templates
 	  	 insert into #dashboard_parameter_default_values select * from OpenXML(@hDoc, N'/Root/_x0023_Dashboard_Parameter_Default_Values')with #dashboard_parameter_default_values
 	  	 insert into #dashboard_parameter_values select * from OpenXML(@hDoc, N'/Root/_x0023_Dashboard_Parameter_Values')with #dashboard_parameter_values
 	  	 insert into #dashboard_template_links select * from OpenXML(@hDoc, N'/Root/_x0023_Dashboard_Template_Links')with #dashboard_template_links
 	  	 insert into #dashboard_reports select * from OpenXML(@hDoc, N'/Root/_x0023_Dashboard_Reports')with #dashboard_reports
 	  	 insert into #dashboard_report_links select * from OpenXML(@hDoc, N'/Root/_x0023_Dashboard_Report_Links')with #dashboard_report_links
 	  	 insert into #dashboard_schedule select * from OpenXML(@hDoc, N'/Root/_x0023_Dashboard_Schedule')with #dashboard_schedule
 	  	 insert into #dashboard_schedule_events select * from OpenXML(@hDoc, N'/Root/_x0023_Dashboard_Schedule_Events')with #dashboard_schedule_events
 	  	 insert into #dashboard_schedule_frequency select * from OpenXML(@hDoc, N'/Root/_x0023_Dashboard_Schedule_Frequency')with #dashboard_schedule_frequency
 	  	 insert into #dashboard_calendar select * from OpenXML(@hDoc, N'/Root/_x0023_Dashboard_Calendar')with #dashboard_calendar
 	  	 insert into #dashboard_custom_dates select * from OpenXML(@hDoc, N'/Root/_x0023_Dashboard_Custom_Dates')with #dashboard_custom_dates
 	  	 insert into #dashboard_day_of_week select * from OpenXML(@hDoc, N'/Root/_x0023_Dashboard_Day_Of_Week')with #dashboard_day_of_week
 	 exec sp_xml_removedocument @hdoc
 	 set nocount on
update #dashboard_datatable_headers set processed = 0
update #dashboard_datatable_presentation_parameters set processed = 0
update #dashboard_datatable_presentation_parameters set processed_input = 0
update #Dashboard_Parameter_Types set processed = 0
update #Dashboard_Dialogue_Parameters set processed = 0
update #Dashboard_Template_Parameters set processed = 0
update #Dashboard_Parameter_Default_Values set processed = 0
update #Dashboard_Parameter_Default_Values set updatevalue = 0
update #Dashboard_Parameter_Values set processed = 0
update #Dashboard_Parameter_Values set updatevalue = 0
update #Dashboard_Template_Dialogue_Parameters set processed = 0
update #Dashboard_Template_Links set processed_a = 0
update #Dashboard_Template_Links set processed_b = 0
update #Dashboard_Report_Links set processed_template = 0
update #Dashboard_Report_Links set processed_a = 0
update #Dashboard_Report_Links set processed_b = 0
update #Dashboard_Reports set processed = 0
update #Dashboard_Schedule set processed = 0
update #Dashboard_Calendar set processed = 0
update #dashboard_schedule_events set processed = 0
update #dashboard_schedule_frequency set processed = 0
update #dashboard_custom_dates set processed = 0
update #dashboard_day_of_week set processed = 0
update #dashboard_schedule_events set pu_id = pu.pu_id from prod_units pu, #dashboard_schedule_events se where pu.pu_desc = se.pu_desc 	  	 
update #dashboard_schedule_events set var_id = v.var_id from variables v, #dashboard_schedule_events se where v.var_desc = se.var_desc 	  	 
/*
good stuff
*************8
select * from #dashboard_datatable_headers
select * from #dashboard_day_of_week
select * from #dashboard_custom_dates
select * from #dashboard_calendar
select * from #dashboard_schedule_frequency
select * from #dashboard_schedule_events
select * from #dashboard_schedule
select * from #dashboard_report_links
select * from #dashboard_reports
select * from #dashboard_template_links
select * from #dashboard_parameter_values
select * from #dashboard_parameter_default_values
select * from #dashboard_templates
select * from #dashboard_template_dialogue_parameters
select * from #dashboard_dialogues
select * from #dashboard_template_parameters
select * from #dashboard_dialogue_parameters
select * from #dashboard_datatable_presentation_parameters
select * from #dashboard_parameter_types
select * from #dashboard_parameter_data_types
*****************
*/
/********
Populate Dashboard_Parameter_Data_Types Table, and update #Dashboard_Parameter_Type foreign keys to be correct
********/
 	 declare @@old_pdt_id int, @@new_pdt_id int, @@pdt_type varchar(100), @@pdt_count int
 	 Declare PDT_Cursor INSENSITIVE CURSOR
   	  	 For Select dashboard_parameter_data_type_id from #dashboard_parameter_data_types order by dashboard_parameter_data_type_id
   	  	 For Read Only
   	 Open PDT_Cursor  
 	 PDT_Loop:
 	  	 Fetch Next From PDT_Cursor Into @@old_pdt_id
 	  	 If (@@Fetch_Status = 0)
 	  	 Begin
 	  	  	 set @@pdt_type = (select dashboard_parameter_data_type from #dashboard_parameter_data_Types where dashboard_parameter_data_Type_id = @@old_pdt_id)
 	  	  	 set @@pdt_count = (select count (dashboard_parameter_data_Type_id) from dashboard_parameter_data_types where dashboard_parameter_data_type = @@pdt_type)
 	  	  	 if (@@pdt_count = 0)
 	  	  	 begin
 	  	  	  	 insert into dashboard_parameter_data_Types (dashboard_parameter_data_type) values(@@pdt_type)
 	  	  	  	 set @@new_pdt_id = (select scope_identity())
 	  	  	  	 update #dashboard_parameter_types set dashboard_parameter_data_type_id = @@new_pdt_id, Processed = 1 where dashboard_parameter_data_type_id = @@old_pdt_id and not Processed = 1
 	  	  	 end 
 	  	  	 else
 	  	  	 begin
 	  	  	  	 set @@new_pdt_id = (select min(dashboard_parameter_data_type_id) from dashboard_parameter_data_types where dashboard_parameter_data_type = @@pdt_type)
 	  	  	  	 update #dashboard_parameter_types set dashboard_parameter_data_type_id = @@new_pdt_id, Processed = 1 where dashboard_parameter_data_type_id = @@old_pdt_id and not Processed = 1
 	  	  	 end
 	  	  	 Goto PDT_Loop
 	  	 End
 	 Close PDT_Cursor 
 	 Deallocate PDT_Cursor
 	 update #dashboard_parameter_types set Processed = 0
 	 drop table #dashboard_parameter_data_types
/****************
Populate Dashboard_Parameter_Types table and update #Dashboard_Datatable_Headers, #Dashboard_Dialogue_Parameters, and #Dashboard_Template_Parameters so that foreign keys are correct
******************/
 	 declare @@old_pt_id int, @@new_pt_id int,@@raw_pt_desc varchar(100), @@pt_desc varchar(100), @@pt_pdt_id int, @@pt_locked bit, @@pt_version int, @@pt_value_type int, @@pt_count int
 	 Declare PT_Cursor INSENSITIVE CURSOR
 	  	 For Select dashboard_parameter_type_id from #dashboard_parameter_types order by dashboard_parameter_type_id
 	  	 For Read Only
 	 Open PT_Cursor  
 	 PT_Loop:
 	    	 Fetch Next From PT_Cursor Into @@old_pt_id
 	  	 If (@@Fetch_Status = 0)
 	  	 Begin
 	  	  	 set @@pt_desc = (select dashboard_parameter_Type_desc from #dashboard_parameter_types where dashboard_parameter_type_id = @@old_pt_id)
 	  	  	 set @@pt_pdt_id = (select dashboard_parameter_data_type_id from #dashboard_parameter_types where dashboard_parameter_type_id = @@old_pt_id)
 	  	  	 set @@pt_locked = (select locked from #dashboard_parameter_types where dashboard_parameter_type_id = @@old_pt_id)
 	  	  	 set @@pt_version = (select version from #dashboard_parameter_types where dashboard_parameter_type_id = @@old_pt_id)
 	  	  	 set @@pt_value_type = (select value_type from #dashboard_parameter_types where dashboard_parameter_type_id = @@old_pt_id)
 	  	  	 if (isnumeric(@@pt_desc) = 1)
 	  	  	  begin
  	  	  	   set @@raw_pt_desc = dbo.fnDBTranslate(N'0', @@pt_desc, @@pt_desc)
 	  	  	  end
 	  	  	 else
 	  	  	  begin
 	  	  	   set @@raw_pt_desc = @@pt_desc
 	  	  	  end
 	  	  	 set @@pt_count = (select count (dashboard_parameter_type_id) from dashboard_parameter_types 
 	  	  	  where case when isnumeric(dashboard_parameter_type_desc) = 1 then  dbo.fnDBTranslate(N'0', dashboard_parameter_type_desc, dashboard_parameter_type_desc) 
 	  	  	   else dashboard_parameter_type_desc end = @@raw_pt_desc  and version = @@pt_version)
 	  	  	 if (@@pt_count = 0)
 	  	  	 begin
 	  	  	  	 insert into dashboard_parameter_types (dashboard_parameter_type_Desc, dashboard_parameter_data_type_id, value_type, locked, version) values(@@pt_desc, @@pt_pdt_id, @@pt_value_type, @@pt_locked, @@pt_version)
 	  	  	  	 set @@new_pt_id = (select scope_identity())
 	  	  	  	 update #dashboard_dialogue_parameters set dashboard_parameter_type_id = @@new_pt_id, processed = 1 where dashboard_parameter_type_id = @@old_pt_id and not processed = 1
 	  	  	  	 update #dashboard_datatable_headers set dashboard_parameter_type_id = @@new_pt_id, processed = 1 where dashboard_parameter_type_id = @@old_pt_id and not processed = 1
 	  	  	  	 update #dashboard_template_parameters set dashboard_parameter_type_id = @@new_pt_id, processed =1  where dashboard_parameter_type_id = @@old_pt_id and not processed = 1
 	  	  	 end 
 	  	  	 else
 	  	  	 begin
 	  	  	  	 set @@new_pt_id = (select min(dashboard_parameter_type_id) from dashboard_parameter_types where case when isnumeric(dashboard_parameter_type_desc) = 1 then  dbo.fnDBTranslate(N'0', dashboard_parameter_type_desc, dashboard_parameter_type_desc) else dashboard_parameter_type_desc end = @@raw_pt_desc and version = @@pt_version)
 	  	  	  	 update dashboard_parameter_types set dashboard_parameter_type_desc = @@pt_desc, dashboard_parameter_data_type_id = @@pt_pdt_id, value_type = @@pt_value_type 
 	  	  	  	  	 where case when isnumeric(dashboard_parameter_type_desc) = 1 then  dbo.fnDBTranslate(N'0', dashboard_parameter_type_desc, dashboard_parameter_type_desc) else dashboard_parameter_type_desc end = @@raw_pt_desc and version = @@pt_version
 	  	  	  	 update #dashboard_dialogue_parameters set dashboard_parameter_type_id = @@new_pt_id, processed = 1 where dashboard_parameter_type_id = @@old_pt_id and not processed = 1
 	  	  	  	 update #dashboard_datatable_headers set dashboard_parameter_type_id = @@new_pt_id, processed = 1 where dashboard_parameter_type_id = @@old_pt_id and not processed = 1
 	  	  	  	 update #dashboard_template_parameters set dashboard_parameter_type_id = @@new_pt_id, processed = 1 where dashboard_parameter_type_id = @@old_pt_id and not processed = 1
 	  	  	 end
 	  	  	 Goto PT_Loop
 	  	 End
 	 Close PT_Cursor 
 	 Deallocate PT_Cursor
 	 drop table #dashboard_parameter_types
 	 update #dashboard_dialogue_parameters set Processed = 0
 	 update #dashboard_datatable_headers set processed = 0
 	 update #dashboard_template_parameters set processed = 0
/***************8
Populate Dashboard_DataTable_Headers table, update #Dashboard_DataTable_Presentation_Parameter foreign keys
**************/
 	 declare @@old_ddh_id int, @@new_ddh_id int, @@ddh_pt_id int, @@ddh_column int, @@ddh_header varchar(50), @@ddh_presentation int, @@ddh_sp varchar(100), @@ddh_count int
 	 
 	 Declare DDH_Cursor INSENSITIVE CURSOR
 	  	 For Select dashboard_datatable_header_id from #dashboard_datatable_headers order by dashboard_datatable_header_id
 	  	 For Read Only
 	 Open DDH_Cursor  
 	 DDH_Loop:
 	  	 Fetch Next From DDH_Cursor Into @@old_ddh_id
 	  	 If (@@Fetch_Status = 0)
 	  	 Begin
 	  	  	 set @@ddh_pt_id = (select dashboard_parameter_Type_id from #dashboard_datatable_headers where dashboard_datatable_header_id = @@old_ddh_id)
 	  	  	 set @@ddh_column = (select dashboard_datatable_column from #dashboard_datatable_headers where dashboard_datatable_header_id = @@old_ddh_id)
 	  	  	 set @@ddh_header = (select dashboard_datatable_header from #dashboard_datatable_headers where dashboard_datatable_header_id = @@old_ddh_id)
 	  	  	 set @@ddh_presentation = (select dashboard_datatable_presentation from #dashboard_datatable_headers where dashboard_datatable_header_id = @@old_ddh_id)
 	  	  	 set @@ddh_sp = (select dashboard_datatable_column_sp from #dashboard_datatable_headers where dashboard_datatable_header_id = @@old_ddh_id)
 	  	  	 
 	  	  	 set @@ddh_count = (select count (dashboard_datatable_header_id) from dashboard_datatable_headers where dashboard_parameter_type_id = @@ddh_pt_id and dashboarD_datatable_column = @@ddh_column)
 	  	  	 if (@@ddh_count = 0)
 	  	  	 begin
 	  	  	  	 insert into dashboard_datatable_headers (dashboard_parameter_type_id, dashboard_datatable_column, dashboard_datatable_header, dashboard_datatable_presentation, dashboard_datatable_column_sp) values(@@ddh_pt_id, @@ddh_column, @@ddh_header, @@ddh_presentation, @@ddh_sp)
 	  	  	  	 set @@new_ddh_id = (select scope_identity())
 	  	  	  	 update #dashboard_datatable_presentation_parameters set dashboard_datatable_header_id = @@new_ddh_id, processed = 1 where dashboard_datatable_header_id = @@old_ddh_id and processed = 0 	  	 
 	  	  	  	 update #dashboard_datatable_presentation_parameters set dashboard_datatable_presentation_parameter_input = @@new_ddh_id, processed_input = 1 where dashboard_datatable_presentation_parameter_input = @@old_ddh_id and processed_input = 0 	  	 
 	  	  	  	 update #dashboard_parameter_default_values  set #dashboard_parameter_default_values.updatevalue = 1 from dashboard_parameter_types dpt, #dashboard_template_parameters dtp where #dashboard_parameter_default_values.dashboard_template_parameter_id = dtp.dashboard_template_parameter_id and dtp.dashboard_parameter_type_id = dpt.dashboard_parameter_type_id and dpt.dashboard_parameter_type_id = @@ddh_pt_id and Dashboard_Parameter_Column = @@ddh_column
 	  	  	  	 update #dashboard_parameter_values  set #dashboard_parameter_values.updatevalue = 1 from dashboard_parameter_types dpt, #dashboard_template_parameters dtp where #dashboard_parameter_values.dashboard_template_parameter_id = dtp.dashboard_template_parameter_id and dtp.dashboard_parameter_type_id = dpt.dashboard_parameter_type_id and dpt.dashboard_parameter_type_id = @@ddh_pt_id and Dashboard_Parameter_Column = @@ddh_column
 	  	  	 end 
 	  	  	 else
 	  	  	 begin
 	  	  	  	 set @@new_ddh_id = (select min(dashboard_datatable_header_id) from dashboard_datatable_headers where dashboard_parameter_type_id = @@ddh_pt_id and dashboarD_datatable_column = @@ddh_column)
 	  	  	  	 
 	  	  	  	 declare @@old_header varchar(50), @@old_presentation bit, @@old_datatable_column_sp varchar(50)
 	  	  	  	 set @@old_header = (select dashboard_datatable_header from dashboard_datatable_headers where dashboard_datatable_header_id = @@new_ddh_id)
 	  	  	  	 set @@old_presentation = (select dashboard_datatable_presentation from dashboard_datatable_headers where dashboard_datatable_header_id = @@new_ddh_id)
 	  	  	  	 set @@old_datatable_column_sp = (select dashboard_datatable_column_sp from dashboard_datatable_headers where dashboard_datatable_header_id = @@new_ddh_id)
 	  	  	  	 
 	  	  	  	 update dashboard_datatable_headers set dashboard_datatable_header = @@ddh_header, dashboard_datatable_presentation = @@ddh_presentation, dashboard_datatable_column_sp = @@ddh_sp where dashboard_parameter_type_id = @@ddh_pt_id and dashboarD_datatable_column = @@ddh_column
 	  	  	  	 update #dashboard_datatable_presentation_parameters set dashboard_datatable_header_id = @@new_ddh_id, processed = 1 where dashboard_datatable_header_id = @@old_ddh_id and processed = 0 	  	 
 	  	  	  	 update #dashboard_datatable_presentation_parameters set dashboard_datatable_presentation_parameter_input = @@new_ddh_id, processed_input = 1 where dashboard_datatable_presentation_parameter_input = @@old_ddh_id and processed_input = 0 	  	 
 	  	  	  	 
declare @@old_lang_header varchar(50), @@ddh_lang_header varchar(50)
if (isnumeric(@@old_header) = 1)
 begin
  select @@old_lang_header = dbo.fnDBTranslate(N'0', @@old_header, @@old_header)
 end
else
 begin
  select @@old_lang_header = @@old_header
 end
if (isnumeric(@@ddh_header) = 1)
 begin
  select @@ddh_lang_header = dbo.fnDBTranslate(N'0', @@ddh_header, @@ddh_header)
 end
else
 begin
  select @@ddh_lang_header = @@ddh_header
 end
 	  	  	  	 if ((not @@old_lang_header = @@ddh_lang_header) or (not @@old_presentation = @@ddh_presentation) or (not @@old_datatable_column_sp = @@ddh_sp))
 	  	  	  	 begin
 	  	  	  	  	 update #dashboard_parameter_default_values set #dashboard_parameter_default_values.updatevalue = 1 from dashboard_parameter_types dpt, #dashboard_template_parameters dtp where #dashboard_parameter_default_values.dashboard_template_parameter_id = dtp.dashboard_template_parameter_id and dtp.dashboard_parameter_type_id = dpt.dashboard_parameter_type_id and dpt.dashboard_parameter_type_id = @@ddh_pt_id and Dashboard_Parameter_Column = @@ddh_column
 	  	  	  	  	 update #dashboard_parameter_values set #dashboard_parameter_values.updatevalue = 1 from dashboard_parameter_types dpt, #dashboard_template_parameters dtp where #dashboard_parameter_values.dashboard_template_parameter_id = dtp.dashboard_template_parameter_id and dtp.dashboard_parameter_type_id = dpt.dashboard_parameter_type_id and dpt.dashboard_parameter_type_id = @@ddh_pt_id and Dashboard_Parameter_Column = @@ddh_column
 	  	  	  	 end 	 
 	  	  	 end
 	  	  	 Goto DDH_Loop
 	  	 End
 	 Close DDH_Cursor 
 	 Deallocate DDH_Cursor
 	 drop table #dashboard_datatable_headers
 	 update #dashboard_datatable_presentation_parameters set processed = 0
 	 update #dashboard_datatable_presentation_parameters set processed_input = 0
/*****************
Populate Dashboard_Datatable_Presentation_Parameters
****************/
 	 declare @@old_ddpp_id int, @@new_ddpp_id int, @@ddpp_ddh_id int, @@ddpp_order int, @@ddpp_input int, @@ddpp_count int
 	 
 	 Declare DDPP_Cursor INSENSITIVE CURSOR
 	  	 For Select dashboard_datatable_presentation_parameter_id from #dashboard_datatable_presentation_parameters order by dashboard_datatable_presentation_parameter_id
 	  	 For Read Only
 	 Open DDPP_Cursor  
 	 DDPP_Loop:
 	  	 Fetch Next From DDPP_Cursor Into @@old_ddpp_id
 	  	 If (@@Fetch_Status = 0)
 	  	 Begin
 	  	  	 set @@ddpp_ddh_id = (select dashboard_datatable_header_id from #dashboard_datatable_presentation_parameters where dashboard_datatable_presentation_parameter_id = @@old_ddpp_id)
 	  	  	 set @@ddpp_order = (select dashboard_datatable_presentation_parameter_order from #dashboard_datatable_presentation_parameters where dashboard_datatable_presentation_parameter_id = @@old_ddpp_id)
 	  	  	 set @@ddpp_input = (select dashboard_datatable_presentation_parameter_input from #dashboard_datatable_presentation_parameters where dashboard_datatable_presentation_parameter_id = @@old_ddpp_id)
 	  	  	 set @@ddpp_count = (select count(dashboard_datatable_presentation_parameter_id) from dashboard_datatable_presentation_parameters where dashboard_datatable_header_id = @@ddpp_ddh_id and dashboard_datatable_presentation_parameter_order = @@ddpp_order)
 	  	  	 
 	  	  	 if (@@ddpp_count = 0)
 	  	  	 begin
 	  	  	  	 insert into dashboard_datatable_presentation_parameters (dashboard_datatable_header_id, dashboard_datatable_presentation_parameter_order, dashboard_datatable_presentation_parameter_input) values(@@ddpp_ddh_id, @@ddpp_order, @@ddpp_input)
 	  	  	 end 
 	  	  	 else
 	  	  	 begin
 	  	  	  	 update dashboard_datatable_presentation_parameters set dashboard_datatable_presentation_parameter_order = @@ddpp_order, dashboard_datatable_presentation_parameter_input = @@ddpp_input where dashboard_datatable_header_id = @@ddpp_ddh_id and dashboard_datatable_presentation_parameter_order = @@ddpp_order
 	  	  	 end
 	  	  	 Goto DDPP_Loop
 	  	 End
 	 Close DDPP_Cursor 
 	 Deallocate DDPP_Cursor
 	 
 	 drop table #dashboard_datatable_presentation_parameters
/*****************
Populate Dashboard_Dialogue table and update #Dashboard_Dialouge_Parameters and #Dashboard_Template_Dialogue_Parameters foreign keys
*****************/
 	 declare @@old_dd_id int, @@new_dd_id int, @@text_dd_name varchar(100), @@dd_name varchar(100), @@dd_url varchar(1000), @@dd_external int, @@dd_param_Count int, @@dd_locked bit, @@dd_version int, @@dd_count int
 	 
 	 Declare DD_Cursor INSENSITIVE CURSOR
 	  	 For Select dashboard_dialogue_id from #dashboard_dialogues order by dashboard_dialogue_id
 	  	 For Read Only
 	 Open DD_Cursor  
 	 DD_Loop:
 	  	 Fetch Next From DD_Cursor Into @@old_dd_id
 	  	 If (@@Fetch_Status = 0)
 	  	 Begin
 	  	  	 set @@dd_name = (select dashboard_dialogue_name from #dashboard_dialogues where dashboard_dialogue_id = @@old_dd_id)
 	  	  	 set @@dd_url = (select url from #dashboard_dialogues where dashboard_dialogue_id = @@old_dd_id)
 	  	  	 set @@dd_external = (select external_address from #dashboard_dialogues where dashboard_dialogue_id = @@old_dd_id)
 	  	  	 set @@dd_param_count = (select parameter_count from #dashboard_dialogues where dashboard_dialogue_id = @@old_dd_id)
 	  	  	 set @@dd_locked = (select locked from #dashboard_dialogues where dashboard_dialogue_id = @@old_dd_id)
 	  	  	 set @@dd_version = (select version from #dashboard_dialogues where dashboard_dialogue_id = @@old_dd_id)
 	  	  	 if (isnumeric(@@dd_name) = 1)
 	  	  	  begin
  	  	  	   set @@text_dd_name = dbo.fnDBTranslate(N'0', @@dd_name, @@dd_name)
 	  	  	  end
 	  	  	 else
 	  	  	  begin
 	  	  	   set @@text_dd_name = @@dd_name
 	  	  	  end
 	  	  	 set @@dd_count = (select count (dashboard_dialogue_id) from dashboard_dialogues where case when isnumeric(dashboard_dialogue_name) = 1 then dbo.fnDBTranslate(N'0', dashboard_dialogue_name, dashboard_dialogue_name) else dashboard_dialogue_name end like @@text_dd_name and version = @@dd_version)
 	  	  	 if (@@dd_count = 0)
 	  	  	 begin
 	  	  	  	 insert into dashboard_dialogues (dashboard_dialogue_name, external_address, url,parameter_count,locked, version) values(@@dd_name, @@dd_external, @@dd_url, @@dd_param_count, @@dd_locked, @@dd_version)
 	  	  	  	 set @@new_dd_id = (select scope_identity())
 	  	  	  	 update #dashboard_dialogue_parameters set dashboard_dialogue_id = @@new_dd_id, Processed = 1 where dashboard_dialogue_id = @@old_dd_id and not Processed = 1
 	  	  	  	 update #dashboard_template_dialogue_parameters set dashboard_dialogue_id = @@new_dd_id, Processed = 1 where dashboard_dialogue_id = @@old_dd_id and not processed = 1
 	  	  	 end 
 	  	  	 else
 	  	  	 begin
 	  	  	  	 set @@new_dd_id = (select min(dashboard_dialogue_id) from dashboard_dialogues where case when isnumeric(dashboard_dialogue_name) = 1 then dbo.fnDBTranslate(N'0', dashboard_dialogue_name, dashboard_dialogue_name) else dashboard_dialogue_name end = @@text_dd_name and version = @@dd_version)
 	  	  	  	 update dashboard_dialogues set dashboard_dialogue_name = @@dd_name, external_address = @@dd_external, url = @@dd_url, parameter_count = @@dd_param_count where case when isnumeric(dashboard_dialogue_name) = 1 then dbo.fnDBTranslate(N'0', dashboard_dialogue_name, dashboard_dialogue_name) else dashboard_dialogue_name end = @@text_dd_name and version = @@dd_version
 	  	  	  	 update #dashboard_dialogue_parameters set dashboard_dialogue_id = @@new_dd_id, processed = 1 where dashboard_dialogue_id = @@old_dd_id and not processed = 1
 	  	  	  	 update #dashboard_template_dialogue_parameters set dashboard_dialogue_id = @@new_dd_id, processed = 1 where dashboard_dialogue_id = @@old_dd_id and not processed = 1
 	  	  	 end
 	  	  	 Goto DD_Loop
 	  	 End
 	 Close DD_Cursor 
 	 Deallocate DD_Cursor
 	 drop table #dashboard_dialogues
 	 update #dashboard_dialogue_parameters set processed = 0
 	 update #dashboard_template_dialogue_parameters set processed = 0
/*********************
Populate Dashboard_Dialogue_Parameter table
**********************/
 	 declare @@old_ddp_id int, @@new_ddp_id int, @@ddp_dd_id int, @@ddp_pt_id int, @@ddp_count int, @@default bit
 	 
 	 Declare DDP_Cursor INSENSITIVE CURSOR
 	  	 For Select dashboard_dialogue_parameter_id from #dashboard_dialogue_parameters order by dashboard_dialogue_parameter_id
 	  	 For Read Only
 	 Open DDP_Cursor  
 	 DDP_Loop:
 	  	 Fetch Next From DDP_Cursor Into @@old_ddp_id
 	  	 If (@@Fetch_Status = 0)
 	  	 Begin
 	  	  	 set @@ddp_dd_id = (select dashboard_dialogue_id from #dashboard_dialogue_parameters where dashboard_dialogue_parameter_id = @@old_ddp_id)
 	  	  	 set @@ddp_pt_id = (select dashboard_parameter_type_id from #dashboard_dialogue_Parameters where dashboard_dialogue_parameter_id = @@old_ddp_id)
 	  	  	 set @@default = (select default_Dialogue from #dashboard_dialogue_Parameters where dashboard_dialogue_parameter_id = @@old_ddp_id)
 	  	  	 set @@ddp_count = (select count (dashboard_dialogue_parameter_id) from dashboard_dialogue_parameters where dashboard_dialogue_id = @@ddp_dd_id and dashboard_parameter_type_id = @@ddp_pt_id)
 	  	  	 if (@@ddp_count = 0)
 	  	  	 begin
 	  	  	  	 insert into dashboard_dialogue_parameters (dashboard_dialogue_id, dashboard_parameter_type_id) values(@@ddp_dd_id, @@ddp_pt_id)
 	  	  	 end 
 	  	  	 Goto DDP_Loop
 	  	 End
 	 Close DDP_Cursor 
 	 Deallocate DDP_Cursor
 	 
 	 drop table #dashboard_dialogue_parameters
/************************
Populate Dashboard_Templates update #dashboard_template_links, #dashboard_template_parameter, #dashboard_reports foreign keys
************************/
 	 declare
 	  	 @@old_t_id int, @@new_t_id int, @@text_t_name varchar(100), @@t_name varchar(100), @@t_xsl_filename varchar(100), @@t_preview_filename varchar(100), @@t_build int, @@t_locked int,
 	  	 @@t_launch_type int, @@t_procedure varchar(100), @@t_size_unit int, @@t_description varchar(400), @@t_fixed_height int,@@t_fixed_width int, @@t_column int, 
 	  	 @@t_column_position int,
 	  	 @@t_has_frame int, @@t_expanded int, @@t_allow_remove int, @@t_allow_minimize int, @@t_cache_code int, @@t_cache_timeout int,
 	  	 @@t_detail_link varchar(500), @@t_help_link varchar(500),@@version_number int, @@t_count int, @@height int, @@width int,
 	  	 @@type int, @@base bit
 	 
 	 Declare T_Cursor INSENSITIVE CURSOR
 	  	 For Select dashboard_template_id from #dashboard_templates order by dashboard_template_id
 	  	 For Read Only
 	 Open T_Cursor  
 	 T_Loop:
 	  	 Fetch Next From T_Cursor Into @@old_t_id
 	  	 If (@@Fetch_Status = 0)
 	  	 Begin
 	  	  	 set @@t_name = (select dashboard_template_name from #dashboard_templates where dashboard_template_id = @@old_t_id)
 	  	  	 set @@t_xsl_filename = (select dashboard_template_xsl_filename from #dashboard_templates where dashboard_template_id = @@old_t_id)
 	  	  	 set @@t_preview_filename = (select dashboard_template_preview_filename from #dashboard_templates where dashboard_template_id = @@old_t_id)
 	  	  	 set @@t_build = (select dashboard_template_build from #dashboard_templates where dashboard_template_id = @@old_t_id)
 	  	  	 set @@t_locked = (select dashboard_template_locked from #dashboard_templates where dashboard_template_id = @@old_t_id)
 	  	  	 set @@t_launch_type = (select dashboard_template_launch_type from #dashboard_templates where dashboard_template_id = @@old_t_id)
 	  	  	 set @@t_procedure = (select dashboard_template_procedure from #dashboard_templates where dashboard_template_id = @@old_t_id)
 	  	  	 set @@t_size_unit = (select dashboard_template_size_unit from #dashboard_templates where dashboard_template_id = @@old_t_id)
 	  	  	 set @@t_description = (select dashboard_template_description from #dashboard_templates where dashboard_template_id = @@old_t_id)
 	  	  	 set @@t_fixed_height = (select dashboard_template_fixed_height from #dashboard_templates where dashboard_template_id = @@old_t_id)
 	  	  	 set @@t_fixed_width = (select dashboard_template_fixed_width from #dashboard_templates where dashboard_template_id = @@old_t_id)
 	  	  	 set @@t_column = (select dashboard_template_column from #dashboard_templates where dashboard_template_id = @@old_t_id)
 	  	  	 set @@t_column_position = (select dashboard_template_column_position from #dashboard_templates where dashboard_template_id = @@old_t_id)
 	  	  	 set @@t_has_frame = (select dashboard_template_has_frame from #dashboard_templates where dashboard_template_id = @@old_t_id)
 	  	  	 set @@t_expanded = (select dashboard_template_expanded from #dashboard_templates where dashboard_template_id = @@old_t_id)
 	  	  	 set @@t_allow_remove = (select dashboard_template_allow_remove from #dashboard_templates where dashboard_template_id = @@old_t_id)
 	  	  	 set @@t_allow_minimize = (select dashboard_template_allow_minimize from #dashboard_templates where dashboard_template_id = @@old_t_id)
 	  	  	 set @@t_cache_code = (select dashboard_template_cache_code from #dashboard_templates where dashboard_template_id = @@old_t_id)
 	  	  	 set @@t_cache_timeout = (select dashboard_template_cache_timeout from #dashboard_templates where dashboard_template_id = @@old_t_id)
 	  	  	 set @@t_detail_link = (select dashboard_template_detail_link from #dashboard_templates where dashboard_template_id = @@old_t_id)
 	  	  	 set @@t_help_link = (select dashboard_template_help_link from #dashboard_templates where dashboard_template_id = @@old_t_id)
 	  	  	 set @@version_number = (select version from #dashboard_templates where dashboard_template_id = @@old_t_id)
 	  	  	 set @@height = (select height from #dashboard_templates where dashboard_template_id = @@old_t_id)
 	  	  	 set @@width = (select width from #dashboard_templates where dashboard_template_id = @@old_t_id)
 	  	  	 set @@type = (select type from #dashboard_templates where dashboard_template_id = @@old_t_id)
 	  	  	 set @@base = (select basetemplate from #dashboard_templates where dashboard_template_id = @@old_t_id)
 	  	  	 
 	  	  	 if (isnumeric(@@t_name) = 1)
 	  	  	  begin
  	  	  	   set @@text_t_name = dbo.fnDBTranslate(N'0', @@t_name, @@t_name)
 	  	  	  end
 	  	  	 else
 	  	  	  begin
 	  	  	   set @@text_t_name = @@t_name
 	  	  	  end
 	  	  	 set @@t_count = (select count(dashboard_template_id) from dashboard_templates where case when isnumeric(dashboard_template_name) = 1 then dbo.fnDBTranslate(N'0', dashboard_template_name, dashboard_template_name) else dashboard_template_name end = @@text_t_name and version = @@version_number)
 	  	  	 
 	  	  	 if (@@t_count = 0)
 	  	  	 begin
 	  	  	  	 insert into dashboard_templates (dashboard_template_name, dashboard_template_xsl, dashboard_template_xsl_filename,dashboard_template_preview,
 	  	  	  	 dashboard_template_preview_filename, 
 	  	  	  	 dashboard_template_build, dashboard_template_locked, dashboard_template_launch_type, dashboard_template_procedure,
 	  	  	  	 dashboard_template_size_unit, dashboard_template_description, dashboard_template_fixed_height, dashboard_template_fixed_width, dashboard_template_column,
 	  	  	  	 dashboard_template_column_position, dashboard_template_has_frame, dashboard_template_expanded, dashboard_template_allow_remove,
 	  	  	  	 dashboard_template_allow_minimize, dashboard_template_cache_code, dashboard_template_cache_timeout, dashboard_template_detail_link,
 	  	  	  	 dashboard_template_help_link,height, width, version, type, basetemplate)
 	  	  	  	 values(@@t_name,'',@@t_xsl_filename, '',@@t_preview_filename, @@t_build, @@t_locked, @@t_launch_type, @@t_procedure, 
 	  	  	  	 @@t_size_unit, @@t_description, @@t_fixed_height,@@t_fixed_width, @@t_column, @@t_column_position, @@t_has_frame, @@t_expanded, @@t_allow_remove,
 	  	  	  	 @@t_allow_minimize, @@t_cache_code, @@t_cache_timeout, @@t_detail_link, @@t_help_link,@@height, @@width,  @@version_number, @@type, @@base)
 	  	  	  	 
 	  	  	  	 set @@new_t_id = (select scope_identity())
 	  	  	  	 update #dashboard_template_parameters set dashboard_template_id = @@new_t_id, processed = 1 where dashboard_template_id = @@old_t_id and processed = 0
 	  	  	  	 update #dashboard_reports set dashboard_template_id = @@new_t_id, processed = 1 where dashboard_template_id = @@old_t_id and processed = 0
 	  	  	  	 update #dashboard_template_links set dashboard_template_link_from = @@new_t_id, processed_a = 1 where dashboard_template_link_from = @@old_t_id and processed_a = 0
 	  	  	  	 update #dashboard_template_links set dashboard_template_link_to = @@new_t_id, processed_b = 1 where dashboard_template_link_to = @@old_t_id and processed_b = 0 	  	  	 
 	  	  	 end 
 	  	  	 else
 	  	  	 begin
 	  	  	  	 set @@new_t_id =(select min(dashboard_template_id) from dashboard_templates where case when isnumeric(dashboard_template_name) = 1 then dbo.fnDBTranslate(N'0', dashboard_template_name, dashboard_template_name) else dashboard_template_name end = @@text_t_name and version = @@version_number) 
 	  	  	  	 
 	  	  	  	 update dashboard_templates set dashboard_template_name = @@t_name, dashboard_template_xsl_filename = @@t_xsl_filename,
 	  	  	  	 dashboard_template_preview_filename = @@t_preview_filename,
 	  	  	  	 dashboard_template_build = @@t_build, dashboard_template_locked=@@t_locked,
 	  	  	  	 dashboard_template_launch_type = @@t_launch_type, dashboard_template_procedure=@@t_procedure,
 	  	  	  	 dashboard_template_size_unit = @@t_size_unit, dashboard_template_description = @@t_description, 
 	  	  	  	 dashboard_template_fixed_height = @@t_fixed_height,dashboard_template_fixed_width = @@t_fixed_width, dashboard_template_column = @@t_column,
 	  	  	  	 dashboard_template_column_position = @@t_column_position, dashboard_template_has_frame = @@t_has_frame, 
 	  	  	  	 dashboard_template_expanded = @@t_expanded, dashboard_template_allow_remove = @@t_allow_remove,
 	  	  	  	 dashboard_template_allow_minimize =@@t_allow_minimize, dashboard_template_cache_code = @@t_cache_code, 
 	  	  	  	 dashboard_template_cache_timeout = @@t_cache_timeout, dashboard_template_detail_link =@@t_detail_link,
 	  	  	  	 dashboard_template_help_link = @@t_help_link,
 	  	  	  	 height = @@height, width = @@width, type = @@type, basetemplate = @@base
 	  	  	  	 where dashboard_template_id = @@new_t_id
 	  	  	  	 
 	  	  	  	 update #dashboard_template_parameters set dashboard_template_id = @@new_t_id, processed = 1 where dashboard_template_id = @@old_t_id and processed = 0
 	  	  	  	 update #dashboard_reports set dashboard_template_id = @@new_t_id, processed = 1 where dashboard_template_id = @@old_t_id and processed = 0
 	  	  	  	 update #dashboard_template_links set dashboard_template_link_from = @@new_t_id, processed_a = 1 where dashboard_template_link_from = @@old_t_id and processed_a = 0
 	  	  	  	 update #dashboard_template_links set dashboard_template_link_to = @@new_t_id, processed_b = 1 where dashboard_template_link_to = @@old_t_id and processed_b = 0 	  	  	       
 	  	  	 end
 	  	  	 Goto T_Loop
 	  	 End 	 
 	 Close T_Cursor 
 	 Deallocate T_Cursor
 	 drop table #dashboard_templates
 	 update #dashboard_template_links set processed_a = 0, processed_b = 0
 	 update #dashboard_reports set processed = 0;
 	 update #dashboard_template_parameters set processed = 0;
/**************************
Populate table Dashboard_Template_Links update Dashboard_Report_Links foreign keys
****************************/
 	 declare @@old_dtl_id int, @@new_dtl_id int, @@dtl_from int, @@dtl_to int, @@dtl_count int
 	 
 	 
 	 Declare DTL_Cursor INSENSITIVE CURSOR
 	  	 For Select dashboard_template_link_id from #dashboard_template_links order by dashboard_template_link_id
 	  	 For Read Only
 	 Open DTL_Cursor  
 	 DTL_Loop:
 	  	 Fetch Next From DTL_Cursor Into @@old_dtl_id
 	  	 If (@@Fetch_Status = 0)
 	  	 Begin
 	  	  	 set @@dtl_from = (select dashboard_template_link_from from #dashboard_template_links where dashboard_template_link_id = @@old_dtl_id)
 	  	  	 set @@dtl_to = (select dashboard_template_link_to from #dashboard_template_links where dashboard_template_link_id = @@old_dtl_id)
 	  	  	 
 	  	  	 set @@dtl_count = (select count(dashboard_template_link_id) from dashboard_template_links where dashboard_template_link_from = @@dtl_from and dashboard_template_link_to = @@dtl_to)
 	  	  	 
 	  	  	 if (@@dtl_count = 0)
 	  	  	 begin
 	  	  	  	 insert into dashboard_template_links (dashboard_template_link_from, dashboard_template_link_to) values(@@dtl_from, @@dtl_to)
 	  	  	  	 set @@new_dtl_id = (select scope_identity())
 	  	  	  	 update #dashboard_report_links set dashboard_template_link_id = @@new_dtl_id, Processed_Template = 1 where dashboard_template_link_id = @@old_dtl_id and not Processed_Template = 1
 	  	  	 end 
 	  	  	 else
 	  	  	 begin
 	  	  	  	 set @@new_dtl_id = (select min(dashboard_template_link_id) from dashboard_template_links where dashboard_template_link_from = @@dtl_from and dashboard_template_link_to = @@dtl_to)
 	  	  	  	 update #dashboard_report_links set dashboard_template_link_id = @@new_dtl_id, Processed_Template = 1 where dashboard_template_link_id = @@old_dtl_id and not Processed_Template = 1 	  	  	 
 	  	  	 end
 	  	  	 Goto DTL_Loop
 	  	 End
 	 Close DTL_Cursor 
 	 Deallocate DTL_Cursor
 	 
 	 drop table #dashboard_template_links
 	 update #dashboard_report_links set processed_template = 0
/**************************
Populate Dashboard_Template_Parameters table update #Dashboard_Template_Dialogue_Parameters, #Dashboard_Parameter_Default_Values, #Dashboard_Parameter_Values foreign keys and update codes
**************************/
 	 declare @@old_dtp_id int, @@new_dtp_id int,@@max_dtp_order int, @@dtp_t_id int, @@dtp_order int, @@dtp_pt_id int,@@text_dtp_name varchar(100), @@dtp_name varchar(100), @@dtp_has_default int, @@dtp_count int, @@dtp_allow_nulls int,
 	  	 @@goneparmid int, @@templateupdated int, @@oldtemplateupdateid int
 	 select @@templateupdated = 0
  select @@oldtemplateupdateid = 0
 	 Declare DTP_Cursor INSENSITIVE CURSOR
 	  	 For Select dashboard_template_parameter_id from #dashboard_template_parameters order by dashboard_template_parameter_id
 	  	 For Read Only
 	 Open DTP_Cursor  
 	 DTP_Loop:
 	  	 Fetch Next From DTP_Cursor Into @@old_dtp_id
 	  	 If (@@Fetch_Status = 0)
 	  	 Begin
 	  	  	 set @@dtp_t_id = (select dashboard_template_id from #dashboard_template_parameters where dashboard_template_parameter_id = @@old_dtp_id)
 	  	  	 if (not @@dtp_t_id = @@oldtemplateupdateid)
 	  	  	 begin
 	  	  	  	 select @@oldtemplateupdateid = @@dtp_t_id
 	  	  	  	 select @@templateupdated = 0
 	  	  	 end
 	  	  	 set @@dtp_order = (select dashboard_template_parameter_order from #dashboard_template_parameters where dashboard_template_parameter_id = @@old_dtp_id)
 	  	  	 set @@max_dtp_order = (select max(dashboard_template_parameter_order) from #dashboard_template_parameters where dashboard_template_parameter_id = @@dtp_t_id)
 	  	  	 
/*************************/
 	  	  	 if (@@templateupdated = 0)
 	  	  	 begin
 	  	  	  	 set @@goneparmid = (select dashboard_template_parameter_id from dashboard_template_parameters where dashboard_template_id = @@dtp_t_id 
 	                            and not case when isnumeric(dashboard_template_parameter_name) = 1 then (dbo.fnDBTranslate(N'0', dashboard_template_parameter_name, dashboard_template_parameter_name)) 
 	                             else (dashboard_template_parameter_name) end in 
 	                              (select case when isnumeric(dashboard_template_parameter_name) = 1 then (dbo.fnDBTranslate(N'0', dashboard_template_parameter_name, dashboard_template_parameter_name)) 
 	                                else (dashboard_template_parameter_name) end from #dashboard_template_parameters where dashboard_template_id = @@dtp_t_id))
 	 
 	  	  	  	 delete from dashboard_template_dialogue_parameters where dashboard_template_parameter_id = @@goneparmid 	  	 
 	  	  	  	 delete from dashboard_parameter_default_values where dashboard_template_parameter_id = @@goneparmid
 	  	  	  	 delete from dashboard_parameter_values where dashboard_template_parameter_id = @@goneparmid
 	  	  	  	 delete from dashboard_template_parameters where dashboard_template_parameter_id = @@goneparmid
 	  	  	  	 select @@templateupdated = 1
 	  	 end
/*************************/
 	  	  	 set @@dtp_pt_id = (select dashboard_parameter_type_id from #dashboard_template_parameters where dashboard_template_parameter_id = @@old_dtp_id)
 	  	  	 set @@dtp_name = (select dashboard_template_parameter_name from #dashboard_template_parameters where dashboard_template_parameter_id = @@old_dtp_id)
 	  	  	 set @@dtp_has_default = (select has_default_value from #dashboard_template_parameters where dashboard_template_parameter_id = @@old_dtp_id)
 	  	  	 set @@dtp_allow_nulls = (select allow_nulls from #dashboard_template_parameters where dashboard_template_parameter_id = @@old_dtp_id)
 	  	  	 if (isnumeric(@@dtp_name) = 1)
 	  	  	  begin
  	  	  	   set @@text_dtp_name = dbo.fnDBTranslate(N'0', @@dtp_name, @@dtp_name)
 	  	  	  end
 	  	  	 else
 	  	  	  begin
 	  	  	   set @@text_dtp_name = @@dtp_name
 	  	  	  end 	  	  	 
 	  	  	 
 	  	  	 set @@dtp_count = (select count(dashboard_template_id) from dashboard_Template_parameters where dashboard_template_id = @@dtp_t_id and case when isnumeric(dashboard_template_parameter_name) = 1 then dbo.fnDBTranslate(N'0', dashboard_template_parameter_name,dashboard_template_parameter_name) else dashboard_template_parameter_name end = @@text_dtp_name)
 	  	  	 
 	  	  	 if (@@dtp_count = 0)
 	  	  	 begin
 	  	  	  	 insert into dashboard_template_parameters (dashboard_template_id, dashboard_template_parameter_order, dashboard_parameter_type_id, dashboard_template_parameter_name, has_default_value, allow_nulls) 
 	  	  	  	 values(@@dtp_t_id, @@dtp_order, @@dtp_pt_id, @@dtp_name, @@dtp_has_default, @@dtp_allow_nulls)
 	  	  	  	 set @@new_dtp_id = (select scope_identity()) 	 
 	  	  	  	 update #dashboard_parameter_default_values set dashboard_template_parameter_id = @@new_dtp_id, processed = 1, updatevalue=1 where #dashboard_parameter_default_values.dashboard_template_parameter_id = @@old_dtp_id and processed = 0
 	  	  	  	 update #dashboard_parameter_values set dashboard_template_parameter_id = @@new_dtp_id, processed = 1, updatevalue=1 where #dashboard_parameter_values.dashboard_template_parameter_id = @@old_dtp_id and processed = 0
 	  	  	  	 update #dashboard_template_dialogue_parameters set dashboard_template_parameter_id = @@new_dtp_id, processed = 1 where dashboard_template_parameter_id = @@old_dtp_id and processed = 0
 	  	  	 end 
 	  	  	 else
 	  	  	 begin
 	  	  	  	 set @@new_dtp_id = (select min(dashboard_template_parameter_id) from dashboard_Template_parameters where dashboard_template_id = @@dtp_t_id and case when isnumeric(dashboard_template_parameter_name) = 1 then dbo.fnDBTranslate(N'0', dashboard_template_parameter_name,dashboard_template_parameter_name) else dashboard_template_parameter_name end = @@text_dtp_name) 	 
 	  	  	  	 
 	  	  	  	 declare @old_parameter_type_id int ,  @old_has_default int
 	  	  	  	 set @old_parameter_type_id = (select dashboard_parameter_type_id from dashboard_template_parameters where dashboard_template_id = @@dtp_t_id and case when isnumeric(dashboard_template_parameter_name) = 1 then dbo.fnDBTranslate(N'0', dashboard_template_parameter_name,dashboard_template_parameter_name) else dashboard_template_parameter_name end = @@text_dtp_name) 	  	  	 
 	  	  	  	 set @old_has_default = (select has_default_value from dashboard_template_parameters where dashboard_template_id = @@dtp_t_id and case when isnumeric(dashboard_template_parameter_name) = 1 then dbo.fnDBTranslate(N'0', dashboard_template_parameter_name,dashboard_template_parameter_name) else dashboard_template_parameter_name end = @@text_dtp_name) 	  	  	 
 	  	  	  	 if (@old_has_default = 1)
 	  	  	  	 begin
 	  	  	  	  	 set @@dtp_has_default = @old_has_default
 	  	  	  	 end
 	  	  	  	 
 	  	  	  	 update dashboard_template_parameters set dashboard_parameter_type_id = @@dtp_pt_id, 
 	  	  	  	  	  	  	  	  	 dashboard_template_parameter_name = @@dtp_name, 
 	  	  	  	  	  	  	  	  	 has_default_value = @@dtp_has_default, 
 	  	  	  	  	  	  	  	  	 allow_nulls = @@dtp_allow_nulls,
 	  	  	  	  	  	  	  	  	 dashboard_template_parameter_order = @@dtp_order 
 	  	  	  	  	  	  	  	 where dashboard_template_parameter_id = @@new_dtp_id
 	  	  	  	 
 	  	  	  	 update #dashboard_parameter_default_values set dashboard_template_parameter_id = @@new_dtp_id, processed = 1 where dashboard_template_parameter_id = @@old_dtp_id and processed = 0
 	  	  	  	 update #dashboard_parameter_values set dashboard_template_parameter_id = @@new_dtp_id, processed = 1 where dashboard_template_parameter_id = @@old_dtp_id and processed = 0
 	  	  	  	 update #dashboard_template_dialogue_parameters set dashboard_template_parameter_id = @@new_dtp_id, processed = 1 where dashboard_template_parameter_id = @@old_dtp_id and processed = 0
 	  	  	  	 
 	  	  	  	 if (not @old_parameter_type_id = @@dtp_pt_id)
 	  	  	  	 begin
 	  	  	  	  	 update #dashboard_parameter_default_values set updatevalue = 1 where #dashboard_parameter_default_values.dashboard_template_parameter_id = @@new_dtp_id and processed = 0
 	  	  	  	  	 update #dashboard_parameter_values set updatevalue = 1 where #dashboard_parameter_values.dashboard_template_parameter_id = @@new_dtp_id and processed = 0
 	  	  	  	 end
 	  	  	 end 
 	  	  	 Goto DTP_Loop
 	  	 End
 	 Close DTP_Cursor 
 	 Deallocate DTP_Cursor
 	 
 	 drop table #dashboard_template_parameters
 	 update #dashboard_parameter_default_values set processed = 0
 	 update #dashboard_template_dialogue_parameters set processed = 0
 	 update #dashboard_parameter_values set processed = 0
/******************************
Populate Dashboard_Template_Dialogue_Parameters table
*******************************/
 	 declare @@old_dtdp_id int, @@new_dtdp_id int, @@dtdp_dd_id int, @@dtdp_dtp_id int, @@dtdp_count int
 	 
 	 Declare DTDP_Cursor INSENSITIVE CURSOR
 	  	 For Select dashboard_template_dialogue_parameter_id from #dashboard_template_dialogue_parameters order by dashboard_template_dialogue_parameter_id
 	  	 For Read Only
 	 Open DTDP_Cursor  
 	 DTDP_Loop:
 	  	 Fetch Next From DTDP_Cursor Into @@old_dtdp_id
 	  	 If (@@Fetch_Status = 0)
 	  	 Begin
 	  	  	 set @@dtdp_dd_id = (select dashboard_dialogue_id from #dashboard_template_dialogue_parameters where dashboard_template_dialogue_parameter_id = @@old_dtdp_id)
 	  	  	 set @@dtdp_dtp_id = (select dashboard_template_parameter_id from #dashboard_template_dialogue_parameters where dashboard_template_dialogue_parameter_id = @@old_dtdp_id)
 	  	  	 delete from dashboard_template_dialogue_parameters where dashboard_template_parameter_id = @@dtdp_dtp_id
 	  	  	 insert into dashboard_template_dialogue_parameters (dashboard_dialogue_id, dashboard_template_parameter_id)
 	  	  	 values (@@dtdp_dd_id, @@dtdp_dtp_id)
 	  	  	 
 	  	  	 Goto DTDP_Loop
 	  	 End
 	 Close DTDP_Cursor 
 	 Deallocate DTDP_Cursor
 	 
 	 drop table #dashboard_template_dialogue_parameters
/*********************************
Populate/Update Dashboard_Parameter_Default_Values
**********************************/
-- 	 delete from dashboard_parameter_default_values where dashboard_template_parameter_id in (select dashboard_template_parameter_id from dashboard_template_parameters parms, dashboard_parameter_types types where parms.dashboard_parameter_type_id = types.dashboard_parameter_type_id  and types.dashboard_parameter_type_desc = '38180')
-- 	 delete from dashboard_parameter_values where dashboard_template_parameter_id in (select dashboard_template_parameter_id from dashboard_template_parameters parms, dashboard_parameter_types types where parms.dashboard_parameter_type_id = types.dashboard_parameter_type_id  and types.dashboard_parameter_type_desc = '38180')
 	 declare @@old_dpdv_id int, @@new_dpdv_id int, @@dpdv_dtp_id int, @@dpdv_row int, @@dpdv_column int, @@dpdv_value varchar(4000), @@dpdv_value_type_id int, @@dpdv_count int, @@updatevalue int
 	 
 	 declare @@parm_desc varchar(50)
 	 Declare DPDV_Cursor INSENSITIVE CURSOR
 	  	 For Select dashboard_parameter_default_value_id from #dashboard_parameter_default_values order by dashboard_parameter_default_value_id
 	  	 For Read Only
 	 Open DPDV_Cursor  
 	 DPDV_Loop:
 	  	 Fetch Next From DPDV_Cursor Into @@old_dpdv_id
 	  	 If (@@Fetch_Status = 0)
 	  	 Begin
 	  	  	 set @@dpdv_dtp_id = (select dashboard_template_parameter_id from #dashboard_parameter_default_values where dashboard_parameter_default_value_id = @@old_dpdv_id)
 	  	  	 set @@dpdv_row = (select dashboard_parameter_row from #dashboard_parameter_default_values where dashboard_parameter_default_value_id = @@old_dpdv_id)
 	  	  	 set @@dpdv_column = (select dashboard_parameter_column from #dashboard_parameter_default_values where dashboard_parameter_default_value_id = @@old_dpdv_id)
 	  	  	 set @@dpdv_value = (select dashboard_parameter_value from #dashboard_parameter_default_values where dashboard_parameter_default_value_id = @@old_dpdv_id)
 	  	  	 set @@updatevalue = (select updatevalue from #dashboard_parameter_default_values where dashboard_parameter_default_value_id = @@old_dpdv_id)
 	  	  	 set @@parm_desc = (select types.dashboard_parameter_type_desc from dashboard_parameter_types types, dashboard_template_parameters parms where parms.dashboard_parameter_type_id = types.dashboard_parameter_type_id and parms.dashboard_template_parameter_id = @@dpdv_dtp_id) 	  	  	 
 	  	  	 set @@dpdv_count = (select count (dashboard_parameter_default_value_id) from dashboard_parameter_default_values 
 	  	  	 where dashboard_template_parameter_id = @@dpdv_dtp_id and dashboard_parameter_row = @@dpdv_row 
 	  	  	 and dashboard_parameter_column = @@dpdv_column)
 	  	  	 
 	  	  	 if (@@dpdv_count = 0)
 	  	  	 begin
 	  	  	  	 insert into dashboard_parameter_default_values (dashboard_template_parameter_id, dashboard_parameter_row, dashboard_parameter_column, dashboard_parameter_value)
 	  	  	  	  	 values (@@dpdv_dtp_id, @@dpdv_row, @@dpdv_column, @@dpdv_value)
 	  	  	  	 if (@@parm_desc = '38180')
 	  	  	  	 begin
 	  	  	  	  	 declare @@columnvisibilityreportid int
 	  	  	  	  	 Declare ColumnVisibility_Cursor INSENSITIVE CURSOR
 	  	  	  	  	  	 For Select distinct(dashboard_report_id) from dashboard_reports reports, dashboard_template_parameters parms
 	  	  	  	  	  	  	 where reports.dashboard_template_id = parms.dashboard_template_id and parms.dashboard_template_parameter_id = @@dpdv_dtp_id 
 	  	  	  	  	  	 For Read Only
 	  	  	  	  	 Open ColumnVisibility_Cursor  
 	  	  	  	  	 ColumnVisibility_Loop:
 	  	  	  	  	  	 Fetch Next From ColumnVisibility_Cursor Into @@columnvisibilityreportid
 	  	  	  	  	  	 If (@@Fetch_Status = 0)
 	  	  	  	  	  	 Begin
 	  	  	  	  	  	    insert into dashboard_parameter_values(dashboard_template_parameter_id, dashboard_parameter_row, dashboard_parameter_column, dashboard_parameter_value, dashboard_report_id)
 	  	  	  	  	  	  	 values (@@dpdv_dtp_id, @@dpdv_row, @@dpdv_column, @@dpdv_value, @@columnvisibilityreportid)
 	  	  	  	  	  	    goto ColumnVisibility_Loop
 	  	  	  	  	  	 end
 	  	  	  	         close ColumnVisibility_cursor
 	  	  	  	  	 deallocate columnvisibility_cursor
 	  	  	  	 end
 	  	  	  	 
 	  	  	 end 
 	  	  	 else if (@@updatevalue = 1)
 	  	  	 begin
 	  	  	  	 update dashboard_parameter_default_values set dashboard_parameter_value = @@dpdv_column 
 	  	  	  	  	 where dashboard_template_parameter_id = @@dpdv_dtp_id and dashboard_parameter_row = @@dpdv_row 
 	  	  	  	  	  	 and dashboard_parameter_column = @@dpdv_column
 	  	  	 end
 	  	  	 Goto DPDV_Loop
 	  	 End
 	 Close DPDV_Cursor 
 	 Deallocate DPDV_Cursor
 	 
 	 drop table #dashboard_parameter_default_values
/*****************************
Populate Dashboard_Reports, update #Dashboard_Report_Links, #Dashboard_Parameter_Values, #Dashboard_Schedule foreign keys.
*****************************/
 	 declare
 	  	 @@old_r_id int, @@new_r_id int,@@r_template_id int, @@r_version_Count int, @@r_ad_hoc_flag bit, @@r_session_id int, @@r_security_group int,
 	  	 @@r_server varchar(100), @@r_num_hits int, @@r_description varchar(4000), @@r_create_date datetime, @@r_column int, @@r_column_position int,
 	  	 @@r_has_frame int, @@r_expanded int, @@r_allow_remove int, @@r_allow_minimize int, @@r_cache_code int, @@r_cache_timeout int,
 	  	 @@r_detail_link varchar(500), @@r_help_link varchar(500), @@r_name varchar(100), @@r_version int, @@max_version int
 	 
 	 Declare R_Cursor INSENSITIVE CURSOR
 	  	 For Select dashboard_report_id from #dashboard_reports order by dashboard_report_id, version
 	  	 For Read Only
 	 Open R_Cursor  
 	 R_Loop:
 	  	 Fetch Next From R_Cursor Into @@old_r_id
 	  	 If (@@Fetch_Status = 0)
 	  	 Begin
 	  	  	 set @@r_template_id  = (select dashboard_template_id from #dashboard_reports where dashboard_report_id = @@old_r_id)
 	  	  	 set @@r_version_count  = (select dashboard_report_version_count from #dashboard_reports where dashboard_report_id = @@old_r_id)
 	  	  	 set @@r_ad_hoc_flag  = (select dashboard_report_ad_hoc_flag from #dashboard_reports where dashboard_report_id = @@old_r_id)
 	  	  	 set @@r_session_id  = (select dashboard_session_id from #dashboard_reports where dashboard_report_id = @@old_r_id)
 	  	  	 set @@r_security_group  = null
 	  	  	 execute spServer_CmnGetParameter 165,29, @@SERVERNAME, @@r_server output
 	  	  	 set @@r_num_hits  = 0
 	  	  	 set @@r_description  = (select dashboard_report_description from #dashboard_reports where dashboard_report_id = @@old_r_id)
 	  	  	 set @@r_create_date = (select dashboard_report_create_date from #dashboard_reports where dashboard_report_id = @@old_r_id)
 	  	  	 set @@r_column  = (select dashboard_report_column from #dashboard_reports where dashboard_report_id = @@old_r_id)
 	  	  	 set @@r_column_position  = (select dashboard_report_column_position from #dashboard_reports where dashboard_report_id = @@old_r_id)
 	  	  	 set @@r_has_frame  = (select dashboard_report_has_frame from #dashboard_reports where dashboard_report_id = @@old_r_id)
 	  	  	 set @@r_expanded  = (select dashboard_report_expanded from #dashboard_reports where dashboard_report_id = @@old_r_id)
 	  	  	 set @@r_allow_remove = (select dashboard_report_allow_remove from #dashboard_reports where dashboard_report_id = @@old_r_id)
 	  	  	 set @@r_allow_minimize  = (select dashboard_report_allow_minimize from #dashboard_reports where dashboard_report_id = @@old_r_id)
 	  	  	 set @@r_cache_code  = (select dashboard_report_cache_code from #dashboard_reports where dashboard_report_id = @@old_r_id)
 	  	  	 set @@r_cache_timeout  = (select dashboard_report_cache_timeout from #dashboard_reports where dashboard_report_id = @@old_r_id)
 	  	  	 set @@r_detail_link  = (select dashboard_report_detail_link from #dashboard_reports where dashboard_report_id = @@old_r_id)
 	  	  	 set @@r_help_link  = (select dashboard_report_help_link from #dashboard_reports where dashboard_report_id = @@old_r_id)
 	  	  	 set @@r_name  = (select dashboard_report_name from #dashboard_reports where dashboard_report_id = @@old_r_id)
 	  	  	 set @@r_version  = (select version from #dashboard_reports where dashboard_report_id = @@old_r_id)
 	  	  	 set @@max_version = (select max(version) + 1 from dashboard_reports where dashboard_report_name = @@r_name and dashboard_template_id = @@r_template_id)
 	  	  	 if (@@max_version is null)
 	  	  	 begin
 	  	  	  	 set @@max_version = 1
 	  	  	 end
 	  	  	 insert into dashboard_reports
 	  	  	  	 (dashboard_template_id, dashboard_report_version_count, dashboard_report_ad_hoc_flag, dashboard_session_id,
 	  	  	  	 dashboard_report_security_group_id,dashboard_report_server, dashboard_report_number_hits, dashboard_report_description, 
 	  	  	  	 dashboard_report_create_date, dashboard_report_column,dashboard_report_column_position, dashboard_report_has_frame, 
 	  	  	  	 dashboard_report_expanded, dashboard_report_allow_remove, dashboard_report_allow_minimize,dashboard_report_cache_code, 
 	  	  	  	 dashboard_report_cache_timeout, dashboard_report_detail_link, dashboard_report_help_link, dashboard_report_name, version)
 	  	  	  	 values (@@r_template_id, @@r_version_count, @@r_ad_hoc_flag, @@r_session_id, @@r_security_group, @@r_server, @@r_num_hits, 
 	  	  	  	 @@r_description,@@r_create_date, @@r_column, @@r_column_position, @@r_has_frame, @@r_expanded, @@r_allow_remove,
  	  	  	  	 @@r_allow_minimize, @@r_cache_code, @@r_cache_timeout,@@r_detail_link, @@r_help_link, @@r_name, @@max_version)
 	  	  	 
 	  	  	 set @@new_r_id = (select scope_identity())
 	  	  	 update #dashboard_schedule set dashboard_report_id = @@new_r_id, processed = 1 where dashboard_report_id = @@old_r_id and processed = 0 	  	  	 
 	  	  	 update #dashboard_parameter_values set dashboard_report_id = @@new_r_id, processed = 1 where dashboard_report_id = @@old_r_id and processed = 0
 	  	  	 update #dashboard_report_links set dashboard_report_from_id = @@new_r_id, processed_a = 1 where dashboard_report_from_id = @@old_r_id and processed_a = 0
 	  	  	 update #dashboard_report_links set dashboard_report_to_id = @@new_r_id, processed_b = 1 where dashboard_report_to_id = @@old_r_id and processed_b = 0 	  	  	 
 	  	  	 Goto R_Loop
 	  	 End 	 
 	 Close R_Cursor 
 	 Deallocate R_Cursor
 	 drop table #dashboard_reports
 	 update #dashboard_report_links set processed_a = 0, processed_b = 0
 	 update #dashboard_parameter_values set processed = 0;
 	 update #dashboard_schedule set processed = 0;
/******************************
Populate Dashboard_Report_Links table
*******************************/
 	 declare @@old_drl_id int, @@new_drl_id int,@@drtl_id int, @@drl_from int, @@drl_to int
 	 
 	 
 	 Declare DRL_Cursor INSENSITIVE CURSOR
 	  	 For Select dashboard_report_link_id from #dashboard_report_links order by dashboard_report_link_id
 	  	 For Read Only
 	 Open DRL_Cursor  
 	 DRL_Loop:
 	  	 Fetch Next From DRL_Cursor Into @@old_drl_id
 	  	 If (@@Fetch_Status = 0)
 	  	 Begin
 	  	  	 set @@drtl_id = (select dashboard_template_link_id from #dashboard_report_links where dashboard_report_link_id = @@old_drl_id)
 	  	  	 set @@drl_from = (select dashboard_report_from_id from #dashboard_report_links where dashboard_report_link_id = @@old_drl_id)
 	  	  	 set @@drl_to = (select dashboard_report_to_id from #dashboard_report_links where dashboard_report_link_id = @@old_drl_id)
 	  	  	 
 	  	  	 insert into dashboard_report_links (dashboard_template_link_id, dashboard_report_from_id,dashboard_report_to_id) 
 	  	  	 values(@@drtl_id, @@drl_from, @@drl_to)
 	  	  	 Goto DRL_Loop
 	  	 End
 	 Close DRL_Cursor 
 	 Deallocate DRL_Cursor
 	 
 	 drop table #dashboard_report_links
--SECTION2
/****************************
Populate Dashboard_Parameter_Values table
******************************/
 	 declare @@old_dpv_id int, @@new_dpv_id int,@@dpv_report_id int, @@dpv_dtp_id int, @@dpv_row int, @@dpv_column int, @@dpv_value varchar(4000)
 	 
 	 Declare DPV_Cursor INSENSITIVE CURSOR
 	  	 For Select dashboard_parameter_value_id from #dashboard_parameter_values order by dashboard_parameter_value_id
 	  	 For Read Only
 	 Open DPV_Cursor  
 	 DPV_Loop:
 	  	 Fetch Next From DPV_Cursor Into @@old_dpv_id
 	  	 If (@@Fetch_Status = 0)
 	  	 Begin
 	  	  	 set @@dpv_report_id = (select dashboard_report_id from #dashboard_parameter_values where dashboard_parameter_value_id = @@old_dpv_id)
 	  	  	 set @@dpv_dtp_id = (select dashboard_template_parameter_id from #dashboard_parameter_values where dashboard_parameter_value_id = @@old_dpv_id)
 	  	  	 set @@dpv_row = (select dashboard_parameter_row from #dashboard_parameter_values where dashboard_parameter_value_id = @@old_dpv_id)
 	  	  	 set @@dpv_column = (select dashboard_parameter_column from #dashboard_parameter_values where dashboard_parameter_value_id = @@old_dpv_id)
 	  	  	 set @@dpv_value = (select dashboard_parameter_value from #dashboard_parameter_values where dashboard_parameter_value_id = @@old_dpv_id)
 	  	  	 
 	  	  	 insert into dashboard_parameter_values 
 	  	  	 (dashboard_report_id, dashboard_template_parameter_id, dashboard_parameter_row, dashboard_parameter_column, dashboard_parameter_value)
 	  	  	 values (@@dpv_report_id, @@dpv_dtp_id, @@dpv_row, @@dpv_column, @@dpv_value)
 	  	  	 Goto DPV_Loop
 	  	 End
 	 Close DPV_Cursor 
 	 Deallocate DPV_Cursor
 	 
 	 drop table #dashboard_parameter_values
/**************************8
Populate Dashboard_Schedule_Table, update #Dashboard_Schedule_Events, #Dashboard_Schedule_Frequency, #Dashboard_Calendar Foreign Keys
****************************/
 	 declare @@old_s_id int, @@new_s_id int,@@s_report_id int, @@s_frequency_Based bit, @@s_calendar_based bit, @@s_event_based bit, @@s_last_run_time datetime, @@s_on_demand bit
 	 
 	 Declare S_Cursor INSENSITIVE CURSOR
 	  	 For Select dashboard_schedule_id from #dashboard_schedule order by dashboard_schedule_id
 	  	 For Read Only
 	 Open S_Cursor  
 	 S_Loop:
 	  	 Fetch Next From S_Cursor Into @@old_s_id
 	  	 If (@@Fetch_Status = 0)
 	  	 Begin
 	  	  	 set @@s_report_id = (select dashboard_report_id from #dashboard_schedule where dashboard_schedule_id = @@old_s_id)
 	  	  	 set @@s_frequency_based = (select dashboard_frequency_based from #dashboard_schedule where dashboard_schedule_id = @@old_s_id)
 	  	  	 set @@s_calendar_based = (select dashboard_calendar_based from #dashboard_schedule where dashboard_schedule_id = @@old_s_id)
 	  	  	 set @@s_event_Based = (select dashboard_event_based from #dashboard_schedule where dashboard_schedule_id = @@old_s_id)
 	  	  	 set @@s_last_run_time = (select dashboard_last_run_time from #dashboard_schedule where dashboard_schedule_id = @@old_s_id)
 	  	  	 set @@s_on_demand = (select dashboard_on_demand_based from #dashboard_schedule where dashboard_schedule_id = @@old_s_id)
 	  	  	 
 	  	  	 insert into dashboard_schedule
 	  	  	 (dashboard_report_id, dashboard_frequency_based, dashboard_calendar_based, dashboard_event_based, dashboard_last_run_time, dashboard_on_demand_based)
 	  	  	 values (@@s_report_id, @@s_frequency_based, @@s_calendar_based, @@s_event_based, @@s_last_run_time, @@s_on_demand)
 	  	  	 set @@new_s_id = (select scope_identity())
 	  	  	 update #dashboard_schedule_events set dashboard_schedule_id = @@new_s_id, processed = 1 where dashboard_schedule_id = @@old_s_id and processed = 0 	  	  	 
 	  	  	 update #dashboard_schedule_frequency set dashboard_schedule_id = @@new_s_id, processed = 1 where dashboard_schedule_id = @@old_s_id and processed = 0 	  	  	 
 	  	  	 update #dashboard_calendar set dashboard_schedule_id = @@new_s_id, processed = 1 where dashboard_schedule_id = @@old_s_id and processed = 0 	  	  	 
 	  	  	 Goto S_Loop
 	  	 End
 	 Close S_Cursor 
 	 Deallocate S_Cursor 	 
 	 drop table #dashboard_schedule
 	 update #dashboard_schedule_events set processed = 0
 	 update #dashboard_schedule_frequency set processed = 0
 	 update #dashboard_calendar set processed = 0
/**************************
Populate Dashboard_Calendar, update #Dashboard_Custom_Dates, #Dashboard_Day_Of_Week foreign keys
***************************/
 	 declare @@old_c_id int, @@new_c_id int,@@c_schedule_id int, @@c_first_of_month bit, @@c_last_of_month bit, @@c_first_of_quarter bit, @@c_last_of_quarter bit, @@c_first_of_year bit, @@c_last_of_year bit, @@c_day_of_week bit, @@c_custom_date bit
 	 
 	 Declare C_Cursor INSENSITIVE CURSOR
 	  	 For Select dashboard_Calendar_id from #dashboard_Calendar order by dashboard_calendar_id
 	  	 For Read Only
 	 Open C_Cursor  
 	 C_Loop:
 	  	 Fetch Next From C_Cursor Into @@old_c_id
 	  	 If (@@Fetch_Status = 0)
 	  	 Begin
 	  	  	 set @@c_schedule_id = (select dashboard_schedule_id from #dashboard_calendar where dashboard_calendar_id = @@old_c_id)
 	  	  	 set @@c_first_of_month = (select dashboard_first_of_month from #dashboard_calendar where dashboard_calendar_id = @@old_c_id)
 	  	  	 set @@c_last_of_month = (select dashboard_last_of_month from #dashboard_calendar where dashboard_calendar_id = @@old_c_id)
 	  	  	 set @@c_first_of_quarter = (select dashboard_first_of_quarter from #dashboard_calendar where dashboard_calendar_id = @@old_c_id)
 	  	  	 set @@c_last_of_quarter = (select dashboard_last_of_quarter from #dashboard_calendar where dashboard_calendar_id = @@old_c_id)
 	  	  	 set @@c_first_of_year = (select dashboard_first_of_year from #dashboard_calendar where dashboard_calendar_id = @@old_c_id)
 	  	  	 set @@c_last_of_year = (select dashboard_last_of_year from #dashboard_calendar where dashboard_calendar_id = @@old_c_id)
 	  	  	 set @@c_day_of_week = (select dashboard_day_of_week from #dashboard_calendar where dashboard_calendar_id = @@old_c_id)
 	  	  	 set @@c_custom_date = (select dashboard_custom_date from #dashboard_calendar where dashboard_calendar_id = @@old_c_id)
 	  	  	 
 	  	  	 insert into dashboard_calendar
 	  	  	 (dashboard_schedule_id, dashboard_first_of_month, dashboard_last_of_month, dashboard_first_of_quarter, dashboard_last_of_quarter, dashboard_first_of_year, dashboard_last_of_year, dashboard_day_of_week, dashboard_custom_date)
 	  	  	 values (@@c_schedule_id, @@c_first_of_month, @@c_last_of_month, @@c_first_of_quarter, @@c_last_of_quarter, @@c_first_of_year, @@c_last_of_year, @@c_day_of_week, @@c_custom_date)
 	  	  	 set @@new_c_id = (select scope_identity())
 	  	  	 update #dashboard_custom_dates set dashboard_calendar_id = @@new_c_id, processed = 1 where dashboard_calendar_id = @@old_c_id and processed = 0 	  	  	 
 	  	  	 update #dashboard_day_of_week set dashboard_calendar_id = @@new_c_id, processed = 1 where dashboard_calendar_id = @@old_c_id and processed = 0 	  	  	 
 	  	  	 Goto C_Loop
 	  	 End
 	 Close C_Cursor 
 	 Deallocate C_Cursor 	 
 	 drop table #dashboard_calendar
 	 update #dashboard_custom_dates set processed = 0
 	 update #dashboard_day_of_week set processed = 0
/*****************************
Populate Dashboard_Custom_Dates
*****************************/
 	 declare @@old_cd_id int, @@new_cd_id int,@@cd_calendar_id int, @@cd_day_to_run datetime, @@cd_completed bit
 	 
 	 Declare CD_Cursor INSENSITIVE CURSOR
 	  	 For Select dashboard_custom_Date_id from #dashboard_custom_Dates order by dashboard_custom_Date_id
 	  	 For Read Only
 	 Open CD_Cursor  
 	 CD_Loop:
 	  	 Fetch Next From CD_Cursor Into @@old_cd_id
 	  	 If (@@Fetch_Status = 0)
 	  	 Begin
 	  	  	 set @@cd_calendar_id = (select dashboard_calendar_id from #dashboard_custom_Dates where dashboard_custom_date_id = @@old_cd_id)
 	  	  	 set @@cd_day_to_run = (select dashboard_day_to_run from #dashboard_custom_Dates where dashboard_custom_date_id = @@old_cd_id)
 	  	  	 set @@cd_completed = (select dashboard_completed from #dashboard_custom_Dates where dashboard_custom_date_id = @@old_cd_id)
 	  	  	 
 	  	  	 insert into dashboard_custom_dates
 	  	  	 (dashboard_calendar_id, dashboard_day_to_run, dashboard_completed)
 	  	  	 values (@@cd_calendar_id,@@cd_day_to_run, @@cd_completed)
 	  	  	 Goto CD_Loop
 	  	 End
 	 Close CD_Cursor 
 	 Deallocate CD_Cursor 	 
 	 drop table #dashboard_custom_dates
/***********************************
Populate Dashboard_Day_of_week
********************************/
 	 declare @@old_dw_id int, @@new_dw_id int,@@dw_calendar_id int, @@dw_day_of_week int
 	 
 	 Declare DW_Cursor INSENSITIVE CURSOR
 	  	 For Select dashboard_day_of_week_id from #dashboard_day_of_week order by dashboard_day_of_week_id
 	  	 For Read Only
 	 Open DW_Cursor  
 	 DW_Loop:
 	  	 Fetch Next From DW_Cursor Into @@old_dw_id
 	  	 If (@@Fetch_Status = 0)
 	  	 Begin
 	  	  	 set @@dw_calendar_id = (select dashboard_calendar_id from #dashboard_day_of_week where dashboard_day_of_week_id = @@old_dw_id)
 	  	  	 set @@dw_day_of_week= (select dashboard_day_of_week from #dashboard_day_of_week where dashboard_day_of_week_id = @@old_dw_id)
 	  	  	 
 	  	  	 insert into dashboard_day_of_week
 	  	  	 (dashboard_calendar_id, dashboard_day_of_week)
 	  	  	 values (@@dw_calendar_id,@@dw_day_of_week)
 	  	  	 Goto DW_Loop
 	  	 End
 	 Close DW_Cursor 
 	 Deallocate DW_Cursor 	 
 	 drop table #dashboard_day_of_week
/****************************
Populate Dashboard_Schedule_Frequency
**************************/
 	 declare @@old_dsf_id int, @@new_dsf_id int,@@dsf_schedule_id int, @@dsf_frequency_based_time datetime, @@dsf_frequency int, @@dsf_Frequency_type_id int
 	 
 	 Declare DSF_Cursor INSENSITIVE CURSOR
 	  	 For Select dashboard_schedule_frequency_id from #dashboard_schedule_frequency order by dashboard_schedule_frequency_id
 	  	 For Read Only
 	 Open DSF_Cursor  
 	 DSF_Loop:
 	  	 Fetch Next From DSF_Cursor Into @@old_dsf_id
 	  	 If (@@Fetch_Status = 0)
 	  	 Begin
 	  	  	 set @@dsf_schedule_id = (select dashboard_schedule_id from #dashboard_schedule_frequency where dashboard_schedule_frequency_id = @@old_dsf_id)
 	  	  	 set @@dsf_frequency_based_time = (select dashboard_frequency_base_time from #dashboard_schedule_frequency where dashboard_schedule_frequency_id = @@old_dsf_id)
 	  	  	 set @@dsf_frequency = (select dashboard_frequency from #dashboard_schedule_frequency where dashboard_schedule_frequency_id = @@old_dsf_id)
 	  	  	 set @@dsf_frequency_type_id = (select dashboard_frequency_type_id from #dashboard_schedule_frequency where dashboard_schedule_frequency_id = @@old_dsf_id)
 	  	  	 
 	  	  	 insert into dashboard_schedule_frequency
 	  	  	 (dashboard_schedule_id, dashboard_frequency_base_time, dashboard_frequency, dashboard_frequency_type_id)
 	  	  	 values (@@dsf_schedule_id, @@dsf_frequency_based_time, @@dsf_frequency, @@dsf_frequency_type_id)
 	  	  	 Goto DSF_Loop
 	  	 End
 	 Close DSF_Cursor 
 	 Deallocate DSF_Cursor 	 
 	 drop table #dashboard_schedule_frequency
/********************
Populate Dashboard_Schedule_Events
*******************/
 	 declare @@old_dse_id int, @@new_dse_id int,@@dse_schedule_id int, @@dse_event_scope_id int, @@dse_event_type_id int, @@dse_pu_id int, @@dse_var_id int
 	 
 	 Declare DSE_Cursor INSENSITIVE CURSOR
 	  	 For Select dashboard_schedule_event_id from #dashboard_schedule_events order by dashboard_schedule_event_id
 	  	 For Read Only
 	 Open DSE_Cursor  
 	 DSE_Loop:
 	  	 Fetch Next From DSE_Cursor Into @@old_dse_id
 	  	 If (@@Fetch_Status = 0)
 	  	 Begin
 	  	  	 set @@dse_schedule_id = (select dashboard_schedule_id from #dashboard_schedule_events where dashboard_schedule_event_id = @@old_dse_id)
 	  	  	 set @@dse_event_scope_id = (select dashboard_event_scope_id from #dashboard_schedule_events where dashboard_schedule_event_id = @@old_dse_id)
 	  	  	 set @@dse_event_type_id = (select dashboard_event_type_id from #dashboard_schedule_events where dashboard_schedule_event_id = @@old_dse_id)
 	  	  	 set @@dse_pu_id = (select pu_id from #dashboard_schedule_events where dashboard_schedule_event_id = @@old_dse_id)
 	  	  	 set @@dse_var_id = (select var_id from #dashboard_schedule_events where dashboard_schedule_event_id = @@old_dse_id)
 	  	  	 
 	  	  	 insert into dashboard_schedule_events
 	  	  	 (dashboard_schedule_id, dashboard_event_scope_id, dashboard_event_type_id, pu_id, var_id)
 	  	  	 values (@@dse_schedule_id, @@dse_event_Scope_id, @@dse_event_type_id, @@dse_pu_id, @@dse_var_id)
 	  	  	 Goto DSE_Loop
 	  	 End
 	 Close DSE_Cursor 
 	 Deallocate DSE_Cursor 	 
 	 drop table #dashboard_schedule_events
declare @ptid int
select @ptid = dashboard_parameter_type_id from dashboard_parameter_types where dashboard_parameter_type_desc = 'Test Names'
execute spDBR_Delete_Parameter @ptid
 	 declare @@dialogid int
 	 
 	 Declare Dialog_Cursor INSENSITIVE CURSOR
 	  	 For Select dashboard_dialogue_id from dashboard_dialogues where dashboard_dialogue_name like 'Select %'
 	  	 For Read Only
 	 Open Dialog_Cursor  
 	 Dialog_Cursor_LOOP:
 	  	 Fetch Next From Dialog_Cursor Into @@dialogid
 	  	 If (@@Fetch_Status = 0)
 	  	 Begin
 	  	  	 execute spDBR_Delete_Dialogue @@dialogid
 	  	  	 Goto Dialog_Cursor_LOOP
 	  	 End
 	 Close Dialog_Cursor
 	 Deallocate Dialog_Cursor
/**********************************************************************************************************/
/*This is to allow for the sticky dialogs, ie ones that show up no matter what (should be taken care of by default*/
/***********************************************************************************************************/
/*update dashboard_template_parameters set allow_nulls = 2 where dashboard_Template_parameter_name in ('38491', '38243')
*/
