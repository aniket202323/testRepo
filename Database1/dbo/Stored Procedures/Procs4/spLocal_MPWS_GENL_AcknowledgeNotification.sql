 
 
CREATE 	PROCEDURE [dbo].[spLocal_MPWS_GENL_AcknowledgeNotification]
	@ErrorCode		INT				OUTPUT,
	@ErrorMessage	VARCHAR(500)	OUTPUT,
	@NotificationId	INT,
	@AckUserId		INT,
	@AckTime		DATETIME
--WITH ENCRYPTION	
AS	
 
SET NOCOUNT ON
 
/* -------------------------------------------------------------------------------
 
	dbo.spLocal_MPWS_GENL_AcknowledgeNotification
 
declare @ErrorCode INT, @ErrorMessage VARCHAR(500)
exec dbo.spLocal_MPWS_GENL_AcknowledgeNotification @ErrorCode OUTPUT, @ErrorMessage OUTPUT, 106, 1791, '2016-11-27 12:48'
 
select @ErrorCode, @ErrorMessage
 
	Date			Version	Build	Author  
	30-Jun-2016		001		001		Jim Cameron (GEIP)		Initial development	
	27-Nov-2017     001     002		Susan Lee (GE Digital)	Check user group
 
------------------------------------------------------------------------------- */
Declare @ErrorSeverity	INT,
		@AcknowledgedByUserId INT,
		@NotificationArea	VARCHAR(50);

SELECT
	@ErrorCode		= 1,
	@ErrorMessage	= 'Success';

SELECT 	@AcknowledgedByUserId = AcknowledgedByUserId,
		@NotificationArea = NotificationArea
FROM	dbo.Local_MPWS_GENL_Notifications	WITH (NOLOCK)
WHERE	Notification_Id = @NotificationId

IF @@ROWCOUNT = 0
BEGIN
 
	SELECT
		@ErrorCode		= -1,
		@ErrorMessage	= 'Notification Id not found';
		
	
END;
 
IF @AcknowledgedByUserId IS NOT NULL
BEGIN
 
	SELECT
		@ErrorCode		= -2,
		@ErrorMessage	= 'Notification already Acknowledged';
	
END;
 
IF NOT EXISTS (SELECT u.User_Id FROM dbo.Users_Base u WHERE u.User_Id = @AckUserId)
BEGIN
 
	SELECT
		@ErrorCode		= -3,
		@ErrorMessage	= 'User not found';
 
END;
 
IF ISDATE(@AckTime) = 0
BEGIN
 
	SELECT
		@ErrorCode		= -4,
		@ErrorMessage	= 'Invalid Date/Time';
 
END;


--EXEC dbo.spLocal_MPWS_GENL_GetUserValidation @ErrorCode OUTPUT, @ErrorMessage OUTPUT, 
--		@NotificationArea,'Acknowledge Notification', 'Button',@AckUserId, null

IF @ErrorCode = 1
BEGIN
 
	BEGIN TRY
	
		BEGIN TRAN
		
		UPDATE dbo.Local_MPWS_GENL_Notifications
			SET AcknowledgedTime = @AckTime,
				AcknowledgedByUserId = @AckUserId
			WHERE Notification_Id = @NotificationId;
	
		COMMIT TRAN;
			
	END TRY
	BEGIN CATCH
	
		IF @@TRANCOUNT > 0 ROLLBACK TRAN;
		
		SELECT
			@ErrorCode = ERROR_NUMBER(),
			@ErrorMessage = ERROR_MESSAGE(),
			@ErrorSeverity = ERROR_SEVERITY();
			
		RAISERROR(@ErrorMessage, @ErrorSeverity, 1);
				
	END CATCH
	
END;
 
