CREATE PROCEDURE dbo.spEM_GetDependVar
 @Rslt_Var_Id int AS
  --
  SELECT DISTINCT Var_Id FROM spCalcs_Depends WHERE spcalc_id IN
    (SELECT spCalc_id FROM spCalcs WHERE Rslt_Var_Id = @Rslt_Var_Id)
