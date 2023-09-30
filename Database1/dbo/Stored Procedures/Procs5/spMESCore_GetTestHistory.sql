Create Procedure [dbo].[spMESCore_GetTestHistory] (
@TestId bigint)
AS
SELECT Test_Id, Entry_On,Entry_By,Result,Result_On,Canceled,u.Username
FROM test_History t
LEFT JOIN Users u on u.User_Id = t.Entry_By
WHERE Test_Id = @TestId
