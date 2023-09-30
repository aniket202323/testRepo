





CREATE PROCEDURE [dbo].[spLocal_PCMT_GetNonMembers]
/*
*****************************************************************************************************************
Stored Procedure:		spLocal_PCMT_GetNonMembers
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
1.0.2		2008-06-25	Benoit Saenz de Ugarte (STI)	keep only active users
1.0.1		2007-08-30	Vincent Rouleau, STI				Display Role-Based or Group-Based users depending on type

spLocal_PCMT_GetNonMembers 3, 0
*****************************************************************************************************************
*/
@cboGroup		INTEGER,
@txtType			INTEGER

AS

SET NOCOUNT ON

DECLARE
@intGroupId			INTEGER

SET @intGroupId	= @cboGroup

--If we are looking a a group
IF @txtType = 0
BEGIN
	SELECT 
		u.user_id AS [lvwNonMembers], 
		u.username
	FROM 
		dbo.users u 
	WHERE
		u.Role_Based_Security = 0 AND
		NOT EXISTS (	SELECT us.user_id 
							FROM dbo.user_security us 
							WHERE us.user_id = u.user_id AND us.group_id = @intGroupId)
		AND u.system = 0 
		AND u.active = 1
	ORDER BY username
END
ELSE	--If we are looking at a role
BEGIN
	SELECT 
		u.user_id AS [lvwNonMembers], 
		u.username
	FROM 
		dbo.users u 
	WHERE
		u.Role_Based_Security = 1 AND
		NOT EXISTS (	SELECT urs.user_id 
							FROM dbo.user_role_security urs 
							WHERE urs.user_id = u.user_id AND urs.role_user_id = @intGroupId)
		AND u.system = 0 
		AND u.active = 1
	ORDER BY username
END

SET NOCOUNT OFF







