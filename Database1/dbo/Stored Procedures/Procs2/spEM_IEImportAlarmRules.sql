CREATE PROCEDURE dbo.spEM_IEImportAlarmRules
 	 @Desc 	  	  	 nVarChar(100),
 	 @Rule 	  	  	 nVarChar(100),
 	 @Priority 	  	 nVarChar(100),
 	 @SPCVarType 	  	 nVarChar(100), --SPC Group
 	 @FirePriority 	 nVarChar(100), --SPC
 	 @nValue 	  	  	 nVarChar(100), --SPC
 	 @mValue 	  	  	 nVarChar(100), --SPC
 	 @UserId 	  	  	 Int
AS
Declare 	 @ATId int,
 	     @AlarmRuleId int,
        @APId int,
 	  	 @AlarmTypeId 	 INT,
 	  	 @SPCVarTypeId INT
Select @ATId = Null
Select @AlarmRuleId = Null
Select @APId = Null
SELECT @AlarmTypeId = Null
------------------------------------------------------------------------------------------
-- Trim Parameters
------------------------------------------------------------------------------------------
Select @Desc = LTrim(RTrim(@Desc))
Select @Rule = LTrim(RTrim(@Rule))
Select @Priority = LTrim(RTrim(@Priority))
Select @SPCVarType = LTrim(RTrim(@SPCVarType))
Select @FirePriority = LTrim(RTrim(@FirePriority))
Select @nValue = LTrim(RTrim(@nValue))
Select @mValue = LTrim(RTrim(@mValue))
IF @Desc = '' SELECT @Desc = Null
IF @Rule = '' SELECT @Rule = Null
IF @Priority = '' SELECT @Priority = Null
IF @SPCVarType = '' SELECT @SPCVarType = Null
IF @FirePriority = '' SELECT @FirePriority = Null
IF @nValue = '' SELECT @nValue = Null
IF @mValue = '' SELECT @mValue = Null
-- Verify Arguments 
If  @Desc IS NULL
BEGIN
 	 Select 'Failed - Alarm Template Description Missing'
 	 Return(-100)
END
SELECT @ATId = AT_Id,@AlarmTypeId = Alarm_Type_Id
 	 FROM Alarm_Templates
 	 WHERE AT_Desc = @Desc
If @ATId IS NULL
BEGIN
 	 Select 'Failed - Alarm Template Not Found'
 	 Return(-100)
END
If @Rule IS NULL
 BEGIN
   Select 'Failed - Alarm Rule Description Missing'
   Return(-100)
 END
If @Priority IS NULL
BEGIN
 	 Select 'Failed - Alarm Priority Description Missing'
 	 Return(-100)
END
SELECT @APId = AP_Id
FROM  Alarm_Priorities 
WHERE AP_Desc = @Priority
If @APId IS NULL
BEGIN
 	 Select 'Failed - Alarm Priority Description Not Found'
 	 Return(-100)
END
------------------------------------------------------------------------------------------
--Insert or Update Alarm Rules
------------------------------------------------------------------------------------------
IF @AlarmTypeId NOT IN (1,2,4) 
BEGIN
 	 Select 'Failed - Alarm type not supported'
 	 Return(-100)
END
IF @AlarmTypeId = 4 --SPC Group
BEGIN
 	 If @SPCVarType IS NULL
 	 BEGIN
 	  	 Select 'Failed - Alarm Variable Type For SPC Group required'
 	  	 Return(-100)
 	 END
 	 SELECT @SPCVarTypeId = SPC_Group_Variable_Type_Id
 	  	 FROM SPC_Group_Variable_Types
 	  	 WHERE SPC_Group_Variable_Type_Desc = @SPCVarType
 	 If @SPCVarTypeId IS NULL
 	 BEGIN
 	  	 Select 'Failed - Alarm Variable Type For SPC Group Not Found'
 	  	 Return(-100)
 	 END
END
IF @AlarmTypeId IN( 2,4)
BEGIN
 	 If @FirePriority IS NULL
 	 BEGIN
 	  	 Select 'Failed - Firing order for SPC required'
 	  	 Return(-100)
 	 END
 	 If @nValue IS NULL
 	 BEGIN
 	  	 Select 'Failed - nValue for SPC required'
 	  	 Return(-100)
 	 END
 	 If @mValue IS NULL
 	 BEGIN
 	  	 Select 'Failed - mValue for SPC required'
 	  	 Return(-100)
 	 END
 	 Select @AlarmRuleId = Alarm_SPC_Rule_Id 
 	  	 from Alarm_SPC_Rules
 	  	 where Alarm_SPC_Rule_Desc = @Rule
END
IF @AlarmTypeId = 1 --Variable
BEGIN
 	 Select @AlarmRuleId = Alarm_Variable_Rule_Id 
 	  	 from Alarm_Variable_Rules
 	  	 where Alarm_Variable_Rule_Desc = @Rule
END
If @AlarmRuleId IS NULL
 BEGIN
   Select 'Failed - Alarm Rule Not Found'
   Return(-100)
 END
--select @ATId, @AlarmRuleId, @AlarmRuleId, @nValue, @mValue, @Priority, @APId, @SPCVarTypeId, 1, @UserId
IF  @AlarmTypeId IN (2,4) --SPC
BEGIN
 	 EXECUTE spEMAC_UpdateSPCTriggers @ATId, @AlarmRuleId, @AlarmRuleId, @nValue, @mValue, @FirePriority, @APId, @SPCVarTypeId, 1, @UserId
END
ELSE
BEGIN
 	 EXECUTE spEMAC_UpdateGeneralTriggers @ATId, @AlarmRuleId,  @APId, 1, @UserId
END
Return(0)
