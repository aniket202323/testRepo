Create Procedure dbo.spGBO_CountVariables
@PU_Id int,
@VarCount int OUTPUT
AS
Declare @TempCount int
Select @TempCount = Null
Select @TempCount = count(var_id) from variables where pu_id = @PU_Id
If @TempCount Is Null
  Select @VarCount = 0
Else
  Select @VarCount = @TempCount
Select @TempCount = count(pug_id) from pu_groups where pu_id = @PU_Id
If @TempCount Is Not Null
  Select @VarCount = @VarCount + @TempCount
