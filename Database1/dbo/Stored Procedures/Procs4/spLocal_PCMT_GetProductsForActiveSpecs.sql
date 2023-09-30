







CREATE PROCEDURE [dbo].[spLocal_PCMT_GetProductsForActiveSpecs]
/*
*****************************************************************************************************************
Stored Procedure:		spLocal_PCMT_GetProductsForActiveSpecs
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
@intVarId			INTEGER,
@intPUId				INTEGER

AS

SET NOCOUNT ON

SELECT
	p.prod_id AS [lvwVariable], 
	p.prod_code,
	s.spec_desc,
	c.char_desc,
	p.prod_id,
	s.spec_id,
	pp.prop_id,
	puc.char_id
FROM
	dbo.variables v,
	dbo.specifications s,
	dbo.product_properties pp,
	dbo.pu_characteristics puc,
	dbo.characteristics c,
	dbo.products p
WHERE
	v.var_id = @intVarId
	AND v.spec_id = s.spec_id
	AND s.prop_id = pp.prop_id
	AND puc.prop_id = pp.prop_id
	AND puc.pu_id = @intPUId
	AND puc.prod_id = p.prod_id
	AND puc.char_id = c.char_id
ORDER BY
	p.prod_code

SET NOCOUNT OFF








