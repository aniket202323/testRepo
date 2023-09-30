Create Procedure dbo.spGE_GetRelatedEvents
  @Event_Id int,
  @Child 	 Int = 1,
  @Levels   Int = 20
 AS
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
 	 @NextParent 	 Int
Declare @Id Int,@Count Int,@OrderId Int
set nocount on
select @Levels = coalesce(@Levels,20)
Create Table #Events (EventId Int,SEvent int,OrderId Int,ComponentId Int,NodeCount Int)
Create Table #TempEvent1(EventId Int,SEvent int,ComponentId Int)
Create Table #TempEvent2(EventId Int,SEvent int,ComponentId Int)
Create Table #LoopEvents (EventId Int,SEvent int,ComponentId Int)
Insert Into #TempEvent2(EventId,SEvent,ComponentId) Values (@Event_Id,0,0)
Select @Order = 0
If  @Child = 0 
  Begin
 	 PLoop:
 	 Delete From #TempEvent1
 	 Insert Into #TempEvent1(EventId,SEvent,ComponentId)
 	 Select Event_Id,Source_Event_Id,Component_Id
 	     From Event_Components
 	     Where Source_Event_Id In (select EventId From  #TempEvent2) 
 	 If (Select Count(*) From  #TempEvent1) > 0
 	    Begin
 	       Insert Into  #Events (EventId,Sevent,OrderId,ComponentId) Select EventId,Sevent,@Order,ComponentId From #TempEvent1
 	  	   Insert Into #LoopEvents(EventId,Sevent,ComponentId)
 	  	   Select t.Eventid,t.SEvent,t.ComponentId
 	  	  	 From #Events t
 	  	  	 Join #Events s on t.Eventid = s.SEvent
 	  	   Delete from #TempEvent1 where Eventid in (select EventId From #LoopEvents)
 	  	   Truncate Table #LoopEvents
 	       Delete From #TempEvent2
 	       Insert Into #TempEvent2 Select EventId,Sevent,ComponentId From #TempEvent1
 	       Select @Order = @Order + 1
 	  	   If @Order < @Levels 
 	         Goto PLoop
 	    End
 	 Declare PEvent INSENSITIVE  Cursor  For
 	 Select Count(*),SEvent,OrderId  From #Events Group By SEvent,OrderId
 	 Open PEvent
 	 PEventLoop:
 	 Fetch next from PEvent into @Count,@Id,@OrderId
 	 If @@Fetch_Status = 0
 	 Begin
 	   Update #Events set NodeCount = @Count Where OrderId = @OrderId and SEvent = @Id
 	   Goto PEventLoop
 	 End
 	 Close PEvent
    Deallocate PEvent
  End 	 
Else
 Begin
 	 CLoop:
 	 Delete From #TempEvent1
 	 Insert Into #TempEvent1(EventId,SEvent,ComponentId)
 	   Select Source_Event_Id,Event_Id,Component_Id
 	     From Event_Components
 	     Where Event_Id In (select EventId From  #TempEvent2) 
 	   If (Select Count(*) From  #TempEvent1) > 0
 	    Begin
 	       Insert Into  #Events (EventId,Sevent,OrderId,ComponentId) Select EventId,SEvent,@Order,ComponentId From #TempEvent1
 	  	   Insert Into #LoopEvents(EventId,Sevent,ComponentId)
 	  	   Select t.Eventid,t.SEvent,t.ComponentId
 	  	  	 From #Events t
 	  	  	 Join #Events s on t.Eventid = s.SEvent
 	  	   Delete from #TempEvent1 where SEvent in (select SEvent From #LoopEvents)
 	  	   Truncate Table #LoopEvents
 	       Truncate Table #TempEvent2
 	       Insert Into #TempEvent2 (EventId,Sevent,ComponentId ) Select EventId,Sevent,ComponentId From #TempEvent1
 	       Select @Order = @Order + 1
 	  	   If @Order < @Levels 
 	        	 Goto CLoop
 	    End
 	 
 	 Declare CEvent INSENSITIVE  Cursor  For
 	 Select Count(*),EventId,OrderId  From #Events Group By EventId,OrderId
 	 Open CEvent
 	 CEventLoop:
 	 Fetch next from CEvent into @Count,@Id,@OrderId
 	 If @@Fetch_Status = 0
 	 Begin
 	   Update #Events set NodeCount = @Count Where OrderId = @OrderId and EventId = @Id
 	   Goto CEventLoop
 	 End
 	 Close CEvent
 	 Deallocate CEvent
 End
Drop table #LoopEvents
Drop Table #TempEvent1
Drop Table #TempEvent2
Select * from #Events order by OrderId
Drop table #Events
