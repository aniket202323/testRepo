Create Procedure dbo.spDS_GetNextWasteDetail
@PUId int,
@TimeStamp datetime,
@Orientation int,   -- 0-> previous, -1 --> next
@NewWasteId int Output,
@NewWasteStartTime datetime Output,
@NewWasteEndTime datetime Output
AS
 Declare @NewTimeStamp datetime
----------------------------------------------------------------
-- Initialize variables
---------------------------------------------------------------- 
 Select @NewWasteId = 0
----------------------------------------------------------------
-- Get immediate next/previous timestamp
----------------------------------------------------------------
 If (@Orientation = 1) -- next
  Select @NewTimeStamp = Min(TimeStamp) 
   From Waste_Event_Details
    where pu_id = @PUId 
     And TimeStamp > @TimeStamp
  Else  -- =1 , previous
   Select @NewTimeStamp = Max(TimeStamp) 
    From Waste_Event_Details
     Where pu_id = @PUId 
      And TimeStamp < @TimeStamp
----------------------------------------------------------------
-- Get WasteId for the immediate next/previous
---------------------------------------------------------------
  If (@NewTimeStamp Is Not NULL)
   Select @NewWasteId = Wed_Id , @NewWasteStartTime  = TimeStamp, @NewWasteEndTime =TimeStamp
    From Waste_Event_Details
     Where Pu_id = @PUId 
      And TimeStamp = @NewTimeStamp
  If (@NewWasteEndTime is null) Select @NewWasteEndTime = @NewWasteStartTime 
