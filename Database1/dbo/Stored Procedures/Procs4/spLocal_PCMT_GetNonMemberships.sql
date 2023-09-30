





CREATE PROCEDURE [dbo].[spLocal_PCMT_GetNonMemberships]
/*
*****************************************************************************************************************
Stored Procedure:		spLocal_PCMT_GetNonMemberships
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

spLocal_PCMT_GetNonMemberships 63, 1
*****************************************************************************************************************
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
		sg.group_id AS [lvwNonMembers], 
		sg.group_desc
	FROM 
		dbo.security_groups sg 
	WHERE
		sg.group_id NOT IN (
			SELECT us.group_id 
			FROM dbo.user_security us 
			WHERE
				us.group_id = sg.group_id AND us.user_id = @intUserId)
	--	AND ((sg.group_id <> 1 AND @txtManageAdminGroup = 0) OR @txtManageAdminGroup = 1)
	/*
		NOT EXISTS (	SELECT us.group_id 
							FROM dbo.user_security us 
							WHERE
								us.group_id = sg.group_id AND us.user_id = @intUserId)
		AND (sg.group_id <> 1 AND @txtManageAdminGroup = 0) OR @txtManageAdminGroup = 1
	*/
	ORDER BY group_desc
END
ELSE
BEGIN
	SELECT 
		user_id AS [lvwNonMembers], 
		username
	FROM dbo.users
	WHERE Is_Role = 1 AND active = 1 AND
			User_Id NOT IN (
				SELECT Role_User_Id
				FROM dbo.user_role_security
				WHERE user_id = @intUserId)
	ORDER BY username
END

SET NOCOUNT OFF



