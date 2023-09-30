CREATE PROCEDURE dbo.spEM_GetAliasedVar
 @Rslt_Var_Id int AS
  --
  SELECT DISTINCT Src_Var_Id FROM Variable_Alias WHERE Dst_Var_Id  = @Rslt_Var_Id
