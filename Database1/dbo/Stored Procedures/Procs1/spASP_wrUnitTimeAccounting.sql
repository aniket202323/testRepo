CREATE procedure [dbo].[spASP_wrUnitTimeAccounting]
@Unit int,
@StartTime datetime, 
@EndTime datetime,
@EventTypes nVarChar(1000) = NULL, 
@EventSubTypes nVarChar(1000) = NULL, 
@Variables nVarChar(1000) = NULL,
@InTimeZone nvarchar(200)=NULL
AS
--TODO: Get Specification Id For Production Rate
Declare @ReportName nvarchar(255)
Declare @CriteriaString nVarChar(1000)
Declare @UnitName nVarChar(100)
Declare @VariableName nVarChar(100)
Declare @UDEName nVarChar(100)
Declare @UDEType int
Declare @EventTypeName nVarChar(50)
Declare @SQL nvarchar(3000)
Declare @ProductionRateSpecification int
Select @ProductionRateSpecification = NULL
--**********************************************
-- Translations Setup & Common Prompt Lookup
--**********************************************
-- Retreive the Language Id of the current user
Declare @LangId INT
EXEC spWA_GetCurrentUserInfo @LangId = @LangId OUTPUT
Declare @sUnspecified nVarChar(100)
Declare @sNonProductiveTime nVarChar(100)
Declare @sNPTime nVarChar(100)
Declare @sEvent nVarChar(100)
Declare @sDowntime nVarChar(100)
Declare @sWaste nVarChar(100)
Declare @sProduct nVarChar(100)
Declare @sProcessOrders nVarChar(100)
Declare @sCrew nVarChar(100)
select @StartTime =[dbo].[fnServer_CmnConvertToDbTime] (@StartTime,@InTimeZone)
select @EndTime =[dbo].[fnServer_CmnConvertToDbTime] (@EndTime,@InTimeZone)
SET @sUnspecified = dbo.fnTranslate(@LangId, 34519, '<Unspecified>')
SET @sNonProductiveTime = dbo.fnTranslate(@LangId, 35132, 'Non-Productive Time')
SET @sNPTime = dbo.fnTranslate(@LangId, 35153, 'NP Time')
SET @sEvent = dbo.fnTranslate(@LangId, 34770, 'Event')
SET @sDowntime = dbo.fnTranslate(@LangId, 34775, 'Downtime')
SET @sWaste = dbo.fnTranslate(@LangId, 34779, 'Waste')
SET @sProduct = dbo.fnTranslate(@LangId, 34863, 'Product')
SET @sProcessOrders = dbo.fnTranslate(@LangId, 34864, 'Process Orders')
SET @sCrew = dbo.fnTranslate(@LangId, 34774, 'Crew')
Select @ReportName = dbo.fnTranslate(@LangId, 34865, 'Unit Time Accounting')
--**********************************************
-- Loookup Parameters For This Report
--**********************************************
Select @UnitName = PU_Desc From Prod_Units Where PU_Id = @Unit
Select @EventTypeName = coalesce(es.event_subtype_desc, @sEvent)
  From Event_Configuration ec
  Join Event_Types et on et.et_id = ec.et_id
  Left Outer Join Event_Subtypes es on es.event_subtype_id = ec.event_subtype_id 
  Where ec.PU_Id = @Unit and 
        ec.et_id = 1
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
Insert into #Prompts (PromptName, PromptValue, PromptValue_Parameter, PromptValue_Parameter2, PromptValue_Parameter3)
  Values('Criteria', dbo.fnTranslate(@LangId, 34866, '{0} Events From [{1}] To [{2}]'), @UnitName, @StartTime, @EndTime)
Insert into #Prompts (PromptName, PromptValue, PromptValue_Parameter) Values ('GenerateTime', dbo.fnTranslate(@LangId, 34521, 'Created: {0}'), dbo.fnServer_CmnGetDate(getutcdate()))
Insert into #Prompts (PromptName, PromptValue) Values ('TabTitle', @UnitName)
Insert into #Prompts (PromptName, PromptValue) Values ('Comments', dbo.fnTranslate(@LangId, 34838, 'Comments'))
 	 select PromptId,PromptName,PromptValue,'PromptValue_Parameter'= case when (ISDATE(Convert(varchar,PromptValue_Parameter))=1)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 then
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 [dbo].[fnServer_CmnConvertFromDbTime] (convert(datetime,PromptValue_Parameter),@InTimeZone)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 else
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 PromptValue_Parameter
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 end ,
 	  	  	  	  	  	  	  	  	 'PromptValue_Parameter2'= case when (ISDATE(Convert(varchar,PromptValue_Parameter2))=1)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 then
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 [dbo].[fnServer_CmnConvertFromDbTime] (convert(datetime,PromptValue_Parameter2),@InTimeZone)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 else
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 PromptValue_Parameter2
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 end ,
 	  	  	  	  	  	  	  	  	 'PromptValue_Parameter3'= case when (ISDATE(Convert(varchar,PromptValue_Parameter3))=1)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 then
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 [dbo].[fnServer_CmnConvertFromDbTime] (convert(datetime,PromptValue_Parameter3),@InTimeZone)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 else
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 PromptValue_Parameter3
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 end 
From #Prompts
Drop Table #Prompts
--**********************************************
-- Fill Temporary Tables and Define Cursors
--**********************************************
-- #Events
Create Table #Events (
  Category nvarchar(1000),
  Subcategory nVarChar(1000) NULL,
  StartTime datetime NULL, 
  EndTime datetime,
  ShortLabel nVarChar(1000) NULL,
  LongLabel nVarChar(1000) NULL,
  Color int, 
  Hovertext nVarChar(1000) NULL,
  Hyperlink nVarChar(1000) NULL,
  EventTypeId int NULL,
  SubTypeId int NULL -- variables or UDEs
)
-- END #Events (will be filled later)
-- #EventTypes
Create Table #EventTypes (
  Item int,
  ItemOrder int,
  ItemCategory nVarChar(100)
)
If @EventTypes Is Not Null
   Insert Into #EventTypes (ItemOrder, Item) Exec spRS_MakeOrderedResultSet @EventTypes
Declare Event_Cursor Insensitive Cursor 
  For Select Item From #EventTypes Order By ItemOrder
  For Read Only
-- END #EventTypes
-- #EventSubTypes
Create Table #EventSubTypes (
  Item int,
  ItemOrder int
)
If @EventSubTypes Is Not Null
  Insert Into #EventsubTypes (ItemOrder, Item) Exec spRS_MakeOrderedResultSet @EventSubTypes
Declare SubType_Cursor Insensitive Cursor 
  For Select Item From #EventSubTypes Order By ItemOrder
  For Read Only
-- END #EventSubTypes
-- # Variables
Create Table #Variables (
  Item int,
  ItemOrder int
)
If @Variables Is Not Null
   Insert Into #Variables(ItemOrder, Item) Exec spRS_MakeOrderedResultSet @Variables
Declare Variable_Cursor Insensitive Cursor 
  For Select Item From #Variables Order By ItemOrder
  For Read Only
-- END #Variables
--**********************************************
-- Return Data For Report
--**********************************************
Declare @@EventType int
Declare @@EventSubtypeId int
Declare @@VariableId int
Declare @EventKey int
Declare @VariableKey int
Declare @SubTypeKey int
Set @EventKey = 0
Set @VariableKey = 0
Set @SubTypeKey = 0
Open SubType_Cursor
Open Variable_Cursor
Open Event_Cursor
Fetch Next From Event_Cursor Into @@EventType
While @@Fetch_Status = 0
  Begin
 	  	 Select @EventKey = @EventKey + 1
 	  	 If @@EventType = -2
 	  	  	 Begin
 	  	  	 --*******************************************************************  
 	  	  	 -- Non-Productive Time
 	  	  	 --*******************************************************************  
 	  	  	  	 Print 'Retrieving non-productive time for unit ' + Cast(@Unit As nvarchar(10))
 	  	  	  	 Insert Into #Events (Category, StartTime, EndTime, ShortLabel, LongLabel, Color, HoverText, EventTypeId, SubTypeId)
 	  	  	  	 Select Category = @sNonProductiveTime,
 	  	  	  	  	  	  	  	 StartTime = npd.Start_Time,
 	  	  	  	  	  	  	  	 EndTime = npd.End_Time,
 	  	  	  	  	  	  	  	 ShortLabel = @sNPTime,
 	  	  	  	  	  	  	  	 LongLabel = @sNonProductiveTime  + Coalesce(' (' + Event_Reason_Name + ')', ''),
 	  	  	  	  	  	  	  	 32796 [Color], --Orange
 	  	  	  	  	  	  	  	 HoverText = CONVERT(nvarchar(1000),c.Comment_Text),
 	  	  	  	  	  	  	  	 EventTypeId = @EventKey, 
 	  	  	  	  	  	  	  	 SubTypeId = 0
 	  	  	  	 From NonProductive_Detail npd
 	  	  	  	 Left Outer Join Event_Reason_Tree_Data ertd On (ertd.Event_Reason_Tree_Data_Id = npd.Event_Reason_Tree_Data_Id)
 	  	  	  	 Left Outer Join Event_Reasons er On er.Event_Reason_Id = ertd.Event_Reason_Id
 	  	  	  	 Left Outer Join Comments c On c.Comment_id = npd.Comment_Id
 	  	  	  	 Where npd.PU_Id = @Unit
 	  	  	  	  	 And ((npd.Start_Time > @StartTime And npd.Start_Time < @EndTime) --NPT starts in the range
 	  	  	  	  	  	  	 Or (npd.End_Time > @StartTime And npd.End_Time < @EndTime) --NPT ends in the range
 	  	  	  	  	  	  	 Or (npd.Start_Time <= @StartTime And npd.End_Time >= @EndTime)) --NPT encompasses the range
 	  	  	  	 Print Cast(@@Rowcount As nvarchar(10)) + ' Non-Productive Events Found'
 	  	  	 End    
    Else If @@EventType = 1  	  	 
      Begin
        --*******************************************************************  
        -- Production Events 
        --*******************************************************************  
        Insert Into #Events (Category, Subcategory, StartTime, EndTime, ShortLabel, LongLabel, Color, HoverText, Hyperlink, EventTypeId, SubTypeId)
 	    	   Select Category = @EventTypeName, 
 	              Subcategory = NULL,
 	              StartTime = e.Start_Time,
 	              EndTime = e.Timestamp,
 	              shortLabel = e.event_num,
 	              LongLabel = e.event_num + ' (' + s.ProdStatus_Desc + ')',
 	              Color = ec.Color,
 	              HoverText = CONVERT(nvarchar(1000),c.Comment_Text),
 	  	  	      Hyperlink = '<Link>EventDetail.aspx?Id=' + convert(nvarchar(20),e.Event_Id) + '&TargetTimeZone='+ @InTimeZone + '</Link>',
 	  	  	  	  EventTypeId = @EventKey, 
 	  	  	  	  SubTypeId = 0
 	  	  	     From Events e
 	  	  	     Left Outer Join Production_Status s on s.ProdStatus_id = e.Event_Status
 	  	  	  	   Left Outer Join Colors ec ON ec.Color_Id = s.Color_Id
 	  	       Left Outer Join Comments c On c.Comment_id = e.Comment_Id
 	  	  	     Where e.PU_id = @Unit and
 	  	  	           ((e.Timestamp >= @StartTime) and 
 	  	  	  	  	 (e.Start_Time <= @EndTime or e.Start_Time is null ))  -- consider events sharing the report time window
 	  	             Order By e.Timestamp ASC
        -- Fill In Start Times If Necessary
        If (Select Count(StartTime) From #Events Where Category = @EventTypeName and StartTime Is Not Null) = 0
          Begin
            Update #Events
              Set StartTime = (Select max(Events.Timestamp) From Events Where Events.PU_Id = @Unit and Events.Timestamp <= #Events.EndTime)
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
        Insert Into #Events (Category, Subcategory, StartTime, EndTime, ShortLabel, LongLabel, Color, HoverText, Hyperlink, EventTypeId, SubTypeId)
 	  	    	   Select Category = @sDowntime, 
 	  	              Subcategory = NULL,
 	  	              StartTime = Case When d.Start_Time < @StartTime Then @StartTime Else d.Start_Time End,
 	  	              EndTime = coalesce(d.End_Time, @EndTime),
 	  	              ShortLabel = coalesce('(' + tef.tefault_name + ')', coalesce(r1.event_reason_name, @sUnspecified)),
 	  	              LongLabel = coalesce(r1.event_reason_name, @sUnspecified)  + coalesce(',' + r2.event_reason_name,'') + coalesce(' (' + tef.tefault_name + ')',''),
 	  	              Color = Case when d.reason_level1 Is Null Then (Select Color From Colors Where Color_Id = 3) Else (Select Color From Colors Where Color_Id = 1) End,
 	  	              HoverText = NULL,
 	  	  	  	      Hyperlink = '<Link>DowntimeDetail.aspx?Id=' + convert(nvarchar(20),d.tedet_Id) + '&TargetTimeZone='+ @InTimeZone +  '</Link>',
 	  	  	  	  	  EventTypeId = @EventKey, 
 	  	  	  	  	  SubTypeId = 0
 	  	  	    	  	 From Timed_Event_Details d
 	  	         Left Outer Join Event_Reasons r1 on r1.event_reason_id = d.reason_level1
 	  	         Left Outer Join Event_Reasons r2 on r2.event_reason_id = d.reason_level2
 	  	         Left Outer Join Timed_Event_Fault tef on tef.tefault_id = d.tefault_id
 	  	  	  	  	   Where d.PU_id = @Unit and
 	  	  	    	  	       d.Start_Time = (Select Max(Start_Time) From Timed_Event_Details t Where t.PU_Id = @Unit and t.start_time < @StartTime) and
 	  	  	    	       ((d.End_Time > @StartTime) or (d.End_Time is Null))
  	  	  	  	 Union
 	  	  	    	   Select Category =  @sDowntime, 
 	  	                Subcategory = NULL,
 	  	                StartTime = Case When d.Start_Time < @StartTime Then @StartTime Else d.Start_Time End,
 	  	                EndTime = coalesce(d.End_Time, @EndTime),
 	  	                ShortLabel = coalesce('(' + tef.tefault_name + ')', coalesce(r1.event_reason_name, @sUnspecified)),
 	  	                LongLabel = coalesce(r1.event_reason_name, @sUnspecified)  + coalesce(',' + r2.event_reason_name,'') + coalesce(' (' + tef.tefault_name + ')',''),
 	  	                Color = Case when d.reason_level1 Is Null Then (Select Color From Colors Where Color_Id = 3) Else (Select Color From Colors Where Color_Id = 1) End,
 	  	                HoverText = NULL,
 	  	  	  	  	          Hyperlink = '<Link>DowntimeDetail.aspx?Id=' + convert(nvarchar(20),d.tedet_Id) + '&TargetTimeZone='+ @InTimeZone + '</Link>',
 	  	  	  	  	  	 EventTypeId = @EventKey, 
 	  	  	  	  	  	 SubTypeId = 0
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
        Insert Into #Events (Category, Subcategory, StartTime, EndTime, ShortLabel, LongLabel, Color, HoverText, Hyperlink, EventTypeId, SubTypeId)
 	  	    	   Select Category = @sWaste, 
 	  	              Subcategory = NULL,
 	  	              StartTime = d.Timestamp,
 	  	              EndTime = d.Timestamp,
 	  	              ShortLabel = coalesce('(' + wef.wefault_name + ')', coalesce(r1.event_reason_name, @sUnspecified)),
 	  	              LongLabel = coalesce(r1.event_reason_name, @sUnspecified)  + coalesce(',' + r2.event_reason_name,'') + coalesce(' (' + wef.wefault_name + ')',''),
 	  	              Color = Case when d.reason_level1 Is Null Then (Select Color From Colors Where Color_Id = 3) Else (Select Color From Colors Where Color_Id = 1) End,
 	  	              HoverText = NULL,
 	  	  	  	      Hyperlink = '<Link>WasteDetail.aspx?Id=' + convert(nvarchar(20),d.wed_Id) + '&TargetTimeZone='+ @InTimeZone + '</Link>',
 	  	  	  	  	  EventTypeId = @EventKey, 
 	  	  	  	  	  SubTypeId = 0
 	  	  	  	  	   From Waste_Event_Details d
 	  	         Left Outer Join Event_Reasons r1 on r1.event_reason_id = d.reason_level1
 	  	         Left Outer Join Event_Reasons r2 on r2.event_reason_id = d.reason_level2
 	  	         Left Outer Join Waste_Event_Fault wef on wef.wefault_id = d.wefault_id
 	  	  	  	  	   Where d.PU_id = @Unit and
 	  	  	    	  	       d.Timestamp > @StartTime and 
 	  	               d.Timestamp <= @EndTime and
 	  	               d.Event_Id Is Null
 	  	  	  	 Union
 	  	    	   Select Category = @sWaste, 
 	  	              Subcategory = NULL,
 	  	              StartTime = e.Timestamp,
 	  	              EndTime = e.Timestamp,
 	  	              ShortLabel = coalesce('(' + wef.wefault_name + ')', coalesce(r1.event_reason_name, @sUnspecified)),
 	  	              LongLabel = coalesce(r1.event_reason_name, @sUnspecified)  + coalesce(',' + r2.event_reason_name,'') + coalesce(' (' + wef.wefault_name + ')',''),
 	  	              Color = Case when d.reason_level1 Is Null Then (Select Color From Colors Where Color_Id = 3) Else (Select Color From Colors Where Color_Id = 1) End,
 	  	              HoverText = NULL,
 	  	  	  	          Hyperlink = '<Link>WasteDetail.aspx?Id=' + convert(nvarchar(20),d.wed_Id) + '&TargetTimeZone='+ @InTimeZone +  '</Link>',
 	  	  	  	  	 EventTypeId = @EventKey, 
 	  	  	  	  	 SubTypeId = 0
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
        Insert Into #Events (Category, Subcategory, StartTime, EndTime, ShortLabel, LongLabel, Color, HoverText, Hyperlink, EventTypeId, SubTypeId)
 	  	    	   Select Category = @sProduct, 
 	  	              Subcategory = NULL,
 	  	              StartTime = Case When d.Start_Time < @StartTime Then @StartTime Else d.Start_Time End,
 	  	              EndTime = coalesce(d.End_Time, @EndTime),
 	  	              ShortLabel = p.Prod_code,
 	  	              LongLabel = p.prod_code + ' - ' + p.prod_desc,
 	  	              Color = (Select Color From Colors Where Color_Id = 1),
 	  	              HoverText = CONVERT(nvarchar(1000),c.Comment_Text),
 	  	  	  	      Hyperlink = null,
 	  	  	  	  	  EventTypeId = @EventKey, 
 	  	  	  	  	  SubTypeId = 0
 	  	  	  	  	   From Production_Starts d
 	  	         Join Products p on p.prod_id = d.prod_id
 	  	         Left Outer Join Comments c On c.Comment_id = d.Comment_Id
 	  	  	  	  	   Where d.PU_id = @Unit and
 	  	  	    	  	       d.Start_Time = (Select Max(Start_Time) From Production_Starts t Where t.PU_Id = @Unit and t.start_time < @StartTime) and
 	  	  	     	       ((d.End_Time > @StartTime) or (d.End_Time is Null))
 	  	  	  	 Union
 	  	    	   Select Category = @sProduct, 
 	  	              Subcategory = NULL,
 	  	              StartTime = Case When d.Start_Time < @StartTime Then @StartTime Else d.Start_Time End,
 	  	              EndTime = coalesce(d.End_Time, @EndTime),
 	  	              ShortLabel = p.Prod_code,
 	  	              LongLabel = p.prod_code + ' - ' + p.prod_desc,
 	  	              Color = (Select Color From Colors Where Color_Id = 1),
 	  	              HoverText = CONVERT(nvarchar(1000),c.Comment_Text),
 	  	  	  	      Hyperlink = null,
 	  	  	  	  	  EventTypeId = @EventKey, 
 	  	  	  	  	  SubTypeId = 0
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
 	  	  	 Select @VariableKey = @VariableKey + 1
            Select @VariableName = Var_Desc From Variables Where Var_id = @@VariableId
 	  	         Insert Into #Events (Category, Subcategory, StartTime, EndTime, ShortLabel, LongLabel, Color, HoverText, Hyperlink, EventTypeId, SubTypeId)
 	    	  	    	   Select Category = @VariableName, 
 	                  Subcategory = NULL,
 	                  StartTime = Case When d.Start_Time < @StartTime Then @StartTime Else d.Start_Time End,
 	                  EndTime = coalesce(d.End_Time, @EndTime),
 	                  ShortLabel = coalesce(r1.event_reason_name, @sUnspecified),
 	                  LongLabel = d.alarm_desc,
 	                  Color = Case when d.ack Is Null or d.ack = 0 Then (Select Color From Colors Where Color_Id = 3) Else (Select Color From Colors Where Color_Id = 1) End,
 	                  HoverText = CONVERT(nvarchar(1000),c.Comment_Text),
 	  	  	  	  	  Hyperlink = '<Link>AlarmDetail.aspx?Id=' + convert(nvarchar(20),d.Alarm_Id) + '&TargetTimeZone='+ @InTimeZone + '</Link>',
 	  	  	  	  	  EventTypeId = @EventKey, 
 	  	  	  	  	  SubTypeId = @VariableKey
 	  	  	  	  	  	   From Alarms d
 	  	           Left Outer Join Event_Reasons r1 on r1.event_reason_id = d.cause1
              Left Outer Join Comments c On c.Comment_id = d.Cause_Comment_Id
 	  	  	  	  	  	   Where d.Key_Id = @@VariableId and
 	  	  	  	  	  	  	  	 d.Source_PU_Id = @Unit and
                    d.Alarm_Type_Id in (1,2) and 
 	  	  	    	  	         d.Start_Time = (Select Max(Start_Time) From Alarms t Where t.Key_Id = @@VariableId and t.Alarm_Type_Id in (1,2) and t.start_time < @StartTime) and
 	  	  	  	   	         ((d.End_Time > @StartTime) or (d.End_Time is Null))
 	          Union
 	    	  	    	   Select Category = @VariableName, 
 	                  Subcategory = NULL,
 	                  StartTime = Case When d.Start_Time < @StartTime Then @StartTime Else d.Start_Time End,
 	                  EndTime = coalesce(d.End_Time, @EndTime),
 	                  ShortLabel = coalesce(r1.event_reason_name, @sUnspecified),
 	                  LongLabel = d.alarm_desc,
 	                  Color = Case when d.ack Is Null or d.ack = 0 Then (Select Color From Colors Where Color_Id = 3) Else (Select Color From Colors Where Color_Id = 1) End,
 	                  HoverText = CONVERT(nvarchar(1000),c.Comment_Text),
 	  	  	  	  	  Hyperlink = '<Link>AlarmDetail.aspx?Id=' + convert(nvarchar(20),d.Alarm_Id) + '&TargetTimeZone='+ @InTimeZone + '</Link>',
 	  	  	  	  	  EventTypeId = @EventKey, 
 	  	  	  	  	  SubTypeId = @VariableKey
 	  	  	  	  	  	   From Alarms d
 	  	           Left Outer Join Event_Reasons r1 on r1.event_reason_id = d.cause1
              Left Outer Join Comments c On c.Comment_id = d.Cause_Comment_Id
 	  	  	  	  	  	   Where d.Key_Id = @@VariableId and
 	  	  	  	  	  	  	  	 d.Source_PU_Id = @Unit and
                    d.Alarm_Type_Id in (1,2) and 
 	  	  	               d.Start_Time >= @StartTime and 
 	  	  	  	          	  	 d.Start_Time < @EndTime 
 	  	  	      Order by StartTime 
          End
        --*******************************************************************  
      End
    Else If @@EventType = 14 
      Begin
        --*******************************************************************  
        -- User Defined Events
        --*******************************************************************  
        -- Only one event 14 for all udes. Gather all of them  
        Fetch Next From SubType_Cursor Into @@EventSubtypeId
        WHILE @@Fetch_Status = 0
          Begin
 	  	  	  	 select @SubTypeKey = @SubTypeKey + 1
 	  	  	  	 print 'Retrieving Event Sub Type #' + Cast(@@EventSubtypeId As nvarchar(10))
 	  	  	  	 Select @UDEName = Event_Subtype_Desc, @UDEType = Duration_Required
 	  	  	  	 From Event_Subtypes
 	  	  	  	 Where (Event_Subtype_Id = @@EventSubtypeId Or @@EventSubtypeId < 0)
 	  	  	  	 If @UDEType = 1 
             	  	 Begin
 	  	  	  	  	  -- Both Start and End Times Apply
 	  	  	  	  	  	 Insert Into #Events (Category, Subcategory, StartTime, EndTime, ShortLabel, LongLabel, Color, HoverText, Hyperlink, EventTypeId, SubTypeId)
 	  	  	  	  	  	 Select Category = @UDEName, 
 	  	  	  	  	  	 Subcategory = NULL,
 	  	  	  	  	  	 StartTime = Case When d.Start_Time < @StartTime Then @StartTime Else d.Start_Time End,
 	  	  	  	  	  	 EndTime = coalesce(d.End_Time, @EndTime),
 	  	  	  	  	  	 ShortLabel = coalesce(r1.event_reason_name, @sUnspecified),
 	  	  	  	  	  	 LongLabel = coalesce(d.UDE_Desc + '-' + r1.event_reason_name, r1.event_reason_name, d.UDE_Desc, @sUnspecified),
 	  	  	  	  	  	 Color = Case when d.cause1 Is Null or d.ack = 0 Then (Select Color From Colors Where Color_Id = 3) Else (Select Color From Colors Where Color_Id = 1) End,
 	  	  	  	  	  	 HoverText = CONVERT(nvarchar(1000),c.Comment_Text),
 	  	  	  	  	  	 Hyperlink = '<Link>UDEDetail.aspx?Id=' + convert(nvarchar(20),d.UDE_Id) + '&TargetTimeZone='+ @InTimeZone + '</Link>',
 	  	  	  	  	  	 EventTypeId = @EventKey,
 	  	  	  	  	  	 SubTypeId = @SubTypeKey
 	  	  	  	  	  	 From User_Defined_Events d
 	  	  	  	  	  	 Left Outer Join Event_Reasons r1 on r1.event_reason_id = d.cause1
 	  	  	  	  	  	 Left Outer Join Event_Reasons r2 on r1.event_reason_id = d.cause2
 	  	  	  	  	  	 Left Outer Join Comments c On c.Comment_id = d.Comment_Id
 	  	  	  	  	  	 Where d.PU_Id = @Unit and
 	  	  	  	  	  	  	  	  	   d.Event_Subtype_id = @@EventSubtypeId and
 	  	  	  	  	  	  	   d.Start_Time = (Select Max(Start_Time) From User_Defined_Events t Where t.PU_Id = @Unit and t.Event_Subtype_id = @@EventSubtypeId and t.start_time < @StartTime) and
 	  	  	  	  	  	  	   ((d.End_Time > @StartTime) or (d.End_Time is Null))
 	  	  	  	  	  	 Union
 	  	  	  	  	  	 Select Category = @UDEName, 
 	  	  	  	  	  	 Subcategory = NULL,
 	  	  	  	  	  	 StartTime = Case When d.Start_Time < @StartTime Then @StartTime Else d.Start_Time End,
 	  	  	  	  	  	 EndTime = coalesce(d.End_Time, @EndTime),
 	  	  	  	  	  	 ShortLabel = coalesce(r1.event_reason_name, @sUnspecified),
 	  	  	  	  	  	 LongLabel = coalesce(d.UDE_Desc + '-' + r1.event_reason_name, r1.event_reason_name, d.UDE_Desc, @sUnspecified),
 	  	  	  	  	  	 Color = Case when d.cause1 Is Null or d.ack = 0 Then (Select Color From Colors Where Color_Id = 3) Else (Select Color From Colors Where Color_Id = 1) End,
 	  	  	  	  	  	 HoverText = CONVERT(nvarchar(1000),c.Comment_Text),
 	  	  	  	  	  	 Hyperlink = '<Link>UDEDetail.aspx?Id=' + convert(nvarchar(20),d.UDE_Id) + '&TargetTimeZone='+ @InTimeZone + '</Link>',
 	  	  	  	  	  	 EventTypeId = @EventKey, 
 	  	  	  	  	  	 SubTypeId = @SubTypeKey
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
 	  	  	  	 Else --If @UDEType <> 1 
 	  	  	  	  	 Begin
 	  	  	  	  	  	  	  	 -- Only Start Time Applies
 	  	  	  	  	  	 Insert Into #Events (Category, Subcategory, StartTime, EndTime, ShortLabel, LongLabel, Color, HoverText, Hyperlink, EventTypeId, SubTypeId)
 	  	  	  	  	  	 Select Category = @UDEName, 
 	  	  	  	  	  	 Subcategory = NULL,
 	  	  	  	  	  	 StartTime = d.Start_time,
 	  	  	  	  	  	 EndTime = d.Start_Time,
 	  	  	  	  	  	 ShortLabel = coalesce(r1.event_reason_name, @sUnspecified),
 	  	  	  	  	  	 LongLabel = coalesce(d.UDE_Desc + '-' + r1.event_reason_name, r1.event_reason_name, d.UDE_Desc, @sUnspecified),
 	  	  	  	  	  	 Color = Case when d.cause1 Is Null or d.ack = 0 Then (Select Color From Colors Where Color_Id = 3) Else (Select Color From Colors Where Color_Id = 3) End,
 	  	  	  	  	  	 HoverText = CONVERT(nvarchar(1000),c.Comment_Text),
 	  	  	  	  	  	 Hyperlink = '<Link>UDEDetail.aspx?Id=' + convert(nvarchar(20),d.UDE_Id) + '&TargetTimeZone='+ @InTimeZone + '</Link>',
 	  	  	  	  	  	 EventTypeId = @EventKey, 
 	  	  	  	  	  	 SubTypeId = @SubTypeKey
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
 	  	  	  	 
 	  	  	  	 Fetch Next From SubType_Cursor Into @@EventSubtypeId 
          End 
        --*******************************************************************  
      End
    Else If @@EventType = 19 
      Begin
        --*******************************************************************  
        -- Process Orders
        --*******************************************************************  
        -- TODO: Join In Status Color
        Insert Into #Events (Category, Subcategory, StartTime, EndTime, ShortLabel, LongLabel, Color, HoverText, Hyperlink, EventTypeId, SubTypeId)
 	  	    	   Select Category = @sProcessOrders, 
 	  	              Subcategory = NULL,
 	  	              StartTime = Case When d.Start_Time < @StartTime Then @StartTime Else d.Start_Time End,
 	  	              EndTime = coalesce(d.End_Time, @EndTime),
 	  	              ShortLabel = pp.Process_Order,
 	  	              LongLabel = pp.Process_Order + ' (' +  s.pp_status_desc + ')' + ' - ' + p.prod_code,
 	  	              Color = (Select Color From Colors Where Color_Id = 1),
 	  	              HoverText = CONVERT(nvarchar(1000),c.Comment_Text),
 	  	  	  	      Hyperlink = '<Link>ProcessOrderDetail.aspx?Id=' + convert(nvarchar(20),pp.pp_Id) + '&TargetTimeZone='+ @InTimeZone + '</Link>',
 	  	  	  	  	  EventTypeId = @EventKey, 
 	  	  	  	  	  SubTypeId = 0
 	  	  	  	  	   From Production_Plan_Starts d
 	           Join Production_Plan pp on pp.pp_id = d.pp_id
 	           Join production_plan_statuses s on s.pp_status_id = pp.pp_status_id
 	  	         Join Products p on p.prod_id = pp.prod_id
 	  	         Left Outer Join Comments c On c.Comment_id = d.Comment_Id
 	  	  	  	  	   Where d.PU_id = @Unit and
 	  	  	    	  	       d.Start_Time = (Select Max(Start_Time) From Production_Plan_Starts t Where t.PU_Id = @Unit and t.start_time < @StartTime) and
 	  	  	     	       ((d.End_Time > @StartTime) or (d.End_Time is Null))
 	  	  	  	 Union
 	  	    	   Select Category = @sProcessOrders, 
 	  	              Subcategory = NULL,
 	  	              StartTime = Case When d.Start_Time < @StartTime Then @StartTime Else d.Start_Time End,
 	  	              EndTime = coalesce(d.End_Time, @EndTime),
 	  	              ShortLabel = pp.Process_Order,
 	  	              LongLabel = pp.Process_Order + ' (' +  s.pp_status_desc + ')' + ' - ' + p.prod_code,
 	  	              Color = (Select Color From Colors Where Color_Id = 1),
 	  	              HoverText = CONVERT(nvarchar(1000),c.Comment_Text),
 	  	  	  	      Hyperlink = '<Link>ProcessOrderDetail.aspx?Id=' + convert(nvarchar(20),pp.pp_Id) + '&TargetTimeZone='+ @InTimeZone + '</Link>',
 	  	  	  	  	  EventTypeId = @EventKey, 
 	  	  	  	  	  SubTypeId = 0
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
        Insert Into #Events (Category, Subcategory, StartTime, EndTime, ShortLabel, LongLabel, Color, HoverText, Hyperlink, EventTypeId, SubTypeId)
 	  	    	   Select Category = @sCrew, 
 	  	              Subcategory = NULL,
 	  	              StartTime = Case When d.Start_Time < @StartTime Then @StartTime Else d.Start_Time End,
 	  	              EndTime = coalesce(d.End_Time, @EndTime),
 	  	              ShortLabel = d.crew_desc,
 	  	              LongLabel = d.crew_desc + ' - ' + d.shift_desc,
 	  	              Color = (Select Color From Colors Where Color_Id = 1),
 	  	              HoverText = CONVERT(nvarchar(1000),c.Comment_Text),
 	  	  	  	      Hyperlink = NULL,
 	  	  	  	  	  EventTypeId = @EventKey, 
 	  	  	  	  	  SubTypeId = 0
 	  	  	  	  	   From crew_schedule d
 	  	         Left Outer Join Comments c On c.Comment_id = d.Comment_Id
 	  	  	  	  	   Where d.PU_id = @Unit and
 	  	  	    	  	       d.Start_Time = (Select Max(Start_Time) From crew_schedule t Where t.PU_Id = @Unit and t.start_time <= @StartTime) and
 	  	  	     	       ((d.End_Time > @StartTime) or (d.End_Time is Null))
 	  	  	  	 Union
 	  	    	   Select Category = @sCrew, 
 	  	              Subcategory = NULL,
 	  	              StartTime = Case When d.Start_Time < @StartTime Then @StartTime Else d.Start_Time End,
 	  	              EndTime = coalesce(d.End_Time, @EndTime),
 	  	              ShortLabel = d.crew_desc,
 	  	              LongLabel = d.crew_desc + ' - ' + d.shift_desc,
 	  	              Color = (Select Color From Colors Where Color_Id = 1),
 	  	              HoverText = CONVERT(nvarchar(1000),c.Comment_Text),
 	  	  	  	      Hyperlink = NULL,
 	  	  	  	  	  EventTypeId = @EventKey, 
 	  	  	  	  	  SubTypeId = 0
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
  Close Event_Cursor
  Close Variable_Cursor
  Close SubType_Cursor
-- Return Report
Select Category, Subcategory,
 'StartTime'=  [dbo].[fnServer_CmnConvertFromDbTime] (StartTime,@InTimeZone)  ,
 'EndTime'=   [dbo].[fnServer_CmnConvertFromDbTime] (EndTime,@InTimeZone)  , 
ShortLabel, LongLabel, Color, Hovertext, Hyperlink
 	   From #Events
 	   Order by EventTypeId, SubTypeId, StartTime ASC 
Deallocate Event_Cursor  
Deallocate SubType_Cursor
Deallocate Variable_Cursor
Drop Table #Events
Drop Table #EventTypes
Drop Table #EventSubtypes
Drop Table #Variables
