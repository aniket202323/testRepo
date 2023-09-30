CREATE PROCEDURE dbo.spServer_EMgrGetProdCalcValue
@VarDesc nVarChar(100),
@Event_Id int,
@PU_Id int,
@TimeStamp Datetime,
@ProdCalc_Type tinyint,
@Success int OUTPUT,
@ErrorMsg nVarChar(100) OUTPUT,
@Value nVarChar(30) OUTPUT
 AS
Declare
  @NumProdCalcVars int,
  @VarId int
Select @Success = 0
Select @ErrorMsg = ''
Select PU_Id 
  Into #pus
  From Prod_Units_Base 
  Where PU_Id = @PU_Id or
        Master_Unit = @PU_Id
Select @VarId = Null
Select @VarId = Var_ID 
  From Variables_Base 
  Where (PU_Id In (Select PU_Id from #pus)) And 
        (ProdCalc_Type = @ProdCalc_Type)
Drop Table #pus
If (@VarID Is Null)
  Begin
    Select @ErrorMsg = @VarDesc + ' Not Properly Configured For Unit [' + Convert(nVarChar(10),@PU_Id) + ']'
    return
  End
Select @Value = Result
  From Tests
  Where (Var_Id = @VarID) And 
        (Result_On = @TimeStamp)
If (@Value Is Null)
  Begin
    Select @ErrorMsg = @VarDesc + ' Value Not Found For Event [' + Convert(nVarChar(10),@Event_Id) + ']'
    return
  End
Select @Success = 1
