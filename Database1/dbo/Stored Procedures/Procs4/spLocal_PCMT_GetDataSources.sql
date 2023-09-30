




















CREATE PROCEDURE [dbo].[spLocal_PCMT_GetDataSources]
/*
*****************************************************************************************************************
Stored Procedure:		spLocal_PCMT_
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

SELECT ds_id AS [cboDataSource], ds_desc
FROM dbo.Data_Source
WHERE ds_desc in ('Autolog','Base Unit','Base Variable','Historian','Undefined', 'CalculationMgr')
ORDER BY ds_desc

--SELECT * FROM Data_Source

SET NOCOUNT OFF






















