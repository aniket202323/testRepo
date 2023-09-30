Create Procedure dbo.spEMAC_UpdateDetailsSignatureLevel
@AT_Id int,
@ESignature_Level int = NULL,
@User_Id int
AS
Declare @Insert_Id int
INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'UpdateDetailsSignatureLevel',
             Convert(nVarChar(10),@AT_Id) + ','  + 
 	      Convert(nVarChar(10),@ESignature_Level) + ','  + 
             Convert(nVarChar(10),@User_Id), dbo.fnServer_CmnGetDate(getUTCdate()))
SELECT @Insert_Id = Scope_Identity()
update alarm_templates set ESignature_Level = @ESignature_Level where at_id = @AT_Id
UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
WHERE Audit_Trail_Id = @Insert_Id
