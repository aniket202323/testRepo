﻿









CREATE PROCEDURE [dbo].[spLocal_PCMT_GetSpecificUDPValuesForSpec]
/*
*****************************************************************************************************************
Stored Procedure:		spLocal_PCMT_GetSpecificUDPValuesForSpec
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
@txtTableFieldId		INTEGER,
@txtSpecId				INTEGER=NULL


AS

SET NOCOUNT ON

DECLARE
@vcrSQLCommand			NVARCHAR(4000),
@vcrSQLParams			NVARCHAR(4000),
@intTableFieldId		INTEGER,
@intSpecId				INTEGER,
@intTableId				INTEGER

CREATE TABLE #IDENTITY(
	Item_Id		INTEGER IDENTITY,
	Item_Desc	VARCHAR(8000),
	Var_Id		INTEGER
)

SET @intTableFieldId = @txtTableFieldId
SET @intSpecId 			= @txtSpecId

SET @intTableId = (SELECT tableid FROM dbo.tables WHERE tablename = 'Specifications')

INSERT #IDENTITY (Item_Desc, Var_Id)
	SELECT DISTINCT tfv.value, @intSpecId
		FROM dbo.table_fields_values tfv 
		WHERE table_field_id = @intTableFieldId
		AND tfv.value IS NOT NULL 
		ORDER BY tfv.value 

SET @vcrSQLCommand =
'SELECT DISTINCT ' + 
'	i.item_id AS [cbo' + CAST(@intTableFieldId AS VARCHAR(10)) + '], tfv.value AS [txtDump]' + 
'FROM ' + 
'	#IDENTITY i ' + 
'	LEFT JOIN dbo.table_fields_values tfv ON (tfv.value = i.item_desc)' + 
'WHERE ' + 
'	(table_field_id = @intTableFieldId AND tfv.keyid = i.var_id AND @intVarId IS NOT NULL)' + 
'	 OR ' +
'	(table_field_id = @intTableFieldId AND @intVarId IS NULL)' +  
'	 AND tfv.value IS NOT NULL AND tableid = @intTableId ' + 
'ORDER BY ' + 
'	tfv.value '

SET @vcrSQLParams = 
'@intTableFieldId INTEGER, @intVarId INTEGER, @intTableId INTEGER'

EXEC sp_executesql @vcrSQLCommand, @vcrSQLParams, @intTableFieldId, @intSpecId, @intTableId

DROP TABLE #IDENTITY



SET NOCOUNT OFF









