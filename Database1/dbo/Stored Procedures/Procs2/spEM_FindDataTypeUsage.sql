CREATE PROCEDURE dbo.spEM_FindDataTypeUsage
  @Data_Type_Id int,
  @VarorSpec    int
 AS
  --
IF @VarorSpec = 0
   SELECT Var_Id FROM Variables WHERE Data_Type_Id = @Data_Type_Id
ELSE
  SELECT Spec_Id FROM Specifications WHERE Data_Type_Id = @Data_Type_Id
