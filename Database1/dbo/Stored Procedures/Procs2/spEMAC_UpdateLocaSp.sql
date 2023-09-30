Create Procedure dbo.spEMAC_UpdateLocaSp
@LocalspName nvarchar(50),
@AT_Id int,
@User_Id int
AS
Declare @Insert_Id int
INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEMAC_UpdateLocaSp',
 	  	  	 @LocalspName + ',' +
             Convert(nVarChar(10),@AT_Id) + ','  + 
             Convert(nVarChar(10),@User_Id), dbo.fnServer_CmnGetDate(getUTCdate()))
SELECT @Insert_Id = Scope_Identity()
Select @LocalspName = REPLACE(@LocalspName,'spLocal_','')
IF @LocalspName = '' Select @LocalspName = Null
update alarm_templates set SP_Name = @LocalspName where at_id = @AT_Id
UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
WHERE Audit_Trail_Id = @Insert_Id
RETURN(0)
