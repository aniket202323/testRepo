/* 	 <summary></summary>
 * 	 <param name="@EventId">The Id of the Batch of interest.</param>
 * 	 <param name="@Command">
 * 	  	 Specifies to the stored procedure to move to a new Event from the current one.
 * 	  	  	 1 = Scroll to Next Event,
 * 	  	  	 2 = Scroll to Previous Event,
 * 	  	  	 3 = Find Event
 * 	 </param>
 * 	 <param name="@SearchEvent"></param>
 * 	 <param name="@Line"></param>
 * 	 <param name="@Path"></param>
 * 	 <param name="@Units"></param>
 * 	  	 A comma seperated list of unit in the order in which they
 * 	  	 are to be displayed.  All other units involved in the 
 * 	  	 batch will be retreived and displayed under the specified 	 units.
 * 	 </param>
 * 	 <param name="@NonProductiveTimeFilter">
 * 	  	 Specifies to the stored procedure to return Non-Productive
 * 	  	 Time information.  Non-Productive Time information will
 * 	  	 be returned after all unit information.
 * 	 </param>
 * 	 <returns>
 * 	  	 Two tables.  The first is a list of prompts.  The second
 * 	  	 is the information for the events for the units involved
 * 	  	 in the Batch as well as the Non-Productive Time if specified
 * 	  	 to include that data.
 * 	 </returns>
 */
CREATE procedure [dbo].[spASP_wrEventProductionTimeline]
--declare 
@EventId int,
@Command int,
@SearchEvent nvarchar(50),
@Line int,
@Path int, 
@Units nvarchar(1000),
@NonProductiveTimeFilter bit = 0,
@InTimeZone nvarchar(200)=NULL
AS
Declare @MaxLevels int
Select @MaxLevels = 20
Declare @ReportName nvarchar(255)
Declare @CriteriaString nVarChar(1000)
Declare @Unit int
Declare @EventEndTime datetime
Declare @EventStartTime datetime
Declare @EventName nVarChar(50)
Declare @LineName nVarChar(100)
Declare @UnitName nVarChar(100)
Declare @EventTypeName nVarChar(50)
Declare @SQL nvarchar(3000)
declare @MinTime datetime
declare @MaxTime datetime
/*********************************************
-- For Testing
--*********************************************
Select @EventId = 327 --2639 --2572 --327
Select @Command =  NULL --3
Select @SearchEvent = NULL --'P11W2604'
Select @Line = NULL
Select @Path = NULL
Select @Units = '2,3,4,5,6,7,8,22'
--**********************************************/
--**********************************************
-- Translations Setup & Common Prompt Lookup
--**********************************************
-- Retreive the Language Id of the current user
Declare @LangId INT
EXEC spWA_GetCurrentUserInfo @LangId = @LangId OUTPUT
--**********************************************
-- Determine the actual event
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
 	 Select @MinTime = Min(Timestamp)
 	 From Events
 	 Where PU_Id = @Unit and Timestamp > @EventEndTime
  Select @EventId = Event_Id 
  From Events
  Where PU_Id = @Unit and Timestamp = @MinTime
End
Else If @Command = 2
Begin
  -- Scroll Previous Event
 	 Select @MaxTime = Max(Timestamp)
 	 From Events
 	 Where PU_Id = @Unit and Timestamp < @EventEndTime
  Select @EventId = Event_Id 
  From Events
  Where PU_Id = @Unit and Timestamp = @MaxTime
End
Else If @Command = 3
Begin
  -- Find Event
 	 If @SearchEvent Is Null
  Begin
    Raiserror('A Search Event Must Be Supplied To Search',16,1)
    Return
  End
  Select @EventId = Event_Id 
  From Events
  Where PU_Id = @Unit and Event_Num = @SearchEvent
End
--Else This is Just A Straight Query
If @EventId Is Null
Begin
  Raiserror('Command Did Not Find Event To Return',16,1)
  Return
End
--**********************************************
-- Retrive Event Information
--**********************************************
Select @Unit = PU_Id, @EventName = Event_Num, 
       @EventStartTime = Start_Time, @EventEndTime = Timestamp 
  From Events e
  Where Event_Id = @EventId
Select @EventTypeName = s.event_subtype_desc
  from event_configuration e 
  join event_subtypes s on s.Event_Subtype_Id = e.Event_Subtype_Id
  where e.pu_id = @Unit and 
        e.et_id = 1
Select @UnitName = pu_desc From prod_Units Where pu_id = @Unit
--**********************************************
-- Lookup Parameters For This Report
--**********************************************
Select @ReportName = @EventTypeName + ' Production Timeline'
Declare @UnitsTable Table(
  Item int,
  ItemOrder int
)
If @Line Is Not Null
 	 Begin
  Select @LineName = pl_desc from prod_lines where pl_id = @Line
  Insert Into @UnitsTable (Item, ItemOrder)
    Select PU_Id, PU_Order
    From Prod_Units 
    Where PL_Id = @Line and Master_Unit Is Null
 	 End
Else If @Path is not null
 	 Begin
 	 --TODO: Change To Path
 	 Select @LineName = pl_desc from prod_lines where pl_id = @Line
End
Else
 	 Begin
 	 --Fetch the Unit Id and the order (in the same order as the list)
 	 Insert Into @UnitsTable
 	  	 Select [Id], ItemOrder From dbo.[fnCMN_IdListToTable]('Prod_Units', @Units, ',')
 	 End
--Fetch the rest of the Units involved in the Batch that have not already been fetched
 	 Insert Into @UnitsTable
 	  	 Select u.PU_Id, ItemOrder = 100
 	  	 From Prod_Units u
 	  	 Join Events e On e.PU_Id = u.PU_Id
 	  	 Join Event_Components ec On ec.Event_Id = e.Event_Id
 	  	 Join Events se On e.Event_Id = ec.Source_Event_Id
 	  	 Join @UnitsTable su On su.Item = e.PU_Id
 	  	 Where u.PU_Id Not In ( Select Item From @UnitsTable )
--**********************************************
-- Return Header Information
--**********************************************
-- Line1: Report Name
-- Line2: Criteria
-- Line3: Generate Time
-- Line4 - n: Column Names
Declare @Prompts Table(
  PromptId int null,
  PromptName nvarchar(20),
  PromptValue nvarchar(1000),
  PromptValue_Parameter SQL_Variant,
  PromptValue_Parameter2 SQL_Variant
)
Insert into @Prompts (PromptName, PromptValue) Values ('ReportName', @ReportName)
Insert into @Prompts (PromptName, PromptValue, PromptValue_Parameter, PromptValue_Parameter2)
  Values('Criteria', dbo.fnTranslate(@LangId, 35086, 'For {0} On {1}'), @EventName, @UnitName)
Insert into @Prompts (PromptName, PromptValue, PromptValue_Parameter) Values('GenerateTime', 'Created: {0}', [dbo].[fnServer_CmnConvertFromDbTime] (dbo.fnServer_CmnGetDate(getutcdate()),@InTimeZone))
Insert into @Prompts (PromptName, PromptValue) Values ('TabTitle', @EventName)
Insert into @Prompts (PromptName, PromptValue) Values ('Comments', 'Comments')
Insert into @Prompts (PromptName, PromptValue, PromptValue_Parameter) Values ('EventId', '{0}', @EventId)
--Note, Returning Later After Getting Min And Max Time
--**********************************************
-- Get Genealogy Data
--**********************************************
Declare @Genealogy Table(
  ThisEvent int,
  [Level] int
)
Declare @WorkEvents Table (
  EventId int
)
Declare @Level int
Declare @NumberOfEvents int
-- Search Backwards In Genealogy
Select @NumberOfEvents = 1
Select @Level = 0
Insert Into @Genealogy (ThisEvent, Level) Values (@EventId, @Level) 
While @NumberOfEvents > 0 and @Level <= @MaxLevels
  Begin
 	 Delete From @WorkEvents
  Insert Into @WorkEvents 
    Select ThisEvent From @Genealogy Where Level = @Level
  Select @Level = @Level + 1
  Insert Into @Genealogy (ThisEvent, Level)
    Select Source_Event_Id, @Level
      From Event_Components 
      Join @WorkEvents we on we.EventId = Event_Components.Event_Id           
  Select @NumberOfEvents = @@RowCount 
  End
Update @Genealogy 
  Set Level = Level * -1
-- Search Forwards In Genealogy
Select @NumberOfEvents = 1
Select @Level = 0
While @NumberOfEvents > 0 and @Level <= @MaxLevels
  Begin
  Delete From @WorkEvents
  Insert Into @WorkEvents 
    Select ThisEvent From @Genealogy Where Level = @Level
  Select @Level = @Level + 1
  Insert Into @Genealogy (ThisEvent, Level)
    Select Event_Id, @Level
      From Event_Components 
      Join @WorkEvents we on we.EventId = Event_Components.Source_Event_Id           
  Select @NumberOfEvents = @@RowCount 
  End
--**********************************************
-- Return Data For Report
--**********************************************
Declare @Events Table(
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
Declare @@Unit int
Declare Unit_Cursor Insensitive Cursor 
  For Select Item From @UnitsTable Order By ItemOrder
  For Read Only
Open Unit_Cursor
Fetch Next From Unit_Cursor Into @@Unit
While @@Fetch_Status = 0
  Begin
    Select @UnitName = PU_Desc From Prod_Units Where PU_Id = @@Unit
 	  	 Select @EventTypeName = coalesce(es.event_subtype_desc, dbo.fnTranslate(@LangId, 35087, 'Event'))
 	  	   From Event_Configuration ec
 	  	   Join Event_Types et on et.et_id = ec.et_id
 	  	   Left Outer Join Event_Subtypes es on es.event_subtype_id = ec.event_subtype_id 
 	  	   Where ec.PU_Id = @@Unit and 
 	  	         ec.et_id = 1
 	  	         
    --*******************************************************************  
    -- Production Events 
    --*******************************************************************
    Insert Into @Events (Category, Subcategory, StartTime, EndTime, ShortLabel, LongLabel, LongLabel_Parameter, Color, HoverText, Hyperlink, SortKey)
 	   Select Category = @UnitName, 
 	  	  	  	  	 Subcategory = NULL,
 	  	  	  	  	 StartTime = Coalesce(e.Start_Time, e.Actual_Start_Time),
 	  	  	  	  	 EndTime = e.[Timestamp],
 	  	  	  	  	 shortLabel = e.event_num,
 	  	  	  	  	 LongLabel = '{0} (' + s.ProdStatus_Desc + ')',
 	  	  	  	  	 LongLabel_Parameter = e.event_num,
 	  	  	  	  	 Color = sc.Color,
 	  	  	  	  	 HoverText = c.Comment_Text,
 	  	  	  	  	 Hyperlink = 'EventDetail.aspx?Id=' + convert(nvarchar(20),e.Event_Id)+ '&TargetTimeZone=' + @InTimeZone,
 	  	  	  	  	 SortKey = u.ItemOrder
 	   From Events_NPT e
 	  	 Join @Genealogy g on g.ThisEvent = e.Event_Id
 	  	 Left Outer Join Production_Status s on s.ProdStatus_id = e.Event_Status
 	  	 Left Outer Join Colors sc ON sc.Color_Id = s.Color_Id
 	  	 Left Outer Join Comments c On c.Comment_id = e.Comment_Id
 	  	 Join @UnitsTable u On u.Item = e.PU_Id
    Where e.PU_id = @@Unit
    Order By e.Timestamp ASC
 	  	 --*******************************************************************
 	  	 
    Fetch Next From Unit_Cursor Into @@Unit
  End
close Unit_Cursor
deallocate Unit_Cursor
--*******************************************************************  
-- Finish Up Resultsets and Return
--*******************************************************************  
Select @MinTime = @EventStartTime, @maxTime = @EventEndTime
If @EventStartTime is null 
BEGIN
  SELECT @MinTime = MIN(StartTime) FROM @Events
END
If @EventStartTime is null 
BEGIN
  SELECT @MinTime = DATEADD(d,-7,@MaxTime)
END
Insert into @Prompts (PromptName, PromptValue, PromptValue_Parameter) Values('StartTime', '{0}',[dbo].[fnServer_CmnConvertFromDbTime] (@MinTime,@InTimeZone))
Insert into @Prompts (PromptName, PromptValue, PromptValue_Parameter) Values('EndTime', '{0}', [dbo].[fnServer_CmnConvertFromDbTime] (@MaxTime,@InTimeZone))
--select PromptId,PromptName,PromptValue,'PromptValue_Parameter'= case when (ISDATE(Convert(varchar,PromptValue_Parameter))=1)
-- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 then
-- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 [dbo].[fnServer_CmnConvertFromDbTime] (convert(datetime,PromptValue_Parameter),@InTimeZone)
-- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 else
-- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 PromptValue_Parameter
-- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 end,
-- 	  	  	  	  	  	  	  	  	  	 'PromptValue_Parameter2'= case when (ISDATE(Convert(varchar,PromptValue_Parameter2))=1)
-- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 then
-- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 [dbo].[fnServer_CmnConvertFromDbTime] (convert(datetime,PromptValue_Parameter2),@InTimeZone)
-- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 else
-- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 PromptValue_Parameter2
-- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 end
SELECT * From @Prompts
--******************************************************************* 
-- Non-Productive Time
--*******************************************************************
If @NonProductiveTimeFilter = 1
Begin
 	 Insert Into @Events (Category, Subcategory, StartTime, EndTime, ShortLabel, LongLabel, LongLabel_Parameter, Color, HoverText, Hyperlink, SortKey)
 	  	 Select Category = Coalesce(PU_Desc + ' ', '') + '(' + dbo.fnTranslate(@LangId, 35132, 'Non-Productive Time') + ')',
 	  	  	  	 Subcategory = Null,
 	  	  	  	 StartTime = npd.Start_Time,
 	  	  	  	 EndTime = npd.End_Time,
 	  	  	  	 ShortLabel = dbo.fnTranslate(@LangId, 35153, 'NP Time'),
 	  	  	  	 LongLabel = '{0}',
 	  	  	  	 LongLabel_Parameter = dbo.fnTranslate(@LangId, 35132, 'Non-Productive Time') + Coalesce(' (' + Event_Reason_Name + ')', ''),
 	  	  	  	 Color = 3328250, --Orange
 	  	  	  	 HoverText = c.Comment_Text,
 	  	  	  	 Hyperlink = Null,
 	  	  	  	 SortKey = u.ItemOrder + 1
 	  	 From NonProductive_Detail npd
 	  	 Left Outer Join Event_Reason_Tree_Data ertd On (ertd.Event_Reason_Tree_Data_Id = npd.Event_Reason_Tree_Data_Id)
 	  	 Left Outer Join Event_Reasons er On er.Event_Reason_Id = ertd.Event_Reason_Id
 	  	 Left Outer Join Prod_Units pu On pu.PU_Id = npd.PU_Id
 	  	 Left Outer Join Comments c On c.Comment_id = npd.Comment_Id
 	  	 Join @UnitsTable u On u.Item = npd.PU_Id
 	  	 Where ((npd.Start_Time > @MinTime And npd.Start_Time < @MaxTime) --NPT starts in the range
 	  	  	  	  	 Or (npd.End_Time > @MinTime And npd.End_Time < @MaxTime) --NPT ends in the range
 	  	  	  	  	 Or (npd.Start_Time <= @MinTime And npd.End_Time >= @MaxTime)) --NPT encompasses the range
 	 Print Cast(@@Rowcount As nvarchar(10)) + ' Non-Productive Events Found'
End 
-- Return Report
Select Category, Subcategory, 'StartTime'=   [dbo].[fnServer_CmnConvertFromDbTime] (StartTime,@InTimeZone)  , 'EndTime'=   [dbo].[fnServer_CmnConvertFromDbTime] (EndTime,@InTimeZone)  , ShortLabel, LongLabel, LongLabel_Parameter, Color, Hovertext, Hyperlink
  From @Events
  Order by SortKey, StartTime ASC 
