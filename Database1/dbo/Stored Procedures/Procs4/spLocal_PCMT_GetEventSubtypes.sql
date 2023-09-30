





















-------------------------------------------------------------------------------------------------

CREATE  	PROCEDURE [dbo].[spLocal_PCMT_GetEventSubtypes]
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
@cboEventType	INTEGER

AS

SET NOCOUNT ON

SELECT event_subtype_id AS [cboEventSubtype], event_subtype_desc
FROM dbo.Event_SubTypes
WHERE 
	(et_id = @cboEventType AND @cboEventType IS NOT NULL)
	or
	@cboEventType IS NULL
ORDER BY event_subtype_desc


SET NOCOUNT OFF























