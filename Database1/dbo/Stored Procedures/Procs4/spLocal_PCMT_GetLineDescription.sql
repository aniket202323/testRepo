













CREATE PROCEDURE [dbo].[spLocal_PCMT_GetLineDescription]
/*
*****************************************************************************************************************
Stored Procedure:		spLocal_PCMT_GetLineDescription
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
@intPLID		INTEGER


AS

SET NOCOUNT ON

SELECT PL_Desc_Local FROM dbo.Prod_Lines WHERE PL_Id = @intPLID


SET NOCOUNT OFF






















