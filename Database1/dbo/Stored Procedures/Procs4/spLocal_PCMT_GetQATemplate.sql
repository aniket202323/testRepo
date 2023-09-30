









CREATE PROCEDURE [dbo].[spLocal_PCMT_GetQATemplate]
/*
*****************************************************************************************************************
Stored Procedure:		spLocal_PCMT_GetQATemplate
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
@vcrLineDesc		VARCHAR(50),
@vcrTplDesc			VARCHAR(50)

AS

SET NOCOUNT ON

SELECT at_id, at_desc FROM dbo.alarm_templates WHERE at_desc = @vcrLineDesc + ' ' + @vcrTplDesc

SET NOCOUNT OFF










