
















CREATE PROCEDURE [dbo].[spLocal_PCMT_GetProps]
/*
*****************************************************************************************************************
Stored Procedure:		spLocal_PCMT_GetProps
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
@txtUserId			INTEGER

AS

SET NOCOUNT ON

--Getting objects IDs on which user as sufficient rights.
CREATE TABLE #PCMTPROPIDs(Item_Id INTEGER)
INSERT #PCMTPROPIDs (Item_Id)
EXECUTE spLocal_PCMT_GetObjectIDs 'product_properties', 'prop_id', @txtUserId

SELECT
	pp.prop_id AS [cboProperty],
	pp.prop_desc
FROM 
	dbo.product_properties pp,
	#PCMTPROPIDs pp2
WHERE
	pp.prop_id = pp2.item_id
ORDER BY
	pp.prop_desc

DROP TABLE #PCMTPROPIDs

SET NOCOUNT OFF

















