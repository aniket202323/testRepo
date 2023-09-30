


















CREATE PROCEDURE [dbo].[spLocal_PCMT_GetChar]
/*
*****************************************************************************************************************
Stored Procedure:		spLocal_PCMT_GetChar
Author:					Marc Charest (STI)
Date Created:			2006-11-14
SP Type:					ADO or SDK Call
Editor Tab Spacing:	3

Description:
=========
This SP creates a user group.

Called by:  			PCMT.xls

Revision Date			Who						What
========	==========	=================== 	=============================================

*****************************************************************************************************************
*/
@cboChar					INTEGER

AS

SET NOCOUNT ON

DECLARE
@intCharId				INTEGER,
@intIsParent			BIT

SET @intCharId 		= @cboChar

SET @intIsParent = (SELECT COUNT(char_id) FROM dbo.characteristics WHERE derived_from_parent = @intCharId)

SELECT 
	char_desc AS [txtCharDesc], ISNULL(derived_from_parent, -1) AS [cboParentChar],
	ISNULL(derived_from_parent, -1) AS [txtParentChar],
	CASE WHEN @intIsParent > 0 THEN 1 ELSE 0 END AS [chkParent] 
FROM 
	dbo.characteristics 
WHERE 
	char_id = @intCharId

SET NOCOUNT OFF




























