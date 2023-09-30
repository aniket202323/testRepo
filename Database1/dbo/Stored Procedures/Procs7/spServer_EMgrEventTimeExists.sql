CREATE PROCEDURE dbo.spServer_EMgrEventTimeExists
@PU_Id int,
@TimeStamp datetime,
@Found int OUTPUT
 AS
Declare
  @TmpTimeStamp datetime
Select @TmpTimeStamp = NULL
Select @TmpTimeStamp = TimeStamp From PreEvents Where (PU_Id = @PU_Id) And (TimeStamp = @TimeStamp)
If @TmpTimeStamp Is Not NULL
  Begin
    Select @Found = -1
    Return
  End
Select @Found = NULL
Select @Found = Event_Id From Events Where (PU_Id = @PU_Id) And (TimeStamp = @TimeStamp)
If @Found Is Null
  Select @Found = 0
Else
  Select @Found = 1
