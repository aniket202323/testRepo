Create Procedure dbo.spXLAGetTimedPUID
 	 @puDesc varchar(50) 
AS 
SELECT  pu_id 
  FROM 	 prod_units 
 WHERE 	 pu_desc = @puDesc
   AND 	 Timed_Event_Association > 0
