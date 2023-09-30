Create Procedure dbo.spGE_GetEventGenealogy
  @Event_Id int,
  @Levels   Int = 10,
  @SheetId  Int = Null
 AS
Declare  	 @MaxEventsPerLevel  	 Int,
 	  	 @DisplayAlarms  	 Int
If @SheetId is Not Null
  Begin
 	 Select @MaxEventsPerLevel = convert(int,value)
 	  	 From Sheet_Display_Options s
 	  	 Join Display_Options d on s.Display_Option_Id = d.Display_Option_Id and d.Display_Option_Desc = 'MaxEventsPerLevel'
 	  	 Where Sheet_Id = @SheetId
 	 Select @DisplayAlarms = convert(int,value)
 	  	 From Sheet_Display_Options s
 	  	 Join Display_Options d on s.Display_Option_Id = d.Display_Option_Id and d.Display_Option_Desc = 'DisplayTreeViewAlarms'
 	  	 Where Sheet_Id = @SheetId
  End
Select @DisplayAlarms = isnull(@DisplayAlarms,1)
Select @MaxEventsPerLevel = isnull(@MaxEventsPerLevel,5)
Select @Levels = isnull(@Levels,10)
Declare @Prev_Id  	 int,
 	 @Ts       	 datetime,
 	 @PU_Id    	 int,
     @Next_Id 	 int,
 	 @ThisTs 	  	 DateTime,
 	 @PrevStartTs 	 DateTime,
 	 @PrevLAC 	 Int,
 	 @PrevMAC 	 Int,
 	 @PrevHAC 	 Int,
 	 @NextLAC 	 Int,
 	 @NextMAC 	 Int,
 	 @NextHAC 	 Int,
 	 @CurrLAC 	 Int,
 	 @CurrMAC 	 Int,
 	 @CurrHAC 	 Int,
 	 @TopEventId 	 Int,
 	 @Order 	  	 int,
 	 @TempParent 	 Int,
 	 @NextParent 	 Int,
 	 @Now 	  	 DateTime
SELECT @Now = dbo.fnServer_CmnGetDate(GetUtcDate())
Declare @Id Int,@Count Int,@OrderId Int
Declare @MinComponent Int
Declare @NodeCount Int,@ECNodeCount Int
select @Levels = coalesce(@Levels,10)
Create Table #ParentEvents (EventId Int,SEvent int,OrderId Int,ComponentId Int,NodeCount Int,ECNodeCount Int,LowAlarm Int ,MedAlarm Int ,HighAlarm Int)
Create Table #ChildEvents (EventId Int,SEvent int,OrderId Int,ComponentId Int,NodeCount Int,ECNodeCount Int,LowAlarm Int ,MedAlarm Int ,HighAlarm Int)
Create Table #TempEvent1(EventId Int,SEvent int,ComponentId Int,NodeCount Int,ECNodeCount Int)
Create Table #TempEvent2(EventId Int,SEvent int,ComponentId Int,NodeCount Int,ECNodeCount Int)
Create Table #LoopEvents (EventId Int,SEvent int,ComponentId Int,NodeCount Int,ECNodeCount Int)
Insert Into #TempEvent2(EventId,SEvent,ComponentId,NodeCount,ECNodeCount) Values (@Event_Id,0,0,0,0)
Select @Order = 0
PLoop:
Truncate Table #TempEvent1
Declare PEventCursor Cursor for
 Select EventId From #TempEvent2
Open PEventCursor
PEventCursorLoop:
Fetch Next From PEventCursor into @Id
If @@Fetch_status = 0
  Begin
 	 Select @NodeCount = Count(Distinct Event_Id) From Event_Components where Source_Event_Id = @Id
 	 If @NodeCount <= @MaxEventsPerLevel 
 	  	 Insert Into #TempEvent1(EventId,SEvent,ComponentId,NodeCount,ECNodeCount)
   	  	  	 Select  Event_Id,Source_Event_Id,Min(Component_Id),@NodeCount,Count(*)
     	  	  	 From Event_Components 
 	  	  	 Where Source_Event_Id = @Id
 	  	  	 Group by Event_Id,Source_Event_Id
 	 Else
 	   Begin
 	  	 Select @MinComponent = min(Component_Id) From Event_Components Where Source_Event_Id = @Id
 	  	 Insert Into #TempEvent1(EventId,SEvent,ComponentId,NodeCount,ECNodeCount)
   	  	  	 Select Event_Id,Source_Event_Id,Component_Id,@NodeCount,Count(*)
     	  	 From Event_Components Where Component_Id = @MinComponent
 	  	  	 Group by Event_Id,Source_Event_Id,Component_Id
 	   End
 	 goto PEventCursorLoop
  End
Close PEventCursor
Deallocate PEventCursor
 If (Select Count(*) From  #TempEvent1) > 0
   Begin
      Insert Into  #ParentEvents (EventId,Sevent,OrderId,ComponentId,NodeCount,ECNodeCount) 
 	  	 Select Distinct EventId,Sevent,@Order,ComponentId,NodeCount,ECNodeCount From #TempEvent1
 	   Insert Into #LoopEvents(EventId,Sevent,ComponentId,NodeCount,ECNodeCount)
 	   Select t.Eventid,t.SEvent,t.ComponentId,t.NodeCount,t.ECNodeCount
 	  	 From #ParentEvents t
 	  	 Join #ParentEvents s on t.Eventid = s.SEvent
 	   Delete from #TempEvent1 where Eventid in (select EventId From #LoopEvents)
 	   Truncate Table #LoopEvents
      Truncate Table #TempEvent2
      Insert Into #TempEvent2 Select EventId,Sevent,ComponentId,NodeCount,ECNodeCount From #TempEvent1
      Select @Order = @Order + 1
 	   If @Order < @Levels 
        Goto PLoop
   End
If @DisplayAlarms = 1
  Begin
 	 Declare AlarmsCursor INSENSITIVE  Cursor  For
 	 Select Distinct EventId  From #ParentEvents
 	 Open AlarmsCursor
 	 AlarmsLoop:
 	 Fetch next from AlarmsCursor into @Id
 	 If @@Fetch_Status = 0
 	   Begin
 	  	 Select @Ts = TimeStamp, @PU_Id = pu_Id
 	  	 From events
 	  	 Where event_id = @Id
 	  	 
 	  	 -- Previous roll 
 	  	 Select @ThisTs = max(timestamp)
 	  	    from events
 	  	    where PU_Id = @PU_Id and TimeStamp < @Ts and TimeStamp > '01/01/1970'
 	  	  
 	  	 Select @PrevStartTs = max(timestamp)
 	  	    from events
 	  	    where PU_Id = @PU_Id and TimeStamp < @ThisTs and TimeStamp > '01/01/1970'
 	  	 
 	  	 If @PrevStartTs is null 
 	  	  	 Select  @PrevStartTs = @Now
 	     Execute spCmn_AlarmCounts @PrevLAC Output,@PrevMAC Output,@PrevHAC Output,@PrevStartTs,@ThisTs,@PU_Id
 	     Update #ParentEvents set LowAlarm = @PrevLAC ,MedAlarm = @PrevMAC,HighAlarm = @PrevHAC Where EventId = @Id
 	     Goto AlarmsLoop
 	   End
 	 Close AlarmsCursor
 	 Deallocate AlarmsCursor
 End
Truncate Table #TempEvent2
Insert Into #TempEvent2(EventId,Sevent,ComponentId,NodeCount,ECNodeCount) Values (@Event_Id,0,0,0,0)
Select @Order = 0
CLoop:
Truncate Table #TempEvent1
Declare CEventCursor Cursor for
 Select EventId From #TempEvent2
Open CEventCursor
CEventCursorLoop:
Fetch Next From CEventCursor into @Id
If @@Fetch_status = 0
  Begin
 	 Select @NodeCount = Count(Distinct Source_Event_Id) From Event_Components where Event_Id = @Id
 	 If @NodeCount <= @MaxEventsPerLevel
 	  	 Insert Into #TempEvent1(EventId,SEvent,ComponentId,NodeCount,ECNodeCount)
 	  	   Select Source_Event_Id,Event_Id,Min(Component_Id),@NodeCount,Count(*)
 	  	     From Event_Components
 	  	     Where Event_Id  = @Id
 	  	  	 Group by Event_Id,Source_Event_Id
 	 Else
 	   Begin
 	  	 Select @MinComponent = min(Component_Id) From Event_Components Where Event_Id = @Id
 	  	 Insert Into #TempEvent1(EventId,SEvent,ComponentId,NodeCount,ECNodeCount)
   	  	  	 Select Source_Event_Id,Event_Id,Component_Id,@NodeCount,Count(*)
     	  	 From Event_Components 
 	  	  	 Where Component_Id = @MinComponent
 	  	  	 Group by Event_Id,Source_Event_Id,Component_Id
 	   End
 	 goto CEventCursorLoop
  End
Close CEventCursor
Deallocate CEventCursor
  If (Select Count(*) From  #TempEvent1) > 0
   Begin
      Insert Into  #ChildEvents (EventId,Sevent,OrderId,ComponentId,NodeCount,ECNodeCount)
 	  	  Select Distinct EventId,SEvent,@Order,ComponentId,NodeCount,ECNodeCount
 	  	  	  From #TempEvent1
 	   Insert Into #LoopEvents(EventId,Sevent,ComponentId,NodeCount,ECNodeCount)
 	   Select t.Eventid,t.SEvent,t.ComponentId,t.NodeCount,t.ECNodeCount
 	  	 From #ChildEvents t
 	  	 Join #ChildEvents s on t.Eventid = s.SEvent
 	   Delete from #TempEvent1 where SEvent in (select SEvent From #LoopEvents)
 	   Truncate Table #LoopEvents
      Truncate Table #TempEvent2
      Insert Into #TempEvent2 (EventId,Sevent,ComponentId,NodeCount,ECNodeCount ) Select EventId,Sevent,ComponentId,NodeCount,ECNodeCount From #TempEvent1
      Select @Order = @Order + 1
 	   If @Order < @Levels 
       	 Goto CLoop
   End
If @DisplayAlarms = 1
  Begin
 	 Declare AlarmsCursor2 INSENSITIVE  Cursor  For
 	 Select Distinct EventId  From #ChildEvents
 	 Open AlarmsCursor2
 	 AlarmsLoop2:
 	 Fetch next from AlarmsCursor2 into @Id
 	 If @@Fetch_Status = 0
 	   Begin
 	  	 Select @Ts = TimeStamp, @PU_Id = pu_Id
 	  	 From events
 	  	 Where event_id = @Id
 	  	 
 	  	 -- Previous roll 
 	  	 Select @ThisTs = max(timestamp)
 	  	    from events
 	  	    where PU_Id = @PU_Id and TimeStamp < @Ts and TimeStamp > '01/01/1970'
 	  	  
 	  	 Select @PrevStartTs = max(timestamp)
 	  	    from events
 	  	    where PU_Id = @PU_Id and TimeStamp < @ThisTs and TimeStamp > '01/01/1970'
 	  	 
 	  	 If @PrevStartTs is null 
 	  	  	 Select  @PrevStartTs = @Now
 	     Execute spCmn_AlarmCounts @PrevLAC Output,@PrevMAC Output,@PrevHAC Output,@PrevStartTs,@ThisTs,@PU_Id
 	     Update #ChildEvents set LowAlarm = @PrevLAC ,MedAlarm = @PrevMAC,HighAlarm = @PrevHAC Where EventId = @Id
 	     Goto AlarmsLoop2
 	   End
 	 Close AlarmsCursor2
 	 Deallocate AlarmsCursor2
  End
Drop table #LoopEvents
Drop Table #TempEvent1
Drop Table #TempEvent2
Select @Ts = TimeStamp, @PU_Id = pu_Id
From events
Where event_id = @Event_Id
-- Previous roll 
Select @ThisTs = max(timestamp)
   from events
   where PU_Id = @PU_Id and TimeStamp < @Ts and TimeStamp > '01/01/1970'
Select @PrevStartTs = max(timestamp)
   from events
   where PU_Id = @PU_Id and TimeStamp < @ThisTs and TimeStamp > '01/01/1970'
If @PrevStartTs is null 
 	 Select  @PrevStartTs = @Now
-- select @PrevStartTs,@ThisTs,@Ts
If @DisplayAlarms = 1
  Begin
 	 Execute spCmn_AlarmCounts @PrevLAC Output,@PrevMAC Output,@PrevHAC Output,@PrevStartTs,@ThisTs,@PU_Id
  End
Execute spCmn_AlarmCounts @CurrLAC Output,@CurrMAC Output,@CurrHAC Output,@ThisTs,@Ts,@PU_Id
select @Prev_Id = Event_Id 
  From Events
  Where  PU_Id = @PU_Id and TimeStamp = @ThisTs
--Next Roll
Select @ThisTs = min(timestamp)
   from events
   where PU_Id = @PU_Id and TimeStamp > @Ts and TimeStamp < @Now
If @DisplayAlarms = 1
  Begin
 	 Execute spCmn_AlarmCounts @NextLAC Output,@NextMAC Output,@NextHAC Output,@Ts,@ThisTs,@PU_Id
  End
select @Next_Id = Event_Id 
  From Events
  Where  PU_Id = @PU_Id and TimeStamp = @ThisTs
--Previous Event
Select  DimA = coalesce(ed.final_dimension_A,0),DimX = coalesce(ed.final_dimension_X,0),DimY = coalesce(ed.final_dimension_Y,0),DimZ = coalesce(ed.final_dimension_z,0),
     e.Event_Id,e.Event_Num,e.PU_Id,e.TimeStamp,e.Source_Event,ProdStatus_Desc,
     e.Event_Status,Prod_Code = case When e.Applied_Product is null then pp.prod_Code else pp1.prod_Code   end ,LowAlarm = Isnull(@PrevLAC,0),MedAlarm = Isnull(@PrevMAC,0),HighAlarm = Isnull(@PrevHAC,0),Pu_Desc,OrderNumber = Coalesce(co.Plant_Order_Number,'N/A'),Comment_Id = coalesce(e.Comment_Id,0),Applied_Product = Coalesce(e.Applied_Product,0),
     Process_Order = Coalesce(ppp.Process_Order, ppp2.Process_Order, 'N/A')
   from events e
    Left Join Event_Details ed On ed.Event_Id = e.Event_Id
    Left Join Customer_Order_Line_Items col On ed.Order_Line_Id = col.Order_Line_Id
    Left Join Customer_Orders co on col.Order_Id = co.Order_Id
    Left  Join Production_status on  ProdStatus_Id = e.Event_Status
    Join Production_Starts s on (s.Start_Time <= e.timestamp and  (s.End_time > e.Timestamp or  s.End_time is null))  and s.pu_id = e.pu_id
    Join  Products pp on pp.prod_id = s.prod_id
    Left Join  Products pp1 on pp1.prod_id = e.Applied_Product
    Join Prod_Units pu on pu.Pu_Id = e.pu_id
    Left Join Production_Plan ppp on ed.PP_Id = ppp.PP_Id
    Left Join Production_Plan_Starts pps on (pps.Start_Time <= e.timestamp and  (pps.End_time > e.Timestamp or  pps.End_time is null))  and pps.pu_id = e.pu_id
    Left Join Production_Plan ppp2 on ppp2.PP_Id = pps.PP_Id
   where e.Event_Id = @Prev_Id
-- Actual 
Select  DimA = coalesce(ed.final_dimension_A,0),DimX = coalesce(ed.final_dimension_X,0),DimY = coalesce(ed.final_dimension_Y,0),DimZ = coalesce(ed.final_dimension_z,0),
        e.Event_Id,e.Event_Num,e.PU_Id,e.TimeStamp,e.Source_Event,ProdStatus_Desc,e.Event_Status,Prod_Code= case When e.Applied_Product is null then pp.prod_Code else pp1.prod_Code  end ,
 	  	 LowAlarm = Isnull(@CurrLAC,0),MedAlarm = Isnull(@CurrMAC,0),HighAlarm = Isnull(@CurrHAC,0),Pu_Desc,OrderNumber = Coalesce(co.Plant_Order_Number,'N/A'),Comment_Id = coalesce(e.Comment_Id,0),Applied_Product = Coalesce(e.Applied_Product,0), 
 	  	 Process_Order = Coalesce(ppp.Process_Order, ppp2.Process_Order, 'N/A')
   FROM Events e
    Left Join Event_Details ed On ed.Event_Id = e.Event_Id
    Left Join Customer_Order_Line_Items col On ed.Order_Line_Id = col.Order_Line_Id
    Left Join Customer_Orders co on col.Order_Id = co.Order_Id
    Left Join Production_status on  Prodstatus_id = e.Event_Status
    Join Production_Starts s on (s.Start_Time <= e.timestamp and  (s.End_time > e.Timestamp or  s.End_time is null))  and s.pu_id = e.pu_id
    Join  Products pp on pp.prod_id = s.prod_id
    Left Join  Products pp1 on pp1.prod_id = e.Applied_Product
    Join Prod_Units pu on pu.Pu_Id = e.pu_id
    Left Join Production_Plan ppp on ed.PP_Id = ppp.PP_Id
    Left Join Production_Plan_Starts pps on (pps.Start_Time <= e.timestamp and  (pps.End_time > e.Timestamp or  pps.End_time is null))  and pps.pu_id = e.pu_id
    Left Join Production_Plan ppp2 on ppp2.PP_Id = pps.PP_Id    
 where e.event_id = @Event_Id
--  Parent Events (for actual)
Select  ECNodeCount,NodeCount,DimA = isnull(ed.final_dimension_A,0),DimX = isnull(ed.final_dimension_X,0),DimY = isnull(ed.final_dimension_Y,0),
 	  	 DimZ = isnull(ed.final_dimension_z,0),e.Event_Id,e.Event_Num,e.PU_Id,e.TimeStamp,ProdStatus_Desc,
 	  	 e.Event_Status,Prod_Code = case When e.Applied_Product is null then pp.prod_Code else pp1.prod_Code   end ,Pu_Desc,
 	  	 [Source_Event] = pe.Sevent,OrderNumber = Coalesce(co.Plant_Order_Number,'N/A'),
 	  	 Comment_Id = isnull(e.Comment_Id,0),Applied_Product = isnull(e.Applied_Product,0),ComponentId,
 	  	 Ec_Time = isnull(Convert(nvarchar(25),ec.Timestamp),'N/A'),LowAlarm = Isnull(LowAlarm,0),MedAlarm= Isnull(MedAlarm,0) ,HighAlarm= Isnull(HighAlarm,0),OrderId,
 	  	 Process_Order = Coalesce(ppp.Process_Order, ppp2.Process_Order, 'N/A')
   from  #ParentEvents pe
   Join Events  e on e.Event_Id = pe.EventId
   Left Join event_Components ec on ec.Component_Id = pe.ComponentId
    Left Join Event_Details ed On ed.Event_Id = e.Event_Id
    Left Join Customer_Order_Line_Items col On ed.Order_Line_Id = col.Order_Line_Id
    Left Join Customer_Orders co on col.Order_Id = co.Order_Id
   Left Join Production_status on  Prodstatus_id = e.Event_Status
   Left Join Production_Starts s on (s.Start_Time <= e.timestamp and  (s.End_time > e.Timestamp or  s.End_time is null))  and s.pu_id = e.pu_id
   Join  Products pp on pp.prod_id = s.prod_id
   Left Join  Products pp1 on pp1.prod_id = e.Applied_Product
   Join Prod_Units pu on pu.Pu_Id = e.pu_id
   Left Join Production_Plan ppp on ed.PP_Id = ppp.PP_Id
   Left Join Production_Plan_Starts pps on (pps.Start_Time <= e.timestamp and  (pps.End_time > e.Timestamp or  pps.End_time is null))  and pps.pu_id = e.pu_id
   Left Join Production_Plan ppp2 on ppp2.PP_Id = pps.PP_Id   
   Order by ECNodeCount ,OrderId asc,pe.Sevent
  Drop Table #ParentEvents
--  Child events (for actual)
 Select ECNodeCount,NodeCount,DimA = coalesce(ed.final_dimension_A,0),DimX = coalesce(ed.final_dimension_X,0),DimY = coalesce(ed.final_dimension_Y,0),
 	  	 DimZ = coalesce(ed.final_dimension_z,0),e.Event_Id,e.Event_Num,e.PU_Id,e.TimeStamp,ProdStatus_Desc,
 	  	 e.Event_Status,Prod_Code = case When e.Applied_Product is null then pp.prod_Code else pp1.prod_Code   end ,Pu_Desc,
 	  	 [Source_Event]=ce.SEvent,OrderNumber = Coalesce(co.Plant_Order_Number,'N/A'),
 	  	 Comment_Id = coalesce(e.Comment_Id,0),Applied_Product = Coalesce(e.Applied_Product,0),ComponentId,
 	  	 Ec_Time = Coalesce(Convert(nvarchar(25),ec.Timestamp),'N/A'),LowAlarm = Isnull(LowAlarm,0),MedAlarm= Isnull(MedAlarm,0) ,HighAlarm= Isnull(HighAlarm,0),OrderId,
 	   Process_Order = Coalesce(ppp.Process_Order, ppp2.Process_Order, 'N/A')
    From #ChildEvents ce
    Join Events e On e.Event_Id = ce.EventId
    Left Join event_Components ec on ec.Component_Id = ce.ComponentId
    Left Join Event_Details ed On ed.Event_Id = e.Event_Id
    Left Join Customer_Order_Line_Items col On ed.Order_Line_Id = col.Order_Line_Id
    Left Join Customer_Orders co on col.Order_Id = co.Order_Id
    Left Join Production_status on  Prodstatus_id = e.Event_Status
    Join Production_Starts s on (s.Start_Time <= e.timestamp and  (s.End_time > e.Timestamp or  s.End_time is null))  and s.pu_id = e.pu_id
    Join  Products pp on pp.prod_id = s.prod_id
    Left Join  Products pp1 on pp1.prod_id = e.Applied_Product
    Join Prod_Units pu on pu.Pu_Id = e.pu_id
    Left Join Production_Plan ppp on ed.PP_Id = ppp.PP_Id
    Left Join Production_Plan_Starts pps on (pps.Start_Time <= e.timestamp and  (pps.End_time > e.Timestamp or  pps.End_time is null))  and pps.pu_id = e.pu_id
    Left Join Production_Plan ppp2 on ppp2.PP_Id = pps.PP_Id    
   Order by ECNodeCount ,OrderId,ce.EventId
  Drop Table #ChildEvents
-- Next Event
Select  DimA = coalesce(ed.final_dimension_A,0),DimX = coalesce(ed.final_dimension_X,0),DimY = coalesce(ed.final_dimension_Y,0),DimZ = coalesce(ed.final_dimension_z,0),
        e.Event_Id,e.Event_Num,e.PU_Id,e.TimeStamp,e.Source_Event,ProdStatus_Desc,e.Event_Status,Prod_Code = case When e.Applied_Product is null then pp.prod_Code else pp1.prod_Code end,
 	  	 LowAlarm = isnull(@NextLAC,0),MedAlarm = isnull(@NextMAC,0),HighAlarm = isnull(@NextHAC,0),Pu_Desc,OrderNumber = Coalesce(co.Plant_Order_Number,'N/A'),Comment_Id = coalesce(e.Comment_Id,0),Applied_Product = Coalesce(e.Applied_Product,0),
 	  	 Process_Order = Coalesce(ppp.Process_Order, ppp2.Process_Order, 'N/A') 	  	 
   from events e
   Left Join Production_status on  Prodstatus_id = e.Event_Status
   Left Join Event_Details ed On ed.Event_Id = e.Event_Id
   Left Join Customer_Order_Line_Items col On ed.Order_Line_Id = col.Order_Line_Id
   Left Join Customer_Orders co on col.Order_Id = co.Order_Id
   Join Production_Starts s on (s.Start_Time <= e.timestamp and  (s.End_time > e.Timestamp or  s.End_time is null))  and s.pu_id = e.pu_id
   Join  Products pp on pp.prod_id = s.prod_id
   Left Join  Products pp1 on pp1.prod_id = e.Applied_Product
   Join Prod_Units pu on pu.Pu_Id = e.pu_id
   Left Join Production_Plan ppp on ed.PP_Id = ppp.PP_Id
   Left Join Production_Plan_Starts pps on (pps.Start_Time <= e.timestamp and  (pps.End_time > e.Timestamp or  pps.End_time is null))  and pps.pu_id = e.pu_id
   Left Join Production_Plan ppp2 on ppp2.PP_Id = pps.PP_Id       
  where e.event_id = @Next_Id
