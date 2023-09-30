CREATE PROCEDURE dbo.spRS_DeleteReportDefinition
@Report_Id int
AS
Declare @Schedule_Id int,
        @Err int
Select @Err = 0
BEGIN TRANSACTION
-- Delete From Report_Definition_Data 
  Delete From Report_Definition_Data Where Report_Id = @Report_Id
-- Deleting from Report_Definition_Parameters
  Delete  From Report_Definition_Parameters  Where Report_Id = @Report_Id
  If @@Error <> 0 Select @Err = 1
-- Deleting from Report_Que
  Select @Schedule_Id = Schedule_Id From Report_Schedule Where Report_Id = @Report_Id
  Delete From Report_Que Where Schedule_Id = @Schedule_Id
  If @@Error <> 0 Select @Err = 2
-- Deleting from Report_Schedule
  Delete From Report_Schedule Where Report_Id = @Report_Id
  If @@Error <> 0 Select @Err = 3
-- Deleting from Report_Tree_Nodes
  Delete From Report_Tree_Nodes Where Report_Def_Id = @Report_Id
  If @@Error <> 0 Select @Err = 4
-- Deleting Report Runs
  Delete From Report_Runs Where Report_Id = @Report_Id
  If @@Error <> 0 Select @Err = 5
-- Deleting From Report_Hits
  Delete From Report_Hits Where Report_Id = @Report_Id
  If @@Error <> 0 Select @Err = 6
-- Delete From Report_Def_Webpages
  Delete From Report_Def_Webpages  Where Report_Def_Id = @Report_Id
  If @@Error <> 0 Select @Err = 7
-- Delete From Report ASP Print Que
  Delete From Report_AspPrintQue Where ReportId = @Report_Id
  If @@Error <> 0 Select @Err = 8
-- Deleting from Report_Definitions
  Delete From Report_Definitions Where Report_Id = @Report_Id
  If @@Error <> 0 Select @Err = 9
if @Err = 0
  Begin
    Commit Transaction
    return (0)
  End
Else
  Begin
    Rollback Transaction
    return (@Err)
  End
 Return(@Err)
