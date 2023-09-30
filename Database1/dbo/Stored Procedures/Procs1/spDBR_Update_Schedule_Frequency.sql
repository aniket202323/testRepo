Create Procedure dbo.spDBR_Update_Schedule_Frequency
@ScheduleID int,
@RefreshInterval int,
@IntervalType int,
@RelativeTime datetime,
@InTimeZone 	  	 varchar(200) = ''  ---23/08/2010 - Ex: 'India Standard Time','Central Stardard Time' 
AS
 	 declare @count int
 	 set @count = (select count(*) from dashboard_schedule_frequency where dashboard_schedule_id = @scheduleid)
 	 
 	 ---24/08/2010 - Conversion of datetime into UTC e.g. India Standard Time','Central Stardard Time'
 	  
 	  	 SELECT @RelativeTime = dbo.fnServer_CmnConvertToDBTime(@RelativeTime,@InTimeZone)
 	  
 	 if (@count = 0)
 	 begin
 	  	 insert into dashboard_schedule_frequency (Dashboard_Schedule_ID,Dashboard_Frequency_Base_Time,Dashboard_Frequency,Dashboard_Frequency_Type_ID) values (@scheduleid, @RelativeTime, @RefreshInterval, @IntervalType)
 	 end
 	 else
 	 begin
 	  	 update dashboard_schedule_frequency set dashboard_frequency_base_time = @RelativeTime, dashboard_Frequency = @RefreshInterval, dashboard_frequency_type_id = @intervaltype where dashboard_schedule_id = @scheduleid
 	 end
 	 
