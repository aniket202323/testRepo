




CREATE PROCEDURE [dbo].[spLocal_PCMT_CreateRole]
/*
-------------------------------------------------------------------------------------------------
Created By	:	Benoit Saenz de Ugarte (STI)
Date			:	2008-06-24
Version		:	1.0.0
Purpose		: 	This SP creates role
-------------------------------------------------------------------------------------------------
*/
@vcrRoleName	VARCHAR(30),
@UserId			INT

AS

SET NOCOUNT ON

DECLARE
@intRoleId	INT

--Creates role
EXECUTE dbo.spEM_CreateSecurityRole @vcrRoleName, @UserId, @intRoleId OUTPUT

SELECT @intRoleId

INSERT INTO Local_PG_PCMT_Log_Users([Timestamp], User_id1, Type, [User_id], User_Desc, User_Name)
VALUES(GETDATE(), @UserId, 1, @intRoleId, '::ROLE::', @vcrRoleName)

SET NOCOUNT OFF




