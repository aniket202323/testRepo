








CREATE PROCEDURE [dbo].[spLocal_PCMT_GetUDPHierarchies]
/*
*****************************************************************************************************************
Stored Procedure:		spLocal_PCMT_GetUDPHierarchies
Author:					Marc Charest (STI)
Date Created:			2009-05-13
SP Type:					ADO or SDK Call
Editor Tab Spacing:	3

Description:
=========
This SP gets hierarchies for the UDP management module.

Called by:  			PCMT.xls

Revision Date			Who						What
========	==========	=================== 	=============================================

*****************************************************************************************************************
*/

AS

SET NOCOUNT ON

SELECT [cboHierarchy], [Description] FROM
(
SELECT 1 AS [cboHierarchy], 'Plant Model' AS [Description]
UNION
SELECT 2 AS [cboHierarchy], 'Products by family (Description)' AS [Description]
UNION
SELECT 3 AS [cboHierarchy], 'Products by group (Description)' AS [Description] 
UNION
SELECT 4 AS [cboHierarchy], 'Products by family (Code)' AS [Description]
UNION
SELECT 5 AS [cboHierarchy], 'Products by group (Code)' AS [Description] 
UNION
SELECT 6 AS [cboHierarchy], 'Products (Description)' AS [Description]
UNION
SELECT 7 AS [cboHierarchy], 'Products (Code)' AS [Description] 
) A
ORDER BY [Description]

SET NOCOUNT OFF









