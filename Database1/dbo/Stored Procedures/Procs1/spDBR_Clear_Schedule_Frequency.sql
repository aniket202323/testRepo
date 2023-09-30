Create Procedure dbo.spDBR_Clear_Schedule_Frequency
@ScheduleID int
AS
 	 delete from dashboard_schedule_Frequency where dashboard_schedule_id = @scheduleid
