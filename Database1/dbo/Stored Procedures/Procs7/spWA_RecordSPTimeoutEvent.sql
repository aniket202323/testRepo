Create Procedure [dbo].[spWA_RecordSPTimeoutEvent]
  @SPName nVarChar(50)
AS
Begin Tran
Update Client_SP_Prototypes
Set TimeoutCount = TimeoutCount + 1
Where SP_Name = @SPName
If @@RowCount > 1
  Rollback Tran
Else
  Commit Tran
