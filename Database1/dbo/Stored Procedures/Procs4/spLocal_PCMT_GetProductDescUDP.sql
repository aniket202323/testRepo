







---------------------------------------------------------------------------------------------------------------

----------------------------------------[Creation Of SP]-------------------------------------------------------
CREATE PROCEDURE [dbo].[spLocal_PCMT_GetProductDescUDP]
/*
---------------------------------------------------------------------------------------------------------------
Stored Procedure:		spLocal_PCMT_GetProductDescUDP
Author:					Marc Charest(STI)
Date Created:			2009-05-15
SP Type:					PCMT
Editor Tab Spacing:	3

Description:
===============================================================================================================
This sp returns the products tree structure.

Called by:  			PCMT (VBA modules)
	
Revision	Date			Who									What
========	===========	==========================		===============================================================


spLocal_PCMT_GetProductDescUDP 1, 1
*/
@intUserId		INTEGER,
@bitGlobal		BIT = 1

AS

SET NOCOUNT ON

SELECT
	p.Prod_Id,
	CASE WHEN @bitGlobal = 1 THEN COALESCE(p.Prod_Desc_global, p.Prod_Desc_Local) ELSE p.Prod_Desc_Local END AS [Prod_Desc], 
	NULL,
	NULL,
	NULL,
	NULL,
	NULL,
	NULL,
	NULL,
	NULL,
	NULL,
	NULL,
	NULL,
	NULL
FROM 
	dbo.Products p
WHERE 
	P.Prod_Desc <> 'z_obs%'
ORDER BY 
	p.Prod_Desc


SET NOCOUNT OFF














