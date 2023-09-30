
--------------------------------------------------------------------------------------------------
-- Stored Procedure: spLocal_CTS_Get_Comments
--------------------------------------------------------------------------------------------------
-- Author				: Francois Bergeron, Symasol
-- Date created			: 2022-02-23
-- Version 				: Version <1.0>
-- SP Type				: PPA Modelv1055
-- Caller				: Model 1055 
-- Description			: Stored procedure that collects comments (chained)
-- Editor tab spacing	: 4
-------------------------------------------------------------------------------
--

--------------------------------------------------------------------------------------------------
-- EDIT HISTORY:
--------------------------------------------------------------------------------------------------
-- ===========================================================================================
-- 1.0		2022-02-23		F.Bergeron				Initial Release 

--================================================================================================

--------------------------------------------------------------------------------------------------
-- TEST CODE:
--------------------------------------------------------------------------------------------------
/*
DECLARE @CommentText		VARCHAR(1000)
EXEC spLocal_CTS_Get_Comments  13998,@CommentText OUTPUT
SELECT @CommentText
SELECT * FROM user_defined_events where event_id = 1038293
SELECT * From comments where comment_id = 13697

*/

-------------------------------------------------------------------------------
CREATE   PROCEDURE [dbo].[spLocal_CTS_Get_Comments]
@CommentId			INTEGER,
@CommentText		VARCHAR(1000) OUTPUT 	
--WITH ENCRYPTION	
AS
SET NOCOUNT ON

DECLARE
@NextCommentId	INTEGER


SET @CommentText = (SELECT	UB.username + CHAR(13) + CAST(Entry_on AS VARCHAR(25)) + CHAR(13) + CAST(C.comment_text AS VARCHAR(1000)) + CHAR(13) 
					FROM	dbo.comments C WITH(NOLOCK) 
					JOIN	dbo.users_base UB WITH(NOLOCK) 
								ON UB.user_id = C.user_id 
					WHERE	C.comment_id = @commentId)
SET @NextCommentId = (SELECT NextComment_id FROM dbo.comments C WITH(NOLOCK) WHERE comment_id = @CommentId)


WHILE COALESCE(@NextCommentId,0) > 0 
BEGIN
	SET @CommentText = @CommentText + (SELECT	UB.username + CHAR(13) + CAST(Entry_on AS VARCHAR(25)) + CHAR(13) + CAST(C.comment_text AS VARCHAR(1000)) + CHAR(13) 
						FROM	dbo.comments C WITH(NOLOCK) 
						JOIN	dbo.users_base UB WITH(NOLOCK) 
									ON UB.user_id = C.user_id 
						WHERE	C.comment_id = @NextCommentId)

	SET @commentId = @NextCommentId
	SET @NextCommentId = (SELECT NextComment_id FROM dbo.comments C WITH(NOLOCK) WHERE comment_id = @CommentId)

END
--PRINT  @CommentText

SET NOCOUNT OFF

RETURN
