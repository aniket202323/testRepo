Create Procedure [dbo].[spSDK_UpdatePrototypeData60_Bak_177]
  @SPName VARCHAR(50),
  @ExecTimeMS Int
AS
Begin Tran
Update Client_SP_Prototypes
Set ExecCount = ExecCount + 1,
ExecTotalMinutes = ExecTotalMinutes + (@ExecTimeMS / 1000 / 60),
ExecMinMS = Case When ExecMinMS = 0.0 Then @ExecTimeMS When ExecMinMS <= @ExecTimeMS Then ExecMinMS Else @ExecTimeMS End,
ExecMaxMS = Case When ExecMaxMS >= @ExecTimeMS Then ExecMaxMS Else @ExecTimeMS End
Where SP_Name = @SPName
If @@RowCount <> 1
  Begin
    Rollback Tran
    Return
  End 
Commit Tran
