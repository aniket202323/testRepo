Create Procedure dbo.spAL_GetTestCommentID
@TestId BigInt,
@CommentID int OUTPUT
AS
Select @CommentID = comment_id 
  From Tests
  Where test_id = @TestId
if @CommentId Is Not Null
  return(100)
else
  return(0)
