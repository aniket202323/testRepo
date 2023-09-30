CREATE PROCEDURE dbo.spEM_DropGroup
  @PUG_Id int,
  @User_Id int
 AS
  --
  -- Return Codes:
  --
  --       0 = Success
  --   50101 = Variable Delete Error
  --   50102 = Group Delete Error
  -- Declare local variables.
  --
  DECLARE @GrpReturnCode int, @GrpVar_Id int, @SaveReturnCode int
  --
  -- Begin a transaction.
  --
  DECLARE @Insert_Id integer 
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_DropGroup',
                 convert(nVarChar(10),@PUG_Id)  + ','  + Convert(nVarChar(10), @User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  SELECT @SaveReturnCode = 0
  --
  -- Create a local table containing the id's of all the variables under
  -- the production group to be delected.
  --
    DECLARE Grp_Cursor CURSOR
    FOR SELECT Var_Id FROM Variables WHERE PUG_Id = @PUG_Id
    FOR READ ONLY
    OPEN Grp_Cursor
    Fetch_Next_GrpVar:
    FETCH NEXT FROM Grp_Cursor INTO @GrpVar_Id
    IF @@FETCH_STATUS = 0
    BEGIN
 	 EXECUTE @GrpReturnCode = spEM_DropVariable @GrpVar_Id, @User_Id
 	 IF @GrpReturnCode = 0 GOTO Fetch_Next_GrpVar
        ELSE
         BEGIN
           SELECT @SaveReturnCode = @GrpReturnCode 
           GOTO Fetch_Next_GrpVar
         END
    END
    ELSE IF @@FETCH_STATUS = -1
 	    SELECT @GrpReturnCode = 0
         ELSE
 	  BEGIN
 	   RAISERROR('Fetch error for Var_Cursor (@@FETCH_STATUS = %d).', 11, -1,
 	     @@FETCH_STATUS)
 	   SELECT @GrpReturnCode = 50102
         END
  DEALLOCATE Grp_Cursor
  -- If successful, delete the production group to be dropped and commit the transaction.
  -- Otherwise, roll the transaction back.
  --
  IF @GrpReturnCode = 0
    BEGIN
      DELETE FROM PU_Groups WHERE PUG_Id = @PUG_Id
--      IF @@ERROR <> 0 SELECT @GrpReturnCode = 50102
--      COMMIT TRANSACTION
    END
--  ELSE ROLLBACK TRANSACTION
  IF @SaveReturnCode = 0 SELECT @SaveReturnCode = @GrpReturnCode
  --
  -- Return status.
  --
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = @SaveReturnCode
     WHERE Audit_Trail_Id = @Insert_Id
RETURN(@SaveReturnCode)
