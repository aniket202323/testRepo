
CREATE PROCEDURE dbo.spMES_GetEventSubtypesForUnit
				 @UnitId 			 Int
AS

DECLARE @EventSubtypeData Table (EventSubtypeId int, EventSubtypeDesc nvarchar(50) )

INSERT INTO @EventSubtypeData(EventSubtypeId, EventSubtypeDesc)
	SELECT DISTINCT EventSubtypeId   = subtype.Event_Subtype_Id,
					EventSubtypeDesc = subtype.Event_Subtype_Desc
	FROM Prod_Units_Base unit
	JOIN Event_Configuration conf ON conf.PU_Id = unit.PU_Id
	JOIN Event_Subtypes subtype ON subtype.Event_Subtype_Id = conf.Event_Subtype_Id
	JOIN EVENT_TYPES eventtype ON eventtype.ET_Id = subtype.ET_Id
	WHERE unit.PU_Id = @UnitId AND eventtype.ET_DESC = 'User-Defined Event'		

SELECT EventSubtypeId, EventSubtypeDesc
FROM @EventSubtypeData
ORDER BY EventSubtypeId

