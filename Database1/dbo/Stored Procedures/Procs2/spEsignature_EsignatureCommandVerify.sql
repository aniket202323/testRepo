
CREATE PROCEDURE dbo.spEsignature_EsignatureCommandVerify 
								@SignatureId				INT,
								@VerifyCommentId			INT,
								@VerifyReasonLevel1Id       INT,
								@VerifyNode					VARCHAR(50),
								@SigningContext				NVARCHAR (MAX),
								@UserId    INT
																		                                                     
AS
BEGIN
		IF NOT EXISTS(SELECT  Signature_Id FROM Esignature WHERE Signature_Id = @SignatureId)
        BEGIN
            SELECT Code = 'InvalidData',
                   Error = 'SignatureId not found',
                   ErrorType = 'ParameterResourceNotFound',
                   PropertyName1 = 'SignatureId',
                   PropertyName2 = '',
                   PropertyName3 = '',
                   PropertyName4 = '',
                   PropertyValue1 = @SignatureId,
                   PropertyValue2 = '',
                   PropertyValue3 = '',
                   PropertyValue4 = ''
            RETURN
        END
		IF  @VerifyReasonLevel1Id IS NOT NULL AND  @VerifyReasonLevel1Id<0
        BEGIN
            SELECT Code = 'InvalidData',
                   Error = 'invalid VerifyReasonLevel1Id',
                   ErrorType = 'ParameterResourceNotFound',
                   PropertyName1 = 'VerifyReasonLevel1Id',
                   PropertyName2 = '',
                   PropertyName3 = '',
                   PropertyName4 = '',
                   PropertyValue1 = @VerifyReasonLevel1Id,
                   PropertyValue2 = '',
                   PropertyValue3 = '',
                   PropertyValue4 = ''
            RETURN
        END
		DECLARE  @VerifyUserId INT, @PerformUserId INT, @existingSigningContext NVARCHAR(MAX);
		SELECT @VerifyUserId =  Verify_User_Id, @PerformUserId = Perform_User_Id, @existingSigningContext = Signing_Context FROM Esignature WHERE Signature_Id = @SignatureId
		IF @VerifyUserId IS NOT NULL
        BEGIN
		DECLARE  @VerifyUserName NVARCHAR(510)=(SELECT UserName FROM USERS where USER_ID=@VerifyUserId);
            SELECT Code = 'SignatureAlreadyVerified',
                   Error = 'Signature record already verified',
                   ErrorType = 'SignatureAlreadyVerified',
                   PropertyName1 = 'VerifiedUser',
                   PropertyName2 = '',
                   PropertyName3 = '',
                   PropertyName4 = '',
                   PropertyValue1 = @VerifyUserName,
                   PropertyValue2 = '',
                   PropertyValue3 = '',
                   PropertyValue4 = ''
            RETURN
        END
		
		DECLARE  @VerifyingUserName NVARCHAR(510)=(SELECT UserName FROM USERS where USER_ID=@UserId);
        DECLARE  @PerformUserName NVARCHAR(510)=(SELECT UserName FROM USERS where USER_ID=@PerformUserId);
		IF @VerifyingUserName=@PerformUserName
		BEGIN
            SELECT Code = 'InvalidData',
                   Error = 'Performing and verifying user should not be same',
                   ErrorType = 'PerformerAndVerifierAreSame',
                   PropertyName1 = 'VerifyUserName',
                   PropertyName2 = '',
                   PropertyName3 = '',
                   PropertyName4 = '',
                   PropertyValue1 = @VerifyingUserName,
                   PropertyValue2 = '',
                   PropertyValue3 = '',
                   PropertyValue4 = ''
            RETURN
        END
		DECLARE  @VerifyTime datetime
		SET @VerifyTime = dbo.fnServer_CmnConvertToDbTime(GetUTCDate(),'UTC')
		SET @SigningContext =  COALESCE(@SigningContext, @existingSigningContext);
		UPDATE ESignature SET Verify_Comment_Id =@VerifyCommentId, Verify_Reason_Id =@VerifyReasonLevel1Id,Verify_Node = @VerifyNode,Verify_User_Id = @UserId,Verify_Time=@VerifyTime, Signing_Context = @SigningContext
		WHERE Signature_Id = @SignatureId
		SELECT 
			SignatureID=av.Signature_Id,
			SigningContext=av.Signing_Context,
			PerformCommentId= av.Perform_Comment_Id,
			PerformReasonLevel1Id=av.Perform_Reason_Id,
			PerformNode=av.Perform_Node,
			PerformingUserName=(SELECT UserName FROM USERS where USER_ID=av.Perform_User_Id),
			PerformTime=dbo.fnServer_CmnConvertFromDbTime(av.Perform_Time,'UTC'),
			VerifyCommentId= av.Verify_Comment_Id,
			VerifyReasonLevel1Id=av.Verify_Reason_Id,
			VerifyNode=av.Verify_Node,
			VerifyingUserName=(SELECT UserName FROM USERS where USER_ID=av.Verify_User_Id),
			VerifyTime=dbo.fnServer_CmnConvertFromDbTime(av.Verify_Time,'UTC')
		FROM Esignature av WHERE 
		av.Signature_Id= @SignatureId
END
