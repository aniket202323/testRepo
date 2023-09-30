 
 
CREATE 	PROCEDURE [dbo].[spLocal_MPWS_GENL_CreateAuditRecord]
	@ErrorCode			INT				OUTPUT,
	@ErrorMessage		VARCHAR(500)	OUTPUT,
	@Message			VARCHAR(1023),
	@Context			VARCHAR(255),
	@User				VARCHAR(255),
	@Location			VARCHAR(255),
	@OccurrenceTime		DATETIME,
	@Type				VARCHAR(50),
	@Topic				VARCHAR(50),
	@Version			INT					= 1,
	@ESignatureId		UniqueIdentifier	= NULL
	
AS	
 
SET NOCOUNT ON
 
/* -------------------------------------------------------------------------------
 
declare @ErrorCode INT, @ErrorMessage VARCHAR(500)
exec dbo.spLocal_MPWS_GENL_CreateAuditRecord @ErrorCode OUTPUT, @ErrorMessage OUTPUT, 'description', 'Dispense Container D01_1235', 'Jessica', 'PW01DS01','2016-07-22 15:24:12','Preweigh','Dispense'
select @ErrorCode, @ErrorMessage
 
	Date			Version	Build	Author  
	22-Jul-2016		001		001		Susan Lee (GEIP)		Initial development	
 
 
------------------------------------------------------------------------------- */
 
DECLARE
	@ErrorSeverity INT,
	@RecordTime		DATETIME,
	@RecordId		INT,
	@EsigCount		INT,
	@UserCount		INT			
	
SELECT
	@ErrorCode		= 1,
	@ErrorMessage	= 'Success',
	@RecordTime		= GETDATE();
 
 
------------------------------------------------------------------------------
-- Data validation
------------------------------------------------------------------------------	
-- valid ESignature
IF @ESignatureId IS NOT NULL
BEGIN
	SELECT	@EsigCount = COUNT(*)
	FROM	dbo.ElectronicSignature 
	WHERE	Id = @ESignatureId
 
	IF @EsigCount = 0 
	BEGIN
	SELECT
			@ErrorCode		= -1,
			@ErrorMessage	= 'ESignatureId not found';
	END;
END;	
	
-- valid user
SELECT  @UserCount = COUNT(*)
FROM	dbo.Users
WHERE	Username = @User
 
IF @UserCount = 0
BEGIN
SELECT
		@ErrorCode		= -2,
		@ErrorMessage	= 'User not found';
END;	
	
-- valid datetime
IF ISDATE(@OccurrenceTime) = 0
BEGIN
 
	SELECT
		@ErrorCode		= -3,
		@ErrorMessage	= 'Invalid Date/Time';
 
END;
 
------------------------------------------------------------------------------
-- Get next Id
------------------------------------------------------------------------------	
SELECT @RecordId = MAX (Id) + 1
FROM	dbo.AuditRecord WITH (NOLOCK)	
 
------------------------------------------------------------------------------
-- Insert into AuditRecord
------------------------------------------------------------------------------	
IF @ErrorCode = 1
BEGIN
 
	BEGIN TRY
	
		BEGIN TRAN
		
		INSERT dbo.AuditRecord 
			(Id,Message,Context,r_User,Location,RecordTime,OccurrenceTime,TypeId,TopicId,Version,ElectronicSignatureId)
			VALUES
			(@RecordId,@Message,@Context,@User,@Location,@RecordTime,@OccurrenceTime,@Type,@Topic,@Version,@ESignatureId)
 
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
 
