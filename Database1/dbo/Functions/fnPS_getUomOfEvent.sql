
CREATE FUNCTION  dbo.fnPS_getUomOfEvent (@EventId Int)
  RETURNS Int
AS 
BEGIN 
    DECLARE @eng_Unit_Id Int;  
	SELECT  @eng_Unit_Id = es.Dimension_X_Eng_Unit_Id
		FROM events e 
		 inner join event_details ed on e.event_id = ed.event_id 
		 left join Event_Configuration ec on ec.PU_Id = e.PU_Id and ec.ET_Id = 1
	     left join Event_Subtypes es on es.Event_Subtype_Id = ec.Event_Subtype_Id 
	 WHERE e.event_id=@EventId;
    RETURN @eng_Unit_Id;  
END
