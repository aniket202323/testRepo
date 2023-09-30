Create Procedure dbo.spDS_CheckOpenRecord
@Source int,
@PUId int,
@KeyId int,
@Result int output
AS
 Declare @StartTime datetime
 Select @StartTime = NULL
/*
declare @xx int
exec spDS_CheckOpenRecord @source=1 , @puid=1, @keyId=1, @result=@xx output
select @xx
*/
------------------------------------------
-- User defined events
-----------------------------------------
 If (@Source=1)
  Begin
   Select @Result = Count(*) From User_Defined_Events UE
    Inner Join Event_SubTypes ES On UE.Event_SubType_Id = ES.Event_SubType_Id
     Where UE.PU_Id = @PUId 
      And UE.End_Time Is Null
       And UE.Ude_Id <> @KeyId
        And ES.Duration_Required = 1
   Return
  End
------------------------------------------
-- Product change
-----------------------------------------
 If (@Source=2)
  Begin
   Select @Result = Count(*) From Production_Starts
    Where PU_Id = @PUId 
      And End_Time Is Null
       And Start_Id <> @KeyId
   Return
  End
------------------------------------------
-- Downtime
-----------------------------------------
 If (@Source=3)
  Begin
   Select @StartTime = Start_Time
    From Timed_Event_Details
     Where TeDet_Id = @KeyId
   Select @Result = Count(*) From Timed_Event_Details
    Where PU_Id = @PUId 
      And Start_Time > @StartTime
   Return
  End
