--exec spS88R_CycleTimeAnalysis 9,''
CREATE procedure [dbo].[spS88R_CycleTimeAnalysis]
--Declare
@AnalysisId int,
@InTimeZone nVarChar(200)=NULL
AS
set arithignore on
set arithabort off
set ansi_warnings off
/******************************************************
-- For Testing
--*******************************************************
Select @AnalysisId = 2
--*******************************************************/
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
Declare @ReportName nVarChar(255)
Declare @CriteriaString nVarChar(1000)
Declare @AnalysisName nVarChar(1000)
Create Table #ProcedureDetails (  
  [Name] nVarChar(255),
  TypeId int,
  Parent nVarChar(255) NULL,
  StartTime datetime,
  EndTime datetime,
  Duration float NULL,
  EventNumber nVarChar(100),
  EventId int
)
Create Table #FilterList(
  UnitProcedure nVarChar(255) NULL,
  Operation nVarChar(255) NULL,
  Phase nVarChar(255) NULL 
)
Create Table #BatchList (
  EventId int,
  EventNumber nVarChar(100)
)
-- Get Batch Selections Into Event List
Insert Into #BatchList
  Select e.Event_Id, e.Event_Num
    From batch_results_selections s
    Join Events e on e.event_id = s.batch_event_id  
    Where s.Analysis_Id = @AnalysisId and
          s.Checked = 1
-- Get Procedure  Selections Into Filter List
Insert Into #FilterList 
  Select Unit_Procedure, Operation, Phase
    From batch_procedure_selections
      Where Analysis_Id = @AnalysisId
--select * from #FilterList
select @AnalysisName = Report_Name
  from Report_Definitions  
  Where Report_Id = @AnalysisId
Select @ReportName = dbo.fnTranslate(@LangId, 34928, 'Cycle Time Analysis')
--**********************************************
-- Return Header Information
--**********************************************
-- Line1: Report Name
-- Line2: Criteria
-- Line3: Generate Time
-- Line4 - n: Column Names
Create Table #Prompts (
  PromptId int identity(1,1),
  PromptName nVarChar(30),
  PromptValue nVarChar(1000),
  PromptValue_Parameter SQL_Variant
)
Insert into #Prompts (PromptName, PromptValue) Values ('ReportName', @ReportName)
Insert into #Prompts (PromptName, PromptValue, PromptValue_Parameter) Values ('Criteria', dbo.fnTranslate(@LangId, 34599, 'For {0}'), @AnalysisName)
Insert into #Prompts (PromptName, PromptValue, PromptValue_Parameter) Values ('GenerateTime', dbo.fnTranslate(@LangId, 34521, 'Created: {0}'), dbo.fnServer_CmnGetDate(getutcdate()))
Insert into #Prompts (PromptName, PromptValue) Values ('CycleTimeStatistics', dbo.fnTranslate(@LangId, 34928, 'Cycle Time Statistics'))
Insert into #Prompts (PromptName, PromptValue) Values ('ProcessCapability', dbo.fnTranslate(@LangId, 34930, 'Process Capability'))
Insert into #Prompts (PromptName, PromptValue) Values ('Procedure', dbo.fnTranslate(@LangId, 34931, 'Procedure'))
Insert into #Prompts (PromptName, PromptValue) Values ('Type', dbo.fnTranslate(@LangId, 34932, 'Type'))
Insert into #Prompts (PromptName, PromptValue) Values ('Parent', dbo.fnTranslate(@LangId, 34933, 'Parent'))
Insert into #Prompts (PromptName, PromptValue) Values ('Average', dbo.fnTranslate(@LangId, 34934, 'Average'))
Insert into #Prompts (PromptName, PromptValue) Values ('StandardDeviationShort', dbo.fnTranslate(@LangId, 34935, 'Std'))
Insert into #Prompts (PromptName, PromptValue) Values ('StandardDeviationLong', dbo.fnTranslate(@LangId, 34936, 'Standard Deviation'))
Insert into #Prompts (PromptName, PromptValue) Values ('PercentDeviation', dbo.fnTranslate(@LangId, 34937, 'Percent Deviation'))
Insert into #Prompts (PromptName, PromptValue) Values ('Minimum', dbo.fnTranslate(@LangId, 34938, 'Min'))
Insert into #Prompts (PromptName, PromptValue) Values ('Maximum', dbo.fnTranslate(@LangId, 34939, 'Max'))
Insert into #Prompts (PromptName, PromptValue) Values ('Total', dbo.fnTranslate(@LangId, 34940, 'Total'))
Insert into #Prompts (PromptName, PromptValue) Values ('UpperReject', dbo.fnTranslate(@LangId, 34671, 'Upper Reject'))
Insert into #Prompts (PromptName, PromptValue) Values ('UpperWarning', dbo.fnTranslate(@LangId, 34670, 'Upper Warning'))
Insert into #Prompts (PromptName, PromptValue) Values ('LowerWarning', dbo.fnTranslate(@LangId, 34668, 'Lower Warning'))
Insert into #Prompts (PromptName, PromptValue) Values ('LowerReject', dbo.fnTranslate(@LangId, 34667, 'Lower Reject'))
Insert into #Prompts (PromptName, PromptValue) Values ('ParameterStatistics', dbo.fnTranslate(@LangId, 34988, 'Parameter Statistics'))
Insert into #Prompts (PromptName, PromptValue) Values ('BatchList', dbo.fnTranslate(@LangId, 34070, 'Batch List'))
Declare @LineName nVarChar(100)
Declare @UnitName nVarChar(100)
Declare @SQL nVarChar(3000)
If @InTimeZone ='' SELECT @InTimeZone=NULL
select PromptId ,
  PromptName,
  PromptValue ,
  'PromptValue_Parameter'= case when (ISDATE(Convert(varchar,PromptValue_Parameter))=1)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 then
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 [dbo].[fnServer_CmnConvertFromDbTime] (convert(datetime,PromptValue_Parameter),@InTimeZone)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 else
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 PromptValue_Parameter
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 end
 from #Prompts
Drop Table #Prompts
--**********************************************
-- Return Data For Report
--**********************************************
Declare @@BatchId int
Declare @@BatchName nVarChar(50)
Declare @@EventId int
Declare @@Unit int
Declare @@EventNumber nVarChar(100)
Declare @ProcedureUnit int
Declare @@UnitProcedureId int
Declare @@UnitProcedureName nVarChar(100)
Declare @@OperationId int
Declare @@OperationName nVarChar(100)
Declare Batch_Cursor Insensitive Cursor 
  For Select EventId, EventNumber From #BatchList
  For Read Only
Open Batch_Cursor
Fetch Next From Batch_Cursor Into @@BatchId, @@BatchName
While @@Fetch_Status = 0
  Begin
 	  	  	 Declare UnitProcedureCursor Insensitive Cursor 
 	  	  	   For Select e.Event_Id, BatchEvent.Event_Num, e.PU_Id, PU.PU_Desc
 	  	  	  	  	  	 From Events E
 	  	  	  	  	  	  	 Join Prod_Units PU on PU.PU_Id = E.PU_Id
 	  	  	  	  	  	  	 Join Event_Components EC ON EC.Event_Id = E.Event_Id
 	  	  	  	  	  	  	 Join Events BatchEvent ON BatchEvent.Event_Id = EC.Source_Event_Id
 	  	  	  	  	  	 Where EC.Source_Event_Id = @@BatchId
              And PU.PU_Desc in (Select UnitProcedure From #FilterList)
 	  	  	   For Read Only
 	  	  	 
 	  	  	 Open UnitProcedureCursor
 	  	  	 
 	  	  	 Fetch Next From UnitProcedureCursor Into @@EventId, @@EventNumber, @@Unit, @@UnitProcedureName
 	  	  	 
 	  	  	 While @@Fetch_Status = 0
 	  	  	   Begin
 	  	  	  	  	  	     
 	  	  	     -- Insert Unit Procedure Record Into Procedure Summary        
 	  	  	     Insert Into #ProcedureDetails 
 	  	  	       Select 
 	  	  	  	  	  	   Name = @@UnitProcedureName,
 	  	  	    	  	  	 TypeId = 1,
 	  	  	         Parent = @sBatch,
 	  	  	         StartTime = e.start_time,
 	  	  	         EndTime = e.timestamp,
 	  	  	         Duration = datediff(second, e.start_time, e.timestamp),
 	  	  	         EventNumber = @@EventNumber,
 	  	  	         EventId = @@EventId
 	  	  	       From Events e
 	  	  	       Where Event_Id = @@EventId   
 	  	  	 
 	  	  	         -- Cursor Through Each Operation Contained In This Unit Procedure
 	  	  	         Declare OperationCursor Insensitive Cursor 
 	  	  	           For Select UDE.UDE_Id, Substring(UDE.UDE_Desc, CharIndex(':',UDE.UDE_Desc)+1, Len(UDE.UDE_Desc) - CharIndex(':',UDE.UDE_Desc)) 	  	  	                 
 	  	  	                 From User_Defined_Events UDE 
 	  	  	                 Where Event_Id = @@EventId 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 and Substring(UDE.UDE_Desc, CharIndex(':',UDE.UDE_Desc)+1, Len(UDE.UDE_Desc) - CharIndex(':',UDE.UDE_Desc)) in (Select Distinct Operation From #FilterList)
 	  	  	           For Read Only
 	  	  	 
 	  	  	         Open OperationCursor
 	  	  	 
 	  	  	         Fetch Next From OperationCursor Into @@OperationId, @@OperationName
 	  	  	 
 	  	  	         While @@Fetch_Status = 0
 	  	  	           Begin
 	  	  	             -- Insert Operation Record Into Procedure Summary        
 	  	  	  	  	         Insert Into #ProcedureDetails 
 	  	  	  	  	           Select 
 	  	  	  	  	  	  	         Name = @@OperationName,
 	  	  	    	  	  	  	  	  	  	   	  	  TypeId = 2,
 	  	  	  	  	                  Parent = @@UnitProcedureName,
 	  	  	  	  	                  StartTime = start_time,
 	  	  	  	  	                  EndTime = End_Time,
 	  	  	                      Duration = ISNULL(datediff(second, start_time, End_Time),0),
 	  	  	  	  	                  EventNumber = @@EventNumber,
 	  	  	  	  	                  EventId = @@EventId
 	  	  	  	  	             From User_Defined_Events
 	  	  	                 Where UDE_Id = @@OperationId   
 	  	  	 
 	  	  	  	  	  	  	  	  	 --Select * from #ProcedureDetails
 	  	  	 
 	  	  	             -- Insert Phase Records Into Procedure Summary        
 	  	  	  	  	         Insert Into #ProcedureDetails 
 	  	  	  	  	           Select 
                           Name = Substring(UDE_Desc, CharIndex(':',UDE_Desc)+1, Len(UDE_Desc) - CharIndex(':',UDE_Desc)),
 	  	  	    	  	  	  	  	  	  	   	  	  TypeId = 3,
 	  	  	  	  	                  Parent = @@OperationName,
 	  	  	  	  	                  StartTime = start_time,
 	  	  	  	  	                  EndTime = End_time,
 	  	  	                      Duration = IsNull(datediff(second, start_time, end_time),0),
 	  	  	  	  	                  EventNumber = @@EventNumber,
 	  	  	  	  	                  EventId = @@EventId
 	  	  	                 From User_Defined_Events
 	  	  	                 Where Parent_UDE_Id = @@OperationId and
 	  	  	                       Substring(UDE_Desc, CharIndex(':',UDE_Desc)+1, Len(UDE_Desc) - CharIndex(':',UDE_Desc)) in (Select Distinct Phase From #FilterList)   
 	  	  	 
 	  	  	             Fetch Next From OperationCursor Into @@OperationId, @@OperationName
 	  	  	           End
 	  	  	 
 	  	  	         Close OperationCursor
 	  	  	         Deallocate OperationCursor  
 	  	  	 
 	  	  	  	  	 Fetch Next From UnitProcedureCursor Into @@EventId, @@EventNumber, @@Unit, @@UnitProcedureName
 	  	  	   End
 	  	  	 
 	  	  	 Close UnitProcedureCursor
 	  	  	 Deallocate UnitProcedureCursor
 	  	  	 print @@BatchName
 	  	  	 Fetch Next From Batch_Cursor Into @@BatchId, @@BatchName
 	   End
Close Batch_Cursor
Deallocate Batch_Cursor
--*******************************************************/
--Return Grouped Data Block With Statistics
--*******************************************************/
Create Table #ProcedureDetails2 (  
  [Id] int IDENTITY (1, 1) NOT NULL ,
  [Name] nVarChar(255),
  Type nVarChar(2000),
  TypeId int,
  Parent nVarChar(255),
  Average float,
  [Count] int,
  StandardDeviation float,
  PercentDeviation float,
  Minimum float,
  Maximum float,
  Total float,
  UpperReject float,
  UpperWarning float,
  LowerWarning float,
  LowerReject float,
  TimeMarker DateTime
)
Insert Into #ProcedureDetails2
Select
       Name, 
       Type = Case 
                When TypeId = 1 Then @sUnitProcedure
                When TypeId = 2 Then @sOperation
                When TypeId = 3 Then @sPhase
                Else @sBatch
              End, 
       TypeId, Parent, Average = avg(duration), [Count] = Count(duration),
       StandardDeviation = stdev(Duration), PercentDeviation = stdev(Duration) / Avg(Duration) * 100.0,
       Minimum = min(Duration), Maximum = max(Duration), Total = sum(Duration),
       UpperReject = avg(duration) + 3.0 * stdev(Duration),
       UpperWarning = avg(duration) + 2.0 * stdev(Duration),
       LowerWarning = avg(duration) - 2.0 * stdev(Duration),
       LowerReject = avg(duration) - 3.0 * stdev(Duration),
       TimeMarker = min(StartTime)
  From #ProcedureDetails
  Group By  Name, TypeId, Parent
  Order By  TimeMarker, TypeId ASC
update #ProcedureDetails2 set TimeMarker = case when (ISDATE(TimeMarker)=1)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 then
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 [dbo].[fnServer_CmnConvertFromDbTime] (TimeMarker,@InTimeZone)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 else
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 TimeMarker
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 end 
Select * from #ProcedureDetails2
Declare @@Name nVarChar(255)
Declare @@TypeId int
Declare @@Parent nVarChar(255)
Declare @Minimum float
Declare @BucketSize float
Create Table #Details (
  Timestamp datetime,
  Value float,
  EventNumber nVarChar(50),
  EventId int,
  Bucket float NULL
)
Declare Item_Cursor Insensitive Cursor 
  For Select Distinct Name, TypeId, Parent From #ProcedureDetails
  For Read Only
Open Item_Cursor
Fetch Next From Item_Cursor Into @@Name, @@TypeId, @@Parent
While @@Fetch_Status = 0
  Begin
      Truncate Table #Details
      --*******************************************************/
 	  	  	 --Return Key
      --*******************************************************/
      Select Name = @@Name, TypeId = @@TypeId, Parent = @@Parent
      Insert into #Details (Timestamp, Value, EventNumber, EventId)
 	  	  	  	 Select StartTime, Duration, EventNumber, EventId From #ProcedureDetails
 	         Where Name = @@Name and TypeId = @@TypeId and Parent = @@Parent
      -- Get Capability Statistics
      Select @Minimum = min(value), @BucketSize = stdev(Value) / 5.0
     	  	 From #Details
      --*******************************************************/
 	  	  	 --Return Detailed Data block
      --*******************************************************/
      Select 'Timestamp' =  [dbo].[fnServer_CmnConvertFromDbTime] (Timestamp,@InTimeZone), Value, EventNumber, EventId
     	  	 From #Details
 	  	  	   Order By Timestamp ASC
      Update #Details
   	  	  	 Set Bucket = Value
      --*******************************************************/
 	  	  	 --Return Capability Data
      --*******************************************************/
 	  	  	 Select Value, 1 [IsBasisProduct]
 	  	  	  	 From #Details
 	  	  	  	 Order By Value ASC
 	  	  	 Fetch Next From Item_Cursor Into @@Name, @@TypeId, @@Parent
 	   End
Close Item_Cursor
Deallocate Item_Cursor
Drop Table #Details
Drop Table #BatchList
Drop Table #FilterList
Drop Table #ProcedureDetails
Drop Table #ProcedureDetails2
