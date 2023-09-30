
-------------------------------------------------------------------------------------------------
CREATE  PROCEDURE [dbo].[spLocal_PCMT_GetUDPTables]
/*
*****************************************************************************************************************
Stored Procedure:		spLocal_PCMT_GetUDPTables
Author:					Juan Pablo Galanzini (Arido)
Date Created:			2014-07-28
SP Type:				ADO or SDK Call
Editor Tab Spacing:		4

Description:
=========
This SP is returns the tables used for UDP in dbo.tables

Called by:  			PCMT.xls

Revision	Date		Who								What
========	==========	=================== 			=============================================
2.0			2014-07-28	Juan Pablo Galanzini (Arido)	Version initial in PPA6

*****************************************************************************************************************
*/
AS

SET NOCOUNT ON

SELECT TableId AS [cboUDPTableId], TableName
	FROM dbo.tables
	ORDER BY TableName

SET NOCOUNT OFF
