
CREATE PROCEDURE dbo.spWaste_GetLocationsWasteEventType
 @MasterUnitId INT
  AS
BEGIN	
		   select p.pu_id,p.Master_Unit
				from prod_events pe 
			join prod_units_base p on p.pu_id = pe.pu_id
			where  p.master_unit = @MasterUnitId and pe.event_type = 3 -- Waste Event Type
END