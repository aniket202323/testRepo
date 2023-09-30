





CREATE PROCEDURE [dbo].[spLocal_PCMT_GetUserMemberships]
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
1.0.1		2007-08-30	Vincent Rouleau, STI	Get all groups and roles the user is member of

*****************************************************************************************************************
spLocal_PCMT_GetUserMemberships 138

*/
@cboUser				INTEGER

AS

SET NOCOUNT ON

DECLARE
@intUserId			INTEGER

SET @intUserId		= @cboUser

SELECT 
	security_id AS [lvwSecurities], 
	group_desc, 
	al_desc
FROM
	dbo.user_security us,
	dbo.security_groups sg,
	dbo.access_level al
WHERE
	us.user_id = @intUserId
	AND us.group_id = sg.group_id
	AND us.access_level = al.al_id
UNION
SELECT 
	urs.user_role_security_id AS [lvwSecurities],
	r.username,
	''
FROM
	dbo.user_role_security urs JOIN
	dbo.users r ON urs.role_user_id = r.user_id
WHERE urs.user_id = @intUserID
ORDER BY 
	group_desc

SET NOCOUNT OFF






















