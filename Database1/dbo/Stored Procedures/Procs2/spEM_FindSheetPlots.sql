CREATE PROCEDURE dbo.spEM_FindSheetPlots
  @Var_Id int AS
  -- Create a temporary table containing the variable and its children.
Select Distinct Sheet_Id From Sheet_Plots Where var_Id1 = @Var_Id or var_Id2 = @Var_Id or var_Id3 = @Var_Id
 	 or var_Id4 = @Var_Id or var_Id5 = @Var_Id
