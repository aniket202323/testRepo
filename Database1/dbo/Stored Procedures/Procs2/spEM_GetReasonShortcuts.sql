Create Procedure dbo.spEM_GetReasonShortcuts
   @PU_Id             int,
   @App_Id            int
 AS
  --
  -- Declare local variables.
  --
  -- Temp patch for waste
  --
    IF @App_Id = 1 SELECT @App_Id = 3
--
--
    SELECT  RS_Id,ShortCut_Name,Source_PU_Id,Reason_Level1 = er1.Event_Reason_Name,
                                             Reason_Level2 = er2.Event_Reason_Name,
                                             Reason_Level3 = er3.Event_Reason_Name,
                                             Reason_Level4 = er4.Event_Reason_Name,
                                             Amount 
    FROM Reason_Shortcuts r
    LEFT JOIN Event_Reasons er1 ON r.Reason_Level1 = er1.Event_Reason_Id 
    LEFT JOIN Event_Reasons er2 ON r.Reason_Level2 = er2.Event_Reason_Id 
    LEFT JOIN Event_Reasons er3 ON r.Reason_Level3 = er3.Event_Reason_Id 
    LEFT JOIN Event_Reasons er4 ON r.Reason_Level4 = er4.Event_Reason_Id 
    WHERE   PU_Id  = @PU_Id
       AND  App_Id = @App_Id
