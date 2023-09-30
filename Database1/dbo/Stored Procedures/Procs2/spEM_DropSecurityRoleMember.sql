CREATE PROCEDURE dbo.spEM_DropSecurityRoleMember
  @User_Role_Security_Id int,
  @User_Id   int
  AS
  --
  -- Return Codes:
  --
  --   0 = Success
  --
  --
   DECLARE @Insert_Id integer 
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_DropSecurityRoleMember',
                 convert(nVarChar(10),@User_Role_Security_Id)  + ','  + Convert(nVarChar(10), @User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  BEGIN TRANSACTION
  --
  -- Delete the security role member.
  --
  DELETE FROM User_Role_Security WHERE User_Role_Security_Id = @User_Role_Security_Id
  --
  -- Commit the transaction and return success.
  --
  COMMIT TRANSACTION
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
