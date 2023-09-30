






CREATE PROCEDURE [dbo].[spLocal_PCMT_GetSpecificUDPs]
/*
*****************************************************************************************************************
Stored Procedure:		spLocal_PCMT_GetSpecificUDPs
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
@cboEventSubtype			INTEGER,
@txtUpdateType				INTEGER,
@txtVarId					INTEGER=NULL,
@txtTableFieldIDs			VARCHAR(1000)=NULL,
@txtTableFieldValues		VARCHAR(8000)=NULL

AS

SET NOCOUNT ON

DECLARE
@intEventSubtypeId		INTEGER,
@intUpdateType				INTEGER,
@intVarId					INTEGER,
@vcrTableFieldIDs			VARCHAR(1000),
@vcrTableFieldValues		VARCHAR(8000),
@intUDPCount				INTEGER

DECLARE @UDPs TABLE(
	table_field_desc	VARCHAR(255),
	table_field_id		INTEGER,
	table_field_value	VARCHAR(7750)
)

CREATE TABLE #TableFieldIDs(
	item_id				INTEGER,
	Field_Id				INTEGER
)

CREATE TABLE #TableFieldValues(
	item_id				INTEGER,
	Field_Value			VARCHAR(8000)
)

SET @intEventSubtypeId		= @cboEventSubtype
SET @intUpdateType			= @txtUpdateType
SET @intVarId					= @txtVarId
SET @vcrTableFieldIDs		= @txtTableFieldIDs
SET @vcrTableFieldValues	= @txtTableFieldValues

IF @vcrTableFieldIDs IS NULL BEGIN

	INSERT @UDPs (table_field_desc, table_field_id)
	SELECT DISTINCT
		tf.table_field_desc, tf.table_field_id
	FROM 
		dbo.table_fields tf 
		JOIN dbo.table_fields_values tfv ON (tfv.table_field_id = tf.table_field_id)
		JOIN dbo.variables v ON (v.var_id = tfv.keyid)
		JOIN dbo.tables t ON (t.tableid = tfv.tableid AND t.tablename = 'Variables')
	WHERE ((v.event_subtype_id = @intEventSubtypeId AND @intUpdateType = 1)
		 OR	(tfv.keyid = @intVarId AND @intUpdateType = 2)) 
		 AND @intEventSubtypeId IS NOT NULL END

ELSE BEGIN

	INSERT #TableFieldIDs(Item_Id, Field_Id)
	EXECUTE spLocal_PCMT_ParseString @vcrTableFieldIDs, NULL, '[REC]', 'INTEGER'

	INSERT #TableFieldValues(Item_Id, Field_Value)
	EXECUTE spLocal_PCMT_ParseString @vcrTableFieldValues, NULL, '[REC]', 'VARCHAR(255)'

	INSERT @UDPs (table_field_desc, table_field_id, table_field_value)
	SELECT
		tf.table_field_desc, i.Field_Id, v.Field_Value
	FROM
		#TableFieldIDs i
		JOIN dbo.table_fields tf ON (tf.table_field_id = i.Field_Id) 
		JOIN #TableFieldValues v ON (i.item_id = v.item_id)

END

SET @intUDPCount = (SELECT COUNT(table_field_id) FROM @UDPs)
SELECT table_field_desc, table_field_id, @intUDPCount, table_field_value FROM @UDPs ORDER BY table_field_desc

DROP TABLE #TableFieldIDs
DROP TABLE #TableFieldValues

SET NOCOUNT OFF










