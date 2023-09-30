CREATE PROCEDURE dbo.spRS_DeleteReportParameter
@RP_Id int
 AS
/*
Deletes a parameter from the system
1.  Get a list of every Report_Type that uses this parameter
2.  Delete From Report_Definition_Parameters based on Report_Type_Parameter in Step 1
3.  Delete From Report_Type_WebPages
4.  Delete From Report_Type_Parameters
*/
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
    -- Select 'Deleting From Report_WebPage_Parameters'
    -- Select *
    Delete
    From Report_WebPage_Parameters
    Where RP_Id = @RP_Id
    If @@Error <> 0
      Select @MyError = 3
  End
If @MyError = 0
  Begin
    -- Select 'Deleting from Report_Parameters'
    -- Select *
    Delete
    From Report_Parameters
    Where RP_Id = @RP_Id
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
