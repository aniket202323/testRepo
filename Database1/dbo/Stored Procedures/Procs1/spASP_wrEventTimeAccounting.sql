CREATE procedure [dbo].[spASP_wrEventTimeAccounting]
--declare 
@EventId int,
@Command int = NULL,
@SearchEvent nVarChar(50) = NULL,
@EventTypes nVarChar(1000) = NULL, 
@EventSubTypes nVarChar(1000) = NULL, 
@Variables nVarChar(1000) = NULL,
@SkipPrompts int = 0,
@InTimeZone nvarchar(200)=NULL
AS
--TODO: Get Specification Id For Production Rate
Declare @ReportName nvarchar(255)
Declare @CriteriaString nVarChar(1000)
Declare @Unit int
Declare @StartTime datetime
Declare @EndTime datetime
Declare @EventName nVarChar(100)
Declare @EventStartTime datetime
Declare @EventEndTime datetime
Declare @UnitName nVarChar(100)
Declare @VariableName nVarChar(100)
Declare @UDEName nVarChar(100)
Declare @UDEType int
Declare @EventTypeName nVarChar(50)
Declare @SQL nvarchar(3000)
Declare @ProductionRateSpecification int
/*********************************************
-- For Testing
--*********************************************
Select @EventId = 327 --2572 --327
Select @Command =  NULL --3
Select @SearchEvent = NULL --'P11W2604'
Select @EventTypes = '2,1,3,4'
Select @EventSubTypes = '2'
Select @Variables = '10'
Select @SkipPrompts = 0
--**********************************************/
--**********************************************
-- Translations Setup & Common Prompt Lookup
--**********************************************
-- Retreive the Language Id of the current user
Declare @LangId INT
EXEC spWA_GetCurrentUserInfo @LangId = @LangId OUTPUT
-- Get Common Prompts
DECLARE @Unspecified nVarChar(100)
SET @Unspecified = dbo.fnTranslate(@LangId, 34519, '<Unspecified>')
--**********************************************
-- Loookup Initial Information For This Event
--**********************************************
If @EventId Is Null
  Begin
    Raiserror('A Base EventId Must Be Supplied',16,1)
    Return
  End
If @Command Is Not Null
  Begin
 	  	 Select @Unit = PU_Id, @EventEndTime = Timestamp
 	  	   From Events e
 	  	   Where Event_Id = @EventId 
   	 Select @EventId = NULL
  End
If @Command = 1
  Begin
    -- Scroll Next Event
    Select @EventId = Event_Id 
      From Events 
      Where PU_Id = @Unit and 
            Timestamp = (Select Min(Timestamp) From Events Where PU_Id = @Unit and Timestamp > @EventEndTime)
  End
Else If @Command = 2
  Begin
    -- Scroll Previous Event
    Select @EventId = Event_Id 
      From Events 
      Where PU_Id = @Unit and
            Timestamp = (Select Max(Timestamp) From Events Where PU_Id = @Unit and Timestamp < @EventEndTime)
  End
Else If @Command = 3
  Begin
    -- Find Event
 	 If @SearchEvent Is Null
 	   Begin
 	     Raiserror('A Search Event Must Be Supplied To Search',16,1)
 	     Return
 	   End
 	 Declare @EventCount int
 	 SET @EventId = NULL
 	 SELECT @EventCount = Count(*) 
 	 FROM Events
 	 WHERE Event_Num = @SearchEvent
 	 If @EventCount > 1 
 	 BEGIN
 	   Select @EventId = Event_Id 
 	   From Events 
 	   Where PU_Id = @Unit and
            Event_Num like @SearchEvent
 	 END
        IF @EventId is null 
            SELECT @EventId = MAX(Event_Id)
            FROM Events
 	     WHERE Event_Num = @SearchEvent
 	 
/*
select PU_ID from events where Event_Id = 327
    Select  Event_Id , Event_Num
      From Events 
      Where PU_Id = 2 and
            Event_Num like 'P11W2624-3'
    Select *
      From Events where Event_Id = 2459
      Where Event_Num like 'P11W2624-3'
Select * from Event_Components where Source_Event_Id = 327
*/
  End
--Else This is Just A Straight Query
If @EventId Is Null
  Begin
    Raiserror('Command Did Not Find Event To Return',16,1)
    Return
  End
Select @Unit = PU_Id, @EventName = Event_Num, 
       @EventStartTime = Start_Time, @EventEndTime = Timestamp 
  From Events e
  Where Event_Id = @EventId 
Select @EventTypeName = s.event_subtype_desc
  from event_configuration e 
  join event_subtypes s on s.Event_Subtype_Id = e.Event_Subtype_Id
  where e.pu_id = @Unit and
        e.et_id = 1
-- Get Start Time If Missing
If @EventStartTime Is Null
  Select @EventStartTime = max(Timestamp) From Events Where PU_Id = @Unit and Timestamp < @EventEndTime
Select @EndTime = min(Timestamp) From Events Where PU_Id = @Unit and Timestamp > @EventEndTime
if @EndTime is null
  Select @EndTime = TimeStamp From Events Where Event_Id = @EventId
Select @StartTime = Start_Time From Events Where PU_Id = @Unit and Timestamp = @EventStartTime
If @StartTime Is Null 
  Select @StartTime = max(Timestamp) From Events Where PU_Id = @Unit and Timestamp < @EventStartTime
--**********************************************
-- Loookup Parameters For This Report
--**********************************************
Select @ReportName = COALESCE(@EventTypeName, dbo.fnTranslate(@LangId, 34776, '*Unknown*')) + ' ' + dbo.fnTranslate(@LangId, 34777, 'Time Accounting') + ' - ' +  @EventName 
Select @UnitName = PU_Desc From Prod_Units Where PU_Id = @Unit
Select @ProductionRateSpecification = NULL
If @EventTypes = '-1' or @EventTypes Is Null
  Select @EventTypes = '4,19,1,2,3,0'
--**********************************************
-- Return Header Information
--**********************************************
-- Line1: Report Name
-- Line2: Criteria
-- Line3: Generate Time
-- Line4 - n: Column Names
Create Table #Prompts (
  PromptId int identity(1,1),
  PromptName nvarchar(20),
  PromptValue nvarchar(1000),
  PromptValue_Parameter SQL_Variant,
  PromptValue_Parameter2 SQL_Variant
)
Insert into #Prompts (PromptName, PromptValue) Values ('ReportName', @ReportName)
Insert into #Prompts (PromptName, PromptValue, PromptValue_Parameter, PromptValue_Parameter2)
  Values('Criteria', dbo.fnTranslate(@LangId, 34778, '{0} On {1}'), @EventTypeName + ' ' + @EventName, @UnitName)
Insert into #Prompts (PromptName, PromptValue, PromptValue_Parameter) Values ('GenerateTime', dbo.fnTranslate(@LangId, 34521, 'Created: {0}'), [dbo].[fnServer_CmnConvertFromDbTime] (dbo.fnServer_CmnGetDate(getutcdate()),@InTimeZone))
Insert into #Prompts (PromptName, PromptValue) Values ('TabTitle', @EventName)
Insert into #Prompts (PromptName, PromptValue) Values ('Comments', dbo.fnTranslate(@LangId, 34743, 'Comments'))
Insert into #Prompts (PromptName, PromptValue, PromptValue_Parameter) Values ('EventId', '{0}', @EventId)
Insert into #Prompts (PromptName, PromptValue, PromptValue_Parameter) Values ('TrendStart', '{0}',[dbo].[fnServer_CmnConvertFromDbTime] (@StartTime,@InTimeZone))
Insert into #Prompts (PromptName, PromptValue, PromptValue_Parameter) Values ('TrendEnd', '{0}', [dbo].[fnServer_CmnConvertFromDbTime](@EndTime,@InTimeZone))
Insert into #Prompts (PromptName, PromptValue, PromptValue_Parameter) Values ('StartTime', '{0}', [dbo].[fnServer_CmnConvertFromDbTime](@EventStartTime,@InTimeZone))
Insert into #Prompts (PromptName, PromptValue, PromptValue_Parameter) Values ('EndTime', '{0}', [dbo].[fnServer_CmnConvertFromDbTime](@EventEndTime,@InTimeZone))
Insert into #Prompts (PromptName, PromptValue, PromptValue_Parameter) Values ('UnitId', '{0}', @Unit)
Insert into #Prompts (PromptName, PromptValue) Values ('PreviousHover', dbo.fnTranslate(@LangId, 35038, 'Previous') + ' ' + @EventTypeName)
Insert into #Prompts (PromptName, PromptValue) Values ('NextHover', dbo.fnTranslate(@LangId, 35037, 'Next') + ' ' + @EventTypeName)
If @SkipPrompts = 0 
 begin  
 	 --select PromptId,PromptName,PromptValue,'PromptValue_Parameter'= case when (ISDATE(Convert(varchar,PromptValue_Parameter))=1)
 	 -- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 then
 	 -- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 [dbo].[fnServer_CmnConvertFromDbTime] (convert(datetime,PromptValue_Parameter),@InTimeZone)
 	 -- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 else
 	 -- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 PromptValue_Parameter
 	 -- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 end,
 	 -- 	  	  	  	  	  	  	  	  	  	 'PromptValue_Parameter2'= case when (ISDATE(Convert(varchar,PromptValue_Parameter2))=1)
 	 -- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 then
 	 -- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 [dbo].[fnServer_CmnConvertFromDbTime] (convert(datetime,PromptValue_Parameter2),@InTimeZone)
 	 -- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 else
 	 -- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 PromptValue_Parameter2
 	 -- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 end 
 	 SELECT * From #Prompts
 end  
Drop Table #Prompts
--Select * from Language_Data where Prompt_String like 'Previous'
--**********************************************
-- Return Data For Report
--**********************************************
Create Table #Events (
  SortKey int NULL,
  Category nvarchar(255),
  Subcategory nvarchar(255) NULL,
  StartTime datetime NULL, 
  EndTime datetime,
  ShortLabel nvarchar(255) NULL,
  LongLabel nvarchar(255) NULL,
  LongLabel_Parameter SQL_Variant,
  Color int, 
  Hovertext nVarChar(1000) NULL,
  Hyperlink nvarchar(255) NULL
)
Create Table #AvailableEventTypes (
 	 EventTypeId Int,
 	 EventSubTypeId Int,
 	 EventDescription Varchar(8000)
)
Create Table #EventTypes (
  Item int,
  ItemOrder int
)
Create Table #EventSubTypes (
  Item int,
  ItemOrder int
)
Create Table #Variables (
  Item int,
  ItemOrder int
)
Insert Into #AvailableEventTypes
 	 Exec spWO_ListEventTypes @VariableId = Null, @UnitId = @Unit
Select @SQL = 'Select ET_Id, ItemOrder = CharIndex(convert(nvarchar(10),ET_Id),' + '''' + @EventTypes + '''' + ',1) ' +
 	  	  	  	  	  	  	 'From Event_Types ' +
 	  	  	  	  	  	  	 'Where ET_Id in ('  + @EventTypes +  ') ' + 	 'And ET_Id In (Select EventTypeId From #AvailableEventTypes)'
Insert Into #EventTypes
  Exec (@SQL)
Select @SQL = 'Select ET_Id = -2, ItemOrder = CharIndex(''-2'',' + '''' + @EventTypes + '''' + ',1) Where -2 in ('  + @EventTypes +  ')'
Insert Into #EventTypes
  Exec (@SQL)
If @EventSubTypes Is Not Null
  Begin
    Select @SQL = 'Select Event_Subtype_Id, ItemOrder = CharIndex(convert(nvarchar(10),Event_Subtype_Id),' + '''' + @EventSubTypes + '''' + ',1)  From Event_SubTypes Where Event_Subtype_Id in ('  + @EventsubTypes  + ')'
    Insert Into #EventsubTypes
      Exec (@SQL)
  End
If @Variables Is Not Null
  Begin
    Select @SQL = 'Select Var_Id, ItemOrder = CharIndex(convert(nvarchar(10),Var_Id),' + '''' + @Variables + '''' + ',1)  From Variables Where Var_Id in (' + @Variables +  ')'
    Insert Into #Variables
      Exec (@SQL)
  End
Declare @@EventType int
Declare @@EventSubtypeId int
Declare @@VariableId int
Declare @SortKey int
Select @SortKey = 0
Declare Event_Cursor Insensitive Cursor 
  For Select Item From #EventTypes Order By ItemOrder
  For Read Only
Open Event_Cursor
Declare SubType_Cursor Insensitive Cursor 
  For Select Item From #EventSubTypes Order By ItemOrder
  For Read Only
Open SubType_Cursor
Declare Variable_Cursor Insensitive Cursor 
  For Select Item From #Variables Order By ItemOrder
  For Read Only
Open Variable_Cursor
IF @StartTime IS NULL
  SELECT @StartTime = '1970-01-01'
Fetch Next From Event_Cursor Into @@EventType
While @@Fetch_Status = 0
  Begin
    Select @SortKey = @SortKey + 1
 	  	 If @@EventType = -2
 	  	  	 Begin
 	  	  	  	 --*******************************************************************  
        -- Non-Productive Time
        --*******************************************************************  
 	  	  	  	 Print 'Retrieving non-productive time for unit ' + Cast(@Unit As nvarchar(10))
 	  	  	  	 Insert Into #Events (Category, Subcategory, StartTime, EndTime, ShortLabel, LongLabel, LongLabel_Parameter, Color, HoverText, Hyperlink, SortKey)
 	  	  	  	  	 Select Category = dbo.fnTranslate(@LangId, 35132, 'Non-Productive Time'),
 	  	  	  	  	  	  	 Subcategory = Null,
 	  	  	  	  	  	  	 StartTime = npd.Start_Time,
 	  	  	  	  	  	  	 EndTime = npd.End_Time,
 	  	  	  	  	  	  	 ShortLabel = dbo.fnTranslate(@LangId, 35153, 'NP Time'),
 	  	  	  	  	  	  	 LongLabel = '{0}',
 	  	  	  	  	  	  	 LongLabel_Parameter = dbo.fnTranslate(@LangId, 35132, 'Non-Productive Time') + Coalesce(' (' + Event_Reason_Name + ')', ''),
 	  	  	  	  	  	  	 Color = 3328250, --Orange
 	  	  	  	  	  	  	 HoverText = c.Comment_Text,
 	  	  	  	  	  	  	 Hyperlink = Null,
 	  	  	  	  	  	  	 SortKey = @SortKey
 	  	  	  	  	 From NonProductive_Detail npd
 	  	  	  	  	 Left Outer Join Event_Reason_Tree_Data ertd On (ertd.Event_Reason_Tree_Data_Id = npd.Event_Reason_Tree_Data_Id)
 	  	  	  	  	 Left Outer Join Event_Reasons er On er.Event_Reason_Id = ertd.Event_Reason_Id
 	  	  	  	  	 Left Outer Join Prod_Units pu On pu.PU_Id = npd.PU_Id
 	  	  	  	  	 Left Outer Join Comments c On c.Comment_id = npd.Comment_Id
 	  	  	  	  	 Where npd.PU_Id = @Unit
 	  	  	  	  	  	  	  	 And ((npd.Start_Time > @StartTime And npd.Start_Time < @EndTime) --NPT starts in the range
 	  	  	  	  	  	  	  	 Or (npd.End_Time > @StartTime And npd.End_Time < @EndTime) --NPT ends in the range
 	  	  	  	  	  	  	  	 Or (npd.Start_Time <= @StartTime And npd.End_Time >= @EndTime)) --NPT encompasses the range
 	  	  	  	 Print Cast(@@Rowcount As nvarchar(10)) + ' Non-Productive Events Found'
 	  	  	 End 
    If @@EventType = 1  	  	 
      Begin
        --*******************************************************************  
        -- Production Events 
        --*******************************************************************  
        Insert Into #Events (Category, Subcategory, StartTime, EndTime, ShortLabel, LongLabel, LongLabel_Parameter, Color, HoverText, Hyperlink, SortKey)
 	    	   Select Category = ISNULL(@EventTypeName, 'Unknown'), 
 	              Subcategory = NULL,
 	              StartTime = e.Start_Time,
 	              EndTime = e.Timestamp,
 	              shortLabel = e.event_num,
 	              LongLabel = '{0} (' + s.ProdStatus_Desc + ')',
                     LongLabel_Parameter = e.event_num,
 	              Color = ec.Color,
 	              HoverText = convert(nvarchar(1000),c.Comment_Text),
 	  	  	          Hyperlink = 'EventDetail.aspx?Id=' + convert(nvarchar(20),e.Event_Id) + '&TargetTimeZone=' + @InTimeZone,
               SortKey = @SortKey
 	  	  	     From Events e
 	  	  	     Join Production_Status s on s.ProdStatus_id = e.Event_Status
 	  	  	     Join Colors ec on ec.Color_Id = s.Color_Id
 	  	       Left Outer Join Comments c On c.Comment_id = e.Comment_Id
 	  	  	     Where e.PU_id = @Unit and
 	  	  	           e.Timestamp > @StartTime and 
 	  	  	           e.Timestamp <= @EndTime 
 	  	             Order By e.Timestamp ASC
        -- Fill In Start Times If Necessary
        If (Select Count(StartTime) From #Events Where Category = @EventTypeName and StartTime Is Not Null) = 0
          Begin
            Update #Events
              Set StartTime = (Select max(Events.Timestamp) From Events Where Events.PU_Id = @Unit and Events.Timestamp < #Events.EndTime)
              From #Events
              Where #Events.Category = @EventTypeName and 
                    #Events.StartTime Is Null  
          End
        --*******************************************************************  
      End
    Else If @@EventType = 2
      Begin
        --*******************************************************************  
        -- Downtime
        --*******************************************************************  
        Insert Into #Events (Category, Subcategory, StartTime, EndTime, ShortLabel, LongLabel, Color, HoverText, Hyperlink, SortKey)
 	  	    	   Select Category = dbo.fnTranslate(@LangId, 34775, 'Downtime'), 
 	  	              Subcategory = NULL,
 	  	              StartTime = Case When d.Start_Time < @StartTime Then @StartTime Else d.Start_Time End,
 	  	              EndTime = coalesce(d.End_Time, @EndTime),
 	  	              ShortLabel = coalesce('(' + tef.tefault_name + ')', coalesce(r1.event_reason_name,@Unspecified)),
 	  	              LongLabel = coalesce(r1.event_reason_name, @Unspecified)  + coalesce(',' + r2.event_reason_name,'') + coalesce(' (' + tef.tefault_name + ')',''),
 	  	              Color = Case when d.reason_level1 Is Null Then (Select Color From Colors Where Color_Id = 3) Else (Select Color From Colors Where Color_Id = 1) End,
 	  	              HoverText = NULL,
 	  	  	  	          Hyperlink = 'DowntimeDetail.aspx?Id=' + convert(nvarchar(20),d.tedet_Id) + '&TargetTimeZone=' + @InTimeZone,
 	                SortKey = @SortKey
 	  	  	    	  	 From Timed_Event_Details d
 	  	         Left Outer Join Event_Reasons r1 on r1.event_reason_id = d.reason_level1
 	  	         Left Outer Join Event_Reasons r2 on r2.event_reason_id = d.reason_level2
 	  	         Left Outer Join Timed_Event_Fault tef on tef.tefault_id = d.tefault_id
 	  	  	  	  	   Where d.PU_id = @Unit and
 	  	  	    	  	       d.Start_Time = (Select Max(Start_Time) From Timed_Event_Details t Where t.PU_Id = @Unit and t.start_time < @StartTime) and
 	  	  	    	       ((d.End_Time > @StartTime) or (d.End_Time is Null))
  	  	  	  	 Union
 	  	  	    	   Select Category = dbo.fnTranslate(@LangId, 34775, 'Downtime'), 
 	  	                Subcategory = NULL,
 	  	                StartTime = Case When d.Start_Time < @StartTime Then @StartTime Else d.Start_Time End,
 	  	                EndTime = coalesce(d.End_Time, @EndTime),
 	  	                ShortLabel = coalesce('(' + tef.tefault_name + ')', coalesce(r1.event_reason_name, @Unspecified)),
 	  	                LongLabel = coalesce(r1.event_reason_name, @Unspecified)  + coalesce(',' + r2.event_reason_name,'') + coalesce(' (' + tef.tefault_name + ')',''),
 	  	                Color = Case when d.reason_level1 Is Null Then (Select Color From Colors Where Color_Id = 3) Else (Select Color From Colors Where Color_Id = 1) End,
 	  	                HoverText = NULL,
 	  	  	  	  	          Hyperlink = 'DowntimeDetail.aspx?Id=' + convert(nvarchar(20),d.tedet_Id) + '&TargetTimeZone=' + @InTimeZone,
 	  	                SortKey = @SortKey
 	  	  	  	  	  	   From Timed_Event_Details d
 	  	           Left Outer Join Event_Reasons r1 on r1.event_reason_id = d.reason_level1
 	  	           Left Outer Join Event_Reasons r2 on r2.event_reason_id = d.reason_level2
 	  	           Left Outer Join Timed_Event_Fault tef on tef.tefault_id = d.tefault_id
 	  	           Where d.PU_id = @Unit and
 	  	                 d.Start_Time > @StartTime and 
 	  	  	      	  	  	     d.Start_Time <= @EndTime 
 	  	        Order by StartTime 
        --*******************************************************************  
      End
    Else If @@EventType = 3 
      Begin
        --*******************************************************************  
        -- Waste
        --*******************************************************************  
        --TODO Join In Production Rate Specification To Estimate Start Time 
        Insert Into #Events (Category, Subcategory, StartTime, EndTime, ShortLabel, LongLabel, Color, HoverText, Hyperlink, SortKey)
 	  	    	   Select Category = dbo.fnTranslate(@LangId, 34779, 'Waste'), 
 	  	              Subcategory = NULL,
 	  	              StartTime = d.Timestamp,
 	  	              EndTime = d.Timestamp,
 	  	              ShortLabel = coalesce('(' + wef.wefault_name + ')', coalesce(r1.event_reason_name, @Unspecified)),
 	  	              LongLabel = coalesce(r1.event_reason_name, @Unspecified)  + coalesce(',' + r2.event_reason_name,'') + coalesce(' (' + wef.wefault_name + ')',''),
 	  	              Color = Case when d.reason_level1 Is Null Then (Select Color From Colors Where Color_Id = 3) Else (Select Color From Colors Where Color_Id = 1) End,
 	  	              HoverText = NULL,
 	  	  	  	          Hyperlink = 'WasteDetail.aspx?Id=' + convert(nvarchar(20),d.wed_Id) + '&TargetTimeZone=' + @InTimeZone,
 	                SortKey = @SortKey
 	  	  	  	  	   From Waste_Event_Details d
 	  	         Left Outer Join Event_Reasons r1 on r1.event_reason_id = d.reason_level1
 	  	         Left Outer Join Event_Reasons r2 on r2.event_reason_id = d.reason_level2
 	  	         Left Outer Join Waste_Event_Fault wef on wef.wefault_id = d.wefault_id
 	  	  	  	  	   Where d.PU_id = @Unit and
 	  	  	    	  	       d.Timestamp > @StartTime and 
 	  	               d.Timestamp <= @EndTime and
 	  	               d.Event_Id Is Null
 	  	  	  	 Union
 	  	    	   Select Category = dbo.fnTranslate(@LangId, 34779, 'Waste'), 
 	  	              Subcategory = NULL,
 	  	              StartTime = e.Timestamp,
 	  	              EndTime = e.Timestamp,
 	  	              ShortLabel = coalesce('(' + wef.wefault_name + ')', coalesce(r1.event_reason_name, @Unspecified)),
 	  	              LongLabel = coalesce(r1.event_reason_name, @Unspecified)  + coalesce(',' + r2.event_reason_name,'') + coalesce(' (' + wef.wefault_name + ')',''),
 	  	              Color = Case when d.reason_level1 Is Null Then (Select Color From Colors Where Color_Id = 3) Else (Select Color From Colors Where Color_Id = 1) End,
 	  	              HoverText = NULL,
 	  	  	  	          Hyperlink = 'WasteDetail.aspx?Id=' + convert(nvarchar(20),d.wed_Id) + '&TargetTimeZone=' + @InTimeZone,
 	                SortKey = @SortKey
 	  	  	  	  	 From Events e
 	  	  	    	  	 Join Waste_Event_Details d on d.event_id = e.event_id
 	  	         Left Outer Join Event_Reasons r1 on r1.event_reason_id = d.reason_level1
 	  	         Left Outer Join Event_Reasons r2 on r2.event_reason_id = d.reason_level2
 	  	         Left Outer Join Waste_Event_Fault wef on wef.wefault_id = d.wefault_id
 	  	         Where e.PU_id = @Unit and
 	  	  	  	  	         e.Timestamp > @StartTime and 
 	  	  	  	  	         e.Timestamp <= @EndTime 
 	  	     Order by StartTime 
        --*******************************************************************  
      End
    Else If @@EventType = 4   	 
      Begin
        --*******************************************************************  
        -- Product Change
        --*******************************************************************  
        Insert Into #Events (Category, Subcategory, StartTime, EndTime, ShortLabel, LongLabel, Color, HoverText, Hyperlink, SortKey)
 	  	    	   Select Category = dbo.fnTranslate(@LangId, 34017, 'Product'), 
 	  	              Subcategory = NULL,
 	  	              StartTime = Case When d.Start_Time < @StartTime Then @StartTime Else d.Start_Time End,
 	  	              EndTime = coalesce(d.End_Time, @EndTime),
 	  	              ShortLabel = p.Prod_code,
 	  	              LongLabel = p.prod_code + ' - ' + p.prod_desc,
 	  	              Color = (Select Color From Colors Where Color_Id = 1),
 	  	              HoverText = convert(nvarchar(1000),c.Comment_Text),
 	  	  	  	          Hyperlink = NULL,
 	                SortKey = @SortKey
 	  	  	  	  	   From Production_Starts d
 	  	         Join Products p on p.prod_id = d.prod_id
 	  	         Left Outer Join Comments c On c.Comment_id = d.Comment_Id
 	  	  	  	  	   Where d.PU_id = @Unit and
 	  	  	    	  	       d.Start_Time = (Select Max(Start_Time) From Production_Starts t Where t.PU_Id = @Unit and t.start_time <= @StartTime) and
 	  	  	     	       ((d.End_Time > @StartTime) or (d.End_Time is Null))
 	  	  	  	 Union
 	  	    	   Select Category = dbo.fnTranslate(@LangId, 34017, 'Product'), 
 	  	              Subcategory = NULL,
 	  	              StartTime = Case When d.Start_Time < @StartTime Then @StartTime Else d.Start_Time End,
 	  	              EndTime = coalesce(d.End_Time, @EndTime),
 	  	              ShortLabel = p.Prod_code,
 	  	              LongLabel = p.prod_code + ' - ' + p.prod_desc,
 	  	              Color = (Select Color From Colors Where Color_Id = 1),
 	  	              HoverText = convert(nvarchar(1000),c.Comment_Text),
 	  	  	  	          Hyperlink = NULL,
 	                SortKey = @SortKey
 	   	  	   From Production_Starts d
 	  	       Join Products p on p.prod_id = d.prod_id
 	  	       Left Outer Join Comments c On c.Comment_id = d.Comment_Id
 	  	       Where d.PU_id = @Unit and
 	  	             d.Start_Time > @StartTime and 
 	  	  	          	 d.Start_Time <= @EndTime 
 	  	    Order by StartTime 
        --*******************************************************************  
      End
    Else If @@EventType = 11 
      Begin
        --*******************************************************************  
        -- Alarms
        --*******************************************************************  
        -- Get The Next Variable In The List  
        Fetch Next From Variable_Cursor Into @@VariableId
        If @@Fetch_Status = 0
          Begin
            Select @VariableName = Var_Desc From Variables Where Var_id = @@VariableId
 	  	         Insert Into #Events (Category, Subcategory, StartTime, EndTime, ShortLabel, LongLabel, Color, HoverText, Hyperlink, SortKey)
 	    	  	    	   Select Category = @VariableName, 
 	                  Subcategory = NULL,
 	                  StartTime = Case When d.Start_Time < @StartTime Then @StartTime Else d.Start_Time End,
 	                  EndTime = coalesce(d.End_Time, @EndTime),
 	                  ShortLabel = coalesce(r1.event_reason_name, @Unspecified),
 	                  LongLabel = d.alarm_desc,
 	                  Color = Case when d.ack Is Null or d.ack = 0 Then (Select Color From Colors Where Color_Id = 3) Else (Select Color From Colors Where Color_Id = 1) End,
 	                  HoverText = convert(nvarchar(1000),c.Comment_Text),
 	  	  	  	  	          Hyperlink = 'AlarmDetail.aspx?Id=' + convert(nvarchar(20),d.Alarm_Id) + '&TargetTimeZone=' + @InTimeZone,
 	  	                SortKey = @SortKey
 	  	  	  	  	  	   From Alarms d
 	  	           Left Outer Join Event_Reasons r1 on r1.event_reason_id = d.cause1
              Left Outer Join Comments c On c.Comment_id = d.Cause_Comment_Id
 	  	  	  	  	  	   Where d.Key_Id = @@VariableId and
                    d.Alarm_Type_Id in (1,2) and 
 	  	  	    	  	         d.Start_Time = (Select Max(Start_Time) From Alarms t Where t.Key_Id = @@VariableId and t.Alarm_Type_Id in (1,2) and t.start_time < @StartTime) and
 	  	  	  	   	         ((d.End_Time > @StartTime) or (d.End_Time is Null))
 	          Union
 	    	  	    	   Select Category = @VariableName, 
 	                  Subcategory = NULL,
 	                  StartTime = Case When d.Start_Time < @StartTime Then @StartTime Else d.Start_Time End,
 	                  EndTime = coalesce(d.End_Time, @EndTime),
 	                  ShortLabel = coalesce(r1.event_reason_name, @Unspecified),
 	                  LongLabel = d.alarm_desc,
 	                  Color = Case when d.ack Is Null or d.ack = 0 Then (Select Color From Colors Where Color_Id = 3) Else (Select Color From Colors Where Color_Id = 1) End,
 	                  HoverText = convert(nvarchar(1000),c.Comment_Text),
 	  	  	  	  	          Hyperlink = 'AlarmDetail.aspx?Id=' + convert(nvarchar(20),d.Alarm_Id) + '&TargetTimeZone=' + @InTimeZone,
 	  	                SortKey = @SortKey
 	  	  	  	  	  	   From Alarms d
 	  	           Left Outer Join Event_Reasons r1 on r1.event_reason_id = d.cause1
              Left Outer Join Comments c On c.Comment_id = d.Cause_Comment_Id
 	  	  	  	  	  	   Where d.Key_Id = @@VariableId and
                    d.Alarm_Type_Id in (1,2) and 
 	  	  	               d.Start_Time > @StartTime and 
 	  	  	  	          	  	 d.Start_Time <= @EndTime 
 	  	  	      Order by StartTime 
          End
        --*******************************************************************  
      End
    Else If @@EventType = 14 
      Begin
        --*******************************************************************  
        -- User Defined Events
        --*******************************************************************  
        -- Get The Next UDE In The List  
        Fetch Next From SubType_Cursor Into @@EventSubtypeId
        If @@Fetch_Status = 0
          Begin
  	  	  	  	  	  	 Select @UDEName = event_subtype_desc, @UDEType = duration_required From Event_Subtypes Where event_subtype_id = @@EventSubtypeId
 	  	  	  	  	  	 If @UDEType = 1 
             	 Begin
                -- Both Start and End Times Apply
 	  	  	  	         Insert Into #Events (Category, Subcategory, StartTime, EndTime, ShortLabel, LongLabel, Color, HoverText, Hyperlink, SortKey)
 	  	  	    	  	    	   Select Category = @UDEName, 
 	  	  	                  Subcategory = NULL,
 	  	  	                  StartTime = Case When d.Start_Time < @StartTime Then @StartTime Else d.Start_Time End,
 	  	  	                  EndTime = coalesce(d.End_Time, @EndTime),
 	  	  	                  ShortLabel = coalesce(r1.event_reason_name, @Unspecified),
 	  	  	                  LongLabel = d.ude_desc,
 	  	  	                  Color = Case when d.cause1 Is Null or d.ack = 0 Then (Select Color From Colors Where Color_Id = 3) Else (Select Color From Colors Where Color_Id = 1) End,
 	  	  	                  HoverText = convert(nvarchar(1000),c.Comment_Text),
 	  	  	  	  	  	  	          Hyperlink = 'UserDefinedEventDetail.aspx?Id=' + convert(nvarchar(20),d.UDE_Id)+ '&TargetTimeZone=' + @InTimeZone,
 	  	  	  	                SortKey = @SortKey
 	  	  	  	  	  	  	  	   From User_Defined_Events d
 	  	  	  	           Left Outer Join Event_Reasons r1 on r1.event_reason_id = d.cause1
 	  	  	  	           Left Outer Join Event_Reasons r2 on r1.event_reason_id = d.cause2
 	  	               Left Outer Join Comments c On c.Comment_id = d.Comment_Id
 	  	  	  	  	  	  	  	   Where d.PU_Id = @Unit and
                        d.Event_Subtype_id = @@EventSubtypeId and
 	  	  	  	  	    	  	         d.Start_Time = (Select Max(Start_Time) From User_Defined_Events t Where t.PU_Id = @Unit and t.Event_Subtype_id = @@EventSubtypeId and t.start_time <= @StartTime) and
 	  	  	  	  	  	   	         ((d.End_Time > @StartTime) or (d.End_Time is Null))
 	  	  	          Union
 	  	  	    	  	    	   Select Category = @UDEName, 
 	  	  	                  Subcategory = NULL,
 	  	  	                  StartTime = Case When d.Start_Time < @StartTime Then @StartTime Else d.Start_Time End,
 	  	  	                  EndTime = coalesce(d.End_Time, @EndTime),
 	  	  	                  ShortLabel = coalesce(r1.event_reason_name, @Unspecified),
 	  	  	                  LongLabel = d.ude_desc,
 	  	  	                  Color = Case when d.cause1 Is Null or d.ack = 0 Then (Select Color From Colors Where Color_Id = 3) Else (Select Color From Colors Where Color_Id = 1) End,
 	  	  	                  HoverText = convert(nvarchar(1000),c.Comment_Text),
 	  	  	  	  	  	  	          Hyperlink = 'UserDefinedEventDetail.aspx?Id=' + convert(nvarchar(20),d.UDE_Id) + '&TargetTimeZone=' + @InTimeZone,
 	  	  	  	                SortKey = @SortKey
 	  	  	  	  	  	  	  	   From User_Defined_Events d
 	  	  	  	           Left Outer Join Event_Reasons r1 on r1.event_reason_id = d.cause1
 	  	  	  	           Left Outer Join Event_Reasons r2 on r1.event_reason_id = d.cause2
 	  	               Left Outer Join Comments c On c.Comment_id = d.Cause_Comment_Id
 	  	  	  	  	  	  	  	   Where d.PU_Id = @Unit and
                        d.Event_Subtype_id = @@EventSubtypeId and
 	  	  	  	  	               d.Start_Time > @StartTime and 
 	  	  	  	  	  	          	  	 d.Start_Time <= @EndTime 
 	  	  	  	  	      Order by StartTime 
 	  	  	  	  	  	  	 End
 	  	  	  	  	  	 Else
 	  	  	  	  	  	  	 Begin
                -- Only Start Time Applies
 	  	  	  	         Insert Into #Events (Category, Subcategory, StartTime, EndTime, ShortLabel, LongLabel, Color, HoverText, Hyperlink, SortKey)
 	  	  	    	  	    	   Select Category = @UDEName, 
 	  	  	                  Subcategory = NULL,
 	  	  	                  StartTime = d.Start_time,
 	  	  	                  EndTime = d.Start_Time,
 	  	  	                  ShortLabel = coalesce(r1.event_reason_name, @Unspecified),
 	  	  	                  LongLabel = d.ude_desc,
 	  	  	                  Color = Case when d.cause1 Is Null or d.ack = 0 Then (Select Color From Colors Where Color_Id = 3) Else (Select Color From Colors Where Color_Id = 1) End,
 	  	  	                  HoverText = convert(nvarchar(1000),c.Comment_Text),
 	  	  	  	  	  	  	          Hyperlink = 'UserDefinedEventDetail.aspx?Id=' + convert(nvarchar(20),d.UDE_Id) + '&TargetTimeZone=' + @InTimeZone,
 	  	  	  	                SortKey = @SortKey
 	  	  	  	  	  	  	  	   From User_Defined_Events d
 	  	  	  	           Left Outer Join Event_Reasons r1 on r1.event_reason_id = d.cause1
 	  	  	  	           Left Outer Join Event_Reasons r2 on r1.event_reason_id = d.cause2
 	  	               Left Outer Join Comments c On c.Comment_id = d.Cause_Comment_Id
 	  	  	  	  	  	  	  	   Where d.PU_Id = @Unit and
 	                       d.Event_Subtype_id = @@EventSubtypeId and
 	  	  	  	  	               d.Start_Time > @StartTime and 
 	  	  	  	  	  	          	  	 d.Start_Time <= @EndTime 
 	  	  	  	  	         Order by StartTime 
 	  	  	  	  	  	  	 End
          End
        --*******************************************************************  
      End
    Else If @@EventType = 19 
      Begin
        --*******************************************************************  
        -- Process Orders
        --*******************************************************************  
        -- TODO: Join In Status Color
        Insert Into #Events (Category, Subcategory, StartTime, EndTime, ShortLabel, LongLabel, Color, HoverText, Hyperlink, SortKey)
 	  	    	   Select Category = dbo.fnTranslate(@LangId, 34773, 'Process Orders'), 
 	  	              Subcategory = NULL,
 	  	              StartTime = Case When d.Start_Time < @StartTime Then @StartTime Else d.Start_Time End,
 	  	              EndTime = coalesce(d.End_Time, @EndTime),
 	  	              ShortLabel = pp.Process_Order,
 	  	              LongLabel = pp.Process_Order + ' (' +  s.pp_status_desc + ')' + ' - ' + p.prod_code,
 	  	              Color = (Select Color From Colors Where Color_Id = 1),
 	  	              HoverText = convert(nvarchar(1000),c.Comment_Text),
 	  	  	  	          Hyperlink = 'ProcessOrderDetail.aspx?Id=' + convert(nvarchar(20),pp.pp_Id) + '&TargetTimeZone=' + @InTimeZone,
 	                SortKey = @SortKey
 	  	  	  	  	   From Production_Plan_Starts d
 	           Join Production_Plan pp on pp.pp_id = d.pp_id
 	           Join production_plan_statuses s on s.pp_status_id = pp.pp_status_id
 	  	         Join Products p on p.prod_id = pp.prod_id
 	  	         Left Outer Join Comments c On c.Comment_id = d.Comment_Id
 	  	  	  	  	   Where d.PU_id = @Unit and
 	  	  	    	  	       d.Start_Time = (Select Max(Start_Time) From Production_Plan_Starts t Where t.PU_Id = @Unit and t.start_time <= @StartTime) and
 	  	  	     	       ((d.End_Time > @StartTime) or (d.End_Time is Null))
 	  	  	  	 Union
 	  	    	   Select Category = dbo.fnTranslate(@LangId, 34773, 'Process Orders'), 
 	  	              Subcategory = NULL,
 	  	              StartTime = Case When d.Start_Time < @StartTime Then @StartTime Else d.Start_Time End,
 	  	              EndTime = coalesce(d.End_Time, @EndTime),
 	  	              ShortLabel = pp.Process_Order,
 	  	              LongLabel = pp.Process_Order + ' (' +  s.pp_status_desc + ')' + ' - ' + p.prod_code,
 	  	              Color = (Select Color From Colors Where Color_Id = 1),
 	  	              HoverText = convert(nvarchar(1000),c.Comment_Text),
 	  	  	  	          Hyperlink = 'ProcessOrderDetail.aspx?Id=' + convert(nvarchar(20),pp.pp_Id) + '&TargetTimeZone=' + @InTimeZone,
 	                SortKey = @SortKey
 	  	  	  	  	   From Production_Plan_Starts d
 	           Join Production_Plan pp on pp.pp_id = d.pp_id
 	           Join production_plan_statuses s on s.pp_status_id = pp.pp_status_id
 	  	         Join Products p on p.prod_id = pp.prod_id
 	  	         Left Outer Join Comments c On c.Comment_id = d.Comment_Id
 	  	  	       Where d.PU_id = @Unit and
 	  	  	             d.Start_Time > @StartTime and 
 	  	  	  	          	 d.Start_Time <= @EndTime 
 	  	  	    Order by StartTime 
        --*******************************************************************  
      End
    Else If @@EventType = 0   	 -- Time / Crew Schedule
      Begin
        --*******************************************************************  
        -- Crew Schedule
        --*******************************************************************  
        Insert Into #Events (Category, Subcategory, StartTime, EndTime, ShortLabel, LongLabel, Color, HoverText, Hyperlink, SortKey)
 	  	    	   Select Category = dbo.fnTranslate(@LangId, 34774, 'Crew'), 
 	  	              Subcategory = NULL,
 	  	              StartTime = Case When d.Start_Time < @StartTime Then @StartTime Else d.Start_Time End,
 	  	              EndTime = coalesce(d.End_Time, @EndTime),
 	  	              ShortLabel = d.crew_desc,
 	  	              LongLabel = d.crew_desc + ' - ' + d.shift_desc,
 	  	              Color = (Select Color From Colors Where Color_Id = 1),
 	  	              HoverText = convert(nvarchar(1000),c.Comment_Text),
 	  	  	  	          Hyperlink = NULL,
                 SortKey = @SortKey
 	  	  	  	  	   From crew_schedule d
 	  	         Left Outer Join Comments c On c.Comment_id = d.Comment_Id
 	  	  	  	  	   Where d.PU_id = @Unit and
 	  	  	    	  	       d.Start_Time = (Select Max(Start_Time) From crew_schedule t Where t.PU_Id = @Unit and t.start_time <= @StartTime) and
 	  	  	     	       ((d.End_Time > @StartTime) or (d.End_Time is Null))
 	  	  	  	 Union
 	  	    	   Select Category = dbo.fnTranslate(@LangId, 34774, 'Crew'), 
 	  	              Subcategory = NULL,
 	  	              StartTime = Case When d.Start_Time < @StartTime Then @StartTime Else d.Start_Time End,
 	  	              EndTime = coalesce(d.End_Time, @EndTime),
 	  	              ShortLabel = d.crew_desc,
 	  	              LongLabel = d.crew_desc + ' - ' + d.shift_desc,
 	  	              Color = (Select Color From Colors Where Color_Id = 1),
 	  	              HoverText = convert(nvarchar(1000),c.Comment_Text),
 	  	  	  	          Hyperlink = NULL,
                 SortKey = @SortKey
 	  	  	  	  	   From crew_schedule d
 	  	         Left Outer Join Comments c On c.Comment_id = d.Comment_Id
 	  	  	       Where d.PU_id = @Unit and
 	  	  	             d.Start_Time > @StartTime and 
 	  	  	  	          	 d.Start_Time <= @EndTime 
 	  	  	    Order by StartTime 
        --*******************************************************************  
      End
    Fetch Next From Event_Cursor Into @@EventType
  End
-- Return Report
Select Category, Subcategory,
 'StartTime'=   [dbo].[fnServer_CmnConvertFromDbTime] (StartTime,@InTimeZone)  , 
 'EndTime'=  [dbo].[fnServer_CmnConvertFromDbTime] (EndTime,@InTimeZone)  ,
 ShortLabel, LongLabel, LongLabel_Parameter, Color, Hovertext, Hyperlink
  From #Events
  Order by SortKey, StartTime ASC 
Close Event_Cursor
Close SubType_Cursor
Close Variable_Cursor
Deallocate Event_Cursor  
Deallocate SubType_Cursor
Deallocate Variable_Cursor
Drop Table #AvailableEventTypes
Drop Table #Events
Drop Table #EventTypes
Drop Table #EventSubtypes
Drop Table #Variables
