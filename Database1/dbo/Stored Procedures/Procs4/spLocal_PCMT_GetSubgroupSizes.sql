






















CREATE PROCEDURE [dbo].[spLocal_PCMT_GetSubgroupSizes]
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
2008-02-15			Tim Rogers		Made the sp go from 10 to 25 subgroups
2008-02-20			Tim Rogers		Made the sp go from 10 to 25 subgroups - completed/tested
*****************************************************************************************************************
*/

AS

SET NOCOUNT ON

SELECT a.size_id AS [cboSubgroupSize], a.size_desc
FROM
(
	SELECT 0 AS [size_id],	'0' AS [size_desc]
	UNION
	SELECT 2 AS [size_id],	'2' AS [size_desc]
	UNION
	SELECT 3 AS [size_id],	'3' AS [size_desc]
	UNION
	SELECT 4 AS [size_id],	'4' AS [size_desc]
	UNION
	SELECT 5 AS [size_id],	'5' AS [size_desc]
	UNION
	SELECT 6 AS [size_id],	'6' AS [size_desc]
	UNION
	SELECT 7 AS [size_id],	'7' AS [size_desc]
	UNION
	SELECT 8 AS [size_id],	'8' AS [size_desc]
	UNION
	SELECT 9 AS [size_id],	'9' AS [size_desc]
	UNION
	SELECT 10 AS [size_id],	'10' AS [size_desc]
	UNION
	SELECT 11 AS [size_id],	'11' AS [size_desc]
	UNION
	SELECT 12 AS [size_id],	'12' AS [size_desc]
	UNION
	SELECT 13 AS [size_id],	'13' AS [size_desc]
	UNION
	SELECT 14 AS [size_id],	'14' AS [size_desc]
	UNION
	SELECT 15 AS [size_id],	'15' AS [size_desc]
	UNION
	SELECT 16 AS [size_id],	'16' AS [size_desc]
	UNION
	SELECT 17 AS [size_id],	'17' AS [size_desc]
	UNION
	SELECT 18 AS [size_id],	'18' AS [size_desc]
	UNION
	SELECT 19 AS [size_id],	'19' AS [size_desc]
	UNION
	SELECT 20 AS [size_id],	'20' AS [size_desc]
	UNION
	SELECT 21 AS [size_id],	'21' AS [size_desc]
	UNION
	SELECT 22 AS [size_id],	'22' AS [size_desc]
	UNION
	SELECT 23 AS [size_id],	'23' AS [size_desc]
	UNION
	SELECT 24 AS [size_id],	'24' AS [size_desc]
	UNION
	SELECT 25 AS [size_id],	'25' AS [size_desc]
) a
ORDER BY
	a.size_id

SET NOCOUNT OFF
























