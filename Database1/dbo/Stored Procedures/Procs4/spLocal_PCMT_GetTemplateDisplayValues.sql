









CREATE PROCEDURE [dbo].[spLocal_PCMT_GetTemplateDisplayValues]
/*
*****************************************************************************************************************
Stored Procedure:		spLocal_PCMT_GetTemplateDisplayValues
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
@intVarId					INTEGER,
@intQAVarId					INTEGER

AS 

SET NOCOUNT ON

DECLARE
@intAlarmTemplateId		INTEGER,
@intAlarmDisplayId		INTEGER,
@intQAlarmTemplateId		INTEGER,
@intQAlarmDisplayId		INTEGER,
@intAutologDisplayId		INTEGER,
@intAutologOrder			INTEGER

SET @intAlarmTemplateId = (
SELECT TOP 1 at.at_id
FROM 
	dbo.alarm_template_var_data atvd, alarm_templates at
WHERE
	atvd.at_id = at.at_id
	AND var_id = @intVarId
ORDER BY at.at_id
)

SET @intAlarmDisplayId = (
SELECT TOP 1 s.sheet_id 
FROM 
	dbo.sheet_variables sv, dbo.sheets s
WHERE
	sv.sheet_id = s.sheet_id AND s.sheet_type =  11
	AND var_id = @intVarId
ORDER BY s.sheet_id
)

SET @intQAlarmTemplateId = (
SELECT TOP 1 at.at_id
FROM 
	dbo.alarm_template_var_data atvd, dbo.alarm_templates at
WHERE
	atvd.at_id = at.at_id
	AND var_id = @intQAVarId
ORDER BY at.at_id
)

SET @intQAlarmDisplayId = (
SELECT TOP 1 s.sheet_id 
FROM 
	dbo.sheet_variables sv, dbo.sheets s
WHERE
	sv.sheet_id = s.sheet_id AND s.sheet_type =  11
	AND var_id = @intQAVarId
ORDER BY s.sheet_id
)

SELECT TOP 1 @intAutologDisplayId = s.sheet_id, @intAutologOrder = sv.var_order
FROM 
	dbo.sheet_variables sv, dbo.sheets s
WHERE
	sv.sheet_id = s.sheet_id AND s.sheet_type <>  11
	AND var_id = @intVarId
ORDER BY s.sheet_id, sv.var_order

SELECT @intAlarmTemplateId, @intAlarmDisplayId, @intQAlarmTemplateId, @intQAlarmDisplayId, @intAutologDisplayId, @intAutologOrder

SET NOCOUNT OFF










