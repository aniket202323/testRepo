Create Procedure dbo.spAL_CreateTest
  @Var_Id int,
  @Entry_By int,
  @Result_On datetime,
  @Test_Id BigInt OUTPUT,
  @Entry_On datetime OUTPUT as
  -- Declare local variables.
  DECLARE @Dummy_Id bigint
  -- Get our new entry on date/time.
  SELECT @Entry_On = dbo.fnServer_CmnGetDate(getutcdate())
  -- Make sure that the test does not already exist.
  SELECT @Dummy_Id = NULL
  SELECT @Dummy_Id = Test_Id
    FROM Tests
    WHERE (Var_Id = @Var_Id) AND (Result_On = @Result_On)
  IF @Dummy_Id IS NOT NULL RETURN(4)
  -- Add the test.
  INSERT Tests(Var_Id, Result_On, Canceled, Result, Entry_On, Entry_By)
    VALUES(@Var_Id, @Result_On, 0, NULL, @Entry_On, @Entry_By)
  -- Get the test id.
  SELECT @Test_Id = Scope_Identity()
  IF @Test_Id IS NULL RETURN(5)
  -- Return successfully.
  RETURN(100)
