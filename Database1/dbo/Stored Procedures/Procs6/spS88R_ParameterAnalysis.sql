-- exec spS88R_ParameterAnalysis 1,''
CREATE procedure [dbo].[spS88R_ParameterAnalysis]
@AnalysisId int,
@InTimeZone nVarChar(200)=NULL
AS
set nocount on
set arithignore on
set arithabort off
set ansi_warnings off
/******************************************************
-- For Testing
--*******************************************************
Select @AnalysisId = 2
--*******************************************************/
Declare @CriteriaString nVarChar(1000)
Declare @AnalysisName nVarChar(1000)
--**********************************************
-- Translations Setup & Common Prompt Lookup
--**********************************************
-- Retreive the Language Id of the current user
Declare @LangId INT
EXEC spWA_GetCurrentUserInfo @LangId = @LangId OUTPUT
-- Get Common Prompts
DECLARE @sUnitProcedure nVarChar(100)
DECLARE @sOperation nVarChar(100)
DECLARE @sPhase nVarChar(100)
DECLARE @sBatch nVarChar(100)
SET @sUnitProcedure = dbo.fnTranslate(@LangId, 34904, 'Unit Procedure')
SET @sOperation = dbo.fnTranslate(@LangId, 34905, 'Operation')
SET @sPhase = dbo.fnTranslate(@LangId, 34906, 'Phase')
SET @sBatch = dbo.fnTranslate(@LangId, 34927, 'Batch')
--**********************************************
Declare @ParameterDetails Table (
  VariableId int,
  Parameter nVarChar(255),
  ProcedureName nVarChar(255),
  TypeId int,
  Timestamp datetime,
  Value real NULL,
  EventNumber nVarChar(100),
  EventId int,
  URL real NULL,
  UWL real NULL,
  TGT real NULL,
  LWL real NULL,
  LRL real NULL
)
Declare @FilterList Table(
  UnitProcedure nVarChar(255) NULL,
  Operation nVarChar(255) NULL,
  Phase nVarChar(255) NULL ,
  Parameter nVarChar(255) NULL
)
Declare @BatchFilterList Table(
  UnitProcedure nVarChar(255) NULL,
  Parameter nVarChar(255) NULL,
  VarId INT
)
Declare @BatchList Table(
  EventId int,
  EventNumber nVarChar(100),
  Unit int,
  ProductId int NULL
)
-- Get Batch Selections Into Event List
Insert Into @BatchList
  Select e.Event_Id, e.Event_Num, e.PU_Id, e.Applied_Product
    From batch_results_selections s
    Join Events e on e.event_id = s.batch_event_id  
    Where s.Analysis_Id = @AnalysisId and
          s.Checked = 1
--Virtual Unit Parameters
Insert Into @BatchFilterList 
  Select Unit_Procedure, ParameterName, Var_Id
    From Batch_Unit_Parameter_Selections
      Where Analysis_Id = @AnalysisId
--
-- Get Parameter Selections Into Filter List
Insert Into @FilterList 
  Select Unit_Procedure, Operation, Phase, ParameterName
    From batch_parameter_selections
      Where Analysis_Id = @AnalysisId
select @AnalysisName = Report_Name
  from Report_Definitions
  Where Report_Id = @AnalysisId
--**********************************************
-- Return Header Information
--**********************************************
-- Line1: Report Name
-- Line2: Criteria
-- Line3: Generate Time
-- Line4 - n: Column Names
Declare @Prompts Table(
  PromptId int,
  PromptName nVarChar(30),
  PromptValue nVarChar(1000),
  PromptValue_Parameter nVarChar(1000)
)
Insert into @Prompts (PromptId, PromptName, PromptValue) Values (1, 'ReportName', dbo.fnTranslate(@LangId, 34941, 'Parameter Analysis'))
Insert into @Prompts (PromptId, PromptName, PromptValue, PromptValue_Parameter) Values (2, 'Criteria', dbo.fnTranslate(@LangId, 34599, 'For {0}'), @AnalysisName)
Insert into @Prompts (PromptId, PromptName, PromptValue, PromptValue_Parameter) Values (3, 'GenerateTime', dbo.fnTranslate(@LangId, 34521, 'Created: {0}'), dbo.fnServer_CmnGetDate(getutcdate())) 
Insert into @Prompts (PromptId, PromptName, PromptValue) Values (4, 'CycleTimeStatistics', dbo.fnTranslate(@LangId, 34928, 'Cycle Time Statistics'))
Insert into @Prompts (PromptId, PromptName, PromptValue) Values (5, 'ProcessCapability', dbo.fnTranslate(@LangId, 34930, 'Process Capability'))
Insert into @Prompts (PromptId, PromptName, PromptValue) Values (6, 'Parameter', dbo.fnTranslate(@LangId, 34920, 'Parameter'))
Insert into @Prompts (PromptId, PromptName, PromptValue) Values (7, 'Procedure', dbo.fnTranslate(@LangId, 34931, 'Procedure'))
Insert into @Prompts (PromptId, PromptName, PromptValue) Values (8, 'Type', dbo.fnTranslate(@LangId, 34932, 'Type'))
Insert into @Prompts (PromptId, PromptName, PromptValue) Values (9, 'Average', dbo.fnTranslate(@LangId, 34934, 'Average'))
Insert into @Prompts (PromptId, PromptName, PromptValue) Values (10, 'StandardDeviationShort', dbo.fnTranslate(@LangId, 34935, 'Std'))
Insert into @Prompts (PromptId, PromptName, PromptValue) Values (11, 'StandardDeviationLong', dbo.fnTranslate(@LangId, 34936, 'Standard Deviation'))
Insert into @Prompts (PromptId, PromptName, PromptValue) Values (12, 'PercentDeviation', dbo.fnTranslate(@LangId, 34937, 'Percent Deviation'))
Insert into @Prompts (PromptId, PromptName, PromptValue) Values (13, 'Minimum', dbo.fnTranslate(@LangId, 34938, 'Min'))
Insert into @Prompts (PromptId, PromptName, PromptValue) Values (14, 'Maximum', dbo.fnTranslate(@LangId, 34939, 'Max'))
Insert into @Prompts (PromptId, PromptName, PromptValue) Values (15, 'Total', dbo.fnTranslate(@LangId, 34940, 'Total'))
Insert into @Prompts (PromptId, PromptName, PromptValue) Values (16, 'UpperReject', dbo.fnTranslate(@LangId, 34671, 'Upper Reject'))
Insert into @Prompts (PromptId, PromptName, PromptValue) Values (17, 'UpperWarning', dbo.fnTranslate(@LangId, 34670, 'Upper Warning'))
Insert into @Prompts (PromptId, PromptName, PromptValue) Values (18, 'LowerWarning', dbo.fnTranslate(@LangId, 34668, 'Lower Warning'))
Insert into @Prompts (PromptId, PromptName, PromptValue) Values (19, 'LowerReject', dbo.fnTranslate(@LangId, 34667, 'Lower Reject'))
Insert into @Prompts (PromptId, PromptName, PromptValue) Values (20, 'ParameterStatistics', dbo.fnTranslate(@LangId, 34988, 'Parameter Statistics'))
Insert into @Prompts (PromptId, PromptName, PromptValue) Values (21, 'BatchList', dbo.fnTranslate(@LangId, 34070, 'Batch List'))
Select * From @Prompts
--**********************************************
-- Return Data For Report
--**********************************************
Declare @@BatchId int
Declare @@BatchProductId int
Declare @@BatchName nVarChar(50)
Declare @@EventId int
Declare @@Unit int
Declare @@EventNumber nVarChar(100)
Declare @@StartTime datetime
Declare @@Timestamp datetime
Declare @LastUnit int
Select @LastUnit = 0
--Virtual Unit Parameters
 	 Declare Batch_Cursor Insensitive Cursor 
  For Select bl.EventId, bl.EventNumber, bl.ProductId, E.TimeStamp, E.Start_Time
    From @BatchList bl
 	  	  	 Join Events e ON e.Event_Id = bl.EventId
    Order By Unit
  For Read Only
Open Batch_Cursor
Select @@BatchProductId = NULL
Fetch Next From Batch_Cursor Into @@BatchId, @@BatchName, @@BatchProductId, @@TimeStamp, @@StartTime
While @@Fetch_Status = 0
  Begin 	  	  	 
 	  	  	 Insert Into @ParameterDetails (VariableId, Parameter, ProcedureName, TypeId, Timestamp, Value, EventNumber, EventId, URL, UWL, TGT, LWL, LRL)
 	  	  	       Select Variableid = v.var_id,
                   Parameter = v.Var_Desc, 
 	  	  	              ProcedureName = 'Batch',
 	  	  	              TypeId = 0,
 	  	  	              Timestamp = @@Timestamp,
 	  	  	  	  	  	  Value = CASE WHEN dbo.fnWA_isReallyNumeric(t.result) = 1 THEN convert(real, t.result) ELSE NULL END,
 	  	  	              EventNumber = @@BatchName,
 	  	  	              EventId = @@BatchId, 
  	  	  	              URL = CASE WHEN dbo.fnWA_isReallyNumeric(vs.U_Reject) = 1 THEN convert(real,vs.U_Reject) ELSE NULL END,
 	  	  	              UWL = CASE WHEN dbo.fnWA_isReallyNumeric(vs.U_Warning) = 1 THEN convert(real,vs.U_Warning) ELSE NULL END,
 	  	  	              TGT = CASE WHEN dbo.fnWA_isReallyNumeric(vs.Target) = 1 THEN convert(real,vs.Target) ELSE NULL END,
 	  	  	              LWL = CASE WHEN dbo.fnWA_isReallyNumeric(vs.L_Warning) = 1 THEN convert(real,vs.L_Warning) ELSE NULL END,
 	  	  	              LRL = CASE WHEN dbo.fnWA_isReallyNumeric(vs.L_Reject) = 1 THEN convert(real,vs.L_Reject) ELSE NULL END 
 	  	  	  From 	 Events 	 BatchEvent
 	  	  	  Join Prod_Units BatchUnit  	  	  	  	 ON 	 BatchUnit.PU_Id = BatchEvent.PU_Id
 	  	  	  Join 	 Variables v 	  	  	  	  	 ON 	 v.PU_Id = BatchUnit.PU_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 v.Event_Type = 1
   	  	   	  Join @BatchFilterList F ON F.VarId = v.Var_Id
 	  	  	  Join Production_Starts ProdStarts 	  	  	  	 ON 	 ProdStarts.PU_Id = BatchUnit.PU_Id 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND ProdStarts.Start_Time <= BatchEvent.Start_Time 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND ((ProdStarts.End_Time > BatchEvent.Start_Time) 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 OR 	 (ProdStarts.End_Time IS NULL))
       LEFT OUTER Join Tests t 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 ON 	 t.var_id = v.var_id 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 t.result is not null 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND T.Result_On = BatchEvent.Timestamp
       LEFT OUTER JOIN Var_Specs vs 	  	  	  	  	  	  	 ON 	 vs.var_id = v.var_id 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 vs.prod_id = ProdStarts.Prod_Id 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND vs.effective_date <= BatchEvent.Start_Time 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND (vs.expiration_date > BatchEvent.Start_Time 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 OR vs.expiration_date IS NULL)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 and dbo.fnWA_isReallyNumeric(vs.U_Reject) = 1
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 and dbo.fnWA_isReallyNumeric(vs.U_Warning) = 1
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 and dbo.fnWA_isReallyNumeric(vs.Target) = 1
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 and dbo.fnWA_isReallyNumeric(vs.L_Warning) = 1
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 and dbo.fnWA_isReallyNumeric(vs.L_Reject) = 1
 	  	  	  Where BatchEvent.Event_Id = @@BatchId
      Fetch Next From Batch_Cursor Into @@BatchId, @@BatchName, @@BatchProductId, @@TimeStamp, @@StartTime
 	   End
Close Batch_Cursor
Deallocate Batch_Cursor
--
Declare Batch_Cursor Insensitive Cursor 
  For Select bl.EventId, bl.EventNumber, bl.ProductId, E.TimeStamp, E.Start_Time
    From @BatchList bl
 	  	  	 Join Events e ON e.Event_Id = bl.EventId
    Order By Unit
  For Read Only
Open Batch_Cursor
Select @@BatchProductId = NULL
Fetch Next From Batch_Cursor Into @@BatchId, @@BatchName, @@BatchProductId, @@TimeStamp, @@StartTime
While @@Fetch_Status = 0
  Begin 	  	  	 
 	  	  	 Insert Into @ParameterDetails (VariableId, Parameter, ProcedureName, TypeId, Timestamp, Value, EventNumber, EventId, URL, UWL, TGT, LWL, LRL)
 	  	  	       Select Variableid = v.var_id,
                   Parameter = v.Var_Desc, 
 	  	  	              ProcedureName = coalesce(Substring(PhaseEvent.UDE_Desc, CharIndex(':',PhaseEvent.UDE_Desc)+1, Len(PhaseEvent.UDE_Desc) - CharIndex(':',PhaseEvent.UDE_Desc)),
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 Substring(OperationEvent.UDE_Desc, CharIndex(':',OperationEvent.UDE_Desc)+1, Len(OperationEvent.UDE_Desc) - CharIndex(':',OperationEvent.UDE_Desc)),
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 UnitProcedure.PU_Desc,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 'Batch'),
 	  	  	              TypeId = Case 
                              When Substring(PhaseEvent.UDE_Desc, CharIndex(':',PhaseEvent.UDE_Desc)+1, Len(PhaseEvent.UDE_Desc) - CharIndex(':',PhaseEvent.UDE_Desc)) Is Not Null Then 3
                              When Substring(OperationEvent.UDE_Desc, CharIndex(':',OperationEvent.UDE_Desc)+1, Len(OperationEvent.UDE_Desc) - CharIndex(':',OperationEvent.UDE_Desc)) Is Not Null Then 2
                              When UnitProcedure.PU_Desc Is Not Null Then 3 Else 0 End,
 	  	  	              Timestamp = @@Timestamp,
 	  	  	  	  	    Value = convert(real, t.result),
 	  	  	              EventNumber = @@BatchName,
 	  	  	              EventId = @@BatchId, 
  	  	  	              URL = convert(real,vs.U_Reject),
 	  	  	              UWL = convert(real,vs.U_Warning),
 	  	  	              TGT = convert(real,vs.Target),
 	  	  	              LWL = convert(real,vs.L_Warning),
 	  	  	              LRL = convert(real,vs.L_Reject)
 	  	  	  From 	 Events 	 BatchEvent
 	  	  	  Join Prod_Units BatchUnit  	  	  	  	 ON 	 BatchUnit.PU_Id = BatchEvent.PU_Id
 	  	  	  Join Event_Components EC 	  	  	 With (index(Event_Components_IDX_Source)) 	 ON 	 EC.Source_Event_Id = BatchEvent.Event_Id
        	  	  Join Events UnitProcedureEvent 	  	  	 ON 	 UnitProcedureEvent.Event_Id = EC.Event_Id
  	  	  	  Join User_Defined_Events OperationEvent 	 With (index(UserDefinedEvents_IDX_EventId)) ON 	 OperationEvent.Event_Id = UnitProcedureEvent.Event_Id
 	  	  	  Join User_Defined_Events PhaseEvent 	  	 With (index(UserDefinedEvents_IDX_ParentUDEId)) ON 	 PhaseEvent.Parent_UDE_Id = OperationEvent.UDE_Id
 	  	  	  Join 	 Variables v 	  	  	  	  	 ON 	 v.PU_Id = PhaseEvent.PU_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 v.Event_Type = 14
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 v.Event_SubType_Id = PhaseEvent.Event_SubType_Id
   	  	  Join PU_Groups PUG 	  	  	  	  	  	  	  	  	  	  	  	 ON 	 PUG.PUG_Id = v.PUG_Id
 	  	  	  Join Prod_Units UnitProcedure  	  	  	  	  	  	 ON 	 UnitProcedure.PU_Id = UnitProcedureEvent.PU_Id
 	  	  	  Join @FilterList F ON F.UnitProcedure = UnitProcedure.PU_Desc 
 	  	  	  	  	  	  	  	  	  	  	  	  	 And F.Operation = Substring(OperationEvent.UDE_Desc, CharIndex(':',OperationEvent.UDE_Desc)+1, Len(OperationEvent.UDE_Desc) - CharIndex(':',OperationEvent.UDE_Desc))
 	  	  	  	  	  	  	  	  	  	  	  	  	 And F.Phase = Substring(PhaseEvent.UDE_Desc, CharIndex(':',PhaseEvent.UDE_Desc)+1, Len(PhaseEvent.UDE_Desc) - CharIndex(':',PhaseEvent.UDE_Desc))
 	  	  	  	  	  	  	  	  	  	  	  	  	 And F.Parameter = V.Var_Desc
 	  	  	  Join Production_Starts ProdStarts 	  	  	  	 ON 	 ProdStarts.PU_Id = BatchUnit.PU_Id 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND ProdStarts.Start_Time <= BatchEvent.Start_Time 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND ((ProdStarts.End_Time > BatchEvent.Start_Time) 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 OR 	 (ProdStarts.End_Time IS NULL))
       Join Tests t 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 ON 	 t.var_id = v.var_id and ISNUMERIC(t.result) = 1
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 t.result is not null 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND T.Result_On = PhaseEvent.End_Time
       LEFT OUTER JOIN Var_Specs vs 	  	  	  	  	  	  	 ON 	 vs.var_id = v.var_id 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 vs.prod_id = ProdStarts.Prod_Id 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND vs.effective_date <= BatchEvent.Start_Time 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND (vs.expiration_date > BatchEvent.Start_Time 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 OR vs.expiration_date IS NULL)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 and ISNUMERIC(vs.U_Reject) = 1
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 and ISNUMERIC(vs.U_Warning) = 1
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 and ISNUMERIC(vs.Target) = 1
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 and ISNUMERIC(vs.L_Warning) = 1
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 and ISNUMERIC(vs.L_Reject) = 1
 	  	  	  Where BatchEvent.Event_Id = @@BatchId
      Fetch Next From Batch_Cursor Into @@BatchId, @@BatchName, @@BatchProductId, @@TimeStamp, @@StartTime
 	   End
Close Batch_Cursor
Deallocate Batch_Cursor
--**********************************************
--Return Grouped Data Block With Statistics
--**********************************************
Select Parameter, 
       VariableId [Id],
       Type = Case 
                When TypeId = 1 Then @sUnitProcedure
                When TypeId = 2 Then @sOperation
                When TypeId = 3 Then @sPhase
                Else @sBatch
              End, 
       TypeId, ProcedureName, Average = COALESCE(avg(Value), 0),[Count] = Count(Value),
       StandardDeviation = COALESCE(stdev(Value), 0), PercentDeviation = COALESCE(stdev(Value) / Avg(Value) * 100.0, 0),
       Minimum = COALESCE(min(Value), 0), Maximum = COALESCE(max(Value), 0), Total = COALESCE(sum(Value),0),
       UpperReject = COALESCE(avg(Value) + 3.0 * stdev(Value),0),
       UpperWarning = COALESCE(avg(Value) + 2.0 * stdev(Value),0),
       LowerWarning = COALESCE(avg(Value) - 2.0 * stdev(Value),0),
       LowerReject = COALESCE(avg(Value) - 3.0 * stdev(Value),0), 
       TimeMarker = COALESCE(min([dbo].[fnServer_CmnConvertFromDbTime] (Timestamp,@InTimeZone)),0)
  From @ParameterDetails
  Group By Parameter, ProcedureName, TypeId, VariableId
  Order By TimeMarker, ProcedureName, Parameter ASC
Declare @@Parameter nVarChar(255)
Declare @@TypeId int
Declare @@ProcedureName nVarChar(255)
Declare @Minimum real
Declare @BucketSize real
Declare @Details Table(
  VariableId int, 
  Timestamp datetime,
  Value real,
  EventNumber nVarChar(50),
  EventId int,
  URL real NULL,
  UWL real NULL,
  TGT real NULL,
  LWL real NULL,
  LRL real NULL,
  Bucket real NULL
)
Declare Item_Cursor Insensitive Cursor 
  For Select Distinct Parameter, TypeId, ProcedureName From @ParameterDetails Where Not Value Is Null
  For Read Only
Open Item_Cursor
Fetch Next From Item_Cursor Into @@Parameter, @@TypeId, @@ProcedureName
While @@Fetch_Status = 0
  Begin
      Delete From @Details
 	  	 
      Insert into @Details (VariableId, Timestamp, Value, EventNumber, EventId, URL, UWL, TGT, LWL, LRL)
 	  	  	  	 Select VariableId, Timestamp, Value, EventNumber, EventId, URL, UWL, TGT, LWL, LRL From @ParameterDetails
 	         Where Parameter = @@Parameter and TypeId = @@TypeId and ProcedureName = @@ProcedureName
 	 
 	  	  	 --**********************************************
 	  	  	 --Return Key
 	  	  	 --**********************************************
      Select Distinct [Id] = VariableId , Parameter = @@Parameter, TypeId = @@TypeId, ProcedureName = @@ProcedureName
      FROM @Details
 	  	  	 --**********************************************
 	  	  	 --Return Variable List
 	  	  	 --**********************************************
      -- Get Capability Statistics
      Select  @Minimum = min(value), @BucketSize = stdev(Value) / 5.0
     	  	 From @Details
 	  	  	 --**********************************************
 	  	  	 --Return Detailed Data block
 	  	  	 --**********************************************
      Select 'Timestamp'=[dbo].[fnServer_CmnConvertFromDbTime] (Timestamp,@InTimeZone), Value, EventNumber, EventId, URL, UWL, TGT, LWL, LRL
     	  	 From @Details
 	  	  	   Order By Timestamp ASC
      Update @Details
 	  	  	  	 Set Bucket = Value
 	  	  	 --**********************************************
 	  	  	 --Return Capability Data
 	  	  	 --**********************************************
      Select Value, 1 [IsBasisProduct]
 	  	  	  	 From @Details
 	  	  	  	 Order By Value ASC
 	  	  	 Fetch Next From Item_Cursor Into @@Parameter, @@TypeId, @@ProcedureName
 	   End
Close Item_Cursor
Deallocate Item_Cursor
