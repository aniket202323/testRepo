
CREATE PROCEDURE dbo.spMES_GetComments
		@TopOfChainId Int,
		@CommentId	Int ,
		@UserId		Int,
		@TableId	Int,
		@UnitId		Int
AS
/* @UserId  @TableId and @UnitId not used for sucurity on a get at this time*/
IF  @TopOfChainId Is Null
BEGIN
	SELECT ERROR = 'Required Parameter Missing'
END
IF @CommentId Is Null -- All Comments(commentThreads)
BEGIN
	IF NOT EXISTS(Select 1 FROM Comments WHERE Comment_Id =  @TopOfChainId and (TopOfChain_Id Is Null or TopOfChain_Id = @TopOfChainId))
	BEGIN
		SELECT ERROR = 'Initial Comment Not Found'
	END
	SELECT c.Comment_Id,
	        c.TopOfChain_Id,
			EntryOn = dbo.fnServer_CmnConvertFromDbTime(c.Entry_On,'UTC'),
		    ModifiedOn = dbo.fnServer_CmnConvertFromDbTime(c.Modified_On,'UTC'),
		    u.User_Id, 
			u.UserName,
		    CommentText = convert(nvarchar(max), Coalesce(c.Comment_Text, c.comment))
	FROM Comments c
	JOIN Users u on u.User_Id = c.User_Id
	WHERE c.Comment_Id = @TopOfChainId or c.TopOfChain_Id = @TopOfChainId
	Order BY c.Entry_On DESC
END
ELSE
BEGIN
	IF  NOT EXISTS(Select 1 FROM Comments WHERE Comment_Id =  @CommentId)
	BEGIN
		SELECT ERROR = 'Comment Not Found'
	END
	IF @CommentId !=  @TopOfChainId
	BEGIN
		IF  EXISTS(Select 1 FROM Comments WHERE Comment_Id =  @CommentId and TopOfChain_Id !=  @TopOfChainId)
		BEGIN
			SELECT ERROR = 'Comment Chain Not Correct'
		END
	END
	SELECT c.Comment_Id,
	        c.TopOfChain_Id,
			EntryOn = dbo.fnServer_CmnConvertFromDbTime(c.Entry_On,'UTC'),
		    ModifiedOn = dbo.fnServer_CmnConvertFromDbTime(c.Modified_On,'UTC'),
		    u.User_Id, 
			u.UserName,
		    CommentText = convert(nvarchar(max), Coalesce(c.Comment_Text, c.comment))
	FROM Comments c
	JOIN Users u on u.User_Id = c.User_Id
	WHERE c.Comment_Id = @CommentId
END

