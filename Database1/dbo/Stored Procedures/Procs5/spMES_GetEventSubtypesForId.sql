CREATE PROCEDURE dbo.spMES_GetEventSubtypesForId
				 @EventSubtypeId 	 Int = NULL
AS


DECLARE @EventSubtypeData Table (EventSubtypeId int, EventSubtypeDesc nvarchar(50) )

IF (@EventSubtypeId Is NULL)
BEGIN
	INSERT INTO @EventSubtypeData(EventSubtypeId,EventSubtypeDesc)
		SELECT EventSubtypeId   = subtype.Event_Subtype_Id,
			   EventSubtypeDesc = subtype.Event_Subtype_Desc		   	  
		FROM EVENT_SUBTYPES subtype
		JOIN EVENT_TYPES eventtype
		ON eventtype.ET_Id = subtype.ET_Id
		WHERE eventtype.ET_DESC = 'User-Defined Event'	
	
END
	IF (@EventSubtypeId Is Not NULL)
	BEGIN
		INSERT INTO @EventSubtypeData(EventSubtypeId,EventSubtypeDesc)
			SELECT EventSubtypeId   = subtype.Event_Subtype_Id,
				   EventSubtypeDesc = subtype.Event_Subtype_Desc		   	  
			FROM Event_Subtypes subtype
			JOIN EVENT_TYPES eventtype
			ON eventtype.ET_Id = subtype.ET_Id
			WHERE subtype.Event_Subtype_Id = @EventSubtypeId AND eventtype.ET_DESC = 'User-Defined Event'	
	END

SELECT EventSubtypeId, EventSubtypeDesc
FROM @EventSubtypeData
ORDER BY EventSubtypeId

