Create Procedure dbo.spGBS_CountVariables
@SheetName nvarchar(50),
@VarCount int OUTPUT
AS
Declare @TempCount int
Declare @SheetId int
Select @SheetId = Sheet_Id
  From Sheets
  Where Sheet_Desc = @SheetName
Select @TempCount = Null
Select @TempCount = count(var_order) from sheet_variables where Sheet_Id = @SheetId
If @TempCount Is Not Null
  Select @VarCount = @TempCount
Else
  Select @VarCount = 0
