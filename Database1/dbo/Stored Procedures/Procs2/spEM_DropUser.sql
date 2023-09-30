CREATE PROCEDURE dbo.spEM_DropUser
  @User_Id int,
  @User2_Id   int
  AS
  --
  -- Return Codes:
  --
  --   0 = Success
  --   50106 = Cannot delete - Tests have been entered (50101 - 50105 used for dropping variables)
  -- Begin a transaction.
  --
  --
  -- Delete all user security records involving this user.
  --
  DECLARE @Insert_Id integer 
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User2_Id,'spEM_DropUser',
                 convert(nVarChar(10),@User_Id) + ','  + Convert(nVarChar(10), @User2_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  IF (SELECT COUNT(*) FROM Tests WHERE Entry_By = @User_Id) <> 0
 	 BEGIN
  	      UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 50106
 	  	  WHERE Audit_Trail_Id = @Insert_Id
 	      RETURN(50106)
 	 END
  BEGIN TRANSACTION
  DELETE FROM User_Security WHERE User_Id = @User_Id
  --
  -- Replace all references to this user with references to
  -- the ComXClient user.
  --
  UPDATE Comments SET User_Id = 1 WHERE User_Id = @User_Id
  UPDATE Transactions SET Approved_By = 1 WHERE Approved_By = @User_Id
  UPDATE Event_History SET User_Id = 1 WHERE User_Id = @User_Id
--  UPDATE Production_Events SET User_Id = 1 WHERE User_Id = @User_Id
  UPDATE Waste_Event_Details SET User_Id = 1 WHERE User_Id = @User_Id
  UPDATE Timed_Event_Details SET User_Id = 1 WHERE User_Id = @User_Id
--  UPDATE Test_History SET Entry_By = 1 WHERE Entry_By = @User_Id
--  UPDATE Tests SET Entry_By = 1 WHERE Entry_By = @User_Id
  --
  -- Delete the user.
  --
  DELETE FROM Users WHERE User_Id = @User_Id
  --
  -- Commit the transaction and return success.
  --
  COMMIT TRANSACTION
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
