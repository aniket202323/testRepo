








CREATE PROCEDURE [dbo].[spLocal_PCMT_DropUserMembership]
/*
*****************************************************************************************************************
Stored Procedure:		spLocal_PCMT_DropUserMembership
Author:					Marc Charest (STI)
Date Created:			2006-11-14
SP Type:					ADO or SDK Call
Editor Tab Spacing:	3

Description:
=========
This SP drops a user membership entry.

Called by:  			PCMT.xls

Revision Date			Who						What
========	==========	=================== 	=============================================
1.0.1		2007-08-30	Vincent Rouleau, STI	Drop a link from a user

*****************************************************************************************************************
*/
@txtSecurityId			INTEGER,
@cboUser					INTEGER,
@txtUserId				INTEGER

AS

SET NOCOUNT ON

DECLARE
@intSecurityId			INTEGER,
@intUserId				INTEGER

SET @intSecurityId	= @txtSecurityId
SET @intUserId			= @cboUser

IF EXISTS (SELECT Security_Id FROM dbo.user_Security WHERE Security_Id = @intSecurityId AND User_Id = @intUserId)
BEGIN
	--Dropping user group membership.
	EXECUTE spem_dropusersecurity @intSecurityId, @txtUserId
END
ELSE IF EXISTS (SELECT User_Role_Security_Id FROM dbo.user_role_Security WHERE User_Role_Security_Id = @intSecurityId AND User_Id = @intUserId)
BEGIN
	--Dropping user role membership.
	EXECUTE spEM_DropSecurityRoleMember @intSecurityId, @txtUserId
END

SELECT @intSecurityId, @intUserId

SET NOCOUNT OFF























