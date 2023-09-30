CREATE PROCEDURE dbo.spServer_CmnGetEvent
@PU_Id int,
@TimeStamp datetime,
@Direction int,
@UseEquals int,
@Event_Id int OUTPUT
 AS
--   Direction
--   --------------
--   1) Backward
--   2) Forward
--   3) Exact
Select @Event_Id = NULL
If (@Direction = 3)
  Begin
    Select @Event_Id = Event_Id
      From Events
      Where (PU_Id = @PU_Id) And
            (TimeStamp = @TimeStamp)
  End
Else
  If (@UseEquals = 1)
    Begin
      If (@Direction = 1)
        Begin
          Select @Event_Id = Event_Id
            From Events
            Where (PU_Id = @PU_Id) And
                  (TimeStamp = (Select Max(TimeStamp) From Events Where (PU_Id = @PU_Id) And (TimeStamp <= @TimeStamp)))
        End
      If (@Direction = 2)
        Begin
          Select @Event_Id = Event_Id
            From Events
            Where (PU_Id = @PU_Id) And
                  (TimeStamp = (Select Min(TimeStamp) From Events Where (PU_Id = @PU_Id) And (TimeStamp >= @TimeStamp)))
        End
    End
  Else
    Begin
      If (@Direction = 1)
        Begin
          Select @Event_Id = Event_Id
            From Events
            Where (PU_Id = @PU_Id) And
                  (TimeStamp = (Select Max(TimeStamp) From Events Where (PU_Id = @PU_Id) And (TimeStamp < @TimeStamp)))
        End
      If (@Direction = 2)
        Begin
          Select @Event_Id = Event_Id
            From Events
            Where (PU_Id = @PU_Id) And
                  (TimeStamp = (Select Min(TimeStamp) From Events Where (PU_Id = @PU_Id) And (TimeStamp > @TimeStamp)))
        End
    End
If (@Event_Id Is NULL)
  Select @Event_Id = 0
