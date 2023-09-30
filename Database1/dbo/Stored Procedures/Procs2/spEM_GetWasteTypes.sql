Create Procedure dbo.spEM_GetWasteTypes
  AS
  --
    SELECT  WET_Id,WET_Name,ReadOnly
      FROM Waste_Event_Type
