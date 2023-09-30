CREATE procedure [dbo].[spASP_wrLineProductionTimeline]
--declare
@Line int,
@Path int, 
@Units nvarchar(1000),
@StartTime datetime, 
@EndTime datetime,
@NonProductiveTimeFilter bit = 0,
@InTimeZone nvarchar(200)=NULL
AS
Declare @ReportName nvarchar(255)
Declare @CriteriaString nVarChar(1000)
Declare @LineName nVarChar(100)
Declare @UnitName nVarChar(100)
Declare @EventTypeName nVarChar(50)
Declare @SQL nvarchar(3000)
/*********************************************
-- For Testing
--*********************************************
Select @Line = NULL
Select @Path = NULL
Select @Units = '2,3'
Select @StartTime = '10-jan-01'
Select @EndTime = dbo.fnServer_CmnGetDate(getutcdate())
--**********************************************/
--**********************************************
-- Translations Setup & Common Prompt Lookup
--**********************************************
-- Retreive the Language Id of the current user
Declare @LangId INT
EXEC spWA_GetCurrentUserInfo @LangId = @LangId OUTPUT
--**********************************************
-- Loookup Parameters For This Report
--**********************************************
Select @ReportName = dbo.fnTranslate(@LangId, 34780, 'Line Production Timeline')
 	 SELECT @StartTime=[dbo].[fnServer_CmnConvertToDbTime] (@StartTime ,@InTimeZone)  
 	 SELECT @EndTime=[dbo].[fnServer_CmnConvertToDbTime] (@EndTime ,@InTimeZone) 
Create Table #Units (
  Item int,
  ItemOrder int
)
If @Line Is Not Null
  Begin
    Select @LineName = pl_desc from prod_lines where pl_id = @Line
    Insert Into #Units (Item, ItemOrder)
      Select PU_Id, PU_Order
        From Prod_Units 
        Where PL_Id = @Line and
              Master_Unit Is Null
  End
Else If @Path is not null
  Begin
  --TODO: Change To Path
  Select @LineName = pl_desc from prod_lines where pl_id = @Line
  End
Else
  Begin
    Select @LineName = 'Unit'
 	  	 Select @SQL = 'Select PU_Id, ItemOrder = CharIndex(convert(nvarchar(10),PU_Id),' + '''' + @Units + '''' + ',1)  From Prod_Units Where PU_Id in ('  + @Units +  ')'
 	  	 Insert Into #Units
 	  	   Exec (@SQL)
  End
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
  PromptValue_Parameter2 SQL_Variant,
  PromptValue_Parameter3 SQL_Variant
)
Insert into #Prompts (PromptName, PromptValue) Values ('ReportName', @ReportName)
Insert into #Prompts(PromptName, PromptValue, PromptValue_Parameter, PromptValue_Parameter2, PromptValue_Parameter3)
  Values('Criteria', dbo.fnTranslate(@LangId, 34769, '{0} Production From [{1}] To [{2}]'), @LineName, @StartTime, @EndTime)
Insert into #Prompts (PromptName, PromptValue, PromptValue_Parameter) Values('GenerateTime', dbo.fnTranslate(@LangId, 34521, 'Created: {0}'), dbo.fnServer_CmnGetDate(getutcdate()))
Insert into #Prompts (PromptName, PromptValue) Values ('TabTitle', @LineName)
Insert into #Prompts (PromptName, PromptValue) Values ('Comments', dbo.fnTranslate(@LangId, 34743, 'Comments'))
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
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 end,
 	  	  	  	  	  	  	  	  	  	 'PromptValue_Parameter3'= case when (ISDATE(Convert(varchar,PromptValue_Parameter3))=1)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 then
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 [dbo].[fnServer_CmnConvertFromDbTime] (convert(datetime,PromptValue_Parameter3),@InTimeZone)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 else
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 PromptValue_Parameter3
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 end 
From #Prompts
 Drop Table #Prompts
--**********************************************
-- Return Data For Report
--**********************************************
Create Table #Events (
 	 TempKey int NULL,
  SortKey int NULL,
  Category nvarchar(255),
  Subcategory nvarchar(255) NULL,
  StartTime datetime NULL, 
  EndTime datetime,
  ShortLabel nvarchar(255) NULL,
  LongLabel nvarchar(255) NULL,
  Color int, 
  Hovertext nVarChar(1000) NULL,
  Hyperlink nvarchar(255) NULL
)
Declare @@Unit int
Declare @TempKey int
Select @TempKey = 0
Declare Unit_Cursor Insensitive Cursor 
  For Select Item From #Units Order By ItemOrder
  For Read Only
Open Unit_Cursor
Fetch Next From Unit_Cursor Into @@Unit
While @@Fetch_Status = 0
  Begin
    Select @TempKey = @TempKey + 1
    Select @UnitName = PU_Desc From Prod_Units Where PU_Id = @@Unit
 	  	 Select @EventTypeName = coalesce(es.event_subtype_desc, dbo.fnTranslate(@LangId, 34770, 'Event'))
 	  	   From Event_Configuration ec
 	  	   Join Event_Types et on et.et_id = ec.et_id
 	  	   Left Outer Join Event_Subtypes es on es.event_subtype_id = ec.event_subtype_id 
 	  	   Where ec.PU_Id = @@Unit and 
 	  	         ec.et_id = 1
 	  	         
    --*******************************************************************  
    -- Production Events 
    --*******************************************************************  
    Insert Into #Events (Category, Subcategory, StartTime, EndTime, ShortLabel, LongLabel, Color, HoverText, Hyperlink, SortKey, TempKey)
 	   Select Category = @UnitName, 
           Subcategory = NULL,
           StartTime = e.Start_Time,
           EndTime = e.Timestamp,
           shortLabel = e.event_num,
           LongLabel = e.event_num + ' (' + s.ProdStatus_Desc + ')',
           Color = ec.Color,
           HoverText = c.Comment_Text,
 	          Hyperlink = 'EventDetail.aspx?Id=' + convert(nvarchar(20),e.Event_Id)+'&TargetTimeZone=' + @InTimeZone,
           SortKey = u.ItemOrder,
 	  	  	  	  	  TempKey = @TempKey
 	     From Events e
 	     Join Production_Status s on s.ProdStatus_id = e.Event_Status
 	     Join Colors ec on ec.Color_Id = s.Color_Id 
      Left Outer Join Comments c On c.Comment_id = e.Comment_Id
 	  	  	 Join #Units u On u.Item = e.PU_Id
 	     Where e.PU_id = @@Unit and
 	           e.Timestamp > @StartTime and 
 	           e.Timestamp <= @EndTime 
            Order By e.Timestamp ASC
    -- Fill In Start Times If Necessary
    If (Select Count(StartTime) From #Events Where TempKey = @TempKey and StartTime Is Not Null) = 0
      Begin
        Update #Events
          Set StartTime = (Select max(Events.Timestamp) From Events Where Events.PU_Id = @@Unit and Events.Timestamp < #Events.EndTime)
          From #Events
          Where #Events.TempKey = @TempKey and
                #Events.StartTime Is Null  
      End
    --*******************************************************************  
 	  	 
 	  	 
    Fetch Next From Unit_Cursor Into @@Unit
  End
CLOSE Unit_Cursor
DEALLOCATE Unit_Cursor
--******************************************************************* 
-- Non-Productive Time
--*******************************************************************
If @NonProductiveTimeFilter = 1
Begin
 	 Insert Into #Events (Category, Subcategory, StartTime, EndTime, ShortLabel, LongLabel, Color, HoverText, Hyperlink, SortKey)
 	  	 Select Category = Coalesce(PU_Desc + ' ', '') + '(' + dbo.fnTranslate(@LangId, 35132, 'Non-Productive Time') + ')',
 	  	  	  	 Subcategory = Null,
 	  	  	  	 StartTime = npd.Start_Time,
 	  	  	  	 EndTime = npd.End_Time,
 	  	  	  	 ShortLabel = dbo.fnTranslate(@LangId, 35153, 'NP Time'),
 	  	  	  	 LongLabel = dbo.fnTranslate(@LangId, 35132, 'Non-Productive Time') + Coalesce(' (' + Event_Reason_Name + ')', ''),
 	  	  	  	 Color = 3328250, --Orange
 	  	  	  	 HoverText = c.Comment_Text,
 	  	  	  	 Hyperlink = Null,
 	  	  	  	 SortKey = u.ItemOrder + 1
 	  	 From NonProductive_Detail npd
 	  	 Left Outer Join Event_Reason_Tree_Data ertd On (ertd.Event_Reason_Tree_Data_Id = npd.Event_Reason_Tree_Data_Id)
 	  	 Left Outer Join Event_Reasons er On er.Event_Reason_Id = ertd.Event_Reason_Id
 	  	 Left Outer Join Prod_Units pu On pu.PU_Id = npd.PU_Id
 	  	 Left Outer Join Comments c On c.Comment_id = npd.Comment_Id
 	  	 Join #Units u On u.Item = npd.PU_Id
 	  	 Where ((npd.Start_Time > @StartTime And npd.Start_Time < @EndTime) --NPT starts in the range
 	  	  	  	  	 Or (npd.End_Time > @StartTime And npd.End_Time < @EndTime) --NPT ends in the range
 	  	  	  	  	 Or (npd.Start_Time <= @StartTime And npd.End_Time >= @EndTime)) --NPT encompasses the range
 	 Print Cast(@@Rowcount As nvarchar(10)) + ' Non-Productive Events Found'
End 
-- Return Report
Select Category, Subcategory,
'StartTime'=  [dbo].[fnServer_CmnConvertFromDbTime] (StartTime,@InTimeZone)  ,  
'EndTime'= [dbo].[fnServer_CmnConvertFromDbTime] (EndTime,@InTimeZone)  ,
 ShortLabel, LongLabel, Color, Hovertext, Hyperlink
  From #Events
  Order by SortKey, StartTime ASC 
Drop Table #Events
Drop Table #Units
