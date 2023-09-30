CREATE PROCEDURE dbo.spServer_CalcMgrGetCalcTimes
@varid int, -- Variable that triggered this.
@puid int, -- PUId of variable
@resultvarid int, -- Result variable id
@resultPUId int, -- PUId of result var 	  	 
@id int, -- id of calc
@RefTime datetime,  -- Time that trigger this all
@TriggerType int,  -- Type of calc trigger
@EventId int, -- Possible eventid.  Could be NULL if it was not known.
@EventType int  -- Type of event
as
declare @StartTime datetime
declare @EndTime datetime
declare @IsEvent int
declare @Now datetime
declare @GenStartTime datetime
declare @GenEndTime datetime
declare @IsGenealogy int
-- Temp table for the resulting runtimes
DECLARE @CMGCTRunTimes TABLE(RunTime datetime, StartTime datetime, varid int, eventid int, isGenealogy int NULL)
--Variable
if @TriggerType = 1
begin
  Select @IsEvent = 0
end
--Timed  
else if @TriggerType = 3
begin
  Select @IsEvent = 1
end
-- do nothing
else 
begin
  goto EndProc
end
Select @Now = dbo.fnServer_CmnGetDate(GetUTCDate()), @StartTime=NULL, @EndTime=NULL
Insert Into @CMGCTRunTimes (RunTime, StartTime, varid, eventid, isGenealogy)
  Select RunTime, StartTime, varid, eventid, isGenealogy
    From dbo.fnServer_CalcMgrGetVarCalcTimes(@varid, @puid, @resultvarid, @resultPUId, @id, @RefTime, @IsEvent, @Now)
--*******************
--IMPORTANT: Must run this after call to fnServer_CalcMgrGetVarCalcTimes
--*******************
-- For genealogy related calc we need to get the time range from the table.  Use that to
-- get the run times.
Select @GenStartTime=min(StartTime), @GenEndTime=max(RunTime) from @CMGCTRunTimes
Select @IsGenealogy=0
Select @IsGenealogy=count(isGenealogy) from @CMGCTRunTimes where isGenealogy = 1
if @IsGenealogy > 0 
begin
  -- merged spServer_CalcMgrGetGenealogyCalcTimes to here.
  exec dbo.spServer_CalcMgrLoadGenealogyTable @puid,@resultPUId,@GenStartTime,@GenEndTime
  -- Marty (1/16/2014) We don't want to delete previously found var times from the list (Jira Case PA-641)
  --delete from @CMGCTRunTimes
  insert into @CMGCTRunTimes(RunTime, StartTime, eventid)  
    select r.TimeStamp, COALESCE(e.start_time,(select max(TimeStamp) From Events Where (pU_Id = @resultpuid) And (TimeStamp < r.timestamp)),r.TimeStamp), eventId 
      from dbo.fnServer_CalcMgrResultEventsFromGeneCache (@puid,@resultPUId,@GenStartTime,@GenEndTime) r
      join events e on e.event_id = r.eventid
end
--*******************
--IMPORTANT: Thru here
--*******************
--Timed  (Use the VarGetCalcTimes with the EventFlag param set.  It will just return the 
--       time range.  That is ALL we want for timed events.  The C Code will determine the rest from that.
if @TriggerType = 3
begin
  select @StartTime=min(StartTime), @EndTime=max(RunTime) from @CMGCTRunTimes 
  delete from @CMGCTRunTimes
  insert into @CMGCTRunTimes(runtime, starttime, eventid) select RunTime=@EndTime, StartTime=@StartTime, EventId=0
end
EndProc: --Single exit point
-- Return the distinct times from the table
Select distinct RunTime, StartTime, EventId 
  From @CMGCTRunTimes 
  where runtime is not null 
  order by runtime
-- Cleanup
