CREATE PROCEDURE dbo.spServer_CmnGetUDEInfo
@UDEId int,
@PUId int OUTPUT,
@StartTime datetime OUTPUT,
@EndTime datetime OUTPUT,
@EventSubType int OUTPUT
AS
Select @PUId = NULL
Select @StartTime = NULL
Select @EndTime = NULL
Select @EventSubType = NULL
Select @PUId = PU_Id, @EndTime = End_Time, @EventSubType = Event_Subtype_Id, @StartTime = Start_Time 
  From User_Defined_Events
  Where UDE_Id = @UDEId
If (@PUId Is NULL)
  Return
If (@StartTime Is NULL)
  Select @StartTime = Max(End_Time) From User_Defined_Events Where (PU_Id = @PUId) And (Event_Subtype_Id = @EventSubType) And (End_Time < @EndTime)
If (@StartTime Is NULL)
  Select @PUId = NULL
