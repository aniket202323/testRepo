







CREATE PROCEDURE [dbo].[spLocal_PCMT_GetIndividualEIs]
/*
*****************************************************************************************************************
Stored Procedure:		spLocal_PCMT_GetIndividualEIs
Author:					Marc Charest (STI)	
Date Created:			2007-05-03
SP Type:					ADO or SDK Call
Editor Tab Spacing:	3

Description:
=========
This SP gets individual infos from parent and child variables (EI, UD1, UD2 and UD3)

Called by:  			PCMT.xls

-------------------------------------------------------------------------------------------------
Updated By	:	Stephane Turner (System Technologies for Industry Inc)
Date			:	2008-04-14
Version		:	1.0.1
Purpose		: 	Checks if global description is null

*****************************************************************************************************************
*/
@intVarId	INTEGER

AS

SET NOCOUNT ON

SELECT
	ISNULL(v.var_desc_global, v.var_desc) AS [VarName],
	ISNULL(v.extended_info, '') AS [EI],
	ISNULL(v.user_defined1, '') AS [UD1],
	ISNULL(v.user_defined2, '') AS [UD2],
	ISNULL(v.user_defined3, '') AS [UD3]
FROM
	dbo.variables v
WHERE
	var_id = @intVarId
	or pvar_id = @intVarId
ORDER BY
	v.var_desc_global


SET NOCOUNT OFF








