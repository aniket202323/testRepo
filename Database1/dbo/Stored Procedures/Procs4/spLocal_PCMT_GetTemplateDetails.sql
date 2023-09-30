










CREATE PROCEDURE [dbo].[spLocal_PCMT_GetTemplateDetails]
/*
*****************************************************************************************************************
Stored Procedure:		spLocal_PCMT_GetTemplateDetails
Author:					Marc Charest (STI)
Date Created:			2006-11-14
SP Type:					ADO or SDK Call
Editor Tab Spacing:	3

Description:
=========
This SP gets access level entries.

Called by:  			PCMT.xls

Revision Date			Who						What
========	==========	=================== 	=============================================

*****************************************************************************************************************
*/
@cboTempDisp		INTEGER

AS

SET NOCOUNT ON

SELECT 
	at.at_desc AS [Template Description],
	t.alarm_type_desc AS [Alarm Type],
	ap.ap_desc AS [Template Priority],
	ap2.ap_desc AS [Rule Priority],
	avr.alarm_variable_rule_desc AS [Rule Description]
--	v.var_desc AS [Variable Description]
FROM
	dbo.alarm_templates at
	LEFT JOIN dbo.alarm_types t ON (at.alarm_type_id = t.alarm_type_id)
	LEFT JOIN dbo.alarm_priorities ap ON (at.ap_id = ap.ap_id)
	LEFT JOIN dbo.Alarm_Template_Variable_Rule_Data atvrd ON (at.at_id = atvrd.at_id)
	LEFT JOIN dbo.alarm_priorities ap2 ON (atvrd.ap_id = ap2.ap_id)
	LEFT JOIN dbo.alarm_variable_rules avr ON (atvrd.alarm_variable_rule_id = avr.alarm_variable_rule_id)
	LEFT JOIN dbo.alarm_template_var_data atvd ON (atvd.atvrd_id = atvrd.atvrd_id AND atvd.at_id = at.at_id)
--	LEFT JOIN dbo.variables v ON (v.var_id = atvd.var_id)
WHERE
	at.at_id = @cboTempDisp
--ORDER BY
	

SET NOCOUNT OFF











