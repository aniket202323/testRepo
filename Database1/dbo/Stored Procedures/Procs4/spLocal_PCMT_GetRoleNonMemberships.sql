



CREATE PROCEDURE [dbo].[spLocal_PCMT_GetRoleNonMemberships]
/*
-------------------------------------------------------------------------------------------------
Created By	:	Benoit Saenz de Ugarte (STI)
Date			:	2008-06-24
Version		:	1.0.0
Purpose		: 	This SP returns role non members
-------------------------------------------------------------------------------------------------
*/
@intRoleId	INT

AS

SET NOCOUNT ON

SELECT 	[user_id] AS lvwNonMembers, username
FROM 		dbo.users
WHERE 	active = 1 AND system = 0 AND Role_based_security = 1 AND
			[user_id] NOT IN(	SELECT 	[user_id]
									FROM 		dbo.user_role_security
									WHERE 	role_user_id = @intRoleId)
ORDER BY username

SET NOCOUNT OFF




