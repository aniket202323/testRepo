CREATE view SDK_V_PAWasteEvent
as
select
Waste_Event_Details.WED_Id as Id,
Waste_Event_Details.WED_Id as WasteEventId,
Prod_Lines_Base.PL_Desc as ProductionLine,
Prod_Units_Base.PU_Desc as ProductionUnit,
Waste_Event_Type.WET_Name as WasteType,
sourcepl.PL_Desc as SourceProductionLine,
sourcepu.PU_Desc as SourceProductionUnit,
Events.Event_Num as ProductionEventName,
Waste_Event_Details.TimeStamp as Timestamp,
Waste_Event_Meas.WEMT_Name as WasteMeasurement,
Waste_Event_Details.Amount as Amount,
cause1.Event_Reason_Name as Cause1,
cause2.Event_Reason_Name as Cause2,
cause3.Event_Reason_Name as Cause3,
cause4.Event_Reason_Name as Cause4,
action1.Event_Reason_Name as Action1,
action2.Event_Reason_Name as Action2,
action3.Event_Reason_Name as Action3,
action4.Event_Reason_Name as Action4,
Waste_Event_Details.Research_Open_Date as ResearchOpenDate,
Waste_Event_Details.Research_Close_Date as ResearchCloseDate,
Research_Status.Research_Status_Desc as ResearchStatus,
research.Username as ResearchUserName,
Waste_Event_Details.Cause_Comment_Id as CauseCommentId,
Waste_Event_Details.Action_Comment_Id as ActionCommentId,
Waste_Event_Details.Research_Comment_Id as ResearchCommentId,
Waste_Event_Details.User_General_1 as UserGeneral1,
Waste_Event_Details.User_General_2 as UserGeneral2,
Waste_Event_Details.User_General_3 as UserGeneral3,
Waste_Event_Details.User_General_4 as UserGeneral4,
Waste_Event_Details.User_General_5 as UserGeneral5,
Waste_Event_Details.Signature_Id as ESignatureId,
Waste_Event_Details.EC_Id as EventConfigurationId,
Waste_Event_Details.Event_Id as ProductionEventId,
Waste_Event_Details.WEFault_Id as WasteFaultId,
Waste_Event_Details.WEMT_Id as WasteMeasurementId,
Waste_Event_Details.PU_Id as ProductionUnitId,
Waste_Event_Details.Research_User_Id as ResearchUserId,
Waste_Event_Details.Event_Reason_Tree_Data_Id as ReasonTreeDataId,
Waste_Event_Details.Source_PU_Id as SourceProductionUnitId,
Waste_Event_Details.Research_Status_Id as ResearchStatusId,
Waste_Event_Details.Action_Level1 as Action1Id,
Waste_Event_Details.Action_Level2 as Action2Id,
Waste_Event_Details.Action_Level3 as Action3Id,
Waste_Event_Details.Action_Level4 as Action4Id,
Waste_Event_Details.Reason_Level1 as Cause1Id,
Waste_Event_Details.Reason_Level2 as Cause2Id,
Waste_Event_Details.Reason_Level3 as Cause3Id,
Waste_Event_Details.Reason_Level4 as Cause4Id,
Waste_Event_Details.WET_Id as WasteTypeId,
Waste_Event_Fault.WEFault_Name as WasteFault,
Departments_Base.Dept_Desc as Department,
sourcedept.Dept_Desc as SourceDepartment,
Prod_Lines_Base.Dept_Id as DepartmentId,
Prod_Units_Base.PL_Id as ProductionLineId,
ac.Comment_Text as ActionCommentText,
cc.Comment_Text as CauseCommentText,
rc.Comment_Text as ResearchCommentText,
Prod_Lines_Base.Dept_Id as SourceDepartmentId,
Prod_Units_Base.PL_Id as SourceProductionLineId,
Waste_Event_Details.Dimension_A as DimensionA,
Waste_Event_Details.Dimension_X as DimensionX,
Waste_Event_Details.Dimension_Y as DimensionY,
Waste_Event_Details.Dimension_Z as DimensionZ,
Waste_Event_Details.Work_Order_Number as OrderNumber,
Waste_Event_Details.Start_Coordinate_A as StartCoordinateA,
Waste_Event_Details.Start_Coordinate_X as StartCoordinateX,
Waste_Event_Details.Start_Coordinate_Y as StartCoordinateY,
Waste_Event_Details.Start_Coordinate_Z as StartCoordinateZ,
Users.User_Id as UserId,
Users.Username as Username
FROM Departments_Base
 JOIN Prod_Lines_Base ON Departments_Base.Dept_Id = Prod_Lines_Base.Dept_Id
 JOIN Prod_Units_Base ON Prod_Lines_Base.PL_Id = Prod_Units_Base.PL_Id
 JOIN Waste_Event_Details ON Prod_Units_Base.PU_Id = Waste_Event_Details.PU_Id
 LEFT JOIN Waste_Event_Type ON Waste_Event_Details.WET_Id = Waste_Event_Type.WET_Id
 LEFT JOIN Waste_Event_Meas ON Waste_Event_Details.WEMT_Id = Waste_Event_Meas.WEMT_Id
 LEFT JOIN Waste_Event_Fault ON Waste_Event_Fault.WEFault_Id = Waste_Event_Details.WEFault_Id 
 LEFT JOIN Prod_Units_Base sourcepu ON Waste_Event_Details.Source_PU_Id = sourcepu.PU_Id 
 LEFT JOIN Prod_Lines_Base sourcepl ON sourcepu.PL_Id = sourcepl.PL_Id
 LEFT JOIN Departments_Base sourcedept ON sourcedept.Dept_Id = sourcepl.Dept_Id 
 JOIN Users ON Waste_Event_Details.User_Id = users.User_id 
 LEFT JOIN Events ON Waste_Event_Details.Event_Id = events.Event_Id 
 LEFT JOIN Event_Reasons cause1 ON Waste_Event_Details.Reason_Level1 = cause1.Event_Reason_Id
 LEFT JOIN Event_Reasons cause2 ON Waste_Event_Details.Reason_Level2 = cause2.Event_Reason_Id
 LEFT JOIN Event_Reasons cause3 ON Waste_Event_Details.Reason_Level3 = cause3.Event_Reason_Id
 LEFT JOIN Event_Reasons cause4 ON Waste_Event_Details.Reason_Level4 = cause4.Event_Reason_Id
 LEFT JOIN Event_Reasons action1 ON Waste_Event_Details.Action_Level1 = action1.Event_Reason_Id
 LEFT JOIN Event_Reasons action2 ON Waste_Event_Details.Action_Level2 = action2.Event_Reason_Id
 LEFT JOIN Event_Reasons action3 ON Waste_Event_Details.Action_Level3 = action3.Event_Reason_Id
 LEFT JOIN Event_Reasons action4 ON Waste_Event_Details.Action_Level4 = action4.Event_Reason_Id
 LEFT JOIN Research_Status ON Waste_Event_Details.Research_Status_Id = Research_Status.Research_Status_Id
 LEFT JOIN Users research ON Waste_Event_Details.Research_User_Id = research.User_Id 
LEFT JOIN Comments ac on ac.Comment_Id=waste_event_details.Action_Comment_Id
LEFT JOIN Comments cc on cc.Comment_Id=waste_event_details.Cause_Comment_Id
LEFT JOIN Comments rc on rc.Comment_Id=waste_event_details.Research_Comment_Id
