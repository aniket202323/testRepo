Create Procedure dbo.spEM_GetSPCChildVariableIds
@User_Id int
AS
Select Var_Id
  From Variables
  Where SPC_Group_Variable_Type_Id is Not NULL and PVar_Id is Not NULL
