Create Procedure dbo.spDS_GetNextEventDetail
@PUId int,
@TimeStamp datetime,
@Orientation int,   -- 0-> previous, -1 --> next
@NewEventId int Output,
@NewEventStartTime datetime Output,
@NewEventEndTime datetime Output
AS
/*
Example
declare @out int
exec spds_getnexteventdetail  1, '2000-02-18 13:14:00.000' ,1,@out output
select @out
*/
 Declare @NewTimeStamp datetime
----------------------------------------------------------------
-- Initialize variables
---------------------------------------------------------------- 
 Select @NewEventId = 0
----------------------------------------------------------------
-- Get immediate next/previous timestamp
----------------------------------------------------------------
 If (@Orientation = 1) -- next
  Select @NewTimeStamp = Min(Timestamp) 
   From Events 
    where pu_id = @PUId 
     And Timestamp > @TimeStamp
  Else  -- =1 , previous
   Select @NewTimeStamp = Max(Timestamp) 
   From Events 
    where pu_id = @PUId 
     And Timestamp < @TimeStamp
----------------------------------------------------------------
-- Get EventId for the immediate next/previous
---------------------------------------------------------------
  If (@NewTimeStamp Is Not NULL)
   Select @NewEventId = Event_Id , @NewEventStartTime  = TimeStamp, @NewEventEndTime =TimeStamp
    From Events 
     Where Pu_id = @PUId 
      And Timestamp = @NewTimeStamp
  If (@NewEventEndTime is null) Select @NewEventEndTime = @NewEventStartTime 
