Create Procedure dbo.spDS_GetNextUDEDetail
@PUId int,
@TimeStamp datetime,
@Orientation int,   -- 0-> previous, -1 --> next
@OriginalUDEId int,
@NewUDEId int Output,
@NewUDEStartTime datetime Output,
@NewUDEEndTime datetime Output
AS
/*
Example
declare @out int, @dt1 datetime, @dt2 datetime
exec spds_getnextUDEdetail  1, '6/6/00 07:15:00 AM' ,1,1,@out output, @dt1 output, @dt2 output
select @out, @dt1, @dt2
*/
 Declare @NewTimeStamp datetime
----------------------------------------------------------------
-- Initialize variables
---------------------------------------------------------------- 
 Select @NewUDEId = 0
----------------------------------------------------------------
-- Get immediate next/previous timestamp
----------------------------------------------------------------
 If (@Orientation = 1) -- next
  Select @NewTimeStamp = Min(Start_Time) 
   From User_Defined_Events 
    where pu_id = @PUId 
     And Start_Time >= @TimeStamp   -- you can have multiple UDes with the same time interval
      And UDE_Id <> @OriginalUDEId
  Else  -- =1 , previous
   Select @NewTimeStamp = Max(Start_Time) 
    From User_Defined_Events 
     Where pu_id = @PUId 
      And Start_Time <= @TimeStamp
       And UDE_Id <> @OriginalUDEId
----------------------------------------------------------------
-- Get UDEId for the immediate next/previous
---------------------------------------------------------------
  If (@NewTimeStamp Is Not NULL)
   Select @NewUDEId = UDE_Id , @NewUDEStartTime  = Start_Time, @NewUDEEndTime = End_Time
    From User_Defined_Events  
     Where Pu_id = @PUId 
      And Start_Time = @NewTimeStamp
       And UDE_Id <> @OriginalUDEId
  If (@NewUDEEndTime is null) Select @NewUDEEndTime = @NewUDEStartTime 
