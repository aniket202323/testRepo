















---------------------------------------------------------------------------------------------------------------

----------------------------------------[Creation Of SP]-------------------------------------------------------
CREATE PROCEDURE [dbo].[spLocal_PCMT_GetPlantModelUDP]
/*
---------------------------------------------------------------------------------------------------------------
Stored Procedure:		spLocal_PCMT_GetPlantModelUDP
Author:					Marc Charest(STI)
Date Created:			2009-05-15
SP Type:					PCMT
Editor Tab Spacing:	3

Description:
===============================================================================================================
This sp returns the plant model tree structure.

Called by:  			PCMT (VBA modules)
	
Revision	Date			Who									What
========	===========	==========================		===============================================================



spLocal_PCMT_GetPlantModelUDP 1, 0
*/
@intUserId		INTEGER,
@bitGlobal		BIT = 1

AS

SET NOCOUNT ON

--Getting objects IDs on which user as sufficient rights.
CREATE TABLE #PCMTPLIDs(Item_Id INTEGER)
CREATE TABLE #PCMTPUIDs(Item_Id INTEGER)
CREATE TABLE #PCMTPUGIDs(Item_Id INTEGER)
INSERT #PCMTPLIDs (Item_Id)
EXECUTE spLocal_PCMT_GetObjectIDs 'prod_lines', 'pl_id', @intUserId
INSERT #PCMTPUIDs (Item_Id)
EXECUTE spLocal_PCMT_GetObjectIDs 'prod_units', 'pu_id', @intUserId
INSERT #PCMTPUGIDs (Item_Id)
EXECUTE spLocal_PCMT_GetObjectIDs 'pu_groups', 'pug_id', @intUserId

SELECT 
	d.Dept_Id, 
	CASE WHEN @bitGlobal = 1 THEN COALESCE(d.dept_desc_global, d.dept_desc_local) ELSE d.dept_desc_local END AS [dept_desc], 
	pl.pl_id, 
	CASE WHEN @bitGlobal = 1 THEN COALESCE(pl.pl_desc_global, pl.pl_desc_local) ELSE pl.pl_desc_local END AS [pl_desc], 
	pu.pu_id, 
	CASE WHEN @bitGlobal = 1 THEN COALESCE(pu.pu_desc_global, pu.pu_desc_local) ELSE pu.pu_desc_local END AS [pu_desc], 
	pug.pug_id, 
	CASE WHEN @bitGlobal = 1 THEN COALESCE(pug.pug_desc_global, pug.pug_desc_local) ELSE pug.pug_desc_local END AS [pug_desc], 
	NULL,
	NULL,
	NULL,
	NULL,
	--v.var_id, 
	--CASE WHEN @bitGlobal = 1 THEN COALESCE(v.var_desc_global, v.var_desc_local) ELSE v.var_desc_local END AS [var_desc],
	--v2.var_id, 
	--CASE WHEN @bitGlobal = 1 THEN COALESCE(v2.var_desc_global, v2.var_desc_local) ELSE v2.var_desc_local END AS [child_desc],
	CASE WHEN pu.master_unit IS NULL THEN pu.pu_id ELSE pu.master_unit END AS [Rank],
	CASE WHEN pu.master_unit IS NULL THEN 'Master' ELSE 'Slave' END AS [UnitType]
FROM 
	dbo.Departments d WITH(NOLOCK)
	JOIN dbo.Prod_Lines pl WITH(NOLOCK) ON (pl.Dept_Id = d.Dept_Id)
	JOIN dbo.Prod_Units pu WITH(NOLOCK) ON (pu.pl_id = pl.pl_id)
	JOIN dbo.Pu_Groups pug WITH(NOLOCK) ON (pug.pu_id = pu.pu_id),
	--JOIN dbo.variables v WITH(NOLOCK) ON (v.pug_id = pug.pug_id)
	--LEFT JOIN dbo.variables v2 WITH(NOLOCK) ON (v2.PVar_Id = v.Var_Id),
	#PCMTPLIDs pl2, #PCMTPUIDs pu2, #PCMTPUGIDs pug2
WHERE 
	pl.pl_id <> 0
	AND pl.pl_id = pl2.item_id AND pu.pu_id = pu2.item_id AND pug.pug_id = pug2.item_id
	AND pl.pl_desc_local IS NOT NULL
	AND pu.pu_desc_local IS NOT NULL
	AND pug.pug_desc_local IS NOT NULL
	--AND v.var_desc_global IS NOT NULL AND v.var_desc_local IS NOT NULL
ORDER BY d.dept_desc, pl.pl_desc, pu.pu_order, UnitType, pu.pu_desc, pug.pug_desc--, v.var_desc, child_desc

DROP TABLE #PCMTPLIDs
DROP TABLE #PCMTPUIDs
DROP TABLE #PCMTPUGIDs

SET NOCOUNT OFF














