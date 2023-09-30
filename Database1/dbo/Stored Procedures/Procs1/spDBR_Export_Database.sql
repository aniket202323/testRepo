Create Procedure dbo.spDBR_Export_Database
@locktemplates bit = 0,
@InTimeZone 	  	 varchar(200) = NULL  ---23/08/2010 - Ex: 'India Standard Time','Central Stardard Time' 
AS
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
 	  	 dashboard_custom_date bit
 	 )
 	 
 	 create table #dashboard_custom_dates
 	 (
 	  	 dashboard_custom_date_id int,
 	  	 dashboard_calendar_id int,
 	  	 dashboard_day_to_run datetime,
 	  	 dashboard_completed bit
 	 )
 	 create table #Dashboard_DataTable_Headers
 	 (
 	  	 Dashboard_DataTable_Header_ID int,
 	  	 Dashboard_Parameter_Type_ID int,
 	  	 Dashboard_DataTable_Column int,
 	  	 Dashboard_DataTable_Header varchar(50),
 	  	 Dashboard_DataTable_Presentation bit,
 	  	 Dashboard_DataTable_Column_SP varchar(100) 
 	 )
 	 create table #Dashboard_DataTable_Presentation_Parameters
 	 (
 	  	 Dashboard_DataTable_Presentation_Parameter_ID int,
 	  	 Dashboard_DataTable_Header_ID int,
 	  	 Dashboard_DataTable_Presentation_Parameter_Order int,
 	  	 Dashboard_DataTable_Presentation_Parameter_Input int 
 	 )
 	 create table #dashboard_day_of_week
 	 ( 	  	 Dashboard_day_of_week_id int,
 	  	 dashboard_calendar_id int,
 	  	 dashboard_day_of_week int
 	 )
 	 create table #Dashboard_Dialogue_Parameters
 	 (
 	  	 Dashboard_Dialogue_Parameter_ID int,
 	  	 Dashboard_Dialogue_ID int,
 	  	 Dashboard_Parameter_Type_Id int 
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
 	 create table #Dashboard_Parameter_Data_Types
 	 (
 	  	 Dashboard_Parameter_Data_Type_ID int,
 	  	 Dashboard_Parameter_Data_Type varchar(100) 
 	 )
 	 create table #Dashboard_Parameter_Default_Values
 	 (
 	  	 Dashboard_Parameter_Default_Value_ID int,
 	  	 Dashboard_Template_Parameter_ID int,
 	  	 Dashboard_Parameter_Row int,
 	  	 Dashboard_Parameter_Column int,
 	  	 Dashboard_Parameter_Value varchar(4000)
 	 )
 	 create table #Dashboard_Parameter_Types
 	 (
 	  	 Dashboard_Parameter_Type_ID int,
 	  	 Dashboard_Parameter_Type_Desc varchar(100),
 	  	 Dashboard_Parameter_Data_Type_ID int,
 	  	 locked bit,
 	  	 Version int,
 	  	 Value_Type int 
 	 )
 	 create table #Dashboard_Parameter_Values
 	 (
 	  	 Dashboard_Parameter_Value_ID int,
 	  	 Dashboard_Report_ID int,
 	  	 Dashboard_Template_Parameter_ID int,
 	  	 Dashboard_Parameter_Row int,
 	  	 Dashboard_Parameter_Column int,
 	  	 Dashboard_Parameter_Value varchar(4000)
 	 )
 	 create table #Dashboard_Report_Links
 	 (
 	  	 Dashboard_Report_Link_ID int,
 	  	 Dashboard_Template_Link_ID int,
 	  	 Dashboard_Report_From_ID int,
 	  	 Dashboard_Report_To_ID int
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
 	  	 dashboard_report_name varchar(100)
 	 )
 	 create table #Dashboard_Schedule
 	 (
 	  	 Dashboard_schedule_id int,
 	  	 dashboard_report_id int,
 	  	 dashboard_frequency_based bit,
 	  	 dashboard_calendar_based bit,
 	  	 dashboard_event_based bit,
 	  	 dashboard_last_run_time datetime,
 	  	 dashboard_on_demand_based bit
 	 )
 	 create table #dashboard_schedule_events
 	 (
 	  	 dashboard_schedule_event_id int,
 	  	 dashboard_schedule_id int,
 	  	 dashboard_event_scope_id int,
 	  	 dashboard_event_type_id int,
 	  	 pu_id int,
 	  	 var_id int
 	 )
 	 create table #dashboard_schedule_frequency
 	 (
 	  	 dashboard_schedule_frequency_id int,
 	  	 dashboard_schedule_id int,
 	  	 dashboard_frequency_base_time datetime,
 	  	 dashboard_frequency int,
 	  	 dashboard_frequency_type_id int
 	 )
 	 
 	 create table #Dashboard_Template_Dialogue_Parameters
 	 (
 	  	 Dashboard_Template_Dialogue_Parameter_ID int,
 	  	 Dashboard_Dialogue_ID int,
 	  	 Dashboard_Template_Parameter_ID int 
 	 )
 	 create table #Dashboard_Template_Links
 	 (
 	  	 Dashboard_Template_Link_ID int,
 	  	 Dashboard_Template_Link_From int,
 	  	 Dashboard_Template_Link_To int 
 	 )
 	 create table #Dashboard_Template_Parameters
 	 (
 	  	 Dashboard_Template_Parameter_ID int,
 	  	 Dashboard_Template_ID int,
 	  	 Dashboard_Template_Parameter_Order int,
 	  	 Dashboard_Parameter_Type_ID int,
 	  	 Dashboard_Template_Parameter_Name varchar(100),
 	  	 Has_Default_Value bit,
 	  	 Allow_Nulls int
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
 	  	 dashboard_template_fixed_width bit
 	 )
 	 insert into #Dashboard_Templates select 	 Dashboard_Template_ID,Dashboard_Template_Name,Dashboard_Template_XSL, 	 Dashboard_Template_XSL_Filename,Dashboard_Template_Preview, Dashboard_Template_Preview_Filename,Dashboard_Template_Build,Dashboard_Template_Locked,Dashboard_Template_Launch_Type, 	 Dashboard_Template_Procedure,Dashboard_Template_Size_Unit,Dashboard_Template_Description, 	 Dashboard_Template_Column,Dashboard_Template_Column_Position,Dashboard_Template_Has_Frame,Dashboard_Template_Expanded,Dashboard_Template_Allow_Remove,Dashboard_Template_Allow_Minimize,Dashboard_Template_Cache_Code,Dashboard_Template_Cache_Timeout,Dashboard_Template_Detail_Link,Dashboard_Template_Help_Link,version,Height, 	 Width,type, dashboard_template_fixed_height, dashboard_template_fixed_width from dashboard_templates
 	 insert into #Dashboard_Template_Parameters select dashboard_template_parameter_id, dashboard_template_id, dashboard_template_parameter_order, 
 	  	 dashboard_parameter_type_id, dashboard_template_parameter_name, has_default_value, allow_nulls from dashboard_template_parameters
 	 insert into #Dashboard_Template_Links select dashboarD_template_link_id, dashboard_template_link_from, dashboard_template_link_to
 	  	 from dashboard_template_links
 	 insert into #Dashboard_Template_Dialogue_Parameters select dashboard_template_dialogue_parameter_id, dashboard_dialogue_id, dashboard_template_parameter_id
 	  	 from dashboard_template_dialogue_parameters
 	 insert into #dashboard_schedule_frequency select dashboard_schedule_frequency_id, dashboard_schedule_id, dashboard_frequency_base_time,
 	  	 dashboard_frequency, dashboard_frequency_type_id from dashboard_schedule_frequency
 	 insert into #dashboarD_schedule_events select dashboard_schedule_event_id, dashboard_schedule_id, dashboarD_event_scope_id, dashboarD_event_type_id,
 	  	 pu_id, var_id from dashboard_schedule_events
 	 insert into #dashboard_schedule select dashboard_schedule_id, dashboard_report_id, dashboard_frequency_based, dashboard_calendar_based, dashboard_event_based,
 	  	 dashboard_last_run_time, dashboarD_on_demand_based from dashboard_schedule
 	 insert into #dashboard_reports select dashboard_report_id, dashboard_template_id, dashboard_report_version_count, dashboard_report_ad_hoc_flag,
 	  	 dashboard_session_id, dashboard_report_security_group_id, dashboard_report_server, dashboard_report_number_hits, dashboard_report_description,
 	  	 dashboard_report_create_date, dashboard_report_column, dashboard_report_column_position, dashboard_report_has_frame, dashboard_report_expanded,
 	  	 dashboard_report_allow_remove, dashboard_report_allow_minimize, dashboard_report_cache_code, dashboard_report_cache_timeout, dashboard_report_detail_link,
 	  	 dashboard_report_help_link, dashboard_report_name from dashboard_reports where dashboard_Report_ad_hoc_flag = 0
 	 insert into #Dashboard_Report_Links select l.dashboard_report_Link_id, l.dashboard_template_link_id, l.dashboarD_report_from_id, l.dashboard_report_to_id from dashboard_report_links l, dashboard_Reports r
 	 where l.dashboard_report_from_id = r.dashboard_report_id and r.dashboard_report_ad_hoc_flag = 0
 	 insert into #Dashboard_Parameter_Values select p.dashboard_parameter_value_id, p.dashboard_report_id, p.dashboard_template_parameter_id, p.dashboard_parameter_row,
 	  	 p.dashboard_parameter_column, p.dashboard_parameter_value from dashboard_parameter_values p, dashboard_reports r
 	  	 where p.dashboard_report_id = r.dashboard_report_id and r.dashboard_report_ad_hoc_flag = 0
 	 insert into #Dashboard_Parameter_Types select dashboard_parameter_type_id, dashboard_parameter_type_desc, dashboard_parameter_data_type_id,
 	  	 locked, version, value_Type from dashboard_parameter_types
 	 insert into #Dashboard_Parameter_Default_Values select dashboard_parameter_default_value_id, dashboard_template_parameter_id, dashboard_parameter_row,
 	  	  	 dashboard_parameter_column, dashboard_parameter_value from dashboard_parameter_default_values
 	 insert into #Dashboard_Parameter_Data_Types select dashboard_parameter_data_type_id, dashboard_parameter_data_type from dashboard_parameter_data_types
 	 insert into #dashboard_dialogues select dashboard_dialogue_id, dashboard_dialogue_name, external_address, url, parameter_count, locked, Version from dashboard_dialogues
 	 insert into #dashboard_dialogue_parameters select dashboard_dialogue_parameter_id, dashboard_dialogue_id, dashboard_parameter_type_id from dashboard_dialogue_parameters
 	 insert into #dashboard_day_of_week select dashboard_day_of_week_id, dashboarD_calendar_id, dashboard_day_of_week from dashboard_day_of_week
 	 insert into #dashboard_calendar select dashboard_calendar_id, dashboard_schedule_id, dashboard_first_of_month, 
 	  	 dashboard_last_of_month, dashboard_first_of_quarter,dashboard_last_of_quarter, dashboard_first_of_year,
 	  	 dashboard_last_of_year, dashboard_day_of_week, dashboard_custom_date from dashboard_calendar
 	 insert into #dashboard_custom_Dates select dashboard_custom_date_id, dashboard_calendar_id, dashboard_day_to_run, dashboard_completed from dashboard_custom_dates
 	 insert into #Dashboard_DataTable_Headers select dashboard_datatable_header_id, dashboard_parameter_type_id, dashboard_datatable_column, dashboard_datatable_header,
 	  	 dashboard_datatable_presentation, dashboard_datatable_column_sp from dashboard_datatable_headers
 	 insert into #dashboard_datatable_presentation_parameters select dashboard_datatable_presentation_parameter_id, dashboard_datatable_header_id,
 	  	 dashboard_datatable_presentation_parameter_order, dashboard_datatable_presentation_parameter_input from dashboard_datatable_presentation_parameters
 	  	 
 	 select * from #Dashboard_Templates for xml auto, BINARY BASE64
 	 select * from #Dashboard_Template_Parameters for xml auto
 	 select * from #Dashboard_Template_Links for xml auto
 	 select * from #Dashboard_Template_Dialogue_Parameters for xml auto 	 
 	 ---23/08/2010 - Update datetime formate in UTC into #Dashboard_Schedule_Frequency table
 	 Update #Dashboard_Schedule_Frequency Set dashboard_frequency_base_time = dbo.fnServer_CmnConvertFromDBTime(dashboard_frequency_base_time,@InTimeZone)
 	 select * from #Dashboard_Schedule_Frequency for xml auto
 	 
 	 select * from #Dashboard_Schedule_Events for xml auto
 	 
 	 ---23/08/2010 - Update datetime formate in UTC into #Dashboard_Schedule table
 	 Update #Dashboard_Schedule Set dashboard_last_run_time = dbo.fnServer_CmnConvertFromDBTime(dashboard_last_run_time,@InTimeZone)
 	 select * from #Dashboard_Schedule for xml auto
 	 ---23/08/2010 - Update datetime formate in UTC into #Dashboard_Reports table
 	 Update #Dashboard_Reports Set dashboard_report_create_date = dbo.fnServer_CmnConvertFromDBTime(dashboard_report_create_date,@InTimeZone)
 	 select * from #Dashboard_Reports for xml auto
 	 
 	 select * from #Dashboard_Report_Links for xml auto
 	 select * from #Dashboard_Parameter_Values for xml auto
 	 select * from #Dashboard_Parameter_Types for xml auto
 	 select * from #Dashboard_Parameter_Default_Values for xml auto
 	 select * from #Dashboard_Parameter_Data_Types for xml auto
 	 select * from #Dashboard_Dialogues for xml auto
 	 select * from #Dashboard_Dialogue_Parameters for xml auto
 	 select * from #Dashboard_Calendar for xml auto
 	 
 	 ---23/08/2010 - Update datetime formate in UTC into #Dashboard_Custom_Dates table
 	 Update #Dashboard_Custom_Dates Set dashboard_day_to_run = dbo.fnServer_CmnConvertFromDBTime(dashboard_day_to_run,@InTimeZone)
 	 select * from #Dashboard_Custom_Dates for xml auto
 	 
 	 select * from #Dashboard_Datatable_Headers for xml auto
 	 select * from #Dashboard_Datatable_Presentation_Parameters for xml auto
 	 select * from #Dashboard_Day_Of_Week for xml auto
 	 
