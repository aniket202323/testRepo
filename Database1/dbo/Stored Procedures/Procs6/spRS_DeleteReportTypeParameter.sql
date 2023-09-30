CREATE PROCEDURE dbo.spRS_DeleteReportTypeParameter
@RP_Id int,
@Report_Type_Id int
 AS
/*
Deletes a parameter from a Report Type
1.  Get a list of every Report_Type that uses this parameter
2.  Delete From Report_Definition_Parameters based on Report_Type_Parameter in Step 1
3.  Delete From Report_Type_Parameters
*/
/* -- old stuff
Declare @RTP_Id int
Declare @MyError int
Declare MyCursor INSENSITIVE CURSOR
  For (
       Select RTP_Id
        From Report_Type_Parameters
        Where RP_Id = @RP_Id
      )
  For Read Only
  Open MyCursor  
Select @MyError = 0
Begin Transaction
MyLoop1:
  Fetch Next From MyCursor Into @RTP_Id
  If (@@Fetch_Status = 0)
    Begin -- Begin Loop
 	 -- Select 'Deleting From Report_Definition_Parameters'
 	 -- Select * 
 	 Delete
        From Report_Definition_Parameters
 	 where RTP_Id = @RTP_Id
 	 If @@Error <> 0
          Begin
            Select @MyError = 1
            goto myEnd
          End
      GoTo MyLoop1
    End -- End Loop
  Else -- @@Fetch_Status is not 0
    Begin
      goto myEnd
    End
myEnd:
Close MyCursor
Deallocate MyCursor
If @MyError = 0
  Begin
    -- Select 'Deleting From Report_Type_Parameters'
    -- Select *
    Delete
    From Report_Type_Parameters
    Where RP_Id = @RP_Id
    If @@Error <> 0
      Select @MyError = 2
  End
If @MyError = 0
  Begin
    Commit Transaction
    Return (0)
  End
Else
  Begin
    Rollback Transaction
    Return (@MyError)
  End
*/
Declare @RTP_ID int
Declare @MyError int
Select @MyError = 0
-- Get the Report_Type_Parameter Id
Select @RTP_Id = RTP_Id
From report_type_Parameters -- this gives RTP_ID 712
Where report_type_Id = @Report_Type_Id
and RP_Id = @RP_ID
BEGIN TRANSACTION
-- Delete this parameter from all the report_definitions
-- that are of this report_type
Delete
From report_definition_Parameters -- RTP_Id, Report_ID
Where Report_Id in (
  Select Report_Id from report_Definitions
  Where report_type_Id = @Report_Type_Id
)
and RTP_Id = @RTP_Id
If @@Error <> 0 
  Begin
    Select @MyError = 1
    Goto MyEnd
  End
-- Delete the Report_Parameter from the Report Type
Delete
From report_type_parameters
Where Report_type_Id = @Report_Type_Id
and RP_Id = @RP_Id
If @@Error <> 0 
  Begin
    Select @MyError = 2
    Goto MyEnd
  End
MyEnd:
If @MyError = 0
  Begin
    Commit Transaction
    Return (0)
  End
Else
  Begin
    Rollback Transaction
    Return (@MyError)
  End
