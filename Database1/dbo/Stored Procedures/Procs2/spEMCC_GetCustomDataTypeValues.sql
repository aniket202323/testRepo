Create Procedure dbo.spEMCC_GetCustomDataTypeValues
@DataTypeId int,
@ResultVarId int,
@User_Id int
AS
Select Phrase_Value, Phrase_Id From Phrase Where Data_Type_Id = @DataTypeId
Select Default_Value From Calculation_Input_Data Where Result_Var_Id = @ResultVarId
