 
 
/*	-------------------------------------------------------------------------------
	dbo.spLocal_MPWS_GENL_SignESignatureRecord
	
	Date			Version		Build	Author  
	15-Aug-2016		001			001		Jim Cameron (GEIP)		Initial development
 
test
 
DECLARE @ErrorCode INT, @ErrorMessage VARCHAR(500), @ESig INT
EXEC dbo.spLocal_MPWS_GENL_SignESignatureRecord @ErrorCode OUTPUT, @ErrorMessage OUTPUT, @Esig OUTPUT, 
 
SELECT @ErrorCode, @ErrorMessage
 
 
 
*/	-------------------------------------------------------------------------------
 
CREATE  PROCEDURE [dbo].[spLocal_MPWS_GENL_SignESignatureRecord]
	@ErrorCode			INT				OUTPUT,
	@ErrorMessage		VARCHAR(500)	OUTPUT,
 
	@ESignatureId		UNIQUEIDENTIFIER,
	@UserName			VARCHAR(255),
	@Password			VARCHAR(255),
	@Comment			VARCHAR(2048)
 
AS
 
SET NOCOUNT ON;
 
DECLARE
	@ErrorSeverity			INT,
	@ESigStatus				VARCHAR(255);
	
DECLARE @Inserted TABLE
(
	Id	UNIQUEIDENTIFIER
);
 
SELECT
	@ErrorCode = 0,
	@ErrorMessage = 'Initialized';
 
SELECT
	@ESigStatus = [Status]
FROM dbo.ElectronicSignature 
WHERE Id = @ESignatureId;
 
-- if an esig row was created, [Status] has a value.
IF @ESigStatus IS NULL
BEGIN
 
	SELECT
		@ErrorCode = -1,
		@ErrorMessage = 'ESignatureId: ' + CAST(@ESignatureId AS VARCHAR(50)) + ' not found';
 
END;
 
IF @ErrorCode >= 0
BEGIN
 
	
	BEGIN TRY
	
		BEGIN TRAN
 
			IF @ESigStatus = 'Awaiting Performer'
			BEGIN
			
				UPDATE dbo.ElectronicSignature
					SET [Status] = CASE VerifierRequired WHEN 1 THEN 'Awaiting Verifier' ELSE 'Completed' END,
						PerformerUserName = @UserName,
						PerformerComment = @Comment,
						PerformerSigningTime = GETDATE(),
						[Version] = 2
					WHERE Id = @ESignatureId;
					
			END
			ELSE IF @ESigStatus = 'Awaiting Verifier'
			BEGIN
			
				UPDATE dbo.ElectronicSignature
					SET [Status] = 'Completed',
						VerifierUserName = @UserName,
						VerifierComment = @Comment,
						VerifierSigningTime = GETDATE(),
						[Version] = 3
					WHERE Id = @ESignatureId;
					
			END
			ELSE IF @ESigStatus = 'Completed'
			BEGIN
			
				SELECT
					@ErrorCode = -2,
					@ErrorMessage = 'ESignature already Completed';
 
			END
			ELSE IF @ESigStatus = 'Cancelled'
			BEGIN
			
				SELECT
					@ErrorCode = -3,
					@ErrorMessage = 'ESignature is Cancelled';
 
			END
			ELSE IF @ESigStatus = 'Failed'
			BEGIN
			
				SELECT
					@ErrorCode = -4,
					@ErrorMessage = 'ESignature has Failed';
 
			END;
				
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
 
