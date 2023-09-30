Create Procedure dbo.spDBR_Get_System_Resource_Stats
@starttime datetime,
@endtime datetime,
@statcode int,
@InTimeZone 	  	 varchar(200) = NULL  ---23/08/2010 - Ex: 'India Standard Time','Central Stardard Time' 
AS
 	 ---24/08/2010 - Conversion of datetime into UTC e.g. India Standard Time','Central Stardard Time'
 	  
 	  	 SELECT @starttime = dbo.fnServer_CmnConvertToDBTime(@starttime,@InTimeZone)
 	  	 SELECT @endtime = dbo.fnServer_CmnConvertToDBTime(@endtime,@InTimeZone)
 	  
 	 
declare @count int
set @count = (select count(dashboard_resource_log_time) from dashboard_content_generator_resource_usage where Dashboard_Resource_Log_Time >= @starttime and Dashboard_Resource_Log_Time <= @endtime)
if @statcode = 1
begin
select @count as NumRows, Dashboard_Resource_Log_Time, Dashboard_CG_Virtual_Memory as StatValue from Dashboard_Content_Generator_Resource_Usage where Dashboard_Resource_Log_Time >= @starttime and Dashboard_Resource_Log_Time <= @endtime order by Dashboard_Resource_Log_Time
end
if @statcode = 2
begin
select @count as NumRows, Dashboard_Resource_Log_Time, Dashboard_CG_Virtual_Memory_Peak as StatValue from Dashboard_Content_Generator_Resource_Usage where Dashboard_Resource_Log_Time >= @starttime and Dashboard_Resource_Log_Time <= @endtime order by Dashboard_Resource_Log_Time
end
if @statcode = 3
begin
select @count as NumRows, Dashboard_Resource_Log_Time, Dashboard_CG_Private_Memory as StatValue from Dashboard_Content_Generator_Resource_Usage where Dashboard_Resource_Log_Time >= @starttime and Dashboard_Resource_Log_Time <= @endtime order by Dashboard_Resource_Log_Time
end
if @statcode = 4
begin
select @count as NumRows, Dashboard_Resource_Log_Time, Dashboard_CG_PageFaults_per_sec as StatValue from Dashboard_Content_Generator_Resource_Usage where Dashboard_Resource_Log_Time >= @starttime and Dashboard_Resource_Log_Time <= @endtime order by Dashboard_Resource_Log_Time
end
if @statcode = 5
begin
select @count as NumRows, Dashboard_Resource_Log_Time, Dashboard_cg_cpu_usage as StatValue from Dashboard_Content_Generator_Resource_Usage where Dashboard_Resource_Log_Time >= @starttime and Dashboard_Resource_Log_Time <= @endtime order by Dashboard_Resource_Log_Time
end
if @statcode = 6
begin
select @count as NumRows, Dashboard_Resource_Log_Time, Dashboard_cg_thread_count as StatValue from Dashboard_Content_Generator_Resource_Usage where Dashboard_Resource_Log_Time >= @starttime and Dashboard_Resource_Log_Time <= @endtime order by Dashboard_Resource_Log_Time
end
if @statcode = 7
begin
select @count as NumRows, Dashboard_Resource_Log_Time, Dashboard_CG_Handle_Count as StatValue from Dashboard_Content_Generator_Resource_Usage where Dashboard_Resource_Log_Time >= @starttime and Dashboard_Resource_Log_Time <= @endtime order by Dashboard_Resource_Log_Time
end
