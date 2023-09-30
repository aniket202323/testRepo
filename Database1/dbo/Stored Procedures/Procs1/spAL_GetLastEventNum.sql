Create Procedure dbo.spAL_GetLastEventNum
@PU_Id int,
@LastEventNum nvarchar(25) OUTPUT
AS
Select @LastEventNum = e.Event_Num
  From Events e
    Where PU_Id = 1 and TimeStamp = (Select Max(TimeStamp) from events e2 where PU_Id = 1)
return(100)
