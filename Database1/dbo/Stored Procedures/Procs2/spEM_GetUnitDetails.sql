Create Procedure dbo.spEM_GetUnitDetails
  @PU_Id int
  AS
  --
  -- Return all the captured data sets for this unit.
  --
  SELECT Production_Event_Association,Waste_Event_Association,Timed_Event_Association,WEMT_Name,
     Def_Production_Dest,Def_Production_Src
    FROM Prod_Units pu
    LEFT JOIN Waste_Event_Meas wem ON Def_Measurement = WEMT_Id
    WHERE pu.PU_Id = @PU_Id
