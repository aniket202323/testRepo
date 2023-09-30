CREATE PROCEDURE dbo.spEM_PutUserData 
  @User_Id   int,
  @User_Desc nvarchar(50),
  @Password  nvarchar(30),
  @Active bit,
  @UserView Int,
  @WindowsLoginInfo nvarchar(30),
  @User1_Id int,
  @RoleBased bit,
  @MixedMode bit,
  @UseSSO bit,
  @SSOUserId nvarchar(50),
  @ReturnResults Int = 1
  AS
Select @ReturnResults = isnull(@ReturnResults,1)
DECLARE @Insert_Id integer,
        @OldRoleBased bit,
        @IsAdmin integer,
        @rc integer
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User1_Id,'spEM_PutUserData',
                Convert(nVarChar(10),@User_Id) + ','  + 
 	  	 LTRIM(RTRIM(@User_Desc)) + ',(password),'  + 
 	  	 Convert(nVarChar(1),@Active) + ','  + 
 	  	 Coalesce(Convert(nVarChar(10),@UserView),'null') + ','  + 
 	  	 Coalesce(Convert(nvarchar(30),@WindowsLoginInfo),'null') + ','  + 
 	  	 Coalesce(@SSOUserId,'null') + ','  + 
 	  	 Convert(nVarChar(1),Coalesce(@UseSSO,0)) + ','  + 
                Convert(nVarChar(1), @RoleBased) + ','  +
                Convert(nVarChar(1), @MixedMode) + ','  +
 	  	 Convert(nVarChar(10),@User1_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  SELECT @OldRoleBased = Role_Based_Security From Users WHERE User_Id = @User_Id
  SELECT @IsAdmin = 
            CASE
               WHEN EXISTS(SELECT Access_Level FROM User_Security us
                     WHERE (us.User_Id = @User_Id) and (us.Group_Id = 1) and (us.Access_Level = 4)) Or
                    EXISTS(SELECT Access_Level FROM User_Security us
                           JOIN User_Role_Security ur on ur.User_Id = @User_Id
                     WHERE (us.User_Id = 34) and (us.Group_Id = 1) and (us.Access_Level = 4))
               THEN 1
               ELSE 0
            END
  --
  -- Return Codes:
  --
  --   0 = Success.
  --
  -- Update the user.
  --
  BEGIN TRANSACTION
  UPDATE Users_base
    SET User_Desc = @User_Desc, Password = @Password, Active = @Active,View_Id = @UserView, 
    WindowsUserInfo = @WindowsLoginInfo, Role_Based_Security = @RoleBased, 
    Mixed_Mode_Login = @MixedMode,
    UseSSO=@UseSSO, SSOUserId=@SSOUserId
    WHERE User_Id = @User_Id
  IF @OldRoleBased <> @RoleBased
    BEGIN
      IF @OldRoleBased = 0
        BEGIN
          Delete from User_Security WHERE User_Id = @User_Id
          Delete from User_Role_Security WHERE User_Id = @User_Id
          If @IsAdmin = 1
            BEGIN
              --User Id 34 is actually the Administrator Role (Give Admin To Admin through the Administrator Role for this user
              Insert Into User_Role_Security (Role_User_Id, User_Id, GroupName) Values (34, @User_Id, '')
            END
          If @User_Id = @User1_Id
            BEGIN
              Insert Into User_Security (User_Id, Group_Id, Access_Level) Values (@User_Id, 1, 4)
            END
        END
      ELSE
        BEGIN
          EXECUTE @Rc =  spCSS_MaintainUserSecurity @User_Id
          --Unable to Update Security for this User - Rollback
          IF @Rc <> 0 
            BEGIN
              ROLLBACK TRANSACTION
              UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 1
 	          WHERE Audit_Trail_Id = @Insert_Id
              RETURN(1)
            END
          Delete from User_Role_Security Where User_Id = @User_Id
        END
    END
  COMMIT TRANSACTION
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
  IF @OldRoleBased <> @RoleBased and @ReturnResults = 1
    BEGIN
    --Return info to refresh the tree for this user (Role based security)
      Select User_Role_Security_Id, Role_User_Id, User_Id, GroupName 
        From User_Role_Security
          Where User_Id = @User_Id
    --Return into to refresh the tree for this user (Group based security)
      Select Security_Id, User_Id, Group_Id, Access_Level
        From User_Security
          Where User_Id = @User_Id
    END
  RETURN(0)
