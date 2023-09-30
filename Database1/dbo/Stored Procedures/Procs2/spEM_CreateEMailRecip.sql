CREATE PROCEDURE dbo.spEM_CreateEMailRecip
  @Recipname  nvarchar(30),
  @In_User_Id int,
  @Reip_Id  int OUTPUT
  AS
  --
  -- Return Codes:
  --
  --   0 = Success
  --   1 = Can't create user.
  --
   DECLARE @Insert_Id integer 
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@In_User_Id,'spEM_CreateEMailRecip',
                @Recipname + ','  + Convert(nVarChar(10), @In_User_Id),dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
 BEGIN TRANSACTION
  INSERT INTO Email_Recipients(ER_Desc,ER_Address,Standard_Header_Mode,Is_Active) VALUES(@Recipname,' ',0,1)
  SELECT @Reip_Id = Scope_Identity()
  IF @Reip_Id IS NULL
    BEGIN
      ROLLBACK TRANSACTION
      UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 1 WHERE Audit_Trail_Id = @Insert_Id
      RETURN(1)
    END
  COMMIT TRANSACTION
   UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 0,Output_Parameters = convert(nVarChar(10),@Reip_Id)
     WHERE Audit_Trail_Id = @Insert_Id
 RETURN(0)
