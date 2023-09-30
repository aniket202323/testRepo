CREATE PROCEDURE dbo.spEM_GetUnitDSets
  @PU_Id int
  AS
  --
  -- Return all the captured data sets for this unit.
  --
  SELECT Id = DSet_Id, Timestamp, Operator, Prod_Id
    FROM GB_DSet WHERE PU_Id = @PU_Id
