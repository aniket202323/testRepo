Create Procedure dbo.spEM_GetTimedEventFault
   @PU_Id             int
  AS
  --
  -- Declare local variables.
  --
    SELECT  t.TEFault_Id,t.TEFault_Name,t.Source_PU_Id /*= 
 	  	  	  	  	  	 CASE
 	  	  	  	  	     	    WHEN Source_PU_Id IS NULL THEN PU_Id
 	  	  	  	  	     	    ELSE 	 Source_PU_Id 
 	  	  	  	  	  	 END*/,
                                             Reason_Level1 = er1.Event_Reason_Name,
                                             Reason_Level2 = er2.Event_Reason_Name,
                                             Reason_Level3 = er3.Event_Reason_Name,
                                             Reason_Level4 = er4.Event_Reason_Name,
                                             t.TEFault_Value
    FROM Timed_Event_Fault t
    Left Join Prod_Units pu On pu.PU_Id = t.Source_PU_Id
    Join Prod_Events pe on pe.PU_Id = pu.PU_Id and  pe.Event_Type = 2
    LEFT JOIN Event_Reasons er1 ON t.Reason_Level1 = er1.Event_Reason_Id 
    LEFT JOIN Event_Reasons er2 ON t.Reason_Level2 = er2.Event_Reason_Id 
    LEFT JOIN Event_Reasons er3 ON t.Reason_Level3 = er3.Event_Reason_Id 
    LEFT JOIN Event_Reasons er4 ON t.Reason_Level4 = er4.Event_Reason_Id 
    WHERE   t.PU_Id  = @PU_Id
    ORDER BY TEFault_Name
