CREATE view SDK_V_PAProductionEvent
as
select
Events.Event_Id as Id,
Events.Event_Id as ProductionEventId,
Prod_Lines_Base.PL_Desc as ProductionLine,
Prod_Units_Base.PU_Desc as ProductionUnit,
Events.Event_Num as EventName,
Events.Start_Time as StartTime,
Events.TimeStamp as EndTime,
Production_Status.ProdStatus_Desc as ProductionStatus,
Event_Subtypes.Event_Subtype_Desc as EventSubType,
applied.Prod_Code as AppliedProductCode,
Products.Prod_Code as OriginalProductCode,
Coalesce(PPAssigned.Process_Order, Production_Plan.Process_Order) as ProcessOrder,
Test_Status.Testing_Status_Desc as TestingStatus,
Events.Comment_Id as CommentId,
Events.Extended_Info as ExtendedInfo,
Events.Signature_Id as ESignatureId,
Events.Applied_Product as AppliedProductId,
Events.Event_Status as ProductionStatusId,
Events.Event_Subtype_Id as EventSubTypeId,
Events.PU_Id as ProductionUnitId,
Production_Plan.Prod_Id as OriginalProductId,
Events.Testing_Status as TestingStatusId,
Departments_Base.Dept_Desc as Department,
Prod_Lines_Base.Dept_Id as DepartmentId,
Prod_Units_Base.PL_Id as ProductionLineId,
Event_Details.Alternate_Event_Num as AlternateEventName,
Event_Details.Initial_Dimension_X as InitialDimensionX,
Event_Details.Initial_Dimension_Y as InitialDimensionY,
Event_Details.Initial_Dimension_Z as InitialDimensionZ,
Event_Details.Initial_Dimension_A as InitialDimensionA,
Event_Details.Final_Dimension_X as FinalDimensionX,
Event_Details.Final_Dimension_Y as FinalDimensionY,
Event_Details.Final_Dimension_Z as FinalDimensionZ,
Event_Details.Final_Dimension_A as FinalDimensionA,
Event_Details.Orientation_X as OrientationX,
Event_Details.Orientation_Y as OrientationY,
Event_Details.Orientation_Z as OrientationZ,
Event_Details.Order_Id as CustomerOrderId,
Event_Details.Order_Line_Id as CustomerOrderLineId,
Coalesce(Event_Details.PP_Id, Production_Plan.PP_Id) as ProductionPlanId,
Event_Details.PP_Setup_Detail_Id as ProductionSetupDetailId,
Event_Details.Shipment_Id as ShipmentId,
Event_Details.Comment_Id as DetailCommentId,
Event_Details.Signature_Id as DetailESignatureId,
dc.Comment_Text as DetailCommentText,
Comments.Comment_Text as CommentText,
eusers.Username as EntryBy,
Event_Details.Entered_By as EntryById,
Events.Approver_Reason_Id as ApprovedReasonId,
Events.Approver_User_Id as ApproverUserId,
Events.Conformance as Conformance,
Events.Entry_On as EntryOn,
Events.Second_User_Id as SecondUserId,
Events.Source_Event as SourceEventId,
Events.Testing_Prct_Complete as TestPercentComplete,
Events.User_Reason_Id as UserReasonId,
Events.User_Signoff_Id as UserSignOffId,
Event_Details.Entered_On as DetailEntryOn,
Users.User_Id as UserId,
Users.Username as Username
FROM Events
 LEFT JOIN Test_Status ON test_status.Testing_Status = events.Testing_Status
 LEFT JOIN Production_Status ON Production_Status.ProdStatus_Id = events.Event_Status
 INNER JOIN Production_Starts ON Production_Starts.PU_Id = events.PU_Id AND events.PU_Id > 0 AND events.TimeStamp > Production_Starts.Start_Time AND (events.TimeStamp <= Production_Starts.End_Time OR Production_Starts.End_Time Is Null)
 INNER JOIN Products ON products.Prod_Id = Production_Starts.Prod_Id
 LEFT JOIN Products applied ON applied.Prod_Id = events.Applied_Product
 INNER JOIN Prod_Units_Base  ON Prod_Units_Base.PU_Id = events.PU_Id
 INNER JOIN Prod_Lines_Base ON Prod_Lines_Base.PL_Id = Prod_Units_Base.PL_Id
 INNER JOIN Departments_Base  ON Departments_Base.Dept_Id = Prod_Lines_Base.Dept_Id
 LEFT JOIN Event_Configuration ON Event_Configuration.PU_Id = Prod_Units_Base.PU_Id AND Event_Configuration.ET_Id = 1
 LEFT JOIN Event_SubTypes ON Event_Configuration.Event_SubType_Id = Event_SubTypes.Event_SubType_Id
 LEFT JOIN Event_Details ON Event_Details.Event_Id = events.Event_Id
 LEFT JOIN Production_Plan_Starts ON Production_Plan_Starts.PU_Id = events.PU_Id AND events.PU_Id > 0 AND Event_Details.PP_Id is null AND events.TimeStamp > Production_Plan_Starts.Start_Time AND (events.TimeStamp <= Production_Plan_Starts.End_Time OR Production_Plan_Starts.End_Time Is Null)
 LEFT JOIN Production_Plan ON Production_Plan_Starts.PP_Id = Production_Plan.PP_Id
 LEFT JOIN Production_Plan PPAssigned ON PPAssigned.PP_Id = Event_Details.PP_Id
 LEFT JOIN Users ON Users.User_Id = Events.User_Id
 LEFT JOIN Users ausers ON ausers.User_Id = Events.Approver_User_Id
 LEFT JOIN Users eusers ON eusers.User_Id = Event_Details.Entered_By
LEFT JOIN Comments dc on dc.Comment_Id=Event_Details.Comment_Id
LEFT JOIN Comments Comments on Comments.Comment_Id=events.Comment_Id
