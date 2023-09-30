Create Procedure dbo.spDBR_Clear_Schedule_Events
@ScheduleID int
AS
 	 delete from dashboard_schedule_Events where dashboard_schedule_id = @scheduleid
