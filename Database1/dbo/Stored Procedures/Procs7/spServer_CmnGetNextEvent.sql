CREATE PROCEDURE dbo.spServer_CmnGetNextEvent
@PUId int,
@TimeStamp datetime,
@Direction int,
@UseEquals int,
@EventType int,
@EventSubType int,
@Id int OUTPUT,
@ActualTime datetime OUTPUT
AS
Declare @PrevEndTime datetime
Declare @TimeLimit datetime
--   Direction
--   --------------
--   1) Backward
--   2) Forward
Select @Id = NULL
Select @ActualTime = NULL
Select @PUId = COALESCE(Master_Unit,PU_Id) From Prod_Units_Base Where PU_Id = @PUId
If (@EventType = 1) -- Production Event
  Begin
    If (@UseEquals = 1) And (@Direction = 1) 
      Select @ActualTime = Max(TimeStamp) From Events Where (PU_Id = @PUId) And (TimeStamp <= @TimeStamp) 
    Else
      If (@UseEquals = 1) And (@Direction = 2) 
        Select @ActualTime = Min(TimeStamp) From Events Where (PU_Id = @PUId) And (TimeStamp >= @TimeStamp)
      Else
        If (@Direction = 1)
          Select @ActualTime = Max(TimeStamp) From Events Where (PU_Id = @PUId) And (TimeStamp < @TimeStamp)
        Else
          If (@Direction = 2)
            Select @ActualTime = Min(TimeStamp) From Events Where (PU_Id = @PUId) And (TimeStamp > @TimeStamp)
    If (@ActualTime Is Not NULL)
      Select @Id = Event_Id From Events Where (PU_Id = @PUId) And (Timestamp = @ActualTime)
    Else
 	  	  	 Begin
 	  	     If (@UseEquals = 1) And (@Direction = 1) 
 	  	  	  	   Select @ActualTime = Max(End_Time) From Event_PU_Transitions Where (PU_Id = @PUId) And (End_Time <= @TimeStamp) 
 	  	  	  	 Else
 	  	  	  	  	 If (@UseEquals = 1) And (@Direction = 2) 
 	  	  	  	  	  	 Select @ActualTime = Min(End_Time) From Event_PU_Transitions Where (PU_Id = @PUId) And (End_Time >= @TimeStamp)
 	  	  	  	  	 Else
 	  	  	  	  	  	 If (@Direction = 1)
 	  	  	  	  	  	  	 Select @ActualTime = Max(End_Time) From Event_PU_Transitions Where (PU_Id = @PUId) And (End_Time < @TimeStamp)
 	  	  	  	  	  	 Else
 	  	  	  	  	  	  	 If (@Direction = 2)
 	  	  	  	  	  	  	  	 Select @ActualTime = Min(End_Time) From Event_PU_Transitions Where (PU_Id = @PUId) And (End_Time > @TimeStamp)
 	  	  	  	 If (@ActualTime Is Not NULL)
 	  	  	  	  	 Select @Id = Event_Id From Event_PU_Transitions Where (PU_Id = @PUId) And (End_Time = @ActualTime)
 	  	  	 End
  End
If (@EventType = 2) -- Downtime
  Select @Id = TEDet_Id, @ActualTime = End_Time From Timed_Event_Details Where (PU_Id = @PUId) And (Start_Time < @TimeStamp) And (End_Time >= @TimeStamp)
If (@EventType = 3) -- Waste
  Begin
    If (@UseEquals = 1) And (@Direction = 1) 
      Select @ActualTime = Max(TimeStamp) From Waste_Event_Details Where (PU_Id = @PUId) And (TimeStamp <= @TimeStamp) 
    Else
      If (@UseEquals = 1) And (@Direction = 2) 
        Select @ActualTime = Min(TimeStamp) From Waste_Event_Details Where (PU_Id = @PUId) And (TimeStamp >= @TimeStamp)
      Else
        If (@Direction = 1)
          Select @ActualTime = Max(TimeStamp) From Waste_Event_Details Where (PU_Id = @PUId) And (TimeStamp < @TimeStamp)
        Else
          If (@Direction = 2)
            Select @ActualTime = Min(TimeStamp) From Waste_Event_Details Where (PU_Id = @PUId) And (TimeStamp > @TimeStamp)
    If (@ActualTime Is Not NULL)
      Select @Id = WED_Id From Waste_Event_Details Where (PU_Id = @PUId) And (Timestamp = @ActualTime)
  End
If (@EventType = 4) -- Product Change
  Select @Id = Start_Id, @ActualTime = End_Time From Production_Starts Where (PU_Id = @PUId) And (Start_Time < @TimeStamp) And (End_Time >= @TimeStamp)
If (@EventType = 22) -- Uptime
  Begin
    Select @ActualTime = Min(Start_Time) From Timed_Event_Details Where (PU_Id = @PUId) And (Start_Time >= @TimeStamp)
    If (@ActualTime Is Not NULL)
      Begin
        Select @PrevEndTime = NULL
        Select @PrevEndTime = Max(End_Time) From Timed_Event_Details Where (PU_Id = @PUId) And (End_Time <= @TimeStamp)
        If (@PrevEndTime Is Not NULL)
          If (@PrevEndTime <> @ActualTime)
            Select @Id = TEDet_Id From Timed_Event_Details Where (PU_Id = @PUId) And (Start_Time = @ActualTime)
      End
  End
If (@EventType = 14) -- User Defined
  Begin
    If (@UseEquals = 1) And (@Direction = 1) 
      Select @ActualTime = Max(End_Time) From User_Defined_Events Where (PU_Id = @PUId) And (End_Time <= @TimeStamp)  And (Event_SubType_Id = @EventSubType)
    Else
      If (@UseEquals = 1) And (@Direction = 2) 
        Select @ActualTime = Min(End_Time) From User_Defined_Events Where (PU_Id = @PUId) And (End_Time >= @TimeStamp) And (Event_SubType_Id = @EventSubType)
      Else
        If (@Direction = 1)
          Select @ActualTime = Max(End_Time) From User_Defined_Events Where (PU_Id = @PUId) And (End_Time < @TimeStamp) And (Event_SubType_Id = @EventSubType)
        Else
          If (@Direction = 2)
            Select @ActualTime = Min(End_Time) From User_Defined_Events Where (PU_Id = @PUId) And (End_Time > @TimeStamp) And (Event_SubType_Id = @EventSubType)
    If (@ActualTime Is Not NULL)
      Select @Id = UDE_Id From User_Defined_Events Where (PU_Id = @PUId) And (End_Time = @ActualTime) And (Event_SubType_Id = @EventSubType)
  End
If (@EventType = 17) -- Event Component
  Begin
    If (@UseEquals = 1) And (@Direction = 1) 
      Select @ActualTime = Max(ec.Timestamp) From Event_Components ec join Events e on e.Event_Id = ec.Event_Id where (e.PU_Id = @PUId) And (ec.Timestamp <= @TimeStamp)
    Else
      If (@UseEquals = 1) And (@Direction = 2) 
        Select @ActualTime = Min(ec.Timestamp) From Event_Components ec join Events e on e.Event_Id = ec.Event_Id where (e.PU_Id = @PUId) And (ec.Timestamp >= @TimeStamp)
      Else
        If (@Direction = 1)
          Select @ActualTime = Max(ec.Timestamp) From Event_Components ec join Events e on e.Event_Id = ec.Event_Id where (e.PU_Id = @PUId) And (ec.Timestamp < @TimeStamp)
        Else
          If (@Direction = 2)
            Select @ActualTime = Min(ec.Timestamp) From Event_Components ec join Events e on e.Event_Id = ec.Event_Id where (e.PU_Id = @PUId) And (ec.Timestamp > @TimeStamp)
    If (@ActualTime Is Not NULL)
      Select @Id = ec.Component_Id From Event_Components ec join Events e on e.Event_Id = ec.Event_Id Where (e.PU_Id = @PUId) And (ec.Timestamp = @ActualTime)
  End
If (@EventType = 19) -- Process Order -- DE113817, change EventType from 27 to 19 For Process order
  Begin
    If (@UseEquals = 1) And (@Direction = 1) 
      Select @ActualTime = Max(End_Time) From Production_Plan_Starts Where (PU_Id = @PUId) And (End_Time <= @TimeStamp)
    Else
      If (@UseEquals = 1) And (@Direction = 2) 
        Select @ActualTime = Min(End_Time) From Production_Plan_Starts Where (PU_Id = @PUId) And (End_Time >= @TimeStamp)
      Else
        If (@Direction = 1)
          Select @ActualTime = Max(End_Time) From Production_Plan_Starts Where (PU_Id = @PUId) And (End_Time < @TimeStamp)
        Else
          If (@Direction = 2)
            Select @ActualTime = Min(End_Time) From Production_Plan_Starts Where (PU_Id = @PUId) And (End_Time > @TimeStamp)
    If (@ActualTime Is Not NULL)
      Select @Id = PP_Start_Id From Production_Plan_Starts Where (PU_Id = @PUId) And (End_Time = @ActualTime)
  End
If (@EventType = 31) -- Segment Response
 	 Begin
 	  	 Set @TimeLimit = dbo.fnServer_CmnConvertFromDbTime(@TimeStamp,'UTC')
    If (@UseEquals = 1) And (@Direction = 1) 
 	  	  	 Select @ActualTime = Max(b.EndTime)
 	  	  	  	 From S95_Event a, SegmentResponse b, PAEquipment_Aspect_SOAEquipment c
 	  	  	  	 Where (a.Event_Type = 31) And (c.PU_Id = @PUId) And (c.origin1equipmentid = b.EquipmentId) And (b.SegmentResponseId = a.S95_Guid) And
 	  	  	  	 (b.EndTime <= @TimeLimit)
    Else
      If (@UseEquals = 1) And (@Direction = 2) 
 	  	  	  	 Select @ActualTime = Min(b.EndTime)
 	  	  	  	  	 From S95_Event a, SegmentResponse b, PAEquipment_Aspect_SOAEquipment c
 	  	  	  	  	 Where (a.Event_Type = 31) And (c.PU_Id = @PUId) And (c.origin1equipmentid = b.EquipmentId) And (b.SegmentResponseId = a.S95_Guid) And
 	  	  	  	  	 (b.EndTime >= @TimeLimit)
      Else
        If (@Direction = 1)
 	  	  	  	  	 Select @ActualTime = Max(b.EndTime)
 	  	  	  	  	  	 From S95_Event a, SegmentResponse b, PAEquipment_Aspect_SOAEquipment c
 	  	  	  	  	  	 Where (a.Event_Type = 31) And (c.PU_Id = @PUId) And (c.origin1equipmentid = b.EquipmentId) And (b.SegmentResponseId = a.S95_Guid) And
 	  	  	  	  	  	 (b.EndTime < @TimeLimit)
        Else
          If (@Direction = 2)
 	  	  	  	  	  	 Select @ActualTime = Min(b.EndTime)
 	  	  	  	  	  	  	 From S95_Event a, SegmentResponse b, PAEquipment_Aspect_SOAEquipment c
 	  	  	  	  	  	  	 Where (a.Event_Type = 31) And (c.PU_Id = @PUId) And (c.origin1equipmentid = b.EquipmentId) And (b.SegmentResponseId = a.S95_Guid) And
 	  	  	  	  	  	  	 (b.EndTime > @TimeLimit)
    If (@ActualTime Is Not NULL)
 	  	 Begin
 	  	  	 Set @TimeLimit = @ActualTime
 	  	  	 Set @ActualTime = dbo.fnServer_CmnConvertToDbTime(@ActualTime,'UTC')
 	  	  	 Select @Id = Event_Id 
 	  	  	  	 From S95_Event a, SegmentResponse b, PAEquipment_Aspect_SOAEquipment c
 	  	  	  	 Where (a.Event_Type = 31) And (c.PU_Id = @PUId) And (c.origin1equipmentid = b.EquipmentId) And (b.SegmentResponseId = a.S95_Guid) And
 	  	  	  	 (b.EndTime = @TimeLimit)
 	  	 End
 	 End
If (@EventType = 32) -- Work Response
 	 Begin
 	  	 Set @TimeLimit = dbo.fnServer_CmnConvertFromDbTime(@TimeStamp,'UTC')
    If (@UseEquals = 1) And (@Direction = 1) 
 	  	  	 Select @ActualTime = Max(b.EndTime)
 	  	  	  	 From S95_Event a, WorkResponse b, PAEquipment_Aspect_SOAEquipment c
 	  	  	  	 Where (a.Event_Type = 32) And (c.PU_Id = @PUId) And (c.origin1equipmentid = b.EquipmentId) And (b.WorkResponseId = a.S95_Guid) And
 	  	  	  	 (b.EndTime <= @TimeLimit)
    Else
      If (@UseEquals = 1) And (@Direction = 2) 
 	  	  	  	 Select @ActualTime = Min(b.EndTime)
 	  	  	  	  	 From S95_Event a, WorkResponse b, PAEquipment_Aspect_SOAEquipment c
 	  	  	  	  	 Where (a.Event_Type = 32) And (c.PU_Id = @PUId) And (c.origin1equipmentid = b.EquipmentId) And (b.WorkResponseId = a.S95_Guid) And
 	  	  	  	  	 (b.EndTime >= @TimeLimit)
      Else
        If (@Direction = 1)
 	  	  	  	  	 Select @ActualTime = Max(b.EndTime)
 	  	  	  	  	  	 From S95_Event a, WorkResponse b, PAEquipment_Aspect_SOAEquipment c
 	  	  	  	  	  	 Where (a.Event_Type = 32) And (c.PU_Id = @PUId) And (c.origin1equipmentid = b.EquipmentId) And (b.WorkResponseId = a.S95_Guid) And
 	  	  	  	  	  	 (b.EndTime < @TimeLimit)
        Else
          If (@Direction = 2)
 	  	  	  	  	  	 Select @ActualTime = Min(b.EndTime)
 	  	  	  	  	  	  	 From S95_Event a, WorkResponse b, PAEquipment_Aspect_SOAEquipment c
 	  	  	  	  	  	  	 Where (a.Event_Type = 32) And (c.PU_Id = @PUId) And (c.origin1equipmentid = b.EquipmentId) And (b.WorkResponseId = a.S95_Guid) And
 	  	  	  	  	  	  	 (b.EndTime > @TimeLimit)
    If (@ActualTime Is Not NULL)
    Begin
 	  	  	 Set @TimeLimit = @ActualTime
 	  	  	 Set @ActualTime = dbo.fnServer_CmnConvertToDbTime(@ActualTime,'UTC')
 	  	  	 Select @Id = Event_Id 
 	  	  	  	 From S95_Event a, WorkResponse b, PAEquipment_Aspect_SOAEquipment c
 	  	  	  	 Where (a.Event_Type = 32) And (c.PU_Id = @PUId) And (c.origin1equipmentid = b.EquipmentId) And (b.WorkResponseId = a.S95_Guid) And
 	  	  	  	 (b.EndTime = @TimeLimit)
 	  	 End
 	 End
 	 
If (@Id Is NULL)
 	 Begin
 	   Select @Id = 0
 	   Select @ActualTime = NULL
 	  End
