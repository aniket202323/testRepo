Create Procedure dbo.spDBR_Export_Database_Template_Attributes
AS
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
 	 insert into #Dashboard_Template_Parameters select dashboard_template_parameter_id, dashboard_template_id, dashboard_template_parameter_order, 
 	  	 dashboard_parameter_type_id, dashboard_template_parameter_name, has_default_value, allow_nulls from dashboard_template_parameters
 	 insert into #Dashboard_Template_Links select dashboarD_template_link_id, dashboard_template_link_from, dashboard_template_link_to
 	  	 from dashboard_template_links
 	 insert into #Dashboard_Template_Dialogue_Parameters select dashboard_template_dialogue_parameter_id, dashboard_dialogue_id, dashboard_template_parameter_id
 	  	 from dashboard_template_dialogue_parameters
 	 insert into #Dashboard_Parameter_Default_Values select dashboard_parameter_default_value_id, dashboard_template_parameter_id, dashboard_parameter_row,
 	  	  	 dashboard_parameter_column, dashboard_parameter_value from dashboard_parameter_default_values
 	 select * from #Dashboard_Template_Parameters for xml auto
 	 select * from #Dashboard_Template_Links for xml auto
 	 select * from #Dashboard_Template_Dialogue_Parameters for xml auto 	 
 	 select * from #Dashboard_Parameter_Default_Values for xml auto 	 
