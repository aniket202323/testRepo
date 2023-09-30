CREATE PROCEDURE dbo.spSDK_QueryWasteTypes
 	 @WasteNameMask 	  	  	 nvarchar(50)
AS
SELECT 	 @WasteNameMask = REPLACE(COALESCE(@WasteNameMask, '*'), '*', '%')
SELECT 	 @WasteNameMask = REPLACE(REPLACE(@WasteNameMask, '?', '_'), '[', '[[]')
SELECT 	 WasteTypeId = WET_Id,
 	  	  	 TypeName = WET_Name
 	 FROM 	 Waste_Event_Type
 	 WHERE 	 WET_Name LIKE @WasteNameMask
