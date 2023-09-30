/* 	 ------------------------------------------------------------------------------
 	 To get "Line" for Downtime Event, Waste Event, etc.
 	 Line list consists of Master Unit with event association or 
 	 one with no event association but its children are event associated.
 	 MT 10-21-1999 (changed from masters only in previous version)
   	 ------------------------------------------------------------------------------ */
Create Procedure dbo.spXLA_SearchUnitByEvent
 	 @EventType int
AS
If @EventType = 2 	 -- Downtime Event
  BEGIN
        SELECT  distinct pu1.PU_Id, pu1.PU_Desc, pu1.Master_Unit, pu1.Timed_Event_Association
          FROM  Prod_Units pu1
         WHERE  pu1.Master_Unit Is Null 	  	  	  	  	 -- master only
           AND  (     pu1.Timed_Event_Association > 0 
                  OR  (      (pu1.Timed_Event_Association Is Null OR pu1.Timed_Event_Association = 0)
 	                 AND  pu1.PU_Id IN 	  	  	  	 -- this master has event-assoc slave
 	                      (  SELECT  pu2.Master_Unit
 	                           FROM  Prod_Units pu2
 	                          WHERE  pu2.Timed_Event_Association > 0
 	                            AND  pu2.Master_Unit = pu1.PU_Id
 	  	              )
                      )
 	         )
     ORDER BY  pu1.PU_Desc
  END
Else 	  	  	 -- Time-Associated Waste Event
  BEGIN
        SELECT  Distinct pu1.PU_Id, pu1.PU_Desc, pu1.Master_Unit, pu1.Waste_Event_Association
          FROM  Prod_Units pu1
         WHERE  pu1.Master_Unit Is Null 	  	  	  	  	 -- master only
           AND  (      pu1.Waste_Event_Association > 0 	 
 	           OR (      (pu1.Waste_Event_Association Is Null OR pu1.Waste_Event_Association = 0)
                       AND  pu1.PU_Id IN 	  	  	  	 -- this master has event-assoc slaves
                                (  SELECT  pu2.Master_Unit
                                     FROM  Prod_Units pu2
                                    WHERE  pu2.Waste_Event_Association > 0
                                      AND  pu2.Master_Unit = pu1.PU_Id
                                )
                     )
                )
      ORDER BY  pu1.PU_Desc  
  END
/* 	 ------- Original Code -------- 	 */
/*
Create Procedure dbo.spXLA_SearchUnitByEvent
 	 @EventType int
AS
If @EventType = 2 	 -- Downtime Event
  BEGIN
        SELECT  Distinct p.PU_Id, p.PU_Desc
          FROM  Prod_Units p
          JOIN  Event_Config ec on ec.PU_Id = p.PU_Id
         WHERE  (p.Master_Unit Is Null 
 	    AND  p.Timed_Event_Association > 0) 
      ORDER BY  p.PU_Desc  
  END
Else 	  	  	 -- Waste Event
  BEGIN
        SELECT  Distinct p.PU_Id, p.PU_Desc
          FROM  Prod_Units p
          JOIN  Event_Config ec on ec.PU_Id = p.PU_Id
         WHERE  p.Master_Unit Is Null 	  	  	 -- this limits to only the Masters
 	    AND  p.Waste_Event_Association > 0
      ORDER BY  p.PU_Desc  
  END
*/
