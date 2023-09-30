CREATE PROCEDURE dbo.spServer_CmnGetChildEvent
@ParentEventId int,
@ChildEventId int OUTPUT
 AS
Select @ChildEventId = NULL
Select @ChildEventId = Event_Id From Events Where Source_Event = @ParentEventId
If (@ChildEventId Is NULL)
  Select @ChildEventId = 0
