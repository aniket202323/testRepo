/*
*/
CREATE FUNCTION dbo.fnServer_CalcMgrResultEventsFromGeneCache(
@puid int,
@resultPUId int,
@StartTimeRange datetime,
@EndTimeRange datetime
) 
     RETURNS @CMResultEvents TABLE (ComponentId int, EventId int, EventUnit int, TimeStamp datetime, GenealogyLevel int NULL)
AS 
BEGIN -- Function
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
 	     insert into @CMResultEvents (ComponentId, EventId, EventUnit, TimeStamp, GenealogyLevel)
 	        select ComponentId, EventId, EventUnit, TimeStamp, GenealogyLevel from CalcMgrGenealogyCache where OriginalEventId=@EventId and eventunit = @resultpuid
 	   end
 	 end
else
 	 begin
    insert into @CMResultEvents (ComponentId, EventId, EventUnit, TimeStamp, GenealogyLevel)
      select c.ComponentId, c.EventId, c.EventUnit, c.TimeStamp, c.GenealogyLevel 
        from Events e 
        join CalcMgrGenealogyCache c on c.OriginalEventId = e.Event_Id and c.EventUnit = @resultpuid
        where e.TimeStamp > @StartTimeRange and e.TimeStamp <= @EndTimeRange and e.PU_Id=@puid
/*
 	  	 Declare xxx_Cursor CURSOR LOCAL STATIC READ_ONLY For 
 	  	  	 Select event_id from events where TimeStamp > @StartTimeRange and TimeStamp <= @EndTimeRange and PU_Id=@puid 
 	  	 Open xxx_Cursor  
 	  	 Close xxx_Cursor
 	  	 Deallocate xxx_Cursor
 	  	 Fetch_Loop:
 	  	   Fetch Next From xxx_Cursor Into @@eventId
 	  	   If (@@Fetch_Status = 0)
 	  	  	  	 Begin
 	  	       insert into @CMResultEvents (ComponentId, EventId, EventUnit, TimeStamp, GenealogyLevel)
 	  	          select ComponentId, EventId, EventUnit, TimeStamp, GenealogyLevel from CalcMgrGenealogyCache where OriginalEventId=@@EventId and eventunit = @resultpuid
 	  	  	  	   Goto Fetch_Loop
 	  	  	  	 End
 	  	 Close xxx_Cursor
 	  	 Deallocate xxx_Cursor
*/
 	 end
RETURN 
END -- Function
