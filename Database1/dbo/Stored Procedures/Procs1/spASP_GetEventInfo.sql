CREATE PROCEDURE [dbo].[spASP_GetEventInfo]
@EventId INT,
@InTimeZone nvarchar(200)=NULL
AS 
SELECT 	 Event_Id, Event_Num, 'TimeStamp'=[dbo].[fnServer_CmnConvertFromDbTime] (TimeStamp,@InTimeZone), PU_Id
FROM 	 Events
WHERE 	 Event_Id = @EventId
