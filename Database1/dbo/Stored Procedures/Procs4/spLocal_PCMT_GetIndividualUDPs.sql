







CREATE PROCEDURE [dbo].[spLocal_PCMT_GetIndividualUDPs]
/*
*****************************************************************************************************************
Stored Procedure:		spLocal_PCMT_GetIndividualUDPs
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
@txtVarId				INTEGER=NULL

AS

SET NOCOUNT ON

DECLARE
@intVarId				INTEGER

SET @intVarId 			= @txtVarId

	SELECT
		v.var_desc_global, tf.table_field_desc, tf.table_field_id, tfv.value
	FROM
		dbo.variables v
		LEFT JOIN dbo.table_fields_values tfv ON (v.var_id = tfv.keyid)
		LEFT JOIN dbo.table_fields tf ON (tfv.table_field_id = tf.table_field_id)
		LEFT JOIN dbo.tables t ON (t.tableid = tfv.tableid AND t.tablename = 'Variables')

--		dbo.table_fields tf 
--		JOIN dbo.table_fields_values tfv ON (tfv.table_field_id = tf.table_field_id)
--		JOIN dbo.variables v ON (v.var_id = tfv.keyid)
--		JOIN dbo.tables t ON (t.tableid = tfv.tableid AND t.tablename = 'Variables')

	WHERE 
		(tfv.keyid = @intVarId OR v.pvar_id = @intVarId)
	ORDER BY
		v.var_desc_global, table_field_desc


SET NOCOUNT OFF








