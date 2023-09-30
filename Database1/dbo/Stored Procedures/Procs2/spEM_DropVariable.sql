CREATE PROCEDURE dbo.spEM_DropVariable
  @Var_Id int,
  @User_Id   int
 AS
  --
  -- Return Codes:
  --
  --   0 = Success
  --   50101 = Variable
  --
  -- Begin a transaction.
  --
  DECLARE @ReturnCode int, 
 	       @VarReturnCode int,
 	       @Insert_Id integer 
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_DropVariable',
                 convert(nVarChar(10),@Var_Id) + ','  + Convert(nVarChar(10), @User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  --
  -- Begin a transaction.
  --
--  BEGIN TRANSACTION
  SELECT @VarReturnCode = 0
  --
  -- Create a local table containing the id's of the variable to be deleted and
  -- any child variables of this variable (which are also to be deleted).
  --
  SELECT Var_Id = @Var_Id INTO #Var
  INSERT INTO #Var SELECT Var_Id FROM Variables WHERE PVar_Id = @Var_Id
  --
  -- Remove any parent references to the variable to be deleted.
  --
  UPDATE Variables_Base SET PVar_Id = NULL WHERE PVar_Id = @Var_Id
  UPDATE Variables_Base SET Sampling_Reference_Var_Id = NULL WHERE Sampling_Reference_Var_Id = @Var_Id
  --
  -- Drop all variables to be deleted.
  --
  DECLARE Var_Cursor CURSOR FOR SELECT Var_Id FROM #Var FOR READ ONLY
  OPEN Var_Cursor
  Fetch_Next_Var:
  FETCH NEXT FROM Var_Cursor INTO @Var_Id
  IF @@FETCH_STATUS = 0
    BEGIN
      EXECUTE @ReturnCode = spEM_DropVariableSlave @Var_Id
      IF @ReturnCode = 0 GOTO Fetch_Next_Var
      ELSE
       BEGIN
         SELECT @VarReturnCode = @ReturnCode 
         GOTO Fetch_Next_Var
       END
    END
  ELSE IF @@FETCH_STATUS = -1
    SELECT @ReturnCode = 0
  ELSE
    BEGIN
      RAISERROR('Fetch error for Var_Cursor (@@FETCH_STATUS = %d).', 11, -1,
       @@FETCH_STATUS)
      SELECT @ReturnCode = 50101
    END
  DEALLOCATE Var_Cursor
  --
  -- Drop the temporary variable table.
  --
  DROP TABLE #Var
  --
  -- Commit the transaction if successful. Otherwise, roll it back.
  --
--  IF @ReturnCode = 0 COMMIT TRANSACTION
--   ELSE ROLLBACK TRANSACTION
  IF @VarReturnCode = 0 SELECT @VarReturnCode = @ReturnCode
  --
  -- Return status.
  --
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = @VarReturnCode
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(@VarReturnCode)
