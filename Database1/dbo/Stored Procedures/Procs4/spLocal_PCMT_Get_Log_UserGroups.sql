
















-------------------------------------------------------------------------------------------------

----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_PCMT_Get_Log_UserGroups]
/*
*****************************************************************************************************************
Stored Procedure:		spLocal_PCMT_Get_Log_UserGroups
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
@dtmStartTime	datetime=NULL,
@dtmEndTime		datetime=NULL,
@intUserId		integer=NULL

AS

SET NOCOUNT ON

DECLARE @Users TABLE
(
[user_id]		integer
)

--If user is not specified, then look for all users
IF @intUserId IS NULL BEGIN
	INSERT @Users ([user_id])
  	SELECT DISTINCT [user_id1]
  	FROM dbo.Local_PG_PCMT_Log_Groups END
ELSE BEGIN
  	INSERT @Users ([user_id]) VALUES(@intUserId)
END

SELECT	
        CONVERT(varchar,ls.[timestamp],120) AS [Entry On], 
		  u.username AS [Responsible], 
		  CASE 
				WHEN ls.type = 1 THEN 'ADD'
				WHEN ls.type = 2 THEN 'EDIT'
				ELSE 'OBSOLETE'
		  END AS [Type],
		  ls.group_desc AS [Description],
		  ls.group_id AS [Group ID]
FROM	dbo.Local_PG_PCMT_Log_Groups ls
        LEFT JOIN dbo.Users u		ON (u.[user_id] = ls.[user_id1])
WHERE ls.[timestamp] >= ISNULL(@dtmStartTime,'01-Jan-1900') AND
      ls.[timestamp] < ISNULL(@dtmEndTime,Getdate()) AND
      ls.[user_id1] IN (SELECT [user_id] FROM @Users)
ORDER BY ls.[timestamp]

SET NOCOUNT OFF


















