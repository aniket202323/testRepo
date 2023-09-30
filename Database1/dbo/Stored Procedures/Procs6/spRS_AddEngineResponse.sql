CREATE PROCEDURE dbo.spRS_AddEngineResponse
@Error_Id int, 
@Response_Id int
 AS
Declare @RowExists int
Select @RowExists = Error_Id
From Report_Engine_Errors
Where Error_Id = @Error_Id
-- @Error_Id must already exist in Return_Error_Codes
-- @Response_Id must already exist in Report_Engine_Responses
If @RowExists Is Null
  Begin
    Insert Into Report_Engine_Errors(Error_Id, Response_Id)
    Values(@Error_Id, @Response_Id)
  End
Else
  Begin
    Update Report_Engine_Errors
    Set Response_Id = @Response_Id
    Where Error_Id = @Error_Id
  End
