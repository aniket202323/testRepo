CREATE PROCEDURE dbo.spCSS_UpdateSignature 
@Mode int,
@SignatureId int,
@CommentId int, 
@ReasonId int,
@UserId int, 
@Node nvarchar(50)
AS
if @CommentId = 0 Select @CommentId = NULL
if @ReasonId = 0 Select @ReasonId = NULL
DECLARE @UTCNow Datetime,@DbNow Datetime
SELECT @UTCNow = Getutcdate()
SELECT @DbNow = dbo.fnServer_CmnGetdate(@UTCNow)
if @Mode = 1
  Begin
    Update ESignature set Perform_Comment_Id = Coalesce(@CommentId,NULL), Perform_Reason_Id = Coalesce(@ReasonId,NULL),
             Perform_Node = @Node
      Where Signature_Id = @SignatureId
  End
Else
  if @Mode = 2
    Begin
      Update ESignature set Verify_Comment_Id = Coalesce(@CommentId,NULL), Verify_Reason_Id = Coalesce(@ReasonId,NULL),
             Verify_Node = @Node, Verify_User_Id = @UserId, Verify_Time = @DbNow
        Where Signature_Id = @SignatureId
    End
