/* This SP used by Report Server V2 */
CREATE PROCEDURE dbo.spRS_AddReport_Schedule
@Report_Id int,
@Start_Date_Time datetime,
@Interval int,
@Next_Run_Time datetime,
@Last_Run_Time datetime,
@Status int,
@Last_Result int,
@Class int,
@Row_Id int output
 AS
Declare @Exists int
Select @Exists = Report_Id
  From Report_Schedule
  Where Report_Id = @Report_Id
If @Exists Is Null
  Begin
    If @Class = 1
      Begin
 	 -- Class 1 is an immediate request from the web
        Select @Next_Run_Time = GetDate()
 	 Select @Last_Run_Time = dateadd(day, -2,  GetDate())
 	 -- These requests should always be run first High Priority
 	 Update Report_Definitions
 	 Set Priority = 2 
 	 Where Report_Id = @Report_Id
      End
    -- Priority is set back to 1 in spRS_DeleteReportSchedule
    -- UPdate the report_definition Priority to 2
    Insert Into Report_Schedule(
      Report_Id,
      Start_Date_Time,
      Interval,
      Next_Run_Time,
      Last_Run_Time,
      Status,
      Last_Result,
      Run_Attempts)
    Values(
      @Report_Id,
      @Start_Date_Time,
      @Interval,
      @Next_Run_Time,
      @Last_Run_Time,
      @Status,
      @Last_Result,
      0)
    Update Report_Definitions
      Set Class = @Class
      Where Report_Id = @Report_Id
    --
    -- Node_Id_Types
    -- 4 = Scheduled Report
    -- 5 = Defined Report
    -- 7 = UnDefined or AdHoc Report
    Update Report_Tree_Nodes
      Set Node_Id_Type = 4 	  	 
      Where Report_Def_Id = @Report_Id
    Select @Row_Id = Scope_Identity()
    Return (0)
  End 
Else
  Begin
 	 -- Add To The Report Que Again
    Select @Row_Id = Schedule_Id
      From Report_Schedule
      Where Report_Id = @Report_Id
 	 UPDATE Report_Schedule Set Status = 1, Next_Run_Time = (DateAdd(day, -1, GetDate())), Last_Run_Time = (DateAdd(day, -1, GetDate())) where Schedule_Id = @Row_Id
 	 --Insert Into Report_Que(Schedule_Id) Values(@Row_Id)
 	 -- Status Codes
 	 -- 0 Unknown
 	 -- 1 Scheduled
 	 -- 2 Pending
 	 -- 3 Running
 	 -- 4 Complete
 	 -- Status = 4 Complete
    Return (1)
  End
