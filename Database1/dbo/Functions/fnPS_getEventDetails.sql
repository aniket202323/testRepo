
CREATE FUNCTION  dbo.fnPS_getEventDetails (@EventId Int)
  RETURNS Float
AS 
BEGIN 

    DECLARE @finalDimensionX Float;  
    SELECT @finalDimensionX = final_dimension_x FROM Event_details
	 WHERE event_id=@EventId;
    RETURN @finalDimensionX;  
END

