
CREATE PROCEDURE dbo.spActivities_GetTestHistory
@TestId	INT,
@Page INT = 0,
@PageSize INT = 20,
@TotalRecordsCount INT = 0 OUTPUT


 AS 

 DECLARE @startRow Int
 DECLARE @endRow Int

 SET @Page = coalesce(@Page,0)
 SET @PageSize = coalesce(@PageSize,20)

	SELECT 
	    Test_History_Id AS TestHistoryId  ,
		Test_Id       AS TestId,
		dbo.fnServer_CmnConvertFromDbTime(Entry_On,'UTC') AS EntryOn,
		dbo.fnServer_CmnConvertFromDbTime(Result_On,'UTC') AS ResultOn,
		Canceled      AS Canceled,
		Array_Id      AS ArrayId,
		Comment_Id    AS CommentId,
		U.Username    AS EntryBy,
		Event_Id      AS EventId,
		Locked        AS IsLocked,
		Signature_Id AS ESignatureId,
		dbo.fnServer_CmnConvertFromDbTime(Modified_On,'UTC') AS ModifiedOn,
		IsVarMandatory AS IsVarMandatory,
		Var_Id AS VariableId,
		Result AS Result
	FROM Test_History T
	JOIN Users U ON U.User_Id = T.Entry_By
	WHERE Test_Id = @TestId
		ORDER BY Modified_On DESC
    OFFSET @PageSize * (@Page) ROWS
    FETCH NEXT @PageSize ROWS ONLY OPTION (RECOMPILE);

	SELECT 
    @TotalRecordsCount = count(1)
		FROM Test_History
		WHERE Test_Id = @TestId

