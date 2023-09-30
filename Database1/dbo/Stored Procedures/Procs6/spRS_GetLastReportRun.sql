CREATE PROCEDURE dbo.spRS_GetLastReportRun
@Schedule_Id int
 AS
Select * from Report_Runs
Where Run_Id = (
  Select Max(Run_Id)
  From Report_Runs
  Where Schedule_Id = @Schedule_Id)
