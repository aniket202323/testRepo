CREATE PROCEDURE dbo.spEM_PutEmailRecipientAddress
  @ER_Id               int,
  @ER_Address          VarChar(70),
  @IsActive 	  	  	    Int,
  @UseHeader           Int,
  @User_Id 	  	  	  	 Int
  AS
  DECLARE @Insert_Id integer 
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_PutEmailRecipientAddress',
                Convert(nVarChar(10),@ER_Id) + ','  + 
                @ER_Address + ',' +
                Convert(nVarChar(10),@IsActive) + ','  + 
                Convert(nVarChar(10),@UseHeader) + ','  + 
 	  	  	  	 Convert(nVarChar(10),@User_Id),dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  --
  -- Update existing recipient.
  --
  UPDATE Email_Recipients
    SET ER_Address = @ER_Address,Is_Active = @IsActive, Standard_Header_Mode = @UseHeader WHERE ER_Id = @ER_Id
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
