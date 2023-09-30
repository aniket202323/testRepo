




CREATE PROCEDURE [dbo].[spLocal_PCMT_DropRoleMember]
/*
-------------------------------------------------------------------------------------------------
Created By	:	Benoit Saenz de Ugarte (STI)
Date			:	2008-06-24
Version		:	1.0.0
Purpose		: 	This SP drops a role member
-------------------------------------------------------------------------------------------------
*/
@intRoleId	INT,
@memberid	INT,
@UserId		INT

AS

SET NOCOUNT ON

DECLARE
@intSecurityId	INT


--Get security ID.
SET @intSecurityId = (SELECT user_role_security_id FROM dbo.user_role_security WHERE [user_id] = @memberid AND role_user_id = @intRoleId)

--Dropping Role Security
EXECUTE dbo.spEM_DropSecurityRoleMember @intSecurityId, @UserId

SELECT @intSecurityId


SET NOCOUNT OFF




