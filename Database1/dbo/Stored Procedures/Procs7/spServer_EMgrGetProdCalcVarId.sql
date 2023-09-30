CREATE PROCEDURE dbo.spServer_EMgrGetProdCalcVarId
@VarDesc nVarChar(100),
@PU_Id int,
@ProdCalc_Type tinyint,
@Success int OUTPUT,
@ErrorMsg nVarChar(100) OUTPUT,
@Var_Id int OUTPUT
 AS
Select @Success = 0
Select @ErrorMsg = ''
Select PU_Id 
  Into #pus
  From Prod_Units_Base 
  Where PU_Id = @PU_Id or
        Master_Unit = @PU_Id
Select @Var_Id = v.Var_Id From Variables_Base v Where (v.PU_Id in (Select p.PU_Id From #pus p)) And (v.ProdCalc_Type = @ProdCalc_Type)
drop table #pus
If (@Var_Id Is Null)
  Begin
    Select @ErrorMsg = @VarDesc + ' Not Found For Unit [' + Convert(nVarChar(10),@PU_Id) + ']'
    return
  End
Select @Success = 1
