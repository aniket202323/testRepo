CREATE PROCEDURE dbo.spEM_CreateSpecComment
  @User_Id     int,
  @CS_Id       int,
  @Comment_Id  int OUTPUT
  AS
  --
  --
  -- Return Codes:
  --
  --   0 = Success.
  --   1 = Error: Can't create comment.
  --
  -- Begin a transaction.
  --
  BEGIN TRANSACTION
  --
  -- Create the comment.
  --
   DECLARE @Insert_Id integer 
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_CreateSpecComment',
                 convert(nVarChar(10),@User_Id) + ','  + Convert(nVarChar(10), @CS_Id) ,
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  INSERT Comments(Comment, User_Id, Modified_On, CS_Id) VALUES(' ', @User_Id, dbo.fnServer_CmnGetDate(getUTCdate()), @CS_Id)
  SELECT @Comment_Id = Scope_Identity()
  IF @Comment_Id IS NULL
    BEGIN
      ROLLBACK TRANSACTION
      UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 1 WHERE Audit_Trail_Id = @Insert_Id
      RETURN(1)
    END
  ELSE COMMIT TRANSACTION
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 0,Output_Parameters = convert(nVarChar(10),@Comment_Id)
     WHERE Audit_Trail_Id = @Insert_Id
RETURN(0)
