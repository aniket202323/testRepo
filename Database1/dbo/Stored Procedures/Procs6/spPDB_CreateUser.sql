CREATE PROCEDURE dbo.spPDB_CreateUser
  @Username  Varchar_Username,
  @In_User_Id int,
  @User_Id  int OUTPUT,
  @User_Desc nvarchar(255) = NULL
  AS
  --
  -- Return Codes:
  --
  --   0 = Success
  --   1 = Can't create user.
  --
   DECLARE @Insert_Id integer 
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@In_User_Id,'spPDB_CreateUser',
                @Username + ','  + Convert(nvarchar(10), @In_User_Id),
                getdate())
  SELECT @Insert_Id = Scope_Identity()
 BEGIN TRANSACTION
  INSERT INTO Users(Username,User_Desc) VALUES(@Username,@User_Desc)
  SELECT @User_Id = Scope_Identity()
  IF @User_Id IS NULL
    BEGIN
      ROLLBACK TRANSACTION
      UPDATE  Audit_Trail SET EndTime = getdate(),returncode = 1 WHERE Audit_Trail_Id = @Insert_Id
      RETURN(1)
    END
  COMMIT TRANSACTION
   UPDATE  Audit_Trail SET EndTime = getdate(),returncode = 0,Output_Parameters = convert(nvarchar(10),@User_Id)
     WHERE Audit_Trail_Id = @Insert_Id
 RETURN(0)
