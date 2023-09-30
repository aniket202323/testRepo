



CREATE PROCEDURE [dbo].[spLocal_PCMT_EditRole]
/*
-------------------------------------------------------------------------------------------------
Created By	:	Benoit Saenz de Ugarte (STI)
Date			:	2008-06-24
Version		:	1.0.0
Purpose		: 	This SP renames role
-------------------------------------------------------------------------------------------------
*/
@intRoleId		INT,
@vcrRoleName	VARCHAR(50),
@UserId			INT

AS

SET NOCOUNT ON


--Rename role
EXECUTE dbo.spEM_RenameSecurityRole @intRoleId, @vcrRoleName, @UserId

SELECT @intRoleId

INSERT INTO dbo.Local_PG_PCMT_Log_Users([Timestamp], User_id1, Type, [User_id], User_Desc, [User_Name])
VALUES(GETDATE(), @UserId, 2, @intRoleId, '::ROLE::', @vcrRoleName)

SET NOCOUNT OFF




