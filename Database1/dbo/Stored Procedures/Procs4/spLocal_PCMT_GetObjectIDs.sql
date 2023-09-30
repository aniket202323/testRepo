








CREATE PROCEDURE [dbo].[spLocal_PCMT_GetObjectIDs]
/*
*****************************************************************************************************************
Stored Procedure:		spLocal_PCMT_GetObjectIDs
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
EXECUTE spLocal_PCMT_GetObjectIDs @vcrTableName = 'prod_lines', @vcrIDFieldName = 'pl_id', @intUserId = 51
*/
@vcrTableName			VARCHAR(255),
@vcrIDFieldName		VARCHAR(30),
@intUserId				INTEGER

AS

SET NOCOUNT ON

DECLARE
@intSecurityLevel		INTEGER,
@vcrSQLCommand			NVARCHAR(4000),
@vcrSQLParams			NVARCHAR(4000)

SET @intSecurityLevel = ISNULL((
								SELECT  
									CASE	WHEN group_desc = 'Administrator' AND al_desc = 'Admin' THEN 3
											WHEN group_desc = 'Administrator' AND (al_desc = 'Read/Write' OR al_desc = 'Manager') THEN 2
											WHEN group_desc = 'Administrator' THEN 1
											ELSE 0 
									END 
								FROM 
									user_security us 
									 JOIN security_groups sg ON (us.group_id = sg.group_id)
									 JOIN access_level al ON (us.access_level = al.al_id)
								WHERE 
									us.user_id = @intUserId
									AND (group_desc = 'Administrator')
								), 0)


SET @vcrSQLCommand = 
'SELECT DISTINCT obj.' + @vcrIDFieldName + ' ' + 
'FROM ' +  
'	dbo.' + @vcrTableName + ' obj ' + 
'	LEFT JOIN dbo.user_security us ON (us.group_id = obj.group_id) ' + 
'WHERE ' +  
'	' + @vcrIDFieldName + ' <> 0 ' + 
'	AND ((@intSecurityLevel = 3) ' + 
'			OR ' + 
'		  (@intSecurityLevel = 2 AND obj.group_id IS NULL) ' + 
'			OR ' + 
'		  ((@intSecurityLevel = 2 OR @intSecurityLevel = 1) AND us.group_id = obj.group_id AND us.user_id = @intUserId)) '

SET @vcrSQLParams = 
'@intSecurityLevel INTEGER, @intUserId INTEGER'


EXEC sp_executesql @vcrSQLCommand, @vcrSQLParams, @intSecurityLevel, @intUserId

SET NOCOUNT OFF




















