CREATE PROCEDURE dbo.spEM_EditLangTrans
@Prompt_Number int,
@Prompt_String varchar(8000) = NULL,
@User_Id int,
@Language_id Int
AS
Declare @Insert_Id int
INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_EditLangTrans',
             Convert(nVarChar(10),@Prompt_Number) + ','  + 
             @Prompt_String + ','  + 
             Convert(nVarChar(10),@User_Id), dbo.fnServer_CmnGetDate(getUTCdate()))
SELECT @Insert_Id = Scope_Identity()
Declare @Language_Data_Id int
Declare @Override_Lang_Id int
Set @Override_Lang_Id = 0 - @Language_Id -1
select @Language_Data_Id = Language_Data_Id
From Language_Data
Where Prompt_Number = @Prompt_Number
and Language_Id = @Override_Lang_Id
If @Language_Data_Id is NULL and @Prompt_String is NOT NULL --Insert
  Begin
    Insert Into Language_Data (Language_Id, Prompt_Number, Prompt_String)
 	  	 Values (@Override_Lang_Id, @Prompt_Number, @Prompt_String) 
  End
Else If @Language_Data_Id is NOT NULL and @Prompt_String is NOT NULL --Update
  Begin
    Update Language_Data
 	  	 Set Prompt_String = @Prompt_String
 	  	 Where Language_Data_Id = @Language_Data_Id
  End
Else If @Prompt_String is NULL --Delete
  Begin
    Delete From Language_Data Where Language_Data_Id = @Language_Data_Id
  End
UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
WHERE Audit_Trail_Id = @Insert_Id
