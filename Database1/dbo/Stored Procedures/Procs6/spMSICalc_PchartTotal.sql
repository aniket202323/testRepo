CREATE PROCEDURE dbo.spMSICalc_PchartTotal
@OutputValue varchar(25) OUTPUT,
@Var_Id int,
@TimeStamp varchar(30),
@Default_String varchar(30)
AS
Declare
  @@VarId int,
  @Total float,
  @NumValues float,
  @Result varchar(30),
  @DefectCount float
Select @OutputValue = ''
Select @Total = 0.0
Select @NumValues = 0.0
Select @DefectCount = 0.0
Select Var_Id 
  Into #VarDepends
  From Calculation_Instance_Dependencies
  Where Result_Var_Id = @Var_Id
Declare Depend_Cursor INSENSITIVE CURSOR
  For (Select Var_Id From #VarDepends)
  For Read Only
  Open Depend_Cursor  
Fetch_Loop:
  Fetch Next From Depend_Cursor Into @@VarId
  If (@@Fetch_Status = 0)
    Begin
      Select @Result = NULL
      Select @Result = Result From Tests Where (Var_Id = @@VarId) And (Result_On = @TimeStamp)
      If (@Result Is Not Null)  
        Begin
          Select @NumValues = @NumValues + 1.0
          If (@Result = @Default_String) 
            Begin 
            Select @DefectCount = @DefectCount + 1.0
            End
        End
      Goto Fetch_Loop
    End
Close Depend_Cursor
Deallocate Depend_Cursor
Drop Table #VarDepends
If (@NumValues > 0.0)
  Select @OutputValue = Convert(varchar(30),@DefectCount/@NumValues)
