CREATE PROCEDURE dbo.spRS_UpdateReportSchedule
@Schedule_Id int,
@Start_Date_Time datetime,
@Interval int
 AS
Update Report_Schedule
  Set Start_Date_Time = @Start_Date_Time,
      Next_Run_Time = @Start_Date_Time,
      Last_Run_Time = @Start_Date_Time,
      Interval = @Interval
  Where Schedule_Id = @Schedule_Id
