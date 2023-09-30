





CREATE PROCEDURE [dbo].[spLocal_PCMT_GetGroup]
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
@cboGroup		INTEGER

AS

SET NOCOUNT ON

DECLARE
@intGroupId		INTEGER

SET @intGroupId	= @cboGroup

SELECT 
	group_desc AS [txtGroupDesc]
FROM 
	dbo.security_groups 
WHERE 
	group_id = @intGroupId

SET NOCOUNT OFF





















