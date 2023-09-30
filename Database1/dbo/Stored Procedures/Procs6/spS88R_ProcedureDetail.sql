CREATE procedure [dbo].[spS88R_ProcedureDetail]
@Type int,
@EventId int,
@BatchId int,
@Variables VarChar(4000) = Null,
@DisplayESignatureParameter Bit = 0, 	  	  	  	  	 -- This passes on the Display E-Signature parameter to the Procedure Detail
@InTimeZone nVarChar(200)=NULL
AS
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
Declare @SpecificationSetting int  -- For Specification Comparisons
Select @SpecificationSetting = convert(int,value) From Site_Parameters Where Parm_id = 13
If @SpecificationSetting is Null Select @SpecificationSetting = 1
Declare @BatchName nVarChar(100)
Declare @BatchStart datetime
Declare @BatchEnd datetime
Declare @BatchProductId int
Declare @BatchUnit int
Declare @BatchStatus int
Select @BatchName = Event_Num From Events Where Event_id = @BatchId
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
-- Get This Procedure Information
Declare @ProcedureType nVarChar(25)
Declare @ProcedureStart datetime
Declare @ProcedureEnd datetime
Declare @ProcedureStatus int
Declare @ProcedureName nVarChar(50)
Declare @UnitProcedureId int
Declare @OperationId int
Declare @PhaseId int
Declare @ThisBatchId int
Declare @ThisUnitId int
Declare @ThisTimestamp datetime
Declare @ThisStarttime datetime
Select @ProcedureType = Case @Type
                          When 1 then dbo.fnTranslate(@LangId, 34904, 'Unit Procedure')
                          When 2 then dbo.fnTranslate(@LangId, 34905, 'Operation')
                          Else dbo.fnTranslate(@LangId, 34906, 'Phase')
                        End
If @Type = 1
  Begin
 	  	 Select @ProcedureStart = e.Start_Time, 
     	  	    @ProcedureEnd = e.Timestamp,
 	  	        @ProcedureStatus = e.event_status,
     	  	    @ProcedureName = PU.PU_Desc
 	   From Events e
 	  	  	 Join Prod_Units PU on PU.PU_Id = e.PU_Id
 	   Where Event_Id = @EventId
 	 End
Else -- This info must be gathered from User_defined Event
 	 Begin
 	  	 Select @ProcedureStart = e.Start_Time, 
     	  	    @ProcedureEnd = e.End_Time,
 	  	        @ProcedureStatus = '', -- TODO: Figure out what a valid status on UDE is 
     	  	    @ProcedureName = e.UDE_Desc
 	   From User_Defined_Events e
 	   Where UDE_Id = @EventId
 	 End
Select @UnitProcedureId = NULL
Select @OperationId = NULL
Select @PhaseId = NULL
If @Type = 1
  Begin
    Select @UnitProcedureId = @EventId 
  End
If @Type = 2
  Begin
    Select @OperationId = @EventId
    Select @UnitProcedureId = Event_id 
      From User_Defined_Events
      Where UDE_id = @OperationId 
  End
If @Type = 3
  Begin
    Select @PhaseId = @EventId
    Select @OperationId = Parent_UDE_id 
      From User_Defined_Events
      Where UDE_id = @PhaseId 
    Select @UnitProcedureId = Event_id 
      From User_Defined_Events
      Where UDE_id = @OperationId 
  End
Select @ThisBatchId = source_event_id 
  From event_components
  Where event_id = @UnitProcedureId
Select @ThisUnitId = PU_Id,
       @ThisTimestamp = timestamp,
       @ThisStartTime = start_time  
  From Events
  Where Event_Id = @ThisBatchId
--**********************************************
-- Return Header Information
--**********************************************
-- Line1: Report Name
-- Line2: Criteria
-- Line3: Generate Time
-- Line4 - n: Column Names
Create Table #Prompts (
  PromptId int identity(1,1),
  PromptName nVarChar(20),
  PromptValue nVarChar(1000),
  PromptValue_Parameter SQL_Variant 
)
Insert into #Prompts (PromptName, PromptValue) Values ('ReportName', dbo.fnTranslate(@LangId, 34942, 'Procedure Detail'))
Insert into #Prompts (PromptName, PromptValue, PromptValue_Parameter) Values ('Criteria', dbo.fnTranslate(@LangId, 34599, 'For {0}'), IsNull(@BatchName, '?') + ' ' + IsNull(@ProcedureType, '?') + ': ' + IsNull(@ProcedureName, '?'))
Insert into #Prompts (PromptName, PromptValue, PromptValue_Parameter) Values ('GenerateTime', dbo.fnTranslate(@LangId, 34521, 'Created: {0}'), dbo.fnServer_CmnGetDate(getutcdate()))
Insert into #Prompts (PromptName, PromptValue) Values ('General', dbo.fnTranslate(@LangId, 34943, 'General'))
Insert into #Prompts (PromptName, PromptValue) Values ('ElectronicSignature', dbo.fnTranslate(@LangId, 34695, 'Electronic Signature'))
Insert into #Prompts (PromptName, PromptValue) Values ('ProcedureSummary', dbo.fnTranslate(@LangId, 34944, 'Procedure Summary'))
Insert into #Prompts (PromptName, PromptValue) Values ('ParameterDetail', dbo.fnTranslate(@LangId, 34945, 'Parameter Detail'))
Insert into #Prompts (PromptName, PromptValue) Values ('DataSecurity', dbo.fnTranslate(@LangId, 35258, 'Data Security'))
Insert into #Prompts (PromptName, PromptValue) Values ('ProcedureUnit', dbo.fnTranslate(@LangId, 34946, 'Unit'))
Insert into #Prompts (PromptName, PromptValue) Values ('ProcedureType', dbo.fnTranslate(@LangId, 34916, 'Procedure Type'))
Insert into #Prompts (PromptName, PromptValue) Values ('ProcedureName', dbo.fnTranslate(@LangId, 34917, 'Procedure Name'))
Insert into #Prompts (PromptName, PromptValue) Values ('ProcedureStartTime', dbo.fnTranslate(@LangId, 34011, 'Start Time'))
Insert into #Prompts (PromptName, PromptValue) Values ('ProcedureEndTime', dbo.fnTranslate(@LangId, 34012,'End Time'))
Insert into #Prompts (PromptName, PromptValue) Values ('ProcedureDuration', dbo.fnTranslate(@LangId, 34947,'Duration'))
Insert into #Prompts (PromptName, PromptValue) Values ('ProcedureStatus', dbo.fnTranslate(@LangId, 34918,'Status'))
Insert into #Prompts (PromptName, PromptValue) Values ('MaterialCode', dbo.fnTranslate(@LangId, 34919,'Material'))
Insert into #Prompts (PromptName, PromptValue) Values ('Parameter', dbo.fnTranslate(@LangId, 34920, 'Parameter'))
Insert into #Prompts (PromptName, PromptValue) Values ('Variable', dbo.fnTranslate(@LangId, 34847, 'Variable'))
Insert into #Prompts (PromptName, PromptValue) Values ('Value', dbo.fnTranslate(@LangId, 34672, 'Value'))
Insert into #Prompts (PromptName, PromptValue) Values ('URL', dbo.fnTranslate(@LangId, 34671, 'Upper Reject'))
Insert into #Prompts (PromptName, PromptValue) Values ('UWL', dbo.fnTranslate(@LangId, 34670, 'Upper Warning'))
Insert into #Prompts (PromptName, PromptValue) Values ('TGT', dbo.fnTranslate(@LangId, 34669, 'Target'))
Insert into #Prompts (PromptName, PromptValue) Values ('LWL', dbo.fnTranslate(@LangId, 34668, 'Lower Warning'))
Insert into #Prompts (PromptName, PromptValue) Values ('LRL', dbo.fnTranslate(@LangId, 34667, 'Lower Reject'))
Insert into #Prompts (PromptName, PromptValue, PromptValue_Parameter) Values ('BatchStartTime','{0}',@BatchStart) 
Insert into #Prompts (PromptName, PromptValue, PromptValue_Parameter) Values ('BatchEndTime', '{0}', @BatchEnd)
select PromptId,PromptName,PromptValue,'PromptValue_Parameter'= case when (ISDATE(Convert(varchar,PromptValue_Parameter))=1)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 then
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 [dbo].[fnServer_CmnConvertFromDbTime] (convert(datetime,PromptValue_Parameter),@InTimeZone)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 else
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 PromptValue_Parameter
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 end 
From #Prompts
Drop Table #Prompts
--**********************************************
-- Return Data For Report
--**********************************************
--**********************************************
-- Return Batch Header Information
--**********************************************
-- Create Simple Return Table
Create Table #Report (
  Id int identity(1,1),
  Name nVarChar(50),
  Value nVarChar(255) NULL,
  Value_Parameter DateTime,
  Hyperlink nVarChar(255) NULL,
 	 Tag Int NULL
)
Insert Into #Report (Name, Value) Values (dbo.fnTranslate(@LangId, 34917, 'Procedure Name'), @ProcedureName)
Insert Into #Report (Name, Value) Values (dbo.fnTranslate(@LangId, 34916, 'Procedure Type'), @ProcedureType)
Insert Into #Report (Name, Value) 
  Select dbo.fnTranslate(@LangId, 35292,'Procedure Status'), ProdStatus_Desc 
    From Production_Status 
    Where ProdStatus_Id = @ProcedureStatus
Insert Into #Report (Name, Value, Value_Parameter) Values (dbo.fnTranslate(@LangId, 34948, 'Procedure Start Time'), '{0}', @ProcedureStart)
Insert Into #Report (Name, Value, Value_Parameter) Values (dbo.fnTranslate(@LangId, 34949, 'Procedure End Time'), '{0}', @ProcedureEnd) 
Insert Into #Report (Name, Value) Values (dbo.fnTranslate(@LangId, 34921, 'Batch Name'), @BatchName)
Insert Into #Report (Name, Value) 
  Select dbo.fnTranslate(@LangId, 35290,'Batch Status'), ProdStatus_Desc 
    From Production_Status 
    Where ProdStatus_Id = @BatchStatus
Insert Into #Report (Name, Value) 
  Select dbo.fnTranslate(@LangId, 35291,'Batch Product'), Prod_Code
  From Products 
  Where Prod_Id = @BatchProductId
Insert Into #Report (Name, Value) 
  Select dbo.fnTranslate(@LangId, 34924,'Started On'), PU_Desc
  From Prod_Units 
  Where PU_Id = @BatchUnit
Insert Into #Report (Name, Value, Value_Parameter) Values (dbo.fnTranslate(@LangId, 34950, 'Batch Start Time'), '{0}', @BatchStart)
Insert Into #Report (Name, Value, Value_Parameter) Values (dbo.fnTranslate(@LangId, 34951, 'Batch End Time'), '{0}', @BatchEnd)
select [Id],
  [Name],
  [Value],
  'Value_Parameter'= case when (ISDATE(Convert(varchar,Value_Parameter))=1)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 then
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 [dbo].[fnServer_CmnConvertFromDbTime] (convert(datetime,Value_Parameter),@InTimeZone)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 else
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 Value_Parameter
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 end, Hyperlink,Tag
From  #Report Order By Id
--***************************************************************************************************************
--***************************************************************************************************************
-- Gather All Of The Variable Data, Procedural Data, and Genealogy Data For The Batch
Create Table #VariableData (
  VariableId int,
  NumberOfDigits int NULL,
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
  LRL SQL_Variant NULL
)
Create Table #ProcedureData (
 ProcedureUnit nVarChar(100),
 ProcedureType nVarChar(25),
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
Declare @UnitName nVarChar(100)
Declare @ProcedureUnit int
Declare @@TempTime datetime
Declare @@UnitProcedureId int
Declare @@UnitProcedureName nVarChar(100)
Declare @@OperationId int
Declare @@OperationName nVarChar(100)
Select @UnitName = PU_Desc From Prod_Units Where PU_Id = @ThisUnitId
--TODO: This will change later (procedure genealogy is placed on "secondary" unit
Select @ProcedureUnit = PU_Id From Prod_Units Where PU_Desc = '<' + @UnitName + '>'
-- Get Variable Data For This Unit / Batch.  Note that it is timestamped based on 
-- the batch timestamp.  Note also that each "test" record is attached to the 
-- phase it came from through the Event_Id field in the Tests table.  This example 
-- does not use this linkage (although it could).  This example uses the linkages
-- which are also contained in the plant model (external link fields)
-- 
-- TODO: Straighten out phase instance on phase (currently stripping phase instance)    
-- 
Insert Into #VariableData
  Select VariableId = v.Var_Id, 
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
         Operation = OperationEvent.UDE_Desc,
         Phase = PhaseEvent.UDE_Desc,
         PhaseDescription = PhaseEvent.UDE_Desc,
         Parameter = v.Var_Desc, --WAM
         ParameterDescription = v.Var_Desc,
     	  	  ParameterOrder = coalesce(1000 * UnitProcedure.pu_order,0) + coalesce(v.pug_order,0),
         Value = dbo.fnDisplayVarcharValue(v.Data_Type_Id, t.Result),
         URL = dbo.fnDisplayVarcharValue(v.Data_Type_Id, vs.U_Reject),
         UWL = dbo.fnDisplayVarcharValue(v.Data_Type_Id, vs.U_Warning),
         TGT = dbo.fnDisplayVarcharValue(v.Data_Type_Id, vs.Target),
         LWL = dbo.fnDisplayVarcharValue(v.Data_Type_Id, vs.L_Warning),
         LRL =dbo.fnDisplayVarcharValue(v.Data_Type_Id,  vs.L_Reject)
       From Variables v
 	  	  	  	 Join PU_Groups PUG on PUG.PUG_Id = V.PUG_Id
 	  	  	  	 Join User_Defined_Events PhaseEvent on PhaseEvent.UDE_Desc like '%' + SUBString(PUG.External_Link, 3 , Len(PUG.External_Link) - 2) + '%' And V.PU_Id = PhaseEvent.PU_Id
 	  	  	  	 Join User_Defined_Events OperationEvent ON OperationEvent.UDE_Id = PhaseEvent.Parent_UDE_Id 	  	  	  	 
        Join Events UnitProcedureEvent ON UnitProcedureEvent.Event_Id = OperationEvent.Event_Id
 	  	  	  	 Join Prod_Units UnitProcedure ON UnitProcedure.PU_Id = UnitProcedureEvent.PU_Id
 	  	  	  	 Join Event_Components EC ON EC.Event_Id = UnitProcedureEvent.Event_Id
 	  	  	  	 Join Events BatchEvent ON BatchEvent.Event_Id = EC.Source_Event_Id
 	  	  	  	 Join Prod_Units BatchUnit On BatchUnit.PU_Id = BatchEvent.PU_Id
 	  	  	  	 Join Production_Starts ProdStarts ON ProdStarts.PU_Id = BatchUnit.PU_Id And ProdStarts.Start_Time <= BatchEvent.Timestamp And ((ProdStarts.End_Time > BatchEvent.Timestamp) or (ProdStarts.End_Time is Null))
        Join Tests t on t.var_id = v.var_id and t.result is not null and Result_On = PhaseEvent.End_Time
        Left outer Join Var_Specs vs on vs.var_id = v.var_id and vs.prod_id = case when BatchEvent.Applied_product is null Then ProdStarts.Prod_Id else BatchEvent.Applied_product end 
 	  	 and vs.effective_date <= BatchEvent.Start_Time and (vs.expiration_date > BatchEvent.Start_Time or vs.expiration_date is null)
 	  	  	 Where BatchEvent.Event_Id = @BatchId
-- Cursor through procedure genealogy starting with Unit Procedure
 -- Cursor through procedure genealogy starting with Unit Procedure
    Declare UnitProcedureCursor Insensitive Cursor 
      For Select E.Event_Id, PU.PU_Desc
 	  	  	  	  	 From Events E
 	  	  	  	  	  	 Join Prod_Units PU ON PU.PU_Id = E.PU_Id
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
          For Select UDE.UDE_Id, UDE.UDE_Desc
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
                     ProcedureStartTime = UDE.start_time,
                     ProcedureEndTime = EndTimeData.Result,
                     ProcedureDuration = datediff(second,Coalesce(UDE.start_time, EndTimeData.Result), EndTimeData.Result) / 60.0,
                     ProcedureStatus = psd.ProdStatus_Desc,
                     MaterialCode = p.Prod_Code,
                     HyperLink = '<Link>ProcedureDetail.aspx?Type=2&Id=' + convert(nVarChar(25),UDE.UDE_Id) + '&Batch=' + convert(nVarChar(25),@BatchId) + '&VariableList=' + @Variables + '&DisplayESignature=' + convert(nvarchar(1),@DisplayESignatureParameter) + '</Link>'
                From User_Defined_Events UDE
 	  	  	  	  	  	  	  	 Join Events e on e.Event_Id = UDE.Event_Id
                Join Production_Status psd on psd.ProdStatus_Id = e.Event_Status 
                Join Variables EndTimeDataVariable ON EndTimeDataVariable.Var_Desc = '<OperationTimestamp>' and UDE.PU_Id = EndTimeDataVariable.PU_Id
 	  	             Join Tests EndTimeData ON EndTimeData.Var_Id = EndTimeDataVariable.Var_Id and EndTimeData.Entry_On = UDE.End_Time
                Left Outer Join Products p on p.Prod_id = e.Applied_Product
                Where UDE_Id = @@OperationId
/**/
            -- Insert Phase Records Into Procedure Summary        
            Insert Into #ProcedureData 
              Select ProcedureUnit = @@UnitProcedureName,
                     ProcedureType = dbo.fnTranslate(@LangId, 34906, 'Phase'),
                     ProcedureTypeId = 3,
                     ProcedureName = e.extended_info,
                     UnitProcedure = @@UnitProcedureName,
                     Operation = @@OperationName,
                     Phase = UDE.UDE_Desc,
                     ProcedureStartTime = UDE.start_time,
                     ProcedureEndTime = EndTimeData.Result,
                     ProcedureDuration = datediff(second,Coalesce(UDE.start_time, EndTimeData.Result), EndTimeData.Result) / 60.0,
                     ProcedureStatus = psd.ProdStatus_Desc,
                     MaterialCode = p.Prod_Code,
                     HyperLink = '<Link>ProcedureDetail.aspx?Type=3&Id=' + convert(nVarChar(25),UDE.UDE_Id) + '&Batch=' + convert(nVarChar(25),@BatchId) + '&VariableList=' + case when @Variables is not null Then @Variables else ''end + '&DisplayESignature=' + convert(nvarchar(1),@DisplayESignatureParameter) + '</Link>'
                From User_Defined_Events UDE
 	  	  	  	  	  	  	  	 Join User_Defined_Events Operation on Operation.UDE_Id = UDE.Parent_UDE_ID 	  	  	  	  	  	  	 
                Join Events e on e.Event_id = Operation.event_id
                Join Production_Status psd on psd.ProdStatus_Id = e.Event_Status 
                Join Variables EndTimeDataVariable ON EndTimeDataVariable.Var_Desc = '<PhaseTimestamp>' and UDE.PU_Id = EndTimeDataVariable.PU_Id
 	  	             Join Tests EndTimeData ON EndTimeData.Var_Id = EndTimeDataVariable.Var_Id and EndTimeData.Result_On = UDE.End_Time
                Left Outer Join Products p on p.Prod_id = e.Applied_Product
                Where UDE.Parent_UDE_ID = @@OperationId   
 	  	  	  	  	 
            Fetch Next From OperationCursor Into @@OperationId, @@OperationName
 	 
          End
        Close OperationCursor
        Deallocate OperationCursor  
        Fetch Next From UnitProcedureCursor Into @@UnitProcedureId, @@UnitProcedureName
      End
    Close UnitProcedureCursor
    Deallocate UnitProcedureCursor  
/*
spS88R_ProcedureDetail 1,34970,34969
select * from Events where Event_Id in (select Event_Id from Event_Components where Source_Event_Id = 34969)
select * from User_Defined_Events where Event_Id = 34970
select * from User_Defined_Events where Parent_UDe_Id = 3
 	 
sps88R_ProcedureDetail 2,3,34969
sps88R_ProcedureDetail 3,6,34969
*/
If @Type = 1
 	 Begin
 	  	 Delete From #ProcedureData Where UnitProcedure <> @ProcedureName
 	   Delete From #VariableData Where UnitProcedure <> @ProcedureName
 	 End
If @Type = 2
 	 Begin
   	 Delete From #ProcedureData Where Operation <> @ProcedureName Or Operation is null
 	  	 Delete From #VariableData Where Operation <> @ProcedureName
 	 End
If @Type = 3
 	 Begin
 	   Delete From #ProcedureData Where Phase <> @ProcedureName Or Phase Is Null
 	   Delete From #VariableData Where Phase <> @ProcedureName
 	 End 	 
--**********************************************
-- Return Procedure Summary
--**********************************************
 	 update #ProcedureData set ProcedureStartTime=[dbo].[fnServer_CmnConvertFromDbTime] (ProcedureStartTime,@InTimeZone) ,
 	  	 ProcedureEndTime= [dbo].[fnServer_CmnConvertFromDbTime] (ProcedureEndTime,@InTimeZone)
Select * 
  From #ProcedureData
  Order By ProcedureStartTime, ProcedureTypeId ASC
--**********************************************
--**********************************************
-- Return Parameter Detail
--**********************************************
Select * 
  From #VariableData
 	 Join #SelectedVariables On #SelectedVariables.Var_Id = #VariableData.VariableId
  Order by ParameterOrder, UnitProcedure, Operation, Phase, Parameter ASC
--**********************************************
--********************************************************************************
-- Return Electronic Signature Information
--********************************************************************************
Truncate Table #Report
Declare @ESigId Int
If @Type = 1
 	 Select @ESigId = Signature_Id
 	 From Events
 	 Where Event_Id = @EventId
Else
 	 Select @ESigId = Signature_Id
 	 From User_Defined_Events
 	 Where UDE_Id = @EventId
If @ESigId Is Not Null
Begin
 	 Insert Into #Report (Name, Value, Value_Parameter) 
 	  	 Select dbo.fnTranslate(@LangId, 34688, 'User'), Value = u.Username + ' ({0})', Value_Parameter = esig.Perform_Time
 	  	 From ESignature esig
 	  	 Join Users u On esig.Perform_User_Id = u.User_Id
 	  	 Where esig.Signature_Id = @ESigId
 	 Insert Into #Report (Name, Value) 
 	  	 Select dbo.fnTranslate(@LangId, 35136, 'User Reason'), Value = r.Event_Reason_Name 
 	  	 From ESignature esig
 	  	 Join Event_Reasons r On esig.Perform_Reason_Id = r.Event_Reason_Id
 	  	 Where esig.Signature_Id = @ESigId
 	 Insert Into #Report (Name, Value, Tag) 
 	  	 Select dbo.fnTranslate(@LangId, 35137, 'User Comment'), Value = c.Comment_Text, c.Comment_Id
 	  	 From ESignature esig
 	  	 Join Comments c On esig.Perform_Comment_Id = c.Comment_Id
 	  	 Where esig.Signature_Id = @ESigId
 	 Insert Into #Report (Name, Value, Value_Parameter) 
 	  	 Select dbo.fnTranslate(@LangId, 35138, 'Approver'), Value = u.Username + ' ({0})', Value_Parameter = esig.Verify_Time 
 	  	 From ESignature esig
 	  	 Join Users u On esig.Verify_User_Id = u.User_Id
 	  	 Where esig.Signature_Id = @ESigId
 	 Insert Into #Report (Name, Value) 
 	  	 Select dbo.fnTranslate(@LangId, 35139, 'Approver Reason'), Value = r.Event_Reason_Name 
 	  	 From ESignature esig
 	  	 Join Event_Reasons r On esig.Verify_Reason_Id = r.Event_Reason_Id
 	  	 Where esig.Signature_Id = @ESigId
 	 Insert Into #Report (Name, Value, Tag) 
 	  	 Select dbo.fnTranslate(@LangId, 35140, 'Approver Comment'), Value = c.Comment_Text, c.Comment_Id
 	  	 From ESignature esig
 	  	 Join Comments c On esig.Verify_Comment_Id = c.Comment_Id
 	  	 Where esig.Signature_Id = @ESigId
End
select [Id],
  [Name],
  [Value],
  'Value_Parameter'= case when (ISDATE(Convert(varchar,Value_Parameter))=1)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 then
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 [dbo].[fnServer_CmnConvertFromDbTime] (convert(datetime,Value_Parameter),@InTimeZone)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 else
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 Value_Parameter
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 end, Hyperlink,Tag
From  #Report Order By Id
--********************************************************************************
--********************************************************************************
-- Data Security Data
--********************************************************************************
Truncate Table #Report
Insert Into #Report (Name, Value) 
 	 Select dbo.fnTranslate(@LangId, 34688, 'User'), Value = u.Username
 	 From Events e
 	 Join Users u On e.User_Signoff_Id = u.User_Id
 	 Where e.Event_Id = @EventId
Insert Into #Report (Name, Value) 
 	 Select dbo.fnTranslate(@LangId, 35136, 'User Reason'), Value = r.Event_Reason_Name
 	 From Events e
 	 Join Event_Reasons r On e.User_Reason_Id = r.Event_Reason_Id
 	 Where e.Event_Id = @EventId
Insert Into #Report (Name, Value) 
 	 Select dbo.fnTranslate(@LangId, 35138, 'Approver'), Value = u.Username
 	 From Events e
 	 Join Users u On e.Approver_User_Id = u.User_Id
 	 Where e.Event_Id = @EventId
Insert Into #Report (Name, Value) 
 	 Select dbo.fnTranslate(@LangId, 35139, 'Approver Reason'), Value = r.Event_Reason_Name
 	 From Events e
 	 Join Event_Reasons r On e.Approver_Reason_Id = r.Event_Reason_Id
 	 Where e.Event_Id = @EventId
select [Id],
  [Name],
  [Value],
  'Value_Parameter'= case when (ISDATE(Convert(varchar,Value_Parameter))=1)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 then
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 [dbo].[fnServer_CmnConvertFromDbTime] (convert(datetime,Value_Parameter),@InTimeZone)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 else
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 Value_Parameter
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 end, Hyperlink,Tag
From  #Report
--********************************************************************************
Drop Table #Report
--****************************************
--  NOTE: This stored procedure returns
--        a dynamic number of resultsets 
--        based on the number of unit
--        procedures for the batch.  Here
--        Is A summary of those resultsets:
--
--        1. Batch Summary
--        2. Genealogy Summary
--        3. Procedure Summary
--        4. - N.  Parameter Cross Tab(s)
--        N+1. "Other" Variable Data
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
Return
