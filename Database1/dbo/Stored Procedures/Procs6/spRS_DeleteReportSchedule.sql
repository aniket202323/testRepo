-----------------------------------------------------------------
-- This stored procedure is used by the following applications:
-- ProficyRPTAdmin
-- ProficyRPTEngine
-- Edit the master document in VSS project: ProficyRPTAdmin
-----------------------------------------------------------------
CREATE PROCEDURE dbo.spRS_DeleteReportSchedule
@Schedule_Id int
AS
Declare @Report_Id int
Declare @MyError int
Declare @OldClass int
Select @MyError = 0
Begin Transaction
Select @Report_Id = Report_Id
  From Report_Schedule
  Where Schedule_Id = @Schedule_Id
Delete from report_que
   where schedule_Id = @Schedule_Id
If @@Error <> 0 
  Select @MyError = 1
Delete from report_schedule
  where Schedule_Id = @Schedule_Id
If @@Error <> 0 
  Select @MyError = 2
-- Get the Existing Class
Select @OldClass = Class
From Report_Definitions
Where Report_Id = @Report_Id
If @OldClass Is Null
  Select @OldClass = 0  -- No Class
Else If @OldClass = 1   -- AdHoc Web Request
  Select @OldClass = 0  -- No Class
Else If @OldClass = 2   -- Scheduled Report
  Select @OldClass = 3  -- Definition
Update Report_Definitions
  Set Class = @OldClass,
  Priority = 1
  Where Report_Id = @Report_Id
If @@Error <> 0 
  Select @MyError = 3
Update Report_Tree_Nodes
  Set Node_Id_Type = 7
  Where Report_Def_Id = @Report_Id
If @@Error <> 0 
  Select @MyError = 4
If @MyError = 0
  Begin
    Commit Transaction
    Return (0)
  End
Else
  Begin
    RollBack Transaction
    Return @MyError
  End
