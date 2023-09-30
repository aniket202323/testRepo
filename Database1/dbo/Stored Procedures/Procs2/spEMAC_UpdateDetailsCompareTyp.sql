Create Procedure dbo.spEMAC_UpdateDetailsCompareTyp
@AT_Id int,
@Compare_Type tinyint,
@User_Id int
as
Declare @Insert_Id int
INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEMAC_UpdateDetailsCompareTyp',
             Convert(nVarChar(10),@AT_Id) + ','  + 
 	 Convert(nVarChar(10),@Compare_Type) + ','  + 
             Convert(nVarChar(10),@User_Id), dbo.fnServer_CmnGetDate(getUTCdate()))
SELECT @Insert_Id = Scope_Identity()
update alarm_templates set DQ_Criteria = @Compare_Type where at_id = @AT_Id
UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
WHERE Audit_Trail_Id = @Insert_Id
