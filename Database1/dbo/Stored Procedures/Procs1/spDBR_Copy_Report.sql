Create Procedure dbo.spDBR_Copy_Report
@reportid int,
@reportname varchar(100)
AS 	 
declare @localName varchar(100)
declare @version int
declare @localTemp int
select @localTemp = Dashboard_Template_Id from Dashboard_Reports where Dashboard_Report_ID = @reportid
select @version = max(version) + 1 from Dashboard_Reports where Dashboard_Report_Name = @reportname and Dashboard_Template_ID = @localTemp 	 
if (@version is null)
begin
 	 set @version = 1
end
 	 insert into dashboard_reports (Dashboard_Report_Name, Dashboard_Template_Id, Dashboard_Report_Version_Count,
 	  	  	  	  	  	  	  	  	 Dashboard_Report_Ad_Hoc_Flag, Dashboard_Session_Id, Dashboard_Report_Security_Group_ID, 
 	  	  	  	  	  	  	  	  	 Dashboard_Report_Server, Dashboard_Report_Number_Hits, Dashboard_Report_Description,
 	  	  	  	  	  	  	  	  	 Dashboard_Report_Create_Date, Dashboard_Report_Column, Dashboard_Report_Column_Position,
 	  	  	  	  	  	  	  	  	 Dashboard_Report_Has_Frame, Dashboard_Report_Expanded, Dashboard_Report_Allow_Remove,
 	  	  	  	  	  	  	  	  	 Dashboard_Report_Allow_Minimize, Dashboard_Report_Cache_Code, Dashboard_Report_Cache_Timeout,
 	  	  	  	  	  	  	  	  	 Dashboard_Report_Detail_Link, Dashboard_Report_Help_Link, Version) 
 	  	  	  	  	  	  	  	  	 select @reportname, Dashboard_Template_Id, Dashboard_Report_Version_Count,
 	  	  	  	  	  	  	  	  	 Dashboard_Report_Ad_Hoc_Flag, Dashboard_Session_Id, Dashboard_Report_Security_Group_ID, 
 	  	  	  	  	  	  	  	  	 Dashboard_Report_Server, Dashboard_Report_Number_Hits, Dashboard_Report_Description,
 	  	  	  	  	  	  	  	  	 Dashboard_Report_Create_Date, Dashboard_Report_Column, Dashboard_Report_Column_Position,
 	  	  	  	  	  	  	  	  	 Dashboard_Report_Has_Frame, Dashboard_Report_Expanded, Dashboard_Report_Allow_Remove,
 	  	  	  	  	  	  	  	  	 Dashboard_Report_Allow_Minimize, Dashboard_Report_Cache_Code, Dashboard_Report_Cache_Timeout,
 	  	  	  	  	  	  	  	  	 Dashboard_Report_Detail_Link, Dashboard_Report_Help_Link, @version 
 	  	  	  	  	  	  	  	  	 from dashboard_reports where dashboard_report_id = @reportid
 	  	  	  	  	  	  	  	  	 
 	 declare @newreportid int
 	 set @newreportid = (select scope_identity())
 	 
 	 insert into dashboard_parameter_values (Dashboard_Report_ID, Dashboard_Template_Parameter_ID, Dashboard_Parameter_Value,
 	  	  	  	  	  	  	  	  	  	  	 Dashboard_Parameter_Column, Dashboard_Parameter_Row)
 	  	  	  	  	  	  	  	  	  	  	 select @newreportid, dashboard_template_parameter_id, dashboard_parameter_value, dashboard_parameter_column,
 	  	  	  	  	  	  	  	  	  	  	 dashboard_parameter_row from dashboard_parameter_values where
 	  	  	  	  	  	  	  	  	  	  	 dashboard_report_id = @reportid
 	 
 	 insert into dashboard_report_links (dashboard_template_link_id, dashboard_report_from_id, dashboard_report_to_id)
 	  	 select dashboard_template_link_id, @newreportid, dashboard_report_to_id from dashboard_report_links where dashboard_report_from_id = @reportid
 	 insert into dashboard_schedule (dashboard_report_id, dashboard_frequency_based, dashboard_calendar_based, dashboard_event_based, dashboard_on_demand_based, dashboard_last_run_time)
 	  	 select @newreportid, dashboard_frequency_based, dashboard_calendar_based, dashboard_event_based, dashboard_on_demand_based, dashboard_last_run_time
 	  	  	 from dashboard_schedule where dashboard_report_id = @reportid
 	  	  	  	  	 
 	 declare @newscheduleid int
 	 declare @scheduleid int
 	 set @newscheduleid = (select scope_identity())
 	 set @scheduleid = (select dashboard_schedule_id from dashboard_schedule where dashboard_report_id = @reportid)
 	 
 	 insert into dashboard_schedule_events (dashboard_schedule_id, dashboard_event_scope_id, dashboard_event_type_id, pu_id, var_id)
 	  	 select @newscheduleid, dashboard_event_scope_id, dashboard_event_type_id, pu_id, var_id
 	  	  	 from dashboard_schedule_events where dashboard_schedule_id = @scheduleid
 	 insert into dashboard_schedule_frequency (dashboard_schedule_id, dashboard_frequency_base_time, dashboard_frequency, dashboard_frequency_type_id)
 	  	 select @newscheduleid, dashboard_frequency_base_time, dashboard_frequency, dashboard_frequency_type_id
 	  	  	 from dashboard_schedule_Frequency where dashboard_schedule_id = @scheduleid
 	  	  	  	  	  	 
 	 insert into dashboard_calendar (dashboard_schedule_id, dashboard_first_of_month, dashboard_last_of_month, dashboard_first_of_quarter,
 	  	  	  	  	  	  	  	  	 dashboard_last_of_quarter, dashboard_first_of_year, dashboard_last_of_year, dashboard_day_of_week,
 	  	  	  	  	  	  	  	  	 dashboard_custom_date)
 	  	 select @newscheduleid, dashboard_first_of_month, dashboard_last_of_month, dashboard_first_of_quarter, dashboard_last_of_quarter,
 	  	  	  	 dashboard_first_of_year, dashboard_last_of_year, dashboard_day_of_week, dashboard_custom_date
 	  	  	 from dashboard_calendar where dashboard_schedule_id =@scheduleid
 	 
 	 declare @newcalendarid int, @calendarid int
 	 set @newcalendarid = (select scope_identity())
 	 set @calendarid = (select dashboard_calendar_id from dashboard_calendar where dashboard_schedule_id = @scheduleid)
 	 insert into dashboard_day_of_week (dashboard_calendar_id, dashboard_day_of_week) 
 	  	 select @newcalendarid, dashboard_day_of_week
 	  	  	 from dashboard_day_of_week where dashboard_calendar_id = @calendarid
 	  	  	 
 	 
 	 insert into dashboard_custom_dates (dashboard_calendar_id, dashboard_day_to_run, dashboard_completed)
 	  	 select @newcalendarid, dashboard_day_to_run, dashboard_completed from dashboard_custom_dates 
 	  	  	 where dashboard_calendar_id = @calendarid
select @newreportid as id
