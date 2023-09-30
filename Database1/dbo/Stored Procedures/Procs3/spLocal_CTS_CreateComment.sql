

--------------------------------------------------------------------------------------------------
-- Stored Procedure: spLocal_CTS_CreateComment
--------------------------------------------------------------------------------------------------
-- Author				: Ugo Lapierre, Symasol
-- Date created			: 2021-10-19
-- Version 				: Version <1.0>
-- SP Type				: Web
-- Caller				: Called by CTS mobile application
-- Description			: Return all possible Location Types to fill comboBox 
-- Editor tab spacing	: 4
-------------------------------------------------------------------------------
--



--------------------------------------------------------------------------------------------------
-- EDIT HISTORY:
--------------------------------------------------------------------------------------------------
-- ===========================================================================================
-- 1.0		2021-10-19		U.Lapierre				Initial Release 

--================================================================================================
--


--------------------------------------------------------------------------------------------------
-- TEST CODE:
--------------------------------------------------------------------------------------------------
/*

exec [dbo].[spLocal_CTS_CreateComment] 1063,'Test stored proc 4',54

select * from comments where comment_id > 1060

*/

-------------------------------------------------------------------------------
CREATE   PROCEDURE [dbo].[spLocal_CTS_CreateComment]
	@TopCommentId						int,
	@CommentText						varchar(5000),
	@UserId								int,
	@CommentId							int	OUTPUT

--WITH ENCRYPTION	
AS
SET NOCOUNT ON

DECLARE @NewCommentId				int,
		@Now						datetime
SET @Now = GETDATE()

INSERT INTO dbo.Comments(Comment,Comment_Text, CS_Id, TopOfChain_Id, User_Id, Modified_On, Entry_On)
VALUES (@CommentText,@CommentText,1,@TopCommentId, @UserId,@Now,@Now)
SET @NewCommentId = SCOPE_IDENTITY();

--if first chained coment
IF @TopCommentId IS NOT NULL
BEGIN
	IF NOT EXISTS(SELECT comment_id FROM dbo.comments where comment_id = @TopCommentId AND TopOfChain_Id = @TopCommentId)
	BEGIN
		UPDATE dbo.comments
		SET TopOfChain_Id = @TopCommentId,
			NextComment_Id = @NewCommentId
		WHERE comment_id = @TopCommentId
	END
	ELSE
	BEGIN
		UPDATE dbo.comments
		SET NextComment_Id = @NewCommentId
		WHERE TopOfChain_Id = @TopCommentId
			AND nextComment_Id IS NULL
			AND COMMENT_id !=@NewCommentId
	END
END
ELSE
BEGIN
	UPDATE dbo.comments
	SET TopOfChain_Id = @NewCommentId
	WHERE comment_id = @NewCommentId
END


SELECT @CommentId = (SELECT COALESCE(@TopCommentId,@NewCommentId))

LaFin:

SET NOCOUNT OFF

RETURN
