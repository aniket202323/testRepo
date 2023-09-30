Create Procedure dbo.spDBR_Get_Report_Parameter_XML2
@report_id int = 2825
AS
 	 
 	 create table #ParamValues
 	 (
 	     value varchar(7000)
 	 )
 	 create table #Parameters
 	 (
 	  	 dashboard_template_parameter_id int,
 	  	 dashboard_template_parameter_name varchar(100),
 	  	 dashboard_parameter_type_Desc varchar(100),
 	  	 dashboard_parameter_data_Type varchar(100),
 	  	 dashboard_dialogue_name varchar(100),
 	  	 dashboard_parameter_type_id int,
 	  	 dashboard_dialogue_id int,
 	  	 dashboard_template_parameter_order int,
 	  	 has_default_value bit,
 	  	 value_Type int
/* 	  	 dashboard_icon_name varchar(100)
 	 */)
 	 
 	 declare @template_id int
 	 
 	 set @template_id = (select dashboard_template_id from dashboard_reports where dashboard_report_id = @report_id)
 	 insert into #Parameters (dashboard_template_parameter_id, dashboard_template_parameter_name, dashboard_parameter_type_desc, dashboard_parameter_data_type, dashboard_dialogue_name,dashboard_parameter_type_id, dashboard_dialogue_id, dashboard_template_parameter_order,has_default_value, value_type/*,dashboard_icon_name*/) 
 	 select tp.dashboard_template_parameter_id, 
 	  	  	 tp.dashboard_template_parameter_name, 
 	  	  	 type.dashboard_parameter_type_desc, 
 	  	  	 dt.dashboard_parameter_data_type, 
 	  	  	 case when isnumeric(dia.dashboard_dialogue_name) = 1 then (dbo.fnDBTranslate(N'0', dia.dashboard_dialogue_name, dia.dashboard_dialogue_name)) 
 	  	  	 else (dia.dashboard_dialogue_name)
 	  	  	 end as dashboard_dialogue_name,
 	  	  	 tp.dashboard_parameter_type_id, 
 	  	  	 dia.dashboard_dialogue_id, 
 	  	  	 tp.dashboard_template_parameter_order,
 	  	  	 tp.has_default_value,
 	  	  	 type.value_type/*,
 	  	  	 i.dashboard_icon_name*/
 	  	  	 
 	  	 from  dashboard_template_parameters tp, dashboard_parameter_data_types dt,
 	 dashboard_parameter_types type, dashboard_dialogues dia, dashboard_template_dialogue_parameters dtdp/*,
 	 dashboard_icons i*/
 	 where
 	  	 /*i.dashboard_icon_id = type.dashboard_icon_id
 	  	 and */type.dashboard_parameter_data_type_id = dt.dashboard_parameter_data_type_id 
 	  	 and tp.dashboard_parameter_type_id = type.dashboard_parameter_type_id 
 	  	 and tp.dashboard_template_parameter_id = dtdp.dashboard_template_parameter_id
 	  	 and dtdp.dashboard_dialogue_id = dia.dashboard_dialogue_id 
 	  	 and tp.dashboard_template_id = @template_id
 	 order by tp.dashboard_template_parameter_order
 	 
 	 select * from #Parameters order by dashboard_template_parameter_order
declare
  @@id int, @@query nvarchar(400)
Declare P_Cursor INSENSITIVE CURSOR
  For Select dashboard_template_parameter_id from #parameters order by dashboard_template_parameter_order
  For Read Only
  Open P_Cursor  
P_Loop:
  Fetch Next From P_Cursor Into @@id
  If (@@Fetch_Status = 0)
    Begin
 	  	 set @@query = 'spDBR_Get_Parameter_Value2 ' +  Convert(nvarchar(10),@@id)  + ',' + Convert(nvarchar(10),@report_id)
 	  	 declare @val varchar(7000)
     	 EXECUTE sp_executesql @@query
       Goto P_Loop
    End
Close P_Cursor 
Deallocate P_Cursor
select * from #paramvalues
drop table #parameters
GRANT  EXECUTE  ON [dbo].[spDBR_Get_Report_Parameter_XML2]  TO [comxclient]
