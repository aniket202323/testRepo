CREATE PROCEDURE dbo.spMSICalc_CalcRange
@OutputValue varchar(25) OUTPUT,
@Var_Id int,
@TimeStamp varchar(30),
@AllRequired 	 Int = 0
AS
Declare
  @@VarId int,
  @MaxValue float,
  @MinValue float,
  @CurrentValue float,
  @Result varchar(30),
  @Range varchar(30),
  @NumDependVars Int,
  @NumValues Int
SELECT 	 @OutputValue = ''
Select @MaxValue = NULL
Select @MinValue = NULL
Select @Range = NULL
Select @AllRequired = isnull(@AllRequired,0)
Select Var_Id 
  Into #VarDepends
  From Calculation_Instance_Dependencies 
  Where Result_Var_Id = @Var_Id
Select @NumDependVars = Count(*) from #VarDepends
Select @NumValues = 0
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
      If (@Result Is Not NULL)
      BEGIN
          Select @CurrentValue = Convert(float,@Result)
 	    	 If (@MaxValue Is NULL)
            Select @MaxValue = @CurrentValue
          Else
 	      If (@CurrentValue > @MaxValue)
              Select @MaxValue = @CurrentValue
          If (@MinValue Is NULL)
            Select @MinValue = @CurrentValue
          Else
 	      If (@CurrentValue < @MinValue)
              Select @MinValue = @CurrentValue
          Select @NumValues = @NumValues + 1
      END
      Goto Fetch_Loop
    End
Close Depend_Cursor
Deallocate Depend_Cursor
Drop Table #VarDepends
If (@MaxValue Is NULL) or (@MinValue Is NULL)
  Return
If ((@NumValues <> @NumDependVars) and (@AllRequired = 1)) or (@NumValues < 2)
 	 Return
Select @Range = ABS(@MaxValue - @MinValue)
Select @OutputValue = Convert(Varchar(25),@Range)
