 
 
CREATE 	PROCEDURE [dbo].[spLocal_MPWS_GENL_GetNotifications]
	@ErrorCode		INT				OUTPUT,
	@ErrorMessage	VARCHAR(500)	OUTPUT,
	@Area			VARCHAR(255) = NULL
	
AS	
 
SET NOCOUNT ON
 
/* -------------------------------------------------------------------------------
 
	dbo.spLocal_MPWS_GENL_GetNotifications
 
declare @ErrorCode INT, @ErrorMessage VARCHAR(500)
exec dbo.spLocal_MPWS_GENL_GetNotifications @ErrorCode OUTPUT, @ErrorMessage OUTPUT, 'Inventory'
exec dbo.spLocal_MPWS_GENL_GetNotifications @ErrorCode OUTPUT, @ErrorMessage OUTPUT, 'All'
 
select @ErrorCode, @ErrorMessage
 
	Date			Version	Build	Author  
	30-Jun-2016		001		001		Jim Cameron (GEIP)		Initial development	
 
------------------------------------------------------------------------------- */
 
SELECT
	@ErrorCode		= 1,
	@ErrorMessage	= 'Success';
	
SELECT
	n.Notification_Id,
	n.NotificationArea,
	n.NotificationDesc,
	n.NotificationTime,
	n.NotificationType,
	n.AcknowledgedTime,
	u.Username AcknowledgedByUser
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
	
 
