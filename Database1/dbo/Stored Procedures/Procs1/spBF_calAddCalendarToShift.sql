CREATE PROCEDURE dbo.spBF_calAddCalendarToShift
        @ShiftId integer,
        @calendarId integer,
 	  	 @UserId Int = 1
AS
BEGIN
 	 -- SET NOCOUNT ON added to prevent extra result sets from
 	 -- interfering with SELECT statements.
 	 SET NOCOUNT ON;
 	 IF @UserId Is Null SET @UserId = 1
 	 IF NOT EXISTS (SELECT TOP 1 * FROM Shifts_Crew_schedule_mapping WHERE Shift_Id = @ShiftId and Crew_Schedule_Id = @calendarId)
 	 BEGIN
 	  	 insert into Shifts_Crew_schedule_mapping (Shift_Id,Crew_Schedule_Id) values (@ShiftId,@calendarId);
 	  	 SELECT 'Success'
 	 END
END
