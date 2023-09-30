CREATE PROCEDURE dbo.spRS_DeleteReportEngineError
@Error_Code_Value int
 AS
Declare @myError int
Select @myError = 0
Begin Transaction
Delete From Report_Engine_Errors
Where Error_Id = @Error_Code_Value
If @@Error <> 0 
  Select @myError = 1
Delete From Return_Error_Codes
Where Code_Value = @Error_Code_Value
and App_Id = 11
and Group_Id = 5
If @@Error <> 0 
  Select @myError = 2
If @myError = 0
  Begin
    Commit Transaction
    Return (0)
  End
Else
  Begin
    Rollback Transaction
    Return (@myError)
  End
