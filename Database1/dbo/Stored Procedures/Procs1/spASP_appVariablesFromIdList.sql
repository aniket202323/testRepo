CREATE procedure [dbo].[spASP_appVariablesFromIdList]
@Variables VarChar(8000)
AS
Select @Variables = ',' + Replace(@Variables, ' ', '') + ','
Select Var_Id, Var_Desc
From Variables
Where PatIndex('%,' + Convert(VarChar, Var_Id) + ',%', @Variables) > 0
Order By PatIndex('%,' + Convert(VarChar, Var_Id) + ',%', @Variables)
