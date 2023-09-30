CREATE procedure [dbo].[spS88R_BatchSummary]
--declare
@EventId int,
@Variables VarChar(8000) = Null,
@DisplayESignatureParameter Bit = 0,-- This passes on the Display E-Signature parameter to the Procedure Detail
@InTimeZone nVarChar(200) 	 =NULL 	  	  	  	 
AS
SET ARITHABORT Off
--**********************************************
-- Translations Setup & Common Prompt Lookup
--**********************************************
-- Retreive the Language Id of the current user
Declare @LangId INT
EXEC spWA_GetCurrentUserInfo @LangId = @LangId OUTPUT
--**********************************************
--**********************************************
-- Convert @Variables to table
--**********************************************
Create Table #SelectedVariables (
 	 Var_Id Int,
 	 Var_Order Int
)
If @Variables = ''
 	 Select @Variables = '0'
If @Variables Is Not Null
 	 Insert Into #SelectedVariables(Var_Id, Var_Order)
 	  	 Execute('Select Distinct Var_Id, Var_Order = CharIndex(convert(nVarChar(10),Var_Id),' + '''' + @Variables + ''''+ ',1)
 	  	  	  	  	  	  	  	 From Variables
 	  	  	  	  	  	  	  	 Where Var_Id in (' + @Variables + ')' + ' and Var_Id <> 0')
Else
 	 Insert Into #SelectedVariables(Var_Id, Var_Order)
 	  	 Select Var_Id, Var_Id From Variables
--**********************************************
Declare @ReportName nVarChar(255)
Declare @CriteriaString nVarChar(1000)
Declare @SpecificationSetting int  -- For Specification Comparisons
Select @SpecificationSetting = convert(int,value) From Site_Parameters Where Parm_id = 13
If @SpecificationSetting is Null Select @SpecificationSetting = 1
Declare @BatchName nVarChar(100)
Declare @BatchId int
Declare @BatchStart datetime
Declare @BatchEnd datetime
Declare @BatchProductId int
Declare @BatchUnit int
Declare @BatchStatus int
Select @BatchName = Event_Num From Events Where Event_id = @EventId
-- Find The First Batch To Be Created With This Name
Select @BatchStart = min(Start_Time), @BatchEnd = max(Timestamp)
  From Events 
  Where Event_Num = @BatchName
-- Get The First Batch Header Information
Select @BatchId = Event_Id, @BatchStatus = Event_Status, @BatchUnit = PU_Id, @BatchProductId = Applied_Product
  From Events 
  Where Event_Num = @BatchName and
        Start_Time = @BatchStart
-- If The Product Is Not Defined At The Batch Level
-- Go To Production Starts To Find The Product
If @BatchProductId Is Null
  Select @BatchProductId = Prod_Id
    From Production_Starts 
    Where PU_Id = @BatchUnit and
          Start_Time <= @BatchEnd and ((End_Time > @BatchEnd) or (End_Time is Null))
Select @ReportName = dbo.fnTranslate(@LangId, 34429, 'Batch Summary')
--**********************************************
-- Return Header Information
--**********************************************
-- Line1: Report Name
-- Line2: Criteria
-- Line3: Generate Time
-- Line4 - n: Column Names
Create table #Prompts (
  PromptId int ,
  PromptName nVarChar(20),
  PromptValue nVarChar(1000),
  PromptValue_Parameter SQL_Variant,
  PromptValue_Parameter2 SQL_Variant
)
Insert into #Prompts (PromptId,PromptName, PromptValue) Values (1,'ReportName', @ReportName)
Insert into #Prompts (PromptId,PromptName, PromptValue, PromptValue_Parameter, PromptValue_Parameter2) Values (2,'Criteria', dbo.fnTranslate(@LangId, 34907, 'For {0} At {1}'), @BatchName, @BatchStart)
Insert into #Prompts (PromptId,PromptName, PromptValue, PromptValue_Parameter) Values (3,'GenerateTime', dbo.fnTranslate(@LangId, 34521, 'Created: {0}'), dbo.fnServer_CmnGetDate(getutcdate()))
Insert into #Prompts (PromptId,PromptName, PromptValue) Values (4,'General', dbo.fnTranslate(@LangId, 34908, 'General'))
Insert into #Prompts (PromptId,PromptName, PromptValue) Values (5,'ElectronicSignature', dbo.fnTranslate(@LangId, 34695, 'Electronic Signature'))
Insert into #Prompts (PromptId,PromptName, PromptValue) Values (6,'UnitSummary', dbo.fnTranslate(@LangId, 34909, 'Unit Summary'))
Insert into #Prompts (PromptId,PromptName, PromptValue) Values (7,'GenealogySummary', dbo.fnTranslate(@LangId, 34910, 'Genealogy Summary'))
Insert into #Prompts (PromptId,PromptName, PromptValue) Values (8,'ProcedureSummary', dbo.fnTranslate(@LangId, 34911, 'Procedure Summary'))
Insert into #Prompts (PromptId,PromptName, PromptValue) Values (9,'ParameterDetail', dbo.fnTranslate(@LangId, 34912, 'Parameter Detail'))
Insert into #Prompts (PromptId,PromptName, PromptValue) Values (10,'BatchUnit', dbo.fnTranslate(@LangId, 34009, 'Unit'))
Insert into #Prompts (PromptId,PromptName, PromptValue) Values (11,'StartTime', dbo.fnTranslate(@LangId, 34011, 'Start Time'))
Insert into #Prompts (PromptId,PromptName, PromptValue) Values (12,'EndTime', dbo.fnTranslate(@LangId, 34012, 'End Time'))
Insert into #Prompts (PromptId,PromptName, PromptValue) Values (13,'DestinationUnitName', dbo.fnTranslate(@LangId, 34913, 'Dest. Unit'))
Insert into #Prompts (PromptId,PromptName, PromptValue) Values (14,'SourceBatchName', dbo.fnTranslate(@LangId, 34914, 'Source Batch'))
Insert into #Prompts (PromptId,PromptName, PromptValue) Values (15,'SourceUnitName', dbo.fnTranslate(@LangId, 34958, 'Source Unit'))
Insert into #Prompts (PromptId,PromptName, PromptValue) Values (16,'Amount', dbo.fnTranslate(@LangId, 34915, 'Amount'))
Insert into #Prompts (PromptId,PromptName, PromptValue) Values (17,'ProcedureUnit', dbo.fnTranslate(@LangId, 34009, 'Unit'))
Insert into #Prompts (PromptId,PromptName, PromptValue) Values (18,'ProcedureType', dbo.fnTranslate(@LangId, 34916, 'Procedure Type'))
Insert into #Prompts (PromptId,PromptName, PromptValue) Values (19,'ProcedureName', dbo.fnTranslate(@LangId, 34917, 'Procedure Name'))
Insert into #Prompts (PromptId,PromptName, PromptValue) Values (20,'ProcedureStartTime', dbo.fnTranslate(@LangId, 34011, 'Start Time'))
Insert into #Prompts (PromptId,PromptName, PromptValue) Values (21,'ProcedureEndTime', dbo.fnTranslate(@LangId, 34012, 'End Time'))
Insert into #Prompts (PromptId,PromptName, PromptValue) Values (22,'ProcedureDuration', dbo.fnTranslate(@LangId, 34656, 'Duration'))
Insert into #Prompts (PromptId,PromptName, PromptValue) Values (23,'ProcedureStatus', dbo.fnTranslate(@LangId, 34918, 'Status'))
Insert into #Prompts (PromptId,PromptName, PromptValue) Values (24,'MaterialCode', dbo.fnTranslate(@LangId, 34919, 'Material'))
Insert into #Prompts (PromptId,PromptName, PromptValue) Values (25,'Parameter', dbo.fnTranslate(@LangId, 34920, 'Parameter'))
Insert into #Prompts (PromptId,PromptName, PromptValue) Values (26,'Value', dbo.fnTranslate(@LangId, 34672, 'Value'))
Insert into #Prompts (PromptId,PromptName, PromptValue) Values (27,'URL', dbo.fnTranslate(@LangId, 34671, 'Upper Reject'))
Insert into #Prompts (PromptId,PromptName, PromptValue) Values (28,'UWL', dbo.fnTranslate(@LangId, 34670, 'Upper Warning'))
Insert into #Prompts (PromptId,PromptName, PromptValue) Values (29,'TGT', dbo.fnTranslate(@LangId, 34669, 'Target'))
Insert into #Prompts (PromptId,PromptName, PromptValue) Values (30,'LWL', dbo.fnTranslate(@LangId, 34668, 'Lower Warning'))
Insert into #Prompts (PromptId,PromptName, PromptValue) Values (31,'LRL', dbo.fnTranslate(@LangId, 34667, 'Lower Reject'))
Insert into #Prompts (PromptId,PromptName, PromptValue) Values (32,'BatchStartTime', @BatchStart )
Insert into #Prompts (PromptId,PromptName, PromptValue) Values (33,'BatchEndTime', @BatchEnd)
If @InTimeZone='' SELECT @InTimeZone=NULL
select PromptId,PromptName,PromptValue,'PromptValue_Parameter'= case when (ISDATE(Convert(varchar,PromptValue_Parameter))=1)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 then
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 [dbo].[fnServer_CmnConvertFromDbTime] (convert(datetime,PromptValue_Parameter),@InTimeZone)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 else
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 PromptValue_Parameter
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 end,
 	  	  	  	  	  	  	  	  	   'PromptValue_Parameter2'= case when (ISDATE(Convert(varchar,PromptValue_Parameter2))=1)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 then
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 [dbo].[fnServer_CmnConvertFromDbTime] (convert(datetime,PromptValue_Parameter2),@InTimeZone)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 else
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 PromptValue_Parameter2
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 end 
From #Prompts
drop table #Prompts
--**********************************************
-- Return Data For Report
--**********************************************
--**********************************************
-- Return Batch Header Information
--**********************************************
-- Create Simple Return Table
Declare @Report Table  (
  [Id] int,
  [Name] nVarChar(50),
  Value nVarChar(255) NULL,
  Value_Parameter VarChar(4000),
  Hyperlink nVarChar(255) NULL,
 	 Tag Int NULL
)
Insert Into @Report ([Id],[Name], Value) Values (1,dbo.fnTranslate(@LangId, 34921, 'Batch Name'), @BatchName)
Insert Into @Report ([Id],[Name], Value) 
  Select 2,dbo.fnTranslate(@LangId, 34922, 'Status'), ProdStatus_Desc 
    From Production_Status 
    Where ProdStatus_Id = @BatchStatus
Insert Into @Report ([Id],[Name], Value) 
  Select 3,dbo.fnTranslate(@LangId, 34923, 'Product'), Prod_Code
  From Products 
  Where Prod_Id = @BatchProductId
Insert Into @Report ([Id],[Name], Value) 
  Select 4,dbo.fnTranslate(@LangId, 34924, 'Started On'), PU_Desc
  From Prod_Units_Base 
  Where PU_Id = @BatchUnit
Insert Into @Report ([Id],[Name], Value, Value_Parameter) Values(5,dbo.fnTranslate(@LangId, 34011, 'Start Time'), '{0}', @BatchStart)
Insert Into @Report ([Id],[Name], Value, Value_Parameter) Values(6,dbo.fnTranslate(@LangId, 34012, 'End Time'), '{0}', @BatchEnd)
select [Id],
  [Name],
  [Value],
  'Value_Parameter'= case when (ISDATE(Convert(varchar,Value_Parameter))=1)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 then
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 convert(varchar,[dbo].[fnServer_CmnConvertFromDbTime] (convert(datetime,Value_Parameter),@InTimeZone))
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 else
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 Value_Parameter
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 end, Hyperlink,Tag
From  @Report Order By Id
--**********************************************
--Return All Batches In Time Order
--**********************************************
Select BatchUnit = pu.pu_Desc, 
StartTime = [dbo].[fnServer_CmnConvertFromDbTime] (coalesce(e.Start_Time, e.[Timestamp]),@InTimeZone), 
 EndTime =  [dbo].[fnServer_CmnConvertFromDbTime] (e.[Timestamp],@InTimeZone), 
 Hyperlink = '<Link>EventDetail.aspx?Id=' + convert(nVarChar(25), e.Event_Id) + '&DisplayESignature=' + convert(nvarchar(1),@DisplayESignatureParameter) + '&TargetTimeZone='+ @InTimeZone +'</Link>'
  From Events e
  Join Prod_Units_Base pu on pu.pu_id = e.pu_id 
  Where e.Event_Num = @BatchName
  order by StartTime ASC
--***************************************************************************************************************
--***************************************************************************************************************
-- Gather All Of The Variable Data, Procedural Data, and Genealogy Data For The Batch
Create Table #VariableData (
 	 VariableId int,
 	 NumberOfDigits int,
 	 Color int,
 	 UnitProcedure nVarChar(100) NULL,
 	 Operation nVarChar(100) NULL,
 	 Phase nVarChar(100) NULL,
 	 PhaseDescription nVarChar(100),
 	 Parameter nVarChar(100) NULL,
 	 ParameterDescription nVarChar(100),
 	 ParameterOrder int NULL,
 	 Value SQL_Variant NULL,
 	 URL SQL_Variant NULL,
 	 UWL SQL_Variant NULL,
 	 TGT SQL_Variant NULL,
 	 LWL SQL_Variant NULL,
 	 LRL SQL_Variant NULL,
 	 Signature_Id Int,
 	 [User] nvarchar(60) NULL,
 	 User_Parameter datetime NULL,
 	 UserReason nVarChar(100) NULL,
 	 UserComment Int NULL,
 	 Approver varchar(60) NULL,
 	 Approver_Parameter datetime NULL,
 	 ApproverReason nVarChar(100) NULL,
 	 ApproverComment Int NULL,
 	 UnitProcedureOrder Int,
 	 OperationOrder Int,
 	 PhaseOrder Int
)
Create Table #ProcedureData (
 ProcedureUnit nVarChar(100),
 ProcedureType nVarChar(100),
 ProcedureTypeId int,
 ProcedureName nVarChar(100) NULL,
 UnitProcedure nVarChar(100) NULL, 
 Operation nVarChar(100) NULL, 
 Phase nVarChar(100) NULL, 
 ProcedureStartTime datetime NULL,
 ProcedureEndTime datetime NULL,
 ProcedureDuration real NULL,
 ProcedureStatus nVarChar(50) NULL,
 MaterialCode nVarChar(50) NULL,
 HyperLink Text NULL   
)
Create Table #GenealogyData (
  DestinationUnitName nVarChar(100),
  SourceUnitName nVarChar(100),
  SouceBatchName nVarChar(100),
  MaterialCode nVarChar(100) NULL,
  Amount real NULL,
  HyperLink varchar(7000) NULL  
)
Declare @@Unit int
Declare @@BatchId int
Declare @@Timestamp datetime
Declare @@StartTime datetime
Declare @UnitName nVarChar(100)
Declare @ProcedureUnit int
Declare @@TempTime datetime
Declare @@UnitProcedureId int
Declare @@UnitProcedureName nVarChar(100)
Declare @@OperationId int
Declare @@OperationName nVarChar(100)
Declare @Line int
-- This gets all the Units
Insert Into #GenealogyData
 	 Select 
 	  	 DestinationUnitName = UnitProcedureUnit.PU_Desc,
 	  	 SourceUnitName = SourceUnits.PU_Desc,
 	  	 SourceBatchName = SourceEvents.Event_Num,
 	   	 MaterialCode = Case When SourceEvents.applied_product is Null Then p1.Prod_Code else p2.Prod_Code end,
 	  	 Amount = UnitProcedureComponents.Dimension_X,
 	  	 Hyperlink = '<Link>EventDetail.aspx?Id=' + convert(nVarChar(25),SourceEvents.Event_Id) + '&DisplayESignature=' + convert(nvarchar(1),@DisplayESignatureParameter) + '</Link>'
  From Events BatchEvent
 	  	 Join Event_Components BatchEventComponent On BatchEventComponent.Source_Event_Id = BatchEvent.Event_Id
 	  	 Join Prod_Units_Base BatchUnit On BatchUnit.PU_Id = BatchEvent.PU_Id
 	  	 Join Events UnitProcedureEvents On UnitProcedureEvents.Event_Id = BatchEventComponent.Event_Id
 	  	 Join Prod_Units_Base UnitProcedureUnit On UnitProcedureUnit.PU_Id = UnitProcedureEvents.PU_Id
 	  	 Join Event_Components UnitProcedureComponents ON UnitProcedureComponents.Event_Id = UnitProcedureEvents.Event_Id And UnitProcedureComponents.Report_As_Consumption = 1
 	  	 Join Events SourceEvents ON SourceEvents.Event_Id = UnitProcedureComponents.Source_Event_Id AND SourceEvents.Event_Id <> @BatchId
 	  	 Join Prod_Units_Base SourceUnits ON SourceUnits.PU_Id = SourceEvents.PU_Id
    Join Production_Starts ps on ps.pu_Id = SourceEvents.pu_id and ps.start_time <= SourceEvents.timestamp and (ps.end_time > SourceEvents.timestamp or ps.end_time is null)
    Join Products p1 on p1.Prod_Id = ps.Prod_Id
    Left Outer Join Products p2 on p2.Prod_Id = SourceEvents.applied_product
 	 Where BatchEvent.Event_Id = @BatchId
  Order By UnitProcedureComponents.Start_Time asc -- ECR# 36050/ECR# 35265, sort based on component start time not on event start time
/*
spS88R_BatchSummary 94
*/
Insert Into #VariableData (VariableId, NumberOfDigits, Color, UnitProcedure, Operation, Phase, PhaseDescription, Parameter, ParameterDescription, ParameterOrder, Value, URL, UWL, TGT, LWL, LRL, Signature_Id, UnitProcedureOrder, OperationOrder, PhaseOrder)
   Select Distinct 
 	  	  	 VariableId = v.Var_Id, 
 	  	  	 NumberOfDigits = coalesce(v.var_precision,0),
 	  	  	 Color = Case 
 	  	  	 When v.Data_Type_Id in (1,2,6,7) and 1 = 1 Then 
 	  	  	  	  	  Case 
 	  	  	  When convert(real, t.result) > convert(real,coalesce(vs.u_reject,t.result)) or convert(real, t.result) < convert(real,coalesce(vs.l_reject,t.result)) Then 2 
 	  	  	 When convert(real, t.result) > convert(real,coalesce(vs.u_warning,t.result)) or convert(real, t.result) < convert(real,coalesce(vs.l_warning,t.result)) Then 1 
 	  	  	 Else 0 
 	  	  	  	  	  End
 	  	  	 When v.Data_Type_Id in (1,2,6,7) and 1 = 2 Then 
 	  	  	  	  	  Case 
 	  	  	  	  	  	  When convert(real, t.result) >= convert(real,coalesce(vs.u_reject,convert(real, t.result)-1)) or convert(real, t.result) <= convert(real,coalesce(vs.l_reject,convert(real, t.result)+1)) Then 2 
 	  	  	  	  	  	  When convert(real, t.result) >= convert(real,coalesce(vs.u_warning,convert(real, t.result)-1)) or convert(real, t.result) <= convert(real,coalesce(vs.l_warning,convert(real, t.result)+1)) Then 1 
 	  	  	  	  	  	 Else 0 
 	  	  	 End
 	  	  	 Else  
 	  	  	  	  	  Case 
 	  	  	  	  	  	  	 When t.result = coalesce(vs.u_reject,'vs.u_reject') or t.result = coalesce(vs.l_reject,'vs.l_reject') Then 2 
 	  	  	  	  	  	  	 When t.result = coalesce(vs.u_warning,'vs.u_warning') or t.result = coalesce(vs.l_warning,'vs.l_warning') Then 1 
 	  	  	  	  	  	  Else 0 
 	  	  	 End
 	  	  	 End, 	        
 	  	  	 UnitProcedure = UnitProcedure.PU_Desc,
 	  	  	 Operation = Substring(OperationEvent.UDE_Desc, CharIndex(':',OperationEvent.UDE_Desc)+1, Len(OperationEvent.UDE_Desc) - CharIndex(':',OperationEvent.UDE_Desc)),
 	  	  	 Phase = Substring(PhaseEvent.UDE_Desc, CharIndex(':',PhaseEvent.UDE_Desc)+1, Len(PhaseEvent.UDE_Desc) - CharIndex(':',PhaseEvent.UDE_Desc)),
 	  	  	 PhaseDescription = Substring(PhaseEvent.UDE_Desc, CharIndex(':',PhaseEvent.UDE_Desc)+1, Len(PhaseEvent.UDE_Desc) - CharIndex(':',PhaseEvent.UDE_Desc)),
 	  	  	 Parameter = v.Var_Desc,  --WAM
 	  	  	 ParameterDescription = v.Var_Desc,
 	  	  	 ParameterOrder = coalesce(1000 * UnitProcedure.pu_order,0) + coalesce(v.pug_order,0),
 	  	  	 Value = dbo.fnDisplayVarcharValue(v.Data_Type_Id, t.Result),
 	  	  	 URL = dbo.fnDisplayVarcharValue(v.Data_Type_Id, vs.U_Reject),
 	  	  	 UWL = dbo.fnDisplayVarcharValue(v.Data_Type_Id, vs.U_Warning),
 	  	  	 TGT = dbo.fnDisplayVarcharValue(v.Data_Type_Id, vs.Target),
 	  	  	 LWL = dbo.fnDisplayVarcharValue(v.Data_Type_Id, vs.L_Warning),
 	  	  	 LRL =dbo.fnDisplayVarcharValue(v.Data_Type_Id,  vs.L_Reject),
 	  	  	 Signature_Id = t.Signature_Id,
 	  	  	 UnitProcedureOrder = EC.Event_Id,
 	  	  	 OperationOrder = OperationEvent.UDE_Id,
 	  	  	 PhaseOrder = PhaseEvent.UDE_Id
 	       	  From 	 Events 	 BatchEvent
 	  	  	 Join Prod_Units_Base BatchUnit  	  	  	 ON 	 BatchUnit.PU_Id = BatchEvent.PU_Id
 	  	  	 Join Event_Components EC 	  	  	  	 ON 	 EC.Source_Event_Id = BatchEvent.Event_Id
 	  	  	 Join Events UnitProcedureEvent  	  	 ON 	 UnitProcedureEvent.Event_Id = EC.Event_Id
 	  	  	 Join User_Defined_Events OperationEvent 	 With( Index(UserDefinedEvents_IDX_EventId)) ON 	 OperationEvent.Event_Id = UnitProcedureEvent.Event_Id
 	  	  	 Join User_Defined_Events PhaseEvent 	 With( Index(UserDefinedEvents_IDX_ParentUDEId)) 	 ON 	 PhaseEvent.Parent_UDE_Id = OperationEvent.UDE_Id
 	  	  	 Join 	 Variables v 	  	  	  	  	 ON 	 v.PU_Id = PhaseEvent.PU_Id
 	  	  	  	  	  	  	  	  	  	  	  	 AND 	 v.Event_Type = 14
 	  	  	  	  	  	  	  	  	  	  	  	 AND 	 v.Event_SubType_Id = PhaseEvent.Event_SubType_Id
 	  	  	 Join PU_Groups PUG 	  	  	  	  	 ON 	 PUG.PUG_Id = v.PUG_Id
 	  	  	 Join Prod_Units_Base UnitProcedure  	  	 ON 	 UnitProcedure.PU_Id = UnitProcedureEvent.PU_Id
 	  	  	 Join Production_Starts ProdStarts 	  	 ON 	 ProdStarts.PU_Id = BatchUnit.PU_Id 
 	  	  	  	  	  	  	  	  	  	  	  	 AND ProdStarts.Start_Time <= BatchEvent.Timestamp
 	  	  	  	  	  	  	  	  	  	  	  	 AND ((ProdStarts.End_Time > BatchEvent.Timestamp) 
 	  	  	  	  	  	  	  	  	  	  	  	 OR 	 (ProdStarts.End_Time IS NULL))
 	  	  	 Join Tests t 	  	  	  	  	  	 ON 	 t.var_id = v.var_id 
 	  	  	  	  	  	  	  	  	  	  	  	 AND 	 t.result is not null 
 	  	  	  	  	  	  	  	  	  	  	  	 AND T.Result_On = PhaseEvent.End_Time
       LEFT JOIN Var_Specs vs 	  	  	  	  	  	 ON 	 vs.var_id = v.var_id 
 	  	  	  	  	  	  	  	  	  	  	  	 AND 	 vs.prod_id = case when BatchEvent.Applied_product is null Then ProdStarts.Prod_Id else BatchEvent.Applied_product end
 	  	  	  	  	  	  	  	  	  	  	  	 AND vs.effective_date <= BatchEvent.Start_Time 
 	  	  	  	  	  	  	  	  	  	  	  	 AND (vs.expiration_date > BatchEvent.Start_Time 
 	  	  	  	  	  	  	  	  	  	  	  	 OR vs.expiration_date IS NULL)
 	  	  	 
 	  	  	  Where BatchEvent.Event_Id = @BatchId
/*
 * Update #VariableData supplying Esignature information
 * This is not part of the initial Insert statement because the E-Signature
 * information contains Text columns and the initial Insert statement performs
 * a Distinct Select and Text columns cause problems with that.
 */
Update #VariableData Set
 	 [User] = esig_pu.Username + ' ({0})',
 	 User_Parameter = esig.Perform_Time,
 	 UserReason = pr.Event_Reason_Name,
 	 UserComment = esig.Perform_Comment_Id,
 	 Approver = esig_vu.Username + ' ({0})',
 	 Approver_Parameter = esig.Verify_Time,
 	 ApproverReason = vr.Event_Reason_Name,
 	 ApproverComment = esig.Verify_Comment_Id
From #VariableData
left outer join esignature esig 	  	  	  	  	  	 on esig.signature_id = #VariableData.signature_id
left outer join users esig_pu 	  	  	  	  	  	  	 on esig.Perform_User_Id = esig_pu.user_id
left outer join users esig_vu 	  	  	  	  	  	  	 on esig.Verify_User_Id = esig_vu.user_id
left outer join event_reasons pr 	  	  	  	  	 On esig.Perform_Reason_Id = pr.Event_Reason_Id
left outer join event_reasons vr 	  	  	  	  	 On esig.Verify_Reason_Id = vr.Event_Reason_Id
    -- Cursor through procedure genealogy starting with Unit Procedure
    Declare UnitProcedureCursor Insensitive Cursor 
      For Select E.Event_Id, PU.PU_Desc
 	  	  	  	  	 From Events E
 	  	  	  	  	  	 Join Prod_Units_Base PU ON PU.PU_Id = E.PU_Id
 	  	  	  	  	  	 Join Event_Components EC ON EC.Event_Id = E.Event_Id
 	  	  	  	  	 Where EC.Source_Event_Id = @BatchId
 	  	  	  	  	  	  	  	  	  	 
      For Read Only
    Open UnitProcedureCursor
    Fetch Next From UnitProcedureCursor Into @@UnitProcedureId, @@UnitProcedureName
    While @@Fetch_Status = 0
      Begin 	  	  	  	 
        -- Insert Unit Procedure Record Into Procedure Summary        
        Insert Into #ProcedureData 
          Select ProcedureUnit = @@UnitProcedureName,
                 ProcedureType = dbo.fnTranslate(@LangId, 34904, 'Unit Procedure'),
                 ProcedureTypeId = 1,
                 ProcedureName = @@UnitProcedureName,
                 UnitProcedure = @@UnitProcedureName,
                 Operation = Null,
                 Phase = Null,
                 ProcedureStartTime = Coalesce(e.start_time, e.[Timestamp]),
                 ProcedureEndTime = e.timestamp,
                 ProcedureDuration = datediff(second,Coalesce(e.start_time, e.[Timestamp]), e.timestamp) / 60.0,
                 ProcedureStatus = psd.ProdStatus_Desc,
                 MaterialCode = p.Prod_Code,
                 HyperLink = '<Link>ProcedureDetail.aspx?Type=1&Id=' + convert(nVarChar(25),e.Event_Id) + '&Batch=' + convert(nVarChar(25),@BatchId) + '&VariableList=' + @Variables + '&DisplayESignature=' + convert(nvarchar(1),@DisplayESignatureParameter) + '</Link>'
            From Events e
            Join Production_Status psd on psd.ProdStatus_Id = e.Event_Status 
            Left Outer Join Products p on p.Prod_id = e.Applied_Product
            Where Event_Id = @@UnitProcedureId   
 	 
        -- Cursor Through Each Operation Contained In This Unit Procedure
        Declare OperationCursor Insensitive Cursor 
          For Select UDE.UDE_Id, Substring(UDE.UDE_Desc, CharIndex(':',UDE.UDE_Desc)+1, Len(UDE.UDE_Desc) - CharIndex(':',UDE.UDE_Desc))
                From User_Defined_Events UDE 
                Where UDE.Event_Id = @@UnitProcedureId
          For Read Only
        Open OperationCursor
        Fetch Next From OperationCursor Into @@OperationId, @@OperationName
        While @@Fetch_Status = 0
          Begin
            -- Insert Operation Record Into Procedure Summary        
            Insert Into #ProcedureData 
              Select ProcedureUnit = @@UnitProcedureName,
                     ProcedureType = dbo.fnTranslate(@LangId, 34905, 'Operation'),
                     ProcedureTypeId = 2,
                     ProcedureName = @@OperationName,
                     UnitProcedure = @@UnitProcedureName,
                     Operation = @@OperationName,
                     Phase = Null,
                     ProcedureStartTime = Coalesce(UDE.start_time, EndTimeData.Result),
                     ProcedureEndTime = EndTimeData.Result,
                     ProcedureDuration = datediff(second,Coalesce(UDE.start_time, EndTimeData.Result), EndTimeData.Result) / 60.0,
                     ProcedureStatus = psd.ProdStatus_Desc,
                     MaterialCode = p.Prod_Code,
                     HyperLink = '<Link>ProcedureDetail.aspx?Type=2&Id=' + convert(nVarChar(25),UDE.UDE_ID) + '&Batch=' + convert(nVarChar(25),@BatchId) + '&VariableList=' + @Variables + '&DisplayESignature=' + convert(nvarchar(1),@DisplayESignatureParameter) + '</Link>'
                From User_Defined_Events UDE
 	  	 Join Events e on e.Event_Id = UDE.Event_Id
                Join Production_Status psd on psd.ProdStatus_Id = e.Event_Status 
                Left Outer Join Products p on p.Prod_id = e.Applied_Product
 	  	 Join Variables EndTimeDataVariable ON EndTimeDataVariable.Var_Desc = '<OperationTimestamp>' and UDE.PU_Id = EndTimeDataVariable.PU_Id
 	  	 Join Tests EndTimeData ON EndTimeData.Var_Id = EndTimeDataVariable.Var_Id and EndTimeData.Result_On = UDE.End_Time
                Where UDE_Id = @@OperationId
            -- Insert Phase Records Into Procedure Summary        
            Insert Into #ProcedureData 
              Select ProcedureUnit = @@UnitProcedureName,
                     ProcedureType = dbo.fnTranslate(@LangId, 34906, 'Phase'),
                     ProcedureTypeId = 3,
                     ProcedureName = e.extended_info,
                     UnitProcedure = @@UnitProcedureName,
                     Operation = @@OperationName,
                     Phase = Substring(UDE.UDE_Desc, CharIndex(':',UDE.UDE_Desc)+1, Len(UDE.UDE_Desc) - CharIndex(':',UDE.UDE_Desc)),
                     ProcedureStartTime = Coalesce(UDE.start_time, EndTimeData.Result),
                     ProcedureEndTime = EndTimeData.Result,
                     ProcedureDuration = datediff(second,Coalesce(UDE.start_time, EndTimeData.Result), EndTimeData.Result) / 60.0,
                     ProcedureStatus = psd.ProdStatus_Desc,
                     MaterialCode = p.Prod_Code,
                     HyperLink = '<Link>ProcedureDetail.aspx?Type=3&Id=' + convert(nVarChar(25),UDE.UDE_ID) + '&Batch=' + convert(nVarChar(25),@BatchId) + '&VariableList=' + @Variables + '&DisplayESignature=' + convert(nvarchar(1),@DisplayESignatureParameter) + '</Link>'
                From User_Defined_Events UDE
 	  	  	  	  	  	  	  	 Join User_Defined_Events Operation on Operation.UDE_Id = UDE.Parent_UDE_ID 	  	  	  	  	  	  	 
                Join Events e on e.Event_id = Operation.event_id
                Join Production_Status psd on psd.ProdStatus_Id = e.Event_Status 
 	  	 Join Variables EndTimeDataVariable ON EndTimeDataVariable.Var_Desc = '<PhaseTimestamp>' and UDE.PU_Id = EndTimeDataVariable.PU_Id
 	  	 Join Tests EndTimeData ON EndTimeData.Var_Id = EndTimeDataVariable.Var_Id and EndTimeData.Result_On = UDE.End_Time
                Left Outer Join Products p on p.Prod_id = e.Applied_Product
                Where UDE.Parent_UDE_ID = @@OperationId   
 	  	  	  	  	 
            Fetch Next From OperationCursor Into @@OperationId, @@OperationName
 	 
/*
select * from Variables
select * from Tests where var_Id = 9474
*/
          End
        Close OperationCursor
        Deallocate OperationCursor  
        Fetch Next From UnitProcedureCursor Into @@UnitProcedureId, @@UnitProcedureName
      End
    Close UnitProcedureCursor
    Deallocate UnitProcedureCursor  
--**********************************************
-- Return Genealogy Summary
--**********************************************
Print 'Returning Genealogy Summary'
Select *   From #GenealogyData
  --Order By SourceUnitName ASC
--**********************************************
-- Return Procedure Summary
--**********************************************
Print 'Returning Procedure Summary'
--Sarla
--Select *   From #ProcedureData
select ProcedureUnit,
 ProcedureType,
 ProcedureTypeId,
 ProcedureName,
 UnitProcedure, 
 Operation, 
 Phase, 
 'ProcedureStartTime' =  [dbo].[fnServer_CmnConvertFromDbTime] (ProcedureStartTime,@InTimeZone) ,
 'ProcedureEndTime'=  [dbo].[fnServer_CmnConvertFromDbTime] (ProcedureEndTime,@InTimeZone) ,
 ProcedureDuration ,
 ProcedureStatus ,
 MaterialCode ,
 HyperLink   
from #ProcedureData
--Sarla
-- Order By ProcedureStartTime, ProcedureTypeId ASC
--********************************************************************************
-- Return Electronic Signature Information
--********************************************************************************
Print 'Returning E-Signature Information'
Delete From  @Report
Declare @ESigId Int
Select @ESigId = Signature_Id
From Events
Where Event_Id = @EventId
If @ESigId Is Not Null
Begin
 	 Insert Into @Report ([Id],[Name], Value, Value_Parameter) 
 	  	 Select 1,dbo.fnTranslate(@LangId, 34688, 'User'), Value = u.Username + ' ({0})', Value_Parameter = esig.Perform_Time
 	  	 From ESignature esig
 	  	 Join Users u On esig.Perform_User_Id = u.User_Id
 	  	 Where esig.Signature_Id = @ESigId
 	 Insert Into @Report ([Id],[Name], Value) 
 	  	 Select 2,dbo.fnTranslate(@LangId, 35136, 'User Reason'), Value = r.Event_Reason_Name 
 	  	 From ESignature esig
 	  	 Join Event_Reasons r On esig.Perform_Reason_Id = r.Event_Reason_Id
 	  	 Where esig.Signature_Id = @ESigId
 	 Insert Into @Report ([Id],[Name], Value, Tag) 
 	  	 Select 3,dbo.fnTranslate(@LangId, 35137, 'User Comment'), Value = c.Comment_Text, c.Comment_Id
 	  	 From ESignature esig
 	  	 Join Comments c On esig.Perform_Comment_Id = c.Comment_Id
 	  	 Where esig.Signature_Id = @ESigId
 	 Insert Into @Report ([Id],[Name], Value, Value_Parameter) 
 	  	 Select 4,dbo.fnTranslate(@LangId, 35138, 'Approver'), Value = u.Username + ' ({0})', Value_Parameter = esig.Verify_Time 
 	  	 From ESignature esig
 	  	 Join Users u On esig.Verify_User_Id = u.User_Id
 	  	 Where esig.Signature_Id = @ESigId
 	 Insert Into @Report ([Id],[Name], Value) 
 	  	 Select 5,dbo.fnTranslate(@LangId, 35139, 'Approver Reason'), Value = r.Event_Reason_Name 
 	  	 From ESignature esig
 	  	 Join Event_Reasons r On esig.Verify_Reason_Id = r.Event_Reason_Id
 	  	 Where esig.Signature_Id = @ESigId
 	 Insert Into @Report ([Id],[Name], Value, Tag) 
 	  	 Select 6,dbo.fnTranslate(@LangId, 35140, 'Approver Comment'), Value = c.Comment_Text, c.Comment_Id
 	  	 From ESignature esig
 	  	 Join Comments c On esig.Verify_Comment_Id = c.Comment_Id
 	  	 Where esig.Signature_Id = @ESigId
End
select [Id],
  [Name],
  [Value],
  'Value_Parameter'= case when (ISDATE(Convert(varchar,Value_Parameter))=1)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 then
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 convert(varchar,[dbo].[fnServer_CmnConvertFromDbTime] (convert(datetime,Value_Parameter),@InTimeZone))
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 else
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 Value_Parameter
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 end, Hyperlink,Tag
From  @Report Order By Id
--********************************************************************************
--**********************************************
-- Return Parameter Detail
-- exec spS88R_BatchSummary @EventId = 88123
--**********************************************
Select 
 	 VariableId ,
 	 NumberOfDigits ,
 	 Color ,
 	 UnitProcedure ,
 	 Operation ,
 	 Phase,
 	 PhaseDescription,
 	 Parameter,
 	 ParameterDescription ,
 	 ParameterOrder,
 	 'Value'= case when (ISDATE(Convert(varchar,[Value]))=1)--Sarla
 	  	  	  	  	 then
 	  	  	  	  	  	 [dbo].[fnServer_CmnConvertFromDbTime] (convert(datetime,[Value]),@InTimeZone)
 	  	  	  	  	 else
 	  	  	  	  	  	 [Value]
 	  	  	  	  	 end,
 	 'URL'= case when (ISDATE(Convert(varchar,URL))=1)--Sarla
 	  	  	  	  	 then
 	  	  	  	  	  	 [dbo].[fnServer_CmnConvertFromDbTime] (convert(datetime,URL),@InTimeZone)
 	  	  	  	  	 else
 	  	  	  	  	  	 URL
 	  	  	  	  	 end,
 	 'UWL' = case when (ISDATE(Convert(varchar,UWL))=1)--Sarla
 	  	  	  	  	 then
 	  	  	  	  	  	 [dbo].[fnServer_CmnConvertFromDbTime] (convert(datetime,UWL),@InTimeZone)
 	  	  	  	  	 else
 	  	  	  	  	  	 UWL
 	  	  	  	  	 end,
 	 'TGT'= case when (ISDATE(Convert(varchar,TGT))=1)--Sarla
 	  	  	  	  	 then
 	  	  	  	  	  	 [dbo].[fnServer_CmnConvertFromDbTime] (convert(datetime,TGT),@InTimeZone)
 	  	  	  	  	 else
 	  	  	  	  	  	 TGT
 	  	  	  	  	 end,
 	 'LWL' = case when (ISDATE(Convert(varchar,LWL))=1)--Sarla
 	  	  	  	  	 then
 	  	  	  	  	  	 [dbo].[fnServer_CmnConvertFromDbTime] (convert(datetime,LWL),@InTimeZone)
 	  	  	  	  	 else
 	  	  	  	  	  	 LWL
 	  	  	  	  	 end,
 	 'LRL' = case when (ISDATE(Convert(varchar,LRL))=1) --Sarla
 	  	  	  	  	 then
 	  	  	  	  	  	 [dbo].[fnServer_CmnConvertFromDbTime] (convert(datetime,LRL),@InTimeZone)
 	  	  	  	  	 else
 	  	  	  	  	  	 LRL
 	  	  	  	  	 end,
 	 Signature_Id ,
 	 [User] ,
 	 'User_Parameter'=[dbo].[fnServer_CmnConvertFromDbTime] (User_Parameter,@InTimeZone),
 	 UserReason ,
 	 UserComment ,
 	 Approver ,
 	 'Approver_Parameter' =[dbo].[fnServer_CmnConvertFromDbTime] (Approver_Parameter,@InTimeZone),
 	 ApproverReason ,
 	 ApproverComment ,
 	 UnitProcedureOrder,
 	 OperationOrder,
 	 PhaseOrder,
 	 var_id,
 	 Var_order 
  From #VariableData
 	 Join #SelectedVariables On #SelectedVariables.Var_Id = #VariableData.VariableId
 	 Order by UnitProcedureOrder, OperationOrder, PhaseOrder, ParameterOrder, Parameter ASC
--**********************************************
--***************************************************************************************************************
--***************************************************************************************************************
-- For Each Unit Procedure, Build Up a Cross-Tab Of Phases And Parameter Values
Declare @@ParameterName nVarChar(100)
Declare @@TempOrder int
Declare @SQL nVarChar(3000)
--Declare @SelectList nvarchar(3000)
--Cursor Through Each Unit Procedure
Declare UnitProcedureCursor Insensitive Cursor 
  For Select UnitProcedure, StartTime = min(ProcedureStartTime) From #ProcedureData  Group By UnitProcedure Order By StartTime ASC
  For Read Only
Open UnitProcedureCursor
Fetch Next From UnitProcedureCursor Into @@UnitProcedureName, @@TempTime
While @@Fetch_Status = 0
  Begin
    -- Create The Initial Columns In The Cross Tab Table    
 Create Table #PhaseData (
      UnitProcedure nVarChar(100),
      Operation nVarChar(100) NULL,
      Phase nVarChar(100) NULL
/*,
      PhaseStartTime datetime NULL,
      PhaseEndTime datetime NULL,
      PhaseDuration real NULL       
*/
    )    
    --Select @SelectList = 'UnitProcedure, Operation, Phase'    
    -- Load Up The Table With the Phases For This Unit Procedure 
    Insert Into #PhaseData
     Select UnitProcedure, Operation , Phase
        From #ProcedureData
        Where #ProcedureData.UnitProcedure = @@UnitProcedureName and
              #ProcedureData.Phase Is Not Null
/*     
 Select UnitProcedure, Operation , Phase, ProcedureStartTime, ProcedureEndTime, 
             Datediff(second,ProcedureStartTime, ProcedureEndTime) / 60.0 
        From #ProcedureData
        Where #ProcedureData.UnitProcedure = @@UnitProcedureName and
              #ProcedureData.Phase Is Not Null
*/
    -- Get The Distict Parameter For This Unit Procedure and Populate The Cross Tab 
    Declare ParameterCursor Insensitive Cursor 
      For Select Parameter, ItemOrder = min(ParameterOrder) From #VariableData Join #SelectedVariables On #SelectedVariables.Var_Id = #VariableData.VariableId Where UnitProcedure = @@UnitProcedurename Group By Parameter Order By ItemOrder, Parameter ASC
      For Read Only
    Open ParameterCursor
/*
spS88R_BatchSummary 94
select * from [d14jrk31].gbdb.dbo.Events where PU_Id = 224
[d14jrk31].gbdb.dbo.spS88R_BatchSummary 710994
select * from #VariableData
Select * from #ProcedureData
*/
    Fetch Next From ParameterCursor Into @@ParameterName, @@TempOrder
    While @@Fetch_Status = 0
      Begin
        --**************************************************
        -- NOTE:
        --         Only adding value column, could also
        --         add limit columns too (we already have
        --         the data in the #VariableData temp 
        --         table).
        --
        --**************************************************
        -- Add Column(s) To Temp Table
        Select @SQL = 'Alter Table #PhaseData Add [v_' + @@ParameterName + '] SQL_Variant NULL'
        Execute (@SQL)
        Select @SQL = 'Alter Table #PhaseData Add [c_' + @@ParameterName + '] int NULL'
        Execute (@SQL)
--        Select @SelectList = @SelectList + ', [v_' + @@ParameterName+ '], [c_' + @@ParameterName + '] '
        -- Merge In Data
        Select @SQL = 'Update #PhaseData Set #PhaseData.[v_' + @@ParameterName + '] = #VariableData.Value,  #PhaseData.[c_' + @@ParameterName + '] = #VariableData.Color '
        Select @SQL = @SQL + 'From #PhaseData, #VariableData '
        Select @SQL = @SQL + 'Where #VariableData.UnitProcedure = #PhaseData.UnitProcedure and '
        Select @SQL = @SQL + '#VariableData.Operation = #PhaseData.Operation and '
        Select @SQL = @SQL + '#VariableData.Phase = #PhaseData.Phase and '
        Select @SQL = @SQL + '#VariableData.Parameter = ' + '''' + @@ParameterName + ''''
        --Select @SQL
        Execute (@SQL)     
        Fetch Next From ParameterCursor Into @@ParameterName, @@TempOrder
      End
    Close ParameterCursor
    Deallocate ParameterCursor  
    --**********************************************
    -- Return The Cross Tab Of Parameter Summary     
    --**********************************************
    Select Title = @@UnitProcedureName + ' ' + dbo.fnTranslate(@LangId, 34888, 'Parameter Summary')
--    Select @SQL = 'Select ' + @SelectList + ' From #PhaseData Order By PhaseStartTime ASC'
    Select @SQL = 'Select * From #PhaseData'
    exec(@SQL)
    -- Drop The Table, Next Unit Procedure Will Potentially Have Different Parameters
    Drop Table #PhaseData
    Fetch Next From UnitProcedureCursor Into @@UnitProcedureName, @@TempTime
  End
Close UnitProcedureCursor
Deallocate UnitProcedureCursor  
--***************************************************************************************************************
--***************************************************************************************************************
--****************************************
--  NOTE: This stored procedure returns
--        a dynamic number of resultsets 
--        based on the number of unit
--        procedures for the batch.  Here
--        Is A summary of those resultsets:
--
--        1. Batch Summary
-- 	  	  	  	 2. Unit Summary
--        3. Genealogy Summary
--        4. Procedure Summary
-- 	  	  	  	 5. Electronic Signature
-- 	  	  	  	 6. Parameter Detail
--        7. - N.  Parameter Cross Tab(s)
--
--        The first three resultsets are 
--        always fixed.  Following the first
--        three, the next N will also have varying 
--        Columns.  To disguish between the 
--        Parameter Cross Tabs and the last
--        and final resultset, examine the 
--        Fieldname of the first column.  When
--        this shows up as "VariableId", you
--        know you have reached the last resultset      
--
--****************************************
--***************************************************************************************************************
--***************************************************************************************************************
-- Clean Up Temporary Tables And Exit
Drop Table #ProcedureData
Drop Table #VariableData
Drop Table #GenealogyData
Drop Table #SelectedVariables
Return
