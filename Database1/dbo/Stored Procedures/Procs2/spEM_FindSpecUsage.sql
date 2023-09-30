CREATE PROCEDURE dbo.spEM_FindSpecUsage
  @Spec_Id int
  AS
  --
  SELECT Var_Id
    FROM Variables
    WHERE  Spec_Id = @Spec_Id
