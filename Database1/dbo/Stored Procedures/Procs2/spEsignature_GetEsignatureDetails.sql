
CREATE PROCEDURE dbo.spEsignature_GetEsignatureDetails 
								@SignatureId				INT
																		                                                     
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
