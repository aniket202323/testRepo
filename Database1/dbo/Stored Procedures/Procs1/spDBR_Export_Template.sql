Create Procedure dbo.spDBR_Export_Template
@template_id int = 80,
@locktemplates bit = 0
AS
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
 	 create table #Dashboard_Dialogue_Parameters
 	 (
 	  	 Dashboard_Dialogue_Parameter_ID int,
 	  	 Dashboard_Dialogue_ID int,
 	  	 Dashboard_Parameter_Type_Id int,
 	  	 Default_Dialogue bit
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
 	 create table #Dashboard_Parameter_Types
 	 (
 	  	 Dashboard_Parameter_Type_ID int,
 	  	 Dashboard_Parameter_Type_Desc varchar(100),
 	  	 Dashboard_Parameter_Data_Type_ID int,
 	  	 locked bit,
 	  	 Version int,
 	  	 Value_Type int 
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
 	 create table #Dashboard_Parameter_Default_Values
 	 (
 	  	 Dashboard_Parameter_Default_Value_ID int,
 	  	 Dashboard_Template_Parameter_ID int,
 	  	 Dashboard_Parameter_Row int,
 	  	 Dashboard_Parameter_Column int,
 	  	 Dashboard_Parameter_Value varchar(4000)
 	 )
 	 create table #Dashboard_Templates
 	 (
 	  	 Dashboard_Template_ID int,
 	  	 Dashboard_Template_Name varchar(100),
 	  	 Dashboard_Template_XSL_Filename varchar(100),
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
 	 declare @oldrowcount int
 	 set @oldrowcount = 0
 	 declare @newrowcount int
 	 
 	 insert into #Dashboard_Template_Links select dashboarD_template_link_id, dashboard_template_link_from, dashboard_template_link_to
 	  	 from dashboard_Template_links where Dashboard_Template_Link_From = @template_id
 	 set @newrowcount = (select count(dashboard_template_link_to) from #dashboard_template_links) 	 
 	 while (@newrowcount > @oldrowcount)
 	 begin
 	  	 set @oldrowcount = @newrowcount
 	  	 insert into #dashboard_template_links 
 	  	 (dashboard_template_link_id, dashboard_template_link_from, dashboard_template_link_to) 
 	  	 select dashboard_template_link_id, dashboard_template_link_from, dashboard_template_link_to 
 	  	  	 from dashboard_template_links where (not dashboard_template_link_from = @template_id) 
 	  	  	 and (not dashboard_template_link_from in 
 	  	  	  	 (select dashboard_template_link_from from #dashboard_Template_links))
 	  	  	 and (dashboard_template_link_from in
 	  	  	  	 (select dashboard_template_link_to from #dashboard_Template_links))
 	  	 set @newrowcount = (select count(dashboard_template_link_to) from #dashboard_template_links)
 	 end
 	 
 	 
 	 insert into #Dashboard_Templates select 	 Dashboard_Template_ID,Dashboard_Template_Name,Dashboard_Template_XSL_Filename, Dashboard_Template_Preview_Filename,
 	  	 Dashboard_Template_Build,Dashboard_Template_Locked,Dashboard_Template_Launch_Type, 	 
 	  	 Dashboard_Template_Procedure,Dashboard_Template_Size_Unit,Dashboard_Template_Description, 	 
 	  	 Dashboard_Template_Column,Dashboard_Template_Column_Position,Dashboard_Template_Has_Frame,Dashboard_Template_Expanded,Dashboard_Template_Allow_Remove,Dashboard_Template_Allow_Minimize,Dashboard_Template_Cache_Code,Dashboard_Template_Cache_Timeout,Dashboard_Template_Detail_Link,Dashboard_Template_Help_Link,version,Height, 	 Width,type, dashboard_template_fixed_height, dashboard_template_fixed_width, basetemplate 
 	  	  	 from dashboard_templates
 	  	 where dashboard_template_id in (select distinct(dashboard_template_link_to) from #dashboard_template_links)
 	  	 set @newrowcount = (select count(dashboard_Template_link_id) from #dashboard_template_links where dashboard_Template_link_to = @template_id)
 	  	 
 	  	 if (@newrowcount = 0)
 	  	 begin
 	 insert into #Dashboard_Templates select 	 Dashboard_Template_ID,Dashboard_Template_Name,Dashboard_Template_XSL_Filename, Dashboard_Template_Preview_Filename,
 	  	 Dashboard_Template_Build,Dashboard_Template_Locked,Dashboard_Template_Launch_Type, 	 
 	  	 Dashboard_Template_Procedure,Dashboard_Template_Size_Unit,Dashboard_Template_Description, 	 
 	  	 Dashboard_Template_Column,Dashboard_Template_Column_Position,Dashboard_Template_Has_Frame,Dashboard_Template_Expanded,Dashboard_Template_Allow_Remove,Dashboard_Template_Allow_Minimize,Dashboard_Template_Cache_Code,Dashboard_Template_Cache_Timeout,Dashboard_Template_Detail_Link,Dashboard_Template_Help_Link,version,Height, 	 Width,type, dashboard_template_fixed_height, dashboard_template_fixed_width, basetemplate 
 	  	  	 from dashboard_templates
 	  	  	 where dashboard_template_id = @template_id
 	  	 end
 	 update #dashboard_templates set dashboard_template_xsl_filename = '[UNPROCESSED TEMPLATE IMPORT]' + dashboard_template_xsl_filename
 	 update #dashboard_templates set dashboard_template_preview_filename = '[UNPROCESSED TEMPLATE IMPORT]' + dashboard_template_preview_filename
 	 insert into #Dashboard_Template_Parameters select p.dashboard_template_parameter_id, p.dashboard_template_id, p.dashboard_template_parameter_order, 
 	  	 p.dashboard_parameter_type_id, p.dashboard_template_parameter_name, p.has_default_value, p.allow_nulls
 	  	  from dashboard_template_parameters p, #dashboard_templates t where p.dashboard_template_id = t.dashboard_template_id
 	 insert into #Dashboard_Parameter_Default_Values select v.dashboard_parameter_default_value_id, v.dashboard_template_parameter_id, v.dashboard_parameter_row,
 	  	  	 v.dashboard_parameter_column, v.dashboard_parameter_value 
 	 from dashboard_parameter_default_values v, #dashboard_template_parameters p where v.dashboard_template_parameter_id = p.dashboard_template_parameter_id
 	 
 	 
 	 insert into #Dashboard_Template_Dialogue_Parameters select dp.dashboard_template_dialogue_parameter_id, dp.dashboard_dialogue_id, dp.dashboard_template_parameter_id
 	  from dashboard_template_dialogue_parameters dp, #dashboard_template_parameters p where dp.dashboard_template_parameter_id = p.dashboard_template_parameter_id
 	  	 
 	 insert into #Dashboard_Parameter_Types select dashboard_parameter_type_id, dashboard_parameter_type_desc, dashboard_parameter_data_type_id,
 	  	 locked, version, value_Type from dashboard_parameter_types pt where pt.dashboard_parameter_type_id in (select distinct(dashboard_parameter_type_id) from #dashboard_template_parameters)
 	 insert into #Dashboard_Parameter_Data_Types select dashboard_parameter_data_type_id, dashboard_parameter_data_type 
 	  	 from dashboard_parameter_data_types dt where dt.dashboard_parameter_data_type_id in (select distinct(dashboard_parameter_data_type_id) from #dashboard_parameter_types)
 	  	 
 	 
 	 insert into #Dashboard_DataTable_Headers select dth.dashboard_datatable_header_id, dth.dashboard_parameter_type_id, dth.dashboard_datatable_column, dth.dashboard_datatable_header,
 	  	 dth.dashboard_datatable_presentation, dth.dashboard_datatable_column_sp 
 	  	 from dashboard_datatable_headers dth, #dashboard_parameter_types pt where dth.dashboard_parameter_type_id = pt.dashboard_parameter_type_id
 	 insert into #dashboard_datatable_presentation_parameters select dtpp.dashboard_datatable_presentation_parameter_id, dtpp.dashboard_datatable_header_id,
 	  	 dtpp.dashboard_datatable_presentation_parameter_order, dtpp.dashboard_datatable_presentation_parameter_input 
 	  	 from dashboard_datatable_presentation_parameters dtpp, #dashboard_datatable_headers dh where dtpp.dashboard_datatable_header_id = dh.dashboard_datatable_header_id
 	 
 	 
 	 
 	 insert into #dashboard_dialogue_parameters 
 	  	 select ddp.dashboard_dialogue_parameter_id, ddp.dashboard_dialogue_id, ddp.dashboard_parameter_type_id, ddp.default_Dialogue 
 	 from dashboard_dialogue_parameters ddp, #dashboard_parameter_types dpt where ddp.dashboard_parameter_type_id = dpt.dashboard_parameter_type_id
 	 insert into #dashboard_dialogues select dashboard_dialogue_id, dashboard_dialogue_name, external_address, url, parameter_count, locked, Version from dashboard_dialogues
 	  	 where dashboard_dialogue_id in (select distinct(dashboard_dialogue_id) from #dashboard_dialogue_parameters)
 	 if (@locktemplates = 1)
 	 begin
 	  	 update #dashboard_templates set dashboard_template_locked = @locktemplates
 	 end
 	 select * from #Dashboard_Template_Links for xml auto
 	 select * from #Dashboard_Templates for xml auto
 	 select * from #Dashboard_Template_Parameters for xml auto
 	 select * from #Dashboard_Parameter_Default_Values for xml auto
 	 select * from #Dashboard_Template_Dialogue_Parameters for xml auto
 	 select * from #Dashboard_Parameter_Types for xml auto
 	 select * from #Dashboard_Parameter_Data_Types for xml auto
 	 select * from #Dashboard_Datatable_Headers for xml auto
 	 select * from #Dashboard_Datatable_Presentation_Parameters for xml auto
 	 select * from #Dashboard_Dialogue_Parameters for xml auto
 	 select * from #Dashboard_Dialogues for xml auto
/*
 	 select * from #dashboard_template_links 
 	 select * from #dashboard_templates 
 	 select * from #dashboard_template_parameters 
 	 select * from #dashboard_parameter_default_values 
 	 select * from #dashboard_template_dialogue_parameters 
 	 select * from #dashboard_parameter_types 
 	 select * from #dashboard_parameter_data_types 
 	 select * from #dashboard_datatable_headers 
 	 select * from #dashboard_datatable_presentation_parameters 
 	 select * from #dashboard_dialogue_parameters 
 	 select * from #dashboard_dialogues 
*/
