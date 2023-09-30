 
 
/*	-------------------------------------------------------------------------------
	dbo.spLocal_MPWS_GENL_GetESignatureRecord
	
	Date			Version		Build	Author  
	15-Aug-2016		001			001		Jim Cameron (GEIP)		Initial development
 
test
 
DECLARE @ErrorCode INT, @ErrorMessage VARCHAR(500)
EXEC dbo.spLocal_MPWS_GENL_GetESignatureRecord @ErrorCode OUTPUT, @ErrorMessage OUTPUT 
 
SELECT @ErrorCode, @ErrorMessage
 
 
 
*/	-------------------------------------------------------------------------------
 
CREATE  PROCEDURE [dbo].[spLocal_MPWS_GENL_GetESignatureRecord]
	@ErrorCode			INT				OUTPUT,
	@ErrorMessage		VARCHAR(500)	OUTPUT,
 
	@ESignatureId		UNIQUEIDENTIFIER
 
AS
 
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
 
SELECT
	@ErrorCode = 0,
	@ErrorMessage = 'Initialized';
 
IF @ErrorCode >= 0
BEGIN
 
	SELECT
		Id,
		CASE [Status] 
			WHEN 'Awaiting Performer' THEN 0 
			WHEN 'Awaiting Verifier' THEN 1
			WHEN 'Completed' THEN 2
			WHEN 'Cancelled' THEN 3
			WHEN 'Failed' THEN 4
			ELSE -1
		END [Status],
		PerformerUserName,
		PerformerSigningTime,
		PerformerComment,
		VerifierUserName,
		VerifierSigningTime,
		VerifierComment
	FROM dbo.ElectronicSignature
	WHERE Id = @ESignatureId;
	
	SELECT 
		@ErrorCode = 1,
		@ErrorMessage = 'Success';
	
END
ELSE
BEGIN
 
	SELECT
		NULL Id,
		NULL [Status],
		NULL PerformerUserName,
		NULL PerformerSigningTime,
		NULL PerformerComment,
		NULL VerifierUserName,
		NULL VerifierSigningTime,
		NULL VerifierComment
		
	SELECT 
		@ErrorCode = -1,
		@ErrorMessage = 'ESignature not found';
	
END;
 
