





















CREATE PROCEDURE [dbo].[spLocal_PCMT_GetViews]
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

AS

SET NOCOUNT ON

SELECT 
	view_id AS [cboView], 
	view_desc 
FROM 
	dbo.views 
ORDER BY 
	view_desc

SET NOCOUNT OFF





















