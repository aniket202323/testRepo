Create Procedure dbo.spFF_LookupApproverNameByTestId
  @Test_Id BigInt,
  @Approved_By nVarChar(30) OUTPUT AS
  SELECT @Approved_By = u.username
    FROM Tests t
    join Users u on u.user_id = t.second_user_id
    WHERE t.Test_Id = @Test_Id
