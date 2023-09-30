CREATE FUNCTION dbo.fnServer_CalcMgrGetEventCalcTime(
@puid int,
@event_id int,
@Event_Type int,
@EventSubType int,
@ResultVarId int
) 
     RETURNS @CMGCTRunTimes Table (RunTime datetime, StartTime datetime, varid int, eventid int)
AS 
BEGIN -- Function
declare @StartTime datetime
declare @EndTime datetime
declare @Confirmed int
declare @PEIid int
declare @UseIt int
declare @SEId int
declare @PrevStartTime datetime 
declare @PrevEndTime datetime
if (@event_Id is NULL) or (@event_id = 0)
  return
select @StartTime = null
select @EndTime = null
-- Turnups or EventTime
If (@Event_Type = 1) or (@Event_Type = 26) 
Begin
 	 if (@puid is null) or (@puid = 0)
 	  	 begin
 	  	   Select @EndTime=TimeStamp, @StartTime=Start_Time, @PUId=pu_id From Events  Where (Event_Id = @Event_Id)
 	  	   If (@StartTime Is NULL)
 	  	  	  	 Select @StartTime = Max(TimeStamp) From Events Where (PU_Id = @PUId) And (TimeStamp < @EndTime)
 	  	   If (@StartTime Is not NULL)
 	  	  	  	 insert into @CMGCTRunTimes(runtime,starttime,eventid) Values(@EndTime, @StartTime, @Event_Id)
 	  	 end
 	 else
 	  	 begin
 	  	   Select @EndTime=TimeStamp, @StartTime=Start_Time From Events  Where (PU_Id = @puid) And (Event_Id = @Event_Id)
 	  	   If (@StartTime Is NULL) And (@EndTime Is Not NULL)
 	  	  	  	 Select @StartTime = Max(TimeStamp) From Events Where (PU_Id = @PUId) And (TimeStamp < @EndTime)
   	   If (@StartTime Is not NULL)
 	  	  	  	 insert into @CMGCTRunTimes(runtime,starttime,eventid) Values(@EndTime, @StartTime, @Event_Id)
 	  	  	 else
 	  	  	  	 begin
 	  	  	  	   Select @EndTime=End_Time, @StartTime=Start_Time From Event_PU_Transitions Where (PU_Id = @puid) And (Event_Id = @Event_Id)
 	  	  	  	   If (@StartTime Is NULL) And (@EndTime Is Not NULL)
 	  	  	  	  	  	 Select @StartTime = Max(End_Time) From Event_PU_Transitions Where (PU_Id = @PUId) And (End_Time < @EndTime)
   	  	  	  	 If (@StartTime Is not NULL)
 	  	  	  	  	  	 insert into @CMGCTRunTimes(runtime,starttime,eventid) Values(@EndTime, @StartTime, @Event_Id)
 	  	  	  	 end
 	  	 end
End
-- ProcessOrder
else If (@Event_Type = 19) or (@Event_Type = 28) 
Begin
  Select @EndTime=End_Time, @StartTime=Start_Time, @PUId=pu_id From Production_Plan_Starts Where (PP_Start_Id = @Event_Id)
  If (@StartTime Is NULL)
    Select @StartTime = Max(End_Time) From Production_Plan_Starts Where (PU_Id = @PUId) And (End_Time < @EndTime)
  If (@StartTime Is not NULL)
    insert into @CMGCTRunTimes(runtime,starttime,eventid) Values(@EndTime, @StartTime, @Event_Id)
End
-- Used Defined
else If (@Event_Type = 14)
Begin
  Select @EndTime=End_time, @StartTime=Start_Time, @PUId=pu_id From user_defined_Events  Where (UDE_Id = @Event_Id)
  If (@StartTime Is NULL)
    Select @StartTime = Max(end_time) From user_defined_Events Where (PU_Id = @PUId) And (End_time< @EndTime) and (@EventSubType = Event_Subtype_id)
  If (@StartTime Is not NULL)
    insert into @CMGCTRunTimes(runtime,starttime,eventid) Values(@EndTime, @StartTime, @Event_Id)
End
-- Input Geneolgy
else If (@Event_Type = 17)
Begin
 	 select @peiid=pei_id from variables_base where var_id=@ResultVarId
 	 select @seid=source_event_id  from event_components where component_id=@Event_Id
 	 select @puid=pu_id  from events where event_id=@seid
 	 select @UseIt=NULL
 	 select @UseIt=count(pei_id)  from prdexec_input_sources where pu_id = @puid and @peiid = pei_id
 	 if (@UseIt is not NULL and @UseIt > 0)
 	 begin
 	   Select @EndTime=a.timestamp, @StartTime=a.Start_Time, @PUId=b.pu_id
   	   From Event_Components a
     	 Join Events b on (b.Event_Id = a.Event_Id)
     	 Where (a.Component_Id = @Event_Id)
 	   If (@StartTime Is not NULL)
   	   insert into @CMGCTRunTimes(runtime,starttime,eventid) Values(@EndTime, @StartTime, @Event_Id)
 	 end
End
-- Downtime
else If (@Event_Type = 2)
Begin
  Select @EndTime=End_Time, @StartTime=Start_Time, @PUId=PU_Id From Timed_Event_Details Where (TEDet_Id = @Event_Id)
  Select @PrevStartTime = Max(Start_Time) From Timed_Event_Details Where (PU_Id = @PUId) And (Start_Time < @StartTime)
  Select @PrevEndTime = End_Time From Timed_Event_Details Where (PU_Id = @PUId) And (Start_Time = @PrevStartTime)
  if @EndTime is NULL and (@PrevEndTime <> @StartTime)
    return --Uptime!
  insert into @CMGCTRunTimes(runtime,starttime,eventid) Values(@EndTime, @StartTime, @Event_Id)
End
-- Uptime
else If (@Event_Type = 22)
Begin
  Select @EndTime=End_Time, @StartTime=Start_Time, @PUId=PU_Id From Timed_Event_Details Where (TEDet_Id = @Event_Id)
  Select @PrevStartTime = Max(Start_Time) From Timed_Event_Details Where (PU_Id = @PUId) And (Start_Time < @StartTime)
  Select @PrevEndTime = End_Time From Timed_Event_Details Where (PU_Id = @PUId) And (Start_Time = @PrevStartTime)
  if (@PrevEndTime <> @StartTime)
  begin
    insert into @CMGCTRunTimes(runtime,starttime,eventid) Values(@StartTime, @PrevEndTime, @Event_Id)
  end
End
-- Waste
else If (@Event_Type = 3)
Begin
  insert into @CMGCTRunTimes(runtime,starttime,eventid)
    Select TimeStamp, TimeStamp, @Event_Id From Waste_Event_Details  Where (WED_Id = @Event_Id)
End
-- Grade Change
else If (@Event_Type = 4)
Begin
  Select @EndTime=NULL
  Select @StartTime=NULL
  Select @EndTime=End_Time, @StartTime=Start_Time, @Confirmed=COALESCE(Confirmed,0) From Production_Starts  Where (Start_Id = @Event_Id)       
  if (@StartTime <> @EndTime and @Confirmed <> 0)
    insert into @CMGCTRunTimes(runtime,starttime,eventid) Values(@EndTime, @StartTime, @Event_Id)
End
-- Segment Response
else If (@Event_Type = 31)
Begin
  Select @EndTime=NULL
  Select @StartTime=NULL
 	 Select @StartTime = dbo.fnServer_CmnConvertToDbTime(StartTime,'UTC'), @EndTime = dbo.fnServer_CmnConvertToDbTime(EndTime,'UTC') 
 	  	 from S95_Event b
 	  	 Join SegmentResponse a on a.SegmentResponseId = b.S95_Guid
 	  	 Where (b.Event_Id = @Event_Id) And (b.Event_Type = 31)
 	 If (@StartTime Is not NULL) And (@EndTime Is Not NULL)
 	  	 insert into @CMGCTRunTimes(runtime,starttime,eventid) Values(@EndTime, @StartTime, @Event_Id)
End
-- Work Response
else If (@Event_Type = 32)
Begin
  Select @EndTime=NULL
  Select @StartTime=NULL
 	 Select @StartTime = dbo.fnServer_CmnConvertToDbTime(StartTime,'UTC'), @EndTime = dbo.fnServer_CmnConvertToDbTime(EndTime,'UTC') 
 	  	 from S95_Event b
 	  	 Join WorkResponse a on a.WorkResponseId = b.S95_Guid
 	  	 Where (b.Event_Id = @Event_Id) And (b.Event_Type = 32)
 	 If (@StartTime Is not NULL) And (@EndTime Is Not NULL)
 	  	 insert into @CMGCTRunTimes(runtime,starttime,eventid) Values(@EndTime, @StartTime, @Event_Id)
End
RETURN 
END -- Function
