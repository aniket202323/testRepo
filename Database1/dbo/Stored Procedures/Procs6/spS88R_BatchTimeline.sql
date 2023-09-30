CREATE procedure [dbo].[spS88R_BatchTimeline]
  @ReferenceBatch int,
  @OtherBatches nVarChar(1000),
  @UnitProcedureFilter nVarChar(255),
  @OperationFilter nVarChar(255),
  @SortByBatch int,
  @InTimeZone nVarChar(200)=NULL
AS
Declare @ReportName nVarChar(255)
Declare @CriteriaString nVarChar(1000)
Declare @EventNumber nVarChar(50)
Declare @Unit int
Declare @LineName nVarChar(100)
Declare @UnitName nVarChar(100)
Declare @SQL nVarChar(3000)
Declare @LangId INT
EXEC spWA_GetCurrentUserInfo @LangId = @LangId OUTPUT
Select @ReportName = dbo.fnTranslate(@LangId, 34925, 'Batch Timeline')
Select @EventNumber = event_num, @Unit = pu_id
  From Events 
  Where Event_Id = @ReferenceBatch
Select @UnitName = pu.pu_desc, @LineName = pl.pl_desc
  From prod_units pu 
  Join prod_lines pl on pl.pl_id = pu.pl_id
  Where pu.pu_id = @Unit
Create Table #Prompts (
  PromptId int identity(1,1),
  PromptName nVarChar(20),
  PromptValue nVarChar(1000),
  PromptValue_Parameter SQL_Variant,
  PromptValue_Parameter2 SQL_Variant
)
Insert into #Prompts (PromptName, PromptValue) Values ('ReportName', @ReportName)
Insert into #Prompts (PromptName, PromptValue, PromptValue_Parameter, PromptValue_Parameter2) Values ('Criteria', dbo.fnTranslate(@LangId, 34926, 'Relative To {0} On {1}'), @EventNumber, @LineName + '/' + @UnitName)
Insert into #Prompts (PromptName, PromptValue, PromptValue_Parameter) Values ('GenerateTime', dbo.fnTranslate(@LangId, 34521, 'Created: {0}'), dbo.fnServer_CmnGetDate(getutcdate()))
Insert into #Prompts (PromptName, PromptValue) Values ('TabTitle', @EventNumber)
If @InTimeZone = '' SELECT @InTimeZone=NULL
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
Drop Table #Prompts
--**********************************************
-- Return Data For Report
--**********************************************
Create Table #Events (
  SortKey int NULL,
  Category nVarChar(255),
  Subcategory nVarChar(255) NULL,
  StartTime datetime NULL, 
  EndTime datetime,
  DisplayStartTime datetime,
  DisplayEndTime datetime,
  ShortLabel nVarChar(255) NULL,
  LongLabel nVarChar(255) NULL,
  Color int, 
  Hovertext nVarChar(1000) NULL,
  Hyperlink nvarchar(1200) NULL,
  Hyperlink_Encode nVarChar(100),
  Hyperlink_Encode2 nVarChar(100),
 	 Type Int, -- 0 = Unit Procedure, 1 = Operation, 2 = Phase
)
Create Table #BatchList (
  EventId int,
  EventNumber nVarChar(100),
  EventOrder int
)
Declare @EventOrder int
Declare @ReferenceTime datetime
Declare @MinimumPhaseTime datetime
Declare @MaximumPhaseTime datetime
Declare @ThisItemOrder int
Declare @MinimumTime datetime
Select @EventOrder = 0
-- Get Batch Selections Into Event List
Insert Into #BatchList
  Select e.Event_Id, e.Event_Num, @EventOrder
    From Events e
    Where e.Event_Id = @ReferenceBatch
Select @EventOrder = 1
Select @SQL = 'Select e.Event_Id, e.Event_Num, 1 From Events e Where e.Event_Id in (' + @OtherBatches + ')'
Insert Into #BatchList
  Exec (@SQL)
Declare @UnitOrder int
Declare @BatchOrder int
Declare @ItemOrder int
Select @UnitOrder = 0
Select @EventOrder = 0
Select @BatchOrder = 0 
Select @ItemOrder = 0 
Declare @@BatchId int
Declare @@BatchName nVarChar(50)
Declare @@EventId int
Declare @@Unit int
Declare @@EventNumber nVarChar(100)
Declare @ProcedureUnit int
Declare @@UnitProcedureId int
Declare @@UnitProcedureName nVarChar(100)
Declare @@UnitId int
Declare @@OperationId int
Declare @@OperationName nVarChar(100)
Declare Batch_Cursor Insensitive Cursor 
  For Select EventId, EventNumber From #BatchList Order By EventId Desc, EventOrder ASC
  For Read Only
Open Batch_Cursor
Fetch Next From Batch_Cursor Into @@BatchId, @@BatchName
While @@Fetch_Status = 0
  Begin
 	  	  	     Select @ItemOrder = 0
 	  	  	 
 	  	  	     -- Cursor through procedure genealogy starting with Unit Procedure
 	  	  	     Declare UnitProcedureCursor Insensitive Cursor 
 	  	  	       For Select e.Event_Id, PU.PU_Desc, PU.PU_Id
 	  	  	             From Events e 
 	  	  	  	  	  	  	  	  	  	 Join Prod_Units PU ON PU.PU_Id = E.PU_Id
 	  	  	  	  	  	  	  	  	  	 Join Event_Components EC ON EC.Event_Id = e.Event_Id
 	  	  	             Where ((PU.PU_Desc = @UnitProcedureFilter) or (@UnitProcedureFilter Is Null)) And EC.Source_Event_Id = @@BatchId
 	  	  	       For Read Only
 	  	  	 
 	  	  	     Open UnitProcedureCursor
 	  	  	 
 	  	  	     Fetch Next From UnitProcedureCursor Into @@UnitProcedureId, @@UnitProcedureName, @@UnitId
 	  	  	 
 	  	  	     While @@Fetch_Status = 0
 	  	  	       Begin
  	  	  	  	 Select @UnitOrder = @UnitOrder + 1
 	  	  	         -- Insert Unit Procedure Record Into Procedure Summary        
 	  	  	  	  	     Insert Into #Events (Category, Subcategory, StartTime, EndTime, DisplayStartTime, DisplayEndTime, ShortLabel, LongLabel, Color, HoverText, Hyperlink, Hyperlink_Encode, SortKey, Type)
 	  	  	  	  	  	   Select Category = @@UnitProcedureName, 
 	  	  	  	  	            Subcategory = @@BatchName,
 	  	  	  	  	            StartTime = ISNULL(e.Start_Time, e.TimeStamp),
 	  	  	  	  	            EndTime = e.Timestamp,
 	  	  	  	  	  	    DisplayStartTime = ISNULL(e.Start_Time,E.TimeStamp),
 	  	  	  	  	  	    DisplayEndTime = e.TimeStamp,
 	  	  	  	  	            ShortLabel = @@UnitProcedureName,
 	  	  	  	  	            LongLabel = 'Unit Procedure: ' + @@UnitProcedureName,
 	  	  	  	  	            Color = 0,
 	  	  	  	  	            HoverText = '',
  	  	  	  	  	  	  	   	  	  	  Hyperlink = '<Link>MainFrame.aspx?Control=Applications/MultiBatch TimeLine/MultiBatchTimeLine.ascx&ReferenceBatch='+ convert(nVarChar(20),@ReferenceBatch) + coalesce('&OtherBatches=' + @OtherBatches,'')+ '&TargetTimeZone=' + @InTimeZone + '&UnitProcedure={0}</Link>',
 	  	  	  	  	  	  	  	  	  	  Hyperlink_Encode = @@UnitProcedureName,
 	  	  	  	  	            SortKey = (1000 * @EventOrder) + @ItemOrder + (10000 * @UnitOrder) + (@BatchOrder * 1000000),
 	  	  	  	  	  	  	  	  	  	  Type = 0
 	  	             From Events e
 	  	  	           Where Event_Id = @@UnitProcedureId And (e.Start_Time is not Null and e.Timestamp is not null)
 	  	  	 
 	  	  	  	 Select @ItemOrder = @ItemOrder + 1
 	  	  	  	 
 	  	  	         -- Cursor Through Each Operation Contained In This Unit Procedure
 	  	  	         Declare OperationCursor Insensitive Cursor 
 	  	  	           For Select UDE.UDE_Id, UDE_desc
 	  	  	  	  	  	  	  	  	  	  	 From User_Defined_Events UDE
 	  	  	                 Where Event_Id = @@UnitProcedureId And
 	     	  	                   ((UDE_Desc = @OperationFilter) or (@OperationFilter Is Null))
 	  	  	           For Read Only
 	  	  	 
 	  	  	         Open OperationCursor
 	  	  	 
 	  	  	         Fetch Next From OperationCursor Into @@OperationId, @@OperationName
 	  	  	 
 	  	  	         While @@Fetch_Status = 0
 	  	  	           Begin
 	  	  	             -- Insert Operation Record Into Procedure Summary        
 	  	  	  	  	  	  	     Insert Into #Events (Category, Subcategory, StartTime, EndTime, DisplayStartTime, DisplayEndTime, ShortLabel, LongLabel, Color, HoverText, Hyperlink, Hyperlink_Encode, Hyperlink_Encode2, SortKey, Type)
 	  	  	  	  	  	  	  	   Select Category = SubString(@@OperationName,LEN(@@BatchName) + 2,Len(@@OperationName) - Len(@@BatchName)), 
 	  	  	  	  	  	  	            Subcategory = @@BatchName,
 	  	  	  	  	  	  	            StartTime = Start_Time,
 	  	  	  	  	  	  	            EndTime = End_Time,
 	  	  	  	  	  	  	  	    DisplayStartTime = Start_Time,
 	  	  	  	  	  	  	  	    DisplayEndTime = End_Time,
 	  	  	  	  	  	  	            ShortLabel = @@OperationName,
 	  	  	  	  	  	  	            LongLabel = 'Operation: ' + @@OperationName,
 	  	  	  	  	  	  	            Color = 2,
 	  	  	  	  	  	  	            HoverText = null,
 	  	  	  	  	  	  	   	  	  	  	  	  Hyperlink = '<Link>MainFrame.aspx?Control=Applications/MultiBatch TimeLine/MultiBatchTimeLine.ascx&ReferenceBatch='+ convert(nVarChar(20),@ReferenceBatch) + coalesce('&OtherBatches=' + @OtherBatches,'') + '&TargetTimeZone=' + @InTimeZone + '&UnitProcedure={0}&Operation={1}</Link>',
 	  	  	  	  	  	  	  	  	  	  	  	  Hyperlink_Encode = @@UnitProcedureName,
 	  	  	  	  	  	  	  	  	  	  	  	  Hyperlink_Encode2 = @@OperationName,
 	  	  	  	  	  	  	            SortKey = (1000 * @EventOrder) + @ItemOrder + (10000 * @UnitOrder) + (@BatchOrder * 1000000),
 	  	  	  	  	  	  	  	  	  	  	  	  Type = 1
 	  	  	  	  	             From User_Defined_Events UDE
 	  	  	                 Where UDE_Id = @@OperationId   
 	  	  	  	  	  	 
 	  	  	  	  	 Select @ItemOrder = @ItemOrder + 1
 	  	  	  	  	  	  	 
 	  	  	             -- Insert Phase Records Into Procedure Summary        
 	  	  	  	  	  	  	     Insert Into #Events (Category, Subcategory, StartTime, EndTime, DisplayStartTime, DisplayEndTime, ShortLabel, LongLabel, Color, HoverText, Hyperlink, SortKey, Type)
 	  	  	  	  	  	  	  	   Select Category = SubString(UDE.UDE_Desc,LEN(@@BatchName) + 2,Len(UDE.UDE_Desc) - Len(@@BatchName)), 
 	  	  	  	  	  	  	            Subcategory = @@BatchName,
 	  	  	  	  	  	  	            StartTime = Start_Time,
 	  	  	  	  	  	  	            EndTime = End_Time,
 	  	  	  	  	  	  	  	    DisplayStartTime = Start_Time,
 	  	  	  	  	  	  	  	    DisplayEndTime = End_Time,
 	  	  	  	  	  	  	            ShortLabel = UDE_Desc,
 	  	  	  	  	  	  	            LongLabel = 'Phase: ' + UDE.UDE_Desc,
 	  	  	  	  	  	  	            Color = 3,
 	  	  	  	  	  	  	            HoverText = null,
 	  	  	  	  	  	  	  	  	  	  	  	  Hyperlink = '<Link>Applications/Batch Procedure Detail/ProcedureDetail.aspx?Type=3&Id=' + convert(nVarChar(25),UDE_Id) + '&Batch=' + convert(nVarChar(25),@@BatchId) + '&TargetTimeZone=' + @InTimeZone +'</Link>',
 	  	  	  	  	  	  	            SortKey = (1000 * @EventOrder) + @ItemOrder  + (10000 * @UnitOrder) + (@BatchOrder * 1000000),
 	  	  	  	  	  	  	            Type = 2
 	  	  	  	  	             From User_Defined_Events UDE
 	  	  	                 Where Parent_UDE_Id = @@OperationId  
 	  	  	  	  	  	  	 -- Sort these phases based on time; BS - ECR 33537
 	  	  	  	  	  	  	 -- accordignly @ItemOrder is incremented and set to the #Events table
 	  	  	  	  	  	  	 set @ThisItemOrder = @ItemOrder
 	  	  	  	  	  	  	 Select @MinimumPhaseTime = min(StartTime), @MaximumPhaseTime = max(StartTime) From #Events 
 	  	  	  	  	  	  	 Where Sortkey = (1000 * @EventOrder) + @ThisItemOrder  + (10000 * @UnitOrder) + (@BatchOrder * 1000000) 
 	  	  	  	  	  	   
 	  	  	  	  	  	  	 While @MinimumPhaseTime <= @MaximumPhaseTime 
 	  	  	  	  	  	  	  	  	 and @MinimumPhaseTime is not null and @MaximumPhaseTime is not null
 	  	  	  	  	  	  	 begin
 	  	  	  	  	  	  	  	 Update #Events             
 	  	  	  	  	  	  	  	 Set SortKey = (1000 * @EventOrder) + @ItemOrder  + (10000 * @UnitOrder) + (@BatchOrder * 1000000)
 	  	  	  	  	  	  	  	 Where Sortkey = (1000 * @EventOrder) + @ThisItemOrder  + (10000 * @UnitOrder) + (@BatchOrder * 1000000) 
 	  	  	  	  	  	  	  	  	 and StartTime = @MinimumPhaseTime 
 	  	  	  	  	  	  	  	 Select @MinimumPhaseTime = min(StartTime) From #Events 
 	  	  	  	  	  	  	  	  	 Where Sortkey = (1000 * @EventOrder) + @ThisItemOrder  + (10000 * @UnitOrder) + (@BatchOrder * 1000000) 
 	  	  	  	  	  	  	  	  	  	 and StartTime > @MinimumPhaseTime
     	  	  	  	  	  	  	 Select @ItemOrder = @ItemOrder + 1
 	  	  	  	  	  	  	 end
     	  	  	  	     Select @ItemOrder = @ItemOrder + 1
 	  	  	  	  	  	  	 
 	  	  	             Fetch Next From OperationCursor Into @@OperationId, @@OperationName
 	  	  	           End
 	  	  	 
 	  	  	         Close OperationCursor
 	  	  	         Deallocate OperationCursor  
 	  	  	  
 	  	  	  	 Select @EventOrder = @EventOrder + 1
 	  	  	         Fetch Next From UnitProcedureCursor Into @@UnitProcedureId, @@UnitProcedureName, @@UnitId
 	  	  	       End
 	  	  	 
 	  	  	     Close UnitProcedureCursor
 	  	  	     Deallocate UnitProcedureCursor  
 	  	  	 
      If @BatchOrder = 0
        Begin
          Select @ReferenceTime = min(StartTime) From #Events
--          Print 'Setting REference Time To ' + Cast(@ReferenceTime as nvarchar(50))
        End
      Else
        Begin
/*
spS88R_BatchTimeline 29,  '29,33,37', null, null, 0
*/ 	   
/*
 	   If @ReferenceTime is null
            Print 'Reference is null'
*/
          Select @MinimumTime = min(StartTime) From #Events Where SortKey / 1000000 = @BatchOrder 
/*
 	   If @MinimumTime is NULL
            Print 'Minimum Time is Null'
*/
          Update #Events             
            Set StartTime = dateadd(second, datediff(second, @MinimumTime, StartTime), @ReferenceTime),
                EndTime = dateadd(second, datediff(second, @MinimumTime, EndTime), @ReferenceTime)
            Where SortKey / 1000000 = @BatchOrder 
        End 
      Select @EventOrder = @EventOrder + 1
      Select @BatchOrder = @BatchOrder + 1
Fetch Next From Batch_Cursor Into @@BatchId, @@BatchName
end
Close Batch_Cursor
Deallocate Batch_Cursor
-- Return Report
If @OtherBatches Is Not Null
 	 If @SortByBatch = 0
 	   Begin
            Select Category, Subcategory, 
 	  	  	  	 'StartTime'= [dbo].[fnServer_CmnConvertFromDbTime] (StartTime,@InTimeZone),  
 	  	  	  	 'EndTime'=  [dbo].[fnServer_CmnConvertFromDbTime] (EndTime,@InTimeZone) ,  
 	  	  	  	 'DisplayStartTime'= [dbo].[fnServer_CmnConvertFromDbTime] (DisplayStartTime,@InTimeZone) ,  
 	  	  	  	 'DisplayEndTime'= [dbo].[fnServer_CmnConvertFromDbTime] (DisplayEndTime,@InTimeZone) ,
 	  	  	  	 ShortLabel, LongLabel, Color, Hovertext, Hyperlink, Hyperlink_Encode, Hyperlink_Encode2,sortKey
 	     From #Events
 	  	  	 Order By SortKey % 1000, Type, Category, Subcategory
 	   End
 	 Else
 	   Select Category = e.Subcategory, Subcategory = e.Category,
 	  	  	 'StartTime'= [dbo].[fnServer_CmnConvertFromDbTime] (StartTime,@InTimeZone), 
 	  	  	 'EndTime'= [dbo].[fnServer_CmnConvertFromDbTime] (EndTime,@InTimeZone) , 
 	  	  	 'DisplayStartTime'= [dbo].[fnServer_CmnConvertFromDbTime] (DisplayStartTime,@InTimeZone) ,  
 	  	  	 'DisplayEndTime'= [dbo].[fnServer_CmnConvertFromDbTime] (DisplayEndTime,@InTimeZone) ,  
 	  	  	 ShortLabel, LongLabel, Color, Hovertext, Hyperlink, Hyperlink_Encode, Hyperlink_Encode2
 	     From #Events e
 	     Order by e.Subcategory, SortKey % 1000000 ASC , StartTime
Else
  Select Category, Subcategory = NULL, 
 	  	 'StartTime'= [dbo].[fnServer_CmnConvertFromDbTime] (StartTime,@InTimeZone)  , 
 	  	 'EndTime'= [dbo].[fnServer_CmnConvertFromDbTime] (EndTime,@InTimeZone)  , 
 	  	 'DisplayStartTime'=  [dbo].[fnServer_CmnConvertFromDbTime] (DisplayStartTime,@InTimeZone) ,  
 	  	 'DisplayEndTime'= [dbo].[fnServer_CmnConvertFromDbTime] (DisplayEndTime,@InTimeZone) ,  
 	  	  ShortLabel, LongLabel, Color, Hovertext, Hyperlink, Hyperlink_Encode, Hyperlink_Encode2
    From #Events
    Order by StartTime, SortKey ASC 
Drop Table #Events
Drop Table #BatchList
