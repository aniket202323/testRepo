﻿






CREATE PROCEDURE [dbo].[spLocal_PCMT_DropMember]
/*
*****************************************************************************************************************
Stored Procedure:		spLocal_PCMT_DropMember
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
1.0.1		2007-08-30	Vincent Rouleau, STI	Drop the member from the role or group depending on the user

spLocal_PCMT_DropMember 63, 136, 1, 1
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
@intUserId				INTEGER,
@intGroupId				INTEGER,
@intAccessLevel		INTEGER,
@intSecurityId			INTEGER,
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
	--Gets security ID.
	SET @intSecurityId = (SELECT security_id FROM dbo.user_security WHERE user_id = @intMemberId AND group_id = @intGroupId)
	
	--Dropping user security.
	EXECUTE spem_dropusersecurity @intSecurityId, @intUserId
END
ELSE
BEGIN
	--Gets security ID.
	SET @intSecurityId = (SELECT user_role_security_id FROM dbo.user_role_security WHERE user_id = @intMemberId AND role_user_id = @intGroupId)

	--Dropping Role Security
	EXECUTE spEM_DropSecurityRoleMember @intSecurityId, @intUserId
END

SELECT @intSecurityId, @intMemberId, @intGroupId

SET NOCOUNT OFF



















