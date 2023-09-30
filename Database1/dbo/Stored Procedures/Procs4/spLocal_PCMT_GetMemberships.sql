





CREATE PROCEDURE [dbo].[spLocal_PCMT_GetMemberships]
/*
*****************************************************************************************************************
Stored Procedure:		spLocal_PCMT_GetMemberships
Author:					Marc Charest (STI)
Date Created:			2006-11-14
SP Type:					ADO or SDK Call
Editor Tab Spacing:	3

Description:
=========
This SP is...

Called by:  			PCMT.xls

Revision Date			Who									What
========	==========	============================	=============================================
1.0.2		2008-06-25	Benoit Saenz de Ugarte (STI)	keep only active roles
1.0.1		2007-08-30	Vincent Rouleau, STI				Display Groups or Roles depending on user

*****************************************************************************************************************

spLocal_PCMT_GetMemberships 63, 1
*/
@cboUser					INTEGER,
@txtManageAdminGroup	INTEGER

AS

SET NOCOUNT ON

DECLARE
@intUserId			INTEGER,
@intRoleBased		INTEGER

SET @intUserId	= @cboUser

--Get the Role-Based setting of the user
SET @intRoleBased = (SELECT Role_Based_Security FROM dbo.Users WHERE user_id = @intUserId)

--If we have Group-Based Security
IF @intRoleBased = 0
BEGIN
	SELECT 
		sg.group_id AS [lvwMembers], 
		sg.group_desc, 
		al.al_desc
	FROM 
		dbo.user_security us 
		LEFT JOIN dbo.users u ON (us.user_id = u.user_id)
		LEFT JOIN dbo.access_level al ON (us.access_level = al.al_id)
		LEFT JOIN dbo.security_groups sg ON (us.group_id = sg.group_id)
	WHERE 
		u.user_id = @intUserId
	--	AND ((us.group_id <> 1 AND @txtManageAdminGroup = 0) OR @txtManageAdminGroup = 1)
	ORDER BY sg.group_desc
END
ELSE
BEGIN
	SELECT 
		r.user_id AS [lvwMembers], 
		r.username, 
		NULL
	FROM 
		dbo.user_role_security urs 
		LEFT JOIN dbo.users u ON (urs.user_id = u.user_id)
		LEFT JOIN dbo.users r ON (urs.role_user_id = r.user_id)
	WHERE 
		u.user_id = @intUserId AND
		r.active = 1
	--	AND ((us.group_id <> 1 AND @txtManageAdminGroup = 0) OR @txtManageAdminGroup = 1)
	ORDER BY r.username
END

SET NOCOUNT OFF





