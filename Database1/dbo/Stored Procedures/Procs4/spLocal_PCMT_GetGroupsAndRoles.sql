



CREATE PROCEDURE [dbo].[spLocal_PCMT_GetGroupsAndRoles]
/*
*****************************************************************************************************************
Stored Procedure:		spLocal_PCMT_GetGroupsAndRoles
Author:					Vincent Rouleau (STI)
Date Created:			2007-08-30
SP Type:					ADO or SDK Call
Editor Tab Spacing:	3

Description:
=========
This SP is returning a list of groups and roles

Called by:  			PCMT.xls

Revision Date			Who						What
========	==========	=================== 	=============================================

spLocal_PCMT_GetGroupsAndRoles 1
*****************************************************************************************************************
*/

AS

SET NOCOUNT ON

SELECT 
	group_id AS [cboGroup], 
	group_desc 
FROM 
	dbo.security_groups 
--UNION
--SELECT
--	user_id AS [cboGroup],
--	username
--FROM
--	dbo.users
--WHERE
--	Is_Role = 1
--	AND active = 1 AND System = 0
--ORDER BY 
--	group_desc

SET NOCOUNT OFF






