CREATE PROCEDURE dbo.spEM_CreateUserSecurity
  @Group_Id     int,
  @User_Id      int,
  @Access_Level tinyint,
  @C_User_Id int,
  @Security_Id  int OUTPUT
  AS
  --
  -- Return Codes:
  --
  --   0 = Success
  --   1 = Unable to create user security.
  --
  DECLARE @Insert_Id integer 
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@C_User_Id,'spEM_CreateUserSecurity',
                 convert(nVarChar(10),@Group_Id) + ','  + Convert(nVarChar(10), @User_Id) + ','  + Convert(nVarChar(10), @Access_Level) + ','  + Convert(nVarChar(10), @C_User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  BEGIN TRANSACTION
  INSERT User_Security(Group_Id, User_Id, Access_Level) 
    VALUES(@Group_Id, @User_Id, @Access_Level)
  SELECT @Security_Id = Scope_Identity()
  IF @Security_Id IS NULL
    BEGIN
      ROLLBACK TRANSACTION
      UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 1 WHERE Audit_Trail_Id = @Insert_Id
      RETURN(1)
    END
  COMMIT TRANSACTION
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 0,Output_Parameters = convert(nVarChar(10),@Security_Id)
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
