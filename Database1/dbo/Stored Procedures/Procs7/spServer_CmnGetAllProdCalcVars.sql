CREATE PROCEDURE dbo.spServer_CmnGetAllProdCalcVars
@PU_Id int
 AS
Select PU_Id 
 Into #pus 
 From Prod_Units_Base
 Where PU_Id = @PU_Id or 
       Master_Unit = @PU_Id
Select Var_Id = COALESCE(b.Var_Id,0),
       ProdCalc_Type = a.PC_Id
  From Production_Calc_Types a
  Left Outer Join Variables_Base b on (b.ProdCalc_Type = a.PC_Id) And ((b.PU_Id in (Select PU_Id From #pus)) And (b.ProdCalc_Type Is Not NULL))
  Order By a.PC_Id
drop table #pus
