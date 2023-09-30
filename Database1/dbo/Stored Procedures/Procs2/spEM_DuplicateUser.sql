CREATE PROCEDURE dbo.spEM_DuplicateUser
  @Original_User_Id int,
  @New_User_Desc    nvarchar(50),
  @User_Id   int
  AS
  --
  -- Return Codes:
  --
  --   0 = Success
  --   1 = Error: Can't create duplicate User
  --
  -- begin our transaction.
  --
   DECLARE @Insert_Id integer,@Rc Int, @RoleBased int, @MixedMode int, @ViewId int
  Declare @New_User_Id Int
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_DuplicateUser',
                 convert(nVarChar(10), @Original_User_Id) + ','  + @New_User_Desc + ','  + Convert(nVarChar(10), @User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  SELECT @RoleBased = Role_Based_Security, @ViewId = View_Id FROM Users Where User_Id = @Original_User_Id
  SELECT @MixedMode = Mixed_Mode_Login FROM Users Where User_Id = @Original_User_Id
  BEGIN TRANSACTION
  --
  -- Create the duplicate User.
  --
   Execute @Rc =  spEM_CreateUser @New_User_Desc,@User_Id,@New_User_Id Output
  IF @New_User_Id IS NULL or @Rc <> 0 
    BEGIN
      ROLLBACK TRANSACTION
      UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 1
 	  WHERE Audit_Trail_Id = @Insert_Id
      RETURN(1)
    END
  Update Users Set Mixed_Mode_Login = @MixedMode, View_Id = @ViewId Where User_Id = @New_User_Id
  -- Set RoleBasedSecurity indicator based on original User_Id
  If @RoleBased = 1
    BEGIN
      UPDATE Users Set Role_Based_Security = 1 Where User_Id = @New_User_Id
    END
  --
  -- Commit our transaction and return success.
  --
  -- Duplicate Security for the new user (Role Based or User Group based)
  IF @RoleBased = 1
    BEGIN
      Insert into User_Role_Security (Role_User_Id, User_Id, GroupName)
        Select Role_User_Id, @New_User_Id, ''
          From User_Role_Security
          Where User_Id = @Original_User_Id
    END
  ELSE
    BEGIN
      Insert into User_Security (User_Id,Group_Id,Access_Level)
 	 Select @New_User_Id,Group_Id,Access_Level
 	   From User_Security
 	   Where User_Id = @Original_User_Id
    END
  COMMIT TRANSACTION
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0,Output_Parameters = convert(nVarChar(10),@New_User_Id)
     WHERE Audit_Trail_Id = @Insert_Id
   Select user_id = @New_User_Id
   IF @RoleBased = 1
     BEGIN
       Select Role_User_Id, User_Id, User_Role_Security_Id
         From User_Role_Security
          Where User_Id = @New_User_Id
     END
   ELSE
     BEGIN
       Select Security_Id,User_Id,Group_Id,Access_Level
         From User_Security
          Where User_Id = @New_User_Id
     END
  --Copy User Parameters
  Insert into User_Parameters (User_Id, Parm_Id, Hostname, Value, Parm_Required)
    Select @New_User_Id, Parm_Id, Hostname, Value, Parm_Required
      From User_Parameters
        Where User_Id = @Original_User_Id
  RETURN(0)
