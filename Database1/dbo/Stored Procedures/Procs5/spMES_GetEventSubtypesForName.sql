CREATE PROCEDURE dbo.spMES_GetEventSubtypesForName
		@EventSubtypeNames  nvarchar(max) = NULL
AS

DECLARE @EventSubtypeData Table (EventSubtypeId int, EventSubtypeDesc nvarchar(50) )

IF (@EventSubtypeNames Is NULL)
BEGIN
	INSERT INTO @EventSubtypeData(EventSubtypeId,EventSubtypeDesc)
		SELECT EventSubtypeId   = subtype.Event_Subtype_Id,
			   EventSubtypeDesc = subtype.Event_Subtype_Desc		   	  
		FROM EVENT_SUBTYPES subtype
		JOIN EVENT_TYPES eventtype
		ON eventtype.ET_Id = subtype.ET_Id
		WHERE eventtype.ET_DESC = 'User-Defined Event'	
	
END
ELSE
BEGIN
	IF (@EventSubtypeNames Is Not NULL)
	BEGIN
		DECLARE @AllSubtypes TABLE(Event_Subtype_Desc nvarchar(50))
		DECLARE @xml XML
		SET @xml = cast(('<X>'+replace(@EventSubtypeNames,',','</X><X>')+'</X>') as xml)
		INSERT INTO @AllSubtypes (Event_Subtype_Desc)
		SELECT N.value('.', 'nvarchar(50)') FROM @xml.nodes('X') AS T(N)
			
			
		INSERT INTO @EventSubtypeData(EventSubtypeId,EventSubtypeDesc)
			SELECT EventSubtypeId   = subtype.Event_Subtype_Id,
				   EventSubtypeDesc = subtype.Event_Subtype_Desc		   	  
			FROM Event_Subtypes subtype
			JOIN EVENT_TYPES eventtype
			ON eventtype.ET_Id = subtype.ET_Id
			WHERE subtype.Event_Subtype_Desc IN (SELECT Event_Subtype_Desc FROM @AllSubtypes) AND eventtype.ET_DESC = 'User-Defined Event'		
	END
END
SELECT EventSubtypeId, EventSubtypeDesc
FROM @EventSubtypeData
ORDER BY EventSubtypeId

