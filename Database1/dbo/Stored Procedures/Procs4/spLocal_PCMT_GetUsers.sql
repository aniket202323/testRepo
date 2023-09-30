




CREATE PROCEDURE [dbo].[spLocal_PCMT_GetUsers]
/*
*****************************************************************************************************************
Stored Procedure:		spLocal_PCMT_GetUsers
Author:					Marc Charest (STI)
Date Created:			2006-11-14
SP Type:					ADO or SDK Call
Editor Tab Spacing:	3

Description:
=========
This SP is...

Called by:  			PCMT.xls

Revision Date			Who									What
========	==========	============================	=============================================
1.0.1		2008-06-23	Benoit Saenz de Ugarte (STI) 	Add Filters
1.0.0		2006-11-14	Marc Charest (STI)				Creation
*****************************************************************************************************************
*/
@intRoleFiltered				INT = 0,
@intRoleBasedUserOnly		INT = 0


AS

SET NOCOUNT ON

IF (@intRoleFiltered = 0 AND @intRoleBasedUserOnly = 0)
	BEGIN
		SELECT 
			user_id AS [cboUser], 
			username 
		FROM 
			dbo.users 
		WHERE 
			system = 0 AND active = 1 
		ORDER BY 
			username
	END
ELSE IF (@intRoleFiltered = 1 AND @intRoleBasedUserOnly = 0)
	BEGIN
		SELECT 
			user_id AS [cboUser], 
			username 
		FROM 
			dbo.users 
		WHERE 
			system = 0 AND active = 1 AND is_role = 0
		ORDER BY 
			username
	END
ELSE IF (@intRoleBasedUserOnly = 1)
	BEGIN
		SELECT 
			user_id AS [cboUser], 
			username 
		FROM 
			dbo.users 
		WHERE 
			system = 0 AND active = 1 AND role_based_security = 1
		ORDER BY 
			username
	END

SET NOCOUNT OFF





