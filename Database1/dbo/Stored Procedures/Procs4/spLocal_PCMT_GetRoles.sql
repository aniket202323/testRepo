




CREATE PROCEDURE [dbo].[spLocal_PCMT_GetRoles]
/*
-------------------------------------------------------------------------------------------------
Updated By	:	Stephane Turner, STI
Date			:	2008-06-26
Version		:	1.0.1
Purpose		: 	Simplified (remove IF ELSE)
-------------------------------------------------------------------------------------------------
Created By	:	Benoit Saenz de Ugarte (STI)
Date			:	2008-06-24
Version		:	1.0.0
Purpose		: 	This SP returns roles
-------------------------------------------------------------------------------------------------
*/
@intFiltered	INT = 1

AS

SET NOCOUNT ON

SELECT 	[user_id] AS cboRole, username 
FROM 		dbo.users 
WHERE  	is_role = 1 AND ((system = 0 AND active = 1 AND @intFiltered = 1) OR (@intFiltered <> 1))
ORDER BY username
	
SET NOCOUNT OFF




