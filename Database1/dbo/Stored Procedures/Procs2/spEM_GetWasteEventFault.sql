Create Procedure dbo.spEM_GetWasteEventFault
   @PU_Id             int
  AS
  --
  -- Declare local variables.
  --
    SELECT  WEFault_Id,WEFault_Name,Source_PU_Id /*= 
 	  	  	  	  	  	 CASE
 	  	  	  	  	     	    WHEN Source_PU_Id IS NULL THEN PU_Id
 	  	  	  	  	     	    ELSE 	 Source_PU_Id 
 	  	  	  	  	  	 END*/,
                                             Reason_Level1 = er1.Event_Reason_Name,
                                             Reason_Level2 = er2.Event_Reason_Name,
                                             Reason_Level3 = er3.Event_Reason_Name,
                                             Reason_Level4 = er4.Event_Reason_Name,
                                             WEFault_Value
    FROM Waste_Event_Fault t
--    LEFT JOIN Event_Reason_Tree_Data e1 ON  Reason_Level1 = e1.Event_Reason_Tree_Data_Id
--    LEFT JOIN Event_Reason_Tree_Data e2 ON  Reason_Level2 = e2.Event_Reason_Tree_Data_Id
--    LEFT JOIN Event_Reason_Tree_Data e3 ON  Reason_Level3 = e3.Event_Reason_Tree_Data_Id
--    LEFT JOIN Event_Reason_Tree_Data e4 ON  Reason_Level4 = e4.Event_Reason_Tree_Data_Id
    LEFT JOIN Event_Reasons er1 ON t.Reason_Level1 = er1.Event_Reason_Id 
    LEFT JOIN Event_Reasons er2 ON t.Reason_Level2 = er2.Event_Reason_Id 
    LEFT JOIN Event_Reasons er3 ON t.Reason_Level3 = er3.Event_Reason_Id 
    LEFT JOIN Event_Reasons er4 ON t.Reason_Level4 = er4.Event_Reason_Id 
    WHERE   PU_Id  = @PU_Id
