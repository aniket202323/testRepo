CREATE PROCEDURE dbo.spEM_DropSecurityRole
  @Role_Id int,
  @User_Id   int
  AS
  Declare @Active integer,
          @Insert_Id integer 
  --
  -- Return Codes:
  --
  --   0 = Success
  --
  SELECT @Active = Active from Users WHERE User_Id = @Role_Id
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_DropSecurityRole',
                 convert(nVarChar(10),@Role_Id)  + ','  + Convert(nVarChar(10), @User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  BEGIN TRANSACTION
  IF @Active = 1
    Begin
      --
      -- Deactive the security role and delete its members.
      --
      DELETE FROM User_Role_Security WHERE Role_User_Id = @Role_Id
      DELETE FROM User_Security WHERE User_Id = @Role_Id
      UPDATE Users Set Active = 0 WHERE User_Id = @Role_Id
      --
      -- Commit the transaction and return success.
      --
      COMMIT TRANSACTION
    End
  ELSE
    Begin
      --
      -- Activate the security role.
      --
      UPDATE Users Set Active = 1 WHERE User_Id = @Role_Id
      --
      -- Commit the transaction and return success.
      --
      COMMIT TRANSACTION
    End
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
