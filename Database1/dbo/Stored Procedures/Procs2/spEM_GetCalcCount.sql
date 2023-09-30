CREATE PROCEDURE dbo.spEM_GetCalcCount
 	 @Var_Id 	 Int,
 	 @CalcCount       Int OUTPUT 
  AS
Declare @CalcId  int, @IsSystemCalc int
  --
  SELECT @CalcId = Calculation_id From Variables where Var_Id = @Var_Id
  SELECT @IsSystemCalc = System_Calculation From Calculations where Calculation_Id = @CalcId
  IF @IsSystemCalc = 1
    Begin
      Select @CalcCount = 2
    End
  Else
    Select  @CalcCount = Count(*) From Variables where  Calculation_id =   @CalcId
  --
