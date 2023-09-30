











CREATE PROCEDURE [dbo].[spLocal_PCMT_GetSingleProperty]
/*
*****************************************************************************************************************
Stored Procedure:		spLocal_PCMT_GetCharacteristics
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
@intPropId		INTEGER

AS

SET NOCOUNT ON

SELECT prop_desc, prop_id FROM dbo.product_properties WHERE prop_id = @intPropId OR prop_desc = 'RE_Product Information'
ORDER BY prop_desc


SET NOCOUNT OFF


















