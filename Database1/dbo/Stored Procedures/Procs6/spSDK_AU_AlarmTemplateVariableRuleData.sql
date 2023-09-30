CREATE procedure [dbo].[spSDK_AU_AlarmTemplateVariableRuleData]
@AppUserId int,
@Id int OUTPUT,
@AlarmTemplate varchar(100) ,
@AlarmTemplateId int ,
@AlarmVariableRule varchar(100) ,
@AlarmVariableRuleId int ,
@AlarmPriority varchar(100) ,
@AlarmPriorityId int 
AS
DECLARE @ReturnMessages TABLE(msg VarChar(100))
INSERT INTO @ReturnMessages(msg)
 	 EXECUTE spEM_IEImportAlarmRules 	 @AlarmTemplate,@AlarmVariableRule,@AlarmPriority,Null,Null,Null,Null,@AppUserId
IF EXISTS(SELECT 1 FROM @ReturnMessages)
BEGIN
 	 SELECT msg FROM @ReturnMessages
 	 RETURN(-100)
END
IF @Id Is Null
BEGIN
 	 SELECT @Id = ATVRD_Id 
 	  	 FROM Alarm_Template_Variable_Rule_Data a
 	  	  	  	  WHERE a.AT_Id = @AlarmTemplateId and a.Alarm_Variable_Rule_Id = @AlarmVariableRuleId
 	 IF @Id IS NULL
 	 BEGIN
 	  	 SELECT 'Create Alarm Template Variable Rule Data failed'
 	  	 RETURN(-100)
 	 END
END
Return(1)
