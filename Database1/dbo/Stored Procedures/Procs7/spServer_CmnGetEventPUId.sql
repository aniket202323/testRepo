CREATE PROCEDURE dbo.spServer_CmnGetEventPUId
@EventId int,
@EventType int
AS
Declare
 	 @PUId int
 	 
Select @PUId = NULL
If (@EventType = 1) Or (@EventType = 26) -- Production Event
 	 Begin
 	  	 Select @PUId = PU_Id From Events Where Event_Id = @EventId
 	  	 If (@PUId Is NULL)
 	  	  	 Select @PUId = PU_Id From Event_PU_Transitions Where Event_Id = @EventId
 	 End
Else If (@EventType = 2) Or (@EventType = 22) -- Downtime or Uptime
 	 Select @PUId = PU_Id From Timed_Event_Details Where TEDET_Id = @EventId
Else If (@EventType = 3) -- Waste
 	 Select @PUId = PU_Id From Waste_Event_Details Where WED_Id = @EventId
Else If (@EventType = 4) Or (@EventType = 5) -- Product Change
 	 Select @PUId = PU_Id From Production_Starts Where Start_Id = @EventId
Else If (@EventType = 14) -- Waste
 	 Select @PUId = PU_Id From User_Defined_Events Where UDE_Id = @EventId
Else If (@EventType = 17) -- Input Genealogy
 	 Select @PUId = PU_Id From Events Where Event_Id = @EventId
Else If (@EventType = 19) Or (@EventType = 28) -- Process Order
 	 Select @PUId = PU_Id From Production_Plan_Starts Where PP_Start_Id = @EventId
Else If (@EventType = 31) -- Segment Response
 	 Select @PUId = c.PU_Id From S95_Event a, SegmentResponse b, PAEquipment_Aspect_SOAEquipment c 
 	  	 Where (a.Event_Id = @EventId) And (a.Event_Type = 31) And (a.S95_GUID = b.SegmentResponseId) And (b.EquipmentId = c.Origin1EquipmentId)
Else If (@EventType = 32) -- Work Response
 	 Select @PUId = c.PU_Id From S95_Event a, WorkResponse b, PAEquipment_Aspect_SOAEquipment c 
 	  	 Where (a.Event_Id = @EventId) And (a.Event_Type = 32) And (a.S95_GUID = b.WorkResponseId) And (b.EquipmentId = c.Origin1EquipmentId)
Return(@PUId)
