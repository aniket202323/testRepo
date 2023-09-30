





CREATE PROCEDURE [dbo].[spLocal_PCMT_AddMember]
/*
*****************************************************************************************************************
Stored Procedure:		spLocal_PCMT_AddMember
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
1.0.1		2007-08-30	Vincent Rouleau, STI	Add member to the group or role

spLocal_PCMT_DropMember 63, 136, 1, 1, 
select * from user_role_security
*****************************************************************************************************************
*/
@txtMemberId			INTEGER,
@cboGroup				INTEGER,
@cboAccessLevel		INTEGER,
@txtUserId				INTEGER

AS

SET NOCOUNT ON

DECLARE
@intMemberId			INTEGER,
@intGroupId				INTEGER,
@intAccessLevel		INTEGER,
@intSecurityId			INTEGER,
@intUserId				INTEGER,
@intRoleBased			INTEGER

SET @intMemberId		= @txtMemberId
SET @intUserId			= @txtUserId
SET @intGroupId		= @cboGroup
SET @intAccessLevel	= @cboAccessLevel

--Get the Role-Based setting of the user
SET @intRoleBased = (SELECT Role_Based_Security FROM dbo.Users WHERE user_id = @intMemberId)

--If we have Group-Based Security
IF @intRoleBased = 0
BEGIN
	EXECUTE spem_createusersecurity @intGroupId, @intMemberId, @intAccessLevel, @intUserId, @intSecurityId OUTPUT
END
ELSE
BEGIN
	EXECUTE spEM_CreateSecurityRoleMember @intGroupId, @intMemberId, NULL, @intUserId, @intSecurityId OUTPUT
END

SELECT @intSecurityId, @intMemberId, @intGroupId, @intAccessLevel

SET NOCOUNT OFF




















