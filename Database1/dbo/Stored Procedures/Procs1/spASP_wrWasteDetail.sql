﻿CREATE PROCEDURE [dbo].[spASP_wrWasteDetail]
@EventId int,
@Command int = NULL,
@InTimeZone nvarchar(200)=NULL
AS
--TODO: Deal With Chained Comments
--TODO: Display Categories
set arithignore on
set arithabort off
set ansi_warnings off
/*********************************************
-- For Testing
--*********************************************
Select @EventId = 200 --2572 --327
Select @Command =  NULL --3
--**********************************************/
Declare @SpecificationSetting int  -- For Specification Comparisons
Select @SpecificationSetting = convert(int,value) From Site_Parameters Where Parm_id = 13
If @SpecificationSetting is Null Select @SpecificationSetting = 1
Declare @ReportName nvarchar(255)
Declare @CriteriaString nVarChar(1000)
Declare @Unit int
Declare @UnitName nVarChar(100)
Declare @StartTime datetime
Declare @ProductId int
Declare @Type nvarchar(25)
Declare @Amount real
Declare @EnteredIn nvarchar(25)
Declare @Uptime real
Declare @LocationId int
Declare @Location nVarChar(100)
Declare @Fault nVarChar(100)
Declare @Cause1 nVarChar(100)
Declare @Cause2 nVarChar(100)
Declare @Cause3 nVarChar(100)
Declare @Cause4 nVarChar(100)
Declare @CauseCommentId int
Declare @Action1 nVarChar(100)
Declare @Action2 nVarChar(100)
Declare @Action3 nVarChar(100)
Declare @Action4 nVarChar(100)
Declare @ActionCommentId int
Declare @ResearchStatus nvarchar(25)
Declare @ResearchOpen datetime
Declare @ResearchClosed datetime
Declare @ResearchUser nVarChar(100)
Declare @ResearchCommentId int
Declare @UpdatedBy nVarChar(100)
Declare @NumberOfUpdates int
Declare @UpdatedTime datetime
Declare @ProductCode nVarChar(50)
Declare @ProductionEventName nVarChar(50)
Declare @ProductionEventId int
Declare @ProductionEventStart datetime
Declare @ProductionEventEnd datetime
Declare @ProductionEventNumber nVarChar(50)
Declare @ProductionEventStatus nvarchar(25)
Declare @ProductionEventStatusColor int
Declare @DimensionXUnits nvarchar(25)
Declare @TreeId int
Declare @Level1Name nvarchar(25)
Declare @Level2Name nvarchar(25)
Declare @Level3Name nvarchar(25)
Declare @Level4Name nvarchar(25)
Declare @LastTime datetime
Declare @TrendStart datetime
Declare @TrendEnd datetime
--**********************************************
-- Translations Setup & Common Prompt Lookup
--**********************************************
-- Retreive the Language Id of the current user
Declare @LangId INT
EXEC spWA_GetCurrentUserInfo @LangId = @LangId OUTPUT
-- Get Common Prompts
DECLARE @sUnspecified nVarChar(100)
SET @sUnspecified = dbo.fnTranslate(@LangId, 34519, '*Unspecified*')
--**********************************************
--**********************************************
-- Loookup Initial Information For This Event
--**********************************************
If @EventId Is Null
  Begin
    Raiserror('SP: A Base EventId Must Be Supplied',16,1)
    Return
  End
If @Command Is Not Null
  Begin
 	  	 Select @Unit = PU_Id, @StartTime = Timestamp
 	  	   From Waste_Event_Details 
 	  	   Where WED_Id = @EventId 
   	 Select @EventId = NULL
  End
If @Command = 1
  Begin
    -- Scroll Next Event
    Select @EventId = WED_Id 
      From Waste_Event_Details 
      Where PU_Id = @Unit and 
            Timestamp = (Select Min(Timestamp) From Waste_Event_Details Where PU_Id = @Unit and Timestamp > @StartTime)
  End
Else If @Command = 2
  Begin
    -- Scroll Previous Event
    Select @EventId = WED_Id 
      From Waste_Event_Details 
      Where PU_Id = @Unit and
            Timestamp = (Select Max(timestamp) From Waste_Event_Details Where PU_Id = @Unit and Timestamp < @StartTime)
  End
--Else This is Just A Straight Query
If @EventId Is Null
  Begin
    Raiserror('SP: Command Did Not Find Event To Return',16,1)
    Return
  End
-- Get Event Information
Select @Unit = d.PU_Id, @StartTime = Timestamp,
       @ProductionEventId = d.Event_Id, 
       @Type = t.WET_Name,
       @Amount = d.Amount,
       @EnteredIn = m.WEMT_Name,
 	  	  	  @LocationId = d.source_pu_id, 
 	  	  	  @Location = case When pu.PU_Desc Is Null Then @sUnspecified Else pu.PU_Desc End, 
 	  	  	  @Fault = case When wef.wEFault_Name Is Null Then @sUnspecified Else wef.wEFault_Name End,
       @Cause1 = coalesce(r1.event_reason_name, @sUnspecified),
       @Cause2 = r2.event_reason_name,
       @Cause3 = r3.event_reason_name,
       @Cause4 = r3.event_reason_name,
       @CauseCommentId = d.Cause_Comment_Id,
       @Action1 = coalesce(a1.event_reason_name, @sUnspecified),
       @Action2 = a2.event_reason_name,
       @Action3 = a3.event_reason_name,
       @Action4 = a4.event_reason_name,
       @ActionCommentId = d.Cause_Comment_Id,
       @ResearchStatus = rs.research_status_desc,
       @ResearchOpen = d.Research_Open_Date,
       @ResearchClosed = d.Research_Close_Date,
       @ResearchUser = u1.Username,
       @ResearchCommentId = d.Research_Comment_Id,
       @UpdatedBy = u2.Username
  From Waste_Event_Details d
  Left Outer Join Event_Reasons r1 on r1.event_reason_id = d.reason_level1
  Left Outer Join Event_Reasons r2 on r2.event_reason_id = d.reason_level2
  Left Outer Join Event_Reasons r3 on r3.event_reason_id = d.reason_level3
  Left Outer Join Event_Reasons r4 on r4.event_reason_id = d.reason_level4
  Left Outer Join Event_Reasons a1 on a1.event_reason_id = d.action_level1
  Left Outer Join Event_Reasons a2 on a1.event_reason_id = d.action_level2
  Left Outer Join Event_Reasons a3 on a1.event_reason_id = d.action_level3
  Left Outer Join Event_Reasons a4 on a1.event_reason_id = d.action_level4
  Left Outer Join Waste_Event_Fault wef on wef.wefault_id = d.wefault_id
  Left Outer Join Prod_Units pu on pu.pu_id = d.source_pu_id
  Left outer Join Users u1 on u1.user_id = d.research_user_id
  Left outer Join Users u2 on u2.user_id = d.user_id
  left outer join research_status rs on rs.research_status_Id = d.research_status_id
  Left outer join waste_event_type t on t.wet_id = d.wet_id
  Left outer join waste_event_meas m on m.wemt_id = d.wemt_id
  Where d.WED_id = @EventId
Select @UnitName = PU_Desc
 From Prod_Units 
 Where PU_Id = @Unit
Select @ReportName = dbo.fnTranslate(@LangId, 34887, 'Waste Detail')
Select @TrendStart = dateadd(minute, -100, @StartTime)
Select @TrendEnd = dateadd(minute, 100, @StartTime)
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
  PromptValue_Parameter SQL_Variant
)
Insert into #Prompts (PromptName, PromptValue) Values ('ReportName', @ReportName)
Insert into #Prompts (PromptName, PromptValue, PromptValue_Parameter) Values ('Criteria', dbo.fnTranslate(@LangId, 34665, 'On {0}'), @UnitName)
Insert into #Prompts (PromptName, PromptValue, PromptValue_Parameter) Values ('GenerateTime', dbo.fnTranslate(@LangId, 34521, 'Created: {0}'), [dbo].[fnServer_CmnConvertFromDbTime](dbo.fnServer_CmnGetDate(getutcdate()),@InTimeZone))
Insert into #Prompts (PromptName, PromptValue) Values ('EventInformation', dbo.fnTranslate(@LangId, 34600, 'Event Information'))
Insert into #Prompts (PromptName, PromptValue) Values ('ElectronicSignature', dbo.fnTranslate(@LangId, 34695, 'Electronic Signature'))
Insert into #Prompts (PromptName, PromptValue) Values ('CauseInformation', dbo.fnTranslate(@LangId, 34601, 'Cause Information'))
Insert into #Prompts (PromptName, PromptValue) Values ('CauseComments', dbo.fnTranslate(@LangId, 34602, 'Cause Comments'))
Insert into #Prompts (PromptName, PromptValue) Values ('ActionInformation', dbo.fnTranslate(@LangId, 34603, 'Action Information'))
Insert into #Prompts (PromptName, PromptValue) Values ('ActionComments', dbo.fnTranslate(@LangId, 34604, 'Action Comments'))
Insert into #Prompts (PromptName, PromptValue) Values ('ResearchInformation', dbo.fnTranslate(@LangId, 34606, 'NCR Research'))
Insert into #Prompts (PromptName, PromptValue) Values ('ResearchComments', dbo.fnTranslate(@LangId, 34607, 'Research Comments'))
Insert into #Prompts (PromptName, PromptValue) Values ('ParameterSummary', dbo.fnTranslate(@LangId, 34888, 'Parameter Summary'))
Insert into #Prompts (PromptName, PromptValue) Values ('Variable', dbo.fnTranslate(@LangId, 34894, 'Variable'))
Insert into #Prompts (PromptName, PromptValue) Values ('LRL', dbo.fnTranslate(@LangId, 34667, 'Lower Reject'))
Insert into #Prompts (PromptName, PromptValue) Values ('LWL', dbo.fnTranslate(@LangId, 34668, 'Lower Warning'))
Insert into #Prompts (PromptName, PromptValue) Values ('TGT', dbo.fnTranslate(@LangId, 34669, 'Target'))
Insert into #Prompts (PromptName, PromptValue) Values ('UWL', dbo.fnTranslate(@LangId, 34670, 'Upper Warning'))
Insert into #Prompts (PromptName, PromptValue) Values ('URL', dbo.fnTranslate(@LangId, 34671, 'Upper Reject'))
Insert into #Prompts (PromptName, PromptValue) Values ('Value', dbo.fnTranslate(@LangId, 34672, 'Value'))
Insert into #Prompts (PromptName, PromptValue) Values ('EnteredOn', dbo.fnTranslate(@LangId, 34673, 'Entered On'))
Insert into #Prompts (PromptName, PromptValue) Values ('EnteredBy', dbo.fnTranslate(@LangId, 34674, 'Entered By'))
Insert into #Prompts (PromptName, PromptValue) Values ('GotoPrevious', dbo.fnTranslate(@LangId, 34675, 'Goto Previous Event'))
Insert into #Prompts (PromptName, PromptValue) Values ('GotoNext', dbo.fnTranslate(@LangId, 34676, 'Goto Next Event'))
Insert into #Prompts (PromptName, PromptValue) Values ('ViewAudit', dbo.fnTranslate(@LangId, 34677, 'View Audit Trail'))
Insert into #Prompts (PromptName, PromptValue) Values ('ViewTimeline', dbo.fnTranslate(@LangId, 34678, 'View Timeline'))
Insert into #Prompts (PromptName, PromptValue) Values ('TrendLong', dbo.fnTranslate(@LangId, 34612, 'Trend Long Term'))
Insert into #Prompts (PromptName, PromptValue) Values ('TrendShort', dbo.fnTranslate(@LangId, 34613, 'Trend Short Term'))
Insert into #Prompts (PromptName, PromptValue, PromptValue_Parameter) Values ('EventId', '{0}', @EventId)
Insert into #Prompts (PromptName, PromptValue, PromptValue_Parameter) Values ('StartTime', '{0}', [dbo].[fnServer_CmnConvertFromDbTime] (@StartTime,@InTimeZone))
Insert into #Prompts (PromptName, PromptValue, PromptValue_Parameter) Values ('EndTime', '{0}', [dbo].[fnServer_CmnConvertFromDbTime] (@StartTime,@InTimeZone))
Insert into #Prompts (PromptName, PromptValue, PromptValue_Parameter) Values ('TrendStart', '{0}',[dbo].[fnServer_CmnConvertFromDbTime] (@TrendStart,@InTimeZone) )
Insert into #Prompts (PromptName, PromptValue, PromptValue_Parameter) Values ('TrendEnd', '{0}', [dbo].[fnServer_CmnConvertFromDbTime] (@TrendEnd,@InTimeZone))
Insert into #Prompts (PromptName, PromptValue) Values ('UnitId', convert(nvarchar(30), @Unit))
--select PromptId,PromptName,PromptValue,'PromptValue_Parameter'= case when (ISDATE(Convert(varchar,PromptValue_Parameter))=1)
-- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 then
-- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 [dbo].[fnServer_CmnConvertFromDbTime] (convert(datetime,PromptValue_Parameter),@InTimeZone)
-- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 else
-- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 PromptValue_Parameter
-- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 end 
SELECT * From #Prompts
Drop Table #Prompts
--**********************************************
-- Return Data For Report
--**********************************************
-- Get Product
Select @ProductId = Prod_Id 
  From Production_Starts 
  Where PU_Id = @Unit and 
          Start_Time <= @StartTime and
          ((End_Time > @StartTime) or (End_Time Is Null)) 
Select @ProductCode = Prod_Code From Products Where Prod_Id = @ProductId 
-- Check History
Select @UpdatedTime = max(modified_on), 
       @NumberOfUpdates = count(modified_on) - 1 
  From Waste_event_detail_history 
  where WED_Id = @EventId
-- Get Production Event and Event Information
If @ProductionEventId Is Not Null
 	 Select @ProductionEventNumber = e.Event_Num,
 	        @ProductionEventStatus = ps.ProdStatus_Desc
 	   From Events e
 	   join production_status ps on ps.prodstatus_id = e.event_status
 	   Where e.Event_id = @ProductionEventId
If @ProductionEventNumber Is Not Null
 	 Select @ProductionEventName = s.event_subtype_desc,
         @DimensionXUnits = s.Dimension_X_Eng_Units
 	   from event_configuration e 
 	   join event_subtypes s on s.Event_Subtype_Id = e.Event_Subtype_Id
 	   where e.pu_id = @Unit and 
 	         e.et_id = 1
-- Get Last Time
Select @LastTime = max(timestamp)
  From Waste_Event_Details 
  Where PU_Id = @Unit and 
        Timestamp < @StartTime
Select @Uptime = datediff(second,@LastTime, @StartTime) / 60.0
-- Create Simple Return Table
Create Table #Report (
  [Id] int identity(1,1),
  [Name] nvarchar(50),
  Value nvarchar(255) NULL,
  Value_Parameter SQL_Variant,
  Value_Parameter2 SQL_Variant,
  Hyperlink nvarchar(255) NULL,
 	 Tag int NULL
)
--********************************************************************************
-- Return Basic Event Information
--********************************************************************************
Truncate Table #Report
Insert Into #Report ([Name], Value, Value_Parameter)
  Values('Timestamp', '{0}',  @StartTime)
If @Type Is Not Null
  Insert Into #Report ([Name], Value) Values (dbo.fnTranslate(@LangId, 34889, 'Type'), @Type)
Insert Into #Report ([Name], Value, Value_Parameter) Values (dbo.fnTranslate(@LangId, 34890, 'Amount'), '{0} ' + case When @DimensionXUnits Is Null Then '' Else @DimensionXUnits End, @Amount)
If @EnteredIn Is Not Null
  Insert Into #Report ([Name], Value) Values (dbo.fnTranslate(@LangId, 34891, 'Entered In'), @EnteredIn)
If @Uptime is Not Null
  Insert Into #Report ([Name], Value, Value_Parameter) Values(dbo.fnTranslate(@LangId, 34857, 'Time From Last Event'), dbo.fnTranslate(@LangId, 34618, '{0} Minutes'),  @Uptime)
Insert Into #Report ([Name], Value) Values (dbo.fnTranslate(@LangId, 34863, 'Product'), @ProductCode)
If @ProductionEventNumber Is Not Null
  Insert Into #Report ([Name], Value, Value_Parameter, Value_Parameter2, Hyperlink)
    Values(@ProductionEventName, '{0} ({1})', @ProductionEventNumber, @ProductionEventStatus, '<Link>EventDetail.aspx?ID=' + convert(nvarchar(15),@ProductionEventId) + '&TargetTimeZone='+ @InTimeZone+'</Link>')
If @NumberOfUpdates > 0 
  Begin
 	   Insert Into #Report ([Name], Value, Value_Parameter, Value_Parameter2)
            Values(dbo.fnTranslate(@LangId, 34623, 'Updated By'), '{0} ({1})', @UpdatedBy, @UpdatedTime)
 	   Insert Into #Report ([Name], Value, Value_Parameter, Hyperlink) Values
            (dbo.fnTranslate(@LangId, 34625, 'Number Of Updates'), '{0}', @NumberOfUpdates ,'<Link>WasteHistory.aspx?ID=' + convert(nvarchar(15),@EventId) + '&TargetTimeZone='+ @InTimeZone+ '</Link>')
  End
Else
  Begin
 	   Insert Into #Report ([Name], Value, Value_Parameter, Value_Parameter2)
            Values(dbo.fnTranslate(@LangId, 34624, 'Added By'), '{0} ({1})', @UpdatedBy, @UpdatedTime)
  End
select [Id],
  [Name],
  [Value],
  'Value_Parameter'= case when (ISDATE(Convert(varchar,Value_Parameter))=1)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 then
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 [dbo].[fnServer_CmnConvertFromDbTime] (convert(datetime,Value_Parameter),@InTimeZone)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 else
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 Value_Parameter
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 end,
'Value_Parameter2'= case when (ISDATE(Convert(varchar,Value_Parameter2))=1)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 then
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 [dbo].[fnServer_CmnConvertFromDbTime] (convert(datetime,Value_Parameter2),@InTimeZone)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 else
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 Value_Parameter2
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 end, Hyperlink,Tag
From  #Report Order By Id
--********************************************************************************
--********************************************************************************
-- Return Cause Information
--********************************************************************************
Truncate Table #Report
Insert Into #Report ([Name], Value) Values (dbo.fnTranslate(@LangId, 34892, 'Location'), @Location)
Insert Into #Report ([Name], Value) Values (dbo.fnTranslate(@LangId, 34893, 'Fault'), @Fault)
If @LocationId Is Not Null
  Begin
 	  	 Select @TreeId = Name_Id
 	  	   From Prod_Events
 	  	   Where PU_Id = @LocationId and
            Event_Type = 3
 	  	 Select @Level1Name = level_name
 	  	   From event_reason_level_headers 
 	  	   Where Tree_Name_id = @TreeId and
 	  	         Reason_Level = 1
 	  	 
 	  	 If @Level1Name Is Not Null 
 	  	  	 Select @Level2Name = level_name
 	  	  	   From event_reason_level_headers 
 	  	  	   Where Tree_Name_id = @TreeId and
 	  	  	         Reason_Level = 2
 	  	 
 	  	 If @Level2Name Is Not Null 
 	  	  	 Select @Level3Name = level_name
 	  	  	   From event_reason_level_headers 
 	  	  	   Where Tree_Name_id = @TreeId and
 	  	  	         Reason_Level = 3
 	  	 
 	  	 If @Level3Name Is Not Null 
 	  	  	 Select @Level4Name = level_name
 	  	  	   From event_reason_level_headers 
 	  	  	   Where Tree_Name_id = @TreeId and
 	  	  	         Reason_Level = 4
 	  	       
 	  	 
 	  	 Insert Into #Report ([Name], Value) Values (@Level1Name, @Cause1)
 	  	 
 	  	 If @Cause2 Is Not Null
 	  	   Insert Into #Report ([Name], Value) Values (@Level2Name, @Cause2)
 	  	 
 	  	 If @Cause3 Is Not Null
 	  	   Insert Into #Report ([Name], Value) Values (@Level3Name, @Cause3)
 	  	 
 	  	 If @Cause4 Is Not Null
 	  	   Insert Into #Report ([Name], Value) Values (@Level4Name, @Cause4)
  End
select [Id],
  [Name],
  [Value],
  'Value_Parameter'= case when (ISDATE(Convert(varchar,Value_Parameter))=1)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 then
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 [dbo].[fnServer_CmnConvertFromDbTime] (convert(datetime,Value_Parameter),@InTimeZone)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 else
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 Value_Parameter
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 end,
'Value_Parameter2'= case when (ISDATE(Convert(varchar,Value_Parameter2))=1)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 then
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 [dbo].[fnServer_CmnConvertFromDbTime] (convert(datetime,Value_Parameter2),@InTimeZone)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 else
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 Value_Parameter2
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 end, Hyperlink,Tag
From  #Report Order By Id
--********************************************************************************
--********************************************************************************
-- Return Cause Comments
--********************************************************************************
--TODO: Return Chained Comments
Select Username = u.Username,
 'Timestamp' =  [dbo].[fnServer_CmnConvertFromDbTime] (c.Modified_On,@InTimeZone),
 Comment = c.Comment_Text
  From Comments c
  Join Users u on u.user_id = c.User_id 
  Where c.Comment_Id = @CauseCommentId
--********************************************************************************
--********************************************************************************
-- Return Action Information
--********************************************************************************
Truncate Table #Report
Select @Level1Name = NULL
Select @Level2Name = NULL
Select @Level3Name = NULL
Select @Level4Name = NULL
Select @TreeId = NULL
Select @TreeId = Action_Tree_Id
  From Prod_Events
  Where PU_Id = @Unit and
        Event_Type = 3
If @TreeId Is Not Null
  Begin
 	  	 Select @Level1Name = level_name
 	  	   From event_reason_level_headers 
 	  	   Where Tree_Name_id = @TreeId and
 	  	         Reason_Level = 1
 	  	 
 	  	 If @Level1Name Is Not Null 
 	  	  	 Select @Level2Name = level_name
 	  	  	   From event_reason_level_headers 
 	  	  	   Where Tree_Name_id = @TreeId and
 	  	  	         Reason_Level = 2
 	  	 
 	  	 If @Level2Name Is Not Null 
 	  	  	 Select @Level3Name = level_name
 	  	  	   From event_reason_level_headers 
 	  	  	   Where Tree_Name_id = @TreeId and
 	  	  	         Reason_Level = 3
 	  	 
 	  	 If @Level3Name Is Not Null 
 	  	  	 Select @Level4Name = level_name
 	  	  	   From event_reason_level_headers 
 	  	  	   Where Tree_Name_id = @TreeId and
 	  	  	         Reason_Level = 4
 	  	 
 	  	 
 	  	 Insert Into #Report ([Name], Value) Values (@Level1Name, @Action1)
 	  	 
 	  	 If @Action2 Is Not Null
 	  	   Insert Into #Report ([Name], Value) Values (@Level2Name, @Action2)
 	  	 
 	  	 If @Action3 Is Not Null
 	  	   Insert Into #Report ([Name], Value) Values (@Level3Name, @Action3)
 	  	 
 	  	 If @Action4 Is Not Null
 	  	   Insert Into #Report ([Name], Value) Values (@Level4Name, @Action4)
 	 End
select [Id],
  [Name],
  [Value],
  'Value_Parameter'= case when (ISDATE(Convert(varchar,Value_Parameter))=1)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 then
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 [dbo].[fnServer_CmnConvertFromDbTime] (convert(datetime,Value_Parameter),@InTimeZone)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 else
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 Value_Parameter
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 end,
'Value_Parameter2'= case when (ISDATE(Convert(varchar,Value_Parameter2))=1)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 then
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 [dbo].[fnServer_CmnConvertFromDbTime] (convert(datetime,Value_Parameter2),@InTimeZone)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 else
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 Value_Parameter2
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 end, Hyperlink,Tag
From  #Report Order By Id
--********************************************************************************
--********************************************************************************
-- Return Action Comments
--********************************************************************************
--TODO: Return Chained Comments
Select Username = u.Username, 
'Timestamp' =  [dbo].[fnServer_CmnConvertFromDbTime] (c.Modified_On,@InTimeZone) ,
 Comment = c.Comment_Text
  From Comments c
  Join Users u on u.user_id = c.User_id 
  Where c.Comment_Id = @ActionCommentId
--********************************************************************************
--********************************************************************************
-- Return Research Information
--********************************************************************************
Truncate Table #Report
If @ResearchOpen Is Not Null
  Begin
 	  	 Insert Into #Report ([Name], Value) Values (dbo.fnTranslate(@LangId, 34634, 'Assigned To'), @ResearchUser)
 	  	 Insert Into #Report ([Name], Value) Values (dbo.fnTranslate(@LangId, 34635, 'Status'), @ResearchStatus)
 	  	 Insert Into #Report ([Name], Value, Value_Parameter) Values (dbo.fnTranslate(@LangId, 34636, 'Opened On'), '{0}', @ResearchOpen)
    If @ResearchClosed Is Not Null
   	  	 Insert Into #Report ([Name], Value, Value_Parameter) Values (dbo.fnTranslate(@LangId, 34637, 'Closed On'), '{0}', @ResearchClosed)
    Else
   	  	 Insert Into #Report ([Name], Value) Values (dbo.fnTranslate(@LangId, 34637, 'Closed On'), dbo.fnTranslate(@LangId, 34616, 'OPEN'))
  End
select [Id],
  [Name],
  [Value],
  'Value_Parameter'= case when (ISDATE(Convert(varchar,Value_Parameter))=1)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 then
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 [dbo].[fnServer_CmnConvertFromDbTime] (convert(datetime,Value_Parameter),@InTimeZone)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 else
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 Value_Parameter
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 end,
'Value_Parameter2'= case when (ISDATE(Convert(varchar,Value_Parameter2))=1)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 then
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 [dbo].[fnServer_CmnConvertFromDbTime] (convert(datetime,Value_Parameter2),@InTimeZone)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 else
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 Value_Parameter2
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 end, Hyperlink,Tag
From  #Report Order By Id
--********************************************************************************
--********************************************************************************
-- Return Research Comments
--********************************************************************************
--TODO: Return Chained Comments
Select Username = u.Username,
 'Timestamp' =  [dbo].[fnServer_CmnConvertFromDbTime] (c.Modified_On,@InTimeZone), 
 Comment = c.Comment_Text
  From Comments c
  Join Users u on u.user_id = c.User_id 
  Where c.Comment_Id = @ResearchCommentId
--********************************************************************************
--********************************************************************************
-- Return Parameter Information
--********************************************************************************
Select GroupOrder = pug.pug_order,
       ItemOrder = v.pug_order,
       IsTitle = 0,
       Unit = case when pu.Master_Unit Is Null then pu.pu_id else pu.Master_Unit End,
       Id = v.var_id,
       Color = Case 
                 When v.Data_Type_Id in (1,2,6,7) and @SpecificationSetting = 1 Then 
 	  	  	  	  	  	  	  	  	  	 Case 
          	  	  	  	  	  	  	 When convert(real, t.result) > convert(real,coalesce(vs.u_reject,t.result)) or convert(real, t.result) < convert(real,coalesce(vs.l_reject,t.result)) Then 2 
          	  	  	  	  	  	  	 When convert(real, t.result) > convert(real,coalesce(vs.u_warning,t.result)) or convert(real, t.result) < convert(real,coalesce(vs.l_warning,t.result)) Then 1 
          	  	  	  	  	  	  	 Else 0 
 	  	  	  	  	  	  	  	  	  	 End
                 When v.Data_Type_Id in (1,2,6,7) and @SpecificationSetting = 2 Then 
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
       Interpolated = 0,
       Variable = v.var_desc,
       EngineeringUnits = v.eng_units,
       LRL = vs.L_Reject,
       LWL = vs.L_Warning,
       TGT = vs.Target,
       UWL = vs.U_Warning,
       URL = vs.U_Reject,
       Value = t.Result,
       EnteredOn =  [dbo].[fnServer_CmnConvertFromDbTime] (t.Entry_On,@InTimeZone) ,
       EnteredBy = u.Username
  From Variables v
  Join prod_units pu on pu.pu_id = @Unit or pu.master_Unit = @Unit
  Join pu_groups pug on pug.pu_id = pu.pu_id and pug.pug_id = v.pug_id
  left outer join tests t on t.var_id = v.var_id and t.result_on = @StartTime
  left outer join var_specs vs on vs.prod_id = @ProductId and vs.var_id = v.var_id and vs.effective_date <= @StartTime and ((vs.expiration_date > @StartTime) or (vs.expiration_date is null))
  left outer join users u on u.user_id = t.entry_by
  where v.event_type = 3 and v.pu_id <> 0
Union
Select GroupOrder = pug.pug_order,
       ItemOrder = -1000,
       IsTitle = 1,
       Unit = case when pu.Master_Unit Is Null then pu.pu_id else pu.Master_Unit End,
       Id = 0,
       Color = 0,
       Interpolated = 0,
       Variable = pug.pug_desc,
       EngineeringUnits = null,
       LRL = null,
       LWL = null,
       TGT = null,
       UWL = null,
       URL = null,
       Value = null,
       EnteredOn = null,
       EnteredBy = null
  From pu_groups pug
  Join prod_units pu on pu.pu_id = pug.pu_id and (pu.pu_id = @Unit or pu.master_Unit = @Unit) 
  Order By Unit, GroupOrder, ItemOrder 
--********************************************************************************
--********************************************************************************
-- Return Electronic Signature Information
--********************************************************************************
Print 'Electronic Signature Information'
Truncate Table #Report
Declare @ESigId Int
Select @ESigId = Signature_Id
From Waste_Event_Details
Where WED_Id = @EventId
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
 	  	 Select dbo.fnTranslate(@LangId, 35137, 'User Comment'), Value = c.Comment_Text, Tag = c.Comment_Id
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
 	  	 Select dbo.fnTranslate(@LangId, 35140, 'Approver Comment'), Value = c.Comment_Text, Tag = c.Comment_Id
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
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 end,
'Value_Parameter2'= case when (ISDATE(Convert(varchar,Value_Parameter2))=1)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 then
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 [dbo].[fnServer_CmnConvertFromDbTime] (convert(datetime,Value_Parameter2),@InTimeZone)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 else
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 Value_Parameter2
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 end, Hyperlink,Tag
From  #Report Order By Id
--********************************************************************************
Drop Table #Report
