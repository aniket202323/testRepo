 
 
/*	-------------------------------------------------------------------------------
	dbo.spLocal_MPWS_GENL_CreateESignatureRecord
	
	Date			Version		Build	Author  
	15-Aug-2016		001			001		Jim Cameron (GEIP)		Initial development
	27-Nov-2017		001			002		Susan Lee (GE Digital)	Add PWActionConfigId and PWActionData to parameter and write to 
test
 
DECLARE @ErrorCode INT, @ErrorMessage VARCHAR(500), @ESig UNIQUEIDENTIFIER
EXEC dbo.spLocal_MPWS_GENL_CreateESignatureRecord @ErrorCode OUTPUT, @ErrorMessage OUTPUT, 
@Esig OUTPUT, 'PG Key Users', 'false', '', 'I validate that I am cancelling this PO', 'Planning', 'CancelPO',4,'PPId=314'
 
SELECT @ErrorCode, @ErrorMessage, @ESig
 
 
select * from dbo.electronicsignature
*/	-------------------------------------------------------------------------------
 
CREATE PROCEDURE [dbo].[spLocal_MPWS_GENL_CreateESignatureRecord]
	@ErrorCode			INT					OUTPUT,
	@ErrorMessage		VARCHAR(500)		OUTPUT,
	@ESignatureId		UNIQUEIDENTIFIER	OUTPUT,
	
	@ValidPerformers	VARCHAR(255),
	@VerifierRequired	VARCHAR(5),
	@ValidVerifiers		VARCHAR(255),
	@Description		VARCHAR(1024),
	@Function			VARCHAR(50),
	@Action				VARCHAR(50),
	@PWActionConfigId	INT,
	@PWActionData		VARCHAR(250)		-- data related to the item being verified, such as Event_Id, PP_Id, Prod_Id, etc.
											-- format as key/value pairs such as 'Event_Id=12345;Prod_Id=6789'
--WITH ENCRYPTION 
AS
 
SET NOCOUNT ON;
 
DECLARE
	@ErrorSeverity			INT,
	@ElectronicSignatureId	UNIQUEIDENTIFIER;
	
DECLARE @Inserted TABLE
(
	Id	UNIQUEIDENTIFIER
);

SELECT
	@ErrorCode = 0,
	@ErrorMessage = 'Initialized';


--IF NOT EXIST (SELECT Id				
--FROM dbo.Local_MPWS_GENL_ESigActionConfig esac
--WHERE esac.Id = @PWActionConfigId )
--BEGIN
--END

IF @ErrorCode >= 0
BEGIN
 
	BEGIN TRY
	
		BEGIN TRAN
 
			SET @ESignatureId = NEWID();
			INSERT dbo.ElectronicSignature (Id, [Status], [Description], VerifierRequired, LastModifiedTime, PerformerGroupName, VerifierGroupName, [Version])
				SELECT
					@ESignatureId, 'Awaiting Performer', @Description, CASE @VerifierRequired WHEN 'True' THEN 1 ELSE 0 END, GETDATE(), @ValidPerformers, @ValidVerifiers, 1

				
 
			INSERT dbo.Local_MPWS_GENL_ESigActionData (ESigActionConfigId, ElectronicSignatureId, ESigActionData)
				VALUES (@PWActionConfigId, @ESignatureId, @PWActionData)

 
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
 
