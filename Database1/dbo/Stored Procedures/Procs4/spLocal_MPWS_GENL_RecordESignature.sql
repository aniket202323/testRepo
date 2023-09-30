 
 
/*	-------------------------------------------------------------------------------
	dbo.spLocal_MPWS_GENL_RecordESignature
	
	Date			Version		Build	Author  
	09-Aug-2016		001			001		Jim Cameron (GEIP)		Initial development
 
test
 
DECLARE @ErrorCode INT, @ErrorMessage VARCHAR(500)
EXEC dbo.spLocal_MPWS_GENL_RecordESignature @ErrorCode OUTPUT, @ErrorMessage OUTPUT, '20150101', '20160731'
 
SELECT @ErrorCode, @ErrorMessage
 
*/	-------------------------------------------------------------------------------
 
CREATE  PROCEDURE [dbo].[spLocal_MPWS_GENL_RecordESignature]
	@ErrorCode			INT				OUTPUT,
	@ErrorMessage		VARCHAR(500)	OUTPUT,
 
	@PWActionConfigId	INT,
	@PWActionData		VARCHAR(250),		-- data related to the item being verified, such as Event_Id, PP_Id, Prod_Id, etc.
											-- format as key/value pairs such as 'Event_Id=12345;Prod_Id=6789'
	@PerformerTime		DATETIME,
	@PerformerUserName	VARCHAR(50),
	@PerformerComment	VARCHAR(2048),
	@VerifierUserName	VARCHAR(50),
	@VerifierComment	VARCHAR(2048)
 
AS
 
SET NOCOUNT ON;
 
DECLARE
	@ErrorSeverity			INT,
	@ElectronicSignatureId	UNIQUEIDENTIFIER;
	--@PerformerCommentId	INT,
	--@VerifierCommentId	INT,
	--@CSId				INT,
	--@SignatureId		INT;
	
DECLARE @Inserted TABLE
(
	Id	UNIQUEIDENTIFIER
);
 
SELECT
	@ErrorCode = 0,
	@ErrorMessage = 'Initialized';
 
--SET @CSId = (SELECT CS_Id FROM dbo.Comment_Source WHERE CS_Desc = 'PWESig');
 
IF NOT EXISTS (SELECT [User_Id] FROM dbo.Users_Base WHERE Username = @PerformerUserName)
BEGIN
	SELECT
		@ErrorCode = -1,
		@ErrorMessage = 'Performer UserName: ' + @PerformerUserName + ' not found';
END;
	
IF NOT EXISTS (SELECT [User_Id] FROM dbo.Users_Base WHERE Username = @VerifierUserName) 
	AND (SELECT ESigVerifierEnabled FROM dbo.Local_MPWS_GENL_ESigActionConfig WHERE Id = @PWActionConfigId) = 1
BEGIN
	SELECT
		@ErrorCode = -2,
		@ErrorMessage = 'Verifier UserName: ' + @VerifierUserName + ' not found';
END;
 
--IF @CSId IS NULL
--BEGIN
--	SELECT
--		@ErrorCode = -3,
--		@ErrorMessage = 'Comment Source Id (CS_Id) for "PWESig" not found in dbo.Comment_Source';
--END;
 
IF @ErrorCode >= 0
BEGIN
 
	BEGIN TRY
	
		BEGIN TRAN
 
			INSERT dbo.ElectronicSignature ([Status], [Description], VerifierRequired, LastModifiedTime,
											PerformerGroupName, PerformerUserName, PerformerComment, PerformerSigningTime,
											VerifierGroupName, VerifierUserName, VerifierComment, VerifierSigningTime,
											[Version])
				OUTPUT inserted.Id INTO @Inserted
				SELECT
					esac.PWAction, esac.PWFunction, esac.ESigVerifierEnabled, @PerformerTime,
					esac.ValidUserGroup, @PerformerUserName, @PerformerComment, @PerformerTime,
					esac.ESigVerifierGroup, @VerifierUserName, @VerifierComment, @PerformerTime,
					1
				FROM dbo.Local_MPWS_GENL_ESigActionConfig esac
				WHERE esac.Id = @PWActionConfigId
				
			SET @ElectronicSignatureId = (SELECT Id FROM @Inserted);
 
			INSERT dbo.Local_MPWS_GENL_ESigActionData (ESigActionConfigId, ElectronicSignatureId, ESigActionData)
				VALUES (@PWActionConfigId, @ElectronicSignatureId, @PWActionData)
 
			--IF ISNULL(@PerformerComment, '') <> ''
			--BEGIN
 
			--	INSERT dbo.Comments (Modified_On, [User_Id], CS_Id, Comment, Comment_Text, Entry_On)
			--		OUTPUT inserted.Comment_Id INTO @Inserted
			--		VALUES(@PerformerTime, @PerformerUserId, @CSId, @PerformerComment, @PerformerComment, @PerformerTime);
					
			--	SET @PerformerCommentId = (SELECT Id FROM @Inserted);
			--	DELETE @Inserted;
				
			--	UPDATE dbo.Comments
			--		SET TopOfChain_Id = @PerformerCommentId
			--		WHERE Comment_Id = @PerformerCommentId;
					
			--END;
 
			--IF ISNULL(@VerifierComment, '') <> ''
			--BEGIN
 
			--	INSERT dbo.Comments (Modified_On, [User_Id], CS_Id, Comment, Comment_Text, Entry_On)
			--		OUTPUT inserted.Comment_Id INTO @Inserted
			--		VALUES(@PerformerTime, @VerifierUserId, @CSId, @VerifierComment, @VerifierComment, @PerformerTime);
					
			--	SET @VerifierCommentId = (SELECT Id FROM @Inserted);
			--	DELETE @Inserted;
				
			--	UPDATE dbo.Comments
			--		SET TopOfChain_Id = @VerifierCommentId
			--		WHERE Comment_Id = @VerifierCommentId;
					
			--END;
 
			--INSERT dbo.ESignature (Perform_Comment_Id, Perform_Node, Perform_Time, Perform_Time_MS, Perform_User_Id, Verify_Comment_Id, Verify_Node, Verify_Time, Verify_Time_MS, Verify_User_Id)
			--	OUTPUT inserted.Signature_Id INTO @Inserted
			--	VALUES(@PerformerCommentId, @PerformerLocation, @PerformerTime, 0, @PerformerUserId, @VerifierCommentId, @PerformerLocation, @PerformerTime, 0, @VerifierUserId);
 
			--SET @SignatureId = (SELECT Id FROM @Inserted);
			--DELETE @Inserted;
 
		-- TODO: Need a place to put Signature_Id
		
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
 
