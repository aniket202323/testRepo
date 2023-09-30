
CREATE PROCEDURE dbo.spEsignature_GetEsignatures 
								@SignatureIds				NVARCHAR(MAX),
								@PageSize					INT = 20,
								@PageNum					INT = 0,
								@TotalRowCount				INT =0 OUTPUT
																		                                                     
AS
BEGIN

DECLARE @AllSignatureIds Table (Esig_Id Int)
DECLARE @xml XML
	   IF @SignatureIds IS NOT NULL
	   BEGIN
          SET @xml = cast(('<X>'+replace(@SignatureIds,',','</X><X>')+'</X>') as xml)
          INSERT INTO @AllSignatureIds(Esig_Id)
          SELECT N.value('.', 'int') FROM @xml.nodes('X') AS T(N)
	   END
	--Pagination Provide requested page.

    SET @PageNum = coalesce(@PageNum,0)
    SET @PageSize = coalesce(@PageSize,20)

	if(@SignatureIds IS NULL OR datalength(@SignatureIds)=0)
	BEGIN
		--Result
		SELECT 
			SignatureID=av.Signature_Id,
			SigningContext=av.Signing_Context,
			PerformCommentId= av.Perform_Comment_Id,
			PerformReasonLevel1Id=av.Perform_Reason_Id,
			PerformNode=av.Perform_Node,
			PerformingUserName=PerformUser.UserName,
			PerformTime=dbo.fnServer_CmnConvertFromDbTime(av.Perform_Time,'UTC'),
			VerifyCommentId= av.Verify_Comment_Id,
			VerifyReasonLevel1Id=av.Verify_Reason_Id,
			VerifyNode=av.Verify_Node,
			VerifyingUserName=VerifyUser.UserName,
			VerifyTime=dbo.fnServer_CmnConvertFromDbTime(av.Verify_Time,'UTC')
		FROM Esignature AS av
		LEFT OUTER JOIN Users  PerformUser on PerformUser.USER_ID=av.Perform_User_Id
		LEFT OUTER JOIN Users  VerifyUser on VerifyUser.USER_ID=av.Verify_User_Id
		ORDER BY av.Perform_Time DESC

		OFFSET @PageSize * (@PageNum) ROWS
		FETCH NEXT @PageSize ROWS ONLY OPTION (RECOMPILE);
        
		--Totel Element
    SELECT @TotalRowCount=  COUNT(1) FROM Esignature AS av
	END

	if(@SignatureIds IS NOT NULL OR datalength(@SignatureIds)>0)
	BEGIN
		--Result
		SELECT 
			SignatureID=av.Signature_Id,
			SigningContext=av.Signing_Context,
			PerformCommentId= av.Perform_Comment_Id,
			PerformReasonLevel1Id=av.Perform_Reason_Id,
			PerformNode=av.Perform_Node,
			PerformingUserName=PerformUser.UserName,
			PerformTime=dbo.fnServer_CmnConvertFromDbTime(av.Perform_Time,'UTC'),
			VerifyCommentId= av.Verify_Comment_Id,
			VerifyReasonLevel1Id=av.Verify_Reason_Id,
			VerifyNode=av.Verify_Node,
			VerifyingUserName=VerifyUser.UserName,
			VerifyTime=dbo.fnServer_CmnConvertFromDbTime(av.Verify_Time,'UTC')
		FROM Esignature AS av
		JOIN @AllSignatureIds esigIds on esigIds.Esig_Id=av.Signature_Id
		LEFT OUTER JOIN Users  PerformUser on PerformUser.USER_ID=av.Perform_User_Id
		LEFT OUTER JOIN Users  VerifyUser on VerifyUser.USER_ID=av.Verify_User_Id
		Order By av.Perform_Time DESC
		
		OFFSET @PageSize * (@PageNum) ROWS
		FETCH NEXT @PageSize ROWS ONLY OPTION (RECOMPILE);
		
		--Totel Element
        SELECT @TotalRowCount=  COUNT(1) FROM Esignature AS av 
		JOIN @AllSignatureIds esigIds on esigIds.Esig_Id=av.Signature_Id
	END
END
