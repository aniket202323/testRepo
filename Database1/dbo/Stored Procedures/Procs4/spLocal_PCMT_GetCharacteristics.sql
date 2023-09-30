











CREATE PROCEDURE [dbo].[spLocal_PCMT_GetCharacteristics]
/*
*****************************************************************************************************************
Stored Procedure:		spLocal_PCMT_GetCharacteristics
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

DECLARE
@intPropId			INTEGER

SET @intPropId		= @cboProperty


SELECT a.prop_id, a.prop_desc, a.char_id, a.char_desc, a.derived_from_parent
FROM
(

SELECT prop_id, prop_desc, -1 AS [char_id], prop_desc AS [char_desc], -99 AS [derived_from_parent], 1 AS [code] 
FROM dbo.product_properties pp 
WHERE prop_id = @intPropId

UNION

SELECT
	pp.prop_id, 
	pp.prop_desc, 
	c.char_id, 
	c.char_desc, 
	CASE WHEN c.derived_from_parent IS NULL THEN -1 ELSE c.derived_from_parent END AS [derived_from_parent],
	2 AS [code]
FROM 
	dbo.product_properties pp
	LEFT JOIN dbo.characteristics c ON (c.prop_id = pp.prop_id)
	LEFT JOIN dbo.characteristics c2 ON (c.derived_from_parent = c2.char_id)
WHERE
	pp.prop_id IS NOT NULL AND c.char_id IS NOT NULL
	AND pp.prop_id = @intPropId
--ORDER BY
--	c.derived_from_parent, pp.prop_desc asc, c.char_desc

) a

ORDER BY
	a.derived_from_parent, a.prop_desc ASC, a.code, a.char_desc


SET NOCOUNT OFF





















