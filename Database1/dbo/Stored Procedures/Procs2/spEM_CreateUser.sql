CREATE PROCEDURE dbo.spEM_CreateUser
  @Username  nvarchar(30),
  @In_User_Id int,
  @User_Id  int OUTPUT,
  @ImportUserDesc nvarchar(255) = Null
  AS
  --
  -- Return Codes:
  --
  --   0 = Success
  --   1 = Can't create user.
  --
   DECLARE @Insert_Id integer 
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@In_User_Id,'spEM_CreateUser',
                @Username + ','  + Convert(nVarChar(10), @In_User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
 BEGIN TRANSACTION
  --Insert the current time as the password so that they don't have a NULL password initially
  If @ImportUserDesc Is Null
 	 INSERT INTO Users(Username, [Password]) VALUES(@Username, Cast(dbo.fnServer_CmnGetDate(getUTCdate()) As nVarChar(100)))
  ELSE
 	 INSERT INTO Users(Username, [Password],User_Desc) VALUES(@Username, Cast(dbo.fnServer_CmnGetDate(getUTCdate()) As nVarChar(100)),@ImportUserDesc)
  SELECT @User_Id = USER_ID 
 	 From Users
 	 WHERE Username = @Username
  IF @User_Id IS NULL
    BEGIN
      ROLLBACK TRANSACTION
      UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 1 WHERE Audit_Trail_Id = @Insert_Id
      RETURN(1)
    END
  COMMIT TRANSACTION
   UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 0,Output_Parameters = convert(nVarChar(10),@User_Id)
     WHERE Audit_Trail_Id = @Insert_Id
 RETURN(0)
