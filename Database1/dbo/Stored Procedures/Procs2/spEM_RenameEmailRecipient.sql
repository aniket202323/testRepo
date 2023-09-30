CREATE PROCEDURE dbo.spEM_RenameEmailRecipient
  @Recipient_Id  int,
  @Recipientname nVarChar(100),
  @User2_Id int
  AS 
  DECLARE @Insert_Id integer 
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
  	  VALUES (1,@User2_Id,'spEM_RenameEmailRecipient',
                Convert(nVarChar(10),@Recipient_Id) + ','  + 
                @Recipientname + ','  + 
                Convert(nVarChar(10),@User2_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  --
  -- Return Code: 0 = Success. 
  --
  UPDATE Email_Recipients SET ER_Desc = @Recipientname WHERE ER_Id = @Recipient_Id
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
