
CREATE PROCEDURE [dbo].[spLocal_PCMT_GetAccessLevels]
/*
*****************************************************************************************************************
Stored Procedure:		spLocal_PCMT_
Author:					Marc Charest (STI)
Date Created:			2006-11-14
SP Type:					ADO or SDK Call
Editor Tab Spacing:	3

Description:
=========
This SP gets access level entries.

Called by:  			PCMT.xls

Revision Date			Who						What
========	==========	=================== 	=============================================

*****************************************************************************************************************
*/

AS

SET NOCOUNT ON

SELECT 
	al_id AS [cboAccessLevel], 
	al_desc 
FROM 
	dbo.access_level 
ORDER BY 
	al_desc

SET NOCOUNT OFF























