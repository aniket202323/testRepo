Create Procedure dbo.spDBR_Update_Schedule
@ScheduleID int,
@ReportID int,
@Frequencybit bit,
@Calendarbit bit,
@Eventbit bit,
@OnDemand bit
AS
 	 if (@ScheduleID = -1)
 	 begin
 	  	 insert into dashboard_schedule (Dashboard_Report_ID, Dashboard_Frequency_Based,Dashboard_Calendar_Based,Dashboard_Event_Based,Dashboard_On_Demand_Based,Dashboard_Last_Run_Time)  values (@ReportID, @Frequencybit, @Calendarbit, @EventBit, @OnDemand, dbo.fnServer_CmnGetDate(getutcdate()))
 	  	 set @ScheduleID = (select scope_identity())
 	 end
 	 else
 	 begin
 	  	 update dashboard_schedule set Dashboard_Frequency_Based = @Frequencybit, Dashboard_Calendar_Based = @Calendarbit, Dashboard_Event_Based = @Eventbit, Dashboard_On_Demand_Based=@OnDemand where dashboard_Schedule_id = @ScheduleID
 	 end
 	 
 	 select @ScheduleID as id
/* 	 return(@ScheduleID)
*/
