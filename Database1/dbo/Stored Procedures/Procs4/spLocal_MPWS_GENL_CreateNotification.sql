 
 
CREATE 	PROCEDURE [dbo].[spLocal_MPWS_GENL_CreateNotification]
	@ErrorCode			INT				OUTPUT,
	@ErrorMessage		VARCHAR(500)	OUTPUT,
	@NotificationArea	VARCHAR(50),
	@NotificationDesc	VARCHAR(255),
	@NotificationTime	DATETIME,
	@NotificationType	VARCHAR(50)
	
AS	
 
SET NOCOUNT ON
 
/* -------------------------------------------------------------------------------
 
	dbo.spLocal_MPWS_GENL_CreateNotification
 
declare @ErrorCode INT, @ErrorMessage VARCHAR(500)
exec dbo.spLocal_MPWS_GENL_CreateNotification @ErrorCode OUTPUT, @ErrorMessage OUTPUT, 'Inventory', 'Test Description', '2016-06-30 15:01', 'Error'
 
select @ErrorCode, @ErrorMessage
 
	Date			Version	Build	Author  
	30-Jun-2016		001		001		Jim Cameron (GEIP)		Initial development	
 
------------------------------------------------------------------------------- */
 
DECLARE
	@ErrorSeverity INT;
	
SELECT
	@ErrorCode		= 1,
	@ErrorMessage	= 'Success';
	
IF @NotificationArea NOT IN ('Planning', 'Inventory', 'Kitting', 'Returns')
BEGIN
 
	SELECT
		@ErrorCode		= -1,
		@ErrorMessage	= 'Invalid Area';
	
END;
 
IF @NotificationType NOT IN ('Error', 'Warning', 'Message')
BEGIN
 
	SELECT
		@ErrorCode		= -2,
		@ErrorMessage	= 'Invalid Notification Type';
	
END;
 
IF ISNULL(@NotificationDesc, '') = ''
BEGIN
 
	SELECT
		@ErrorCode		= -3,
		@ErrorMessage	= 'Invalid or Missing Description';
 
END;
 
IF ISDATE(@NotificationTime) = 0
BEGIN
 
	SELECT
		@ErrorCode		= -4,
		@ErrorMessage	= 'Invalid Date/Time';
 
END;
 
IF @ErrorCode = 1
BEGIN
 
	BEGIN TRY
	
		BEGIN TRAN
		
		INSERT dbo.Local_MPWS_GENL_Notifications (NotificationArea, NotificationDesc, NotificationTime, NotificationType)
			VALUES
			(@NotificationArea, @NotificationDesc, @NotificationTime, @NotificationType)
 
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
 
