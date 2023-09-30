Create Procedure dbo.spEMEC_GetCurrDetESigLevel 
@EC_Id int,
@Case int,
@ESignature_Level int,
@User_Id int
AS
declare @Association tinyint,
@Tree_Name_Id int,
@Insert_Id int
INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEMEC_GetCurrDetESigLevel',
        Convert(nVarChar(10),@EC_Id) + ','  + 
        Convert(nVarChar(10),@Case) + ','  + 
 	 Convert(nVarChar(10),@ESignature_Level) + ','  + 
        Convert(nVarChar(10),@User_Id), dbo.fnServer_CmnGetDate(getUTCdate()))
SELECT @Insert_Id = Scope_Identity()
if @Case = 1
  Begin
    Select ESignature_Level from Event_Configuration where EC_Id = @EC_Id
  End
if @Case = 2
  Begin
    Update Event_Configuration set ESignature_Level = @ESignature_Level where EC_Id = @EC_Id
  End
UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
WHERE Audit_Trail_Id = @Insert_Id
