CREATE FUNCTION dbo.fnServer_CalcMgrGetVarCalcTimes(
@varid int, --Variable that was changed, input to resultvarid below
@puid int,
@resultvarid int, --variable dependant on the changed variables 
@resultPUId int,
@id int, -- Calc id
@RefTime datetime, --When the change occurred.
@IsEvent int, -- 1= event, 0 not 
@Now datetime -- must pass in GetDate because it's nondeterministic (stuff that changes) 
              -- and user-defined functions can't call this type of data
) 
     RETURNS @CMGCTRunTimes TABLE(RunTime datetime, StartTime datetime, varid int, eventid int, isGenealogy int)
AS 
/*
-- NOTE: MUST CALL THIS FUNCTION LIKE THIS. CAN'T DO THE GENEALOGY PART IN THE FUNCTION BECAUSE IT FILLS A USER TABLE (FUNCTIONS CAN'T CHANGE USER TABLES)
declare @IsEvent int
declare @Now datetime
declare @GenStartTime datetime
declare @GenEndTime datetime
declare @IsGenealogy int
Select @Now = dbo.fnServer_CmnGetDate(GetUTCDate()), @IsEvent = ?? - set to 1 for events, 0 for other
DECLARE @CMGCTRunTimes TABLE(RunTime datetime, StartTime datetime, varid int, eventid int, isGenealogy int NULL)
Insert Into @CMGCTRunTimes (RunTime, StartTime, varid, eventid, isGenealogy)
  Select RunTime, StartTime, varid, eventid, isGenealogy
    From dbo.fnServer_CalcMgrGetVarCalcTimes(@varid, @puid, @resultvarid, @resultPUId, @id, @RefTime, @IsEvent, @Now)
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
*/
BEGIN -- Function
  declare @OuterVarid int
  declare @OuterEntityid int
  declare @OuterAttributeid int
  declare @OuterIsGenealogy int
  declare @InnerVarid int
  declare @InnerAttributeid int
  declare @IsGenealogy int
  declare @StartTime datetime
  declare @EndTime datetime
  declare @PrevTime datetime
  declare @NextTime datetime
  -- Another Temp table.  Put info about the parameters to the calc so we look at them
  -- If any of theses are genealogy variables or genealogy variable aliases set a flag
  DECLARE  @CMGCTResults Table(entityId int, attributeId int, varid int, isGenealogy int)
  insert into @CMGCTResults(entityId, attributeId, varid, isGenealogy)
    Select entityId, attributeId, varid, CASE When Entityid in (6,7) THEN 1 ELSE 0 END
   	   From dbo.fnServer_CalcMgrGetVarCalcVarsAffected(@varid, @resultvarid, @id)
 	 update @CMGCTResults set isGenealogy = 0 where EntityId = 6 and varid <> @varid
  Select @IsGenealogy = 0
  -- Now, loop through the calc parameters and insert any run times it causes
  DECLARE Outer_Cursor CURSOR LOCAL FORWARD_ONLY READ_ONLY
  FOR Select Varid, EntityId, Attributeid, IsGenealogy
    From @CMGCTResults
    Where (Entityid = 7) or (Varid = @varid)
    Order by isGenealogy asc
   	  	  	 
  Open Outer_Cursor  
  OuterFetchLoop:
    Fetch Next From Outer_Cursor Into @OuterVarid,@OuterEntityid,@OuterAttributeid,@OuterIsGenealogy
    If (@@Fetch_Status = 0)
    begin
      -- Merged this call inside this function so we could use the same temp table. 
      --execute dbo.spServer_CalcMgrGetVarCalcTimes_phase32 @varid, @OuterAttributeid, @resultvarid, @id, @reftime, @IsEvent, @IsGenealogy
      -- If any of theses are genealogy variables or genealogy variable aliases set the 
      --   IsGenealogy flag because it's more efficient and we must do some special genealogy stuff after the cursor
      if @IsGenealogy = 0 and @OuterIsGenealogy = 1
       begin
         Select @IsGenealogy = 1
      end
      -- It is not a last or next.  Simply return the reference time
      if @OuterAttributeid <> 8 and  @OuterAttributeid <> 9
      begin
        insert into @CMGCTRunTimes(runtime,starttime, isGenealogy) values(@refTime,@reftime, @IsGenealogy)
      end
      -- It IS a last or next. Do a bunch of work to figure out the time ranges 
      else
      begin
        -- Get the range of times.  First we need the previous value time and the next
        if @OuterAttributeid = 8 -- last value
        begin
          select @NextTime=min(result_on) from tests where var_id=@varid and result_on >@RefTime and Result is not NULL and canceled = 0
          select @StartTime = @RefTime, @EndTime = @NextTime
        end
        else if @OuterAttributeid = 9 -- next value
        begin
          select @PrevTime=max(result_on) from tests where var_id=@varid and result_on <@RefTime and Result is not NULL and canceled = 0
          select @StartTime = @PrevTime, @EndTime = @RefTime
        end
        -- If this is an event based calc, then all we want is the time range.  Also if it is a genealogy var
        if @IsEvent = 1 or @IsGenealogy = 1
        begin
          insert into @CMGCTRunTimes(runtime,starttime, isGenealogy) values(@refTime,@reftime, @IsGenealogy)
          if @EndTime is null
          begin
            select @EndTIme = @Now
          end
          if @StartTime is null
          begin
            Select @StartTime = DateAdd(year,-1,@endtime)
          end
          insert into @CMGCTRunTimes(runtime,starttime, isGenealogy) values(@EndTime,@StartTime, @IsGenealogy)
        end
        else
        begin
          -- Now, loop through the calc parameters again for and insert any run times it causes
          DECLARE Inner_Cursor CURSOR LOCAL FORWARD_ONLY READ_ONLY
          FOR Select Varid, Attributeid
          	  	  	  	 From @CMGCTResults
          	  	  	  	 Where Entityid in (2,3)
          Open Inner_Cursor  
          InnerFetchLoop:
          Fetch Next From Inner_Cursor Into @InnerVarid,@InnerAttributeid
          If (@@Fetch_Status = 0)
          begin
            -- End time is a run time if one of the other inputs is last or next
            -- Get times of any values between the start and end
            if @OuterAttributeid = 8 -- last value
            begin
              if @InnerAttributeid = 8 or @InnerAttributeid = 9 -- last or next
              begin
                insert into @CMGCTRunTimes(runtime,starttime, isGenealogy) values(@EndTime,@endtime, @IsGenealogy)
              end
            end
            else if @OuterAttributeid = 9 -- next
            begin
              if @InnerAttributeid = 8 or @InnerAttributeid = 9  -- last or next
              begin
                insert into @CMGCTRunTimes(runtime,starttime, isGenealogy) values(@StartTime,@starttime, @IsGenealogy)
              end
            end
            -- This stuff is kinda ugly.  It could be written as on insert with the (is not null) stuff as part
            -- of the where, but that is 10 times slower  (Like this)
            --      insert into @CMGCTRunTimes(runtime,starttime)select Result_On,Result_On from tests 
            --        where var_id=@InnerVarid and (Result_On > @StartTime or @StartTime is null) and (Result_On < @EndTime or @EndTime is null) and Result is not NULL and canceled = 0
            if (@StartTime is not null and @EndTime is not null)
            begin   
              insert into @CMGCTRunTimes(runtime,starttime, isGenealogy) select Result_On,Result_On, @IsGenealogy from tests 
                where var_id=@InnerVarid and (Result_On > @StartTime) and (Result_On < @EndTime) and Result is not NULL and canceled = 0
            end
            else
            begin
              if (@StartTime is null and @EndTime is null) 
              begin
                insert into @CMGCTRunTimes(runtime,starttime, isGenealogy) select Result_On,Result_On, @IsGenealogy from tests 
                  where var_id=@InnerVarid and Result is not NULL and canceled = 0
              end
              else if (@StartTime is null) -- And EndTime is not null is implied
              begin
                insert into @CMGCTRunTimes(runtime,starttime, isGenealogy) select Result_On,Result_On, @IsGenealogy from tests 
                  where var_id=@InnerVarid and Result_On < @EndTime and Result is not NULL and canceled = 0
              end
              else
              begin
                insert into @CMGCTRunTimes(runtime,starttime, isGenealogy) select Result_On,Result_On, @IsGenealogy from tests 
                  where var_id=@InnerVarid and Result_On > @StartTime and Result is not NULL and canceled = 0
              end
            end
            Goto InnerFetchLoop
          end
          Close Inner_Cursor
          Deallocate Inner_Cursor
          -- Add any times where there is already result for the result var id
          insert into @CMGCTRunTimes(runtime, StartTime, isGenealogy)
            select Result_On, Result_On, @IsGenealogy from tests where var_id=@resultvarid and Result_On > @StartTime and Result_On < @EndTime and Result is not NULL and canceled = 0
        end -- END OF: Now, loop through the calc parameters again for and insert any run times it causes
      end  -- END OF: It IS a last or next. Do a bunch of work to figure out the time ranges 
      -- END OF: Merged this call inside this function so we could use the same temp table. 
      Goto OuterFetchLoop 
    end  -- "If (@@Fetch_Status = 0)" of OuterFetchLoop
    Close Outer_Cursor
    Deallocate Outer_Cursor
  RETURN
END --Function
