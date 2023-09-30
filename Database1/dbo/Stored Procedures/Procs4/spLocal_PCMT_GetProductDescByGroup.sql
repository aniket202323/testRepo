















---------------------------------------------------------------------------------------------------------------

----------------------------------------[Creation Of SP]-------------------------------------------------------
CREATE PROCEDURE [dbo].[spLocal_PCMT_GetProductDescByGroup]
/*
---------------------------------------------------------------------------------------------------------------
Stored Procedure:		spLocal_PCMT_GetProductDescByGroup
Author:					Marc Charest(STI)
Date Created:			2009-05-15
SP Type:					PCMT
Editor Tab Spacing:	3

Description:
===============================================================================================================
This sp returns the product groups tree structure.

Called by:  			PCMT (VBA modules)
	
Revision	Date			Who									What
========	===========	==========================		===============================================================


spLocal_PCMT_GetProductsByGroup 1, 1
*/
@intUserId		INTEGER,
@bitGlobal		BIT = 1

AS

SET NOCOUNT ON

SELECT
	pg.Product_Grp_Id,
	CASE WHEN @bitGlobal = 1 THEN COALESCE(pg.Product_Grp_Desc_Global, pg.Product_Grp_Desc_Local) ELSE pg.Product_Grp_Desc_Local END AS [PG_Desc], 
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
	NULL
FROM 
	dbo.Product_Group_Data pgd
	JOIN dbo.Products p ON (pgd.Prod_Id = P.Prod_Id)
	JOIN dbo.Product_Groups pg ON (pg.Product_Grp_Id = pgd.Product_Grp_Id)
WHERE 
	P.Prod_Desc <> 'z_obs%'
	AND pg.Product_Grp_Desc <> 'z_obs%'
ORDER BY 
	pg.Product_Grp_Desc,
	p.Prod_Desc


SET NOCOUNT OFF














