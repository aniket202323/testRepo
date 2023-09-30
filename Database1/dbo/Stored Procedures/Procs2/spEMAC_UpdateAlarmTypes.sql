Create Procedure dbo.spEMAC_UpdateAlarmTypes
@AT_Id int,
@AlarmTypeId int,
@User_Id int
AS
Declare @Insert_Id int, @Old_Alarm_Type_Id int
DECLARE @StringSetting TinyInt
INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEMAC_UpdateAlarmTypes',
 	 Convert(nVarChar(10),@AlarmTypeId) + ','  + 
 	 Convert(nVarChar(10),@AT_Id) + ','  + 
             Convert(nVarChar(10),@User_Id), dbo.fnServer_CmnGetDate(getUTCdate()))
SELECT @Insert_Id = Scope_Identity()
SELECT @StringSetting = Null
IF @AlarmTypeId < 0 
BEGIN
 	 SELECT @StringSetting  = (@AlarmTypeId * -1) -1
 	 SELECT @AlarmTypeId = 1 
END
SELECT @Old_Alarm_Type_Id = Alarm_Type_Id From Alarm_Templates Where AT_Id = @AT_Id
If @Old_Alarm_Type_Id = 1
  Begin
    Update Alarm_Templates set Lower_Entry = 0, Lower_Reject = 0, Lower_Warning = 0, Lower_User = 0, Target = 0, Upper_User = 0, Upper_Warning = 0, Upper_Reject = 0, Upper_Entry = 0
    Where AT_Id = @AT_Id
  End
else if @Old_Alarm_Type_Id = 2
  Begin
    Delete from Alarm_Template_SPC_Rule_Property_Data
    Where ATSRD_Id in (select ATSRD_Id from Alarm_Template_SPC_Rule_Data Where AT_Id = @AT_Id)
    Delete from Alarm_Template_SPC_Rule_Data where AT_Id = @AT_Id
  End
else if @Old_Alarm_Type_Id = 4
  Begin
    Delete from Alarm_Template_SPC_Rule_Property_Data
    Where ATSRD_Id in (select ATSRD_Id from Alarm_Template_SPC_Rule_Data Where AT_Id = @AT_Id)
    Delete from Alarm_Template_SPC_Rule_Data where AT_Id = @AT_Id
  End
Update Alarm_Templates set Alarm_Type_Id = @AlarmTypeId,String_Specification_Setting = @StringSetting
where AT_Id = @AT_Id
UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
WHERE Audit_Trail_Id = @Insert_Id
