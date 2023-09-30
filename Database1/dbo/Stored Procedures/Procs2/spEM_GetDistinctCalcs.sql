Create Procedure dbo.spEM_GetDistinctCalcs AS
  --
  SELECT DISTINCT Calculation FROM Calcs WHERE Calculation IS NOT NULL
