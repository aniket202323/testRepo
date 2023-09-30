Create Procedure dbo.spEMAC_UpdateDetailsCustomText 
@AT_Id int,
@Custom_Text nvarchar(255),
@User_Id int
AS
Declare @Insert_Id int
INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEMAC_UpdateDetailsCustomText',
             Convert(nVarChar(10),@AT_Id) + ','  + 
 	 @Custom_Text + ','  + 
             Convert(nVarChar(10),@User_Id), dbo.fnServer_CmnGetDate(getUTCdate()))
SELECT @Insert_Id = Scope_Identity()
update alarm_templates set Custom_Text = @Custom_Text where at_id = @AT_Id
UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
WHERE Audit_Trail_Id = @Insert_Id
