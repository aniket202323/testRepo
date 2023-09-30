Create Procedure dbo.spDS_GetNextDowntimeDetail
@PUId int,
@TimeStamp datetime,
@Orientation int,   -- 0-> previous, -1 --> next
@NewDowntimeId int Output,
@NewDowntimeStartTime datetime Output,
@NewDowntimeEndTime datetime Output
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
 Select @NewDowntimeId = 0
----------------------------------------------------------------
-- Get immediate next/previous timestamp
----------------------------------------------------------------
 If (@Orientation = 1) -- next
  Select @NewTimeStamp = Min(Start_Time) 
   From Timed_Event_Details 
    where pu_id = @PUId 
     And Start_Time > @TimeStamp
  Else  -- =1 , previous
   Select @NewTimeStamp = Max(Start_Time) 
   From Timed_Event_Details 
    where pu_id = @PUId 
     And Start_Time < @TimeStamp
----------------------------------------------------------------
-- Get DowntimeId for the immediate next/previous
---------------------------------------------------------------
  If (@NewTimeStamp Is Not NULL)
   Select @NewDowntimeId = TeDET_Id , @NewDowntimeStartTime  = Start_Time, @NewDowntimeEndTime = End_Time
    From Timed_Event_Details  
     Where Pu_id = @PUId 
      And Start_Time = @NewTimeStamp
  If (@NewDowntimeEndTime is null) Select @NewDowntimeEndTime = @NewDowntimeStartTime 
