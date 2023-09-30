










CREATE PROCEDURE [dbo].[spLocal_PCMT_GetActiveSpecs]
/*
*****************************************************************************************************************
Stored Procedure:		spLocal_PCMT_GetActiveSpecs
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
@intSpecId		INTEGER,
@intCharId		INTEGER

AS

SET NOCOUNT ON

SELECT 
	spec_udp_id AS [lvwActiveSpecs], sample_number, priority, effective_date, expiration_date, spec_id, char_id
FROM 
	dbo.Local_PG_Spec_UDP
WHERE
	spec_id = @intSpecId
	AND char_id = @intCharId
ORDER BY
	effective_date ASC

SET NOCOUNT OFF











