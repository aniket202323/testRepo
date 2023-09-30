CREATE PROCEDURE dbo.spEM_PutPhrase 
  @Phrase_Id   int,
  @Active bit, 
  @User1_Id int,
  @Comment_Required bit
  AS
DECLARE @Insert_Id integer,
        @rc integer
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User1_Id,'spEM_PutPhrase',
                Convert(nVarChar(10),@Phrase_Id) + ','  + 
 	  	 Convert(nVarChar(1),@Active) + ',' + 
 	  	 Convert(nVarChar(1),@Comment_Required),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  --
  -- Return Codes:
  --
  --   0 = Success.
  --
  -- Update the user.
  --
  BEGIN TRANSACTION
  UPDATE Phrase
    SET Active = @Active, Comment_Required = @Comment_Required
    WHERE Phrase_Id = @Phrase_Id
  COMMIT TRANSACTION
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
