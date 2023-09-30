CREATE PROCEDURE dbo.spEM_DropPhrase
  @Phrase_Id int,
  @User_Id int
 AS
Declare @Phrase_Order  Smallint_Natural,
        @Data_Type_Id int
  --
  -- Return Codes:
  --
  --   0 = Success
  DECLARE @Insert_Id integer 
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_DropPhrase',
                 convert(nVarChar(10),@Phrase_Id)  + ','  + Convert(nVarChar(10), @User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  --
  -- Delete the phrase.
  --
  -- need to reorder phrase order
  -- 
  SELECT @Phrase_Order = Phrase_Order,@Data_Type_Id = Data_Type_Id FROM Phrase WHERE Phrase_Id = @Phrase_Id
  DELETE FROM Phrase WHERE Phrase_Id = @Phrase_Id
  UPDATE Phrase Set Phrase_Order = Phrase_Order - 1 WHERE Phrase_Order > @Phrase_Order AND Data_Type_Id = @Data_Type_Id
  --
  -- Return success.
  --
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
