Create Procedure dbo.spFF_LookupEntryBy
  @Test_Id BigInt,
  @Entry_By nVarChar(30) OUTPUT AS
  SELECT @Entry_By = u.username
    FROM Tests t
    join users u on u.user_id = t.entry_by
    WHERE t.Test_Id = @Test_Id
