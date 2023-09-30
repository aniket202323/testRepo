-----------------------------------------------------------------
-- This stored procedure is used by the following applications:
-- ProficyRPTAdmin
-- ProficyRPTEngine
-- Edit the master document in VSS project: ProficyRPTAdmin
-----------------------------------------------------------------
CREATE PROCEDURE dbo.spRS_GetEngineResponse
@Error_Id int = Null
 AS
Declare @Exists int
If @Error_Id Is Null
  Begin
    Select *
    From Report_Engine_Responses
  End
Else
  Begin
    Select @Exists = Error_Id
    From Report_Engine_Errors
    Where Error_Id = @Error_Id
    If @Exists Is Null
      Begin
        Select REE.Response_Id, RER.Response_Desc
        From Report_Engine_Errors REE
        Left Join Report_Engine_Responses RER on REE.Response_Id = RER.Response_Id
        Where Error_Id = 1
      End
    Else
      Begin
        Select REE.Response_Id, RER.Response_Desc
        From Report_Engine_Errors REE
        Left Join Report_Engine_Responses RER on REE.Response_Id = RER.Response_Id
        Where Error_Id = @Error_Id
      End
  End
