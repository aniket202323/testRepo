Create Procedure dbo.spEMAC_GetVarDesc
@Var_Id int,
@User_Id int,
@Var_Desc nvarchar(50) OUTPUT
AS
select @Var_Desc = var_desc
from variables
where var_id = @Var_Id
