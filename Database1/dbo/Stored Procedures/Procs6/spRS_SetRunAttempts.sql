CREATE PROCEDURE dbo.spRS_SetRunAttempts
@Schedule_Id int,
@Attempts int
AS
Update Report_Schedule
  Set Run_Attempts = @Attempts
  Where Schedule_Id = @Schedule_Id
