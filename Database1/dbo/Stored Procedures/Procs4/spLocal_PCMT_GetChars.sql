

















CREATE PROCEDURE [dbo].[spLocal_PCMT_GetChars]
/*
*****************************************************************************************************************
Stored Procedure:		spLocal_PCMT_GetChars
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
@cboProperty		INTEGER

AS

SET NOCOUNT ON

SELECT
	c.char_id AS [cboChar],
	c.char_desc
FROM 
	dbo.characteristics c
WHERE
	c.prop_id = @cboProperty
ORDER BY
	c.char_desc


SET NOCOUNT OFF


















