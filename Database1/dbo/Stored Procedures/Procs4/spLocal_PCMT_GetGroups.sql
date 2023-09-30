







CREATE PROCEDURE [dbo].[spLocal_PCMT_GetGroups]
/*
*****************************************************************************************************************
Stored Procedure:		spLocal_PCMT_
Author:					Marc Charest (STI)
Date Created:			2006-11-14
SP Type:					ADO or SDK Call
Editor Tab Spacing:	3

Description:
=========
This SP is...

Called by:  			PCMT.xls

Revision Date			Who						What
========	==========	=================== 	=============================================

*****************************************************************************************************************
*/
@txtManageAdminGroup	INTEGER

AS

SET NOCOUNT ON

SELECT 
	group_id AS [cboGroup], 
	group_desc 
FROM 
	dbo.security_groups 
--WHERE
--	(group_id <> 1 AND @txtManageAdminGroup = 0) OR @txtManageAdminGroup = 1
ORDER BY 
	group_desc

SET NOCOUNT OFF
















