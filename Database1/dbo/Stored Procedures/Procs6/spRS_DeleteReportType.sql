/* This Stored Procedure Used in Report Server V2 */
CREATE PROCEDURE dbo.spRS_DeleteReportType 
@ReportTypeId int
AS
Declare @LocalReportDefId int
Declare @MyError int
Select @MyError = 0
Begin Transaction
  -- Delete any existing report definitions
  Declare MyCursor INSENSITIVE CURSOR
  For( 
        Select Report_Id
        From Report_Definitions
        Where Report_Type_Id = @ReportTypeId
     )For Read Only
    Open MyCursor
  MyLoop1:
    Fetch Next From MyCursor Into @LocalReportDefId 
    If (@@Fetch_Status = 0)
      Begin
        -- Do Looping here
  -- 	 Select 'Deleting Report ' + convert(varchar(5), @LocalReportDefId)
   	 Exec spRS_DeleteReportDefinition @LocalReportDefId
   	 goto MyLoop1
      End
    Else -- No More Records to be fetched
      Begin
  --      Select 'Done Deleting Report Definitions'
        goto myEnd
      End
  myEnd:
  Close MyCursor
  Deallocate MyCursor
  If @@Error <> 0
    Select @MyError = 1
  -- Delete From Report_Type_Parameters
  Delete From Report_Type_Parameters
  Where Report_Type_Id = @ReportTypeId
  If @@Error <> 0 
    Select @MyError = 2
  -- Delete From Report_Type_WebPages
  Delete From Report_Type_WebPages
  Where Report_Type_Id = @ReportTypeId
  If @@Error <> 0 
    Select @MyError = 3
  Delete From Report_Tree_Nodes
  Where Report_Type_Id = @ReportTypeId
  If @@Error <> 0 
    Select @MyError = 4
  Delete From Report_Type_Dependencies
  Where Report_Type_Id = @ReportTypeId
  If @@Error <> 0
    Select @MyError = 5
  -- Delete From Report_Types
  Delete From Report_Types
  Where Report_Type_Id = @ReportTypeId
  If @@Error <> 0 
    Select @MyError = 6
If @MyError = 0
  Begin
    Commit Transaction
    Return (0)
  End
Else
  Begin
    Rollback Transaction
    Return @MyError
  End
