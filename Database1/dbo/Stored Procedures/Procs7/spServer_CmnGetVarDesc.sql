CREATE PROCEDURE dbo.spServer_CmnGetVarDesc
@Var_Id int,
@Var_Desc nvarchar(50) OUTPUT
 AS
Select @Var_Desc = Var_Desc 
 	 From Variables_Base 
 	 Where (Var_Id = @Var_Id)
if @Var_Desc Is Null
  Select @Var_Desc = ''
