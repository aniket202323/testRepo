CREATE PROCEDURE dbo.spEM_ImportUser
  @Username  nvarchar(30),
  @PassWord  nvarchar(30),
  @WindowsUserInfo nVarChar(200),
  @SecurityUserId int,
  @In_User_Id int
  AS
  --
  -- Return Codes:
  --
  --   0 = Success
  --   1 = Can't create user.
  --
  DECLARE @Insert_Id integer 
  DECLARE @User_Id  integer
  DECLARE @Role_Based tinyint
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@In_User_Id,'spEM_ImportUser',
                @Username + ','  + @Password + ',' + @WindowsUserInfo + ',' + Convert(nVarChar(10), @SecurityUserId) + ',' + Convert(nVarChar(10), @In_User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  SELECT @Role_Based = Role_Based_Security From Users Where User_Id = @SecurityUserId
 BEGIN TRANSACTION
  INSERT INTO Users(Username, Password, WindowsUserInfo, Role_Based_Security) VALUES(@Username, @Password, @WindowsUserInfo, Coalesce(@Role_Based, 0))
  SELECT @User_Id = USER_ID From Users WHERE Username = @Username
  IF @User_Id IS NULL
    BEGIN
      ROLLBACK TRANSACTION
      UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 1 WHERE Audit_Trail_Id = @Insert_Id
      RETURN(1)
    END
-- If specified, copy Security Groups for new user
IF @SecurityUserId > 0
   IF @Role_Based = 1
      BEGIN
       INSERT INTO User_Role_Security (Role_User_Id, User_Id, GroupName)
          Select ur.Role_User_Id, @User_Id, u.Username
            From User_Role_Security ur
            Join Users u on u.User_Id = @User_Id
            Where ur.user_id = @SecurityUserId
       END
   ELSE
     BEGIN
       INSERT INTO User_Security (User_Id,Group_Id,Access_Level)
 	   Select @User_Id,Group_Id,Access_Level
 	     From User_Security
 	     Where User_Id = @SecurityUserId
     END
 COMMIT TRANSACTION
 UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0,Output_Parameters = convert(nVarChar(10),@User_Id)
    WHERE Audit_Trail_Id = @Insert_Id
   SELECT User_Id = @User_Id
   IF @Role_Based = 1
     BEGIN
       Select Role_User_Id, User_Id, User_Role_Security_Id
         From User_Role_Security
          Where User_Id = @User_Id
     END
   ELSE
     BEGIN
       Select Security_Id,User_Id,Group_Id,Access_Level
         From User_Security
          Where User_Id = @User_Id
     END
RETURN(0)
