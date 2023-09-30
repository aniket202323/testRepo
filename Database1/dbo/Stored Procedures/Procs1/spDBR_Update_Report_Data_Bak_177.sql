Create Procedure dbo.[spDBR_Update_Report_Data_Bak_177]
@ReportID int,
@RunTime datetime,
@XML   text,
@InTimeZone 	  	 varchar(200) = NULL  ---23/08/2010 - Ex: 'India Standard Time','Central Stardard Time' 
AS
declare @MaxVersions int
declare @CurrentVersions int
declare @ThisVersion int
declare @ReportTitle varchar(100)
DECLARE @ptrval binary(16)
 	 ---24/08/2010 - Conversion of datetime into UTC e.g. India Standard Time','Central Stardard Time'
 	  
 	  	 SELECT @RunTime = dbo.fnServer_CmnConvertToDBTime(@RunTime,@InTimeZone)
 	  
select @MaxVersions =  (select Dashboard_report_Version_Count from dashboard_reports where dashboard_report_id = @ReportID)
select @CurrentVersions = (select count(Dashboard_Report_Data_ID) from Dashboard_Report_Data where Dashboard_Report_ID = @ReportID)
select @ReportTitle = (Select dashboard_report_name from dashboard_reports where dashboard_report_id = @reportid)
if (@CurrentVersions < @MaxVersions)
begin
 	 if (@CurrentVersions = 0) 
 	 begin
 	  	 insert into dashboard_report_data (Dashboard_report_id, dashboard_time_stamp, dashboard_report_version, dashboard_report_display_name, dashboard_report_xml) 
 	  	  	 values (@ReportID, @RunTime, 1, @ReportTitle, @XML)
 	  	  	 SELECT @ptrval = TEXTPTR(dashboard_report_xml) FROM dashboard_report_data WHERE dashboard_report_id = @reportid and dashboard_time_stamp = @runtime and dashboard_report_version = 1
 	  	  	 WRITETEXT dashboard_report_Data.dashboard_report_xml @ptrval @xml
 	  	 update dashboard_schedule set dashboard_last_run_time = @RunTime where dashboard_report_id = @ReportID and dashboard_last_run_time < @RunTime
 	 end
 	 else
 	 begin
 	  	 set @ThisVersion = (select min(dashboard_report_version) from dashboard_report_data where dashboard_time_stamp < @RunTime)
 	  	 
 	  	 if (@ThisVersion is null)
 	  	 begin
 	  	  	 set @ThisVersion = @CurrentVersions + 1
 	  	 end
 	  	 
 	  	 While (@CurrentVersions >= @ThisVersion)
 	  	 begin 	  	  	 
 	  	  	 update dashboard_report_Data set dashboard_report_version = @CurrentVersions + 1, dashboard_report_display_name = @ReportTitle where dashboard_report_id = @ReportID and dashboard_report_Version = @CurrentVersions  	 
 	  	  	 set @CurrentVersions = (@CurrentVersions -1)
 	  	 end
 	  	  	 insert into dashboard_report_data (Dashboard_report_id, dashboard_time_stamp, dashboard_report_version, dashboard_report_display_name, dashboard_report_xml) 
 	  	  	 values (@ReportID, @RunTime, @ThisVersion, @ReportTitle, @XML)
 	  	  	 SELECT @ptrval = TEXTPTR(dashboard_report_xml) FROM dashboard_report_data WHERE dashboard_report_id = @reportid and dashboard_time_stamp = @runtime and dashboard_report_version = @thisversion
 	  	  	 WRITETEXT dashboard_report_Data.dashboard_report_xml @ptrval @xml
 	  	  	 update dashboard_schedule set dashboard_last_run_time = @RunTime where dashboard_report_id = @ReportID and dashboard_last_run_time < @RunTime
 	 end
end
else  /*we are storing the max amount of versions and must find location of next insert*/
begin
 	 set @ThisVersion = (select min(dashboard_report_version) from dashboard_report_data where dashboard_time_stamp < @RunTime)
 	 if (not @ThisVersion is null)
 	 begin
 	  	 delete from dashboard_report_Data where dashboard_report_id = @reportID and dashboard_report_version = @MaxVersions
 	  	 While (@CurrentVersions >= @ThisVersion)
 	  	 begin 	  	  	 
 	  	  	 update dashboard_report_Data set dashboard_report_version = @CurrentVersions + 1, dashboard_report_display_name = @ReportTitle where dashboard_report_id = @ReportID and dashboard_report_Version = @CurrentVersions  	 
 	  	  	 set @CurrentVersions = (@CurrentVersions -1)
 	  	 end
 	  	  	 insert into dashboard_report_data (Dashboard_report_id, dashboard_time_stamp, dashboard_report_version, dashboard_report_display_name, dashboard_report_xml) 
 	  	  	 values (@ReportID, @RunTime, @ThisVersion, @ReportTitle, @XML)
 	  	  	 SELECT @ptrval = TEXTPTR(dashboard_report_xml) FROM dashboard_report_data WHERE dashboard_report_id = @reportid and dashboard_time_stamp = @runtime and dashboard_report_version = @thisversion
 	  	  	 WRITETEXT dashboard_report_Data.dashboard_report_xml @ptrval @xml
 	  	  	 update dashboard_schedule set dashboard_last_run_time = @RunTime where dashboard_report_id = @ReportID and dashboard_last_run_time < @RunTime
 	 end
end
 	 declare @ScheduleID int
 	 select @ScheduleID = (select dashboard_schedule_id from dashboard_schedule where dashboard_report_id = @ReportID)
 	 update dashboard_custom_Dates set dashboard_completed = 1 where dashboard_calendar_id = 
 	 (select dashboard_calendar_id from dashboard_calendar where dashboard_schedule_id = @ScheduleID) and datediff(mi, dashboard_day_to_run, @RunTime) = 0
