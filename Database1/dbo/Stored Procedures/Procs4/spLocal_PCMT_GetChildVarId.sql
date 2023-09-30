














CREATE PROCEDURE [dbo].[spLocal_PCMT_GetChildVarId]
/*
*****************************************************************************************************************
Stored Procedure:		spLocal_PCMT_GetChildVarId
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
@intChildNumber		INTEGER,
@intPVar_Id				INTEGER

AS

SET NOCOUNT ON

SELECT var_id FROM dbo.variables WHERE pvar_id = @intPVar_Id AND CAST(RIGHT(var_desc, 2) AS INTEGER) = @intChildNumber

SET NOCOUNT OFF














