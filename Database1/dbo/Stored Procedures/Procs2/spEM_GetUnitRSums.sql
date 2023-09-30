Create Procedure dbo.spEM_GetUnitRSums
  @PU_Id int
  AS
  --
  -- Return all the run summaries for this unit.
  --
  SELECT Id = RSum_Id, Start_Time, End_Time, Prod_Id
   FROM GB_RSum WHERE PU_Id = @PU_Id
