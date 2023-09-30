CREATE PROCEDURE dbo.spRS_ReportRunFailed
@Schedule_Id int,
@Fail_Code int
AS
-- Set the Schedule record to failed
Update Report_Schedule
  Set Last_Result = @Fail_Code,  
      Status = 4
  Where Schedule_Id = @Schedule_Id
-- Remove the report from the que
delete from Report_Que
  where Schedule_Id = @Schedule_Id
