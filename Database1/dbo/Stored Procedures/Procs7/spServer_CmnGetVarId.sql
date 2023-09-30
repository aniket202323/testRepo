CREATE PROCEDURE dbo.spServer_CmnGetVarId
@Master_Unit int,
@Var_Desc nVarChar(100),
@Event_Type int,
@Var_Id int OUTPUT
 AS
Select PU_Id 
 Into #pus 
 From Prod_Units_Base
 Where PU_Id = @Master_Unit or 
       Master_Unit = @Master_Unit
Select @Var_Id = NULL
Select @Var_Id = Var_Id 
  From Variables_Base 
  Where (PU_Id in (Select PU_Id From #pus)) And 
        (Var_Desc = @Var_Desc) And
        (Event_Type = @Event_Type)
If (@Var_Id Is Null)
  Select @Var_Id = 0
drop table #pus
