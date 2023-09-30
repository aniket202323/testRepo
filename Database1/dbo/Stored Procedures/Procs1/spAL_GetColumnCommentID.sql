Create Procedure dbo.spAL_GetColumnCommentID
@SheetId int,
@ResultOn datetime,
@CommentID int OUTPUT
AS
Select @CommentID = comment_id 
  From Sheet_Columns
  Where sheet_id = @SheetId and
        result_on = @ResultOn
if @CommentId Is Not Null
  return(100)
else
  return(0)
