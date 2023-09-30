CREATE view SDK_V_PAEventSubType
as
select
Event_Subtypes.Event_Subtype_Id as Id,
Event_Types.ET_Desc as EventType,
Event_Subtypes.Event_Subtype_Desc as EventSubType,
Event_Subtypes.Event_Mask as EventMask,
Event_Subtypes.Dimension_X_Name as DimensionXName,
euX.Eng_Unit_Desc as DimensionXEngineeringUnit,
Event_Subtypes.Dimension_Y_Name as DimensionYName,
euY.Eng_Unit_Desc as DimensionYEngineeringUnit,
Event_Subtypes.Dimension_Y_Enabled as DimensionYEnabled,
Event_Subtypes.Dimension_Z_Name as DimensionZName,
euZ.Eng_Unit_Desc as DimensionZEngineeringUnit,
Event_Subtypes.Dimension_Z_Enabled as DimensionZEnabled,
Event_Subtypes.Dimension_A_Name as DimensionAName,
euA.Eng_Unit_Desc as DimensionAEngineeringUnit,
Event_Subtypes.Dimension_A_Enabled as DimensionAEnabled,
Event_Subtypes.Cause_Required as CauseRequired,
causetree.Tree_Name as CauseTree,
cause1.Event_Reason_Name as DefaultCause1,
cause2.Event_Reason_Name as DefaultCause2,
cause3.Event_Reason_Name as DefaultCause3,
cause4.Event_Reason_Name as DefaultCause4,
Event_Subtypes.Action_Required as ActionRequired,
actiontree.Tree_Name as ActionTree,
action1.Event_Reason_Name as DefaultAction1,
action2.Event_Reason_Name as DefaultAction2,
action3.Event_Reason_Name as DefaultAction3,
action4.Event_Reason_Name as DefaultAction4,
Event_Subtypes.Ack_Required as AckRequired,
Event_Subtypes.Extended_Info as ExtendedInfo,
Event_Subtypes.Comment_Id as CommentId,
Comments.Comment_Text as CommentText,
Event_Subtypes.ET_Id as EventTypeId,
Event_Subtypes.Default_Action1 as DefaultAction1Id,
Event_Subtypes.Default_Action2 as DefaultAction2Id,
Event_Subtypes.Default_Action3 as DefaultAction3Id,
Event_Subtypes.Default_Action4 as DefaultAction4Id,
Event_Subtypes.Default_Cause1 as DefaultCause1Id,
Event_Subtypes.Default_Cause2 as DefaultCause2Id,
Event_Subtypes.Default_Cause3 as DefaultCause3Id,
Event_Subtypes.Default_Cause4 as DefaultCause4Id,
Event_Subtypes.Cause_Tree_Id as CauseTreeId,
Event_Subtypes.Action_Tree_Id as ActionTreeId,
ED_FieldType_ValidValues.Field_Desc as ESignatureLevel,
Event_Subtypes.Esignature_Level as ESignatureLevelId,
Event_Subtypes.Dimension_A_Eng_Unit_Id as DimensionAEngineeringUnitId,
Event_Subtypes.Dimension_X_Eng_Unit_Id as DimensionXEngineeringUnitId,
Event_Subtypes.Dimension_Y_Eng_Unit_Id as DimensionYEngineeringUnitId,
Event_Subtypes.Dimension_Z_Eng_Unit_Id as DimensionZEngineeringUnitId,
event_subtypes.Event_Controlled_Product as EventControlledProduct,
event_subtypes.Icon_Id as IconId
FROM Event_SubTypes 
JOIN Event_Types ON Event_Types.ET_Id = Event_SubTypes.ET_Id 
LEFT
 JOIN Event_Reason_Tree causetree ON causetree.Tree_Name_Id = Event_Subtypes.Cause_Tree_Id 
LEFT
 JOIN Event_Reason_Tree actiontree ON actiontree.Tree_Name_Id = Event_Subtypes.Action_Tree_Id 
LEFT
 JOIN Event_Reasons action1 ON Event_Subtypes.Default_Action1 = action1.Event_Reason_Id 
LEFT
 JOIN Event_Reasons action2 ON Event_Subtypes.Default_Action2 = action2.Event_Reason_Id 
LEFT
 JOIN Event_Reasons action3 ON Event_Subtypes.Default_Action3 = action3.Event_Reason_Id 
LEFT
 JOIN Event_Reasons action4 ON Event_Subtypes.Default_Action4 = action4.Event_Reason_Id 
LEFT
 JOIN Event_Reasons cause1 ON Event_Subtypes.Default_Cause1 = cause1.Event_Reason_Id 
LEFT
 JOIN Event_Reasons cause2 ON Event_Subtypes.Default_Cause1 = cause2.Event_Reason_Id 
LEFT
 JOIN Event_Reasons cause3 ON Event_Subtypes.Default_Cause1 = cause3.Event_Reason_Id 
LEFT
 JOIN Event_Reasons cause4 ON Event_Subtypes.Default_Cause1 = cause4.Event_Reason_Id 
left
 join ED_FieldType_ValidValues on ED_FieldType_ValidValues.ED_Field_Type_Id = 55 and ED_FieldType_ValidValues.Field_Id = Event_Subtypes.Esignature_Level
LEFT
 JOIN Engineering_Unit eua on eua.Eng_Unit_Id = Event_Subtypes.Dimension_A_Eng_Unit_Id
LEFT
 JOIN Engineering_Unit eux on eux.Eng_Unit_Id = Event_Subtypes.Dimension_X_Eng_Unit_Id
LEFT
 JOIN Engineering_Unit euy on euy.Eng_Unit_Id = Event_Subtypes.Dimension_Y_Eng_Unit_Id
LEFT
 JOIN Engineering_Unit euz on euz.Eng_Unit_Id = Event_Subtypes.Dimension_Z_Eng_Unit_Id
LEFT JOIN Comments Comments on Comments.Comment_Id=event_subtypes.Comment_Id
