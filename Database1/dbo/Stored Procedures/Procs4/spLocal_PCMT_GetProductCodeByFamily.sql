















---------------------------------------------------------------------------------------------------------------

----------------------------------------[Creation Of SP]-------------------------------------------------------
CREATE PROCEDURE [dbo].[spLocal_PCMT_GetProductCodeByFamily]
/*
---------------------------------------------------------------------------------------------------------------
Stored Procedure:		spLocal_PCMT_GetProductCodeByFamily
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


spLocal_PCMT_GetProductCodeByFamily 1, 1
*/
@intUserId		INTEGER,
@bitGlobal		BIT = 1

AS

SET NOCOUNT ON

CREATE TABLE #PCMTPFIDs(Item_Id INTEGER)
INSERT #PCMTPFIDs (Item_Id)
EXECUTE spLocal_PCMT_GetObjectIDs 'product_family', 'Product_Family_Id', @intUserId

SELECT
	pf.Product_Family_Id,
	CASE WHEN @bitGlobal = 1 THEN COALESCE(pf.Product_Family_Desc_Global, pf.Product_Family_Desc_Local) ELSE pf.Product_Family_Desc_Local END AS [PF_Desc], 
	p.Prod_Id,
	p.Prod_Code AS [Prod_Code], 
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
	JOIN dbo.Product_Family pf ON (pf.Product_Family_Id = p.Product_Family_Id),
	#PCMTPFIDs pf2
WHERE 
	P.Prod_Desc <> 'z_obs%'
	AND pf.Product_Family_Desc <> 'z_obs%'
	AND pf.Product_Family_Id = pf2.item_id
ORDER BY 
	pf.Product_Family_Desc,
	p.Prod_Code


DROP TABLE #PCMTPFIDs


SET NOCOUNT OFF














