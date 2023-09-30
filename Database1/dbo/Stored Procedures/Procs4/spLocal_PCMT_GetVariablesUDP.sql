














---------------------------------------------------------------------------------------------------------------

----------------------------------------[Creation Of SP]-------------------------------------------------------
CREATE PROCEDURE [dbo].[spLocal_PCMT_GetVariablesUDP]
/*
---------------------------------------------------------------------------------------------------------------
Stored Procedure:		spLocal_PCMT_GetVariablesUDP
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



spLocal_PCMT_GetPlantModelUDP 1, 1
*/
@intUserId		INTEGER,
@bitGlobal		BIT = 1,
@PUG_Id			INTEGER

AS

SET NOCOUNT ON

SELECT 
	NULL,
	NULL,
	NULL,
	NULL,
	NULL,
	NULL,
	NULL,
	NULL,
	v.var_id, 
	CASE WHEN @bitGlobal = 1 THEN COALESCE(v.var_desc_global, v.var_desc_local) ELSE v.var_desc_local END AS [var_desc],
	v2.var_id, 
	CASE WHEN @bitGlobal = 1 THEN COALESCE(v2.var_desc_global, v2.var_desc_local) ELSE v2.var_desc_local END AS [child_desc],
	NULL,
	NULL
FROM 
	dbo.Pu_Groups pug WITH(NOLOCK)
	JOIN dbo.variables v WITH(NOLOCK) ON (v.pug_id = pug.pug_id)
	LEFT JOIN dbo.variables v2 WITH(NOLOCK) ON (v2.PVar_Id = v.Var_Id)
WHERE 
	pug.pug_id = @PUG_Id
	AND v.var_desc_global IS NOT NULL AND v.var_desc_local IS NOT NULL
ORDER BY 
	v.var_desc, child_desc

SET NOCOUNT OFF













