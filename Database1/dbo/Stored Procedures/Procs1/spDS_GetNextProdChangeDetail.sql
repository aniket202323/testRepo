Create Procedure dbo.spDS_GetNextProdChangeDetail
@PUId int,
@TimeStamp datetime,
@Orientation int,   -- 0-> previous, -1 --> next
@NewStartId int Output,
@NewProdChangeStartTime datetime Output,
@NewProdChangeEndTime datetime Output
AS
/*
Example
declare @out int
exec spds_getnextProdChangedetail 33, '4/6/00 06:33:00 AM' ,1,@out output
select @out
*/
 Declare @NewTimeStamp datetime
----------------------------------------------------------------
-- Initialize variables
---------------------------------------------------------------- 
 Select @NewStartId = 0
----------------------------------------------------------------
-- Get immediate next/previous timestamp
----------------------------------------------------------------
 If (@Orientation = 1) -- next
  Select @NewTimeStamp = Min(Start_Time) 
   From Production_Starts
    where Pu_Id = @PUId 
     And Start_Time > @TimeStamp
  Else  -- =1 , previous
   Select @NewTimeStamp = Max(Start_Time) 
    From Production_Starts
     Where Pu_Id = @PUId 
      And Start_Time < @TimeStamp
----------------------------------------------------------------
-- Get Id for the immediate next/previous
---------------------------------------------------------------
  If (@NewTimeStamp Is Not NULL)
   Select @NewStartId = Start_Id , @NewProdChangeStartTime  = Start_Time, @NewProdChangeEndTime = End_Time
     From Production_Starts
     Where Pu_id = @PUId 
      And Start_Time = @NewTimeStamp
  If (@NewProdChangeEndTime is null) Select @NewProdChangeEndTime = @NewProdChangeStartTime 
