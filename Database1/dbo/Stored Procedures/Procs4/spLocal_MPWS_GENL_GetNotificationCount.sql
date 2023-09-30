 
 
CREATE 	PROCEDURE [dbo].[spLocal_MPWS_GENL_GetNotificationCount]
	@ErrorCode		INT				OUTPUT,
	@ErrorMessage	VARCHAR(500)	OUTPUT,
	@Area			VARCHAR(255) = NULL
	
AS	
 
SET NOCOUNT ON
 
/* -------------------------------------------------------------------------------
 
	testing stored procedure
 
declare @ErrorCode INT, @ErrorMessage VARCHAR(500)
exec dbo.spLocal_MPWS_GENL_GetNotificationCount @ErrorCode OUTPUT, @ErrorMessage OUTPUT 
 
select @ErrorCode, @ErrorMessage
 
	Date			Version	Build	Author  
	19-Jun-2016		001		001		Jim Cameron (GEIP)		Initial development	
 
 
 
------------------------------------------------------------------------------- */
 
SELECT
	@ErrorCode		= 1,
	@ErrorMessage	= 'Success';
	
SELECT
	n.NotificationArea Area,
	COUNT(n.NotificationType) [Count]
FROM dbo.Local_MPWS_GENL_Notifications n
	LEFT JOIN dbo.Users_Base u ON u.[User_Id] = n.AcknowledgedByUserId
WHERE AcknowledgedTime IS NULL
	AND
	(
		ISNULL(@Area, '') = '' 
		OR 
		@Area = 'All'
		OR 
		n.NotificationArea IN (
								SELECT
									x.y.value('.', 'varchar(50)') NotificationArea
								FROM (SELECT CAST('<p>' + REPLACE(@Area, ',', '</p><p>') + '</p>' AS XML) q) p
									CROSS APPLY q.nodes('/p/text()') x(y)
								)
	)
GROUP BY n.NotificationArea
 
