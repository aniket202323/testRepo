CREATE PROCEDURE dbo.spEM_UpdateCommentData
  @CommentId         int,
  @UserId 	  	  	  int
AS
Declare @Now DateTime
Select @Now = dbo.fnServer_CmnGetDate(getUTCdate())
Select @Now = DateAdd(millisecond,-DatePart(millisecond,@Now),@Now)
UPDATE COMMENTS Set User_Id = @UserId,Entry_On = @Now,Modified_On = @Now
 	  	 WHERE Comment_Id = @CommentId
  RETURN(0)
