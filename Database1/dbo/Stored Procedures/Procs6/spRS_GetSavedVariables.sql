CREATE PROCEDURE dbo.spRS_GetSavedVariables
@InputStr varchar(1000)
 AS
Declare @StartRead int
Declare @EndRead int
Declare @TempStr varchar(1000)
Declare @Number varchar(1000) -- text between Start and end
Declare @Length int
Declare @ReadPtr int
CREATE TABLE #Temp_Table(
    Var_Id int)
If RTrim(LTrim(@InputStr)) = ''
  Begin
    Select Null 'Var_Id', Null 'Var_Desc'
    Return (0)
  End
Else
  Select @TempStr = @InputStr
-- Start Loop
BeginLoop:
Select @EndRead = CharIndex(',', @TempStr)
-- at this point endread could be 0
If @EndRead <> 0
 	 Select @Number = SubString(@TempStr,1, @EndRead - 1)
Else
 	 Select @Number = @TempStr
Insert Into #Temp_Table(Var_Id) Values(convert(int, @Number))
Select @TempStr = SubString(@TempStr, @EndRead + 1, Len(@TempStr) - @EndRead)
If @EndRead = 0 
  goto EndLoop
Else 
  goto BeginLoop
EndLoop:
-- End Loop
Select Var_Id, Var_Desc
from variables
Where Var_Id in(
  Select * 
  from #Temp_Table
  Where var_Id <> 0)
Drop Table #Temp_Table
