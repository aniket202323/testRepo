












CREATE PROCEDURE [dbo].[spLocal_PCMT_GetSpecificUDPsForProduct]
/*
*****************************************************************************************************************
Stored Procedure:		spLocal_PCMT_GetSpecificUDPsForProduct
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
@txtUpdateType				INTEGER,
@txtProdId					INTEGER=NULL

AS

SET NOCOUNT ON

DECLARE
@intUpdateType				INTEGER,
@intProdId					INTEGER,
@intUDPCount				INTEGER

DECLARE @UDPs TABLE(
	table_field_desc	VARCHAR(8000),
	table_field_id		INTEGER
)

SET @intUpdateType		= @txtUpdateType
SET @intProdId				= @txtProdId

INSERT @UDPs (table_field_desc, table_field_id)
SELECT DISTINCT
	tf.table_field_desc, tf.table_field_id
FROM 
	dbo.table_fields tf 
	JOIN dbo.table_fields_values tfv ON (tfv.table_field_id = tf.table_field_id)
	JOIN dbo.products p ON (p.prod_id = tfv.keyid)
	JOIN dbo.tables t ON (t.tableid = tfv.tableid AND t.tablename = 'Products')
WHERE 
   ((@intUpdateType = 1)
	 OR
	(tfv.keyid = @intProdId AND @intUpdateType = 2))

SET @intUDPCount = (SELECT COUNT(table_field_id) FROM @UDPs)
SELECT table_field_desc, table_field_id, @intUDPCount FROM @UDPs ORDER BY table_field_desc


SET NOCOUNT OFF














