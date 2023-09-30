






CREATE PROCEDURE [dbo].[spLocal_PCMT_GetUser]
/*
*****************************************************************************************************************
Stored Procedure:		spLocal_PCMT_
Author:					Marc Charest (STI)
Date Created:			2006-11-14
SP Type:					ADO or SDK Call
Editor Tab Spacing:	3

Description:
=========
This SP is...

Called by:  			PCMT.xls

Revision Date			Who						What
========	==========	=================== 	=============================================

*****************************************************************************************************************
*/
@cboUser						INTEGER,
@txtUserName				VARCHAR(255)=NULL

AS

SET NOCOUNT ON

DECLARE
@intUserId					INTEGER,
@vcrUserName				VARCHAR(255),
@intLanguageParmId		INTEGER

SET @intUserId 			= @cboUser
SET @vcrUserName 			= @txtUserName

SET @intLanguageParmId	= (SELECT parm_id FROM dbo.parameters WHERE parm_name = 'LanguageNumber')

SELECT 
	u.username 						AS [txtUserName], 
	u.user_desc 					AS [txtUserDesc], 
	u.password 						AS [txtPassword],
	u.windowsuserinfo 			AS [txtWinUserInfo],
	u.view_id 						AS [cboView],
	u.active 						AS [chkActive],
	u.role_based_security		AS [chkIsRole],
	u.mixed_mode_login			AS [chkMixMode],
	CAST(up.value AS INTEGER)	AS [cboLanguage]
	
FROM 
	dbo.users u
	LEFT JOIN dbo.user_parameters up ON (up.user_id = u.user_id AND parm_id = @intLanguageParmId)
WHERE 
	u.user_id = @intUserId
	--OR username = @txtUserName

SET NOCOUNT OFF


















