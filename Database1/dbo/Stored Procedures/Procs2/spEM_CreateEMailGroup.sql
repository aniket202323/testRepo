CREATE PROCEDURE dbo.spEM_CreateEMailGroup
  @GroupName  nvarchar(30),
  @In_User_Id int,
  @Group_Id  int OUTPUT
  AS
  --
  -- Return Codes:
  --
  --   0 = Success
  --   1 = Can't create user.
  --
   DECLARE @Insert_Id integer 
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@In_User_Id,'spEM_CreateEMailGroup',
                @GroupName + ','  + Convert(nVarChar(10), @In_User_Id),dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
 BEGIN TRANSACTION
  INSERT INTO Email_Groups(EG_Desc) VALUES(@GroupName)
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
