Create Procedure dbo.spFF_GetVariableName 
@Var_Id int,
@Var_Desc nvarchar(50) OUTPUT
AS
Select @Var_Desc = Null
Select @Var_Desc = Var_Desc From Variables Where Var_Id = @Var_Id
Return(100)
