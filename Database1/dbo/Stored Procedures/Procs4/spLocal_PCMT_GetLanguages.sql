







CREATE PROCEDURE [dbo].[spLocal_PCMT_GetLanguages]
/*
*****************************************************************************************************************
Stored Procedure:		spLocal_PCMT_GetLanguages
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

AS

SET NOCOUNT ON

SELECT 
	language_id AS [cboLanguage], 
	language_desc 
FROM 
	dbo.languages 
ORDER BY 
	language_desc

SET NOCOUNT OFF






















