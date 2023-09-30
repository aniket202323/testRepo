










CREATE PROCEDURE [dbo].[spLocal_PCMT_GetSpecificUDPsForSpec]
/*
*****************************************************************************************************************
Stored Procedure:		spLocal_PCMT_GetSpecificUDPsForSpec
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
@txtSpecId					INTEGER=NULL

AS

SET NOCOUNT ON

DECLARE
@intUpdateType				INTEGER,
@intSpecId					INTEGER,
@intUDPCount				INTEGER

DECLARE @UDPs TABLE(
	table_field_desc	VARCHAR(4000),
	table_field_id		INTEGER
)

SET @intUpdateType		= @txtUpdateType
SET @intSpecId				= @txtSpecId

INSERT @UDPs (table_field_desc, table_field_id)
SELECT DISTINCT
	tf.table_field_desc, tf.table_field_id
FROM 
	dbo.table_fields tf 
	JOIN dbo.table_fields_values tfv ON (tfv.table_field_id = tf.table_field_id)
	JOIN dbo.specifications s ON (s.spec_id = tfv.keyid)
	JOIN dbo.tables t ON (t.tableid = tfv.tableid AND t.tablename = 'Specifications')
WHERE 
   ((@intUpdateType = 1)
	 OR
	(tfv.keyid = @intSpecId AND @intUpdateType = 2))

SET @intUDPCount = (SELECT COUNT(table_field_id) FROM @UDPs)
SELECT table_field_desc, table_field_id, @intUDPCount FROM @UDPs ORDER BY table_field_desc


SET NOCOUNT OFF












