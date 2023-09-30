














CREATE PROCEDURE [dbo].[spLocal_PCMT_GetVariableIDsToMakeObs]
/*
*****************************************************************************************************************
Stored Procedure:		spLocal_PCMT_GetVariableIDsToMakeObs
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
@intPVarId					INTEGER,
@intChildNumber			INTEGER

AS 

SET NOCOUNT ON

SELECT var_id FROM dbo.variables WHERE pvar_id = @intPVarId AND CAST(RIGHT(var_desc, 2) AS INTEGER) >= @intChildNumber

SET NOCOUNT OFF














