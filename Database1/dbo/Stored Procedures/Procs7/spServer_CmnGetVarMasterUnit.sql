CREATE PROCEDURE dbo.spServer_CmnGetVarMasterUnit
@Var_Id int,
@Master_Unit int OUTPUT
 AS
Declare
  @PU_Id int,
  @Master_PU_Id int
Select @PU_Id = PU_Id,
       @Master_PU_Id = Master_Unit
  From Prod_Units_Base
  Where PU_Id = (Select PU_Id From Variables_Base Where Var_Id = @Var_Id)
If (@Master_PU_Id Is Not Null)
  Select @Master_Unit = @Master_PU_Id
Else
  Select @Master_Unit = @PU_Id
