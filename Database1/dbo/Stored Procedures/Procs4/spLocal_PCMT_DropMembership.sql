







CREATE PROCEDURE [dbo].[spLocal_PCMT_DropMembership]
/*
*****************************************************************************************************************
Stored Procedure:		spLocal_PCMT_DropMembership
Author:					Marc Charest (STI)
Date Created:			2006-11-14
SP Type:					ADO or SDK Call
Editor Tab Spacing:	3

Description:
=========
This SP drops a user security entry.

Called by:  			PCMT.xls

Revision Date			Who						What
========	==========	=================== 	=============================================
1.0.1		2007-08-30	Vincent Rouleau, STI	Drops the link between a user and a group or a role 
														depending on role-based type

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
	--Gets security ID.
	SET @intSecurityId = (SELECT security_id FROM dbo.user_security WHERE user_id = @intUserId AND group_id = @intGroupId)

	--Dropping user security.
	EXECUTE spem_dropusersecurity @intSecurityId, @txtUserId
END
ELSE
BEGIN
	--Gets security ID.
	SET @intSecurityId = (SELECT user_role_security_id FROM dbo.user_role_security WHERE user_id = @intUserId AND role_user_id = @intGroupId)

	--Dropping Role Security
	EXECUTE spEM_DropSecurityRoleMember @intSecurityId, @txtUserId
END

SELECT @intSecurityId, @intUserId, @intGroupId

SET NOCOUNT OFF















