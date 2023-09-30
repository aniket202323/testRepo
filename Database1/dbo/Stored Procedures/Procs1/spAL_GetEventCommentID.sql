Create Procedure dbo.spAL_GetEventCommentID
@EventId int,
@CommentID int OUTPUT
AS
Select @CommentID = comment_id 
  From Events
  Where Event_id = @EventId
if @CommentId Is Not Null
  return(100)
else
  return(0)
