Create Procedure dbo.spEMCC_GetSPCInputDefault
@InputId int,
@ResultVarId 	 Int,
@defaultValue nVarChar(100) OUTPUT
AS
Select @defaultValue = Default_Value from calculation_input_Data Where Result_Var_Id = @ResultVarId and Calc_Input_Id = @InputId
