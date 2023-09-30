
















CREATE PROCEDURE [dbo].[spLocal_PCMT_GetSPParams]
/*
*****************************************************************************************************************
Stored Procedure:		spLocal_PCMT_GetSPParams
Author:					Marc Charest (STI)
Date Created:			2006-11-14
SP Type:					ADO or SDK Call
Editor Tab Spacing:	3

Description:
=========
This SP duplicates a user.

Called by:  			PCMT.xls

Revision Date			Who						What
========	==========	=================== 	=============================================

*****************************************************************************************************************
*/
@vcrSPName				VARCHAR(255)

AS

SET NOCOUNT ON

SELECT 
	SP_Name, Param_Name, Param_Type, Param_Length
FROM 
	Local_PG_PCMT_SPs
WHERE
	SP_Name = @vcrSPName
ORDER BY
	Param_Order

SET NOCOUNT OFF















