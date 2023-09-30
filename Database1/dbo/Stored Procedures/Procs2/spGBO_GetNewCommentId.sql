Create Procedure dbo.spGBO_GetNewCommentId 
@UserID int, 
@CSID int, 
@CommentID int OUTPUT
AS
Set NoCount On
Insert Comments (Comment, User_Id, Modified_On, CS_ID) Values (' ', @UserId, dbo.fnServer_CmnGetDate(getutcdate()), @CSID)
Select @CommentID = Scope_Identity()
