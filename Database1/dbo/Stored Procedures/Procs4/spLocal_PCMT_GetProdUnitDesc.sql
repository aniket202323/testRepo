












CREATE PROCEDURE [dbo].[spLocal_PCMT_GetProdUnitDesc]
/*
*****************************************************************************************************************
Stored Procedure:		spLocal_PCMT_GetProdUnitDesc
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
@intLineSpecific	INTEGER,
@vcrPUDesc			VARCHAR(50),
@vcrPLDesc			VARCHAR(50)

AS

SET NOCOUNT ON

SELECT pu.pu_desc 
FROM 
	dbo.prod_units pu
	LEFT JOIN dbo.prod_lines pl ON (pu.pl_id = pl.pl_id)
WHERE
	((@intLineSpecific = 0 AND pu.pu_desc = @vcrPUDesc)
	OR
	(@intLineSpecific = 1 AND pu.pu_desc LIKE '%' + @vcrPUDesc + '%' AND pu.pu_desc LIKE '%' + @vcrPLDesc + '%'))
	AND pl.pl_desc = @vcrPLDesc


SET NOCOUNT OFF













