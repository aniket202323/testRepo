Create Procedure dbo.spDBR_Get_Report_Parameter_XML
@report_id int,
@languageid int = 0,
@relativedate datetime = null,
@InTimeZone 	  	 varchar(200) = NULL  ---23/08/2010 - Ex: 'India Standard Time','Central Stardard Time' 
AS
 	 ---24/08/2010 - Conversion of datetime into UTC e.g. India Standard Time','Central Stardard Time'
 	  
 	  	 --SELECT @relativedate = dbo.fnServer_CmnConvertToDBTime(@relativedate,@InTimeZone)
 	  
 	 --if (@relativedate is null)
 	 --begin
 	 -- 	 set @relativedate = dbo.fnServer_CmnGetDate(getutcdate())
 	 --end
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
 	 insert into #Parameters (dashboard_template_parameter_id, dashboard_template_parameter_name, dashboard_parameter_type_desc, dashboard_parameter_data_type, 
 	 dashboard_dialogue_name,
 	 dashboard_parameter_type_id, dashboard_dialogue_id, dashboard_template_parameter_order,has_default_value, value_type/*,dashboard_icon_name*/) 
 	 select tp.dashboard_template_parameter_id, 
 	  	  	 tp.dashboard_template_parameter_name, 
 	  	  	 type.dashboard_parameter_type_desc, 
 	  	  	 dt.dashboard_parameter_data_type, 
 	  	  	 case when isnumeric(dia.dashboard_dialogue_name) = 1 then (dbo.fnDBTranslate(@languageid, dia.dashboard_dialogue_name, dia.dashboard_dialogue_name)) 
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
 	 
 	 
 	 -- Bug # 24247: Error popping up while editing and viewing a web part.
 	 -- removed the TargetTimezoneId Hard coded value and getting the timezone value based on the description.
 	 
 	 declare @timezoneid int
 	 select distinct @timezoneid = dashboard_template_parameter_id From #Parameters where dashboard_parameter_type_desc = '38517' --and dashboard_parameter_type_id=35 --TargetTimeZoneID
 	  
 	 select @InTimeZone = dashboard_parameter_value from dashboard_parameter_values 
 	 where dashboard_template_parameter_id =@timezoneid 
 	 and dashboard_report_id = @report_id
 	  
 	 if (@relativedate is null)
 	 begin
 	  	 set @relativedate = dbo.fnServer_CmnGetDate(getutcdate())
 	 end 
 	 select * from #Parameters order by dashboard_template_parameter_order
 	 declare
  @@id int, @@query nvarchar(700)
Declare P_Cursor INSENSITIVE CURSOR
  For Select dashboard_template_parameter_id from #parameters order by dashboard_template_parameter_order
  For Read Only
  Open P_Cursor  
P_Loop:
  Fetch Next From P_Cursor Into @@id
  If (@@Fetch_Status = 0)
    Begin
 	  	 PRINT @@id
 	  	 set @@query = 'spDBR_Get_Parameter_Value2 ' +  Convert(nvarchar(10),@@id)  + ',' + Convert(nvarchar(10),@report_id) + ',' + char(39) +  convert(nvarchar(100), @relativedate) + char(39)+ ','+ char(39) + convert(nvarchar(200),@InTimeZone) + char(39)
 	  	 PRINT @@query
     	 EXECUTE sp_executesql @@query
       Goto P_Loop
    End
Close P_Cursor 
Deallocate P_Cursor
drop table #parameters
