

CREATE PROCEDURE [dbo].[spMES_GetCommentSecurity]
		@SheetId INT,
		@UserId  INT

 AS
	SELECT dbo.fnCMN_GetCommentsSecurity(@SheetId,@UserId) AS security

