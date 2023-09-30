CREATE view SDK_V_PAAlarmEvent
as
select
Alarms.Alarm_Id as Id,
Alarms.Alarm_Id as AlarmEventId,
Alarms.Alarm_Desc as AlarmDescription,
Alarm_Types.Alarm_Type_Desc as AlarmType,
Alarm_Templates.AT_Desc as AlarmTemplate,
Alarm_SPC_Rules.Alarm_SPC_Rule_Desc as AlarmSPCRule,
Alarm_Priorities.AP_Desc as AlarmPriority,
Departments_Base.Dept_Desc as Department,
Prod_Lines_Base.PL_Desc as ProductionLine,
Prod_Units_Base.PU_Desc as ProductionUnit,
COALESCE(Variables.Var_Desc, Production_Plan.Process_Order) as KeyName,
Alarms.Start_Time as StartTime,
Alarms.End_Time as EndTime,
Alarms.Start_Result as StartValue,
Alarms.End_Result as EndValue,
Alarms.Max_Result as MaxValue,
Alarms.Min_Result as MinValue,
cause1.Event_Reason_Name as Cause1,
cause2.Event_Reason_Name as Cause2,
cause3.Event_Reason_Name as Cause3,
cause4.Event_Reason_Name as Cause4,
action1.Event_Reason_Name as Action1,
action2.Event_Reason_Name as Action2,
action3.Event_Reason_Name as Action3,
action4.Event_Reason_Name as Action4,
Alarms.Research_Open_Date as ResearchOpenDate,
Alarms.Research_Close_Date as ResearchCloseDate,
Research_Status.Research_Status_Desc as ResearchStatus,
research.Username as ResearchUserName,
Alarms.Ack as Ack,
Users.Username as AckBy,
Alarms.Ack_On as AckOn,
Alarms.Cause_Comment_Id as CauseCommentId,
Alarms.Action_Comment_Id as ActionCommentId,
Alarms.Research_Comment_Id as ResearchCommentId,
Alarms.Signature_Id as ESignatureId,
Alarms.Action1 as Action1Id,
Alarms.Action2 as Action2Id,
Alarms.Action3 as Action3Id,
Alarms.Action4 as Action4Id,
Alarms.Ack_By as AckById,
Alarms.SubType as AlarmSubTypeId,
Alarms.Alarm_Type_Id as AlarmTypeId,
Alarm_Templates.AP_Id as AlarmPriorityId,
Alarms.ATD_Id as AlarmTemplateVariableDataId,
Alarm_Template_Var_Data.AT_Id as AlarmTemplateId,
Alarms.ATSRD_Id as AlarmTemplateSPCRuleDataId,
Alarms.ATVRD_Id as AlarmTemplateVariableRuleDataId,
Alarms.Cause1 as Cause1Id,
Alarms.Cause2 as Cause2Id,
Alarms.Cause3 as Cause3Id,
Alarms.Cause4 as Cause4Id,
Alarms.Key_Id as KeyId,
Alarms.Research_Status_Id as ResearchStatusId,
Alarms.Source_Id as SourceId,
Variables.Comment_Id as VariableCommentId,
Alarm_Template_SPC_Rule_Data.Alarm_SPC_Rule_Id as AlarmSPCRuleId,
Prod_Units_Base.PU_Id as ProductionUnitId,
Alarms.Research_User_Id as ResearchUserId,
Prod_Lines_Base.Dept_Id as DepartmentId,
Prod_Units_Base.PL_Id as ProductionLineId,
ac.Comment_Text as ActionCommentText,
cc.Comment_Text as CauseCommentText,
rc.Comment_Text as ResearchCommentText,
vc.Comment_Text as VariableCommentText,
.1 as InAlarm,
ED_FieldType_ValidValues.Field_Desc as ESignatureLevel,
Alarm_Templates.Esignature_Level as ESignatureLevelId
FROM Alarms
 INNER JOIN Alarm_Types ON Alarm_Types.Alarm_Type_Id = alarms.Alarm_Type_Id AND Alarm_Types.Alarm_Type_Id IN (1, 2, 3, 4)
 LEFT JOIN Alarm_Template_Var_Data ON Alarm_Template_Var_Data.ATD_Id = alarms.ATD_Id
 LEFT JOIN Alarm_Templates ON Alarm_Templates.AT_Id = Alarm_Template_Var_Data.AT_Id
 LEFT JOIN Alarm_Priorities ON Alarm_Priorities.AP_Id = Alarm_Templates.AP_Id
 LEFT join Variables_Base as Variables on Variables.Var_Id = alarms.Key_Id and Alarms.Alarm_Type_Id IN (1, 2, 4)
 LEFT JOIN Production_Plan ON Production_Plan.PP_Id = alarms.Key_Id and Alarms.Alarm_Type_Id IN (3)
 LEFT JOIN Prod_Units_Base ON Variables.PU_Id = Prod_Units_Base.PU_Id
 LEFT JOIN Prod_Lines_Base ON Prod_Lines_Base.PL_Id = Prod_Units_Base.PL_Id
 LEFT JOIN Departments_Base ON Departments_Base.Dept_Id = Prod_Lines_Base.Dept_Id
 LEFT JOIN Alarm_Template_SPC_Rule_Data ON Alarm_Template_SPC_Rule_Data.ATSRD_Id = alarms.ATSRD_Id
 LEFT JOIN Alarm_SPC_Rules ON Alarm_SPC_Rules.Alarm_SPC_Rule_Id = Alarm_Template_SPC_Rule_Data.Alarm_SPC_Rule_Id
 LEFT JOIN Event_Reasons cause1 ON cause1.Event_Reason_Id = alarms.Cause1
 LEFT JOIN Event_Reasons cause2 ON cause2.Event_Reason_Id = alarms.Cause2
 LEFT JOIN Event_Reasons cause3 ON cause3.Event_Reason_Id = alarms.Cause3
 LEFT JOIN Event_Reasons cause4 ON cause4.Event_Reason_Id = alarms.Cause4
 LEFT JOIN Event_Reasons action1 ON action1.Event_Reason_Id = alarms.Action1
 LEFT JOIN Event_Reasons action2 ON action2.Event_Reason_Id = alarms.Action2
 LEFT JOIN Event_Reasons action3 ON action3.Event_Reason_Id = alarms.Action3
 LEFT JOIN Event_Reasons action4 ON action4.Event_Reason_Id = alarms.Action4
 LEFT JOIN Research_Status ON Research_Status.Research_Status_Id = alarms.Research_Status_Id
 LEFT JOIN Users ON Users.User_Id = alarms.Ack_By
 LEFT JOIN Users research ON research.User_Id = alarms.Research_User_Id
 LEFT JOIN ED_FieldType_ValidValues on ED_FieldType_ValidValues.ED_Field_Type_Id = 55 and ED_FieldType_ValidValues.Field_Id = Alarm_Templates.Esignature_Level
LEFT JOIN Comments ac on ac.Comment_Id=alarms.Action_Comment_Id
LEFT JOIN Comments cc on cc.Comment_Id=alarms.Cause_Comment_Id
LEFT JOIN Comments rc on rc.Comment_Id=alarms.Research_Comment_Id
LEFT JOIN Comments vc on vc.Comment_Id=Variables.comment_id
