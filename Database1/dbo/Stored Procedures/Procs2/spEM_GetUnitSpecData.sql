CREATE PROCEDURE dbo.spEM_GetUnitSpecData
  @PU_Id int
 AS
  --
  DECLARE @Master_PU_Id  int
  --
  -- Find the master unit for this unit.
  --
  SELECT @Master_PU_Id = Master_Unit FROM Prod_Units WHERE PU_Id = @PU_Id
  IF @Master_PU_Id IS NULL SELECT @Master_PU_Id = @PU_Id
  --
  -- Get the valid products for this production unit.
  --
  SELECT Prod_Id FROM PU_Products WHERE PU_Id = @Master_PU_Id
  --
  -- Get the variables for this production unit that have no specifications.
  --
  SELECT Var_Id FROM Variables WHERE (Spec_Id IS NULL) and (PU_Id = @PU_Id)
