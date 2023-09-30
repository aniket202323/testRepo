CREATE Procedure dbo.spEMAC_DeleteAT
@AT_Id int,
@User_Id int
AS
declare @Comment_Id int,
@Insert_Id int
INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEMAC_DeleteAT',
             Convert(nVarChar(10),@AT_Id) + ','  + 
             Convert(nVarChar(10),@User_Id), dbo.fnServer_CmnGetDate(getUTCdate()))
SELECT @Insert_Id = Scope_Identity()
select @Comment_Id = comment_id
from alarm_templates
where at_id = @AT_Id
if @Comment_Id is not null
  exec spCSS_InsertDeleteComment @AT_Id, 6, @User_Id, 1, null, @Comment_Id
Delete from Alarm_Template_SPC_Rule_Property_Data
Where ATSRD_Id in (select ATSRD_Id from Alarm_Template_SPC_Rule_Data Where AT_Id = @AT_Id)
Delete from Alarm_Template_SPC_Rule_Data where AT_Id = @AT_Id
Delete from Alarm_Template_Variable_Rule_Data where AT_Id = @AT_Id
Delete from alarm_templates where at_id = @AT_Id
UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
WHERE Audit_Trail_Id = @Insert_Id
