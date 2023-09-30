CREATE view SDK_V_PAVariableResultEvent
as
select
Tests.Test_Id as Id,
Tests.Test_Id as VariableResultEventId,
Prod_Lines_Base.PL_Desc as ProductionLine,
Prod_Units_Base.PU_Desc as ProductionUnit,
Variables.Var_Desc as Variable,
Events.Event_Num as EventName,
Variables.Test_Name as TestName,
Production_Plan.Process_Order as ProcessOrder,
Products.Prod_Code as ProductCode,
Tests.Result_On as ResultOn,
COALESCE(Active_Specs.L_Entry,Var_Specs.L_Entry) as LEL,
COALESCE(Active_Specs.L_Reject,Var_Specs.L_Reject) as LRL,
COALESCE(Active_Specs.L_User,Var_Specs.L_User) as LUL,
COALESCE(Active_Specs.L_Warning,Var_Specs.L_Warning) as LWL,
COALESCE(Active_Specs.U_Entry,Var_Specs.U_Entry) as UEL,
COALESCE(Active_Specs.U_Reject,Var_Specs.U_Reject) as URL,
COALESCE(Active_Specs.U_User,Var_Specs.U_User) as UUL,
COALESCE(Active_Specs.U_Warning,Var_Specs.U_Warning) as UWL,
Tests.Result as Value,
Tests.Comment_Id as CommentId,
Tests.Signature_Id as ESignatureId,
Tests.Event_Id as EventId,
Prod_Units_Base.PU_Id as ProductionUnitId,
Tests.Second_User_Id as SecondUserId,
Tests.Var_Id as VariableId,
Tests.Canceled as Canceled,
COALESCE(Active_Specs.Target,Var_Specs.Target) as TGT,
Production_Plan_Starts.PP_Start_Id as ProductionPlanStartId,
Production_Plan_Starts.PP_Id as ProductionPlanId,
Products.Prod_Id as ProductId,
Departments_Base.Dept_Desc as Department,
Departments_Base.Dept_Id as DepartmentId,
Prod_Lines_Base.PL_Id as ProductionLineId,
Comments.Comment_Text as CommentText,
COALESCE(ltrim(str(tsd.Mean - 3 * tsd.sigma,25,Variables.Var_Precision)),Active_Specs.L_Control,Var_Specs.L_Control) as LCL,
COALESCE(ltrim(str(tsd.Mean,25,Variables.Var_Precision)),Active_Specs.T_Control,Var_Specs.T_Control) as TCL,
COALESCE(ltrim(str(tsd.Mean + 3 * tsd.sigma,25,Variables.Var_Precision)),Active_Specs.U_Control,Var_Specs.U_Control) as UCL,
Variables.ShouldArchive as ShouldArchive,
Tests.Array_Id as ArrayId,
Tests.Entry_On as EntryOn,
Users.User_Id as UserId,
Users.Username as Username,
COALESCE(Active_Specs.Test_Freq,Var_Specs.Test_Freq) as TestFrequency,
event_types.et_desc as EventType,
variables.event_type as EventTypeId,
Tests.Locked as IsLocked
FROM Tests
join Variables_Base as Variables on Variables.Var_Id = Tests.Var_Id
JOIN Event_Types ON Event_Types.ET_Id = Variables.Event_Type
LEFT
 JOIN Events ON Variables.Event_Type = 1 and Events.Event_Id = Tests.Event_Id and Event_Types.ValidateTestData = 1
LEFT
 JOIN S95_Event SegRespS95 ON SegRespS95.Event_Type = 31 and SegRespS95.Event_Id = Tests.Event_Id and Event_Types.ValidateTestData = 1 and Variables.Event_Type = 31
Left
 Join SegmentResponse ON SegmentResponse.SegmentResponseId = SegRespS95.S95_Guid
LEFT
 JOIN S95_Event WorkRespS95 ON WorkRespS95.Event_Type = 32 and WorkRespS95.Event_Id = Tests.Event_Id and Event_Types.ValidateTestData = 1 and Variables.Event_Type = 32
LEFT
 JOIN WorkResponse ON WorkResponse.WorkResponseId = WorkRespS95.S95_Guid
JOIN Prod_Units_Base ON Prod_Units_Base.PU_Id = COALESCE(Events.PU_Id,dbo.fnServer_CmnGetSegRespUnit(SegRespS95.S95_Guid),dbo.fnServer_CmnGetWorkRespUnit(WorkRespS95.S95_Guid),Variables.PU_Id) AND Prod_Units_Base.PU_Id <> 0
LEFT
 JOIN Production_Starts ON Production_Starts.PU_Id = COALESCE(Prod_Units_Base.Master_Unit,Prod_Units_Base.PU_Id) AND Production_Starts.Start_Time < Tests.Result_On AND (Production_Starts.End_Time >= Tests.Result_On OR Production_Starts.End_Time IS NULL)
LEFT
 JOIN Products ON Products.Prod_id = COALESCE(events.Applied_Product, Production_Starts.Prod_id)
LEFT
 JOIN Var_Specs ON Var_Specs.Var_id = Tests.Var_Id AND Var_Specs.Prod_id = Products.Prod_id AND Var_Specs.Effective_Date <= Tests.Result_On  AND (Var_Specs.Expiration_date > Tests.Result_On OR Var_Specs.Expiration_date IS NULL)
LEFT
 JOIN Active_Specs ON Active_Specs.Spec_id = Variables.Spec_Id AND Active_Specs.Char_id = COALESCE(SegRespS95.Char_Id,WorkRespS95.Char_Id) AND Active_Specs.Effective_Date <= COALESCE(SegmentResponse.EndTime,WorkResponse.EndTime) AND (Active_Specs.Expiration_date > COALESCE(SegmentResponse.EndTime,WorkResponse.EndTime) OR Active_Specs.Expiration_date IS NULL)
LEFT
 JOIN Test_Sigma_Data tsd on tsd.Test_Id = Tests.Test_Id 
JOIN Prod_Lines_Base ON Prod_Lines_Base.PL_Id = Prod_Units_Base.PL_Id AND Prod_Lines_Base.PL_Id <> 0
JOIN Departments_Base ON Departments_Base.Dept_Id = Prod_Lines_Base.Dept_Id
LEFT
 JOIN Production_Plan_Starts ON Production_Plan_Starts.PU_Id = COALESCE(Prod_Units_Base.Master_Unit,Prod_Units_Base.PU_Id) AND Production_Plan_Starts.Start_Time < Tests.Result_On AND (Production_Plan_Starts.End_Time >= Tests.Result_On OR Production_Plan_Starts.End_Time IS NULL)
LEFT
 JOIN Production_Plan ON Production_Plan_Starts.PP_Id = Production_Plan.PP_Id
Left
 JOIN Users on Users.User_Id = Tests.Entry_By
LEFT JOIN Comments Comments on Comments.Comment_Id=tests.Comment_Id
