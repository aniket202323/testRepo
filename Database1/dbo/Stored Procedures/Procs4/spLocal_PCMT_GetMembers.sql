






CREATE PROCEDURE [dbo].[spLocal_PCMT_GetMembers]
/*
*****************************************************************************************************************
Stored Procedure:		spLocal_PCMT_GetMembers
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

*****************************************************************************************************************
spLocal_PCMT_GetMembers 136, 1
*/
@cboGroup			INTEGER,
@txtType				INTEGER

AS

SET NOCOUNT ON

DECLARE
@intGroupId	INTEGER

SET @intGroupId	= @cboGroup

--If we are looking at a group
IF @txtType = 0
BEGIN
	SELECT 
		us.user_id AS [lvwMembers], 
		username, 
		al_desc
	FROM 
		dbo.user_security us, dbo.users u, dbo.access_level al 
	WHERE 
		us.user_id = u.user_id 
		AND us.access_level = al.al_id
		AND group_id = @intGroupId
		AND u.active = 1
	ORDER BY username
END
ELSE	--If we are looking at a role
BEGIN
	SELECT 
		urs.user_id AS [lvwMembers], 
		username, 
		''
	FROM 
		dbo.user_role_security urs JOIN dbo.users u ON urs.user_id = u.user_id
	WHERE 
		role_user_id = @intGroupId
		AND u.active = 1
	ORDER BY username
END

SET NOCOUNT OFF











