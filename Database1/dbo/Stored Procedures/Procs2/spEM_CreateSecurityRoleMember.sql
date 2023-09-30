CREATE PROCEDURE dbo.spEM_CreateSecurityRoleMember
  @Role_User_Id int,
  @User_Id_1 int,
  @Member_Desc nVarChar(200),
  @User_Id int,
  @Domain nVarChar(100), 
  @User_Role_Security_Id   int OUTPUT
  AS
  --
  -- Return Codes:
  --
  --   0 = Success
  --   1 = Can't create member.
  --
  DECLARE @Insert_Id integer 
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_CreateSecurityRoleMember',
                @Member_Desc + ','  + convert(nVarChar(10), @Role_User_Id) + ',' + Convert(nVarChar(10), @User_Id_1) + ',' + convert(nVarChar(10), @User_Id) + ',' + @Domain,
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  BEGIN TRANSACTION
  INSERT INTO User_Role_Security(Role_User_Id, User_Id, GroupName, Domain) VALUES (@Role_User_Id, @User_Id_1, Coalesce(@Member_Desc, ''), Coalesce(@Domain, ''))
  SELECT @User_Role_Security_Id = Scope_Identity()
  IF @User_Role_Security_Id IS NULL
    BEGIN
      ROLLBACK TRANSACTION
      UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 1 WHERE Audit_Trail_Id = @Insert_Id
      RETURN(1)
    END
  COMMIT TRANSACTION
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 0,Output_Parameters = convert(nVarChar(10),@User_Role_Security_Id)
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
