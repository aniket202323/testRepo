Create Procedure dbo.spAL_VariablesOnSheet
  @SheetID int AS
  SELECT * FROM Sheet_Variables 
    WHERE Sheet_Id = @SheetID 
    ORDER BY Var_Order
