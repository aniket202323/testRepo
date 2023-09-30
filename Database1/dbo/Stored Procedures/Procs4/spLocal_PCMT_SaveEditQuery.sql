










CREATE    PROCEDURE [dbo].[spLocal_PCMT_SaveEditQuery]
/*
*****************************************************************************************************************
Stored Procedure:		spLocal_PCMT_SaveEditQuery
Author:					Marc Charest (STI)	
Date Created:			2007-05-03
SP Type:					ADO or SDK Call
Editor Tab Spacing:	3

Description:
=========
This SP ...

Called by:  			PCMT.xls

Revision Date			Who						What
========	==========	=================== 	=============================================
1.0.1		02-Dec-08	Marc Charest			I added DELETE instructions to avoid key violation error

*****************************************************************************************************************
*/
@txtEditQuery			VARCHAR(5000),
@txtEditVarId			INTEGER,
@txtDatetime			DATETIME

AS


SET NOCOUNT ON

DECLARE
@intCounter				INTEGER,
@intPUID					INTEGER

--Getting PU_ID
SET @intPUID = (SELECT pu_id FROM dbo.variables WHERE var_id = @txtEditVarId)


--Saving edit query. This query string will be executed when a variable is un-obsoleted (spLocal_PCMT_UnobsoleteVariable)
DELETE FROM dbo.Local_PG_PCMT_Edit_Queries WHERE Var_Id = @txtEditVarId
INSERT dbo.Local_PG_PCMT_Edit_Queries (pu_id, var_id, query_string, pcmt_version, timestamp)
VALUES (@intPUID, @txtEditVarId, @txtEditQuery, NULL, @txtDatetime)

--Saving sheet_variables entries. These entries will be inserted again in sheet_variables when a variable is un-obsoleted.
DELETE FROM dbo.Local_PG_PCMT_Sheet_Variables WHERE Var_Id = @txtEditVarId
INSERT dbo.Local_PG_PCMT_Sheet_Variables (pu_id, sheet_id, var_id, var_order, timestamp)
SELECT @intPUID, sheet_id, var_id, var_order, @txtDatetime FROM dbo.sheet_variables WHERE var_id = @txtEditVarId

INSERT dbo.Local_PG_PCMT_Sheet_Variables (pu_id, sheet_id, var_id, var_order, timestamp)
SELECT @intPUID, sheet_id, sv.var_id, var_order, @txtDatetime 
FROM dbo.sheet_variables sv, dbo.variables v 
WHERE 
	sv.var_id = v.var_id 
	AND v.pvar_id = @txtEditVarId

--Saving alarm_template_var_data entries. These entries will be inserted again in alarm_template_var_data when a variable is un-obsoleted.
DELETE FROM dbo.Local_PG_PCMT_Alarm_Template_Var_Data WHERE Var_Id = @txtEditVarId
INSERT dbo.Local_PG_PCMT_Alarm_Template_Var_Data (pu_id, at_id, var_id, timestamp)
SELECT DISTINCT @intPUID, at_id, var_id, @txtDatetime FROM dbo.alarm_template_var_data WHERE var_id = @txtEditVarId

INSERT dbo.Local_PG_PCMT_Alarm_Template_Var_Data (pu_id, at_id, var_id, timestamp)
SELECT DISTINCT @intPUID, at_id, atvd.var_id, @txtDatetime 
FROM dbo.alarm_template_var_data atvd, dbo.variables v 
WHERE 
	atvd.var_id = v.var_id 
	AND v.pvar_id = @txtEditVarId
	AND atvrd_id IS NOT NULL


SELECT @txtEditVarId

SET NOCOUNT OFF






