CREATE procedure [dbo].[spSDK_AU_AlarmTemplateSPCRuleData_Bak_177]
@AppUserId int,
@Id int OUTPUT,
@AlarmSPCRule varchar(100) ,
@AlarmSPCRuleId int ,
@AlarmTemplate varchar(100) ,
@AlarmTemplateId int ,
@AlarmPriority varchar(100) ,
@AlarmPriorityId int ,
@FiringPriority int ,
@SPCGroupVariableType varchar(100) ,
@SPCGroupVariableTypeId int 
AS
/* 
Can not do SPC rules without SPC_Rule_Data_Properties
EXECUTE spEM_IEImportAlarmRules
 	 @AlarmTemplate,
 	 @AlarmSPCRule,
 	 @AlarmPriority,
 	 @SPCGroupVariableType, --SPC Group
 	 @FiringPriority, --SPC
 	 @nValue 	  	  	 Varchar(100), --SPC
 	 @mValue 	  	  	 Varchar(100), --SPC
 	 @UserId 	  	  	 Int
*/
Declare
  @Status int,
  @ErrorMsg varchar(500)
  Select @ErrorMsg = 'Object does not support Add/Update.' 
  Select @Status = 0
  -- Call to Import/Export SP goes here
  If (@Status <> 1)
    Select @ErrorMsg
  Return(@Status)
