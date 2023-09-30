CREATE PROCEDURE dbo.spServer_EMgrDoEventMoves  
@ET_Id int,
@Interval int,
@NewTime DateTime,
@UserId int
AS
declare
 	 @PUId int,
 	 @EventId int,
 	 @EventNum nVarChar(50),
 	 @EntryOn DateTime
declare @UnitList table (PU_Id int)
declare @CurrentEvents table (PU_Id int, TimeStamp DateTime)
declare @EventsToMove table (PU_Id int, EventId int)
insert into @UnitList (PU_Id)
Select distinct PU_Id
  from Event_Configuration
  where ET_Id = @ET_Id and Move_EndTime_Interval = @Interval
if (@ET_Id = 1) -- Production Events
Begin
 	 Insert Into @CurrentEvents (PU_Id, TimeStamp)
 	 Select e.PU_Id, max(e.TimeStamp)
 	   from Events e
 	   join @UnitList u on u.PU_Id = e.PU_Id
 	   group by e.PU_Id
 	 Insert Into @EventsToMove (PU_Id, EventId)
 	 Select e.PU_Id, e.Event_Id
 	   from Events e
 	   join @CurrentEvents c on c.PU_Id = e.PU_Id and c.TimeStamp = e.TimeStamp
 	   join Production_Status s on s.ProdStatus_Id = e.Event_Status and s.NoHistory = 1
 	 While Exists(Select * from @EventsToMove)
 	 Begin
 	  	 Select Top 1 @PUId = PU_Id, @EventId = EventId from @EventsToMove
 	  	 Set @EventNum = null
 	  	 exec spServer_DBMgrUpdEvent @EventId OUTPUT, @EventNum OUTPUT, @PUId, @NewTime, null, null, null, 2, 0, @UserId, null, null, null, null, @EntryOn, 1, null, null, null, null, null, null, null, null, 1, null
 	  	 Delete from @EventsToMove where EventId = @EventId 	 
 	 End 	 
End
