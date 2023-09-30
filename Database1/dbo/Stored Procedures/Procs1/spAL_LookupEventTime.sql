Create Procedure dbo.spAL_LookupEventTime
@TimeStamp datetime,
@PU_Id int,
@Mode int,
@ThisTime datetime OUTPUT
AS
Select @ThisTime = NULL
If @Mode = 0
  Begin
    Select @ThisTime = Max(TimeStamp)
      From Events
      Where Timestamp < @TimeStamp and PU_Id = @PU_Id
  End
Else
  Select @ThisTime = Min(TimeStamp)
    From Events
    Where Timestamp > @TimeStamp and PU_Id = @PU_Id
