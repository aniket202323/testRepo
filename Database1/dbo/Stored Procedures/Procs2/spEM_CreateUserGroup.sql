CREATE PROCEDURE dbo.spEM_CreateUserGroup
  @Group_Desc nvarchar(50),
  @User_Id int,
  @Group_Id   int OUTPUT
  AS
  --
  -- Return Codes:
  --
  --   0 = Success
  --   1 = Can't create user group.
  --
  DECLARE @Insert_Id integer 
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_CreateUserGroup',
                @Group_Desc + ','  + Convert(nVarChar(10), @User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  BEGIN TRANSACTION
  INSERT INTO Security_Groups(Group_Desc) VALUES(@Group_Desc)
  SELECT @Group_Id = Scope_Identity()
  IF @Group_Id IS NULL
    BEGIN
      ROLLBACK TRANSACTION
      UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 1 WHERE Audit_Trail_Id = @Insert_Id
      RETURN(1)
    END
  COMMIT TRANSACTION
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 0,Output_Parameters = convert(nVarChar(10),@Group_Id)
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
