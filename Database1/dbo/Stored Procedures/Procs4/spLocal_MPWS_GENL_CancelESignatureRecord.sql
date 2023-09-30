 
 
/*	-------------------------------------------------------------------------------
	dbo.spLocal_MPWS_GENL_CancelESignatureRecord
	
	Date			Version		Build	Author  
	15-Aug-2016		001			001		Jim Cameron (GEIP)		Initial development
 
test
 
DECLARE @ErrorCode INT, @ErrorMessage VARCHAR(500), @ESig INT
EXEC dbo.spLocal_MPWS_GENL_CancelESignatureRecord @ErrorCode OUTPUT, @ErrorMessage OUTPUT, @Esig OUTPUT, 
 
SELECT @ErrorCode, @ErrorMessage
 
 
*/	-------------------------------------------------------------------------------
 
CREATE  PROCEDURE [dbo].[spLocal_MPWS_GENL_CancelESignatureRecord]
	@ErrorCode			INT				OUTPUT,
	@ErrorMessage		VARCHAR(500)	OUTPUT,
 
	@ESignatureId		UNIQUEIDENTIFIER
 
AS
 
SET NOCOUNT ON;
 
DECLARE
	@ErrorSeverity			INT,
	@ElectronicSignatureId	UNIQUEIDENTIFIER;
	
SELECT
	@ErrorCode = 0,
	@ErrorMessage = 'Initialized';
 
IF @ErrorCode >= 0
BEGIN
 
	BEGIN TRY
	
		BEGIN TRAN
 
				UPDATE dbo.ElectronicSignature
					SET [Status] = 'Cancelled'
					WHERE Id = @ESignatureId;
		
		COMMIT TRAN;
		
		SELECT 
			@ErrorCode = 1,
			@ErrorMessage = 'Success';
	
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
 
