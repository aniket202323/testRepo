CREATE PROCEDURE dbo.spEM_RenameEmailGroup
  @Group_Id  int,
  @Groupname nVarChar(100),
  @User2_Id int
  AS
  DECLARE @Insert_Id integer 
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User2_Id,'spEM_RenameEmailGroup',
                Convert(nVarChar(10),@Group_Id) + ','  + 
                @Groupname + ','  + 
                Convert(nVarChar(10),@User2_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  --
  -- Return Code: 0 = Success. 
  --
  UPDATE Email_Groups SET EG_Desc = @Groupname WHERE EG_Id = @Group_Id
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
