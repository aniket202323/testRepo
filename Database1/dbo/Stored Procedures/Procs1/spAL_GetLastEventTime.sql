Create Procedure dbo.spAL_GetLastEventTime
@PU_Id int,
@LastTime datetime OUTPUT
AS
Select @LastTime = NULL
Select @LastTime = max(TimeStamp)
  From Events
  Where TimeStamp < dbo.fnServer_CmnGetDate(getutcdate()) and PU_Id = @PU_Id
If @LastTime Is Null Select @LastTime = dbo.fnServer_CmnGetDate(getutcdate())
return(100)
