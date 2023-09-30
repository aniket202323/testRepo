CREATE PROCEDURE dbo.spEM_GetVarRunStatistics
  @Var_Id      int,
  @Var_Reject  bit          OUTPUT,
  @Unit_Reject bit          OUTPUT,
  @Rank        Smallint_Pct OUTPUT AS
  SELECT @Var_Reject  = Var_Reject,
         @Unit_Reject = Unit_Reject,
         @Rank        = Rank
    FROM Variables
    WHERE Var_Id = @Var_Id
  RETURN(0)
