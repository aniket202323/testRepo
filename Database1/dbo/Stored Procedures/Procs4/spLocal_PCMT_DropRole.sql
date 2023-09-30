




CREATE PROCEDURE [dbo].[spLocal_PCMT_DropRole]
/*
-------------------------------------------------------------------------------------------------
Created By	:	Benoit Saenz de Ugarte (STI)
Date			:	2008-06-24
Version		:	1.0.0
Purpose		: 	This SP drops a role
-------------------------------------------------------------------------------------------------
*/
@intRoleId	INT,
@UserId		INT

AS

SET NOCOUNT ON


--Drop role
EXECUTE dbo.spEM_DropSecurityRole @intRoleId, @UserId

SELECT @intRoleId

INSERT INTO Local_PG_PCMT_Log_Users([Timestamp], User_id1, Type, [User_id], User_Desc)
VALUES(GETDATE(), @UserId, 3, @intRoleId, '::ROLE::')

SET NOCOUNT OFF




