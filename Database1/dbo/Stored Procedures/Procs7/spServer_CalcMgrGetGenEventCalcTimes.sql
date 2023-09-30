CREATE PROCEDURE dbo.spServer_CalcMgrGetGenEventCalcTimes
@event_id int,
@Event_Type int,
@EventSubType int,
@varid int,
@puid int, 
@resultvarid int,
@resultPUId int,
@calcid int,
@RefTime datetime,
@StartTime datetime,
@EndTime datetime
as
declare @Confirmed int
declare @@eventid int
declare @theid int
declare @@TimeStamp datetime
declare @IsEvent int
declare @Now datetime
declare @GenStartTime datetime
declare @GenEndTime datetime
declare @IsGenealogy int
DECLARE @CMGCTRunTimes TABLE(RunTime datetime, StartTime datetime, varid int, eventid int, isGenealogy int NULL)
if @puid is null
 	 select  @puid=COALESCE(m.Master_Unit, v.PU_Id) from variables_base v join Prod_Units_Base m on m.PU_Id = v.PU_Id  where v.var_id=@varid
 	 -- We have an event id.  So only get the times for this one event
 	 if (@Event_Id is not null and @Event_Id <> 0)
 	  	 begin
 	  	  	 Insert Into @CMGCTRunTimes (RunTime , StartTime , varid , eventid)
 	  	  	  	 Select * from dbo.fnServer_CalcMgrGetEventCalcTime (@resultPUId,@event_id, @event_type, @EventSubType,@ResultVarId)
 	  	  	 select distinct RunTime, StartTime, EventId from @CMGCTRunTimes where runtime is not null order by runtime
 	  	  	 return
 	  	 end
  Select @Now = dbo.fnServer_CmnGetDate(GetUTCDate()), @IsEvent = 1
  Insert Into @CMGCTRunTimes (RunTime, StartTime, varid, eventid, isGenealogy)
    Select RunTime, StartTime, varid, eventid, isGenealogy
      From dbo.fnServer_CalcMgrGetVarCalcTimes(@varid, @puid, @resultvarid, @resultPUId, @calcid, @RefTime, @IsEvent, @Now)
  --*******************
  --IMPORTANT: Must run this after call to fnServer_CalcMgrGetVarCalcTimes
  --*******************
  -- For genealogy related calc we need to get the time range from the table.  Use that to
  -- get the run times.
  Select @GenStartTime=min(StartTime), @GenEndTime=max(RunTime), @IsGenealogy=count(isGenealogy) from @CMGCTRunTimes
  if @IsGenealogy > 0 
  begin
    -- merged spServer_CalcMgrGetGenealogyCalcTimes to here.
    exec dbo.spServer_CalcMgrLoadGenealogyTable @puid,@resultPUId,@GenStartTime,@GenEndTime
    delete from @CMGCTRunTimes  
    insert into @CMGCTRunTimes(RunTime, StartTime, eventid)  
      select r.TimeStamp, COALESCE(e.start_time,(select max(TimeStamp) From Events Where (pU_Id = @resultpuid) And (TimeStamp < r.timestamp)),r.TimeStamp), eventId 
        from dbo.fnServer_CalcMgrResultEventsFromGeneCache (@puid,@resultPUId,@GenStartTime,@GenEndTime) r
        join events e on e.event_id = r.eventid
  end
  --*******************
  --IMPORTANT: Thru here
  --*******************
  DECLARE Loop_Cursor CURSOR LOCAL FORWARD_ONLY READ_ONLY
  FOR Select distinct RunTime From @CMGCTRunTimes
 	 Open Loop_Cursor 
 	 Fetch_Loop2:
 	  	 Fetch Next From Loop_Cursor Into @@TimeStamp
 	  	 If (@@Fetch_Status = 0)
 	  	  	 Begin
 	  	     exec spServer_CalcMgrGetEventId @puid, @Event_Type, @EventSubType, @@TimeStamp, @theid output
 	  	  	  	 update @CMGCTRunTimes set eventid = @theid where RunTime = @@TimeStamp
 	  	  	  	 goto Fetch_Loop2
 	  	  	 end
  Close Loop_Cursor 
  Deallocate Loop_Cursor
  select distinct RunTime, StartTime, EventId from @CMGCTRunTimes where runtime is not null order by runtime
