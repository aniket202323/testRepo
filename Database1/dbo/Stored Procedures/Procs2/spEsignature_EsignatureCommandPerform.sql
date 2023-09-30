
CREATE PROCEDURE dbo.spEsignature_EsignatureCommandPerform 
								@PerformCommentId           INT,
                                @PerformReasonLevel1Id      INT,
								@PerformNode				VARCHAR(50),
								@SigningContext				NVARCHAR (MAX),
								@UserId    INT
								                                                
AS
BEGIN
		IF  @PerformReasonLevel1Id IS NOT NULL AND  @PerformReasonLevel1Id<1
			BEGIN
				SELECT Code = 'InvalidData',
					   Error = 'Invalid PerformReasonLevel1Id',
					   ErrorType = 'ParameterResourceNotFound',
					   PropertyName1 = 'PerformReasonLevel1Id',
					   PropertyName2 = '',
					   PropertyName3 = '',
					   PropertyName4 = '',
					   PropertyValue1 = @PerformReasonLevel1Id,
					   PropertyValue2 = '',
					   PropertyValue3 = '',
					   PropertyValue4 = ''
				RETURN
			END
		DECLARE  @PerformTime datetime
		SET @PerformTime = dbo.fnServer_CmnConvertToDbTime(GetUTCDate(),'UTC')
			INSERT INTO [dbo].[ESignature] (Perform_Comment_Id,Perform_Reason_Id,Perform_Node,Signing_Context,Perform_User_Id,Perform_Time)
			VALUES (@PerformCommentId,@PerformReasonLevel1Id,@PerformNode,@SigningContext,@UserId,@PerformTime);
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
			av.Signature_Id=Scope_Identity()	
END
