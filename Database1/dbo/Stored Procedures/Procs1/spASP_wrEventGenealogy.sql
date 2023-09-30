CREATE procedure [dbo].[spASP_wrEventGenealogy]
@EventId int,
@Command int,
@SearchEvent nvarchar(50),
@InputAliasId int,
@OutputAliasId int,
@IsUDE bit = 0,
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
Declare @DimXUnits nVarChar(50)
Declare @HighAlarm int
Declare @MediumAlarm int
Declare @LowAlarm int
Declare @SQL nvarchar(3000)
Declare @InputAlias nvarchar(50)
Declare @OutputAlias nvarchar(50)
--**********************************************
-- Translations Setup & Common Prompt Lookup
--**********************************************
-- Retreive the Language Id of the current user
Declare @LangId INT
EXEC spWA_GetCurrentUserInfo @LangId = @LangId OUTPUT
-- Get Common Prompts
DECLARE @sDirect nVarChar(100)
SET @sDirect = dbo.fnTranslate(@LangId, 34188, '<All>')
/*********************************************
-- For Testing
--*********************************************
Declare @EventId int,
@Command int,
@SearchEvent nvarchar(50),
@InputAlias nvarchar(100),
@OutputAlias nVarChar(100)
Select @EventId = 327 --2639 --2572 --327
Select @Command =  NULL --3
Select @SearchEvent = NULL --'P11W2604'
Select @InputAlias = NULL
Select @OutputAlias = NULL
spASP_wrEventGenealogy 35023,null,null,null,null
--**********************************************/
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
    If @IsUDE = 1
 	 Begin
 	  	 Select @Unit = PU_Id , @EventEndTime = End_Time
 	  	 From User_Defined_Events 
 	  	 Where UDE_Id = @EventId
 	 End
    Else
 	 Begin
 	  	 Select @Unit = PU_Id, @EventEndTime = Timestamp
 	  	   From Events e
 	  	   Where Event_Id = @EventId 
 	 End
   	 Select @EventId = NULL
  End
If @Command = 1
  Begin
    -- Scroll Next Event
    IF @IsUDE = 1
 	 Begin
 	  	 Select @EventId = UDE_Id 
 	         From User_Defined_Events 
 	         Where PU_Id = @Unit and 
                End_Time = (Select Min(End_Time) From User_Defined_Events Where PU_Id = @Unit and End_Time > @EventEndTime)
 	 End
    Else
 	 Begin            
 	  	 Select @EventId = Event_Id 
 	         From Events 
 	         Where PU_Id = @Unit and 
                Timestamp = (Select Min(Timestamp) From Events Where PU_Id = @Unit and Timestamp > @EventEndTime)
 	 End
  End
Else If @Command = 2
  Begin
    -- Scroll Previous Event
    IF @IsUDE =1 
 	 Begin
 	     Select @EventId = UDE_Id 
 	       From User_Defined_Events 
 	       Where PU_Id = @Unit and
              End_Time = (Select Max(End_Time) From User_Defined_Events Where PU_Id = @Unit and End_Time < @EventEndTime)
 	 End
    Else
 	 Begin 	   
 	     Select @EventId = Event_Id 
 	       From Events 
 	       Where PU_Id = @Unit and
              Timestamp = (Select Max(Timestamp) From Events Where PU_Id = @Unit and Timestamp < @EventEndTime)
 	 End
  End
Else If @Command = 3
  Begin
    -- Find Event
 	 Print 'Searching for Event'
 	  	 If @SearchEvent Is Null
 	  	   Begin
 	  	     Raiserror('A Search Event Must Be Supplied To Search',16,1)
 	  	     Return
 	  	   End
 	 If @IsUDE = 1
 	  	 Begin
 	  	     Select @EventId = MAX(UDE_Id)
 	  	       From User_Defined_Events 
 	  	       Where PU_Id = @Unit and
 	             UDE_Desc = @SearchEvent
 	  	 End
 	 Else
 	  	 Begin
 	  	     print @Unit
 	  	     Select @EventId = MAX(Event_Id )
 	  	       From Events 
 	  	       Where Event_Num = @SearchEvent
 	  	  	 
                    Print 'here'
 	  	     print @EventId
 	  	 End
/*
select Event_nUm, PU_Id from Events
*/
  End
--Else This is Just A Straight Query
If @EventId Is Null
  Begin
    Raiserror('Command Did Not Find Event To Return',16,1)
    Return
  End
If @IsUDE = 1
 	 Begin
 	  	 print 'Displaying UDE'
 	   Select @Unit = PU_Id, @EventName = UDE_Desc, 
          @EventStartTime = Start_Time, @EventEndTime = End_Time 
 	   From User_Defined_Events e
 	   Where UDE_Id = @EventId 
 	   If @EventStartTime Is Null
 	     Select @EventStartTime = max(End_Time) 
 	     From User_Defined_Events 
 	     Where PU_Id = @Unit and End_Time < @EventEndTime
 	   Select  @DimXUnits = ''
--Select * from User_Defined_Events 	  	 
 	   Select @EventTypeName = Case When Event_Id is null Then 'Phase' Else 'Operation' End
 	   From User_Defined_Events
 	   Where UDE_Id = @EventId
 	 End
Else
 	 Begin
          Select @Unit = PU_Id, @EventName = Event_Num, 
          @EventStartTime = Start_Time, @EventEndTime = Timestamp 
 	   From Events e
 	   Where Event_Id = @EventId 
   	   If @EventStartTime Is Null
 	     Select @EventStartTime = max(Timestamp) 
            From Events 
            Where PU_Id = @Unit and Timestamp < @EventEndTime
 	   Select @EventTypeName = s.event_subtype_desc,
 	        @DimXUnits = s.Dimension_X_Eng_Units
 	  	 from event_configuration e 
 	  	   join event_subtypes s on s.Event_Subtype_Id = e.Event_Subtype_Id
 	  	 where e.pu_id = @Unit and  e.et_id = 1
 	 End
Select @UnitName = pu_desc From prod_Units Where pu_id = @Unit
--**********************************************
-- Loookup Parameters For This Report
--**********************************************
Select @ReportName = @EventTypeName + ' ' + dbo.fnTranslate(@LangId, 34748, 'Genealogy')
--**********************************************
-- Loookup Alias Names For This Report
--**********************************************
Select @InputAlias = Input_Name From PrdExec_Inputs Where PEI_Id = @InputAliasId
Select @OutputAlias = Input_Name From PrdExec_Inputs Where PEI_Id = @OutputAliasId
--**********************************************
-- Return Header Information
--**********************************************
-- Line1: Report Name
-- Line2: Criteria
-- Line3: Generate Time
-- Line4 - n: Column Names
Create table #Prompts (
  PromptId int,
  PromptName nvarchar(20),
  PromptValue nvarchar(1000),
  PromptValue_Parameter SQL_Variant, --ECR 35506 - PA 4.3.1: HKNL Genealogy alarm number does not match - Siebel Case#1-474442129
  PromptValue_Parameter2 nVarChar(1000)
)
Insert into #Prompts (PromptId, PromptName, PromptValue) Values (1, 'ReportName', @ReportName)
Insert into #Prompts (PromptId, PromptName, PromptValue, PromptValue_Parameter, PromptValue_Parameter2) Values(2, 'Criteria', dbo.fnTranslate(@LangId, 34749, 'For {0} On {1}'), @EventName, @UnitName)
Insert into #Prompts (PromptId, PromptName, PromptValue, PromptValue_Parameter) Values(3, 'GenerateTime', dbo.fnTranslate(@LangId, 34521, 'Created: {0}'), [dbo].[fnServer_CmnConvertFromDbTime]( dbo.fnServer_CmnGetDate(getutcdate()),@InTimeZone))
Insert into #Prompts (PromptId, PromptName, PromptValue, PromptValue_Parameter) Values(4, 'InputColumnName', dbo.fnTranslate(@LangId, 34750, 'Inputs: {0}'), COALESCE(@InputAlias, @sDirect))
Insert into #Prompts (PromptId, PromptName, PromptValue) Values(5, 'MiddleColumnName', @EventTypeName + ': ' + @EventName)
Insert into #Prompts (PromptId, PromptName, PromptValue, PromptValue_Parameter) Values(6, 'OutputColumnName', dbo.fnTranslate(@LangId, 34751, 'Outputs: {0}'), COALESCE(@OutputAlias, @sDirect))
Insert into #Prompts (PromptId, PromptName, PromptValue, PromptValue_Parameter) Values (7, 'EventId', '{0}', @EventId)
Insert into #Prompts (PromptId, PromptName, PromptValue) Values (8, 'EventType', @EventTypeName)
Insert into #Prompts (PromptId, PromptName, PromptValue) Values (9, 'EventNumber', @EventName)
Insert into #Prompts (PromptId, PromptName, PromptValue) Values (10, 'Unit', @Unit)
Insert into #Prompts (PromptId, PromptName, PromptValue, PromptValue_Parameter) Values (11, 'GotoPrevious', dbo.fnTranslate(@LangId, 34716, 'Goto Previous {0}'), @EventTypeName)
Insert into #Prompts (PromptId, PromptName, PromptValue, PromptValue_Parameter) Values (12, 'GotoNext', dbo.fnTranslate(@LangId, 34717, 'Goto Next {0}'), @EventTypeName)
IF @EventStartTime is NULL
  Insert Into #Prompts (PromptId, PromptName, PromptValue) Values (13, 'StartTime',dbo.fnTranslate(@LangId, 34488, 'UNKNOWN'))
ELSE
  Insert Into #Prompts (PromptId, PromptName, PromptValue, PromptValue_Parameter) Values (13, 'StartTime','{0}', [dbo].[fnServer_CmnConvertFromDbTime]( @EventStartTime,@InTimeZone))
Insert Into #Prompts (PromptId, PromptName, PromptValue, PromptValue_Parameter) Values (14, 'EndTime','{0}', [dbo].[fnServer_CmnConvertFromDbTime]( @EventEndTime,@InTimeZone) )
Insert Into #Prompts (PromptId, PromptName, PromptValue, PromptValue_Parameter) Values (15, 'Unit','{0}', @Unit)
--select PromptId,PromptName,PromptValue,'PromptValue_Parameter'= case when (ISDATE(Convert(varchar,PromptValue_Parameter))=1)
-- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 then
-- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 [dbo].[fnServer_CmnConvertFromDbTime] (convert(datetime,PromptValue_Parameter),@InTimeZone)
-- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 else
-- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 PromptValue_Parameter
-- 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 end, PromptValue_Parameter2
--From #Prompts
SELECT PromptId,PromptName,PromptValue,PromptValue_Parameter,PromptValue_Parameter2 From #Prompts
Drop Table #Prompts
--**********************************************
-- Get Alarm Counts For This Event
--**********************************************
If Not @IsUDE = 1
execute spCMN_GetUnitAlarmCounts
 	 @Unit,
 	 @EventStartTime, 
 	 @EventEndTime,
 	 @HighAlarm OUTPUT,
 	 @MediumAlarm OUTPUT,
 	 @LowAlarm OUTPUT
--**********************************************
-- Return This Event's Information
--**********************************************
If @IsUDE = 1
 	 Begin
 	  	 Select EventId = @EventId,
 	  	        EventType = Case When E.Event_Id is Null Then 'Phase' Else 'Operation' End,
 	  	        EventNumber = e.UDE_Desc,
 	  	        Status = null,
 	  	        Product = null,
 	  	        Unit = @UnitName,
 	  	        HighAlarm = 0,
 	  	        MediumAlarm = 0,
 	  	        LowAlarm = 0,
 	  	        HoverText = '',
 	  	        Color = 0,
 	  	        LinkCount = NULL,
 	  	        LinkAmount = cast(0 as real),
 	  	        LinkUnit = @DimXUnits,
 	  	  	 IsUDE = 1
 	  	   From User_Defined_Events e
 	  	   Where e.UDE_Id = @EventId
 	 End
Else
 	 Begin
 	  	 Select EventId = @EventId,
 	  	        EventType = @EventTypeName,
 	  	        EventNumber = e.event_num,
 	  	        Status = s.prodstatus_desc,
 	  	        Product = Case When e.Applied_Product Is Null Then p1.prod_code else p2.prod_code end,
 	  	        Unit = @UnitName,
 	  	        HighAlarm = @HighAlarm,
 	  	        MediumAlarm = @MediumAlarm,
 	  	        LowAlarm = @LowAlarm,
 	  	        HoverText = c.Comment_Text,
 	  	        Color = Case when s.status_valid_for_input = 0 Then 2 Else 0 End,
 	  	        LinkCount = NULL,
 	  	        LinkAmount = NULL,
 	  	        LinkUnit = @DimXUnits,
 	  	  	 IsUDE = 0
 	  	   From Events e
 	  	   Join Production_Status s on s.prodstatus_id = e.event_status
 	  	   Left outer join comments c on c.comment_Id = e.comment_id
 	  	   join production_starts ps on ps.pu_id = @Unit and ps.start_time <= @EventEndTime and ((ps.end_time > @EventEndTime) or (ps.End_Time Is Null))
 	  	   join products p1 on p1.prod_id = ps.prod_id 	  	 
 	  	   Left outer join products p2 on p2.prod_id = e.applied_product
 	  	   Where e.Event_Id = @EventId
 	 End
--**********************************************
-- Get Required Genealogy
--**********************************************
Create Table #Genealogy (
  ThisEvent int,
  Level int,
  OtherEvent int NULL,
  LinkCount int NULL,
  Unit int NULL,
  Amount real NULL,
  HighAlarm int NULL,
  MediumAlarm int NULL,
  LowAlarm int NULL,
  IsUDE bit  null,
 	 UnitId int NULL
)
Create Index ThisEventIdx on #Genealogy (ThisEvent)
Create Table #WorkEvents (
  EventId int,
 	 IsUDE bit
)
Create Index EventIdx on #WorkEvents (EventId)
Declare @Level int
Declare @WorkLevels int
Declare @NumberOfEvents int
-- Search Backwards In Genealogy
Select @NumberOfEvents = 1
Select @Level = 0
If @InputAlias Is Not Null
  Select @WorkLevels = @MaxLevels
Else
  Select @WorkLevels = 2
Insert Into #Genealogy (ThisEvent, Level, IsUDE) Values (@EventId, @Level, @IsUDE) 
If @IsUDE = 1
 	 Begin
 	  	     Declare @IsOp Bit
 	  	     Select @IsOp = Case When Event_Id Is NULL then 0 else 1 End
 	  	       From User_Defined_Events
 	  	       Where UDE_Id = @EventId
 	  	     If @IsOp = 1
 	  	  	 Begin
 	  	  	   Print 'Event is Operation'
 	  	  	   -- Return the Unit Procedure then
 	  	  	   Select EventId = e.Event_Id,
 	  	  	        EventType = 'Unit Procedure',
 	  	  	        EventNumber = e.event_num,
 	  	  	        Status = s.prodstatus_desc,
 	  	  	        Product = Case When e.Applied_Product Is Null Then p1.prod_code else p2.prod_code end,
 	  	  	        Unit = pu.pu_desc,
 	  	  	        HighAlarm = dbo.[fnCMN_GetUnitAlarmCount](pu.PU_Id, e.Start_Time, e.Timestamp, 3),
 	  	  	        MediumAlarm = dbo.[fnCMN_GetUnitAlarmCount](pu.PU_Id, e.Start_Time, e.Timestamp, 2),
 	  	  	        LowAlarm = dbo.[fnCMN_GetUnitAlarmCount](pu.PU_Id, e.Start_Time, e.Timestamp, 1),
 	  	  	        HoverText = c.Comment_Text,
 	  	  	        Color = Case when s.status_valid_for_input = 0 Then 2 Else 0 End,
 	  	  	        LinkCount = 1,
 	  	  	        LinkAmount = cast(0 as real),
 	  	  	        LinkUnits = es.Dimension_X_Eng_Units,
 	  	  	  	 IsUDE = 0
 	  	  	   From Events e
 	  	  	   Join prod_units pu on pu.pu_id = e.pu_id
 	  	  	   Join Production_Status s on s.prodstatus_id = e.event_status
 	  	  	   join production_starts ps on ps.pu_id = e.pu_id and ps.start_time <= e.timestamp and ((ps.end_time > e.timestamp) or (ps.End_Time Is Null))
 	  	  	   join products p1 on p1.prod_id = ps.prod_id
 	  	  	   Left outer join products p2 on p2.prod_id = e.applied_product
 	  	  	   left outer Join event_configuration ec on ec.pu_id = e.pu_id and ec.et_id = 1
 	  	  	   left outer Join event_subtypes es on es.event_subtype_id = ec.event_subtype_id
 	  	  	   Left outer join comments c on c.comment_Id = e.comment_id
 	  	  	   Where Event_id = (Select Event_Id From User_Defined_Events Where UDE_Id = @EventId)
 	  	  	   -- Return all Phases
 	  	  	   Select EventId = e.UDE_Id,
 	  	  	        EventType = 'Phase',
 	  	  	        EventNumber = e.UDE_Desc,
 	  	  	        Status = '',
 	  	  	        Product = null,
 	  	  	        Unit = pu.pu_desc,
 	  	  	        HighAlarm = 0,
 	  	  	        MediumAlarm = 0,
 	  	  	        LowAlarm = 0,
 	  	  	        HoverText = '',
 	  	  	        Color = 0,
 	  	  	        LinkCount = 0,
 	  	  	        LinkAmount = cast(0 as real),
 	  	  	        LinkUnits = '',
 	  	  	  	 IsUDE = 1
 	  	  	   From User_Defined_Events e 
 	  	  	  	 Join Prod_Units pu ON pu.PU_Id = e.PU_Id
 	  	  	   Where e.Parent_UDE_Id = @EventId
 	  	  	 End
 	  	     Else
 	  	  	 Begin
 	  	  	   Print 'Event is Phase'
 	  	  	   -- Return Operation
 	  	  	   Select EventId = e.UDE_Id,
 	  	  	        EventType = 'Operation',
 	  	  	        EventNumber = e.UDE_Desc,
 	  	  	        Status = '',
 	  	  	        Product = null,
 	  	  	        Unit = pu.pu_desc,
 	  	  	        HighAlarm = 0,
 	  	  	        MediumAlarm = 0,
 	  	  	        LowAlarm = 0,
 	  	  	        HoverText = '',
 	  	  	        Color = 0,
 	  	  	        LinkCount = '1',
 	  	  	        LinkAmount = cast(0 as real),
 	  	  	        LinkUnits = '',
 	  	  	  	 IsUDE = 1
 	  	  	   From User_Defined_Events e 
 	  	  	  	 Join Prod_Units pu ON pu.PU_Id = e.PU_Id
 	  	  	   Where e.UDE_ID = (Select Parent_UDE_Id From User_Defined_Events Where UDE_Id = @EventId)
 	  	  	  	  	 
 	  	  	   Select EventId = null ,
 	  	  	        EventType = null ,
 	  	  	        EventNumber= null ,
 	  	  	        Status= null  ,
 	  	  	        Product = null ,
 	  	  	        Unit = null ,
 	  	  	        HighAlarm = null ,
 	  	  	        MediumAlarm = null ,
 	  	  	        LowAlarm = null ,
 	  	  	        HoverText = null ,
 	  	  	        Color = null ,
 	  	  	        LinkCount = null ,
 	  	  	        LinkAmount = null ,
 	  	  	        LinkUnits = null ,
 	  	  	  	 IsUDE = 0
 	  	  	   From User_Defined_Events e 
 	  	  	   Where 1 =0 	     
 	  	   End
 	  	 return
 	 End
Else
 	 Begin
 	  	 While @NumberOfEvents > 0 and @Level <= @WorkLevels and @Level <= @MaxLevels
 	  	   Begin
 	  	     truncate table #WorkEvents
 	  	     Insert Into #WorkEvents 
 	  	       Select ThisEvent, IsUDE From #Genealogy Where Level = @Level
 	  	     Select @Level = @Level + 1
 	  	  	  	 -- Finds a Unit Procedure's Batch
 	  	     Insert Into #Genealogy (ThisEvent, Level, OtherEvent, Amount)
 	  	       Select Source_Event_Id, @Level, Event_Id, Dimension_X
 	  	         From Event_Components 
     	  	     Join #WorkEvents on #WorkEvents.EventId = Event_Components.Event_Id And #WorkEvents.IsUDE = 0          
 	  	     Select @NumberOfEvents = @@RowCount 
 	  	   End
 	  	 
 	  	 --Update Link Counts Backwards
 	  	 Update #Genealogy
 	  	   Set #Genealogy.LinkCount = (Select Count(g2.ThisEvent) From #Genealogy g2 Where g2.OtherEvent = #Genealogy.ThisEvent)
 	  	   From #Genealogy
 	  	   Where #Genealogy.Level > 0
 	 End
Update #Genealogy 
  Set Level = Level * -1
-- Search Forwards In Genealogy
Select @NumberOfEvents = 1
Select @Level = 0
If @OutputAlias Is Not Null
  Select @WorkLevels = @MaxLevels
Else
  Select @WorkLevels = 2
Declare @NewNumberOfEvents int
While @NumberOfEvents > 0 and @Level <= @WorkLevels and @Level <= @MaxLevels
  Begin
    truncate table #WorkEvents
 	  	 -- Processing Current level's Events
    Insert Into #WorkEvents 
      Select ThisEvent, IsUDE From #Genealogy Where Level = @Level
    Select @Level = @Level + 1
 	  	 -- Gets a Batch's Unit Procedures
    Insert Into #Genealogy (ThisEvent, Level, OtherEvent, Amount)
      Select Event_Id, @Level, Source_Event_Id, Dimension_X
        From Event_Components 
        Join #WorkEvents on #WorkEvents.EventId = Event_Components.Source_Event_Id And #WorkEvents.IsUDE = 0         
    Select @NumberOfEvents = @@RowCount 
 	  	 Insert Into #Genealogy (ThisEvent, Level, OtherEvent, Amount, IsUDE)
 	     Select UDE_Id, @Level, #WorkEvents.EventId,  0, 1
 	  	  	 From User_Defined_Events 
 	  	  	 Join #WorkEvents on #WorkEvents.EventId = User_Defined_Events.Parent_UDE_Id
 	  	  	 Join #Genealogy ON #WorkEvents.EventId = #Genealogy.ThisEvent and #Genealogy.IsUDE = 1
 	  	 Select @NewNumberOfEvents = @@RowCount
 	  	 If @NumberOfEvents = 0 
 	  	  	 Select @NumberOfEvents = @NewNumberOfEvents 
 	  	 Insert Into #Genealogy (ThisEvent, Level, OtherEvent, Amount, IsUDE)
 	     Select UDE_Id, @Level, #WorkEvents.EventId, 0, 1
 	  	  	 From User_Defined_Events
 	  	  	 Join #WorkEvents on #WorkEvents.EventId = User_Defined_Events.Event_Id
 	  	 
  Select @NewNumberOfEvents = @@RowCount
  If @NumberOfEvents = 0 
    Select @NumberOfEvents = @NewNumberOfEvents  
  End
Drop Table #WorkEvents
--Update Link Counts Forward
Update #Genealogy
  Set #Genealogy.LinkCount = (Select Count(g2.ThisEvent) From #Genealogy g2 Where g2.OtherEvent = #Genealogy.ThisEvent)
  From #Genealogy
  Where #Genealogy.Level > 0
--Update Unit For All
Update #Genealogy
  Set Unit = (Select PU_id From Events Where Event_id = #Genealogy.ThisEvent)
Create Table #Units (
  Unit int
)
--**********************************************
-- Prepare Input Unit List If Necessary
--**********************************************
--select * from prod_units
If @InputAlias Is Not Null
BEGIN
 	 Insert Into #Units (Unit)
 	  	 Select Distinct peis.PU_Id
 	  	 From PrdExec_Inputs pei
 	  	 Join PrdExec_Input_Sources peis on pei.PEI_Id = peis.PEI_Id
 	  	 Where pei.PEI_Id = @InputAliasId
 	 Delete From #Genealogy  Where Unit Not In (Select Unit From #Units) And Level < 0
 	 Update #Genealogy Set Level = -1 Where Level < 0    
END
--**********************************************
-- Prepare Output Unit List If Necessary
--**********************************************
Truncate Table #Units
If @OutputAlias Is Not Null
Begin
 	 Insert Into #Units (Unit)
 	  	 Select Distinct PU_Id
 	  	 From PrdExec_Inputs
 	  	 Where PEI_Id = @OutputAliasId
 	 Delete From #Genealogy  Where Unit Not In (Select Unit From #Units) and Level > 0
 	 Update #Genealogy Set Level = 1 Where Level > 0    
End
--**********************************************
-- Purge Non-Master Unit Genealogy
--**********************************************
Delete From #Genealogy  Where Unit In (Select PU_Id From Prod_Units Where Master_Unit Is Not Null)
--*******************************************************
-- Cursor Through Reamining Events And Get Alarm Counts
--*******************************************************
Declare @@EventId int
Declare @@StartTime datetime
Declare @@EndTime datetime
Declare @@Unit int
Declare Event_Cursor Insensitive Cursor 
  For Select g.ThisEvent, g.Unit, e.Start_Time, e.Timestamp
        From #Genealogy g 
        Join Events e on e.event_id = g.ThisEvent
  For Read Only
Open Event_Cursor
 	  	 
Fetch Next From Event_Cursor Into @@EventId, @@Unit, @@StartTime, @@EndTime
While @@Fetch_Status = 0
  Begin
 	  	 
 	  	 If @@StartTime Is Null
 	  	   Select @@StartTime = max(Timestamp) 
 	  	     From Events 
 	  	     Where PU_Id = @@Unit and Timestamp < @@EndTime
    Select @HighAlarm = 0
    Select @MediumAlarm = 0
    Select @LowAlarm = 0
 	  	 execute spCMN_GetUnitAlarmCounts
 	  	  	 @@Unit,
 	  	  	 @@StartTime, 
 	  	  	 @@EndTime,
 	  	  	 @HighAlarm OUTPUT,
 	  	  	 @MediumAlarm OUTPUT,
 	  	  	 @LowAlarm OUTPUT
    Update #Genealogy 
      Set HighAlarm = @HighAlarm, MediumAlarm = @MediumAlarm, LowAlarm = @LowAlarm      	  	  	  	 
      Where ThisEvent = @@EventId 
 	  	 Fetch Next From Event_Cursor Into @@EventId, @@Unit, @@StartTime, @@EndTime
  End
Close Event_Cursor
Deallocate Event_Cursor
/*
--This is a possible replacement for the above code to replace the need for the cursor.
Update #Genealogy
Set
 	 HighAlarm = dbo.[fnCMN_GetUnitAlarmCount](g.Unit, e.Start_Time, e.Timestamp, 3),
 	 MediumAlarm = dbo.[fnCMN_GetUnitAlarmCount](g.Unit, e.Start_Time, e.Timestamp, 2),
 	 LowAlarm = dbo.[fnCMN_GetUnitAlarmCount](g.Unit, e.Start_Time, e.Timestamp, 1)
From #Genealogy g
Join Events e On e.Event_Id = g.ThisEvent
*/
--**********************************************
-- Return Input Genealogy
--**********************************************
Select EventId = g.ThisEvent,
       EventType = es.event_subtype_desc,
       EventNumber = e.event_num,
       Status = s.prodstatus_desc,
       Product = Case When e.Applied_Product Is Null Then p1.prod_code else p2.prod_code end,
       Unit = pu.pu_desc,
       HighAlarm = g.HighAlarm,
       MediumAlarm = g.MediumAlarm,
       LowAlarm = g.LowAlarm,
       HoverText = c.Comment_Text,
       Color = Case when s.status_valid_for_input = 0 Then 2 Else 0 End,
       LinkCount = g.LinkCount,
       LinkAmount = cast(g.Amount as real),
       LinkUnits = es.Dimension_X_Eng_Units,
 	  	  	  IsUDE = 0,
 	  	  	  UnitId = pu.PU_Id
  From #Genealogy g
  Join Events e on e.event_id = g.ThisEvent
  Join prod_units pu on pu.pu_id = e.pu_id
  Join Production_Status s on s.prodstatus_id = e.event_status
  join production_starts ps on ps.pu_id = e.pu_id and ps.start_time <= e.timestamp and ((ps.end_time > e.timestamp) or (ps.End_Time Is Null))
  join products p1 on p1.prod_id = ps.prod_id
  Left outer join products p2 on p2.prod_id = e.applied_product
  left outer Join event_configuration ec on ec.pu_id = e.pu_id and ec.et_id = 1
  left outer Join event_subtypes es on es.event_subtype_id = ec.event_subtype_id
  Left outer join comments c on c.comment_Id = e.comment_id
  Where g.Level = -1
--**********************************************
-- Return Output Genealogy
--**********************************************
Declare @ShowEvents bit
Select @ShowEvents = Case when Count(*) > 0 Then 1 else 0 end
From #Genealogy
Where Level = 1 and Isnull(IsUDE,0) = 0
If @ShowEvents = 1
BEGIN
Print 'Displaying Events'
Select EventId = g.ThisEvent,
       EventType = es.event_subtype_desc,
       EventNumber = e.event_num,
       Status = s.prodstatus_desc,
       Product = Case When e.Applied_Product Is Null Then p1.prod_code else p2.prod_code end,
       Unit = pu.pu_desc,
       HighAlarm = g.HighAlarm,
       MediumAlarm = g.MediumAlarm,
       LowAlarm = g.LowAlarm,
       HoverText = c.Comment_Text,
       Color = Case when s.status_valid_for_input = 0 Then 2 Else 0 End,
       LinkCount = g.LinkCount,
       LinkAmount = cast(g.Amount as real),
       LinkUnits = es.Dimension_X_Eng_Units,
 	  	  	  IsUDE = 0,
 	  	  	  UnitId = pu.PU_Id
  From #Genealogy g
  Join Events e on e.event_id = g.ThisEvent
  Join Events eOut on eOut.event_id = g.OtherEvent  -- ECR# 35674: for the ouput genealogy eng unit should come from the other event (source_event_id)
  Join prod_units pu on pu.pu_id = e.pu_id
  Join Production_Status s on s.prodstatus_id = e.event_status
  join production_starts ps on ps.pu_id = e.pu_id and ps.start_time <= e.timestamp and ((ps.end_time > e.timestamp) or (ps.End_Time Is Null))
  join products p1 on p1.prod_id = ps.prod_id
  Left outer join products p2 on p2.prod_id = e.applied_product
  left outer Join event_configuration ec on ec.pu_id = eOut.pu_id and ec.et_id = 1
  left outer Join event_subtypes es on es.event_subtype_id = ec.event_subtype_id
  Left outer join comments c on c.comment_Id = e.comment_id
  Where g.Level = 1 And Isnull(IsUDE,0) = 0
END
ELSE
BEGIN
Print 'Output Comps are Operations'
Select EventId = g.ThisEvent,
       EventType = 'Batch',
       EventNumber = e.UDE_Desc,
       Status = '',
       Product = '',
       Unit = pu.pu_desc,
       HighAlarm =0,
       MediumAlarm = 0,
       LowAlarm = 0,
       HoverText = '',
       Color = 0,
       LinkCount = g.LinkCount,
       LinkAmount = cast(0 as real),
       LinkUnits = '',
 	  	  	  IsUDE = 1,
 	  	  	  UnitId = pu.PU_Id
  From #Genealogy g
  Join User_Defined_Events e on e.UDE_Id = g.ThisEvent
  Join prod_units pu on pu.pu_id = e.pu_id
  Where g.Level = 1 And IsUDE = 1
END 
 	  	 
Drop Table #Genealogy
Drop Table #Units
