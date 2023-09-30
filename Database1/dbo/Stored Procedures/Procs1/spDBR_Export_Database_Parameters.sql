Create Procedure dbo.spDBR_Export_Database_Parameters
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
 	 insert into #Dashboard_Parameter_Types select dashboard_parameter_type_id, dashboard_parameter_type_desc, dashboard_parameter_data_type_id,
 	  	 locked, version, value_Type from dashboard_parameter_types
 	 insert into #Dashboard_Parameter_Data_Types select dashboard_parameter_data_type_id, dashboard_parameter_data_type from dashboard_parameter_data_types
 	 insert into #dashboard_dialogues select dashboard_dialogue_id, dashboard_dialogue_name, external_address, url, parameter_count, locked, Version from dashboard_dialogues
 	 insert into #dashboard_dialogue_parameters select dashboard_dialogue_parameter_id, dashboard_dialogue_id, dashboard_parameter_type_id, default_Dialogue from dashboard_dialogue_parameters
 	 insert into #Dashboard_DataTable_Headers select dashboard_datatable_header_id, dashboard_parameter_type_id, dashboard_datatable_column, dashboard_datatable_header,
 	  	 dashboard_datatable_presentation, dashboard_datatable_column_sp from dashboard_datatable_headers
 	 insert into #dashboard_datatable_presentation_parameters select dashboard_datatable_presentation_parameter_id, dashboard_datatable_header_id,
 	  	 dashboard_datatable_presentation_parameter_order, dashboard_datatable_presentation_parameter_input from dashboard_datatable_presentation_parameters
 	  	 
 	 select * from #Dashboard_Parameter_Types for xml auto
 	 select * from #Dashboard_Parameter_Data_Types for xml auto
 	 select * from #Dashboard_Dialogues for xml auto
 	 select * from #Dashboard_Dialogue_Parameters for xml auto
 	 select * from #Dashboard_Datatable_Headers for xml auto
 	 select * from #Dashboard_Datatable_Presentation_Parameters for xml auto
 	 
