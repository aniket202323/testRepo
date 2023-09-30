




CREATE PROCEDURE [dbo].[spLocal_PCMT_GetRoleMemberships]
/*
-------------------------------------------------------------------------------------------------
Created By	:	Benoit Saenz de Ugarte (STI)
Date			:	2008-06-24
Version		:	1.0.0
Purpose		: 	This SP returns role members
-------------------------------------------------------------------------------------------------
*/
@intRoleId	INT

AS

SET NOCOUNT ON

SELECT 	u.[user_id] AS lvwMembers, u.username
FROM 		dbo.user_role_security urs LEFT JOIN 
			dbo.users u ON (urs.[user_id] = u.[user_id])
WHERE 	urs.role_user_id = @intRoleId
ORDER BY u.username

SET NOCOUNT OFF




