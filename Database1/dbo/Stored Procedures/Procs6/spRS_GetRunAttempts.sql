CREATE PROCEDURE dbo.spRS_GetRunAttempts
@Schedule_Id int,
@Attempts int output
AS
  Select @Attempts = Run_Attempts
  From Report_Schedule
  Where Schedule_Id = @Schedule_Id
