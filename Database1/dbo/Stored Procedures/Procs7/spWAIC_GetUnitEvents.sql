Create Procedure [dbo].[spWAIC_GetUnitEvents]
@UnitId Int,
@EventTypeId Int,
@EventSubtypeId Int,
@StartTime datetime,
@EndTime datetime,
@Events 	 VARCHAR(8000) = null,
@InTimeZone nvarchar(200)=NULL
AS
 	 select @StartTime =[dbo].[fnServer_CmnConvertToDbTime] (@StartTime,@InTimeZone)
 	 select @EndTime =[dbo].[fnServer_CmnConvertToDbTime] (@EndTime,@InTimeZone)
If DATALENGTH(@Events) > 7500
Begin
 	 Raiserror('Maximum Number Of Events In Filter Exceeded',16,1)
    return
End
If DATALENGTH(@Events) > 7500
Begin
 	 Raiserror('Maximum Number Of Events In Filter Exceeded',16,1)
    return
End
 --Run the query
Declare @SQL varchar(8000)
Create Table #SelectedEvents(
 	  EventId Int
)
If @Events Is Not Null
Begin
 	 Select @SQL = 'Insert Into #SelectedEvents(EventId) Select Event_Id From Events Where Event_Id In (' + @Events + ')'
 	 Exec(@SQL)
End 	  	 
If @Events Is Not Null
Begin
 	 Select @SQL = 'Insert Into #SelectedEvents(EventId) Select Event_Id From Events Where Event_Id In (' + @Events + ')'
 	 Exec(@SQL)
End 	  	 
--**********************************************
-- Translations Setup & Common Prompt Lookup
--**********************************************
-- Retreive the Language Id of the current user
Declare @LangId INT
EXEC spWA_GetCurrentUserInfo @LangId = @LangId OUTPUT
-- Get Common Prompts
DECLARE @sUnspecified nVarChar(100)
SET @sUnspecified = dbo.fnTranslate(@LangId, 34519, '<Unspecified>')
--**********************************************
    Create Table #Events (
      Label nvarchar(255) NULL,
      StartTime datetime NULL,
      EndTime datetime,
      Hyperlink nvarchar(255) NULL
    )
    If @EventTypeId = 1
      Begin
        --*******************************************************************  
        -- Production Events 
        --*******************************************************************  
        Insert Into #Events (Label, StartTime, EndTime, Hyperlink)
 	  	    	   Select Label = e.event_num + ' (' + s.ProdStatus_Desc + ')',
 	  	              StartTime = e.Start_Time,
 	  	              EndTime = e.Timestamp,
 	  	  	  	          Hyperlink = '<Link>EventDetail.aspx?Id=' + convert(nvarchar(20),e.Event_Id)+ '&TargetTimeZone='+ @InTimeZone + '</Link>' 
 	  	  	  	     From Events e
 	  	  	  	     Join Production_Status s on s.ProdStatus_id = e.Event_Status
 	  	  	  	     Where e.PU_id = @UnitId and
 	  	  	  	           e.Timestamp > @StartTime and 
  	    	    	    	            e.Timestamp <= @EndTime and
 	  	  	  	  	 --Filter By Events
 	  	  	  	  	         (@Events IS NULL OR e.Event_Id IN (Select * From #SelectedEvents))     
 	  	  	             Order By e.Timestamp ASC
        -- Fill In Start Times If Necessary
        If (Select Count(StartTime) From #Events Where StartTime Is Not Null) = 0
          Begin
            Update #Events
              Set StartTime = (Select max(Events.Timestamp) From Events Where Events.PU_Id = @UnitId and Events.Timestamp < #Events.EndTime)
              From #Events
              Where #Events.StartTime Is Null  
          End
      End
    Else If @EventTypeId = 2
      Begin
        --*******************************************************************  
        -- Downtime
        --*******************************************************************  
        Insert Into #Events (Label, StartTime, EndTime, Hyperlink)
 	  	    	   Select Label = coalesce('(' + tef.tefault_name + ')', coalesce(r1.event_reason_name,@sUnspecified)),
 	  	              StartTime = Case When d.Start_Time < @StartTime Then @StartTime Else d.Start_Time End,
 	  	              EndTime = coalesce(d.End_Time, @EndTime),
 	  	  	  	          Hyperlink = '<Link>DowntimeDetail.aspx?Id=' + convert(nvarchar(20),d.tedet_Id)+ '&TargetTimeZone='+ @InTimeZone + '</Link>'
 	  	  	    	  	 From Timed_Event_Details d
 	  	         Left Outer Join Event_Reasons r1 on r1.event_reason_id = d.reason_level1
 	  	         Left Outer Join Timed_Event_Fault tef on tef.tefault_id = d.tefault_id
 	  	  	  	  	   Where d.PU_id = @UnitId and
 	  	  	    	  	       d.Start_Time = (Select Max(Start_Time) From Timed_Event_Details t Where t.PU_Id = @UnitId and t.start_time < @StartTime) and
 	  	  	    	       ((d.End_Time > @StartTime) or (d.End_Time is Null))
  	  	  	  	 Union
 	  	    	   Select Label = coalesce('(' + tef.tefault_name + ')', coalesce(r1.event_reason_name, @sUnspecified)),
 	  	              StartTime = Case When d.Start_Time < @StartTime Then @StartTime Else d.Start_Time End,
 	  	              EndTime = coalesce(d.End_Time, @EndTime),
 	  	  	  	          Hyperlink = '<Link>DowntimeDetail.aspx?Id=' + convert(nvarchar(20),d.tedet_Id)+ '&TargetTimeZone='+ @InTimeZone + '</Link>'
 	  	  	  	  	  	   From Timed_Event_Details d
 	  	           Left Outer Join Event_Reasons r1 on r1.event_reason_id = d.reason_level1
 	  	           Left Outer Join Timed_Event_Fault tef on tef.tefault_id = d.tefault_id
 	  	           Where d.PU_id = @UnitId and
 	  	                 d.Start_Time > @StartTime and 
 	  	  	      	  	  	     d.Start_Time <= @EndTime 
      End
    Else If @EventTypeId = 3
      Begin
        --*******************************************************************  
        -- Waste
        --*******************************************************************  
        --TODO Join In Production Rate Specification To Estimate Start Time 
        Insert Into #Events (Label, StartTime, EndTime, Hyperlink)
 	  	    	   Select Label = coalesce('(' + wef.wefault_name + ')', coalesce(r1.event_reason_name, @sUnspecified)), 
 	  	              StartTime = d.Timestamp,
 	  	              EndTime = d.Timestamp,
 	  	  	  	          Hyperlink = '<Link>WasteDetail.aspx?Id=' + convert(nvarchar(20),d.wed_Id)+ '&TargetTimeZone='+ @InTimeZone + '</Link>'
 	  	  	  	  	   From Waste_Event_Details d
 	  	         Left Outer Join Event_Reasons r1 on r1.event_reason_id = d.reason_level1
 	  	         Left Outer Join Waste_Event_Fault wef on wef.wefault_id = d.wefault_id
 	  	  	  	  	   Where d.PU_id = @UnitId and
 	  	  	    	  	       d.Timestamp > @StartTime and 
 	  	               d.Timestamp <= @EndTime and
 	  	               d.Event_Id Is Null
 	  	  	  	 Union
 	  	    	   Select Label = coalesce('(' + wef.wefault_name + ')', coalesce(r1.event_reason_name, @sUnspecified)), 
 	  	              StartTime = d.Timestamp,
 	  	              EndTime = d.Timestamp,
 	  	  	  	          Hyperlink = '<Link>WasteDetail.aspx?Id=' + convert(nvarchar(20),d.wed_Id)+ '&TargetTimeZone='+ @InTimeZone + '</Link>'
 	  	  	  	  	  	 From Events e
 	  	  	    	  	 Join Waste_Event_Details d on d.event_id = e.event_id
 	  	         Left Outer Join Event_Reasons r1 on r1.event_reason_id = d.reason_level1
 	  	         Left Outer Join Waste_Event_Fault wef on wef.wefault_id = d.wefault_id
 	  	         Where e.PU_id = @UnitId and
 	  	  	  	  	         e.Timestamp > @StartTime and 
 	  	  	  	  	         e.Timestamp <= @EndTime 
        --*******************************************************************  
      End
    Else If @EventTypeId = 4
      Begin
        --*******************************************************************  
        -- Product Change
        --*******************************************************************  
        Insert Into #Events (Label, StartTime, EndTime, Hyperlink)
 	  	    	   Select Label = p.Prod_code,
 	  	              StartTime = Case When d.Start_Time < @StartTime Then @StartTime Else d.Start_Time End,
 	  	              EndTime = coalesce(d.End_Time, @EndTime),
 	  	  	  	          Hyperlink = '<Link>ProductChangeDetail.aspx?Id=' + convert(nvarchar(20),d.start_Id)+ '&TargetTimeZone='+ @InTimeZone + '</Link>'
 	  	  	  	  	   From Production_Starts d
 	  	         Join Products p on p.prod_id = d.prod_id
 	  	  	  	  	   Where d.PU_id = @UnitId and
 	  	  	    	  	       d.Start_Time = (Select Max(Start_Time) From Production_Starts t Where t.PU_Id = @UnitId and t.start_time < @StartTime) and
 	  	  	     	       ((d.End_Time > @StartTime) or (d.End_Time is Null))
 	  	  	  	 Union
 	  	    	   Select Label = p.Prod_code,
 	  	              StartTime = Case When d.Start_Time < @StartTime Then @StartTime Else d.Start_Time End,
 	  	              EndTime = coalesce(d.End_Time, @EndTime),
 	  	  	  	          Hyperlink = '<Link>ProductChangeDetail.aspx?Id=' + convert(nvarchar(20),d.start_Id) + '&TargetTimeZone='+ @InTimeZone+ '</Link>'
 	  	   	  	   From Production_Starts d
 	  	       Join Products p on p.prod_id = d.prod_id
 	  	       Where d.PU_id = @UnitId and
 	  	             d.Start_Time > @StartTime and 
 	  	  	          	 d.Start_Time <= @EndTime 
        --*******************************************************************  
      End
    Else If @EventTypeId = 11 
      Begin
        --*******************************************************************  
        -- Alarms
        --*******************************************************************  
        -- Event Subtype Id = Variable Id
        Insert Into #Events (Label, StartTime, EndTime, Hyperlink)
 	  	    	   Select Label = d.alarm_desc,
               StartTime = Case When d.Start_Time < @StartTime Then @StartTime Else d.Start_Time End,
               EndTime = coalesce(d.End_Time, @EndTime),
 	  	  	          Hyperlink = '<Link>AlarmDetail.aspx?Id=' + convert(nvarchar(20),d.Alarm_Id)+ '&TargetTimeZone='+ @InTimeZone + '</Link>'
 	  	  	  	   From Alarms d
          Left Outer Join Event_Reasons r1 on r1.event_reason_id = d.cause1
 	  	  	  	   Where d.Key_Id = @EventSubtypeId and
                d.Alarm_Type_Id in (1,2) and 
 	    	  	         d.Start_Time = (Select Max(Start_Time) From Alarms t Where t.Key_Id = @EventSubtypeId and t.Alarm_Type_Id in (1,2) and t.start_time < @StartTime) and
 	  	   	         ((d.End_Time > @StartTime) or (d.End_Time is Null))
       Union
 	  	    	   Select Label = d.alarm_desc,
               StartTime = Case When d.Start_Time < @StartTime Then @StartTime Else d.Start_Time End,
               EndTime = coalesce(d.End_Time, @EndTime),
 	  	  	          Hyperlink = '<Link>AlarmDetail.aspx?Id=' + convert(nvarchar(20),d.Alarm_Id)+ '&TargetTimeZone='+ @InTimeZone + '</Link>'
 	  	  	  	   From Alarms d
          Left Outer Join Event_Reasons r1 on r1.event_reason_id = d.cause1
 	  	  	  	   Where d.Key_Id = @EventSubtypeId and
                d.Alarm_Type_Id in (1,2) and 
 	               d.Start_Time > @StartTime and 
 	  	          	  	 d.Start_Time <= @EndTime 
        --*******************************************************************  
      End
    Else If @EventTypeId = 14 
      Begin
        --*******************************************************************  
        -- User Defined Events
        --*******************************************************************  
        Declare @UDEType int
 	  	  	  	 Select @UDEType = duration_required From Event_Subtypes Where event_subtype_id = @EventSubtypeId
 	  	  	  	 If @UDEType = 1 
         	 Begin
            -- Both Start and End Times Apply
           	 Insert Into #Events (Label, StartTime, EndTime, Hyperlink)
 	    	  	    	   Select Label = coalesce(d.UDE_Desc + '-' + r1.event_reason_name, r1.event_reason_name, d.UDE_Desc, @sUnspecified), 
 	                  StartTime = Case When d.Start_Time < @StartTime Then @StartTime Else d.Start_Time End,
 	                  EndTime = coalesce(d.End_Time, @EndTime),
 	  	  	  	  	          Hyperlink = '<Link>UserDefinedEventDetail.aspx?Id=' + convert(nvarchar(20),d.UDE_Id)+ '&TargetTimeZone='+ @InTimeZone + '</Link>'
 	  	  	  	  	  	   From User_Defined_Events d
 	  	           Left Outer Join Event_Reasons r1 on r1.event_reason_id = d.cause1
 	  	  	  	  	  	   Where d.PU_Id = @UnitId and
                    d.Event_Subtype_id = @EventSubtypeId and
 	  	  	    	  	         d.Start_Time = (Select Max(Start_Time) From User_Defined_Events t Where t.PU_Id = @UnitId and t.Event_Subtype_id = @EventSubtypeId and t.start_time < @StartTime) and
 	  	  	  	   	         ((d.End_Time > @StartTime) or (d.End_Time is Null))
 	          Union
 	    	  	    	   Select Label = coalesce(d.UDE_Desc + '-' + r1.event_reason_name, r1.event_reason_name, d.UDE_Desc, @sUnspecified), 
 	                  StartTime = Case When d.Start_Time < @StartTime Then @StartTime Else d.Start_Time End,
 	                  EndTime = coalesce(d.End_Time, @EndTime),
 	  	  	  	  	          Hyperlink = '<Link>UserDefinedEventDetail.aspx?Id=' + convert(nvarchar(20),d.UDE_Id) + '&TargetTimeZone='+ @InTimeZone+ '</Link>'
 	  	  	  	  	  	   From User_Defined_Events d
 	  	           Left Outer Join Event_Reasons r1 on r1.event_reason_id = d.cause1
 	  	  	  	  	  	   Where d.PU_Id = @UnitId and
                    d.Event_Subtype_id = @EventSubtypeId and
 	  	  	               d.Start_Time > @StartTime and 
 	  	  	  	          	  	 d.Start_Time <= @EndTime 
 	  	  	  	  	 End
 	  	  	  	 Else
 	  	  	  	  	 Begin
            -- Only Start Time Applies
           	 Insert Into #Events (Label, StartTime, EndTime, Hyperlink)
 	    	  	    	   Select Label = coalesce(d.UDE_Desc + '-' + r1.event_reason_name, r1.event_reason_name, d.UDE_Desc, @sUnspecified), 
 	                  StartTime = d.Start_time,
 	                  EndTime = d.Start_Time,
 	  	  	  	  	          Hyperlink = '<Link>UserDefinedEventDetail.aspx?Id=' + convert(nvarchar(20),d.UDE_Id)+ '&TargetTimeZone='+ @InTimeZone + '</Link>'
 	  	  	  	  	  	   From User_Defined_Events d
 	  	           Left Outer Join Event_Reasons r1 on r1.event_reason_id = d.cause1
 	  	  	  	  	  	   Where d.PU_Id = @UnitId and
                    d.Event_Subtype_id = @EventSubtypeId and
 	  	  	               d.Start_Time > @StartTime and 
 	  	  	  	          	  	 d.Start_Time <= @EndTime 
 	  	  	  	  	 End
        --*******************************************************************  
      End
    Else If @EventTypeId = 19 
      Begin
        --*******************************************************************  
        -- Process Orders
        --*******************************************************************  
        	 Insert Into #Events (Label, StartTime, EndTime, Hyperlink)
 	  	    	   Select Label = pp.Process_Order + ' (' +  s.pp_status_desc + ')',
 	  	              StartTime = Case When d.Start_Time < @StartTime Then @StartTime Else d.Start_Time End,
 	  	              EndTime = coalesce(d.End_Time, @EndTime),
 	  	  	  	          Hyperlink = '<Link>ProcessOrderDetail.aspx?Id=' + convert(nvarchar(20),pp.pp_Id) + '&TargetTimeZone='+ @InTimeZone+ '</Link>'
 	  	  	  	  	   From Production_Plan_Starts d
 	           Join Production_Plan pp on pp.pp_id = d.pp_id
 	           Join production_plan_statuses s on s.pp_status_id = pp.pp_status_id
 	  	  	  	  	   Where d.PU_id = @UnitId and
 	  	  	    	  	       d.Start_Time = (Select Max(Start_Time) From Production_Plan_Starts t Where t.PU_Id = @UnitId and t.start_time < @StartTime) and
 	  	  	     	       ((d.End_Time > @StartTime) or (d.End_Time is Null))
 	  	  	  	 Union
 	  	    	   Select Label = pp.Process_Order + ' (' +  s.pp_status_desc + ')',
 	  	              StartTime = Case When d.Start_Time < @StartTime Then @StartTime Else d.Start_Time End,
 	  	              EndTime = coalesce(d.End_Time, @EndTime),
 	  	  	  	          Hyperlink = '<Link>ProcessOrderDetail.aspx?Id=' + convert(nvarchar(20),pp.pp_Id)+ '&TargetTimeZone='+ @InTimeZone + '</Link>'
 	  	  	  	  	   From Production_Plan_Starts d
 	           Join Production_Plan pp on pp.pp_id = d.pp_id
 	           Join production_plan_statuses s on s.pp_status_id = pp.pp_status_id
 	  	  	       Where d.PU_id = @UnitId and
 	  	  	             d.Start_Time > @StartTime and 
 	  	  	  	          	 d.Start_Time <= @EndTime 
        --*******************************************************************  
      End
    Else If @EventTypeId = 0 
      Begin
        --*******************************************************************  
        -- Crew Schedule
        --*******************************************************************  
        	 Insert Into #Events (Label, StartTime, EndTime, Hyperlink)
 	  	    	   Select LongLabel = d.crew_desc + ' - ' + d.shift_desc,
 	  	              StartTime = Case When d.Start_Time < @StartTime Then @StartTime Else d.Start_Time End,
 	  	              EndTime = coalesce(d.End_Time, @EndTime),
 	  	  	  	          Hyperlink = NULL
 	  	  	  	  	   From crew_schedule d
 	  	  	  	  	   Where d.PU_id = @UnitId and
 	  	  	    	  	       d.Start_Time = (Select Max(Start_Time) From crew_schedule t Where t.PU_Id = @UnitId and t.start_time < @StartTime) and
 	  	  	     	       ((d.End_Time > @StartTime) or (d.End_Time is Null))
 	  	  	  	 Union
 	  	    	   Select LongLabel = d.crew_desc + ' - ' + d.shift_desc,
 	  	              StartTime = Case When d.Start_Time < @StartTime Then @StartTime Else d.Start_Time End,
 	  	              EndTime = coalesce(d.End_Time, @EndTime),
 	  	  	  	          Hyperlink = NULL
 	  	  	  	  	   From crew_schedule d
 	  	  	       Where d.PU_id = @UnitId and
 	  	  	             d.Start_Time > @StartTime and 
 	  	  	  	          	 d.Start_Time <= @EndTime 
        --*******************************************************************  
      End
--Sarla
--Select * From #Events Order By EndTime ASC
Select Label,
      'StartTime'=  [dbo].[fnServer_CmnConvertFromDbTime] (StartTime,@InTimeZone)   ,
      'EndTime' =  [dbo].[fnServer_CmnConvertFromDbTime] (EndTime,@InTimeZone) ,
      Hyperlink From #Events
Order By EndTime ASC
--Sarla
Drop Table #Events
DROP TABLE #SelectedEvents
