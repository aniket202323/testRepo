Create procedure [dbo].[spASP_wrSOEListing]
@Units varchar(4000),
@StartTime datetime, 
@EndTime datetime,
@EventTypes varchar(1000) = NULL,
@EventSubTypes varchar(1500) = NULL, 
@Variables varchar(1500) = NULL,
@RootEvent int = NULL,
@InTimeZone varchar(200)=NULL --Sarla
AS 
--********************************/
Declare @RowCount int, @MaxRowCount int
Select @RowCount=0, @MaxRowCount=10000
Declare @ReportName varchar(255)
Declare @CriteriaString varchar(1000)
Declare @UnitName varchar(100)
Declare @EventTypeName varchar(50)
Declare @SQL varchar(3000)
SELECT @StartTime=[dbo].[fnServer_CmnConvertToDbTime] (@StartTime,@InTimeZone) --Sarla
SELECT @EndTime=[dbo].[fnServer_CmnConvertToDbTime] (@EndTime,@InTimeZone) --Sarla
If (@EventSubTypes = '') Select @EventSubTypes = Null
If (@Variables = '') Select @Variables = Null
--**********************************************
-- Loookup Parameters For This Report
--**********************************************
Select @ReportName = 'SOE Listing'
Create Table #Units (
  Item int,
  ItemOrder int
)
Select @SQL = 'Select PU_Id, ItemOrder = CharIndex(convert(varchar(10),PU_Id),' + '''' + @Units + '''' + ',1)  From Prod_Units Where PU_Id in ('  + @Units +  ')'
Insert Into #Units
  Exec (@SQL)
If @EventTypes = '-1' or @EventTypes Is Null
  Select @EventTypes = '4,19,1,2,3,0'
--**********************************************
-- Get Data For Report
--**********************************************
Create Table #Events (
  Item int identity(1,1),
  Category varchar(1000),
  Timestamp datetime,
  StartTime datetime NULL, 
  EndTime datetime NULL,
  ShortLabel varchar(1000) NULL,
  LongLabel varchar(1000) NULL,
  Color int, 
  Hovertext varchar(1000) NULL,
  Hyperlink varchar(1000) NULL,
  IsRoot int default(0),
  EventType int default(1),
  NextTime datetime NULL
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
Select @SQL = 'Select ET_Id, ItemOrder = CharIndex(convert(varchar(10),ET_Id),' + '''' + @EventTypes + '''' + ',1)  From Event_Types Where ET_Id in ('  + @EventTypes +  ')'
Insert Into #EventTypes
  Exec (@SQL)
If @EventSubTypes Is Not Null
  Begin
    Select @SQL = 'Select Event_Subtype_Id, ItemOrder = CharIndex(convert(varchar(10),Event_Subtype_Id),' + '''' + @EventSubTypes + '''' + ',1)  From Event_SubTypes Where Event_Subtype_Id in ('  + @EventsubTypes  + ')'
    Insert Into #EventsubTypes
      Exec (@SQL)
  End
If @Variables Is Not Null
  Begin
    Select @SQL = 'Select Var_Id, ItemOrder = CharIndex(convert(varchar(10),Var_Id),' + '''' + @Variables + '''' + ',1)  From Variables Where Var_Id in (' + @Variables +  ')'
    Insert Into #Variables
      Exec (@SQL)
  End
Declare @UnitCount int
Select @UnitCount = count(item) from #Units
Declare @@EventType int
Declare @@EventSubtypeId int
Declare @@VariableId int
Declare @@Unit int
DEclare @VariableName varchar(100)
Declare @UDEname varchar(100)
Declare @UDEtype int
Declare @DimXUnits varchar(50)
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
Fetch Next From Event_Cursor Into @@EventType
While @@Fetch_Status = 0
  Begin
    If @RootEvent Is Null Select @RootEvent = @@EventType        
    If @@EventType = 1   	    	  
      Begin
        --*******************************************************************  
        -- Production Events 
        --*******************************************************************  
  	    	    	    	  Declare Unit_Cursor Insensitive Cursor 
  	    	    	    	    For Select Item From #Units Order By ItemOrder
  	    	    	    	    For Read Only
  	    	    	    	  Open Unit_Cursor
  	    	    	    	    	    	  
  	    	    	    	  Fetch Next From Unit_Cursor Into @@Unit
  	    	    	    	  
  	    	    	    	  While @@Fetch_Status = 0 and @RowCount < @MaxRowCount
  	    	    	    	    Begin
  	    	    	    	    	    	  
  	    	    	    	      Select @UnitName = PU_Desc From Prod_Units Where PU_Id = @@Unit
  	    	    	    	  
  	    	    	    	    	    	  Select @EventTypeName = coalesce(es.event_subtype_desc, 'Event')
  	    	    	    	    	    	    From Event_Configuration ec
  	    	    	    	    	    	    Join Event_Types et on et.et_id = ec.et_id
  	    	    	    	    	    	    Left Outer Join Event_Subtypes es on es.event_subtype_id = ec.event_subtype_id 
  	    	    	    	    	    	    Where ec.PU_Id = @@Unit and 
  	    	    	    	    	    	          ec.et_id = 1
  	    	          Insert Into #Events (Category, Timestamp, StartTime, EndTime, ShortLabel, LongLabel, Color, HoverText, Hyperlink, IsRoot, EventType)
  	    	    	      	    Select Category = @EventTypeName, 
  	    	    	               Timestamp = e.Start_Time,
  	    	    	               StartTime = e.Start_Time,
  	    	    	               EndTime = e.Timestamp,
  	    	    	               ShortLabel = e.event_num,
  	    	    	               LongLabel = e.event_num + ' (' + s.ProdStatus_Desc + ')' + Case when @UnitCount > 1 Then ' on ' + @UnitName Else '' End,
  	    	    	    	    	    	    	    	    	   Color = Case  
  	    	    	    	    	    	    	    	    	    	    	         When s.Status_Valid_For_Input <> 1 Then 1 --Red
  	    	    	    	    	    	    	    	    	    	    	         When s.Count_For_Production <> 1 Then 2 -- Blue
  	    	    	    	    	    	    	    	    	    	    	         Else -1 --Black
  	    	    	    	    	    	    	    	    	    	    	       End, 
  	    	    	               HoverText = c.Comment_Text,
  	    	    	    	    	           Hyperlink = 'EventDetail.aspx?Id=' + convert(varchar(20),e.Event_Id) + '&TargetTimeZone=' + replace(@InTimeZone,' ','+'),
  	    	                 IsRoot = Case When @RootEvent = @@EventType then 1 Else 0 End,
  	    	                 EventType = @@EventType 
  	    	    	    	    	      From Events e
  	    	    	    	    	      Join Production_Status s on s.ProdStatus_id = e.Event_Status
  	    	    	    	        Left Outer Join Comments c On c.Comment_id = e.Comment_Id
  	    	    	    	    	      Where e.PU_id = @@Unit and
  	    	    	    	    	            e.Timestamp > @StartTime and 
  	    	    	    	    	            e.Timestamp <= @EndTime 
  	    	    	    	              Order By e.Timestamp ASC
  	    	    	    	    	  -- Changed
 	  	  	  	  	 Select @RowCount = @RowCount + @@RowCount
  	    	          -- Fill In Start Times If Necessary
  	    	          --If (Select Count(Item) From #Events Where Category = @EventTypeName and StartTime Is Not Null) = 0
  	    	            --Begin
  	    	              Update #Events
  	    	                Set StartTime = (Select max(Events.Timestamp) From Events Where Events.PU_Id = @@Unit and Events.Timestamp < #Events.EndTime)
  	    	                From #Events
  	    	                Where #Events.Category = @EventTypeName and 
  	    	                      #Events.StartTime Is Null  
  	    	              Update #Events
  	    	                Set Timestamp = StartTime
  	    	                From #Events
  	    	                Where #Events.Category = @EventTypeName and 
  	    	                      #Events.Timestamp Is Null  
  	    	            --End
  	    	    	    	      Fetch Next From Unit_Cursor Into @@Unit
  	    	    	    	    End
  	    	  
  	    	  
  	    	    	    	  Close Unit_Cursor
  	    	    	    	  Deallocate Unit_Cursor
        --*******************************************************************  
      End
    Else If @@EventType = 2
      Begin
        --*******************************************************************  
        -- Downtime
        --*******************************************************************  
  	    	    	    	  Declare Unit_Cursor Insensitive Cursor 
  	    	    	    	    For Select Item From #Units Order By ItemOrder
  	    	    	    	    For Read Only
  	    	    	    	  Open Unit_Cursor
  	    	    	    	    	    	  
  	    	    	    	  Fetch Next From Unit_Cursor Into @@Unit
  	    	    	    	  
  	    	    	    	  While @@Fetch_Status = 0 and @RowCount < @MaxRowCount
  	    	    	    	    Begin
  	    	    	    	      Select @UnitName = PU_Desc From Prod_Units Where PU_Id = @@Unit
  	    	          Insert Into #Events (Category, Timestamp, StartTime, EndTime, ShortLabel, LongLabel, Color, HoverText, Hyperlink, IsRoot, EventType)
  	    	    	    	      	    Select Category = 'Downtime', 
  	    	    	    	               Timestamp = Case When d.Start_Time < @StartTime Then @StartTime Else d.Start_Time End,
  	    	    	    	               StartTime = d.Start_Time,
  	    	    	    	               EndTime = coalesce(d.End_Time, getdate()),
  	    	    	    	               ShortLabel = coalesce('(' + tef.tefault_name + ')', coalesce(r1.event_reason_name,'*Unspecified*')),
  	    	    	    	               LongLabel = convert(varchar(25),convert(decimal(10,2),datediff(second,d.start_time, coalesce(d.end_time,getdate())) / 60.0)) + ' minutes for ' + coalesce(r1.event_reason_name,'*Unspecified*')  + coalesce(',' + r2.event_reason_name,'') + coalesce(' (' + tef.tefault_name + ')','') + Case when @UnitCount > 1 Then ' on ' + @UnitName Else '' End,
  	    	    	    	               Color = Case when d.reason_level1 Is Null Then 1 Else -1 End,
  	    	    	    	               HoverText = NULL,
  	    	    	    	    	    	           Hyperlink = 'DowntimeDetail.aspx?Id=' + convert(varchar(20),d.tedet_Id)+ '&TargetTimeZone=' + replace(@InTimeZone,' ','+'),
  	    	    	                 IsRoot = Case When @RootEvent = @@EventType then 1 Else 0 End,
  	    	    	                 EventType = @@EventType 
  	    	    	    	    	      	    	  From Timed_Event_Details d
  	    	    	    	          Left Outer Join Event_Reasons r1 on r1.event_reason_id = d.reason_level1
  	    	    	    	          Left Outer Join Event_Reasons r2 on r2.event_reason_id = d.reason_level2
  	    	    	    	          Left Outer Join Timed_Event_Fault tef on tef.tefault_id = d.tefault_id
  	    	    	    	    	    	    	    Where d.PU_id = @@Unit and
  	    	    	    	    	      	    	        d.Start_Time = (Select Max(Start_Time) From Timed_Event_Details t Where t.PU_Id = @@Unit and t.start_time < @StartTime) and
  	    	    	    	    	      	        ((d.End_Time > @StartTime) or (d.End_Time is Null))
  	    	     	    	    	    	  Union
  	    	    	    	    	      	    Select Category = 'Downtime', 
  	    	      	    	               Timestamp = Case When d.Start_Time < @StartTime Then @StartTime Else d.Start_Time End,
  	    	    	    	                 StartTime = d.Start_Time,
  	    	    	    	                 EndTime = coalesce(d.End_Time, getdate()),
  	    	    	    	                 ShortLabel = coalesce('(' + tef.tefault_name + ')', coalesce(r1.event_reason_name,'*Unspecified*')),
  	    	    	    	                 LongLabel = convert(varchar(25),convert(decimal(10,2),datediff(second,d.start_time, coalesce(d.end_time,getdate())) / 60.0)) + ' minutes for ' + coalesce(r1.event_reason_name,'*Unspecified*')  + coalesce(',' + r2.event_reason_name,'') + coalesce(' (' + tef.tefault_name + ')','') + Case when @UnitCount > 1 Then ' on ' + @UnitName Else '' End,
  	    	    	    	                 Color = Case when d.reason_level1 Is Null Then 1 Else -1 End,
  	    	    	    	                 HoverText = NULL,
  	    	    	    	    	    	    	           Hyperlink = 'DowntimeDetail.aspx?Id=' + convert(varchar(20),d.tedet_Id)+ '&TargetTimeZone=' + replace(@InTimeZone,' ','+'),
  	    	    	    	                 IsRoot = Case When @RootEvent = @@EventType then 1 Else 0 End,
  	    	    	    	                 EventType = @@EventType 
  	    	    	    	    	    	    	    	    From Timed_Event_Details d
  	    	    	    	            Left Outer Join Event_Reasons r1 on r1.event_reason_id = d.reason_level1
  	    	    	    	            Left Outer Join Event_Reasons r2 on r2.event_reason_id = d.reason_level2
  	    	    	    	            Left Outer Join Timed_Event_Fault tef on tef.tefault_id = d.tefault_id
  	    	    	    	            Where d.PU_id = @@Unit and
  	    	    	    	                  d.Start_Time >  @StartTime and 
  	    	    	    	    	        	    	   d.Start_Time <= @EndTime 
  	    	    	    	         Order by StartTime 
  	    	    	    	    	    -- Changed
 	  	  	  	  	  Select @RowCount = @RowCount + @@RowCount
  	    	    	    	      Fetch Next From Unit_Cursor Into @@Unit
  	    	    	    	    End
  	    	  
  	    	  
  	    	    	    	  Close Unit_Cursor
  	    	    	    	  Deallocate Unit_Cursor
        --*******************************************************************  
      End
    Else If @@EventType = 3 
      Begin
        --*******************************************************************  
        -- Waste
        --*******************************************************************  
  	    	    	    	  Declare Unit_Cursor Insensitive Cursor 
  	    	    	    	    For Select Item From #Units Order By ItemOrder
  	    	    	    	    For Read Only
  	    	    	    	  Open Unit_Cursor
  	    	    	    	    	    	  
  	    	    	    	  Fetch Next From Unit_Cursor Into @@Unit
  	    	    	    	  
  	    	    	    	  While @@Fetch_Status = 0 and @RowCount < @MaxRowCount
  	    	    	    	    Begin
  	    	    	    	      Select @UnitName = PU_Desc From Prod_Units Where PU_Id = @@Unit
  	    	    	    	    	    	  Select @DimXUnits = coalesce(es.dimension_x_eng_units, 'units')
  	    	    	    	    	    	    From Event_Configuration ec
  	    	    	    	    	    	    Join Event_Types et on et.et_id = ec.et_id
  	    	    	    	    	    	    Left Outer Join Event_Subtypes es on es.event_subtype_id = ec.event_subtype_id 
  	    	    	    	    	    	    Where ec.PU_Id = @@Unit and 
  	    	    	    	    	    	          ec.et_id = 1
  	    	          Insert Into #Events (Category, Timestamp, StartTime, EndTime, ShortLabel, LongLabel, Color, HoverText, Hyperlink, IsRoot, EventType)
  	    	    	    	      	    Select Category = 'Waste', 
  	    	    	    	               Timestamp = d.Timestamp,
  	    	    	    	               StartTime = d.Timestamp,
  	    	    	    	               EndTime = d.Timestamp,
  	    	    	    	               ShortLabel = coalesce('(' + wef.wefault_name + ')', coalesce(r1.event_reason_name,'*Unspecified*')),
 	  	  	  	  	  	  	   LongLabel = convert(varchar(25),convert(decimal(10,2),d.amount)) + ' ' + Coalesce(wem.wemt_name, 'units') + ' for ' + coalesce(r1.event_reason_name,'*Unspecified*')  + coalesce(',' + r2.event_reason_name,'') + coalesce(' (' + wef.wefault_name + ')','') + Case when @UnitCount > 1 Then ' on ' + @UnitName Else '' End,
  	    	    	    	               Color = Case when d.reason_level1 Is Null Then 1 Else -1 End,
  	    	    	    	               HoverText = NULL,
  	    	    	    	    	    	           Hyperlink = 'WasteDetail.aspx?Id=' + convert(varchar(20),d.wed_Id)+ '&TargetTimeZone=' + replace(@InTimeZone,' ','+'),
  	    	    	                 IsRoot = Case When @RootEvent = @@EventType then 1 Else 0 End,
  	    	    	                 EventType = @@EventType 
  	    	    	    	    	    	    	    From Waste_Event_Details d
  	    	    	    	          Left Outer Join Event_Reasons r1 on r1.event_reason_id = d.reason_level1
  	    	    	    	          Left Outer Join Event_Reasons r2 on r2.event_reason_id = d.reason_level2
  	    	    	    	          Left Outer Join Waste_Event_Fault wef on wef.wefault_id = d.wefault_id
 	  	  	  	  	  	  Left Outer Join Waste_Event_Meas wem on wem.wemt_id = d.wemt_Id
  	    	    	    	    	    	    	    Where d.PU_id = @@Unit and
  	    	    	    	    	      	    	        d.Timestamp >= @StartTime and 
  	    	    	    	                  	    	   d.Timestamp < @EndTime and
  	    	    	    	                  	    	   d.Event_Id Is Null
  	    	    	    	    	    	  Union
  	    	    	    	      	    Select Category = 'Waste', 
  	    	    	    	               Timestamp = d.Timestamp,
  	    	    	    	               StartTime = e.Timestamp,
  	    	    	    	               EndTime = e.Timestamp,
  	    	    	    	               ShortLabel = coalesce('(' + wef.wefault_name + ')', coalesce(r1.event_reason_name,'*Unspecified*')),
 	  	  	  	  	  	  	   LongLabel = convert(varchar(25),convert(decimal(10,2),d.amount)) + ' ' + Coalesce(wem.wemt_name, 'units') + ' for ' + coalesce(r1.event_reason_name,'*Unspecified*')  + coalesce(',' + r2.event_reason_name,'') + coalesce(' (' + wef.wefault_name + ')','') + Case when @UnitCount > 1 Then ' on ' + @UnitName Else '' End,
  	    	    	    	               Color = Case when d.reason_level1 Is Null Then 1 Else -1 End,
  	    	    	    	               HoverText = NULL,
  	    	    	    	    	    	           Hyperlink = 'WasteDetail.aspx?Id=' + convert(varchar(20),d.wed_Id)+ '&TargetTimeZone=' + replace(@InTimeZone,' ','+'),
  	    	    	                 IsRoot = Case When @RootEvent = @@EventType then 1 Else 0 End,
  	    	    	                 EventType = @@EventType 
  	    	    	    	    	    	    	  From Events e
  	    	    	    	    	      	    	  Join Waste_Event_Details d on d.event_id = e.event_id
  	    	    	    	          Left Outer Join Event_Reasons r1 on r1.event_reason_id = d.reason_level1
  	    	    	    	          Left Outer Join Event_Reasons r2 on r2.event_reason_id = d.reason_level2
  	    	    	    	          Left Outer Join Waste_Event_Fault wef on wef.wefault_id = d.wefault_id
 	  	  	  	  	  	  Left Outer Join Waste_Event_Meas wem on wem.wemt_id = d.wemt_Id
  	    	    	    	          Where e.PU_id = @@Unit and
  	    	    	    	    	    	    	          e.Timestamp >  @StartTime and 
  	    	    	    	    	    	    	          e.Timestamp <= @EndTime 
  	    	    	    	      Order by StartTime 
 	  	  	  	  	 Select @RowCount = @RowCount + @@RowCount
  	    	    	    	    	  -- Changed
  	    	    	    	      Fetch Next From Unit_Cursor Into @@Unit
  	    	    	    	    End
  	    	  
  	    	  
  	    	    	    	  Close Unit_Cursor
  	    	    	    	  Deallocate Unit_Cursor
        --*******************************************************************  
      End
    Else If @@EventType = 4    	  
      Begin
        --*******************************************************************  
        -- Product Change
        --*******************************************************************  
  	    	    	    	  Declare Unit_Cursor Insensitive Cursor 
  	    	    	    	    For Select Item From #Units Order By ItemOrder
  	    	    	    	    For Read Only
  	    	    	    	  Open Unit_Cursor
  	    	    	    	    	    	  
  	    	    	    	  Fetch Next From Unit_Cursor Into @@Unit
  	    	    	    	  
  	    	    	    	  While @@Fetch_Status = 0 and @RowCount < @MaxRowcount
  	    	    	    	    Begin
  	    	    	    	      Select @UnitName = PU_Desc From Prod_Units Where PU_Id = @@Unit
  	    	          Insert Into #Events (Category, Timestamp, StartTime, EndTime, ShortLabel, LongLabel, Color, HoverText, Hyperlink, IsRoot, EventType)
  	    	    	    	      	    Select Category = 'Product', 
  	    	    	    	               Timestamp = Case When d.Start_Time < @StartTime Then @StartTime Else d.Start_Time End,
  	    	    	    	               StartTime = d.Start_Time,
  	    	    	    	               EndTime = coalesce(d.End_Time, @EndTime),
  	    	    	    	               ShortLabel = p.Prod_code,
  	    	    	    	               LongLabel = p.prod_code + ' - ' + p.prod_desc + Case when @UnitCount > 1 Then ' on ' + @UnitName Else '' End,
  	    	    	    	               Color = -1,
  	    	    	    	               HoverText = convert(varchar(100),c.Comment_Text),
  	    	    	    	    	    	     --Hyperlink = 'ProductChangeDetail.aspx?Id=' + convert(varchar(20),d.start_Id),
  	    	    	    	    	    	     Hyperlink = '',
  	    	    	                 IsRoot = Case When @RootEvent = @@EventType then 1 Else 0 End,
  	    	    	                 EventType = @@EventType 
  	    	    	    	    	    	    	    From Production_Starts d
  	    	    	    	          Join Products p on p.prod_id = d.prod_id
  	    	    	    	          Left Outer Join Comments c On c.Comment_id = d.Comment_Id
  	    	    	    	    	    	    	    Where d.PU_id = @@Unit and
  	    	    	    	    	      	    	        d.Start_Time = (Select Max(Start_Time) From Production_Starts t Where t.PU_Id = @@Unit and t.start_time < @StartTime) and
  	    	    	    	    	       	        ((d.End_Time > @StartTime) or (d.End_Time is Null))
  	    	    	    	    	    	  Union
  	    	    	    	      	    Select Category = 'Product', 
  	    	    	    	               Timestamp = Case When d.Start_Time < @StartTime Then @StartTime Else d.Start_Time End,
  	    	    	    	               StartTime = d.Start_Time,
  	    	    	    	               EndTime = coalesce(d.End_Time, @EndTime),
  	    	    	    	               ShortLabel = p.Prod_code,
  	    	    	    	               LongLabel = p.prod_code + ' - ' + p.prod_desc + Case when @UnitCount > 1 Then ' on ' + @UnitName Else '' End,
  	    	    	    	               Color = -1,
  	    	    	    	               HoverText = convert(varchar(100),c.Comment_Text),
  	    	    	    	    	    	     --Hyperlink = 'ProductChangeDetail.aspx?Id=' + convert(varchar(20),d.start_Id),
  	    	    	    	    	    	     HyperLink = '',
  	    	    	                 IsRoot = Case When @RootEvent = @@EventType then 1 Else 0 End,
  	    	    	                 EventType = @@EventType 
  	    	    	     	    	    From Production_Starts d
  	    	    	    	        Join Products p on p.prod_id = d.prod_id
  	    	    	    	        Left Outer Join Comments c On c.Comment_id = d.Comment_Id
  	    	    	    	        Where d.PU_id = @@Unit and
  	    	    	    	              d.Start_Time > @StartTime and 
  	    	    	    	            	    d.Start_Time <= @EndTime 
  	    	    	    	       Order by StartTime 
  	    	    	    	    	  -- Changed
 	  	  	  	  	  	 Select @RowCount = @RowCount + @@RowCount
  	    	    	    	      Fetch Next From Unit_Cursor Into @@Unit
  	    	    	    	    End
  	    	  
  	    	  
  	    	    	    	  Close Unit_Cursor
  	    	    	    	  Deallocate Unit_Cursor
        --*******************************************************************  
      End
    Else If @@EventType = 11 
      Begin
        --*******************************************************************  
        -- Alarms
        --*******************************************************************  
        -- Get The Next Variable In The List  
        Fetch Next From Variable_Cursor Into @@VariableId
        While @@Fetch_Status = 0 and @RowCount < @MaxRowCount
          Begin
            Select @VariableName = Var_Desc From Variables Where Var_id = @@VariableId
  	    	          Insert Into #Events (Category, Timestamp, StartTime, EndTime, ShortLabel, LongLabel, Color, HoverText, Hyperlink, IsRoot, EventType)
  	      	    	      	    Select Category = @VariableName, 
  	                   Timestamp = Case When d.Start_Time < @StartTime Then @StartTime Else dateadd(second,-1,d.Start_Time) End,
  	                   StartTime = d.Start_Time,
  	                   EndTime = coalesce(d.End_Time, @EndTime),
  	                   ShortLabel = coalesce(r1.event_reason_name,'*Unspecified*'),
  	                   LongLabel = d.alarm_desc,
  	                   Color = Case when d.ack Is Null or d.ack = 0 Then 1 Else -1 End,
  	    	    	   HoverText = convert(varchar(100),c.Comment_Text),
  	    	    	    	    	           Hyperlink = 'AlarmDetail.aspx?Id=' + convert(varchar(20),d.Alarm_Id)+ '&TargetTimeZone=' + replace(@InTimeZone,' ','+'),
  	    	                 IsRoot = Case When @RootEvent = @@EventType then 1 Else 0 End,
  	    	                 EventType = @@EventType 
  	    	    	    	    	    	    From Alarms d
  	    	            Left Outer Join Event_Reasons r1 on r1.event_reason_id = d.cause1
              Left Outer Join Comments c On c.Comment_id = d.Cause_Comment_Id
  	    	    	    	    	    	    Where d.Key_Id = @@VariableId and
                    d.Alarm_Type_Id in (1,2) and 
  	    	    	      	    	          d.Start_Time = (Select Max(Start_Time) From Alarms t Where t.Key_Id = @@VariableId and t.Alarm_Type_Id in (1,2) and t.start_time < @StartTime) and
  	    	    	    	     	          ((d.End_Time > @StartTime) or (d.End_Time is Null))
  	           Union
  	      	    	      	    Select Category = @VariableName, 
  	                   Timestamp = Case When d.Start_Time < @StartTime Then @StartTime Else dateadd(second,-1,d.Start_Time) End,
  	                   StartTime = d.Start_Time,
  	                   EndTime = coalesce(d.End_Time, @EndTime),
  	                   ShortLabel = coalesce(r1.event_reason_name,'*Unspecified*'),
  	                   LongLabel = d.alarm_desc,
  	                   Color = Case when d.ack Is Null or d.ack = 0 Then 1 Else -1 End,
  	    	    	   HoverText = convert(varchar(100),c.Comment_Text),
  	    	    	    	    	           Hyperlink = 'AlarmDetail.aspx?Id=' + convert(varchar(20),d.Alarm_Id) + '&TargetTimeZone=' + replace(@InTimeZone,' ','+'),
  	    	                 IsRoot = Case When @RootEvent = @@EventType then 1 Else 0 End,
  	    	                 EventType = @@EventType 
  	    	    	    	    	    	    From Alarms d
  	    	            Left Outer Join Event_Reasons r1 on r1.event_reason_id = d.cause1
                	    	  Left Outer Join Comments c On c.Comment_id = d.Cause_Comment_Id
  	    	    	    	    	    	    Where d.Key_Id = @@VariableId and
                      	    	    	  d.Alarm_Type_Id in (1,2) and 
  	    	    	                  	    	  d.Start_Time >  @StartTime and 
  	    	    	    	            	    	  d.Start_Time <= @EndTime 
  	    	    	       Order by StartTime 
 	  	  	  	 Select @RowCount = @RowCount + @@RowCount
 	  	  	  	 Fetch Next From Variable_Cursor Into @@VariableId
  	    	    	    	  -- Changed
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
 	  	  	 While @@Fetch_Status = 0 and @RowCount < @MaxRowCount
 	  	  	  	 Begin
 	  	  	  	  	 Select @UDEName = event_subtype_desc, @UDEType = duration_required From Event_Subtypes Where event_subtype_id = @@EventSubtypeId
 	  	  	  	  	 Declare Unit_Cursor Insensitive Cursor 
 	  	  	  	  	 For Select Item From #Units Order By ItemOrder
 	  	  	  	  	 For Read Only
 	  	  	  	  	 Open Unit_Cursor
  	    	    	    	    	    	    	    	  
 	  	  	  	  	 Fetch Next From Unit_Cursor Into @@Unit
  	    	    	    	    	    	  
 	  	  	  	  	 While @@Fetch_Status = 0 and @RowCount < @MaxRowCount
 	  	  	  	  	  	 Begin  	    	  
 	  	  	  	  	  	  	 Select @UnitName = PU_Desc From Prod_Units Where PU_Id = @@Unit
 	  	  	  	  	  	  	 If @UDEType = 1 
 	  	  	  	  	  	  	  	 Begin
  	    	  	  	  	  	  	  	  	 -- Both Start and End Times Apply  	    	  
 	  	  	  	  	  	  	  	  	 Insert Into #Events (Category, Timestamp, StartTime, EndTime, ShortLabel, LongLabel, Color, HoverText, Hyperlink, IsRoot, EventType)
 	  	  	  	  	  	  	  	  	  	 Select Category = @UDEName, 
 	  	  	  	  	  	  	  	  	  	  	 Timestamp = Case When d.Start_Time < @StartTime Then @StartTime Else d.Start_Time End,
 	  	  	  	  	  	  	  	  	  	  	 StartTime = d.Start_Time,
 	  	  	  	  	  	  	  	  	  	  	 EndTime = coalesce(d.End_Time, getdate()),
 	  	  	  	  	  	  	  	  	  	  	 ShortLabel = coalesce(r1.event_reason_name,'*Unspecified*'),
 	  	  	  	  	  	  	  	  	  	  	 LongLabel = d.ude_desc + convert(varchar(25),convert(decimal(10,2),datediff(second,d.start_time, coalesce(d.end_time,getdate())) / 60.0)) + ' minutes for ' + coalesce(r1.event_reason_name,'*Unspecified*')  + coalesce(',' + r2.event_reason_name,'') + Case when @UnitCount > 1 Then ' on ' + @UnitName Else '' End,
 	  	  	  	  	  	  	  	  	  	  	 Color = Case when d.cause1 Is Null or d.ack = 0 Then 1 Else -1 End,
 	  	  	  	  	  	  	  	  	  	  	 HoverText = convert(varchar(100),c.Comment_Text),
 	  	  	  	  	  	  	  	  	  	  	 Hyperlink = 'UDEDetail.aspx?Id=' + convert(varchar(20),d.UDE_Id)+ '&TargetTimeZone=' + replace(@InTimeZone,' ','+'),
 	  	  	  	  	  	  	  	  	  	  	 --Hyperlink = '',
 	  	  	  	  	  	  	  	  	  	  	 IsRoot = Case When @RootEvent = -1 * @@EventSubtypeId then 1 Else 0 End,
 	  	  	  	  	  	  	  	  	  	  	 EventType = -1 * @@EventSubtypeId 
 	  	  	  	  	  	  	  	  	  	 From User_Defined_Events d
 	  	  	  	  	  	  	  	  	  	  	 Left Outer Join Event_Reasons r1 on r1.event_reason_id = d.cause1
 	  	  	  	  	  	  	  	  	  	  	 Left Outer Join Event_Reasons r2 on r1.event_reason_id = d.cause2
 	  	  	  	  	  	  	  	  	  	  	 Left Outer Join Comments c On c.Comment_id = d.Comment_Id
 	  	  	  	  	  	  	  	  	  	 Where d.PU_Id = @@Unit and
 	  	  	  	  	  	  	  	  	  	  	 d.Event_Subtype_id = @@EventSubtypeId and
 	  	  	  	  	  	  	  	  	  	  	 d.Start_Time = (Select Max(Start_Time) From User_Defined_Events t Where t.PU_Id = @@Unit and t.Event_Subtype_id = @@EventSubtypeId and t.start_time < @StartTime) and
 	  	  	  	  	  	  	  	  	  	  	 ((d.End_Time > @StartTime) or (d.End_Time is Null))
  	    	    	    	    	  	  	  	  	   Union
 	  	  	  	  	  	  	  	  	  	 Select Category = @UDEName, 
 	  	  	  	  	  	  	  	  	  	  	 Timestamp = Case When d.Start_Time < @StartTime Then @StartTime Else d.Start_Time End,
 	  	  	  	  	  	  	  	  	  	  	 StartTime = d.Start_Time,
 	  	  	  	  	  	  	  	  	  	  	 EndTime = coalesce(d.End_Time, getdate()),
 	  	  	  	  	  	  	  	  	  	  	 ShortLabel = coalesce(r1.event_reason_name,'*Unspecified*'),
 	  	  	  	  	  	  	  	  	  	  	 LongLabel = d.ude_desc + convert(varchar(25),convert(decimal(10,2),datediff(second,d.start_time, coalesce(d.end_time,getdate())) / 60.0)) + ' minutes for ' + coalesce(r1.event_reason_name,'*Unspecified*')  + coalesce(',' + r2.event_reason_name,'') + Case when @UnitCount > 1 Then ' on ' + @UnitName Else '' End,
 	  	  	  	  	  	  	  	  	  	  	 Color = Case when d.cause1 Is Null or d.ack = 0 Then 1 Else -1 End,
 	  	  	  	  	  	  	  	  	  	  	 HoverText = convert(varchar(100),c.Comment_Text),
 	  	  	  	  	  	  	  	  	  	  	 Hyperlink = 'UDEDetail.aspx?Id=' + convert(varchar(20),d.UDE_Id)+ '&TargetTimeZone=' + replace(@InTimeZone,' ','+'),
 	  	  	  	  	  	  	  	  	  	  	 --Hyperlink = '',
 	  	  	  	  	  	  	  	  	  	  	 IsRoot = Case When @RootEvent = -1 * @@EventSubtypeId then 1 Else 0 End,
 	  	  	  	  	  	  	  	  	  	  	 EventType = -1 * @@EventSubtypeId 
 	  	  	  	  	  	  	  	  	  	 From User_Defined_Events d
 	  	  	  	  	  	  	  	  	  	  	 Left Outer Join Event_Reasons r1 on r1.event_reason_id = d.cause1
 	  	  	  	  	  	  	  	  	  	  	 Left Outer Join Event_Reasons r2 on r1.event_reason_id = d.cause2
 	  	  	  	  	  	  	  	  	  	  	 Left Outer Join Comments c On c.Comment_id = d.Cause_Comment_Id
 	  	  	  	  	  	  	  	  	  	 Where d.PU_Id = @@Unit and
 	  	  	  	  	  	  	  	  	  	  	 d.Event_Subtype_id = @@EventSubtypeId and
 	  	  	  	  	  	  	  	  	  	  	 d.Start_Time > @StartTime and 
 	  	  	  	  	  	  	  	  	  	  	 d.Start_Time <= @EndTime 
 	  	  	  	  	  	  	  	  	  	 Order by StartTime 
 	  	  	  	  	  	  	  	  	  	 Select @RowCount = @RowCount + @@RowCount
  	    	    	    	    	    	    	    	  	  	  -- Changed
 	  	   	    	    	    	    	  	 End -- @UDEType = 1  Both Start and End Times Apply
 	  	  	  	  	  	  	 Else
  	    	    	    	    	    	  	  	 Begin
  	    	  	  	  	  	  	  	  	 -- Only Start Time Applies
 	  	  	  	  	  	  	  	  	 Insert Into #Events (Category, Timestamp, StartTime, EndTime, ShortLabel, LongLabel, Color, HoverText, Hyperlink, IsRoot, EventType)
 	  	  	  	  	  	  	  	  	  	 Select Category = @UDEName, 
 	  	  	  	  	  	  	  	  	  	  	 Timestamp = d.Start_time,
 	  	  	  	  	  	  	  	  	  	  	 StartTime = d.Start_time,
 	  	  	  	  	  	  	  	  	  	  	 EndTime = d.Start_Time,
 	  	  	  	  	  	  	  	  	  	  	 ShortLabel = coalesce(r1.event_reason_name,'*Unspecified*'),
 	  	  	  	  	  	  	  	  	  	  	 LongLabel = d.ude_desc + ' for ' + coalesce(r1.event_reason_name,'*Unspecified*')  + coalesce(',' + r2.event_reason_name,'') + Case when @UnitCount > 1 Then ' on ' + @UnitName Else '' End,
 	  	  	  	  	  	  	  	  	  	  	 Color = Case when d.cause1 Is Null or d.ack = 0 Then 1 Else -1 End,
 	  	  	  	  	  	  	  	  	  	  	 HoverText = c.Comment_Text,
 	  	  	  	  	  	  	  	  	  	  	 Hyperlink = 'UDEDetail.aspx?Id=' + convert(varchar(20),d.UDE_Id) + '&TargetTimeZone=' + replace(@InTimeZone,' ','+'),
 	  	  	  	  	  	  	  	  	  	  	 --Hyperlink = '',
 	  	  	  	  	  	  	  	  	  	  	 IsRoot = Case When @RootEvent = -1 * @@EventSubtypeId then 1 Else 0 End,
 	  	  	  	  	  	  	  	  	  	  	 EventType = -1 * @@EventSubtypeId 
 	  	  	  	  	  	  	  	  	  	 From User_Defined_Events d
 	  	  	  	  	  	  	  	  	  	  	 Left Outer Join Event_Reasons r1 on r1.event_reason_id = d.cause1
 	  	  	  	  	  	  	  	  	  	  	 Left Outer Join Event_Reasons r2 on r1.event_reason_id = d.cause2
 	  	  	  	  	  	  	  	  	  	  	 Left Outer Join Comments c On c.Comment_id = d.Cause_Comment_Id
 	  	  	  	  	  	  	  	  	  	 Where d.PU_Id = @@Unit and
 	  	  	  	  	  	  	  	  	  	  	 d.Event_Subtype_id = @@EventSubtypeId and
 	  	  	  	  	  	  	  	  	  	  	 d.Start_Time >  @StartTime and 
 	  	  	  	  	  	  	  	  	  	  	 d.Start_Time <= @EndTime 
 	  	  	  	  	  	  	  	  	  	 Order by StartTime 
 	  	  	  	  	  	  	  	  	 Select @RowCount = @RowCount + @@RowCount
 	  	  	  	  	  	  	  	  	  	 -- Changed
 	  	  	  	  	  	  	  	 End
 	  	  	  	  	  	  	 Fetch Next From Unit_Cursor Into @@Unit
 	  	  	  	  	  	 End -- While @@Fetch_Status = 0 In Unit_Cursor
 	  	  	  	  	 Close Unit_Cursor
 	  	  	  	  	 Deallocate Unit_Cursor
 	  	  	  	  	 Fetch Next From SubType_Cursor Into @@EventSubtypeId
  	    	  	  	 End -- If @@Fetch_Status = 0 in SubType_Cursor
        --*******************************************************************  
      End
    Else If @@EventType = 19 
      Begin
        --*******************************************************************  
        -- Process Orders
        --*******************************************************************  
  	    	    	    	  Declare Unit_Cursor Insensitive Cursor 
  	    	    	    	    For Select Item From #Units Order By ItemOrder
  	    	    	    	    For Read Only
  	    	    	    	  Open Unit_Cursor
  	    	    	    	    	    	  
  	    	    	    	  Fetch Next From Unit_Cursor Into @@Unit
  	    	    	    	  
  	    	    	    	  While @@Fetch_Status = 0 and @RowCount < @MaxRowCount
  	    	    	    	    Begin
  	    	    	    	      Select @UnitName = PU_Desc From Prod_Units Where PU_Id = @@Unit
  	    	          Insert Into #Events (Category, Timestamp, StartTime, EndTime, ShortLabel, LongLabel, Color, HoverText, Hyperlink, IsRoot, EventType)
  	    	    	    	      	    Select Category = 'Process Orders', 
  	    	    	    	               Timestamp = Case When d.Start_Time < @StartTime Then @StartTime Else d.Start_Time End,
  	    	    	    	               StartTime = d.Start_Time,
  	    	    	    	               EndTime = coalesce(d.End_Time, @EndTime),
  	    	    	    	               ShortLabel = pp.Process_Order,
  	    	    	    	               LongLabel = pp.Process_Order + ' (' +  s.pp_status_desc + ')' + ' - ' + p.prod_code + Case when @UnitCount > 1 Then ' on ' + @UnitName Else '' End,
  	    	    	    	               Color = -1,
  	    	    	    	               HoverText = convert(varchar(1000),c.Comment_Text),
  	    	    	    	    	    	           Hyperlink = 'ProcessOrderDetail.aspx?Id=' + convert(varchar(20),pp.pp_Id) + '&TargetTimeZone=' + replace(@InTimeZone,' ','+'),
  	    	    	                 IsRoot = Case When @RootEvent = @@EventType then 1 Else 0 End,
  	    	    	                 EventType = @@EventType 
  	    	    	    	    	    	    	    From Production_Plan_Starts d
  	    	    	            Join Production_Plan pp on pp.pp_id = d.pp_id
  	    	    	            Join production_plan_statuses s on s.pp_status_id = pp.pp_status_id
  	    	    	    	          Join Products p on p.prod_id = pp.prod_id
  	    	    	    	          Left Outer Join Comments c On c.Comment_id = d.Comment_Id
  	    	    	    	    	    	    	    Where d.PU_id = @@Unit and
  	    	    	    	    	      	    	        d.Start_Time = (Select Max(Start_Time) From Production_Plan_Starts t Where t.PU_Id = @@Unit and t.start_time < @StartTime) and
  	    	    	    	    	       	        ((d.End_Time > @StartTime) or (d.End_Time is Null))
  	    	    	    	    	    	  Union
  	    	    	    	      	    Select Category = 'Process Orders', 
  	    	    	    	               Timestamp = Case When d.Start_Time < @StartTime Then @StartTime Else d.Start_Time End,
  	    	    	    	               StartTime = d.Start_Time,
  	    	    	    	               EndTime = coalesce(d.End_Time, @EndTime),
  	    	    	    	               ShortLabel = pp.Process_Order,
  	    	    	    	               LongLabel = pp.Process_Order + ' (' +  s.pp_status_desc + ')' + ' - ' + p.prod_code + Case when @UnitCount > 1 Then ' on ' + @UnitName Else '' End,
  	    	    	    	               Color = -1,
  	    	    	    	               HoverText = convert(varchar(1000),c.Comment_Text),
  	    	    	    	    	    	           Hyperlink = 'ProcessOrderDetail.aspx?Id=' + convert(varchar(20),pp.pp_Id)+ '&TargetTimeZone=' + replace(@InTimeZone,' ','+') ,
  	    	    	                 IsRoot = Case When @RootEvent = @@EventType then 1 Else 0 End,
  	    	    	                 EventType = @@EventType 
  	    	    	    	    	    	    	    From Production_Plan_Starts d
  	    	    	            Join Production_Plan pp on pp.pp_id = d.pp_id
  	    	    	            Join production_plan_statuses s on s.pp_status_id = pp.pp_status_id
  	    	    	    	          Join Products p on p.prod_id = pp.prod_id
  	    	    	    	          Left Outer Join Comments c On c.Comment_id = d.Comment_Id
  	    	    	    	    	        Where d.PU_id = @@Unit and
  	    	    	    	    	              d.Start_Time > @StartTime and 
  	    	    	    	    	    	         d.Start_Time <= @EndTime 
  	    	    	    	    	     Order by StartTime 
  	    	    	    	    	    	  -- Changed
 	  	  	  	  	  	 Select @RowCount = @RowCount + @@RowCount
  	    	    	    	      Fetch Next From Unit_Cursor Into @@Unit
  	    	    	    	    End
  	    	  
  	    	  
  	    	    	    	  Close Unit_Cursor
  	    	    	    	  Deallocate Unit_Cursor
  	    	  
        --*******************************************************************  
      End
    Else If @@EventType = 0    	  -- Time / Crew Schedule
      Begin
 	  	  	 
        --*******************************************************************  
        -- Crew Schedule
        --*******************************************************************  
 	  	  	 
  	    	    	    	  Declare Unit_Cursor Insensitive Cursor 
  	    	    	    	    For Select Item From #Units Order By ItemOrder
  	    	    	    	    For Read Only
  	    	    	    	  Open Unit_Cursor
  	    	    	    	    	    	  
  	    	    	    	  Fetch Next From Unit_Cursor Into @@Unit
  	    	    	    	  
  	    	    	    	  While @@Fetch_Status = 0 and @RowCount < @MaxRowCount
  	    	    	    	    Begin
  	    	    	    	      Select @UnitName = PU_Desc From Prod_Units Where PU_Id = @@Unit
  	    	          Insert Into #Events (Category, Timestamp, StartTime, EndTime, ShortLabel, LongLabel, Color, HoverText, Hyperlink, IsRoot, EventType)
  	    	    	    	      	    Select Category = 'Crew', 
  	    	    	    	               Timestamp = Case When d.Start_Time < @StartTime Then @StartTime Else d.Start_Time End,
  	    	    	    	               StartTime = d.Start_Time,
  	    	    	    	               EndTime = coalesce(d.End_Time, @EndTime),
  	    	    	    	               ShortLabel = d.crew_desc,
  	    	    	    	               LongLabel = d.crew_desc + ' Crew - ' + d.shift_desc + ' Shift' + Case when @UnitCount > 1 Then ' on ' + @UnitName Else '' End,
  	    	    	    	               Color = -1,
  	    	    	    	               HoverText = convert(varchar(1000),c.Comment_Text),
  	    	    	    	    	    	           Hyperlink = NULL,
  	    	    	                 IsRoot = Case When @RootEvent = @@EventType then 1 Else 0 End,
  	    	    	                 EventType = @@EventType 
  	    	    	    	    	    	    	    From crew_schedule d
  	    	    	    	          Left Outer Join Comments c On c.Comment_id = d.Comment_Id
  	    	    	    	    	    	    	    Where d.PU_id = @@Unit and
  	    	    	    	    	      	    	        d.Start_Time = (Select Max(Start_Time) From crew_schedule t Where t.PU_Id = @@Unit and t.start_time <= @StartTime) and
  	    	    	    	    	       	        ((d.End_Time > @StartTime) or (d.End_Time is Null))
  	    	    	    	    	    	  Union
  	    	    	    	      	    Select Category = 'Crew', 
  	    	    	    	               Timestamp = Case When d.Start_Time < @StartTime Then @StartTime Else d.Start_Time End,
  	    	    	    	               StartTime = d.Start_Time,
  	    	    	    	               EndTime = coalesce(d.End_Time, @EndTime),
  	    	    	    	               ShortLabel = d.crew_desc,
  	    	    	    	               LongLabel = d.crew_desc + ' Crew - ' + d.shift_desc + ' Shift' + Case when @UnitCount > 1 Then ' on ' + @UnitName Else '' End,
  	    	    	    	               Color = -1,
  	    	    	    	               HoverText = convert(varchar(1000),c.Comment_Text),
  	    	    	    	    	    	           Hyperlink = NULL,
  	    	    	                 IsRoot = Case When @RootEvent = @@EventType then 1 Else 0 End,
  	    	    	                 EventType = @@EventType 
  	    	    	    	    	    	    	    From crew_schedule d
  	    	    	    	          Left Outer Join Comments c On c.Comment_id = d.Comment_Id
  	    	    	    	    	        Where d.PU_id = @@Unit and
  	    	    	    	    	              d.Start_Time > @StartTime and 
  	    	    	    	    	    	            	  d.Start_Time < @EndTime 
  	    	    	    	    	     Order by StartTime 
  	    	    	    	    	    	  -- Changed
 	  	  	  	  	  	 Select @RowCount = @RowCount + @@RowCount
  	    	    	    	      Fetch Next From Unit_Cursor Into @@Unit
  	    	    	    	    End
  	    	  	  	  	 
  	    	  
  	    	    	    	  Close Unit_Cursor
  	    	    	    	  Deallocate Unit_Cursor
       End
        --*******************************************************************  
    Fetch Next From Event_Cursor Into @@EventType
  End
Close Event_Cursor
Close SubType_Cursor
Close Variable_Cursor
Deallocate Event_Cursor  
Deallocate SubType_Cursor
Deallocate Variable_Cursor
--**********************************************
-- Update Root Times 
--**********************************************
Declare @@Item int
Declare @@ThisTime datetime
Declare @LastTime datetime
Select @LastTime = @EndTime
Declare Time_Cursor Insensitive Cursor 
  	  For Select Item, Timestamp From #Events Where IsRoot = 1 Order By Timestamp DESC
  	  For Read Only
Open Time_Cursor
Fetch Next From Time_Cursor Into @@Item, @@ThisTime   
While @@Fetch_Status = 0
  Begin
    Update #Events Set NextTime = @LastTime Where Item = @@Item
    Select @LastTime = @@ThisTime
  	    	  Fetch Next From Time_Cursor Into @@Item, @@ThisTime   
  End
Close Time_Cursor
Deallocate Time_Cursor
--**********************************************
-- Return Header Information
--**********************************************
-- Line1: Report Name
-- Line2: Criteria
-- Line3: Generate Time
-- Line4 - n: Column Names
Create Table #Prompts (
  PromptId int identity(1,1),
  PromptName varchar(20),
  PromptValue varchar(1000)
)
Insert into #Prompts (PromptName, PromptValue) Values ('ReportName', @ReportName)
Select @CriteriaString = 'Sequence Of Events'
Select @CriteriaString = @CriteriaString + ' From [' + convert(varchar(25), [dbo].[fnServer_CmnConvertFromDbTime] (@StartTime,@InTimeZone),120) + '] To [' + convert(varchar(25),[dbo].[fnServer_CmnConvertFromDbTime] (@EndTime,@InTimeZone) ,120) + ']'
If @RowCount > @MaxRowCount
 	 Select @CriteriaString = @CriteriaString + ' ** Maximum Report Data Limit Exceeded.  Top ' + convert(varchar(10), @MaxRowCount) + ' Rows Returned.**'
Insert into #Prompts (PromptName, PromptValue) Values ('Criteria', @CriteriaString)
Insert into #Prompts (PromptName, PromptValue) Values ('GenerateTime', 'Created: ' + convert(varchar(25),dbo.fnServer_CmnConvertFromDbTime([dbo].[fnServer_CmnGetDate](getutcdate()),@InTimeZone),120))
Insert into #Prompts (PromptName, PromptValue) Values ('TabTitle', 'Sequence Of Events')
Insert into #Prompts (PromptName, PromptValue) Values ('Comments', 'Comments')
Insert into #Prompts (PromptName, PromptValue) Values ('RootEventType', convert(varchar(25),@RootEvent))
Insert into #Prompts (PromptName, PromptValue) Values ('StartTime', convert(varchar(25),[dbo].[fnServer_CmnConvertFromDbTime] (@StartTime,@InTimeZone),120))
Insert into #Prompts (PromptName, PromptValue) Values ('EndTime', convert(varchar(25),[dbo].[fnServer_CmnConvertFromDbTime] (@EndTime,@InTimeZone),120))
select * From #Prompts
Drop Table #Prompts
--**********************************************
-- Return Data 
--**********************************************
If @RowCount > @MaxRowCount
 	 Insert Into #Events (Category, Timestamp, StartTime, EndTime, ShortLabel, LongLabel, Color, HoverText, Hyperlink, IsRoot, EventType)
 	 Values ('Max Limit', GetDate(), @StartTime, @EndTime, '(Report Limit Exceeded)', 'Maximum Limit Of Events (' + convert(varchar(10), @MaxRowCount) + ') Was Exceeded.', 1, '', '', 1, 11)
Declare @TopSQL varchar(4000)
Select @TopSQL = 'Select Top ' + convert(varchar(10), @MaxRowCount) + '
  Item,
  Category,
  Timestamp=[dbo].[fnServer_CmnConvertFromDbTime] (Timestamp,'''+ @InTimeZone + '''),
  StartTime =[dbo].[fnServer_CmnConvertFromDbTime] (StartTime,'''+ @InTimeZone + '''),
  EndTime  =[dbo].[fnServer_CmnConvertFromDbTime] (EndTime,'''+ @InTimeZone + '''),
  ShortLabel,
  LongLabel ,
  Color, 
  Hovertext,
  Hyperlink,
  IsRoot ,
  EventType,
  NextTime =[dbo].[fnServer_CmnConvertFromDbTime] (NextTime,'''+ @InTimeZone + ''')
 From #Events Order By Timestamp ASC, IsRoot DESC'
print @TopSQL
Exec (@TopSQL)
--Select * from #Events
--  Order By Timestamp ASC, IsRoot DESC
Drop Table #Units
Drop Table #Events
Drop Table #EventTypes
Drop Table #EventSubtypes
Drop Table #Variables
