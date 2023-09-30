CREATE PROCEDURE dbo.spServer_CalcMgrGetEventId
@PU_Id int,
@Event_Type int,
@EventSubType int,
@TimeStamp datetime,
@TheId int OUTPUT
 AS
/*
 * BCS 01/04/24  Changed the data type of @TimeStamp from nVarChar(30) to datetime.
 *   SQL was passed as a datetime, but SQL would truncate the seconds doing a natural Convert.
 */
Declare
  @ActualId int,
  @TheTime DateTime,
  @TempTime DateTime,
  @MasterUnit int
declare @StartTime datetime
declare @EndTime datetime
declare @Confirmed int
declare @PUid int
declare @PrevStartTime datetime 
declare @PrevEndTime datetime
Select @TheId = 0
Select @ActualId = NULL
Select @TheTime = DateAdd(Second,-1,@TimeStamp)
Select @MasterUnit = NULL
Select @MasterUnit = Master_Unit From Prod_Units_Base Where PU_Id = @PU_Id
If (@MasterUnit Is Not NULL)
 	 Select @PU_Id = @MasterUnit
-- Turnups or ProdEventType
If (@Event_Type = 1) or (@event_Type = 26) 
  Begin
 	  	 select @temptime=null
    select @temptime=Min(TimeStamp) From Events Where (PU_Id = @PU_Id) And (TimeStamp > @TheTime)
    if (@temptime is not null)
 	     Select @ActualId = Event_Id 
 	  	     From Events 
 	  	  	   Where (PU_Id = @PU_Id) And (TimeStamp = @temptime)
    if (@ActualId Is NULL)
 	  	  	 begin
 	  	  	  	 select @temptime=null
 	  	  	  	 select @temptime=Min(end_time) From Event_pu_transitions Where (PU_Id = @PU_Id) And (end_time > @TheTime)
 	  	  	  	 if (@temptime is not null)
 	  	  	  	  	 Select @ActualId = Event_Id 
 	  	  	  	  	  	 From Event_pu_transitions 
 	  	  	  	  	  	 Where (PU_Id = @PU_Id) And (end_time = @temptime)
 	  	  	 end
  End
-- ProcessOrder  
Else If (@Event_Type = 19) or (@event_Type = 28) 
  Begin
    select @temptime=Min(End_Time) From Production_Plan_Starts Where (PU_Id = @PU_Id) And (End_Time > @TheTime)
    Select @ActualId = pp_Start_Id
      From Production_Plan_Starts 
      Where (PU_Id = @PU_Id) And (End_Time = @temptime)
  End
-- UserDefined
Else If (@Event_Type = 14)
  Begin
    select @temptime=Min(End_time) From user_defined_Events 
 	  	  	 Where (PU_Id = @PU_Id) and (Event_Subtype_id = @EventSubType) And (End_Time > @TheTime)
    Select @ActualId = UDE_Id From user_defined_Events 
      Where (PU_Id = @PU_Id) And (Event_Subtype_id = @EventSubType) and (End_time = @temptime)
  End
-- Input Geneology
Else If (@Event_Type = 17)
  Begin
    select @temptime=Min(a.timestamp) 
      From Event_Components a
      Join Events b on (b.Event_Id = a.Event_Id) and (b.PU_Id = @PU_Id)
      Where (a.timestamp > @TheTime)
    Select @ActualId = a.Component_Id 
      From Event_Components a
      Join Events b on (b.Event_Id = a.Event_Id) and (b.PU_Id = @PU_Id)
      Where (a.timestamp = @temptime)
  End
/*
-- UPTIME CHANGE
 	 1) Return NULL For ActualId for delay if there is no delay at this time.
 	 2) Add the Uptime one.  Return NULL for actualId for uptime if there is no uptime at this time.
*/
-- Delay
Else If (@Event_Type = 2) or (@Event_Type = 22)
  Begin
 	  	 If (@Event_Type = 2)
 	  	 begin
 	     Select @ActualId = TEDet_Id From Timed_Event_Details
 	       Where (PU_Id = @PU_Id) And (Start_Time < @TimeStamp) And (End_Time >= @TimeStamp) And (End_Time Is Not Null)
    end
 	  	 else
 	  	 begin
 	     Select @ActualId = TEDet_Id From Timed_Event_Details
 	       Where (PU_Id = @PU_Id) And (Start_Time <= @TimeStamp) And (End_Time >= @TimeStamp or End_Time is null) 
    end
    if (@ActualId is NULL)
 	  	 begin
      Select @TheId = @ActualId
 	    	 return
 	  	 end
    -- Downtime
    If (@Event_Type = 2)
    Begin
      Select @EndTime=End_Time, @StartTime=Start_Time, @PUId=PU_Id From Timed_Event_Details Where (TEDet_Id = @ActualId)
      Select @PrevStartTime = Max(Start_Time) From Timed_Event_Details Where (PU_Id = @PUId) And (Start_Time < @StartTime)
      Select @PrevEndTime = End_Time From Timed_Event_Details Where (PU_Id = @PUId) And (Start_Time = @PrevStartTime)
      if @EndTime is NULL and (@PrevEndTime <> @StartTime)
 	  	  	  	 select @ActualId = NULL --Uptime!
    End
    -- Uptime
    else If (@Event_Type = 22)
    Begin
      Select @EndTime=End_Time, @StartTime=Start_Time, @PUId=PU_Id From Timed_Event_Details Where (TEDet_Id = @ActualId)
      Select @PrevStartTime = Max(Start_Time) From Timed_Event_Details Where (PU_Id = @PUId) And (Start_Time < @StartTime)
      Select @PrevEndTime = End_Time From Timed_Event_Details Where (PU_Id = @PUId) And (Start_Time = @PrevStartTime)
      if (@PrevEndTime = @StartTime)
 	  	  	  	 select @ActualId = NULL --Downtime!
    End
  End
-- Waste
Else If (@Event_Type = 3)
  Begin
    Select @ActualId = WED_Id 
      From Waste_Event_Details
      Where (PU_Id = @PU_Id) And
            (TimeStamp = (Select Min(TimeStamp) From Waste_Event_Details Where (PU_Id = @PU_Id) And (TimeStamp > @TheTime)))
  End
-- Grade Change
Else If (@Event_Type = 4)
  Begin
    Select @ActualId = Start_Id 
      From Production_Starts
      Where (PU_Id = @PU_Id) And
 	     (Start_Time < @TimeStamp) And
            (End_Time >= @TimeStamp) And
            (End_Time Is Not Null)
  End
-- Segment Response
Else If (@Event_Type = 31)
 	 Begin
 	  	 Select @ActualId = a.Event_Id 
 	  	  	 From S95_Event a, SegmentResponse b, PAEquipment_Aspect_SOAEquipment c
 	  	  	 Where (c.PU_Id = @PU_Id) And (c.origin1equipmentid = b.EquipmentId) And
 	  	  	  	  	  	 (b.StartTime < dbo.fnServer_CmnConvertFromDbTime(@TimeStamp,'UTC')) And (b.EndTime >= dbo.fnServer_CmnConvertFromDbTime(@TimeStamp,'UTC')) And (b.EndTime Is Not NULL) And
 	  	  	  	  	  	 (b.SegmentResponseId = a.S95_Guid) And (a.Event_Type = 31)
 	 End
-- Work Response
Else If (@Event_Type = 32)
 	 Begin
 	  	 Select @ActualId = a.Event_Id 
 	  	  	 From S95_Event a, WorkResponse b, PAEquipment_Aspect_SOAEquipment c
 	  	  	 Where (c.PU_Id = @PU_Id) And (c.origin1equipmentid = b.EquipmentId) And
 	  	  	  	  	  	 (b.StartTime < dbo.fnServer_CmnConvertFromDbTime(@TimeStamp,'UTC')) And (b.EndTime >= dbo.fnServer_CmnConvertFromDbTime(@TimeStamp,'UTC')) And (b.EndTime Is Not NULL) And
 	  	  	  	  	  	 (b.WorkResponseId = a.S95_Guid) And (a.Event_Type = 32)
 	 End
If @ActualId Is Not Null
  Select @TheId = @ActualId
