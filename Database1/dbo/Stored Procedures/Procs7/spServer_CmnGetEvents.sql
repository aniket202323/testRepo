CREATE PROCEDURE dbo.spServer_CmnGetEvents
@PU_Id int,
@StartTime datetime,
@EndTime datetime,
@EventType int,
@EventSubType int
AS
Declare
  @Id int,
  @Tmp int
Declare @UtcStartTime datetime
Declare @UtcEndTime datetime
Declare @EventIds Table(Event_Id int)
-- Production Event -------------------------------------------------------------
If (@EventType = 1) 
  Begin
    If (@StartTime = @EndTime)
      Begin
 	  	  	  	 Select @Id = NULL
 	  	  	  	 Select @Id = Event_Id From Events Where (PU_Id = @PU_Id) And (TimeStamp = (Select Min(TimeStamp) From Events Where (PU_Id = @PU_Id) And (TimeStamp >= @EndTime)))
        If (@Id Is Not NULL)
          Insert Into @EventIds(Event_Id) Values(@Id)
 	  	  	  	 Select @Id = NULL
 	  	  	  	 Select @Id = Event_Id From Events Where (PU_Id = @PU_Id) And (TimeStamp = (Select Max(TimeStamp) From Events Where (PU_Id = @PU_Id) And (TimeStamp < @StartTime)))
        If (@Id Is Not NULL)
          Insert Into @EventIds(Event_Id) Values(@Id)
 	  	  	  	 Select @Id = NULL
 	  	  	  	 Select @Id = Event_Id From Event_PU_Transitions Where (PU_Id = @PU_Id) And (End_Time = (Select Min(End_Time) From Event_PU_Transitions Where (PU_Id = @PU_Id) And (End_Time >= @EndTime)))
        If (@Id Is Not NULL)
          Insert Into @EventIds(Event_Id) Values(@Id)
 	  	  	  	 Select @Id = NULL
 	  	  	  	 Select @Id = Event_Id From Event_PU_Transitions Where (PU_Id = @PU_Id) And (End_Time = (Select Max(End_Time) From Event_PU_Transitions Where (PU_Id = @PU_Id) And (End_Time < @StartTime)))
        If (@Id Is Not NULL)
          Insert Into @EventIds(Event_Id) Values(@Id)
        Select Event_Id From @EventIds
      End
    Else
 	  	  	 Begin 
 	  	  	  	 Insert Into @EventIds(Event_Id)
 	  	  	  	  	 Select Event_Id From Events Where (PU_Id = @PU_Id) And (TimeStamp >= @StartTime) and (TimeStamp <= @EndTime)
 	  	  	  	  	 
 	  	  	  	 Insert Into @EventIds(Event_Id)
 	  	  	  	  	 Select Event_Id From Event_PU_Transitions Where (PU_Id = @PU_Id) And (End_Time >= @StartTime) and (End_Time <= @EndTime)
 	  	  	  	  	 
        Select Event_Id From @EventIds
 	  	  	  	  	 
 	  	  	 End
  End
-- User Defined ---------------------------------------------------------------------
If (@EventType = 14) 
  Begin
    If (@StartTime = @EndTime)
      Begin
 	  	  	  	 Select @Id = NULL
 	  	  	  	 Select @Id = UDE_Id From User_Defined_Events Where (PU_Id = @PU_Id) And (Event_SubType_Id = @EventSubType) And (End_Time = (Select Min(End_Time) From User_Defined_Events Where (PU_Id = @PU_Id) And (Event_SubType_Id = @EventSubType) And (End_Time >= @EndTime)))
        If (@Id Is Not NULL)
          Insert Into @EventIds(Event_Id) Values(@Id)
 	  	  	  	 Select @Id = NULL
 	  	  	  	 Select @Id = UDE_Id From User_Defined_Events Where (PU_Id = @PU_Id) And (Event_SubType_Id = @EventSubType) And (End_Time = (Select Max(End_Time) From User_Defined_Events Where (PU_Id = @PU_Id) And (Event_SubType_Id = @EventSubType) And (End_Time < @StartTime)))
        If (@Id Is Not NULL)
          Insert Into @EventIds(Event_Id) Values(@Id)
        Select Event_Id From @EventIds
      End
    Else 
      Select UDE_Id From User_Defined_Events 
 	  	  	  	 Where (PU_Id = @PU_Id) And 
 	  	  	  	  	  	  	 (Event_SubType_Id = @EventSubType) And
 	  	  	  	  	  	  	 (End_Time >= @StartTime) and (End_Time <= @EndTime)
  End
-- Downtime Or Uptime -------------------------------------------------------------------
If (@EventType = 2) Or (@EventTYpe = 22)
  Begin
    If (@StartTime = @EndTime)
      Begin
 	  	  	  	 Select @Id = NULL
 	  	  	  	 Select @Id = TEDet_Id From Timed_Event_Details Where (PU_Id = @PU_Id) And (End_Time = (Select Min(End_Time) From Timed_Event_Details Where (PU_Id = @PU_Id) And (End_Time >= @EndTime)))
        If (@Id Is Not NULL)
          Insert Into @EventIds(Event_Id) Values(@Id)
 	  	  	  	 Select @Id = NULL
 	  	  	  	 Select @Id = TEDet_Id From Timed_Event_Details Where (PU_Id = @PU_Id) And (End_Time = (Select Max(End_Time) From Timed_Event_Details Where (PU_Id = @PU_Id) And (End_Time < @EndTime)))
        If (@Id Is Not NULL)
          Insert Into @EventIds(Event_Id) Values(@Id)
        Select Event_Id From @EventIds
      End
    Else 
 	     Select TEDet_Id From Timed_Event_Details 
 	  	  	  	 Where (PU_Id = @PU_Id) And 
 	  	  	  	 (End_Time Is Not NULL) And (End_Time >= @StartTime) and (End_Time < @EndTime)
 	 End  
-- Waste ------------------------------------------------------------------------------
If (@EventType = 3) 
  Begin
    If (@StartTime = @EndTime)
      Begin
 	  	  	  	 Select @Id = NULL
 	  	  	  	 Select @Id = WED_Id From Waste_Event_Details Where (PU_Id = @PU_Id) And (TimeStamp = (Select Min(TimeStamp) From Waste_Event_Details Where (PU_Id = @PU_Id) And (TimeStamp >= @EndTime)))
        If (@Id Is Not NULL)
          Insert Into @EventIds(Event_Id) Values(@Id)
 	  	  	  	 Select @Id = NULL
 	  	  	  	 Select @Id = WED_Id From Waste_Event_Details Where (PU_Id = @PU_Id) And (TimeStamp = (Select Max(TimeStamp) From Waste_Event_Details Where (PU_Id = @PU_Id) And (TimeStamp < @EndTime)))
        If (@Id Is Not NULL)
          Insert Into @EventIds(Event_Id) Values(@Id)
        Select Event_Id From @EventIds
      End
    Else 
 	     Select WED_Id From Waste_Event_Details 
 	  	  	  	 Where (PU_Id = @PU_Id) And 
 	  	  	  	  	  	  	 (TimeStamp >= @StartTime) and (TimeStamp <= @EndTime)
  End
-- Product Change ----------------------------------------------------------------------
If (@EventType = 4) 
  Begin
    If (@StartTime = @EndTime)
      Begin
 	  	  	  	 Select @Id = NULL
 	  	  	  	 Select @Id = Start_Id From production_starts Where (PU_Id = @PU_Id) And (End_Time = (Select Min(End_Time) From production_starts Where (PU_Id = @PU_Id) And (End_Time >= @EndTime)))
        If (@Id Is Not NULL)
          Insert Into @EventIds(Event_Id) Values(@Id)
 	  	  	  	 Select @Id = NULL
 	  	  	  	 Select @Id = Start_Id From production_starts Where (PU_Id = @PU_Id) And (End_Time = (Select Max(End_Time) From production_starts Where (PU_Id = @PU_Id) And (End_Time < @EndTime)))
        If (@Id Is Not NULL)
          Insert Into @EventIds(Event_Id) Values(@Id)
        Select Event_Id From @EventIds
      End
    Else 
 	     Select Start_Id From Production_Starts 
 	  	  	  	 Where (PU_Id = @PU_Id) And 
 	  	  	  	 (End_Time Is Not NULL) And (End_Time >= @StartTime) and (End_Time < @EndTime)
  End
-- Process Order -------------------------------------------------------------------------
If (@EventType = 19) 
 	 Begin
    Select @Id = NULL
    Select @Id = Max(PP_Start_Id) From Production_Plan_Starts Where (PU_Id = @PU_Id) And (End_Time >= @StartTime) And (End_Time <= @EndTime)
    If (@Id Is Not Null)
 	  	  	 Select @Id
  End
-- Input Genealogy -------------------------------------------------------------------------
If (@EventType = 17) 
  Begin
    Select a.Component_Id 
      From Event_Components a
      Join Events b on (b.PU_Id = @PU_Id) and (a.Event_Id = b.Event_Id)
      Where (a.TimeStamp >= @StartTime) and (a.TimeStamp <= @EndTime)
  End
-- Segment Response -------------------------------------------------------------------------
If (@EventType = 31) 
  Begin
    Set @UtcStartTime 	 = dbo.fnServer_CmnConvertFromDbTime(@StartTime,'UTC')
    Set @UtcEndTime 	  	 = dbo.fnServer_CmnConvertFromDbTime(@EndTime,'UTC')
    If (@StartTime = @EndTime)
      Begin
        Select @Id = NULL
        Select Top 1 @Id = a.Event_Id
          From SegmentResponse b
          Join S95_Event a on a.Event_Type = 31 and a.S95_Guid = b.SegmentResponseId
          Join PAEquipment_Aspect_SOAEquipment c on c.PU_Id = @PU_Id And c.origin1equipmentid = b.EquipmentId
          Where b.EndTime >= @UtcEndTime
          order by b.EndTime Asc
        If (@Id Is Not NULL)
          Insert Into @EventIds(Event_Id) Values(@Id)
        Select @Id = NULL
        Select Top 1 @Id = a.Event_Id
          From SegmentResponse b
          Join S95_Event a on a.Event_Type = 31 and a.S95_Guid = b.SegmentResponseId
          Join PAEquipment_Aspect_SOAEquipment c  on c.PU_Id = @PU_Id And c.origin1equipmentid = b.EquipmentId
          Where b.EndTime < @UtcEndTime
          order by b.EndTime Desc
        If (@Id Is Not NULL)
          Insert Into @EventIds(Event_Id) Values(@Id)
        Select Event_Id From @EventIds
      End
    Else 
      Select a.Event_Id 
        From SegmentResponse b
        Join S95_Event a on a.Event_Type = 31 and a.S95_Guid = b.SegmentResponseId
        Join PAEquipment_Aspect_SOAEquipment c  on c.PU_Id = @PU_Id And c.origin1equipmentid = b.EquipmentId
        Where b.EndTime >= @UtcStartTime and b.EndTime <= @UtcEndTime
        order by b.EndTime Asc
  End
-- Work Response -------------------------------------------------------------------------
If (@EventType = 32) 
  Begin
    Set @UtcStartTime 	 = dbo.fnServer_CmnConvertFromDbTime(@StartTime,'UTC')
    Set @UtcEndTime 	  	 = dbo.fnServer_CmnConvertFromDbTime(@EndTime,'UTC')
    If (@StartTime = @EndTime)
      Begin
        Select @Id = NULL
        Select Top 1 @Id = a.Event_Id
          From WorkResponse b
          Join S95_Event a on a.Event_Type = 32 and a.S95_Guid = b.WorkResponseId
          Join PAEquipment_Aspect_SOAEquipment c on c.PU_Id = @PU_Id And c.origin1equipmentid = b.EquipmentId
          Where b.EndTime >= @UtcEndTime
          order by b.EndTime Asc
        If (@Id Is Not NULL)
          Insert Into @EventIds(Event_Id) Values(@Id)
        Select @Id = NULL
        Select Top 1 @Id = a.Event_Id
          From WorkResponse b
          Join S95_Event a on a.Event_Type = 32 and a.S95_Guid = b.WorkResponseId
          Join PAEquipment_Aspect_SOAEquipment c  on c.PU_Id = @PU_Id And c.origin1equipmentid = b.EquipmentId
          Where b.EndTime < @UtcEndTime
          order by b.EndTime Desc
        If (@Id Is Not NULL)
          Insert Into @EventIds(Event_Id) Values(@Id)
        Select Event_Id From @EventIds
      End
    Else 
      Select a.Event_Id 
        From WorkResponse b
        Join S95_Event a on a.Event_Type = 32 and a.S95_Guid = b.WorkResponseId
        Join PAEquipment_Aspect_SOAEquipment c  on c.PU_Id = @PU_Id And c.origin1equipmentid = b.EquipmentId
        Where b.EndTime >= @UtcStartTime and b.EndTime <= @UtcEndTime
        order by b.EndTime Asc
  End
