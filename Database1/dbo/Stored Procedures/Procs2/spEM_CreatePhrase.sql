CREATE PROCEDURE dbo.spEM_CreatePhrase
  @Data_Type_Id int,
  @Phrase_Value nvarchar(25),
  @Phrase_Order Smallint_Natural,
  @User_Id int,
  @Phrase_Id    int OUTPUT
 AS
  --
  -- Return Codes:
  --
  --   0 = Success
  --   1 = Error: Can't create phrase.
  --
 DECLARE @Insert_Id integer 
Insert into Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_CreatePhrase',
                 convert(nVarChar(10),@Data_Type_Id) + ','  + Convert(nVarChar(25), @Phrase_Value) + ','  + Convert(varchar(5),@Phrase_Order) +  ',' + Convert(nVarChar(10), @User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
select @Insert_Id = Scope_Identity()
 INSERT INTO Phrase(Data_Type_Id, Phrase_Value, Phrase_Order)
    VALUES(@Data_Type_Id, @Phrase_Value, @Phrase_Order)
  IF @@ERROR = 0 
    BEGIN
      SELECT @Phrase_Id = Scope_Identity()
      IF @Phrase_Id IS NULL
 	 BEGIN
 	      Update  Audit_Trail set EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 1 where Audit_Trail_Id = @Insert_Id
 	      RETURN(1)
 	 END
    END
  ELSE
    BEGIN
 	 Update  Audit_Trail set EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 1 where Audit_Trail_Id = @Insert_Id
 	 RETURN(1)
    END
  Update  Audit_Trail set EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 0,Output_Parameters = convert(nVarChar(10),@Phrase_Id) where Audit_Trail_Id = @Insert_Id
  RETURN(0)
