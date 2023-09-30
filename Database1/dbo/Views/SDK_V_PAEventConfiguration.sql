CREATE view SDK_V_PAEventConfiguration
as
select
Event_Configuration.EC_Id as Id,
Departments_Base.Dept_Desc as Department,
Prod_Lines_Base.PL_Desc as ProductionLine,
Prod_Units_Base.PU_Desc as ProductionUnit,
PrdExec_Inputs.Input_Name as PathInput,
Event_Types.ET_Desc as EventType,
Event_Subtypes.Event_Subtype_Desc as EventSubType,
Event_Configuration.Is_Active as ModelIsActive,
ED_Models.Model_Desc as Model,
ED_Models.Model_Num as ModelNumber,
Event_Configuration.Extended_Info as ExtendedInfo,
Event_Configuration.Exclusions as Exclusions,
Event_Configuration.Comment_Id as CommentId,
Comments.Comment_Text as CommentText,
Prod_Lines_Base.Dept_Id as DepartmentId,
Event_Configuration.PU_Id as ProductionUnitId,
Prod_Units_Base.PL_Id as ProductionLineId,
Event_Configuration.ED_Model_Id as ModelId,
Event_Configuration.ET_Id as EventTypeId,
Event_Configuration.Event_Subtype_Id as EventSubTypeId,
Event_Configuration.PEI_Id as PathInputId,
Event_Configuration.EC_Desc as EventConfigurationName,
ED_FieldType_ValidValues.Field_Desc as ESignatureLevel,
Event_Configuration.Esignature_Level as ESignatureLevelId,
event_configuration.Debug as Debug,
event_configuration.External_Time_Zone as ExternalTimeZone,
event_configuration.Is_Calculation_Active as IsCalculationActive,
event_configuration.Max_Run_Time as MaxRunTime,
event_configuration.Model_Group as ModelGroup,
event_configuration.Priority as Priority,
event_configuration.Retention_Limit as RetentionLimit
FROM  Event_Configuration 
 LEFT JOIN PrdExec_Inputs ON PrdExec_Inputs.PEI_Id = Event_Configuration.PEI_Id 
 INNER JOIN Prod_Units_Base  ON Prod_Units_Base.PU_Id = Event_Configuration.PU_Id 
 INNER JOIN Prod_Lines_Base  ON Prod_Lines_Base.PL_Id = Prod_Units_Base.PL_Id 
 INNER JOIN Departments_Base  ON Departments_Base.Dept_Id = Prod_Lines_Base.Dept_Id
 LEFT JOIN Event_Types ON Event_Types.ET_Id = Event_Configuration.ET_Id 
 LEFT JOIN Event_SubTypes ON Event_SubTypes.Event_Subtype_Id = Event_Configuration.Event_Subtype_Id 
 LEFT JOIN ED_Models ON ED_Models.ED_Model_Id = Event_Configuration.ED_Model_Id
 left join ED_FieldType_ValidValues on ED_FieldType_ValidValues.ED_Field_Type_Id = 55 and ED_FieldType_ValidValues.Field_Id =  Event_Configuration.Esignature_Level
LEFT JOIN Comments Comments on Comments.Comment_Id=event_configuration.Comment_Id
