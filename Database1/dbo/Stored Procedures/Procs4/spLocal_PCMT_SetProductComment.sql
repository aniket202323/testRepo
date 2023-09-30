


CREATE PROCEDURE [dbo].[spLocal_PCMT_SetProductComment]
/*
*****************************************************************************************************************
Stored Procedure:		spLocal_PCMT_SetProductComment
Author:					Marc Charest (STI)	
Date Created:			2007-05-03
SP Type:					ADO or SDK Call
Editor Tab Spacing:	3

Description:
=========
This SP creates or edit a product comment.

Called by:  			PCMT.xls

Revision Date			Who						What
========	==========	=================== 	=============================================
2.0.0		2008-04-22	PD Dubois (STI)		Modified the Product comment management. 

-------------------------------------------------------------------------------------------------
Updated By	:	Patrick-Daniel Dubois (System Technologies for Industry Inc)
Date			:	2008-04-22
Version		:	2.0.0 => Compatible with PCMT version 1.7 and higher only
Purpose		: 	Modified the Product comment management. 
					This has been done to be able to manage the comment in the Product Edit form.
					1- Commented the input parameters @vcrOldDesc and @vcrNewDesc
					2- Added the input parameter @VcrProductComments VARCHAR(8000)= NULL	
					3- Completly changed the way that the comments are inserted or updated
*****************************************************************************************************************
*/
@intUserId		INTEGER,
--@vcrOldDesc		VARCHAR(1000), --> Commented by PDD
--@vcrNewDesc		VARCHAR(1000), --> Commented by PDD
@intProdId		INTEGER,
@VcrProductComments		VARCHAR(8000)= NULL --> Added by PDD
AS

SET NOCOUNT ON

DECLARE
@intCommentId	INTEGER,
@NewComment	VARCHAR(8000)	--> Added by PDD

SET @intCommentId = (SELECT comment_id FROM dbo.products WHERE prod_id = @intProdId)

IF @intCommentId IS NOT NULL BEGIN

--> Added by PDD
SELECT  @NewComment= Replace(CAST(comment AS VARCHAR(8000)),CAST(comment_text AS VARCHAR(8000)),@VcrProductComments)
FROM dbo.Comments
WHERE comment_id=@intCommentId

	--Adding product description to an existing comment
	UPDATE dbo.comments
	SET 
		comment = 	@NewComment,--> Added by PDD
						--> Commented by PDD
								--Adding product description to an existing comment
--						CASE 	WHEN CHARINDEX(@vcrOldDesc, comment) = 0 AND CHARINDEX(@vcrNewDesc, comment) = 0
--									THEN '{\rtf1 ' + @vcrNewDesc + '\par' + CHAR(13) + CHAR(10) + REPLACE(CAST(comment AS VARCHAR(8000)), '{\rtf1', '')
--								--Replacing product description within an existing comment
--								WHEN CHARINDEX(@vcrOldDesc, comment) <> 0 AND CHARINDEX(@vcrNewDesc, comment) = 0
--									THEN REPLACE(CAST(comment AS VARCHAR(8000)), @vcrOldDesc, @vcrNewDesc)
--								--Statu quo
--								ELSE comment
--						END,
		comment_text = 	@VcrProductComments --> Added by PDD
								--> Commented by PDD
								--Adding product description to an existing comment
--						CASE 	WHEN CHARINDEX(@vcrOldDesc, comment) = 0 AND CHARINDEX(@vcrNewDesc, comment) = 0 
--									THEN @vcrNewDesc + CHAR(13) + CAST(comment_text AS VARCHAR(8000))
--								--Replacing product description within an existing comment
--								WHEN CHARINDEX(@vcrOldDesc, comment) <> 0 AND CHARINDEX(@vcrNewDesc, comment) = 0
--									THEN REPLACE(CAST(comment_text AS VARCHAR(8000)), @vcrOldDesc, @vcrNewDesc)
--								--Statu quo
--								ELSE comment_text
--						END
	WHERE 
		comment_id = @intCommentId END

ELSE BEGIN

	--Creating brand new comment with product description
	INSERT dbo.comments (comment, comment_text, modified_on, user_id)
	VALUES(
		'{\rtf1\ansi\ansicpg1252\deff0\deflang1033{\fonttbl{\f0\fnil\fcharset0 MS Sans Serif;}}' + CHAR(13) + CHAR(10) + '\viewkind4\uc1\pard\f0\fs17 ' + @VcrProductComments + '\par' + CHAR(13) + CHAR(10) +  '}',--> Changed by PDD
		@VcrProductComments + CHAR(13),--> Changed by PDD
		GETDATE(),
		@intUserId)

	UPDATE dbo.products SET comment_id = @@IDENTITY WHERE prod_id = @intProdId

END

SET NOCOUNT OFF




