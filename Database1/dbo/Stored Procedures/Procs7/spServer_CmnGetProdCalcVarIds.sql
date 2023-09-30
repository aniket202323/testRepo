CREATE PROCEDURE dbo.spServer_CmnGetProdCalcVarIds
@PU_Id int,
@Success int OUTPUT,
@OWTVar_Id int OUTPUT,
@OLFVar_Id int OUTPUT,
@ODIVar_Id int OUTPUT,
@LWTVar_Id int OUTPUT,
@LLFVar_Id int OUTPUT,
@LDIVar_Id int OUTPUT
 AS
Select @Success = 0
Select PU_Id 
 Into #pus 
 From Prod_Units_Base
 Where PU_Id = @PU_Id or 
       Master_Unit = @PU_Id
Select @OWTVar_Id = NULL
Select @OLFVar_Id = NULL
Select @ODIVar_Id = NULL
Select @LWTVar_Id = NULL
Select @LLFVar_Id = NULL
Select @LDIVar_Id = NULL
Select @OWTVar_Id = Var_Id From Variables_Base Where (PU_Id in (Select PU_Id From #pus)) And (ProdCalc_Type = 1)
Select @OLFVar_Id = Var_Id From Variables_Base Where (PU_Id in (Select PU_Id From #pus)) And (ProdCalc_Type = 3)
Select @ODIVar_Id = Var_Id From Variables_Base Where (PU_Id in (Select PU_Id From #pus)) And (ProdCalc_Type = 5)
Select @LWTVar_Id = Var_Id From Variables_Base Where (PU_Id in (Select PU_Id From #pus)) And (ProdCalc_Type = 2)
Select @LLFVar_Id = Var_Id From Variables_Base Where (PU_Id in (Select PU_Id From #pus)) And (ProdCalc_Type = 4)
Select @LDIVar_Id = Var_Id From Variables_Base Where (PU_Id in (Select PU_Id From #pus)) And (ProdCalc_Type = 6)
drop table #pus
If (@OWTVar_Id Is Null)
  Return
If (@OLFVar_Id Is Null)
  Return
If (@ODIVar_Id Is Null)
  Return
If (@LWTVar_Id Is Null)
  Return
If (@LLFVar_Id Is Null)
  Return
If (@LDIVar_Id Is Null)
  Return
Select @Success = 1
