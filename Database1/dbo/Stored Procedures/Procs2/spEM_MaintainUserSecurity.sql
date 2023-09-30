CREATE PROCEDURE dbo.spEM_MaintainUserSecurity
  @Mode int,
  @Member_Desc nvarchar(50),
  @WindowsInfoText nVarChar(200),
  @User_Id int
  AS
  --
  -- Mode:
  --
  --   0 = Changing from Proficy User defined Roles to NT User Group defined Roles
  --   1 = Changing from NT User Group defined Roles to Proficy User defined Roles
  --
  -- Return Codes:
  --
  --   0 = Success
  --   1 = Failed
  --
  DECLARE @Insert_Id integer, @rc integer, @New_Security_User_Id integer, @Role_Based_Security integer
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_MaintainUserSecurity',
                convert(nVarChar(10), @Mode) + ',' + @Member_Desc + ',' + convert(nvarchar(50), @WindowsInfoText) + ',' + convert(nVarChar(10), @User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  IF @Mode = 0
    BEGIN
      BEGIN TRANSACTION
      DELETE FROM User_Role_Security
      EXECUTE @Rc =  spEM_CreateSecurityRoleMember 34, NULL, @Member_Desc, @User_Id, Null, @New_Security_User_Id Output
      --Unable to create New member (NT User Group) under Administrator Security Role - Rollback
      IF @New_Security_User_Id IS NULL or @Rc <> 0 
        BEGIN
          ROLLBACK TRANSACTION
          UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 1
 	      WHERE Audit_Trail_Id = @Insert_Id
          RETURN(1)
        END
      UPDATE Users Set WindowsUserInfo = @WindowsInfoText, Role_Based_Security = 1 WHERE User_Id = @User_Id
      COMMIT TRANSACTION
    END
  ELSE
    BEGIN
      BEGIN TRANSACTION
      DELETE FROM User_Role_Security
      SELECT @Role_Based_Security = Role_Based_Security FROM Users WHERE User_Id = @User_Id
      IF @Role_Based_Security = 1
        BEGIN
          EXECUTE @Rc =  spEM_CreateSecurityRoleMember 34, @User_Id, '', @User_Id, Null, @New_Security_User_Id Output
          --Unable to create New member (Proficy User) under Administrator Security Role - Rollback
          IF @New_Security_User_Id IS NULL or @Rc <> 0 
            BEGIN
              ROLLBACK TRANSACTION
              UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 1
 	          WHERE Audit_Trail_Id = @Insert_Id
              RETURN(1)
            END
        END
      ELSE
        --Must have Admin to Admin if allowed to change Manage Security
        BEGIN
          INSERT into User_Security (User_Id, Group_Id, Access_Level) Values (@User_Id, 1, 4)
        END
      COMMIT TRANSACTION
    END
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 0
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
