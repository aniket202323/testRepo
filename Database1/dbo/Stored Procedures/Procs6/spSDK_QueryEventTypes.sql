Create Procedure dbo.spSDK_QueryEventTypes
 	 @ETId 	  	  	  	  	  	  	 INT 	  	  	  	 = NULL,
 	 @EventTypeMask  	  	  	 nvarchar(50) 	 = NULL
AS
SELECT 	 @EventTypeMask  	 = REPLACE(REPLACE(REPLACE(COALESCE(@EventTypeMask, '*'), '*', '%'), '?', '_'), '[', '[[]')
SELECT 	 EventTypeId 	  	  	  	 = ET_Id,
 	  	  	 EventTypeName 	  	  	 = ET_Desc,
 	  	  	 IsVariableEventType 	 = Variables_Assoc,
 	  	  	 HasSubtypes 	  	  	  	 = SubTypes_Apply
 	 FROM 	 Event_Types
 	 WHERE 	 ET_Desc LIKE @EventTypeMask
 	 AND 	 (ET_Id = @ETId OR @ETId IS NULL)
