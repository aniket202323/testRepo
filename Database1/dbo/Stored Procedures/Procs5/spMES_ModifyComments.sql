
CREATE PROCEDURE dbo.spMES_ModifyComments
		@TopOfChainId Int, --ThreadId
		@CommentId	Int ,
		@UserId		Int,
		@TableId	Int,
		@UnitId		Int,
		@CommentText nvarchar(max),
		@TransactionType Int 
AS

DECLARE @UsersSecurity Int, @ActualSecurity Int
DECLARE @CurrentCommentUserId	Int
DECLARE @PrevCommentId Int
DECLARE @CurrentTop		Int
DECLARE @NextCommentId	Int


SELECT @CommentText = Ltrim(Rtrim(@CommentText))
IF @CommentText = '' SELECT @CommentText = Null

IF @TransactionType Not In (1,2,3) or @TransactionType Is Null
BEGIN
	SELECT ERROR = 'Invalid - Transaction Type Required'
	RETURN
END
IF @TransactionType In (2,3) And @CommentId Is Null
BEGIN
	SELECT ERROR = 'Invalid -Id Required'
	RETURN
END

IF  Not Exists (SELECT 1 FROM Users WHERE User_Id = @UserId)
BEGIN
	SELECT ERROR = 'User Not Found'
			RETURN
END
IF  Not Exists (SELECT 1 FROM Prod_Units_Base WHERE PU_Id = @UnitId)
BEGIN
	SELECT ERROR = 'Unit Not Found'
			RETURN
END
IF  @TableId Not in (16,17,18,57,79,80) Or @TableId Is Null
BEGIN
	SELECT ERROR = 'Target Table Not Supported'
			RETURN
END
IF @TransactionType = 1 
BEGIN
	IF @TopOfChainId Is Not Null
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM Comments WHERE Comment_Id = @TopOfChainId)
		BEGIN
			SELECT ERROR = 'Comment Chain No Found'
			RETURN
		END
	END
	IF @CommentText IS NULL
	BEGIN
		SELECT ERROR = 'No Comment Supplied'
		RETURN
	END
	IF @TableId in(16,17,18)   -- Downtime Add
	BEGIN
		Select @UnitId = CASE 
	 WHEN Master_Unit IS NULL THEN pu_Id else MAster_Unit
	 END from Prod_Units where Pu_Id = @UnitId

		Select @UsersSecurity = dbo.fnBF_CmnGetUserAccessLevel(@UnitId,@UserId,1)
		SELECT @ActualSecurity = dbo.fnCMN_CheckSheetSecurity(@UnitId,NULL,388,1,@UsersSecurity)
		IF @ActualSecurity = 0 
		BEGIN
			SELECT ERROR = 'Invalid - Attempt to Add Comment'
			RETURN
		END
	END
	INSERT INTO Comments (Comment, Comment_Text, User_Id, Entry_On, CS_Id, Modified_On,TopOfChain_Id) 
		VALUES (@CommentText, @CommentText, @UserId, dbo.fnServer_CmnGetDate(getutcdate()), 1, dbo.fnServer_CmnGetDate(getutcdate()),@TopOfChainId)
	SET @CommentId = @@Identity

	IF @TopOfChainId Is NOT Null 
	BEGIN
		SELECT @PrevCommentId = Max(Comment_Id) 
		FROM Comments 
		WHERE TopOfChain_Id = @TopOfChainId and Comment_Id != @CommentId
		IF @PrevCommentId IS Null
		BEGIN
			SET @PrevCommentId = @TopOfChainId
		END
		UPDATE Comments Set NextComment_Id = @CommentId Where Comment_Id = @PrevCommentId
	END
	ELSE
	BEGIN
		SET   @TopOfChainId = @CommentId
		UPDATE Comments Set TopOfChain_Id = @CommentId Where Comment_Id = @CommentId
	END
END
IF @TransactionType = 2  -- Update 
BEGIN
	IF @CommentText IS NULL
	BEGIN
		SELECT ERROR = 'No Comment Supplied'
		RETURN
	END
	SELECT @CurrentCommentUserId = User_Id FROM Comments WHERE Comment_Id = @CommentId
	IF @CurrentCommentUserId Is Null
	BEGIN
		SELECT ERROR = 'No Comment Found'
		RETURN
	END
	IF @TableId in(16,17,18) and @CurrentCommentUserId != @UserId  -- ATTEMPT TO CHANGE OTHER USERS COMMENT
	BEGIN
	Select @UnitId = CASE 
	 WHEN Master_Unit IS NULL THEN pu_Id else MAster_Unit
	 END from Prod_Units where Pu_Id = @UnitId
		Select @UsersSecurity = dbo.fnBF_CmnGetUserAccessLevel(@UnitId,@UserId,1)
		SELECT @ActualSecurity = dbo.fnCMN_CheckSheetSecurity(@UnitId,null,390,3,@UsersSecurity)
		IF @ActualSecurity = 0 
		BEGIN
			SELECT ERROR = 'Invalid - Attempt to Change Comment'
			RETURN
		END
	END
	UPDATE comments
	  SET comment = @CommentText,
		comment_text = @CommentText,
		User_Id = @UserId,
		modified_on = [dbo].[fnServer_CmnGetDate](GetUTCDate())
	  WHERE Comment_id = @CommentId
END
IF @TransactionType = 3  --currently only support deleting top of chain and only if it is the only record
BEGIN
	IF NOT EXISTS (SELECT 1 FROM Comments WHERE Comment_Id = @CommentId )
	BEGIN
		SELECT ERROR = 'Comment to Delete No Found'
		RETURN
	END
    SELECT @CurrentTop = TopOfChain_Id, @NextCommentId = NextComment_Id FROM Comments Where Comment_Id = @CommentId
    SELECT @CurrentTop = Coalesce(@CurrentTop,@CommentId)
 	IF  EXISTS (SELECT 1 FROM Comments WHERE TopOfChain_Id = @CurrentTop and Comment_Id != @CommentId) and @CurrentTop = @CommentId 
	BEGIN
		SELECT ERROR = 'Deleting top of a chain is not supported'
		RETURN
	END
    If  @NextCommentId is Not NULL  --Removing a comment in the middle of a Chain
    BEGIN
        Update Comments Set NextComment_Id = @NextCommentId Where NextComment_Id = @CommentId
    END
    ELSE
	BEGIN
		Update Comments Set NextComment_Id = NULL Where NextComment_Id = @CommentId 
	END
	DELETE FROM Comments WHERE Comment_Id = @CommentId
END
IF @TransactionType IN(1, 2)
BEGIN
	EXECUTE spMES_GetComments @TopOfChainId,@CommentId ,@UserId,@TableId,	@UnitId
END

