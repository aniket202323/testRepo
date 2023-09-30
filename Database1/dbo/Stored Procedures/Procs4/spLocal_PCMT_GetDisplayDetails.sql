










CREATE PROCEDURE [dbo].[spLocal_PCMT_GetDisplayDetails]
/*
*****************************************************************************************************************
Stored Procedure:		spLocal_PCMT_GetDisplayDetails
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
	s.sheet_desc AS [Description], 
	sg.sheet_group_desc AS [Display Group],
	st.sheet_type_desc AS [Display Type],
	pu.pu_desc AS [Production Unit],
	et.et_desc AS [Event Type],
	est.event_subtype_desc AS [Event Subtype],
	s.event_prompt AS [Event Prompt],
	s.interval AS [Interval],
	s.offset AS [Offset]
FROM
	dbo.sheets s
	LEFT JOIN dbo.sheet_groups sg ON (s.sheet_group_id = sg.sheet_group_id)
	LEFT JOIN dbo.sheet_type st ON (s.sheet_type = st.sheet_type_id)
	LEFT JOIN dbo.prod_units pu ON (s.master_unit = pu.pu_id)
	LEFT JOIN dbo.event_types et ON (s.event_type = et.et_id)
	LEFT JOIN dbo.event_subtypes est ON (s.event_subtype_id = est.event_subtype_id)
WHERE
	s.sheet_id = @cboTempDisp
	

SET NOCOUNT OFF











