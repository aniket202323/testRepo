CREATE PROCEDURE dbo.spServer_CalcMgrGetEventCalcTimes
@event_id int,
@Event_Type int,
@EventSubType int,
@inputvarid int,
@puid int, 
@resultvarid int,
@resultPUId int,
@calcid int,
@ResultOn datetime,
@StartTime datetime,
@EndTime datetime,
@IsLast int,
@IsNext int
as
declare @@eventid int
declare @Status int
declare @ErrorMsg nVarChar(255)
declare @MinStartTime datetime
declare @MaxEndTime datetime
declare @Now datetime
set @Now = dbo.fnServer_CmnGetDate(GetUtcDate())
DECLARE @CMGCTRunTimes TABLE(RunTime datetime, StartTime datetime, varid int, eventid int, isGenealogy int NULL)
Declare @TestData Table (EventId int NULL, Result nVarChar(255) NULL, ResultOn datetime)
If (@IsLast Is NULL) Or (@IsLast <> 1)
 	 Select @IsLast = 0
If (@IsNext Is NULL) Or (@IsNext <> 1)
 	 Select @IsNext = 0
if (@StartTime Is Not NULL) And (@EndTime Is Not NULL) And (@StartTime = @Endtime)
begin
  execute dbo.spServer_CalcMgrGetEventId @resultPUId, @event_type, @EventSubType, @StartTime, @event_Id OUTPUT
  Insert Into @CMGCTRunTimes (RunTime , StartTime , varid , eventid)
    Select * from dbo.fnServer_CalcMgrGetEventCalcTime (@resultPUId,@event_id, @event_type, @EventSubType,@ResultVarId)
  select distinct RunTime, StartTime, EventId from @CMGCTRunTimes where runtime is not null order by runtime
  return
end
If (@Event_Id Is Not NULL) And (@Event_Id <> 0) And (@IsLast = 0) And (@IsNext = 0) And (@StartTime Is NULL)
 	 Begin
 	  	 Insert Into @CMGCTRunTimes (RunTime , StartTime , varid , eventid)
 	  	 Select * from dbo.fnServer_CalcMgrGetEventCalcTime (@resultPUId,@event_id, @event_type, @EventSubType,@ResultVarId)
 	  	 select distinct RunTime, StartTime, EventId from @CMGCTRunTimes where runtime is not null order by runtime
 	  	 Return
 	 End
If (@IsLast = 1)
 	 Begin
 	  	 If (@ResultOn Is NULL)
 	  	  	 Return
 	  	 Select @StartTime = @ResultOn
 	  	 Select @EndTime = NULL
 	  	 Insert Into @TestData(EventId,Result,ResultOn) Select Event_Id,Result,Result_On from fnServer_CmnGetTestData(@inputvarid,@ResultPUId,@ResultOn,NULL,0,0,0,'>',1,1,0,0,0)
 	  	 Select @Status = NULL
 	  	 Select @Status = EventId, @ErrorMsg = Result From @TestData Where EventId = -1
 	  	 If (@Status Is NULL)
 	  	  	 Select @EndTime = ResultOn From @TestData
 	  	 if (@EndTime is null)
 	  	  	 Select @EndTime = @Now
 	 End
Set @MinStartTime = @StartTime
Set @MaxEndTime = @EndTime
If (@IsNext = 1)
 	 Begin
 	  	 If (@ResultOn Is NULL)
 	  	  	 Return
 	  	 Select @EndTime = @ResultOn
 	  	 Select @StartTime = NULL
 	  	 Insert Into @TestData(EventId,Result,ResultOn) select Event_Id,Result,Result_On from fnServer_CmnGetTestData(@inputvarid,@ResultPUId,@ResultOn,NULL,0,0,0,'<',1,1,0,0,0)
 	  	 Select @Status = NULL
 	  	 Select @Status = EventId, @ErrorMsg = Result From @TestData Where EventId = -1
 	  	 If (@Status Is NULL)
 	  	  	 Select @StartTime = ResultOn From @TestData
 	 End
if (@StartTime is not null) and ((@MinStartTime is null) or (@StartTime < @MinStartTime))
 	 Set @MinStartTime = @StartTime
if (@EndTime is not null) and ((@MaxEndTime is null) or (@EndTime > @MaxEndTime))
 	 Set @MaxEndTime = @EndTime
set @StartTime = @MinStartTime
set @EndTime = @MaxEndTime
If (@StartTime Is NULL) Or (@EndTime Is NULL)
 	 return
 	 
DECLARE @CMGCTEventIds Table(EventId int)
-- Turnups or ProdEventType
If (@Event_Type = 1) or (@Event_Type = 26)
begin
  insert into @CMGCTEventIds(eventid) Select Event_Id From Events Where (TimeStamp >= @StartTime and  TimeStamp <= @EndTime and @resultPUId=pu_id)
  insert into @CMGCTEventIds(eventid) Select Event_Id From Event_PU_Transitions Where (End_Time >= @StartTime and  End_Time <= @EndTime and @resultPUId=pu_id)
  execute dbo.spServer_CalcMgrGetEventId @resultPUId, @event_type, @EventSubType, @EndTime, @event_Id OUTPUT
  insert into @CMGCTEventIds(eventid) select @Event_Id
end
-- ProcessOrder
If (@Event_Type = 19) or (@Event_Type = 28)
begin
  insert into @CMGCTEventIds(eventid) Select pp_Start_Id From Production_Plan_Starts Where (End_Time >= @StartTime and  End_Time <= @EndTime and @resultPUId=pu_id)
  execute dbo.spServer_CalcMgrGetEventId @resultPUId, @event_type, @EventSubType, @EndTime, @event_Id OUTPUT
  insert into @CMGCTEventIds(eventid) select @Event_Id
end
-- User Defined
else If (@Event_Type = 14)
begin
  insert into @CMGCTEventIds(eventid) Select UDE_Id From user_defined_Events Where (End_Time >= @StartTime and  End_Time<= @EndTime and @resultPUId=pu_id and event_subtype_id=@EventSubType)
  execute dbo.spServer_CalcMgrGetEventId @resultPUId, @event_type, @EventSubType, @EndTime, @event_Id OUTPUT
  insert into @CMGCTEventIds(eventid) select @Event_Id
end
-- Input Geneolgy
else If (@Event_Type = 17)
begin
  insert into @CMGCTEventIds(eventid) 
    Select Component_Id From Event_Components a 
    join events b on (b.event_id = a.event_id) and (b.pu_id = @resultPUId)
    Where (a.Timestamp >= @StartTime and  a.Timestamp<= @EndTime)
  execute dbo.spServer_CalcMgrGetEventId @resultPUId, @event_type, @EventSubType, @EndTime, @event_Id OUTPUT
  insert into @CMGCTEventIds(eventid) select @Event_Id
end
-- Downtime and Uptime
else If (@Event_Type = 2 or @Event_Type=22)
begin
  DECLARE Loop_Cursor CURSOR LOCAL FORWARD_ONLY READ_ONLY
  For Select TEDet_Id From Timed_Event_Details Where (End_Time>=@StartTime and End_Time<=@EndTime and PU_Id=@resultPUId And End_Time Is Not Null)
  Open Loop_Cursor  
Fetch_Loop:
  Fetch Next From Loop_Cursor Into @@eventid
  If (@@Fetch_Status = 0)
  begin
    --execute dbo.spServer_CalcMgrGetEventCalcTime @@eventId, @event_type, @EventSubType 
    Insert Into @CMGCTRunTimes (RunTime , StartTime , varid , eventid)
      Select * from dbo.fnServer_CalcMgrGetEventCalcTime (@resultPUId,@@eventid, @event_type, @EventSubType,@ResultVarId)
    goto Fetch_Loop
  end
  Close Loop_Cursor 
  Deallocate Loop_Cursor
end
-- Waste
else If (@Event_Type = 3)
begin
  insert into @CMGCTEventIds(eventid) Select WED_Id From Waste_Event_Details Where (TimeStamp >= @StartTime and  TimeStamp <= @EndTime and @resultPUId=pu_id)
  execute dbo.spServer_CalcMgrGetEventId @resultPUId, @event_type, @EventSubType, @EndTime, @event_Id OUTPUT
  insert into @CMGCTEventIds(eventid) select @Event_Id
end
-- Grade Change
else If (@Event_Type = 4)
Begin
  insert into @CMGCTEventIds(eventid) 
    Select Start_Id From Production_Starts Where (End_Time >= @StartTime and  End_Time <= @EndTime and PU_Id = @resultPUId And End_Time Is Not Null)
End
-- Segment Response
Else If (@Event_Type = 31)
Begin
  insert into @CMGCTEventIds(eventid) 
 	  	 Select Event_Id From S95_Event a, SegmentResponse b, PAEquipment_Aspect_SOAEquipment c 
 	  	  	 Where (a.Event_Type = 31) And (a.S95_Guid = b.SegmentResponseId) And 
 	  	  	  	  	  	 (b.EndTime >= dbo.fnServer_CmnConvertFromDbTime(@StartTime,'UTC')) And (b.EndTime <= dbo.fnServer_CmnConvertFromDbTime(@EndTime,'UTC')) And
 	  	  	  	  	  	 (b.EquipmentId = c.origin1equipmentid) And (c.PU_Id = @resultPUId)
End
-- Work Response
Else If (@Event_Type = 32)
Begin
  insert into @CMGCTEventIds(eventid) 
 	  	 Select Event_Id From S95_Event a, WorkResponse b, PAEquipment_Aspect_SOAEquipment c 
 	  	  	 Where (a.Event_Type = 32) And (a.S95_Guid = b.WorkResponseId) And 
 	  	  	  	  	  	 (b.EndTime >= dbo.fnServer_CmnConvertFromDbTime(@StartTime,'UTC')) And (b.EndTime <= dbo.fnServer_CmnConvertFromDbTime(@EndTime,'UTC')) And
 	  	  	  	  	  	 (b.EquipmentId = c.origin1equipmentid) And (c.PU_Id = @resultPUId)
End
-- Debug line
--select * from @CMGCTEventIds
-- Loop through all the eventids that were in the time range and add their specific times to the table.
DECLARE zzz_Cursor CURSOR LOCAL FORWARD_ONLY READ_ONLY
FOR select eventid from @CMGCTEventIds
Open zzz_Cursor  
FetchLoop:
Fetch Next From zzz_Cursor Into @@eventid
If (@@Fetch_Status = 0)
begin
  if @@eventid <> 0
    begin
      --execute dbo.spServer_CalcMgrGetEventCalcTime @@eventid, @event_type, @EventSubType 
      Insert Into @CMGCTRunTimes (RunTime , StartTime , varid , eventid)
        Select * from dbo.fnServer_CalcMgrGetEventCalcTime (@resultPUId,@@eventid, @event_type, @EventSubType,@ResultVarId)
    end
  Goto FetchLoop
end
Close zzz_Cursor
Deallocate zzz_Cursor
select distinct RunTime, StartTime, EventId from @CMGCTRunTimes where runtime is not null order by runtime
