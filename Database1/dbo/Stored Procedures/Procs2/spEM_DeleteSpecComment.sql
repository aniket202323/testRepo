CREATE PROCEDURE dbo.spEM_DeleteSpecComment
  @Comment_Id   int,
  @User_Id int
   AS
  --
  -- Return Codes:
  --
  --   0 = Success.
  --
  -- Begin a transaction.
  --
  DECLARE @Insert_Id integer 
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_DeleteSpecComment',
                 convert(nVarChar(10),@Comment_Id) + ','  + Convert(nVarChar(10), @User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  BEGIN TRANSACTION
  --
  -- Delete the comment. (Changed 04/22/98 - Deletes Causing to much bottle necking)
  --
      UPDATE Comments SET Comment = '',ShouldDelete = 1 WHERE Comment_Id = @Comment_ID
  -- DELETE FROM Comments WHERE Comment_Id = @Comment_Id
  --
  -- Commit the transaction and return success.
  --
  COMMIT TRANSACTION
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 0
     WHERE Audit_Trail_Id = @Insert_Id
 RETURN(0)
