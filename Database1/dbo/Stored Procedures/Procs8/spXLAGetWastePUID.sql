Create Procedure dbo.spXLAGetWastePUID
 	 @puDesc varchar(50) 
AS 
SELECT  pu_id 
  FROM 	 prod_units 
 WHERE 	 pu_desc = @puDesc
   AND 	 Waste_Event_Association > 0
