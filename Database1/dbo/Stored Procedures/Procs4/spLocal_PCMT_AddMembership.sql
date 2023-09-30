








CREATE PROCEDURE [dbo].[spLocal_PCMT_AddMembership]
/*
*****************************************************************************************************************
Stored Procedure:		spLocal_PCMT_AddMembership
Author:					Marc Charest (STI)
Date Created:			2006-11-14
SP Type:					ADO or SDK Call
Editor Tab Spacing:	3

Description:
=========
This SP is creating a security entry for the given user.

Called by:  			PCMT.xls

Revision Date			Who						What
========	==========	=================== 	=============================================
1.0.1		2007-08-30	Vincent Rouleau, STI	Links a user to a group or a role depending on role-based type

*****************************************************************************************************************
*/
@cboUser					INTEGER,
@txtGroupId				INTEGER,
@cboAccessLevel		INTEGER,
@txtUserId				INTEGER
AS

SET NOCOUNT ON

DECLARE
@intUserId				INTEGER,
@intGroupId				INTEGER,
@intAccessLevel		INTEGER,
@intSecurityId			INTEGER,
@intRoleBased			INTEGER

SET @intUserId			= @cboUser
SET @intGroupId		= @txtGroupId
SET @intAccessLevel	= @cboAccessLevel

--Get the Role-Based setting of the user
SET @intRoleBased = (SELECT Role_Based_Security FROM dbo.Users WHERE user_id = @intUserId)

--If we have Group-Based Security
IF @intRoleBased = 0
BEGIN
	EXECUTE spem_createusersecurity @intGroupId, @intUserId, @intAccessLevel, @txtUserId, @intSecurityId OUTPUT
END
ELSE
BEGIN
	EXECUTE spEM_CreateSecurityRoleMember @intGroupId, @intUserId, NULL, @txtUserId, @intSecurityId OUTPUT
END

SELECT @intSecurityId, @intUserId, @intGroupId, @intAccessLevel

SET NOCOUNT OFF

















