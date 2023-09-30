
CREATE PROCEDURE [dbo].[spWaste_WasteEventTypes]
 @WET_ID Int = Null
  AS
BEGIN		 				
		select  WET_ID,WET_NAME,ReadOnly FROM Waste_Event_Type
		where 
				 ((@WET_ID is null) or (WET_ID=@WET_ID))
		order by WET_NAME 			
END