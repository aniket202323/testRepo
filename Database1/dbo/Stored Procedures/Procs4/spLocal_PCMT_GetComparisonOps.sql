







CREATE PROCEDURE [dbo].[spLocal_PCMT_GetComparisonOps]
/*
*****************************************************************************************************************
Stored Procedure:		spLocal_PCMT_GetComparisonOps
Author:					Vincent Rouleau (STI)
Date Created:			2007-09-04
SP Type:					ADO or SDK Call
Editor Tab Spacing:	3

Description:
=========
This SP is returning the list of comparison operators

Called by:  			PCMT.xls

Revision Date			Who						What
========	==========	=================== 	=============================================


*****************************************************************************************************************
spLocal_PCMT_GetComparisonOps
*/

AS

SET NOCOUNT ON

SELECT 
	comparison_operator_id AS [cboDQCompType], 
	comparison_operator_value
FROM
	dbo.comparison_operators
--UNION
--SELECT NULL, '<None>'
ORDER BY 
	comparison_operator_value

SET NOCOUNT OFF









