Create Procedure dbo.spWD_LastEventTime
@PU_Id int,
@LastTime datetime OUTPUT
AS
Select @LastTime = NULL
Select @LastTime = max(TimeStamp)
  From Waste_Event_Details
  Where PU_Id = @PU_Id and
        TimeStamp < dbo.fnServer_CmnGetDate(getUTCdate())
If @LastTime Is Null Select @LastTime = dbo.fnServer_CmnGetDate(getUTCdate())
return(100)
