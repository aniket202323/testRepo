/*
truncate table local_CalcMgrGenealogyCache
exec dbo.spServer_CalcMgrLoadGenealogyTable2 77 ,75 ,'Jan 16 2006  6:50PM' ,'Jan 16 2006  6:50PM'
select * from local_CalcMgrGenealogyCache
select * from fnServer_CalcMgrResultEventsFromGeneCache2 (77 ,75 ,'Jan 16 2006  6:50PM' ,'Jan 16 2006  6:50PM')
*/
CREATE PROCEDURE dbo.spServer_CalcMgrLoadGenealogyTable
@puid int,
@resultPUId int,
@StartTimeRange datetime,
@EndTimeRange datetime
AS 
declare @tmptime datetime
declare @EventId int
declare @@EventId int
--
-- **** Get Genealogy Information ****
--
-- Single time, not range.  So find the next event.
if @StartTimeRange = @EndTimeRange
 	 begin
 	   select @tmptime = (Select Min(TimeStamp) From Events Where (PU_Id = @PUId) And (TimeStamp >= @StartTimeRange))
 	   Select @EventId=Event_Id From Events Where (PU_Id = @PUId) And (TimeStamp = @tmptime)
 	   if (@EventId is not null)
 	   begin
 	     exec spServer_CalcMgrAddToGeneTable @EventId
 	   end
 	 end
else
 	 begin
 	  	 Declare xxx_Cursor CURSOR LOCAL STATIC READ_ONLY For 
 	  	  	 Select event_id from events where TimeStamp > @StartTimeRange and TimeStamp <= @EndTimeRange and PU_Id=@puid 
 	  	 Open xxx_Cursor  
 	  	 Fetch_Loop:
 	  	   Fetch Next From xxx_Cursor Into @@eventId
 	  	   If (@@Fetch_Status = 0)
 	  	  	  	 Begin
 	  	  	  	   exec spServer_CalcMgrAddToGeneTable @@EventId
 	  	  	  	   Goto Fetch_Loop
 	  	  	  	 End
 	  	 Close xxx_Cursor
 	  	 Deallocate xxx_Cursor
 	 end
